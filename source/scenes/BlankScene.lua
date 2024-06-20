BlankScene = {}
class("BlankScene").extends(NobleScene)
local scene = BlankScene 
local pd = playdate
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
	self.color2 = Graphics.kColorWhite
    self.sceneText = "This is the template scene, replace this text with the required text later. Press B to exit"
    Noble.Text.setFont(Noble.Text.FONT_LARGE) 
end

function scene:init()
    scene.super.init(self) --calls parent constructor
    self:setValues()
    Noble.Text.draw(self.sceneText, 20, 20, Noble.Text.ALIGN_LEFT, false, Noble.Text.getCurrentFont()) --it's possible this works but we may need a font asset
end
function scene:update()
    scene.super.update(self)
    if pd.buttonIsPressed(pd.kButtonB) then
        scene.exit(self)
    end
end
function scene:exit()
    Noble.transition(MainMenu, nil, Noble.Transition.DipToBlack)
end