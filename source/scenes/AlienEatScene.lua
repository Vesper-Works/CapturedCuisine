AlienEatScene = {}
class("AlienEatScene").extends(NobleScene)
local scene = AlienEatScene
local pd = playdate
local totalDayRep = 0
local repThreshold = 30
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    self.sceneText = "This will be where alien eats"
    Noble.Text.setFont(Noble.Text.FONT_LARGE)
end

function scene:init(__sceneProperties)
    scene.super.init(self, __sceneProperties) --calls parent constructor
    self.rep = __sceneProperties.rep
    totalDayRep = totalDayRep + self.rep
    self:setValues()
end
function scene:update()
    scene.super.update(self)
    Noble.Text.draw(self.sceneText, 20, 20, Noble.Text.ALIGN_CENTER, false, Noble.Text.getCurrentFont()) --it's possible this works but we may need a font asset
    if pd.buttonJustPressed(pd.kButtonB) then
        if OrdersScene.returnNumberOfOutstandingOrders() <= 0 then --if number of orders is less than 0, all orders for the day are finished
            local averageDayRep = totalDayRep / OrdersScene.returnNumberOfDayOrders()
            local message = ""
            local succeed = false
            print(totalDayRep)
            print(averageDayRep)
            if(averageDayRep >= repThreshold) then
                message = "I'm very pleased with your work today, good job"
                succeed = true
                print("Good Day")
            elseif(averageDayRep < repThreshold) then
                message = "I'm very displeased with your work today. Do better"
                succeed = false
                print("Bad Day")
            end
            OrdersScene.incrementLevelOrders()
            repThreshold = repThreshold + 20
            print(repThreshold)
            pd.timer.performAfterDelay(1000, function() Noble.transition(BossScene, nil, Noble.Transition.DipToBlack, nil, {bossMessage = message, succeeded=succeed}) end)
        else
            Noble.transition(OrdersScene, nil, Noble.Transition.DipToBlack) --otherwise go back to order scene and complete remaining orders
        end
        scene.exit(self)
    end
end
function scene:exit()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
end