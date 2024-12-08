import 'trackminigame/PlateSprite'
PlateScene = {}
class("PlateScene").extends(NobleScene)
local scene = PlateScene
local pd = playdate
local renderSpriteTable = {}
local sprites = 0
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    Noble.Text.setFont(Noble.Text.FONT_LARGE)
end

function scene:init()
    scene.super.init(self) --calls parent constructor
    self:setValues()
    Plate = PlateSprite(200, 200, 50, 10)
    Plate:add()
end
function scene:update()
    local change, accelerateChange = pd.getCrankChange() --clockwise/anticlockwise, with high accelerateChange representing speed of crank change while change
    if Plate:getX() + pd.getCrankChange() < 25 then
        Plate:move(25, Plate:getY())
    elseif Plate:getX() + pd.getCrankChange() > 375 then
        Plate:move(375, Plate:getY())
    end
    Plate:move(Plate:getX() + pd.getCrankChange(), Plate:getY())
    scene.super.update(self)
    if pd.buttonIsPressed(pd.kButtonB) then
        scene.exit(self)
    end
end
function scene:exit()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Plate:remove()
    Noble.transition(PickIngredientScene, nil, Noble.Transition.DipToBlack)
end