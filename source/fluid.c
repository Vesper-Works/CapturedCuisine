#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define N 30  // Grid size
#define STEPS 1.f  // Number of simulation steps
#define DT 0.02f  // Time step
#define DIFF 0.001f  // Diffusion rate
#define VISC 0.00001f  // Viscosity
#define COOL 0.001f   // Cooling rate
#define BURN 0.1f  // Burning rate
#define BUOY 0.5f  // Buoyancy

static int ESIZE = N;
// Utility macros
#define IX(i, j) ((i) + (ESIZE + 2) * (j))
#define SWAP(x0,x) {float* tmp=x0;x0=x;x=tmp;}
#define RENDER_TO_SIM(x, size) (x - xOffset) * (ESIZE - 1) / (size - 1) + 1

#include "pd_api.h"
#include "fluid.h"

//http://graphics.cs.cmu.edu/nsp/course/15-464/Spring11/papers/StamFluidforGames.pdf

static int SIZE = (N + 2) * (N + 2);  // Grid size including boundary
static float* u, * v, * u_prev, * v_prev;
static float* dens, * dens_fuel;
static float* temp;
uint8_t* renderBuffer;
static int interp = 0;
static int renderSizeX = 200, renderSizeY = 200;
static PlaydateAPI* pd = NULL;
static int fluid_update(lua_State* L);
static int fluid_initialise(lua_State* L);
static int fluid_reinitialise(lua_State* L);


const lua_reg fluid[] =
{
	{ "update",			fluid_update },
	{ "initialise",		fluid_initialise },
	{ "reinitialise",   fluid_reinitialise },
	{ NULL,				NULL }
};

static void add_source(float* x, float* s, float dt)
{
	int i;
	for (i = 0; i < SIZE; i++) x[i] += dt * s[i];
}

static void set_bnd(int b, float* x)
{
	return;
	int i;
	for (i = 1; i <= ESIZE; i++) {
		x[IX(0, i)] = b == 1 ? -x[IX(1, i)] : x[IX(1, i)];
		x[IX(ESIZE + 1, i)] = b == 1 ? -x[IX(ESIZE, i)] : x[IX(ESIZE, i)];
		x[IX(i, 0)] = b == 2 ? -x[IX(i, 1)] : x[IX(i, 1)];
		x[IX(i, ESIZE + 1)] = b == 2 ? -x[IX(i, ESIZE)] : x[IX(i, ESIZE)];
	}
	x[IX(0, 0)] = 0.5f * (x[IX(1, 0)] + x[IX(0, 1)]);
	x[IX(0, ESIZE + 1)] = 0.5f * (x[IX(1, ESIZE + 1)] + x[IX(0, ESIZE)]);
	x[IX(ESIZE + 1, 0)] = 0.5f * (x[IX(ESIZE, 0)] + x[IX(ESIZE + 1, 1)]);
	x[IX(ESIZE + 1, ESIZE + 1)] = 0.5f * (x[IX(ESIZE, ESIZE + 1)] + x[IX(ESIZE + 1, ESIZE)]);
}

static void diffuse(int b, float* x, float* x0, float diff, float dt)
{
	// Gauss-Seidel relaxation
	int i, j, k;
	float a = dt * diff * ESIZE * ESIZE;
	float lossFactor = 1.f / (1.f + 4.f * a);
	for (k = 0; k < 1; k++) { //Default 20, 1 is cheating!
		for (i = 1; i <= ESIZE; i++) {
			for (j = 1; j <= ESIZE; j++) {
				x[IX(i, j)] = (x0[IX(i, j)] + a * (x[IX(i - 1, j)] + x[IX(i + 1, j)] +
					x[IX(i, j - 1)] + x[IX(i, j + 1)])) * lossFactor;
			}
		}
		set_bnd(b, x);
	}
}

static void advect(int b, float* d, float* d0, float* u, float* v, float dt)
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

