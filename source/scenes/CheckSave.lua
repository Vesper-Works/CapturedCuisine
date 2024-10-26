import "CoreLibs/timer"
CheckSave = {}
class("CheckSave").extends(NobleScene)
local scene = CheckSave
local pd = playdate
local gameSaved = true
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
	self.color2 = Graphics.kColorWhite
    Noble.Text.setFont(Noble.Text.FONT_SMALL)
end
function scene:init()
    scene.super.init(self)
end
function scene:start()
    if gameSaved == false then
        scene.loadGame(self)
    end
end
function scene:update() -- this code should only need to run if a saved game is found, adapt later
    if gameSaved == true then
        scene.super.update(self)
        Noble.Text.draw("Are you sure you want to start a new game?", 200, 100, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_LARGE)
        Noble.Text.draw("This will overwrite your current progress!", 200, 120, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_LARGE)
        Noble.Text.draw("Press A to Continue. \n Press B to go back to main menu.", 200, 150, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_SMALL)
        if pd.buttonIsPressed(pd.kButtonB) then
            scene.exit(self)
        elseif(pd.buttonIsPressed(pd.kButtonA)) then
            scene.loadGame(self)
        end
    else
        scene.loadGame(self)
    end
end
function scene:loadGame() 
    Noble.Text.draw("Loading game...", 80, 120)
    Noble.transition(CinematicScene, nil, Noble.Transition.CrossDissolve)
end
function scene:exit() 
    Noble.transition(MainMenuGrid, nil, Noble.Transition.DipToBlack)
end
