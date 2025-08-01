import 'trackminigame/PlateSprite'
PlateScene = {}
class("PlateScene").extends(NobleScene)
local scene = PlateScene
local pd = playdate
local gfx = pd.graphics
local renderSpriteTable = {}
local sprites = 0
local timesCalled = 0
local ingredientsRep = {0, 0, 0}
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    Noble.Text.setFont(Noble.Text.FONT_LARGE)
    self.speed = 0.3
    self.acceleration = 0.098 --gravity
    self.startingY = 200
end

function scene:init(__sceneProperties)
    self.rep = __sceneProperties.rep
    scene.super.init(self) --calls parent constructor
    self:setValues()
    Plate = PlateSprite(200, 200, 50, 10)
    Plate:add()
    print(self.rep)
    --totalRep = totalRep + self.rep
    timesCalled = timesCalled + 1
    if sprites ~= 0 then
        for i, v in ipairs(renderSpriteTable) do
            RenderSprite = renderSpriteTable[i]
            RenderSprite:move(200, self.startingY - (RenderSprite:getHeight() - 10))
            self.startingY = self.startingY - (RenderSprite:getHeight() - 10)
            RenderSprite:add() --these are sprites that should no longer be moved as they are ingredients that have already been placed
        end
    end
    local randomXPos = math.random(50, 350)
    NewIngredientSprite = PlateSprite(randomXPos, 50, 30, 30) --current ingredient that will fall
    NewIngredientSprite:add()
    print("TimesCalled: " .. timesCalled)
    self.isThisAdjective = AdjectiveHandler.checkAdjective()
end
function scene:update()
    --NewIngredientSprite.update()
    --Plate.update()
    self.speed = self.speed + self.acceleration
    if NewIngredientSprite:move(NewIngredientSprite:getX(), NewIngredientSprite:getY() + self.speed) == true then
        print("We have called this")
        table.insert(renderSpriteTable, NewIngredientSprite)
        NewIngredientSprite:remove()
        sprites = sprites + 1
        print(self.isThisAdjective)
        if (self.isThisAdjective == true) then
            ingredientsRep[timesCalled] = self.rep
        else
            ingredientsRep[timesCalled] = (self.rep / 2) 
        end
        print(ingredientsRep[timesCalled])
        self:checkSceneEnd()
    end
    if NewIngredientSprite:getY() > 400 then
        print("Called this")
        PickIngredientScene.updateReputation(0)
        ingredientsRep[timesCalled] = 0
        NewIngredientSprite:remove()
        PickIngredientScene.reset() --should hopefully reset all static variables for pick ingredient
        self:checkSceneEnd()
    end
    local change, accelerateChange = pd.getCrankChange() --clockwise/anticlockwise, with high accelerateChange representing speed of crank change while change
    if Plate:getX() + pd.getCrankChange() < (Plate:getWidth() / 2) then
        Plate:move((Plate:getWidth() / 2), Plate:getY())
    elseif Plate:getX() + pd.getCrankChange() > 400 - (Plate:getWidth() / 2) then
        Plate:move(400 - (Plate:getWidth() / 2), Plate:getY())
    end
    Plate:move(Plate:getX() + pd.getCrankChange(), Plate:getY())
    if sprites ~= 0 then
        for i, v in ipairs(renderSpriteTable) do
            RenderSprite = renderSpriteTable[i]
            --RenderSprite:update()
            RenderSprite:move(Plate:getX(), RenderSprite:getY())
        end
    end
    scene.super.update(self)
    if pd.buttonIsPressed(pd.kButtonB) then
        scene.exit(self)
    end
end
function scene:checkSceneEnd()
    if timesCalled == 3 then
            print(ingredientsRep[1])
            OrdersScene.removeFinishedOrder()
            local totalRep = ingredientsRep[1] + ingredientsRep[2] + ingredientsRep[3]
            print(totalRep)
            local averageRep = totalRep / 3 --calculate the average Reputation for all sprites
            print(averageRep)
            Noble.transition(AlienEatScene, nil, Noble.DipToBlack, nil, {rep = averageRep})
            timesCalled = 0
            PickIngredientScene.reset() --should hopefully reset all static variables for pick ingredient
            ingredientsRep = {0, 0, 0}
            self:resetSprites()
        else
            IngredientHandler.resetStartRep() -- everytime an ingredient is plated the default reputation must be reset
            PickIngredientScene.reset() --should hopefully reset all static variables for pick ingredient
            Noble.transition(PickIngredientScene, nil, Noble.Transition.DipToBlack)
        end
end
function scene:exit()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Plate:remove()
    if sprites ~= 0 then
        for i, v in ipairs(renderSpriteTable) do
            RenderSprite = renderSpriteTable[i]
            RenderSprite:remove()
        end
    end
end
function PlateScene.returnSprites()
    return sprites
end
function scene:resetSprites()
    if sprites ~= 0 then
        for i, v in ipairs(renderSpriteTable) do
            RenderSprite = renderSpriteTable[i]
            RenderSprite:remove()
        end
    end
    renderSpriteTable = {}
    sprites = 0
end