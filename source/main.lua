import 'libraries/noble/Noble'

import 'utilities/Utilities'

import 'scenes/ExampleScene'
import 'scenes/ExampleScene2'
import 'scenes/OpeningScene'
import 'scenes/MainMenu'
import 'scenes/BlankScene'
import "CoreLibs/timer"
local pd = playdate
local mainMenuLoad = 3000 --should load after 3 seconds, change this pending on how long we wish the opening cinematic to be
local openingCinematic = true --consider if we want the opening cinematic to be skipped
Noble.Settings.setup({
	Difficulty = "Medium"
})

Noble.GameData.setup({
	Score = 0
})
Noble.showFPS = true
Noble.new(OpeningScene)
pd.timer.performAfterDelay(mainMenuLoad, function ()
	loadMainMenu() --second argument is a lambda where multiple functions can be passed in sequence
end)
function loadMainMenu() 
	OpeningScene.exit() --running this seems to create the main.pdx folder which is unneeded, bear this in mind when creating
end