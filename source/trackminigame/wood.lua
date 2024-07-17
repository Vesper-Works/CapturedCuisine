import "CoreLibs/object"
import "CoreLibs/sprites"
Wood = {}
local pd = playdate
local gfx = pd.graphics
local woodSprite
class('Wood').extends(gfx.sprite)
function Wood:init(x, y, width, height, originX)
    self.originX = originX 
    Wood.super.init(self)
    local woodImage = gfx.image.new(width, height)
    gfx.pushContext(woodImage)
        gfx.fillRect(0, 0, width, height) --(0, 0) is the relative x and y coordinates for the image
    gfx.popContext()
    self:setImage(woodImage)
    --woodSprite = gfx.sprite.new(woodImage)
    self:moveTo(x, y)
    self:add()
end
