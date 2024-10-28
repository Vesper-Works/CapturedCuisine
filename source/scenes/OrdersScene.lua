import "scenes/Order.lua"
OrdersScene = {}
class("OrdersScene").extends(NobleScene)
local scene = OrdersScene
local pd = playdate
local gfx <const> = pd.graphics
local allOrders = {} --will be filled with new Orders
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    self.a = Order("I want my order to have \n crunchy carrots", "A delightful zesty twist", "Finished with a lime sorbet", "assets/images/bird.png")
    self.b = Order("I want my order to have \n soggy carrots", "A delightful tangy twist", "Finished with an orange yogurt", "assets/images/Potato.png")
    table.insert(allOrders, self.a)
    table.insert(allOrders, self.b)
    self.index = 1;
    Noble.Text.setFont(Noble.Text.FONT_LARGE)
    self.spriteImage = gfx.image.new(allOrders[self.index]:returnPath())
    self.sprite = gfx.sprite.new(self.spriteImage)
    self.sprite:moveTo(50, 200)
    self.sprite:add() --adds to render queue
end

function scene:init()
    scene.super.init(self) --calls parent constructor
    self:setValues()
end
function scene:update()
    scene.super.update(self)
    if pd.buttonJustPressed(pd.kButtonLeft) then
        if self.index - 1 < 1 then
            self.index = #allOrders
        else
            self.index = self.index - 1
        end
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        if self.index + 1 > #allOrders then
            self.index = 1
        else
            self.index = self.index + 1
        end
    end
    Noble.Text.draw(allOrders[self.index]:returnFirstSentence(), 0, 0, Noble.Text.ALIGN_LEFT, false, Noble.Text.getCurrentFont()) --it's possible this works but we may need a font asset
    Noble.Text.draw(allOrders[self.index]:returnSecondSentence(), 0, 50, Noble.Text.ALIGN_LEFT, false, Noble.Text.getCurrentFont()) 
    Noble.Text.draw(allOrders[self.index]:returnThirdSentence(), 0, 100, Noble.Text.ALIGN_LEFT, false, Noble.Text.getCurrentFont())
    self.spriteImage = gfx.image.new(allOrders[self.index]:returnPath())
    self.sprite:setImage(self.spriteImage)
    if pd.buttonIsPressed(pd.kButtonB) then
        scene.exit(self)
    end
end
function scene:exit()
    self.sprite:remove()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(PickIngredientScene, nil, Noble.Transition.DipToBlack)
end