import "scenes/Order.lua"
OrdersScene = {}
class("OrdersScene").extends(NobleScene)
local scene = OrdersScene
local pd = playdate
local gfx <const> = pd.graphics
local allOrders = {} --will be filled with new Orders, this will stay constant throughout the game, so once the level is finished, this needs to be cleared
local allDialogue = {} --this will also need to be refilled with all dialogue again
local currentOrders = 2 --this will increase by one but I'll need to figure out how statics work
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    self.index = 1;
    Noble.Text.setFont(Noble.Text.FONT_LARGE)
    self.spriteImage = gfx.image.new("assets/images/bird.png")
    self.sprite = gfx.sprite.new(self.spriteImage)
    self.sprite:moveTo(50, 200)
    self.sprite:add() --adds to render queue
end

function scene:init()
    scene.super.init(self) --calls parent constructor
    self.file = "dialogue/orders.json"
    self.branch = json.decodeFile(self.file)
    allDialogue = self.branch.OrderLines
    self.potentialDialogue = #allDialogue
    self:setValues()
    self:generateOrders()
end
function scene:generateOrders()
    for i = 1,currentOrders do --generate the required number of orders for each level
        local ord = Order(self:pickDialogue(), self:pickDialogue(), self:pickDialogue(), "assets/images/bird.png") --pickDialogue called three times to pick ingredient dialogue for order
        table.insert(allOrders, ord)
        currentOrders = currentOrders - 1
    end
    self:drawAllText(allOrders[1]:returnFirstSentence(), allOrders[1]:returnSecondSentence(), allOrders[1]:returnThirdSentence())
end
function scene:drawAllText(firstText, secondText, thirdText)
    local allText = firstText .. '\n' .. secondText .. '\n' .. thirdText
    self.textSprite = gfx.sprite.spriteWithText(allText, 400, 200)
    self.textSprite:moveTo(200, 100)
    self.textSprite:add()
end
function scene:removeAllText()
    self.textSprite:remove()
end
function scene:pickDialogue()
    local randomNum = math.random(self.potentialDialogue)
    local dial = allDialogue[randomNum]
    table.remove(allDialogue, randomNum)
    self.potentialDialogue = self.potentialDialogue - 1 --randomly picked and then removed from list so that it is not picked again
    return dial
end
function scene:update()
    scene.super.update(self)
    if pd.buttonJustPressed(pd.kButtonLeft) then
        if self.index - 1 < 1 then
            self.index = #allOrders
        else
            self.index = self.index - 1
        end
        self:removeAllText()
        self:drawAllText(allOrders[self.index]:returnFirstSentence(), allOrders[self.index]:returnSecondSentence(), allOrders[self.index]:returnThirdSentence())
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        if self.index + 1 > #allOrders then
            self.index = 1
        else
            self.index = self.index + 1
        end
        self:removeAllText()
        self:drawAllText(allOrders[self.index]:returnFirstSentence(), allOrders[self.index]:returnSecondSentence(), allOrders[self.index]:returnThirdSentence())
    end
    self.spriteImage = gfx.image.new(allOrders[self.index]:returnPath())
    self.sprite:setImage(self.spriteImage)
    if pd.buttonIsPressed(pd.kButtonB) then
        pd.timer.performAfterDelay(0000, function () Noble.transition(PickIngredientScene, nil, Noble.Transition.CrossDissolve, nil, {allAttributes = allOrders[self.index]:returnAdjectives(), firstSentence = allOrders[self.index]:returnFirstSentence(), secondSentence = allOrders[self.index]:returnSecondSentence(), thirdSentence = allOrders[self.index]:returnThirdSentence()})  end)
    end
end
function scene:exit()
    self.sprite:remove()
    self:removeAllText()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    
end