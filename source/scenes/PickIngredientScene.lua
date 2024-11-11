import "utilities/IngredientHandler.lua"
PickIngredientScene = {}
class("PickIngredientScene").extends(NobleScene)
local scene = PickIngredientScene
local pd = playdate
local gfx = pd.graphics
--local ingredients = IngredientHandler.ingredients --gets all ingredients from the ingredient handler class and stores them in a local variable (not overriden)
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    self.sceneText = "This will be where ingredients are picked, there may be dialogue for each one"
    Noble.Text.setFont(Noble.Text.FONT_LARGE)
    self.offset = 0
    self.index = 1
    self.ingredientSelected = false --this will be required to switch between two menus, the ingredient selection menu and the minigame selection menu
end

function scene:init(allAttributes)
    scene.super.init(self) --calls parent constructor
    self.attributes = allAttributes
    self:setValues()
    self:drawIngredient(self.index) --pass through first ingredient
end
function scene:drawIngredient(i)
    local ingredientText = IngredientHandler.getIngredientFromIndex(i).name --this can be extended with string concatanation later
    self.ingredientTextSprite = gfx.sprite.spriteWithText(ingredientText, 400, 200)
    self.ingredientTextSprite:moveTo(200, 100)
    self.ingredientTextSprite:add()
end
function scene:removeAllText()
    self.ingredientTextSprite:remove()
end
function scene:update()
    scene.super.update(self)
    local change, accelerateChange = pd.getCrankChange() --clockwise/anticlockwise, with high accelerateChange representing speed of crank change while change
    self.offset = self.offset + pd.getCrankChange()
    if self.offset > 30 then
        self.offset = 0
        self.index = self.index + 1
        if self.index > 10 then
            self.index = 1
        end
        self:removeAllText()
        self:drawIngredient(self.index)
    elseif self.offset < -30 then
        self.offset = 0
        self.index = self.index - 1
        if self.index < 1 then
            self.index = 10
        end
        self:removeAllText()
        self:drawIngredient(self.index)
    end --seperate if else statement will be required for accessibility
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
    self:removeAllText()
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