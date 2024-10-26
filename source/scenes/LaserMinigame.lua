import "CoreLibs/graphics"
import "utilities/IngredientHandler"
import "CoreLibs/utilities/sampler"

LaserMinigame = {}
class("LaserMinigame").extends(NobleScene)
--local scene = LaserMinigame --when refering to scene, it's referring to an instance of the OpeningScene object
local pd <const> = playdate
local gfx <const> = pd.graphics
local img
local img2
local mask
local test = 0
local splitMask
local splitImg1
local splitImg2
local splitLine
local spritesList = {}
local outsideMin, outsideMaxY, outsideMaxX = 37, 203, 363
local splitLineOffset = pd.geometry.point.new(0, 0)
local laserBaseNorth, laserBaseSouth, laserBaseEast, laserBaseWest
local laserSize = 3
local fluidSettings = { 30, 0, 200, 200 }

-- function which rotates a line segement around a point using the crank
local function rotateLineSegmentAroundPoint(angle, lengthX, lengthY)
    if (lengthX == nil) then
        lengthX = 400
    end
    if (lengthY == nil) then
        lengthY = 240
    end
    local lineSegment = pd.geometry.lineSegment.new(0, 0, lengthX, lengthY)
    lineSegment:offset(splitLineOffset.x, splitLineOffset.y)
    local x1, y1, x2, y2 = lineSegment:unpack()
    local centerX, centerY = lineSegment:midPoint():unpack()
    local angleRads = math.rad(angle)
    -- Translate the line segment to the origin
    x1 = x1 - centerX
    y1 = y1 - centerY
    x2 = x2 - centerX
    y2 = y2 - centerY

    -- Rotate the line segment
    local cosAngle = math.cos(angleRads)
    local sinAngle = math.sin(angleRads)
    local newX1 = x1 * cosAngle - y1 * sinAngle
    local newY1 = x1 * sinAngle + y1 * cosAngle
    local newX2 = x2 * cosAngle - y2 * sinAngle
    local newY2 = x2 * sinAngle + y2 * cosAngle

    -- Translate the line segment back to its original position
    newX1 = newX1 + centerX
    newY1 = newY1 + centerY
    newX2 = newX2 + centerX
    newY2 = newY2 + centerY

    return pd.geometry.lineSegment.new(newX1, newY1, newX2, newY2)
