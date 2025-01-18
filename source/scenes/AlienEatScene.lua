AlienEatScene = {}
class("AlienEatScene").extends(NobleScene)
local scene = AlienEatScene
local pd = playdate
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    self.sceneText = "This will be where alien eats"
    Noble.Text.setFont(Noble.Text.FONT_LARGE)
end

function scene:init()
    scene.super.init(self) --calls parent constructor
    self:setValues()
end
function scene:update()
    scene.super.update(self)
    Noble.Text.draw(self.sceneText, 20, 20, Noble.Text.ALIGN_CENTER, false, Noble.Text.getCurrentFont()) --it's possible this works but we may need a font asset
    if pd.buttonIsPressed(pd.kButtonB) then
        if OrdersScene.returnNumberOfOutstandingOrders() <= 0 then --if number of orders is less than 0, all orders for the day are finished
            OrdersScene.incrementLevelOrders()
            pd.timer.performAfterDelay(1000, function() Noble.transition(ResturauntScene, nil, Noble.Transition.DipToBlack) end)
        else
            Noble.transition(OrdersScene, nil, Noble.Transition.DipToBlack) --otherwise go back to order scene and complete remaining orders
        end
        scene.exit(self)
    end
end
function scene:exit()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
end