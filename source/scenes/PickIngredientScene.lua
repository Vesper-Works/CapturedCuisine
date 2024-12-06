import "utilities/IngredientHandler.lua"
PickIngredientScene = {}
class("PickIngredientScene").extends(NobleScene)
local scene = PickIngredientScene
local pd = playdate
local gfx = pd.graphics
local workingOnOrder = false --this should be false the first time this scene is loaded, but turned to true once an order is worked on
local selectedIngredient = nil
local attributes = nil --locals should mean that, when scene is reloaded, order can still be viewed
local firstSentence = nil
local secondSentence = nil
local thirdSentence = nil
local plateSpriteTable = {} --this will contain all the sprites required for the plating minigame
local currentIndex = nil
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

function scene:init(__sceneProperties) --there is no function overriding in lua
    scene.super.init(self, __sceneProperties) --calls parent constructor
    attributes = __sceneProperties.allAttributes
    self:setValues()
    if workingOnOrder == false then
        print("Called the function for sentences")
        self:drawIngredient(self.index) --pass through first ingredient
        firstSentence = __sceneProperties.firstSentence
        secondSentence = __sceneProperties.secondSentence
        thirdSentence = __sceneProperties.thirdSentence
    else
        self:drawActions()
    end
    print("I am " .. tostring(workingOnOrder))
end
function scene:drawIngredient(i)
    local ingredient = IngredientHandler.getIngredientFromIndex(i)
    local ingredientText = ingredient.name .. '\n' .. ingredient.properties .. "\nLiked methods: " .. ingredient.revealedPrep --this can be extended with string concatanation later
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
        self:drawAllText(firstSentence, secondSentence, thirdSentence)
    elseif self.crankTurned == true and self.offset < -30 then
        self.crankTurned = false
        self.offset = 0
        self:removeAllText()
        if selectedIngredient ~= nil then
            self:drawActions()
        else
            if self.ingredientSelected == true then
                self:drawActions()
            elseif self.ingredientSelected == false then
                self:drawIngredient(self.index)
            end
        end
    end
    if self.ingredientSelected == false and self.crankTurned == false and workingOnOrder == false then
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
            selectedIngredient = self.currentIngredient
            currentIndex = self.index
            self:removeAllText()
            self:drawActions()
            return
        end
        if pd.buttonJustPressed(pd.kButtonB) then
            scene.exit(self)
        end
    end
    if (self.ingredientSelected == true or workingOnOrder == true) and self.crankTurned == false then
        if pd.buttonJustPressed(pd.kButtonB) and workingOnOrder == false then
            self.ingredientSelected = false
            self.currentIngredient = nil
            self:removeAllText()
            self:drawIngredient(self.index)
            return
        elseif pd.buttonJustPressed(pd.kButtonDown) then
            workingOnOrder = true
            scene.chooseLaser(scene)
        elseif pd.buttonJustPressed(pd.kButtonLeft) then
            workingOnOrder = true
            scene.chooseSweet(scene)
        elseif pd.buttonJustPressed(pd.kButtonRight) then
            workingOnOrder = true
            scene.chooseAge(scene)
        elseif pd.buttonJustPressed(pd.kButtonUp) then
            workingOnOrder = true
            scene.chooseCrank(scene)
        elseif pd.buttonJustPressed(pd.kButtonA) then
            workingOnOrder = false
            selectedIngredient = nil
            scene.choosePlate(scene)
            --when one of these minigames is picked, save the game
        end
    end
end
function scene:exit()
    self:removeAllText()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    pd.timer.performAfterDelay(0000, function() Noble.transition(OrdersScene, nil, Noble.Transition.DipToBlack) end)
end
function scene:chooseLaser()
    local prefer = self:checkPreferredMethods(selectedIngredient.preferredPreparationMethods, "Laser Cutting")
    if prefer == true then
        IngredientHandler.likedMethodRevealed(currentIndex, "Laser Cutting")
    end
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    pd.timer.performAfterDelay(0000, function() Noble.transition(LaserMinigame, nil, Noble.Transition.DipToBlack, nil, {prefferedMethods = prefer}) end)
end
function scene:chooseSweet()
    local prefer = self:checkPreferredMethods(selectedIngredient.preferredPreparationMethods, "Sweet Talking")
    if prefer == true then
        IngredientHandler.likedMethodRevealed(currentIndex, "Sweet Talking")
    end
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    pd.timer.performAfterDelay(0000, function() Noble.transition(SweetTalking, nil, Noble.Transition.DipToBlack, nil, {prefferedMethods = prefer}) end)
end
function scene:chooseAge()
    local prefer = self:checkPreferredMethods(selectedIngredient.preferredPreparationMethods, "Aging")
    if prefer == true then
        IngredientHandler.likedMethodRevealed(currentIndex, "Aging")
    end
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    pd.timer.performAfterDelay(0000, function() Noble.transition(AgingScene, nil, Noble.Transition.DipToBlack, nil, {prefferedMethods = prefer}) end)
end
function scene:chooseCrank()
    local prefer = self:checkPreferredMethods(selectedIngredient.preferredPreparationMethods, "Alien Fryer")
    if prefer == true then
        IngredientHandler.likedMethodRevealed(currentIndex, "Alien Fryer")
    end
    pd.timer.performAfterDelay(0000, function() Noble.transition(CrankScene, nil, Noble.Transition.DipToBlack, nil, {prefferedMethods = prefer}) end)
end
function scene:choosePlate()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    pd.timer.performAfterDelay(0000, function() Noble.transition(PlateScene, nil, Noble.Transition.DipToBlack) end)
end
function scene:checkPreferredMethods(methods, methodUsed)
    local lookUpTable = buildLookUpTable(methods)
    return lookUpTable[methodUsed] or false
end
function buildLookUpTable(table) --check which methods in table are the preferred methods (could also be used for disliked methods). This may have a storage complexity of O(N) however
    local lookUp = {}
    for _, value in ipairs(table) do
        print(value)
        lookUp[value] = true
    end
    return lookUp
end