end
local function splitSpriteIntoTwo(splitSprite, splitLine)
    local splitImg1, splitImg2, polygon, polygonInverse = Utilities.splitImage(splitSprite[1], mask, splitLine,
        splitSprite[7], pd.geometry.point.new(splitSprite[2], splitSprite[3]))
    if (splitImg1 == nil or splitImg2 == nil) then
        return false
    end
    local x1, y1, x2, y2 = splitLine:unpack()
    local vec = splitLine:segmentVector()
    vec:normalize()
    local normalX, normalY = vec:rightNormal():unpack()
    local angle = vec:angleBetween(pd.geometry.vector2D.new(0, 1))
    print(angle)
    if (angle > 40 or angle < -140) then
        --normalX = -normalX
        --normalY = -normalY
    end
    local speedX = (splitSprite[5] / (math.random() + 1)) + (normalX / (math.random() + 1))
    local speedY = (splitSprite[6] / (math.random() + 1)) + (normalY / (math.random() + 1))
    local speedXInv = (splitSprite[5] / (math.random() + 1)) - (normalX / (math.random() + 1))
    local speedYInv = (splitSprite[6] / (math.random() + 1)) - (normalY / (math.random() + 1))

    local speedX = splitSprite[5] / 2 + (normalX / 2)
    local speedY = splitSprite[6] / 2 + (normalY / 2)
    local speedXInv = splitSprite[5] / 2 + -(normalX / 2)
    local speedYInv = splitSprite[6] / 2 + -(normalY / 2)

    local polygonLength1 = polygonInverse:length()
    local polygonLength2 = polygon:length()

    local targetLine1 = rotateLineSegmentAroundPoint(math.random() * 360, polygonLength1 / 4, polygonLength1 / 4)
        :offsetBy(splitSprite[2], splitSprite[3])
    local targetLine2 = rotateLineSegmentAroundPoint(math.random() * 360, polygonLength2 / 4, polygonLength2 / 4)
        :offsetBy(splitSprite[2], splitSprite[3])

    --Get middle of each polygon and offset each target line to the middle of the polygon
    local averageX = 0
    local averageY = 0
    for i = 1, polygonInverse:count(), 1 do
        local point = polygonInverse:getPointAt(i)
        averageX += point.x
        averageY += point.y
    end
    averageX = averageX / polygonInverse:count()
    averageY = averageY / polygonInverse:count()

    local targetLine1Midpoint = targetLine1:midPoint()
    local lineOffset = pd.geometry.point.new(averageX, averageY) - targetLine1Midpoint
    targetLine1:offset(lineOffset.x, lineOffset.y)

    averageX = 0
    averageY = 0
    for i = 1, polygon:count(), 1 do
        local point = polygon:getPointAt(i)
        averageX += point.x
        averageY += point.y
    end
    averageX = averageX / polygon:count()
    averageY = averageY / polygon:count()

    local targetLine2Midpoint = targetLine2:midPoint()
    lineOffset = pd.geometry.point.new(averageX, averageY) - targetLine2Midpoint
    targetLine2:offset(lineOffset.x, lineOffset.y)

    targetLine1:offset(-splitSprite[2], -splitSprite[3])
    targetLine2:offset(-splitSprite[2], -splitSprite[3])

    spritesList[#spritesList + 1] = { splitImg1, splitSprite[2], splitSprite[3], 0, speedX, speedY, polygonInverse,
        targetLine1 }
    spritesList[#spritesList + 1] = { splitImg2, splitSprite[2], splitSprite[3], 0, speedXInv, speedYInv, polygon,
        targetLine2 }
    return true
end

local laserCutAnimation = Sequence.new():from(1):to(0, 0.5, "inOutQuad"):callback(
    function()
        laserSize = 7
        local intersectingIndex = {}
        for i, splitSprite in ipairs(spritesList) do
            if (splitLine:intersectsPolygon(splitSprite[7])) then
                table.insert(intersectingIndex, i)
            end
        end
        for i = #intersectingIndex, 1, -1 do
            local splitSprite = spritesList[intersectingIndex[i]]
            if splitSpriteIntoTwo(splitSprite, splitLine) then
                table.remove(spritesList, intersectingIndex[i])
            end
        end
        --laserCutAnimation:set(0.55)
    end
):to(1, 0.2):callback(
    function()
        laserSize = 3
    end
)

LaserMinigame.inputHandler = {
    rightButtonHold = function()
        splitLineOffset:offset(3, 0)
    end,
    leftButtonHold = function()
        splitLineOffset:offset(-3, 0)
    end,
    upButtonHold = function()
        splitLineOffset:offset(0, -3)
    end,
    downButtonHold = function()
        splitLineOffset:offset(0, 3)
    end,
    AButtonDown = function()
        laserCutAnimation:restart()
    end
}

function LaserMinigame:setValues()
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
end

function LaserMinigame:start()
    local backgroundImage = gfx.image.new("assets/images/LaserCutterBackground")
    local backgroundSprite = NobleSprite(backgroundImage)
    backgroundSprite:add(200, 120)
    Noble.Input.setHandler(LaserMinigame.inputHandler)
end

