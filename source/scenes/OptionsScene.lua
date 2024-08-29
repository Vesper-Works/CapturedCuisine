OptionsScene = {}
class("OptionsScene").extends(NobleScene)
local scene = OptionsScene
local pd = playdate
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    self.sceneText = "Options Scene"
    Noble.Text.setFont(Noble.Text.FONT_LARGE)
end

function scene:init()
    scene.super.init(self) --calls parent constructor
    self:setValues()
end
function scene:update()
    scene.super.update(self)
    Noble.Text.draw(self.sceneText, 200, 120, Noble.Text.ALIGN_CENTER, false, Noble.Text.getCurrentFont()) --it's possible this works but we may need a font asset
    if pd.buttonIsPressed(pd.kButtonB) then
        scene.exit(self)
    end
end
function scene:exit()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(MainMenu, nil, Noble.Transition.DipToBlack)
end