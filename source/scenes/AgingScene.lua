
import "CoreLibs/crank"
import "CoreLibs/timer"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

AgingScene = {}
class("AgingScene").extends(NobleScene)
local scene = AgingScene
local pd = playdate

local gfx <const> = pd.graphics
local tmr <const> = pd.timer

function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
	self.color2 = Graphics.kColorWhite

    -- game stuff
    self.rotationSpeed = math.random(1, 3)
    self.xVel = 0
    self.xInd = 200
    print("setting phase seed")
    self.phaseSeed = math.random(1, 1000) / 7000
    print("phase seed set " .. self.phaseSeed)
    self.score = 0

    self.barVal = 0
    self.maxBarVal = 100

    -- game logic stuff
    self.gameOver = false
    self.gameStarted = false
    self.timeLimit = 25000

    self.gameTimer = tmr.new(self.timeLimit, function ()
        self.gameOver = true
    end)
    self.gameTimer.paused = true

    self.startTimer = tmr.new(3000, function()
        self.gameStarted = true
        self.gameTimer.paused = false
        self.scoreRepeatTimer.paused = false
    end)
    self.startTimer.paused = true

    self.scoreRepeatTimer = tmr.new(100, function()
        self.barVal = ScoreRoutine(self.barVal, self.maxBarVal, self.sprite, self.xInd, 20)
    end)
    self.scoreRepeatTimer.paused = true
    self.scoreRepeatTimer.repeats = true

    -- sprite stuff
    self.image = gfx.image.new("assets/images/potato.png")
    self.sprite = gfx.sprite.new(self.image)
    self.sprite:setZIndex(10)
    self.sprite:setScale(0.75)
    self.sprite:moveTo(200, 120)
    self.sprite:add()

    Noble.Text.setFont(Noble.Text.FONT_LARGE)
end

function scene:init()
    scene.super.init(self) --calls parent constructor
    self:setValues()
end

function scene:start()
    scene.super.start(self)
    self.startTimer.paused = false

    
end

function scene:update()
    scene.super.update(self)
    tmr.updateTimers()
    playdate.frameTimer.updateTimers()

    -- draw indicators
    gfx.setLineWidth(3)
    gfx.drawLine(self.sprite.x, 86, self.sprite.x, 94)

    gfx.setLineWidth(2)
    gfx.setStrokeLocation(gfx.kStrokeOutside)
    gfx.drawRoundRect(10, 90, 380, 57, 4)

    -- game logic
    if not self.gameStarted then
        TimeBarRoutine(20, 20, 10, 3000, self.startTimer, true)
        Noble.Text.draw("Booting up the time machine!", 200, 40, Noble.Text.ALIGN_CENTER, false, Noble.Text.getCurrentFont) 
        Noble.Text.draw("You have " .. math.floor(tonumber(self.timeLimit / 1000)) .. " seconds.", 200, 60, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_SMALL)
    end

    self.gameTimer.timerEndedCallback = function()
        self:GameOver()
        self.xVel = 0
    end

    -- do rotation and zeroG and input stuff
    if not self.gameOver and self.gameStarted then
        ZeroGRoutine(self.sprite, self.xVel)
        self.xVel = VelocityRoutine(self.xVel)

        -- score stuff
        DrawScoreBar(self.barVal, self.maxBarVal, self.sprite, 50, 5)

        -- while game is running, show timer bar and current time
        TimeBarRoutine(20, 20, 10, self.timeLimit, self.gameTimer, false)
        Noble.Text.draw("Time Remaining: " .. math.floor(tonumber(self.gameTimer.timeLeft / 1000)) .. " seconds", 200, 40, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_SMALL)
    end

    SpriteRotationRoutine(self.sprite, self.rotationSpeed)
    self.xInd = IndicatorRoutine(self.xInd, self.phaseSeed)

    -- game over
    if self.gameOver then
        Noble.Text.draw("Game Over!", 200, 40, Noble.Text.ALIGN_CENTER, false, Noble.Text.getCurrentFont)
        Noble.Text.draw("Final Score: " .. self.score, 200, 60, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_SMALL)
    end

    -- debug
    --print("xVel: " .. self.xVel)
    --print("gameOver: " .. tostring(self.gameOver) .. " gameStarted: " .. tostring(self.gameStarted))
    --print("lineWidth: " .. gfx.getLineWidth())
    --print(self.phaseSeed)
