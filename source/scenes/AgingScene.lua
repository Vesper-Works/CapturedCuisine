
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
    self.perishAge = self.targetAge * 1.1
    self.gameOver = false
    self.gameStart = false
    self.senstivity = 6 -- not recommended to go past about 75, since it ends up being innacurate. will want to be a decently high number though. could be adjusted with a 'difficulty'?
    self.gameOverText = ""
    self.gameTimer = pd.timer.new(10000)
    self.gameTimer.paused = true


    Noble.Text.setFont(Noble.Text.FONT_LARGE)
end

function scene:init()
    scene.super.init(self) --calls parent constructor
    self:setValues()
    pd.timer.new(3000, function() self.gameStart = true end) 
end

function scene:update()
    scene.super.update(self)
    pd.timer.updateTimers()

    if pd.buttonIsPressed(pd.kButtonB) then
        scene.exit(self)
    end

    if (self.gameOver == false) and (self.gameStart == true) then self:MinigameRoutine() end
    if (self.gameStart == true) then self.gameTimer.paused = false end


    self.gameTimer.updateCallback = function()
        local timeRemaining = tostring(10 - math.floor(self.gameTimer.currentTime/1000))
        if self.gameOver == false then Noble.Text.draw("Time Remaining:  " .. timeRemaining, 20, 100, Noble.Text.ALIGN_LEFT, false, Noble.Text.getCurrentFont()) end
    end

    self.gameTimer.timerEndedCallback = function()
        self.gameOver = true
        self.gameOverText = "GAME OVER!"
        ExitAfterDelay()
    end

    Noble.Text.draw(self.gameOverText, 20, 40, Noble.Text.ALIGN_LEFT, false, Noble.Text.getCurrentFont()) 

    Noble.Text.draw(self.ingredientStatus, 20, 20, Noble.Text.ALIGN_LEFT, false, Noble.Text.getCurrentFont()) 

    self.age = math.clamp(self.age, 0, self.perishAge)

    ProgressBarRoutine(self.age, self.targetAge, self.perishAge, 60, 80, 10)
    Noble.Text.draw("Current Age: " .. self.age, 20, 60, Noble.Text.ALIGN_LEFT, false, Noble.Text.getCurrentFont())
    
end

function scene:MinigameRoutine()
    crankTick = pd.getCrankTicks(self.senstivity)
    self.age += crankTick


    if self.age > self.targetAge then
        self.ingredientStatus = "TOO OLD"
    elseif self.age < self.targetAge then
        self.ingredientStatus = "TOO YOUNG"
    else
        self.ingredientStatus = "JUST RIGHT"
    end

    if self.age >= self.perishAge then
        self.ingredientStatus = "INGREDIENT PERISHED"
        self.gameOver = true
        ExitAfterDelay()
    end
end

function scene:exit()
    self.gameOver = true
    Noble.transition(MainMenu, nil, Noble.Transition.DipToBlack)
end

function ExitAfterDelay()
    pd.timer.performAfterDelay(3000, function() scene:exit() end)
end

function ProgressBarRoutine(age, targetAge, perishAge, xOffset, yOffset, width)
    local length = (400 - 2*xOffset)
    gfx.drawRect(xOffset, yOffset, length, width)
    gfx.drawLine(xOffset + length * (targetAge / perishAge), yOffset, xOffset + length * (targetAge / perishAge), yOffset + 8)
    gfx.fillRect(xOffset, yOffset, length * (age / perishAge), width)
end