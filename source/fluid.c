#include <stdio.h>
#include <stdlib.h>
#include <math.h>
//#define TARGET_PLAYDATE 1;
//#define TARGET_SIMULATOR 0;
//#if TARGET_PLAYDATE
//#define __FPU_PRESENT 1
//#define __CC_ARM
//
//#include "core_cm7.h"
//#endif
//
//#if TARGET_SIMULATOR
//
//#include "intrin.h"
//#endif

// ^^ above stuff is for playing around with intrinsics for further optimisation.
// The Playdate can only do 32-bit in parallet, so 4 8 bit values at a time, which is not very useful unless we implement the density field as uint_8s.

#define N 30  // Grid size
#define STEPS 1.f  // Number of simulation steps
#define DT 0.02f  // Time step
#define DIFF 0.02f  // Diffusion rate
#define VISC 0.0001f  // Viscosity
#define COOL 0.001f   // Cooling rate
#define BURN 0.1f  // Burning rate
#define BUOY 0.5f  // Buoyancy
#define SOURCE_SQUARE_SIZE 8 
// Constants for the fluid simulation, some unused.

static int ESIZE = N; // Grid size, not using just N everywhere as lua can change its value for testing.

// Utility macros
#define IX(i, j) ((i) + (ESIZE + 2) * (j))
#define SWAP(x0,x) {float* tmp=x0;x0=x;x=tmp;}
#define RENDER_TO_SIM(x, size) (x - xOffset) * (ESIZE - 1) / (size - 1) + 1
#define RENDER_TO_SIMY(x, size) (x - yOffset) * (ESIZE - 1) / (size - 1) + 1

#include "pd_api.h"
#include "fluid.h"

//http://graphics.cs.cmu.edu/nsp/course/15-464/Spring11/papers/StamFluidforGames.pdf


//So some of these may be unused, that's very likely!
static int SIZE = (N + 2) * (N + 2);  // Grid size total including boundary
static float* u, * v, * u_prev, * v_prev;
static float* dens, * dens_fuel;
uint8_t* renderBuffer;
static int interp = 0;
static int simState = 0; //0 = rotating, ~0 = flame intensity control
static float fireStrength = 0.4f;
static float crankAngle = 0.f;
static int sourcePosX, sourcePosY;
static float sourceVelX, sourceVelY;
static int renderSizeX = 200, renderSizeY = 200;
const int xOffset = 100;
const int yOffset = 20;
static LCDBitmap* ingredientBitmap;
int iWidth, iHeight, iRowBytes;
uint8_t* iMask = NULL, * iData = NULL;
static PlaydateAPI* pd = NULL;
static int fluid_update(lua_State* L);
static int fluid_initialise(lua_State* L);
static int fluid_reinitialise(lua_State* L);
static int fluid_addSource(lua_State* L);
static int fluid_flipState(lua_State* L);
static int fluid_setTargetPosition(lua_State* L);

//Function table which maps the lua functions to the C functions. NULL indicates the end of the table.
const lua_reg fluid[] =
{
	{ "update",			fluid_update },
	{ "initialise",		fluid_initialise },
	{ "reinitialise",   fluid_reinitialise },
	{ "addSource",      fluid_addSource },
	{ "flipState",      fluid_flipState },
	{ "setTargetPosition", fluid_setTargetPosition },
	{ NULL,				NULL }
};

//Linear interpolation function that wraps around the 360 degree mark.
static float lerp(float a, float b, float t) {
	float diff = fmodf(b - a, 360.0f);
	float wrappedDiff = fmodf((diff + 540.0f), 360.0f) - 180.0f;
	return fmodf(a + t * wrappedDiff + 360.0f, 360.0f);
}

static void add_source(float* restrict x, float* restrict s, float dt)
{
	int i;
	for (i = 0; i < SIZE; i++) x[i] += dt * s[i];
}

