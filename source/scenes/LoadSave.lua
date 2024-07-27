LoadSave = {}
class("LoadSave").extends(NobleScene)
local scene = LoadSave
local pd = playdate
local noSavedGame = true
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
	self.color2 = Graphics.kColorWhite
    self.sceneText = "This is the template scene, replace this text with the required text later. Press B to exit"
    Noble.Text.setFont(Graphics.font.new("assets/fonts/Beastfont-Regular")) 
end
function scene:init() 
    scene.super.init(self)
end
function scene:start() 
    if noSavedGame == true then
        self.sceneText = "No Saved Game available. Press B to Leave"
    else
        self.loadGame(self)
    end
end
function scene:update()
    scene.super.update(self)
    Noble.Text.draw(self.sceneText, 20, 20, Noble.Text.ALIGN_LEFT, false, Noble.Text.getCurrentFont()) 
    if pd.buttonIsPressed(pd.kButtonB) then
        scene.exit(self)
    end 
end
function scene:loadGame() 
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(ExampleScene2, nil, Noble.Transition.DipToBlack)
end
function scene:exit() 
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(MainMenuGrid, nil, Noble.Transition.DipToBlack)
end
