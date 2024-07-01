import "CoreLibs/object"
import "CoreLibs/sprites"
Dialogue = {}
local pd = playdate
local gfx = pd.graphics
local textSprite
local rectSprite
class('Dialogue').extends(gfx.sprite)
function Dialogue:init(dial, x, y, width, height)
    Dialogue.super.init(self)
    self.dial = dial --json attributes for the dialogue system are parsed through here
    self:moveTo(x, y)
    local dialogueImage = gfx.image.new(width, height)
    gfx.pushContext(dialogueImage)
        gfx.drawRect(0, 0, width, height)
        gfx.drawTextInRect(dial, 0, 0, width, height)
    gfx.popContext()
    self:setImage(dialogueImage)
    textSprite = gfx.sprite.new(dialogueImage)
    self:moveTo(x, y)
    textSprite:setCenter(0, 0) --this means the sprite will be drawn at the top left corner
    textSprite:moveTo(x, y)
end

