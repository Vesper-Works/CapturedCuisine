import "CoreLibs/object"
import "CoreLibs/sprites"
PlateSprite = {}
local pd = playdate
local gfx = pd.graphics
class('PlateSprite').extends(gfx.sprite)
function PlateSprite:init(x, y, width, height)
    self.x = x
    self.y = y
    self.finalY = 0
    self.width = width
    self.height = height
    Fire.super.init(self)
    local plateImage = gfx.image.new(width, height)
    gfx.pushContext(plateImage)
        gfx.drawRect(0, 0, width, height) --(0, 0) is the relative x and y coordinates for the image
        gfx.setColor(gfx.kColorBlack)
    gfx.popContext()
    self:setImage(plateImage)
    self:moveTo(x, y)
    self:setCollideRect(0, 0, self:getSize()) --sets the collision rect for the sprite
    --self:setGroups(2) --gives the sprite a group of 2 two for collisions
    --self:add()
end

function PlateSprite:collisionResponse(other)
    return 'freeze'
end
function PlateSprite:setX(newX)
    self.x = newX
end
function PlateSprite:setY(newY)
    self.y = newY
end
function PlateSprite:move(newX, newY)
    local actualX, actualY, collisions, collisionsLen = self:moveWithCollisions(newX, newY)
    if collisionsLen ~= 0 then
        self.finalY = newY
        return true
    end
end
function PlateSprite:getX()
    return self.x
end
function PlateSprite:getY()
    return self.y
end
function PlateSprite:getWidth()
    return self.width
end
function PlateSprite:getHeight()
    return self.height
end
function PlateSprite:getFinalY()
    return self.finalY
end