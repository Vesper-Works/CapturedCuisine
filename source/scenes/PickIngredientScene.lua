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
    self.currentIngredient = nil
    self.crankTurned = false
    self.offset = 0
end

function scene:init(__sceneProperties)
    scene.super.init(self, __sceneProperties) --calls parent constructor
    self.attributes = __sceneProperties.allAttributes
    self:setValues()
    self:drawIngredient(self.index) --pass through first ingredient
    self.firstSentence = __sceneProperties.firstSentence
    self.secondSentence = __sceneProperties.secondSentence
    self.thirdSentence = __sceneProperties.thirdSentence
    print("New Scene")
    print(__sceneProperties)
end
function scene:drawIngredient(i)
    local ingredientText = IngredientHandler.getIngredientFromIndex(i).name --this can be extended with string concatanation later
    self.ingredientTextSprite = gfx.sprite.spriteWithText(ingredientText, 400, 200)
    self.ingredientTextSprite:moveTo(200, 100)
    self.ingredientTextSprite:add()
    self.offset = 0
end
function scene:removeAllText()
    self.ingredientTextSprite:remove()
end
function scene:drawActions()
    local text = "Choose Cooking Method \n Left for Sweet Talking \n Up for Firing \n Down for Laser Cutting \n Right for Aging"
    self.ingredientTextSprite = gfx.sprite.spriteWithText(text, 400, 200)
    self.ingredientTextSprite:moveTo(200, 100)
    self.ingredientTextSprite:add()
    self.offset = 0
end
function scene:drawAllText(firstText, secondText, thirdText)
    local allText = firstText .. '\n' .. secondText .. '\n' .. thirdText
    self.ingredientTextSprite = gfx.sprite.spriteWithText(allText, 400, 200)
    self.ingredientTextSprite:moveTo(200, 100)
    self.ingredientTextSprite:add()
    self.offset = 0
end
function scene:update()
    scene.super.update(self)
    local change, accelerateChange = pd.getCrankChange() --clockwise/anticlockwise, with high accelerateChange representing speed of crank change while change
    self.offset = self.offset + pd.getCrankChange()
    if self.crankTurned == false and self.offset > 30 then
        self.crankTurned = true
        self.offset = 0
        self:removeAllText()
        self:drawAllText(self.firstSentence, self.secondSentence, self.thirdSentence)
    elseif self.crankTurned == true and self.offset < -30 then
        self.crankTurned = false
        self.offset = 0
        self:removeAllText()
        if self.ingredientSelected == true then
            self:drawActions()
        elseif self.ingredientSelected == false then
            self:drawIngredient(self.index)
        end
    end
    if self.ingredientSelected == false and self.crankTurned == false then
        if pd.buttonJustPressed(pd.kButtonLeft) then
            --self.offset = 0
            self.index = self.index + 1
            if self.index > 10 then
                self.index = 1
            end
            self:removeAllText()
            self:drawIngredient(self.index)
        elseif pd.buttonJustPressed(pd.kButtonRight) then
            --self.offset = 0
            self.index = self.index - 1
            if self.index < 1 then
                self.index = 10
            end
            self:removeAllText()
            self:drawIngredient(self.index)
        end --seperate if else statement will be required for accessibility
        if pd.buttonJustPressed(pd.kButtonA) then
            self.ingredientSelected = true
            self.currentIngredient = IngredientHandler.getIngredientFromIndex(self.index)
            self:removeAllText()
            self:drawActions()
            return
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            scene.exit(self)
        end
    end
    if self.ingredientSelected == true and self.crankTurned == false then
        if pd.buttonJustPressed(pd.kButtonB) then
            self.ingredientSelected = false
            self.currentIngredient = nil
            self:removeAllText()
            self:drawIngredient(self.index)
            return
        elseif pd.buttonJustPressed(pd.kButtonDown) then
            scene.chooseLaser(scene)
        elseif pd.buttonJustPressed(pd.kButtonLeft) then
            scene.chooseSweet(scene)
        elseif pd.buttonJustPressed(pd.kButtonRight) then
            scene.chooseAge(scene)
        elseif pd.buttonJustPressed(pd.kButtonUp) then
            scene.chooseCrank(scene)
        elseif pd.buttonJustPressed(pd.kButtonA) then
            scene.choosePlate(scene)
            --when one of these minigames is picked, save the game
        end
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