function LaserMinigame:init()
    gfx.sprite.setAlwaysRedraw(false)
    LaserMinigame.super.init(self) --calls parent constructor
    --pd.display.setRefreshRate(500)
    self:setValues()

   --[[ local menu = pd.getSystemMenu()
    local updating = false
    local updateSimulation = Sequence.new():from(20):to(80, 0.1, "linear"):callback(function()
        fluid.reinitialise(fluidSettings[1], fluidSettings[2], fluidSettings[3], fluidSettings[4])
        updating = false
    end)

    menu:addOptionsMenuItem("Fluid",
        { "20", "25", "30", "35", "40", "45", "50", "55", "60", "65", "70", "75", "80" }, "30",
        function(option)
            fluidSettings[1] = tonumber(option)
            if not updating then
                updating = true
                updateSimulation:restart()
            end
        end)
    menu:addOptionsMenuItem("Res",
        { "40x40", "60x60", "80x80", "100x100", "120x120", "140x140", "160x160", "180x180", "200x200", "300x180","400x240" }, "200x200",
        function(option)
            fluidSettings[3] = tonumber(option:match("%d+"))
            fluidSettings[4] = tonumber(option:match("x(%d+)"))
            if not updating then
                updating = true
                updateSimulation:restart()
            end
        end)

    menu:addCheckmarkMenuItem("Interp", 0, function(checked)
        fluidSettings[2] = checked == true and 1 or 0
        if not updating then
            updating = true
            updateSimulation:restart()
        end
    end)

    fluid.initialise()
]]
    IngredientHandler.loadIngredients()
    IngredientHandler.test()
    img = IngredientHandler.getSpriteForIngredientByName("Glow Leeks")
    local newPoint = function(x, y) return pd.geometry.point.new(x, y):offsetBy(168, 88) end
    local polygon = pd.geometry.polygon.new(newPoint(0, 0), newPoint(0, 64 + 0), newPoint(64 + 0, 64 + 0),
        newPoint(64 + 0, 0))
    polygon:close()
    local targetLine = rotateLineSegmentAroundPoint(math.random() * 360, 64, 64)
    --               Image, x,   y,   r, vx,vy,cpolygon, target cut
    spritesList[1] = { img, 168, 88, 0, 0, 0, polygon, targetLine }
    mask = gfx.image.new("assets/images/default_mask")
    splitLine = pd.geometry.lineSegment.new(-200, 32, 200, 32)
    --pd.display.setRefreshRate(2)
    laserBaseNorth = gfx.image.new("assets/images/laserbase_north")
    laserBaseSouth = gfx.image.new("assets/images/laserbase_south")
    laserBaseEast = gfx.image.new("assets/images/laserbase_east")
    laserBaseWest = gfx.image.new("assets/images/laserbase_west")
    
end