end

function scene:GameOver()
    self.gameOver = true
    self.xVel = 0
    self.score = CalcScore(self.barVal, self.maxBarVal)
    ExitAfterDelay(self.sprite)
end

function scene:exit()
    self.gameOver = true

    Noble.transition(PickIngredientScene, nil, Noble.Transition.DipToBlack)
end

function ExitAfterDelay(sprite)
    tmr.performAfterDelay(3000, function()
        scene:exit()
        sprite:remove()
    end)
end

function TimeBarRoutine(xOffset, yOffset, width, timeLimit, timer, reverse)
    -- set line width
    gfx.setLineWidth(1)

    -- get time remaining
    local timeRemaining = timeLimit - timer.currentTime

    -- make bar
    local length = (400 - 2*xOffset)
    gfx.drawRect(xOffset, yOffset, length, width)
    if reverse then
        gfx.fillRect(xOffset, yOffset, length * (1 - (timeRemaining / timeLimit)), width)
    else
        gfx.fillRect(xOffset, yOffset, length * (timeRemaining / timeLimit), width)
    end

end

function CalcScore(score, maxScore)
    return score / maxScore
end

function SpriteRotationRoutine(sprite, speed)
    -- get rot
    local currentRot = sprite:getRotation(speed)
    -- add rot
    currentRot += speed
    -- set rot
    sprite:setRotation(currentRot)
end

function ZeroGRoutine(sprite, speed)
    -- get pos
    local x, y = sprite:getPosition()
    -- add pos
    x += speed
    -- set pos
    sprite:moveTo(x, y)
    ClampPosition(sprite, 40, 360)
end

function VelocityRoutine(xVelocity)
    local change, acceleratedChange = playdate.getCrankChange()
    return xVelocity + (change / 100)
end

function ClampPosition(sprite, min, max)
    local x, y = sprite:getPosition()
    if x < min then
        sprite:moveTo(min, y)
    elseif x > max then
        sprite:moveTo(max, y)
    end
end

function IndicatorRoutine(x, seed)
    local t = pd.getCurrentTimeMilliseconds()

    -- change x
    x = (0.7*(math.sin((2/5500) * t + seed)) +
    (-0.4)*(math.sin((3/5500) * t + seed)) +
    0.4*(math.cos((2/5500) * t + seed)) +
    math.cos((4/5500) * t + seed) +
    0.7*(math.cos((7/5500) * t + seed))) * 50 + 200

    -- apply x
    gfx.setLineWidth(1)
    gfx.drawLine(x, 90, x, 90+57) -- gfx.drawRoundRect(10, 90, 380, 57, 4)

    return x

    --[[

    fourier wave for f/2
    0.7sin(2t) + (-0.4)sin(3t) + 0.4cos(2t) + cos(4t) + 0.7cos(7t)

    ]]--
end



function DrawScoreBar(score, maxScore, sprite, width, height)
    -- Calculate the percentage
    local percentage = score / maxScore

    -- Calculate the length of the filled bar
    local filledLength = width * percentage

    -- Set the line width
    gfx.setLineWidth(1)

    -- Draw the background bar
    gfx.drawRect(sprite.x - width/2, sprite.y - 50, width, height)

    -- Draw the filled bar
    gfx.fillRect(sprite.x - width/2, sprite.y - 50, filledLength, height)
end

function ScoreRoutine(score, maxScore, sprite, target, difficulty)
    -- Increment score if self.xInd is within range

    print("target: " .. target, "sprite.x: " .. sprite.x, "difference: " .. target-sprite.x, "difficulty: " .. difficulty)


    if math.abs(target - sprite.x) <= difficulty then
        score += 1
        if score > maxScore then
            score = maxScore
        end
    else
        score -= 1
        if score < 0 then
            score = 0
        end
    end

    return score
end