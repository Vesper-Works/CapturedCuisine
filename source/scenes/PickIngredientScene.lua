PickIngredientScene = {}
class("PickIngredientScene").extends(NobleScene)
local scene = PickIngredientScene
local pd = playdate
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    self.sceneText = "This will be where ingredients are picked, there may be dialogue for each one"
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
        scene.exit(self)
    elseif pd.buttonIsPressed(pd.kButtonDown) then
        scene.chooseLaser(scene)
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        scene.chooseSweet(scene)
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        scene.chooseAge(scene)
    elseif pd.buttonIsPressed(pd.kButtonUp) then
        scene.chooseCrank(scene)
    elseif pd.buttonIsPressed(pd.kButtonA) then
        scene.choosePlate(scene)
    end
end
function scene:exit()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(OrdersScene, nil, Noble.Transition.DipToBlack)
end
function scene:chooseLaser()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(LaserMinigame, nil, Noble.Transition.DipToBlack)
end
function scene:chooseSweet()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(SweetTalking, nil, Noble.Transition.DipToBlack)
end
function scene:chooseAge()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(AgingScene, nil, Noble.Transition.DipToBlack)
end
function scene:chooseCrank()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(CrankScene, nil, Noble.Transition.DipToBlack)
end
function scene:choosePlate()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(PlateScene, nil, Noble.Transition.DipToBlack)
end