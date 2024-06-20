BlankScene = {}
class("BlankScene").extends(NobleScene)
local scene = BlankScene 
local pd = playdate
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
	self.color2 = Graphics.kColorWhite 
end

function scene:init()
    scene.super.init(self) --calls parent constructor
    self:setValues()
end
function scene:update()
    scene.super.update(self)
    if pd.buttonIsPressed(pd.kButtonB) then
        scene.exit(self)
    end
    --this should only transition back to MainMenu scene if B button is called, but it seems to be doing this automatically. Not sure why.
end
function scene:exit()
    Noble.transition(MainMenu, nil, Noble.Transition.DipToBlack)
end