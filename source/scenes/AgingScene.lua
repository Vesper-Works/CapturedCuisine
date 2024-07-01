
import "CoreLibs/crank"
import "CoreLibs/timer"
import "CoreLibs/graphics"

AgingScene = {}
class("AgingScene").extends(NobleScene)
local scene = AgingScene
local pd = playdate

local gfx <const> = pd.graphics

function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
	self.color2 = Graphics.kColorWhite

    self.ingredientStatus = "Booting up time machine"
    self.timeLimit = 10
    self.age = 0
    self.targetAge = 30
    self.perishAge = self.targetAge * 2
    self.gameOver = false
    self.gameStart = false
    self.senstivity = 6 -- not recommended to go past about 75, since it ends up being innacurate. will want to be a decently high number though. could be adjusted with a 'difficulty'?
    self.timeLimit = 2000
    self.gameTimer = pd.timer.new(self.timeLimit)
    self.gameTimer.paused = true

    self.chargeTimer = pd.timer.new(3000, function() self.gameStart = true end) 

    Noble.Text.setFont(Noble.Text.FONT_LARGE)
end

function scene:init()
    scene.super.init(self) --calls parent constructor
    self:setValues()
end

function scene:update()
    scene.super.update(self)
    pd.timer.updateTimers()



    if (self.gameOver == false) and (self.gameStart == true) then 
        self:MinigameRoutine() 
        TimeBarRoutine(0, 230, 10, self.timeLimit, self.gameTimer, false)
    end
    if (self.gameStart == true) then self.gameTimer.paused = false end
    if (self.gameStart == false) then 
        TimeBarRoutine(0, 230, 10, 3000, self.chargeTimer, true) 
        Noble.Text.draw("You have " .. math.floor(tonumber(self.timeLimit / 1000)) .. " seconds.", 200, 215, Noble.Text.ALIGN_CENTER, false, Noble.Text.getCurrentFont()) 
    end 


    self.gameTimer.updateCallback = function()
    end

    self.gameTimer.timerEndedCallback = function()
        self:GameOver()
    end

    -- game loop
    if self.gameOver == false then

        --ingredient status text
        Noble.Text.draw(self.ingredientStatus, 200, 20, Noble.Text.ALIGN_CENTER, false, Noble.Text.getCurrentFont()) 
    
        self.age = math.clamp(self.age, 0, self.perishAge)
    
        ProgressBarRoutine(self.age, self.targetAge, self.perishAge, 60, 80, 10)

        Noble.Text.draw("Current Age: " .. self.age, 200, 60, Noble.Text.ALIGN_CENTER, false, Noble.Text.getCurrentFont())  
    end

    -- end of game
    if self.gameOver == true then
        Noble.Text.draw("Score: " .. CalcScore(self.age, self.targetAge), 200, 120, Noble.Text.ALIGN_CENTER, false, Noble.Text.getCurrentFont())  
    end
end

function scene:MinigameRoutine()
    local crankTick = pd.getCrankTicks(self.senstivity)
    self.age += crankTick


    if self.age > self.targetAge then
        self.ingredientStatus = "TOO OLD"
    elseif self.age < self.targetAge then
        self.ingredientStatus = "TOO YOUNG"
    else
        self.ingredientStatus = "JUST RIGHT"
    end

end

function scene:GameOver()
    self.gameOver = true
    ExitAfterDelay()
end

function scene:exit()
    self.gameOver = true
    Noble.transition(MainMenu, nil, Noble.Transition.DipToBlack)
end

function ExitAfterDelay()
    pd.timer.performAfterDelay(3000, function() scene:exit() end)
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

function ProgressBarRoutine(age, targetAge, perishAge, xOffset, yOffset, width)
    local length = (400 - 2*xOffset)
    gfx.drawRect(xOffset, yOffset, length, width)
    gfx.drawLine(xOffset + length * (targetAge / perishAge), yOffset, xOffset + length * (targetAge / perishAge), yOffset + 8)
    gfx.fillRect(xOffset, yOffset, length * (age / perishAge), width)
end

function CalcScore(age, targetAge)
    local distance
    local score
    distance = math.abs(targetAge - age)
    if distance == 1 then score = 1 - (1 / targetAge)
    elseif distance == 0 then score = 1
    elseif distance == targetAge then score = 0 
    else score = 1 / (distance)
    end

    return score
end