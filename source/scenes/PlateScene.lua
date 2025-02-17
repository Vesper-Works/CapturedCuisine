import 'trackminigame/PlateSprite'
PlateScene = {}
class("PlateScene").extends(NobleScene)
local scene = PlateScene
local pd = playdate
local renderSpriteTable = {}
local totalRep = 0
local sprites = 0
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
    print(self.rep)
    scene.super.init(self) --calls parent constructor
    self:setValues()
    Plate = PlateSprite(200, 200, 50, 10)
    Plate:add()
    totalRep = totalRep + self.rep
    print(totalRep)
    if sprites ~= 0 then
        for i, v in ipairs(renderSpriteTable) do
            RenderSprite = renderSpriteTable[i]
            print(RenderSprite:getX(), RenderSprite:getY())
            RenderSprite:move(200, self.startingY - (RenderSprite:getHeight() - 10))
            self.startingY = self.startingY - (RenderSprite:getHeight() - 10)
            RenderSprite:add() --these are sprites that should no longer be moved
        end
    end
    NewIngredientSprite = PlateSprite(200, 50, 30, 30)
    NewIngredientSprite:add()
end
function scene:update()
    self.speed = self.speed + self.acceleration
    if NewIngredientSprite:move(NewIngredientSprite:getX(), NewIngredientSprite:getY() + self.speed) == true then
        table.insert(renderSpriteTable, NewIngredientSprite)
        NewIngredientSprite:remove()
        sprites = sprites + 1
        if sprites == 3 then
            local averageRep = totalRep / 3 --calculate the average Reputation for all sprites
            print(averageRep)
            OrdersScene.removeFinishedOrder()
            Noble.transition(AlienEatScene, nil, Noble.DipToBlack)
            PickIngredientScene.reset() --should hopefully reset all static variables for pick ingredient
            totalRep = 0
        else
            Noble.transition(PickIngredientScene, nil, Noble.Transition.DipToBlack)
        end
        PickIngredientScene.updateReputation(0) --reputation needs to reset
    end
    if NewIngredientSprite:getY() > 250 then
        PickIngredientScene.updateReputation(0)
        NewIngredientSprite:remove()
        Noble.transition(PickIngredientScene, nil, Noble.Transition.DipToBlack)
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
            RenderSprite:move(Plate:getX(), RenderSprite:getY())
        end
    end
    scene.super.update(self)
    if pd.buttonIsPressed(pd.kButtonB) then
        scene.exit(self)
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
    if sprites == 3 then
        renderSpriteTable = {}
        sprites = 0
    end
end
function PlateScene.returnSprites()
    return sprites
end