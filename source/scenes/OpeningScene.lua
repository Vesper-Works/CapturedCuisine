import "CoreLibs/graphics" --note that any libraries from playdate can be used with noble
OpeningScene = {}
class("OpeningScene").extends(NobleScene)
local scene = OpeningScene --when refering to scene, it's referring to an instance of the OpeningScene object
local pd <const> = playdate
local gfx <const> = pd.graphics
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
	self.color2 = Graphics.kColorWhite 
end

function scene:init()
    scene.super.init(self) --calls parent constructor
    self:setValues()
end

function scene:exit()
    Noble.transition(MainMenuGrid, nil, Noble.Transition.DipToBlack) --move to the main scene
end

--flesh this out with the actual opening cinematic later