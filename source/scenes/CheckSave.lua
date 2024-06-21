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
    self.sceneText = "This is the template scene, replace this text with the required text later. Press B to exit"
    Noble.Text.setFont(Graphics.font.new("assets/fonts/Beastfont-Regular")) 
end
function scene:init() 
    scene.super.init(self)
    self.sceneText = "Are you sure you want to load the saved game? This will overwrite your progress"
end
function scene:start()
    if gameSaved == false then
        scene.loadGame(self)
    end
end
function scene:update() --this code should only need to run if a saved game is found, adapt later
    if gameSaved == true then
        scene.super.update(self)
        Noble.Text.draw(self.sceneText, 20, 20, Noble.Text.ALIGN_LEFT, false, Noble.Text.getCurrentFont()) 
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
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(BlankScene, nil, Noble.Transition.CrossDissolve)
end
function scene:exit() 
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(MainMenu, nil, Noble.Transition.DipToBlack)
end