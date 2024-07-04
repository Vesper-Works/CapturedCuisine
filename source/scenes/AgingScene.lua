
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


    -- line stuff
    gfx.setLineWidth(4)
    gfx.setLineCapStyle(gfx.kLineCapStyleRound)

    -- game stuff
    self.rotationSpeed = math.random(1, 5)
    self.xVel = 0;

    -- game logic stuff
    self.gameOver = false
    self.gameStarted = false
    self.timeLimit = 10000

    self.gameTimer = tmr.new(self.timeLimit, function ()
        self.gameOver = true
    end)
    self.gameTimer.paused = true

    self.startTimer = tmr.new(3000, function()
        self.gameStarted = true
        self.gameTimer.paused = false
    end)
    self.startTimer.paused = true

    -- sprite stuff
    self.image = gfx.image.new("assets/images/potato.png")
    self.sprite = gfx.sprite.new(self.image)
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

    -- game logic
    if not self.gameStarted then
        TimeBarRoutine(20, 20, 10, 3000, self.startTimer, true)
        Noble.Text.draw("Booting up the time machine!", 200, 40, Noble.Text.ALIGN_CENTER, false, Noble.Text.getCurrentFont) 
        Noble.Text.draw("You have " .. math.floor(tonumber(self.timeLimit / 1000)) .. " seconds.", 200, 60, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_SMALL)
    end

    gfx.drawLine(40, 360, 360, 360)

    self.gameTimer.timerEndedCallback = function()
        self:GameOver()
    end

    -- debug
    --print("xVel: " .. self.xVel)
    --print("gameOver: " .. tostring(self.gameOver) .. " gameStarted: " .. tostring(self.gameStarted))


    -- do rotation and zeroG and input stuff
    if not self.gameOver and self.gameStarted then
        ZeroGRoutine(self.sprite, self.xVel);
        self.xVel = VelocityRoutine(self.xVel)

        -- while game is running, show timer bar and current time
        TimeBarRoutine(20, 20, 10, self.timeLimit, self.gameTimer, false)
        Noble.Text.draw("Time Remaining: " .. math.floor(tonumber(self.gameTimer.timeLeft / 1000)) .. " seconds", 200, 40, Noble.Text.ALIGN_CENTER, false, Noble.Text.FONT_SMALL)
    end

    SpriteRotationRoutine(self.sprite, self.rotationSpeed)
    ClampPosition(self.sprite, 40, 360)
end

function scene:GameOver()
    self.gameOver = true
    self.xVel = 0
    ExitAfterDelay(self.sprite)
end

function scene:exit()
    self.gameOver = true

    
    Noble.transition(MainMenu, nil, Noble.Transition.DipToBlack)
end

function ExitAfterDelay(sprite)

    tmr.performAfterDelay(3000, function()
        scene:exit()
        sprite:remove()
    end)
end

function TimeBarRoutine(xOffset, yOffset, width, timeLimit, timer, reverse)

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

function CalcScore(age, targetAge)
    local distance
    local score
    distance = math.abs(targetAge - age)
    if distance == 1 then
        score = 1 - (1 / targetAge)
    elseif distance == 0 then
        score = 1
    elseif distance == targetAge then
        score = 0
    else
        score = 1 / (distance)
    end

    return score
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