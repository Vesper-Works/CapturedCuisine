import "CoreLibs/object"
import "CoreLibs/sprites"
Wood = {}
local pd = playdate
local gfx = pd.graphics
local woodSprite
local speed = 2
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
    self:setCollideRect(0, 0, self:getSize()) --sets the collision rect for the sprite
    --self:setGroups(1) --gives the sprite a group of 1 for collisions
    --self:setCollidesWithGroups(2) --states what group the sprite should collide with
    self:add()
end

function Wood:collisionResponse(other)
    return 'overlap' --should return the collision type to be an overlap collision
end
function Wood:update()
    local actualX, actualY, collisions, collisionsLen = self:moveWithCollisions(self.x, (self.y - speed)) --moveWithCollisions takes collisions into account for movement
            if collisionsLen ~= 0 then
                print(collisions[1].sprite.className)
                if collisions[1].other:isa(Fire) then --since there are no other collidable objects other than fire, collisions[1] should only be fireSprite
                    return true --collisions contains sprite for current sprite and other for the object that is being collided with
                end
            else
                return false
            end
end