static void set_bnd(int b, float* x)
{
	//Uncomment the values to have walls that reflect the fluid around the edge of the grid.
	//Right now it just has the fluid disappear at the edges.
	int i;
	for (i = 1; i <= ESIZE; i++) {

		x[IX(0, i)] = 0;// b == 1 ? -x[IX(1, i)] : x[IX(1, i)];
		x[IX(ESIZE + 1, i)] = 0;// b == 1 ? -x[IX(ESIZE, i)] : x[IX(ESIZE, i)];
		x[IX(i, 0)] = 0.f;//b == 2 ? -x[IX(i, 1)] : x[IX(i, 1)];
		x[IX(i, ESIZE + 1)] = 0;//b == 2 ? -x[IX(i, ESIZE)] : x[IX(i, ESIZE)];
	}
	x[IX(0, 0)] = 0;// 0.5f * (x[IX(1, 0)] + x[IX(0, 1)]);
	x[IX(0, ESIZE + 1)] = 0;// 0.5f * (x[IX(1, ESIZE + 1)] + x[IX(0, ESIZE)]);
	x[IX(ESIZE + 1, 0)] = 0;//0.5f * (x[IX(ESIZE, 0)] + x[IX(ESIZE + 1, 1)]);
	x[IX(ESIZE + 1, ESIZE + 1)] = 0;// 0.5f * (x[IX(ESIZE, ESIZE + 1)] + x[IX(ESIZE + 1, ESIZE)]);
}

static void diffuse(int b, float* restrict x, float* restrict x0, float diff, float dt)
{
	// Gauss-Seidel relaxation
	int i, j, k;
	float a = dt * diff * ESIZE * ESIZE;
	float lossFactor = 1.f / (1.f + 4.f * a);
	for (k = 0; k < 2; k++) { //Default 20, 1 is cheating!
		for (i = 1; i <= ESIZE; i++) {
			for (j = 1; j <= ESIZE; j++) {
				x[IX(i, j)] = (x0[IX(i, j)] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] +
					x[IX(i, j - 1)] + x[IX(i, j + 1)])) * lossFactor;
			}
		}
		set_bnd(b, x);
	}
}

static void advect(int b, float* restrict d, float* restrict d0, float* restrict u, float* restrict v, float dt)
{
	int i, j, i0, j0, i1, j1;
	float x, y, s0, t0, s1, t1, dt0;
	dt0 = dt * ESIZE;

	// Calculate the advection of density
	for (i = 1; i <= ESIZE; i++) {
		for (j = 1; j <= ESIZE; j++) {
			x = i - dt0 * u[IX(i, j)];
			y = j - dt0 * v[IX(i, j)];

			// Clamp the values of x and y
			if (x < 0.5f) {
				x = 0.5f;
			}
			if (x > ESIZE + 0.5f) {
				x = ESIZE + 0.5f;
			}
			if (y < 0.5f) {
				y = 0.5f;
			}
			if (y > ESIZE + 0.5f) {
				y = ESIZE + 0.5f;
			}

			// Calculate the indices
			i0 = (int)x;
			i1 = i0 + 1;
			j0 = (int)y;
			j1 = j0 + 1;

			// Calculate the interpolation factors
			s1 = x - i0;
			s0 = 1 - s1;
			t1 = y - j0;
			t0 = 1 - t1;

			// Perform bilinear interpolation to calculate the density
			d[IX(i, j)] = s0 * (t0 * d0[IX(i0, j0)] + t1 * d0[IX(i0, j1)]) +
				s1 * (t0 * d0[IX(i1, j0)] + t1 * d0[IX(i1, j1)]);
		}
	}
	set_bnd(b, d);
}

