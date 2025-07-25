-- Put your utilities and other helper functions here.
-- The "Utilities" table is already defined in "noble/Utilities.lua."
-- Try to avoid name collisions.
local pd <const> = playdate
local gfx <const> = pd.graphics

function Utilities.pointIsOnLineSegement(point, lineSegment)
    local x, y = point:unpack()
    local x1, y1, x2, y2 = lineSegment:unpack()
    local ABLength = (pd.geometry.point.new(x1, y1) .. point):length() + (pd.geometry.point.new(x2, y2) .. point):length()
    if math.abs(lineSegment:length()-ABLength) < 0.1 then
        return true
    end
    return false
end

function Utilities.splitImage(image, mask, splitLine, imagePolygon, imagePos)
    local originSplitLine = splitLine:copy()
    originSplitLine:offset(-imagePos.x, -imagePos.y)
    local fx1, fy1, fx2, fy2 = originSplitLine:unpack()

    local width, height = image:getSize()
    local splitMask1 = gfx.image.new(width, height, gfx.kColorWhite)
    local splitMask2 = gfx.image.new(width, height, gfx.kColorWhite)
    local splitImg1 = gfx.image.new(width, height, gfx.kColorClear)
    local splitImg2 = gfx.image.new(width, height, gfx.kColorClear)


    local intersects, intersectionPoints = splitLine:intersectsPolygon(imagePolygon)
    if not intersects then
        print("Error: No intersection, how did this happen?")
    end
    local polygonPoints = {}
    for i = 1, imagePolygon:count(), 1 do
        polygonPoints[i] = imagePolygon:getPointAt(i)
    end
    printTable(intersectionPoints)
    printTable(polygonPoints)
    -- Combine the intersection points with the polygon points. If the intersection point is on the edge between two polygon points, add the intersection point and the next polygon point
    local completePolygonPoints = {}
    local intersectionPointsIndices = {}
    for i = 1, #polygonPoints, 1 do
        local point = polygonPoints[i]
        local nextPoint = polygonPoints[i + 1]
        if nextPoint == nil then
            nextPoint = polygonPoints[1]
        end
        completePolygonPoints[#completePolygonPoints + 1] = point
        for j = 1, #intersectionPoints, 1 do
            local intersectionPoint = intersectionPoints[j]
            if Utilities.pointIsOnLineSegement(intersectionPoint, point .. nextPoint) then
                completePolygonPoints[#completePolygonPoints + 1] = intersectionPoint
                intersectionPointsIndices[#intersectionPointsIndices + 1] = #completePolygonPoints
            end
        end
    end

    if (#intersectionPointsIndices ~= 2) then
        print("Error: More than 2 intersection points")
        return nil, nil, nil, nil
    end
    -- Remove the points that are to the right of the split line
    local firstPolygonPoints = {}
    local secondPolygonPoints = {}

    -- Add the first part of the split
    for i = 1, intersectionPointsIndices[1] do
        table.insert(firstPolygonPoints, completePolygonPoints[i])
    end
    for i = intersectionPointsIndices[2], #completePolygonPoints do
        table.insert(firstPolygonPoints, completePolygonPoints[i])
    end

    -- Add the second part of the split
    for i = intersectionPointsIndices[1], intersectionPointsIndices[2] do
        table.insert(secondPolygonPoints, completePolygonPoints[i])
    end

    --[[
    pd.debugDraw = function()
        --draw arrows pointing to show the next point on the polygon
        pd.setDebugDrawColor(1,0,0,0.5)
        for i = 1, #firstPolygonPoints, 1 do
            local point = firstPolygonPoints[i]
            local nextPoint = firstPolygonPoints[i + 1]
            if nextPoint == nil then
                nextPoint = firstPolygonPoints[1]
            end
            gfx.drawLine(point .. nextPoint)
            gfx.drawCircleAtPoint(point, 5)
        end
        pd.setDebugDrawColor(0,1,0,0.5)
        for i = 1, #secondPolygonPoints, 1 do
            local point = secondPolygonPoints[i]
            local nextPoint = secondPolygonPoints[i + 1]
            if nextPoint == nil then
                nextPoint = secondPolygonPoints[1]
            end
            gfx.drawLine(point .. nextPoint)
            gfx.drawCircleAtPoint(point, 5)
        end
    end
]]
    local splitPolygon = pd.geometry.polygon.new(#firstPolygonPoints)
    for i = 1, #firstPolygonPoints, 1 do
        splitPolygon:setPointAt(i, firstPolygonPoints[i].x, firstPolygonPoints[i].y)
    end
    local polygonInverse = pd.geometry.polygon.new(#secondPolygonPoints)
    for i = 1, #secondPolygonPoints, 1 do
        polygonInverse:setPointAt(i, secondPolygonPoints[i].x, secondPolygonPoints[i].y)
    end
    splitPolygon:close()
    polygonInverse:close()
    splitPolygon:translate(-imagePos.x, -imagePos.y)
    polygonInverse:translate(-imagePos.x, -imagePos.y)
    gfx.pushContext()


    local cutLineVisualMask1 = gfx.image.new(width, height, gfx.kColorClear)
    local cutLineVisualMask2 = gfx.image.new(width, height, gfx.kColorClear)

    gfx.lockFocus(splitMask1)
    --gfx.setDrawOffset(-imagePos.x, -imagePos.y)
    gfx.fillPolygon(splitPolygon)
    gfx.lockFocus(splitMask2)
    --gfx.setDrawOffset(-imagePos.x, -imagePos.y)
    gfx.fillPolygon(polygonInverse)
    
    --Combine mask and splitMask into one mask
    mask:setInverted(false)
    gfx.lockFocus(cutLineVisualMask1)
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.setStencilImage(mask)
    splitMask1:draw(0, 0)
    
    gfx.lockFocus(cutLineVisualMask2)
    gfx.setImageDrawMode(gfx.kDrawModeInverted)
    gfx.setStencilImage(mask)
    splitMask2:draw(0, 0)
    cutLineVisualMask1:setInverted(false)
    cutLineVisualMask2:setInverted(false)
    gfx.lockFocus(splitImg1)
    
    gfx.setStencilImage(cutLineVisualMask2)
    image:draw(0, 0)
    gfx.setDitherPattern(0, gfx.image.kDitherTypeBayer2x2)
    gfx.setLineWidth(1)
    gfx.drawLine(originSplitLine)
    gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
    gfx.drawLine(originSplitLine:offsetBy(1, 1))
    gfx.drawLine(originSplitLine:offsetBy(-1, -1))
    gfx.drawLine(originSplitLine:offsetBy(1, -1))
    gfx.drawLine(originSplitLine:offsetBy(-1, 1))
    gfx.lockFocus(splitImg2)
    
    --splitMask:setInverted(true)
    
    gfx.setStencilImage(cutLineVisualMask1)
    image:draw(0, 0)
    gfx.setDitherPattern(0, gfx.image.kDitherTypeBayer2x2)
    gfx.setLineWidth(1)
    gfx.drawLine(originSplitLine)
    gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
    gfx.drawLine(originSplitLine:offsetBy(1, 1))
    gfx.drawLine(originSplitLine:offsetBy(-1, -1))
    gfx.drawLine(originSplitLine:offsetBy(1, -1))
    gfx.drawLine(originSplitLine:offsetBy(-1, 1))
    
    gfx.unlockFocus()
    gfx.popContext()
    --[[
    pd.debugDraw = function()
        --draw arrows pointing to show the next point on the polygon
        cutLineVisualMask1:draw(0, 0)
        cutLineVisualMask2:draw(70, 0)
        splitMask1:draw(140, 0)
        splitMask2:draw(210, 0)
        mask:draw(280, 0)
    end
    --]]
    splitPolygon:translate(imagePos.x, imagePos.y)
    polygonInverse:translate(imagePos.x, imagePos.y)
    
    return splitImg1, splitImg2, splitPolygon, polygonInverse
end
