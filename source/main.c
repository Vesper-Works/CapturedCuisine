
#include <stdio.h>
#include <stdlib.h>

#include "pd_api.h"
#include "fluid.h"

#ifdef _WINDLL
__declspec(dllexport)
#endif

//		Use this to build to device:
//		cmake .. -G "NMake Makefiles" --toolchain=%Playdate_SDK_PATH%/C_API/buildsupport/arm.cmake

int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg)
{
	if (event == kEventInitLua) {
		registerFluid(playdate);
	}
	return 0;
}