function LaserMinigame:update()
    LaserMinigame.super.update(self)

    --[[
    test += pd.getCrankChange() / 360
    gfx.pushContext()
    gfx.setStencilPattern(8)
    --img:drawFaded(100, 100, 1-test, gfx.image.kDitherTypeBayer8x8)
    --gfx.setImageDrawMode(gfx.kDrawModeInverted)
    --img:setMaskImage(mask)
    img:drawBlurred(100, 100, test, 3, gfx.image.kDitherTypeDiagonalLine)
    --img:removeMask()
    gfx.popContext()
]]
    splitLine = rotateLineSegmentAroundPoint(pd.getCrankPosition()) -- pd.geometry.lineSegment.new(20, 64, 0, 14)


    gfx.pushContext()
    -- Make all split sprites drift around
    for i, splitSprite in ipairs(spritesList) do
        splitSprite[2] += splitSprite[5]
        splitSprite[3] += splitSprite[6]
        local spriteX, spriteY, spriteRotation = splitSprite[2], splitSprite[3], splitSprite[4]

        --local polygonTransform = pd.geometry.affineTransform.new()
        --polygonTransform:scale(-1, -1)
        --polygonTransform:rotate(spriteRotation, pd.geometry.point.new(-32, -32))
        --local polygon = splitSprite[7] * polygonTransform
        splitSprite[7]:translate(splitSprite[5], splitSprite[6])

        for i = 1, splitSprite[7]:count(), 1 do
            local point = splitSprite[7]:getPointAt(i)
            if (point.x < outsideMin or point.x > outsideMaxX) then
                splitSprite[5] = -splitSprite[5]
                spriteX += splitSprite[5]
                splitSprite[7]:translate(splitSprite[5], 0)
            end
            if (point.y < outsideMin or point.y > outsideMaxY) then
                splitSprite[6] = -splitSprite[6]
                spriteY += splitSprite[6]
                splitSprite[7]:translate(0, splitSprite[6])
            end
        end
        --gfx.setClipRect()
        splitSprite[1]:draw(spriteX, spriteY)

        gfx.pushContext()
        gfx.setDrawOffset(spriteX, spriteY)
        gfx.setLineWidth(2)
        gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer2x2)
        gfx.drawLine(splitSprite[8])
        gfx.popContext()
        --gfx.drawPolygon(splitSprite[7])

        --[[ Count how many pixels are not transparent
        local pixelCount = 0
        local width, height =  splitSprite[1]:getSize()
        for i = 0,width, 1 do
            for j = 0, height, 1 do
                if splitSprite[1]:sample(i, j) ~= gfx.kColorClear then
                    pixelCount += 1
                end
            end
        end
        sasprint(pixelCount)
        ]]
    end

    gfx.popContext()

    gfx.pushContext()
    gfx.setScreenClipRect(outsideMin, outsideMin, outsideMaxX - outsideMin, outsideMaxY - outsideMin)
    gfx.setDitherPattern(laserCutAnimation:get(), gfx.image.kDitherTypeBayer4x4)
    gfx.setLineWidth(laserSize)
    gfx.drawLine(splitLine)
    gfx.popContext()

    --Get the points where the splitLine intersects the outside of the screen
    local firstPoint, secondPoint
    local quadPoints = {
        pd.geometry.point.new(outsideMin, outsideMin),
        pd.geometry.point.new(outsideMaxX, outsideMin),
        pd.geometry.point.new(outsideMaxX, outsideMaxY),
        pd.geometry.point.new(outsideMin, outsideMaxY),
        pd.geometry.point.new(outsideMin, outsideMin)
    }
    for i = 1, #quadPoints - 1, 1 do
        local intersects, intersectPoint = splitLine:intersectsLineSegment(quadPoints[i] .. quadPoints[i + 1])
        if intersects then
            if firstPoint == nil then
                firstPoint = intersectPoint
            else
                secondPoint = intersectPoint
            end
        end
    end

    --Draw correct laser base based on what side of the quad the point is
    gfx.pushContext()
    local almostEqual = function(a, b)
        return math.abs(a - b) < 0.01
    end
    if firstPoint == nil then
        gfx.popContext()
        return
    end
    if almostEqual(firstPoint.x, outsideMin) then
        laserBaseEast:drawCentered(firstPoint.x, firstPoint.y)
    elseif almostEqual(firstPoint.x, outsideMaxX) then
        laserBaseWest:drawCentered(firstPoint.x, firstPoint.y)
    elseif almostEqual(firstPoint.y, outsideMin) then
        laserBaseSouth:drawCentered(firstPoint.x, firstPoint.y)
    elseif almostEqual(firstPoint.y, outsideMaxY) then
        laserBaseNorth:drawCentered(firstPoint.x, firstPoint.y)
    end
    if secondPoint == nil then
        gfx.popContext()
        return
    end
    if almostEqual(secondPoint.x, outsideMin) then
        laserBaseEast:drawCentered(secondPoint.x, secondPoint.y)
    elseif almostEqual(secondPoint.x, outsideMaxX) then
        laserBaseWest:drawCentered(secondPoint.x, secondPoint.y)
    elseif almostEqual(secondPoint.y, outsideMin) then
        laserBaseSouth:drawCentered(secondPoint.x, secondPoint.y)
    elseif almostEqual(secondPoint.y, outsideMaxY) then
        laserBaseNorth:drawCentered(secondPoint.x, secondPoint.y)
    end
    gfx.popContext()


    --splitLineStensil:draw(0,0)
end

function LaserMinigame:exit()
    Noble.transition(PickIngredientScene, nil, Noble.Transition.DipToBlack) --move to the main scene
end

--flesh this out with the actual opening cinematic later
