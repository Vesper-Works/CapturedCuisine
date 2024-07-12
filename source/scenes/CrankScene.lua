import 'CoreLibs/Graphics'
CrankScene = {}
class("CrankScene").extends(NobleScene)
local scene = CrankScene
local pd = playdate
local rectSprite
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    local squareImage = pd.graphics.image.new(10, 10)
    pd.graphics.pushContext(squareImage)
        pd.graphics.drawRect(0, 0, 10, 10)
    pd.graphics.popContext()
    rectSprite = pd.graphics.sprite.new(squareImage)
    rectSprite:moveTo(20, 20)
    rectSprite:add()
end
function scene:init() 
    scene.super.init(self)
    self:setValues()
end
function scene:update()

end