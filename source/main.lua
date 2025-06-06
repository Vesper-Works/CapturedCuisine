import 'libraries/noble/Noble'

import 'utilities/Utilities'
import 'scenes/ExampleScene'
import 'scenes/ExampleScene2'
import 'scenes/OpeningScene'
import 'scenes/MainMenu'
import 'scenes/BlankScene'
import 'scenes/CheckSave'
import 'scenes/CheckSave2'
import 'scenes/LoadSave'
import 'scenes/AgingScene'
import 'scenes/LaserMinigame'
import "CoreLibs/timer"
import "scenes/SweetTalking"
import "scenes/CrankScene"
import 'scenes/MainMenuGrid'
import 'scenes/CinematicScene'
import 'scenes/SplashScreenScene'
import 'scenes/OptionsScene'
import 'scenes/CutScene'
import "CoreLibs/timer"
import 'scenes/ResturauntScene'
import 'scenes/OrdersScene'
import 'scenes/PickIngredientScene'
import 'scenes/PlateScene'
import 'scenes/AlienEatScene'
import 'scenes/BossScene'
local pd = playdate
local gfx = pd.graphics
local mainMenuLoad = 3000 --should load after 3 seconds, change this pending on how long we wish the opening cinematic to be
local openingCinematic = true --consider if we want the opening cinematic to be skipped
Noble.Settings.setup({
	Difficulty = "Medium"
})

Noble.GameData.setup({
	Reputation = 0,
	Day = 0,
	Orders = {}, --allOrders from OrdersScene
	IngredientInfo = {} --IngredientHandler.ingrdients 
})
Noble.showFPS = false
--Noble.new(LaserMinigame)
--[[
Noble.showFPS = true
Noble.new(SplashScreenScene)
-]]
pd.timer.performAfterDelay(mainMenuLoad, function ()
	loadMainMenu() --second argument is a lambda where multiple functions can be passed in sequence
end)
function loadMainMenu()
	IngredientHandler.loadIngredients() --should load the ingredients themselves
	SplashScreenScene.exit() --running this seems to create the main.pdx folder which is unneeded, bear this in mind when creating 
	--Luke has the functionality of OpeningScene and Update in SplashScreenScene, check what this is doing
	--OpeningScene.exit() --running this seems to create the main.pdx folder which is unneeded, bear this in mind when creating
end
function update() 
	gfx.sprite.update()
	pd.timer.updateTimers()
	--IncredientTestScene.exit()
end
