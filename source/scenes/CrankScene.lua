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
    local squareImage = pd.graphics.image.new(30, 30)
    pd.graphics.pushContext(squareImage)
        pd.graphics.drawRect(0, 0, 30, 30)
    pd.graphics.popContext()
    rectSprite = pd.graphics.sprite.new(squareImage)
    rectSprite:moveTo(200, 200)
    rectSprite:setZIndex(30) --should allow sprite to be above arc
    rectSprite:add()
    self.lastPosition = 0
end
function scene:init() 
    scene.super.init(self)
    self:setValues()
end
function scene:update()
    local track = pd.geometry.arc.new(200, 100, 100, 120, 240) --creation of an arc
    pd.graphics.drawArc(track)
    local change, accelerateChange = pd.getCrankChange() --clockwise/anticlockwise, with high accelerateChange representing speed of crank change while change
    local point = track:pointOnArc(rectSprite.x, rectSprite.y)
    local centreX = (200 + 400) / 2 --convert playdate coordinates to cartesian
    local centreY = (100 + 240) / 2
    local movementAngle = math.max(120, math.min(240, pd.getCrankPosition())) --returns a value between 120 and 240
    local radiansMovement = math.rad(movementAngle) --lua math uses radians
    --is angle change since last callback
    if change ~= 0 then
        accelerateChange = math.abs(accelerateChange) --this ensures that accelerateChange is positive acceleration to prevent a negative * negative outcome
        accelerateChange = accelerateChange / 10
        rectSprite:moveTo(centreX + math.sin(radiansMovement) * 100, centreY - math.cos(radiansMovement) * 100)
    end
    
end