static void project(float* restrict u, float* restrict v, float* restrict p, float* restrict div)
{
	int i, j, k;
	float h = 1.0f / ESIZE;
	for (i = 1; i <= ESIZE; i++) {
		for (j = 1; j <= ESIZE; j++) {
			div[IX(i, j)] = -0.5f * h * (u[IX(i + 1, j)] - u[IX(i - 1, j)] +
				v[IX(i, j + 1)] - v[IX(i, j - 1)]);
			p[IX(i, j)] = 0;
		}
	}
	set_bnd(0, div); set_bnd(0, p);
	for (k = 0; k < 2; k++) { //20 default
		for (i = 1; i <= ESIZE; i++) {
			for (j = 1; j <= ESIZE; j++) {
				p[IX(i, j)] = (div[IX(i, j)] + p[IX(i - 1, j)] + p[IX(i + 1, j)] +
					p[IX(i, j - 1)] + p[IX(i, j + 1)]) * 0.25f;
			}
		}
		set_bnd(0, p);
	}
	for (i = 1; i <= ESIZE; i++) {
		for (j = 1; j <= ESIZE; j++) {
			u[IX(i, j)] -= 0.5f * (p[IX(i + 1, j)] - p[IX(i - 1, j)]) / h;
			v[IX(i, j)] -= 0.5f * (p[IX(i, j + 1)] - p[IX(i, j - 1)]) / h;
		}
	}
	set_bnd(1, u); set_bnd(2, v);
}

//Relic of proper flame simulation
static void buoyancy(float* restrict v, float* restrict t, float dt)
{
	int i, j;
	float a = dt * BUOY * ESIZE;
	for (i = 1; i <= ESIZE; i++) {
		for (j = 1; j <= ESIZE; j++) {
			v[IX(i, j)] -= a * t[IX(i, j)];
		}
	}
}

//Relic of proper flame simulation
static void cooling(float* t, float dt)
{
	int i, j;
	float a = dt * COOL * ESIZE;
	for (i = 1; i <= ESIZE; i++) {
		for (j = 1; j <= ESIZE; j++) {
			t[IX(i, j)] -= a * t[IX(i, j)];
		}
	}
}

static void dens_step(float* restrict x, float* restrict x0, float* restrict u, float* restrict v, float diff, float dt)
{
	add_source(x, x0, dt);
	SWAP(x0, x); diffuse(0, x, x0, diff, dt);
	SWAP(x0, x); advect(0, x, x0, u, v, dt);
}

static void vel_step(float* restrict u, float* restrict v, float* restrict u0, float* restrict v0, float visc, float dt)
{
	add_source(u, u0, dt); add_source(v, v0, dt);
	SWAP(u0, u); diffuse(1, u, u0, visc, dt);
	SWAP(v0, v); diffuse(2, v, v0, visc, dt);
	//project(u, v, u0, v0);
	SWAP(u0, u); SWAP(v0, v);
	advect(1, u, u0, u0, v0, dt); advect(2, v, v0, u0, v0, dt);
	project(u, v, u0, v0);
}


//All this noise crap is for filling up different arrays with test values.
#pragma region Noise

