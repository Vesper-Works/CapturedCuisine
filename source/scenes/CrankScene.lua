import 'CoreLibs/Graphics'
import 'trackminigame/wood'
import 'trackminigame/fire'
CrankScene = {}
class("CrankScene").extends(NobleScene)
local scene = CrankScene
local pd = playdate
local rectSprite
local track
local offset
local woods = {}
local index = 0
local speed = 2
local collideSprite
local stopUpdate = false
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
    collideSprite = Fire(200, 100, 30, 30)
end
function scene:init() 
    scene.super.init(self)
    self:setValues()
end
function scene:update()
    if stopUpdate == true then 
        return 
    end
    pd.graphics.drawArc(track)
    local change, accelerateChange = pd.getCrankChange() --clockwise/anticlockwise, with high accelerateChange representing speed of crank change while change
    offset = offset + pd.getCrankChange()
    offset = math.min(track:length(), math.max(0, offset)) --ensures that rect will be clamped between the arc
    local point = track:pointOnArc(offset) --pointonArc = distance from original point
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
            local collisionOccured = woods[i]:update() --checks if fire is collieded with
            print(collisionOccured)
            if collisionOccured == true then
                stopUpdate = true
                scene.exit(self)
                return --breaks the if and the loop, so that the next if is not checked
            end
            if woods[i].x <= 0 or woods[i].x >= 400 or woods[i].y <= 0 then --should the x boundary be breached or the upper y boundary (it will never go below the arc)
                woods[i]:remove() --remove sprite from render
                table.remove(woods, i) --remove from table
                index = index - 1
            end
        end
    end
end
function scene:exit() 
    for i=1, #woods do
        if woods[i] == nil then
            return
        else
            woods[i]:remove()
            table.remove(woods, i)
            index = index - 1
        end --should reset scene
    end
    collideSprite:remove()
    rectSprite:remove()
    Noble.transition(MainMenuGrid, nil, Noble.Transition.DipToBlack)
    stopUpdate = false
end