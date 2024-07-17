import 'CoreLibs/Graphics'
import 'trackminigame/wood'
CrankScene = {}
class("CrankScene").extends(NobleScene)
local scene = CrankScene
local pd = playdate
local rectSprite
local track
local offset
local woods = {}
local index = 0
local speed = 5
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
    track = pd.geometry.arc.new(200, 100, 100, 120, 240) --creation of an arc
    local point = track:pointOnArc(0)
    rectSprite:moveTo(point.x, point.y)
    offset = 0
end
function scene:init() 
    scene.super.init(self)
    self:setValues()
end
function scene:update()
    pd.graphics.drawArc(track)
    local change, accelerateChange = pd.getCrankChange() --clockwise/anticlockwise, with high accelerateChange representing speed of crank change while change
    offset = offset + pd.getCrankChange()
    offset = math.min(track:length(), math.max(0, offset))
    local point = track:pointOnArc(offset)
    rectSprite:moveTo(point.x, point.y)
    if pd.buttonJustReleased(pd.kButtonB) then
        local woodObject = Wood(point.x, point.y, 20, 20, point.x) 
        index = index + 1
        table.insert(woods, index, woodObject)
    end
    for i=1,#woods do
        if woods[i] == nil then
            return
        else
            woods[i]:moveTo(woods[i].x, (woods[i].y - speed))
            if woods[i].x <= 0 or woods[i].x >= 400 or woods[i].y <= 0 then --should the x boundary be breached or the upper y boundary (it will never go below the arc)
                woods[i]:remove() --remove sprite from render
                table.remove(woods, i) --remove from table
                index = index - 1
            end
        end
    end
end