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
    local dialogueTextImage = gfx.image.new(width, height)
    gfx.pushContext(dialogueTextImage)
        gfx.drawTextInRect(dial, 0, 0, width, height)
    gfx.popContext()
    textSprite = gfx.sprite.new(dialogueTextImage)
    textSprite:setZIndex(30) --needs to be overlayed on top of speech bubble
    local dialogueRectImage = gfx.image.new(width, height)
    gfx.pushContext(dialogueRectImage)
        gfx.drawRect(0, 0, width, height)
    gfx.popContext()
    rectSprite = gfx.sprite.new(dialogueRectImage)
end
function Dialogue:add() 
    gfx.sprite.addSprite(textSprite)
    gfx.sprite.addSprite(rectSprite)
end
function Dialogue:remove() 
    gfx.sprite.removeSprite(textSprite)
    gfx.sprite.removeSprite(rectSprite)
end
