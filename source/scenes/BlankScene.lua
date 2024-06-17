BlankScene = {}
class("BlankScene").extends(MainMenu)
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
    if pd.kButtonB then
        self.exit(self)
    end
end
function scene:exit()
    Noble.transition(MainMenu, nil, Noble.Transition.DipToBlack)
end