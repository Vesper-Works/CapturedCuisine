import 'CoreLibs/Graphics'
import 'trackminigame/wood'
import 'trackminigame/fire'
CrankScene = {}
class("CrankScene").extends(NobleScene)
local scene = CrankScene
local pd = playdate
local gfx = playdate.graphics
local geo = pd.geometry
local rectSprite
local track
local offset
local woods = {}
local index = 0
local speed = 2
local collideSprite
local stopUpdate = false
local Animator = gfx.animator
local sideOne = geo.lineSegment.new(140, 60, 260, 60)
local sideTwo = geo.lineSegment.new(260, 60, 200, 0)
local sideThree = geo.lineSegment.new(200, 0, 140, 60)
local parts = {sideOne, sideTwo, sideThree}
--local parts = {topLine, trArc, rightLine, brArc, bottomLine, blArc, leftLine, tlArc}

local partsAnimation = Animator.new(2000, parts, playdate.easingFunctions.linear)
partsAnimation.repeatCount = -1
partsAnimation.reverses = true
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
        local squareImage = gfx.image.new("assets/images/bird.png")
        rectSprite = pd.graphics.sprite.new(squareImage)
        rectSprite:moveTo(200, 200)
        rectSprite:setZIndex(30) --should allow sprite to be above arc
        --rectSprite:add()
        scene:addSprite(rectSprite)
        self.lastPosition = 0
        track = pd.geometry.arc.new(200, 100, 100, 120, 240) --creation of an arc
        local point = track:pointOnArc(0)
        rectSprite:moveTo(point.x, point.y)
        offset = 0
        collideSprite = Fire(200, 100, 30, 30)
        scene:addSprite(collideSprite)
        self.angle = 0 -- start angle
        self.angleSweepSpeed = -0.1 -- in degrees per frame
        self.arcLength = 100
        self.launched = false
        self.stopped = false
        self.launchVelocity = 5
        self.launchVelocityX = 0.0
        self.launchVelocityY = 0.0
        self.tries = 3
end
function scene:init(__sceneProperties)
    self.likesThisMethod = __sceneProperties.prefferedMethods
    self.hatesThisMethod = __sceneProperties.hatedMethods
    if self.hatesThisMethod == true then
        print("I hate this laser method")
        PickIngredientScene.updateReputation(0)
    elseif self.likesThisMethod == true then
        print("I love this method")
        PickIngredientScene.updateReputation(2)
    end
    scene.super.init(self)
    self:setValues()
end
function scene:update()
    if self.tries == 0 then
        pd.timer.performAfterDelay(1000, function () Noble.transition(PickIngredientScene, nil, Noble.Transition.DipToBlack)  end)
    end
    collideSprite:moveTo(partsAnimation:currentValue())
    rectSprite.update()
    collideSprite.update()
    pd.graphics.drawArc(track)
    self:woodHandler()
    if stopUpdate == true then 
        return 
    end
    if self.stopped == true then
        if self.launched == false then
            if pd.buttonJustPressed(pd.kButtonB) then
                self.launched = true
                self.launchVelocityX = self.launchVelocity * math.cos(self.angle)
                self.launchVelocityY = self.launchVelocity * math.sin(self.angle)
            end
            self.angle += self.angleSweepSpeed
            local arcX = rectSprite.x + self.arcLength * math.cos(self.angle)
            local arcY = rectSprite.y + self.arcLength * math.sin(self.angle)
            gfx.drawLine(rectSprite.x, rectSprite.y, arcX, arcY)
        else
            local woodObject = Wood(rectSprite.x, rectSprite.y, 10, 10, rectSprite.x, self.launchVelocityX, self.launchVelocityY) 
            index = index + 1
            table.insert(woods, index, woodObject)
            self.launched = false
            self.stopped = false
        end
    else
        local change, accelerateChange = pd.getCrankChange() --clockwise/anticlockwise, with high accelerateChange representing speed of crank change while change
        offset = offset + pd.getCrankChange()
        offset = math.min(track:length(), math.max(0, offset)) --ensures that rect will be clamped between the arc
        local point = track:pointOnArc(offset) --pointonArc = distance from original point
        rectSprite:moveTo(point.x, point.y)
        if pd.buttonJustPressed(pd.kButtonB) then
            self.stopped = true
            return
        end
    end
end
function scene:woodHandler()
    for i=1,#woods do
        if woods[i] == nil then
            return
        else
            local collisionOccured = woods[i]:update() --checks if fire is collieded with
            print(collisionOccured)
            if collisionOccured == true then
                woods[i]:remove() --remove sprite from render
                table.remove(woods, i) --remove from table
                index = index - 1
                stopUpdate = true
                pd.timer.performAfterDelay(1000, function () Noble.transition(PickIngredientScene, nil, Noble.Transition.DipToBlack)  end)
                return --breaks the if and the loop, so that the next if is not checked
            end
            if woods[i].x <= 0 or woods[i].x >= 400 or woods[i].y <= 0 then --should the x boundary be breached or the upper y boundary (it will never go below the arc)
                woods[i]:remove() --remove sprite from render
                table.remove(woods, i) --remove from table
                index = index - 1
                self.tries = self.tries - 1
            end
        end
    end
end
function scene:exit()
    if self.tries == 0 then
        PickIngredientScene.updateReputation(0)
    end 
    for i=1, #woods do
        if woods[i] == nil then
            return
        else
            woods[i]:remove()
            table.remove(woods, i)
            index = index - 1
        end --should reset scene
    end
    stopUpdate = false
    scene:removeSprite(rectSprite)
    scene:removeSprite(collideSprite)
end