//from https://stackoverflow.com/questions/16569660/2d-perlin-noise-in-c
static float noise(int x, int y) {
	int n;

	n = x + y * 57;
	n = (n << 13) ^ n;
	return (1.0f - ((n * ((n * n * 15731) + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0f);
}
//from https://stackoverflow.com/questions/16569660/2d-perlin-noise-in-c
static float       interpolate(float a, float b, float x)
{
	float     pi_mod;
	float     f_unk;

	pi_mod = x * 3.1415927f;
	f_unk = (1 - cosf(pi_mod)) * 0.5f;
	return (a * (1 - f_unk) + b * x);
}

//from https://stackoverflow.com/questions/16569660/2d-perlin-noise-in-c
static float       smooth_noise(int x, int y)
{
	float     corners;
	float     center;
	float     sides;

	corners = (noise(x - 1, y - 1) + noise(x + 1, y - 1) +
		noise(x - 1, x + 1) + noise(x + 1, y + 1)) / 16;
	sides = (noise(x - 1, y) + noise(x + 1, y) + noise(x, y - 1) +
		noise(x, y + 1)) / 8;
	center = noise(x, y) / 4;
	return (corners + sides + center);
}

//from https://stackoverflow.com/questions/16569660/2d-perlin-noise-in-c
static float       noise_handler(float x, float y)
{
	int       int_val[2];
	float     frac_val[2];
	float     value[4];
	float     res[2];

	int_val[0] = (int)x;
	int_val[1] = (int)y;
	frac_val[0] = x - int_val[0];
	frac_val[1] = y - int_val[1];
	value[0] = smooth_noise(int_val[0], int_val[1]);
	value[1] = smooth_noise(int_val[0] + 1, int_val[1]);
	value[2] = smooth_noise(int_val[0], int_val[1] + 1);
	value[3] = smooth_noise(int_val[0] + 1, int_val[1] + 1);
	res[0] = interpolate(value[0], value[1], frac_val[0]);
	res[1] = interpolate(value[2], value[3], frac_val[0]);
	return (interpolate(res[0], res[1], frac_val[1]));
}

//from https://stackoverflow.com/questions/16569660/2d-perlin-noise-in-c
static float perlin_two(float x, float y, float gain, int octaves, int hgrid) {
	int i;
	float total = 0.0f;
	float frequency = 1.0f / (float)hgrid;
	float amplitude = gain;
	float lacunarity = 2.0;

	for (i = 0; i < octaves; ++i)
	{
		total += noise_handler((float)x * frequency, (float)y * frequency) * amplitude;
		frequency *= lacunarity;
		amplitude *= gain;
	}

	return (total);
}
#pragma endregion


static float dither_matrix8x8[8][8] = {
	{0, 0.50f, 0.13f, 0.63f, 0.31f, 0.81f, 0.19f, 0.69f},
	{0.75f, 0.25f, 0.88f, 0.38f, 0.94f, 0.44f, 0.81f, 0.31f},
	{0.19f, 0.69f, 0.06f, 0.56f, 0.25f, 0.75f, 0.13f, 0.63f},
	{0.94f, 0.44f, 0.81f, 0.31f, 0.75f, 0.25f, 0.88f, 0.38f},
	{0.31f, 0.81f, 0.19f, 0.69f, 0.00f, 0.50f, 0.13f, 0.63f},
	{0.75f, 0.25f, 0.88f, 0.38f, 0.94f, 0.44f, 0.81f, 0.31f},
	{0.19f, 0.69f, 0.06f, 0.56f, 0.25f, 0.75f, 0.13f, 0.63f},
	{0.94f, 0.44f, 0.81f, 0.31f, 0.75f, 0.25f, 0.88f, 0.38f} };

//This is here from ages past, maybe it could help somewhere in the future, but I highly doubt it.
static float bilinear_interpolate(float* density, float x, float y) {
	int x0 = (int)x;
	int x1 = x0 + 1;
	int y0 = (int)y;
	int y1 = y0 + 1;

	//if (x1 >= ESIZE) x1 = ESIZE - 1;
	//if (y1 >= ESIZE) y1 = ESIZE - 1;

	float q11 = density[IX(x0, y0)];
	float q21 = density[IX(x1, y0)];
	float q12 = density[IX(x0, y1)];
	float q22 = density[IX(x1, y1)];

	float tx = x - x0;
	float ty = y - y0;

	float q1 = (1 - tx) * q11 + tx * q21;
	float q2 = (1 - tx) * q12 + tx * q22;
	float q = (1 - ty) * q1 + ty * q2;

	return q;
}

static void render(int xOffset, int yOffset) {
	for (int j = yOffset; j < renderSizeY + yOffset; j++) {
		for (int i = xOffset; i < renderSizeX + xOffset; i += 8) {
			uint8_t column = 0;
			float xRatio = (float)(ESIZE) / (renderSizeX);
			float yRatio = (float)(ESIZE) / (renderSizeY);
			int x = ((i - xOffset) * xRatio) + 1;
			int y = ((j - yOffset) * yRatio) + 1;
			int x8 = ((i + 8 - xOffset) * xRatio) + 1; //Pre-calculate the next x value one byte ahead

			if (dens[IX(x, y)] > 1.3f && dens[IX(x8, y)] > 1.3f) {

				//8 bits will be black, so ignore

			}
			else if (dens[IX(x, y)] <= 0.25f && dens[IX(x8, y)] < 0.25f) {
				//8 bits will be clear, so ignore
				//column = UINT8_MAX;
				continue;
			}
			else
			{
				float x2 = x8;
				for (int k = 0; k < 8; k++) {
					x2 -= xRatio;
					float density_value = dens[IX((int)x2, (int)y)];
					uint8_t dither_value = (density_value < dither_matrix8x8[j % 8][k]) && ((renderBuffer[(j * 52) + (i / 8)] & (1 << k)));
					column |= (dither_value << k);
				}
			}
			renderBuffer[(j * 52) + (i / 8)] = column;
		}
	}

}

static int fluid_update(lua_State* L) {

	PDButtons buttonStatesDown;
	PDButtons buttonStatesPushed;
	PDButtons buttonStatesReleased;
	pd->system->getButtonState(&buttonStatesDown, &buttonStatesPushed, &buttonStatesReleased);

	//If we're in simulation mode, update the fire strength based on the crank angle
	//Else, move the source position based on the crank angle
	if (simState) {
		float crankChange = pd->system->getCrankChange();

		fireStrength += crankChange / 360.f;
	}
	else {
		//fireStrength = 0.4f;
		crankAngle = lerp(crankAngle, pd->system->getCrankAngle(), 0.15f); //Lerp to smooth movement.
		float crank = crankAngle - 90;
		crank = crank * 3.14159f / 180.f;
		sourcePosX = (cosf(crank) * (ESIZE / 2.25f));
		sourcePosY = (sinf(crank) * (ESIZE / 2.25f));
		sourceVelX = (cosf(crank) * 0.5f);
		sourceVelY = (sinf(crank) * 0.5f);
	}
	const float constDens = 0.85f * fireStrength;// 0.125f * (ESIZE / 30.f);
	const float constVel = 3.95f;//0.15f * (ESIZE / 30.f);

	int area = ESIZE / 6;

	for (int i = ESIZE / 2 - (area / 2); i < ESIZE / 2 + (area / 2); i++) {
		for (int j = ESIZE / 2 - (area / 2); j < ESIZE / 2 + (area / 2); j++) {
			dens[IX(sourcePosX + i, sourcePosY + j)] += constDens;
			u[IX(sourcePosX + i, sourcePosY + j)] -= sourceVelX * constVel;
			v[IX(sourcePosX + i, sourcePosY + j)] -= sourceVelY * constVel;
		}
	}

	//int area = ESIZE / 4;
	float velPower = 0.9f;
	float densPower = 0.05f;
	float fuelPower = 6.5f;
	if (buttonStatesDown & kButtonUp) {
		for (int x = ESIZE / 2 - (area / 2); x < ESIZE / 2 + (area / 2); x++) {
			for (int y = ESIZE / 2 - (area / 2); y < ESIZE / 2 + (area / 2); y++) {
				v[IX(x, y)] -= velPower;

				dens_fuel[IX(x, y)] += fuelPower;
			}
		}
	}
	if (buttonStatesDown & kButtonDown) {
		for (int x = ESIZE / 2 - (area / 2); x < ESIZE / 2 + (area / 2); x++) {
			for (int y = ESIZE / 2 - (area / 2); y < ESIZE / 2 + (area / 2); y++) {
				v[IX(x, y)] += velPower;

				dens_fuel[IX(x, y)] += fuelPower;
			}
		}
	}
	if (buttonStatesDown & kButtonLeft) {
		for (int x = ESIZE / 2 - (area / 2); x < ESIZE / 2 + (area / 2); x++) {
			for (int y = ESIZE / 2 - (area / 2); y < ESIZE / 2 + (area / 2); y++) {
				u[IX(x, y)] -= velPower;

				dens_fuel[IX(x, y)] += fuelPower;
			}
		}
	}
	if (buttonStatesDown & kButtonRight) {
		for (int x = ESIZE / 2 - (area / 2); x < ESIZE / 2 + (area / 2); x++) {
			for (int y = ESIZE / 2 - (area / 2); y < ESIZE / 2 + (area / 2); y++) {
				u[IX(x, y)] += velPower;

				dens_fuel[IX(x, y)] += fuelPower;
			}
		}
	}

	for (size_t i = 0; i < STEPS; i++)
	{
		vel_step(u, v, u_prev, v_prev, VISC, DT);
		//cooling(temp, DT);
		//add_source(temp, dens_fuel, DT);
		//buoyancy(v, temp, DT);
		//add_source(temp, dens_fuel, DT);
		//dens_step(temp, dens_fuel, u, v, DIFF, DT);
		dens_step(dens, dens_fuel, u, v, DIFF, DT);
	}
	int i, j;

	//pd->graphics->pushContext(NULL);
	//pd->graphics->setDrawOffset(150, 0);
	//pd->graphics->setScreenClipRect(xOffset, yOffset, renderSizeX, renderSizeY);

	//pd->graphics->clear(kColorWhite);
	uint8_t* frameBuffer = pd->graphics->getFrame();

	int ingredientPosX = 200 - (iWidth / 2);
	int ingredientPosY = 120 - (iHeight / 2);
	pd->graphics->drawBitmap(ingredientBitmap, ingredientPosX, ingredientPosY, 0);

	//memset(renderBuffer, UINT8_MAX, 52 * 240);
	memcpy(renderBuffer, frameBuffer, 52 * 240); //I'm assuming I had a reason to use my own render buffer instead of the frame buffer, but I can't remember why.

	render(xOffset, yOffset);

	memcpy(frameBuffer, renderBuffer, 52 * 240);

	//Apply collision between the fluid and the ingredient bitmap. Check for overlapping pixels on the bitmap and the render buffer
	for (int i = 0; i < iWidth; i++) {
		for (int j = 0; j < iHeight; j++) {
			int x = RENDER_TO_SIM(i + ingredientPosX, renderSizeX);
			int y = RENDER_TO_SIMY(j + ingredientPosY, renderSizeY);

			//If the cell is taken on the mask, set velocity to 0
			if (iMask[(j * iRowBytes) + (i / 8)] & ~frameBuffer[((j + ingredientPosY) * 52) + ((i + ingredientPosX) / 8)]) {

				u[IX(x+1, y+1)] = 0.f;
				v[IX(x+1, y+1)] = 0.f;
			}
		}
	}



	pd->sprite->addDirtyRect(LCDMakeRect(xOffset, yOffset, renderSizeX, renderSizeY));
	pd->graphics->markUpdatedRows(0, 200); //You could probably calculate what rows need updating, but for now this is fine.
	//pd->graphics->setScreenClipRect(0, 0, 400, 240);
	//pd->system->drawFPS(0, 0);
	//pd->graphics->popContext();

	memset(u_prev, 0, sizeof(float) * SIZE);
	memset(v_prev, 0, sizeof(float) * SIZE);
	memset(dens_fuel, 0, sizeof(float) * SIZE);
	return 0;
}
static int fluid_initialise(lua_State* L) {

	//pd->display->setRefreshRate(30);
	u = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	v = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	u_prev = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	v_prev = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	dens = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	dens_fuel = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	renderBuffer = (uint8_t*)pd->system->realloc(NULL, 52 * 240);
	ingredientBitmap = pd->lua->getBitmap(1);

	pd->graphics->getBitmapData(ingredientBitmap, &iWidth, &iHeight, &iRowBytes, &iMask, &iData);

	memset(u, 0, sizeof(float) * SIZE);
	memset(v, 0, sizeof(float) * SIZE);
	memset(u_prev, 0, sizeof(float) * SIZE);
	memset(v_prev, 0, sizeof(float) * SIZE);
	memset(dens, 0, sizeof(float) * SIZE);
	memset(dens_fuel, 0, sizeof(float) * SIZE);

	return 0;
}

static int fluid_reinitialise(lua_State* L) {

	pd->graphics->clear(kColorWhite);

	memset(u, 0, sizeof(float) * SIZE);
	memset(v, 0, sizeof(float) * SIZE);
	memset(u_prev, 0, sizeof(float) * SIZE);
	memset(v_prev, 0, sizeof(float) * SIZE);
	memset(dens, 0, sizeof(float) * SIZE);
	memset(dens_fuel, 0, sizeof(float) * SIZE);

	//Log all args coming in using getArgCount and getArgType
	pd->system->logToConsole("Args: %i", pd->lua->getArgCount());
	//for (int i = 1; i < pd->lua->getArgCount()+1; i++) {
	//	char* outClass;
	//	enum LuaType type = pd->lua->getArgType(2, &outClass);
	//	pd->system->logToConsole("Arg %i: %s", i, outClass);

	//}



	int oldSize = ESIZE;
	ESIZE = pd->lua->getArgInt(1);
	interp = pd->lua->getArgInt(2);
	renderSizeX = pd->lua->getArgInt(3);
	renderSizeY = pd->lua->getArgInt(4);
	SIZE = (ESIZE + 2) * (ESIZE + 2);
	pd->system->logToConsole("Args retrieved");

	if (oldSize < ESIZE) {
		pd->system->logToConsole("Reallocating memory");
		u = pd->system->realloc(u, sizeof(float) * SIZE);
		v = pd->system->realloc(v, sizeof(float) * SIZE);
		u_prev = pd->system->realloc(u_prev, sizeof(float) * SIZE);
		v_prev = pd->system->realloc(v_prev, sizeof(float) * SIZE);
		dens = pd->system->realloc(dens, sizeof(float) * SIZE);
		dens_fuel = pd->system->realloc(dens_fuel, sizeof(float) * SIZE);

		memset(u, 0, sizeof(float) * SIZE);
		memset(v, 0, sizeof(float) * SIZE);
		memset(u_prev, 0, sizeof(float) * SIZE);
		memset(v_prev, 0, sizeof(float) * SIZE);
		memset(dens, 0, sizeof(float) * SIZE);
		memset(dens_fuel, 0, sizeof(float) * SIZE);
	}


	//nullptr check
	if (u == NULL || v == NULL || u_prev == NULL || v_prev == NULL || dens == NULL || dens_fuel == NULL ) {
		pd->system->error("Failed to reallocate memory");
		pd->system->logToConsole("bleh");
		return 0;
	}
	return 0;
}

static int fluid_addSource(lua_State* L) {

	const float amountScale = 0.2f;
	float amount = pd->lua->getArgFloat(1) * amountScale;
	int x = pd->lua->getArgFloat(2) * ESIZE;
	int y = ESIZE - (pd->lua->getArgFloat(3) * ESIZE / 1.f);
	//dens_fuel[IX(x, y)] += amount;
	//v[IX(x, y)] -= 0.05f;
	for (size_t i = 0; i < SOURCE_SQUARE_SIZE; i++)
	{
		for (size_t j = 0; j < SOURCE_SQUARE_SIZE; j++)
		{

			//v[IX(i + x, j + y)] += amount-0.5f;
			u[IX(i + x, j + y)] += amount - (amountScale / 2.f);
		}
	}

	return 0;
}

static int fluid_flipState(lua_State* L) {

	simState = ~simState;

	return 0;
}

static int fluid_setTargetPosition(lua_State* L) {

	//targetPosX = pd->lua->getArgFloat(1);
	//targetPosY = pd->lua->getArgFloat(2);
	return 0;
}

int registerFluid(PlaydateAPI* playdate)
{
	pd = playdate;
	//fluid_initialise(NULL);
	playdate->system->logToConsole("%s:%i: gorp", __FILE__, __LINE__);
	const char* err;
	if (!pd->lua->registerClass("fluid", fluid, NULL, 0, &err)) {
		pd->system->error("%s:%i: addFunction failed, %s", __FILE__, __LINE__, err);
	}
	return 0;
}
