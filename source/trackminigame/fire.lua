import "CoreLibs/object"
import "CoreLibs/sprites"
import "CoreLibs/Animator"
Fire = {}
local pd = playdate
local gfx = pd.graphics
class('Fire').extends(gfx.sprite)
function Fire:init(x, y, width, height)
    Fire.super.init(self)
    local fireImage = gfx.image.new(width, height)
    gfx.pushContext(fireImage)
        gfx.drawRect(0, 0, width, height) --(0, 0) is the relative x and y coordinates for the image
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, width, height)
    gfx.popContext()
    self:setImage(fireImage)
    self:moveTo(x, y)
    self:setCollideRect(0, 0, self:getSize()) --sets the collision rect for the sprite
    --self:setGroups(2) --gives the sprite a group of 2 two for collisions
    --self:add()
end

function Fire:collisionResponse(other)
    return 'overlap'
end