static void project(float* u, float* v, float* p, float* div)
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
	for (k = 0; k < 4; k++) { //20 default
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

static void buoyancy(float* v, float* t, float dt)
{
	int i, j;
	float a = dt * BUOY * ESIZE;
	for (i = 1; i <= ESIZE; i++) {
		for (j = 1; j <= ESIZE; j++) {
			v[IX(i, j)] -= a * t[IX(i, j)];
		}
	}
}

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

static void dens_step(float* x, float* x0, float* u, float* v, float diff, float dt)
{
	add_source(x, x0, dt);
	SWAP(x0, x); diffuse(0, x, x0, diff, dt);
	SWAP(x0, x); advect(0, x, x0, u, v, dt);
}

static void vel_step(float* u, float* v, float* u0, float* v0,
	float visc, float dt)
{
	add_source(u, u0, dt); add_source(v, v0, dt);
	SWAP(u0, u); diffuse(1, u, u0, visc, dt);
	SWAP(v0, v); diffuse(2, v, v0, visc, dt);
	//project(u, v, u0, v0);
	SWAP(u0, u); SWAP(v0, v);
	advect(1, u, u0, u0, v0, dt); advect(2, v, v0, u0, v0, dt);
	project(u, v, u0, v0);
}



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

void render(int xOffset, int yOffset) {
	for (int j = yOffset; j < renderSizeY + yOffset; j++) {
		for (int i = xOffset; i < renderSizeX + xOffset; i += 8) {
			uint8_t column = 0;
			float xRatio = (float)(ESIZE) / (renderSizeX);
			float yRatio = (float)(ESIZE) / (renderSizeY);
			int x = ((i - xOffset) * xRatio) + 1;
			int y = ((j - yOffset) * yRatio) + 1;
			int x8 = ((i + 8 - xOffset) * xRatio) + 1;

			if (dens[IX(x, y)] > 1.3f && dens[IX(x8, y)] > 1.3f) {
				//8 bits will be black, so ignore

			}
			else if (dens[IX(x, y)] <= 0.25f && dens[IX(x8, y)] < 0.25f) {
				//8 bits will be clear, so ignore
				continue;
			}
			else
			{
				float x2 = x8;
				for (int k = 0; k < 8; k++) {
					x2 -= xRatio;
					float density_value = dens[IX((int)x2, (int)y)];
					uint8_t dither_value = (density_value < dither_matrix8x8[j % 8][k]);
					column |= (dither_value << k);
				}
			}
			renderBuffer[(j * 52) + (i / 8)] = column;
		}
	}

}

static int fluid_update(lua_State* L) {

	memset(u_prev, 0, sizeof(float) * SIZE);
	memset(v_prev, 0, sizeof(float) * SIZE);
	memset(dens_fuel, 0, sizeof(float) * SIZE);

	PDButtons buttonStatesDown;
	PDButtons buttonStatesPushed;
	PDButtons buttonStatesReleased;
	pd->system->getButtonState(&buttonStatesDown, &buttonStatesPushed, &buttonStatesReleased);
	//Based on the up/down/left/right d-pad buttons, add velocity and density to a 20 x 20 area in the center of the grid, velocity pointing in diretion of Dpad
	int constArea = ESIZE / 3;
	float constDens = 0.125f * (ESIZE / 30.f);
	float constVel = 0.15f * (ESIZE / 30.f);

	for (int x = ESIZE / 2 - constArea; x < ESIZE / 2 - (constArea / 4.f); x++) {
		for (int y = ESIZE - 10; y < ESIZE; y++) {
			dens[IX(x, y)] += constDens;
			v[IX(x, y)] -= constVel;
		}
	}
	for (int x = ESIZE / 2 + (constArea / 4); x < ESIZE / 2 + constArea; x++) {
		for (int y = ESIZE - 10; y < ESIZE; y++) {
			dens[IX(x, y)] += constDens;
			v[IX(x, y)] -= constVel;

		}
	}
	for (int x = ESIZE / 2 - (constArea / 8); x < ESIZE / 2 + (constArea / 8); x++) {
		for (int y = ESIZE - 10; y < ESIZE; y++) {
			dens[IX(x, y)] += constDens;
			v[IX(x, y)] -= constVel;

		}
	}
	int area = ESIZE / 4;
	float velPower = 0.5f;
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
	const int xOffset = 0;
	const int yOffset = 0;
	//pd->graphics->pushContext(NULL);
	//pd->graphics->setDrawOffset(150, 0);
	pd->graphics->setScreenClipRect(xOffset, yOffset, renderSizeX, renderSizeY);

	//pd->graphics->clear(kColorWhite);
	uint8_t* frameBuffer = pd->graphics->getFrame();

	//memset(frameBuffer, 255, 52 * 240);
	memset(renderBuffer, UINT8_MAX, 52 * 240);
	render(xOffset, yOffset);

	memcpy(frameBuffer, renderBuffer, 52 * 240);


	//for (i = yOffset; i < renderSizeY + yOffset; i++) {
	//	for (j = xOffset; j < renderSizeX + xOffset; j++) {
	//		// Map the coordinates to the original density field with interpolation
	//		float x = (float)(j - xOffset) * (ESIZE - 1) / (renderSizeX - 1) + 1;
	//		float y = (float)(i - yOffset) * (ESIZE - 1) / (renderSizeY - 1) + 1;
	//		float density_value = 0;
	//		if (interp) {
	//			density_value = bilinear_interpolate(dens, x, y);
	//		}
	//		else {
	//			density_value = dens[IX((int)x, (int)y)];
	//		}
	//		//float grad  = compute_gradient(dens, ESIZE + 2, ESIZE + 2, (int)x, (int)y);

	//		// Determine the corresponding dither matrix value
	//		float dither_value = dither_matrix8x8[i % 8][j % 8];

	//		//if (density_value > dither_value + 0.25f) {
	//			//setPixelRow(frameBuffer, j, shift?i:i+1, ~dither_pattern_lookup[3-(int)(density_value/10.f)][(int)((grad+1) * 4.5f)]);
	//		//}


	//		// Apply the dither and print the pixel
	//		if (density_value > 1.4f) {// && dens[IX((int)x+1, (int)y)] > 1.4f && dens[IX((int)x - 1, (int)y)] > 1.4f) {
	//			setPixelRow(frameBuffer, j, i, 0b00000000);
	//			j += 7 - (j % 8);
	//		}
	//		else if (density_value > dither_value + 0.25f) {
	//			setPixel(frameBuffer, j, i, 0);
	//			//pd->graphics->setPixel(j, i, kColorBlack);
	//		}
	//	}
	//}
	pd->graphics->markUpdatedRows(yOffset, yOffset + renderSizeY);
	pd->graphics->setScreenClipRect(0, 0, 400, 240);
	pd->system->drawFPS(0, 0);
	//pd->graphics->popContext();
	return 0;
}
static int fluid_initialise(lua_State* L) {

	pd->display->setRefreshRate(30);
	u = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	v = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	u_prev = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	v_prev = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	dens = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	dens_fuel = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	temp = (float*)pd->system->realloc(NULL, sizeof(float) * SIZE);
	renderBuffer = (uint8_t*)pd->system->realloc(NULL, 52 * 240);

	memset(u, 0, sizeof(float) * SIZE);
	memset(v, 0, sizeof(float) * SIZE);
	memset(u_prev, 0, sizeof(float) * SIZE);
	memset(v_prev, 0, sizeof(float) * SIZE);
	memset(dens, 0, sizeof(float) * SIZE);
	memset(dens_fuel, 0, sizeof(float) * SIZE);
	memset(temp, 0, sizeof(float) * SIZE);

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
	memset(temp, 0, sizeof(float) * SIZE);

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
		temp = pd->system->realloc(temp, sizeof(float) * SIZE);

		memset(u, 0, sizeof(float) * SIZE);
		memset(v, 0, sizeof(float) * SIZE);
		memset(u_prev, 0, sizeof(float) * SIZE);
		memset(v_prev, 0, sizeof(float) * SIZE);
		memset(dens, 0, sizeof(float) * SIZE);
		memset(dens_fuel, 0, sizeof(float) * SIZE);
		memset(temp, 0, sizeof(float) * SIZE);
	}


	//nullptr check
	if (u == NULL || v == NULL || u_prev == NULL || v_prev == NULL || dens == NULL || dens_fuel == NULL || temp == NULL) {
		pd->system->error("Failed to reallocate memory");
		pd->system->logToConsole("bleh");
		return 0;
	}
	return 0;
}

int registerFluid(PlaydateAPI* playdate)
{
	pd = playdate;
	fluid_initialise(NULL);
	playdate->system->logToConsole("%s:%i: gorp", __FILE__, __LINE__);
	const char* err;
	if (!pd->lua->registerClass("fluid", fluid, NULL, 0, &err)) {
		pd->system->error("%s:%i: addFunction failed, %s", __FILE__, __LINE__, err);
	}
	return 0;
}
