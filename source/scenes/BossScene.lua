BossScene = {}
class("BossScene").extends(NobleScene)
local scene = BossScene
local pd = playdate
local gfx <const> = pd.graphics
local numberOfGoodDays = 0
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
function scene:init(__sceneProperties)
    scene.super.init(self, __sceneProperties) --calls parent constructor
    self.message = __sceneProperties.bossMessage
    self.addIngredient = __sceneProperties.succeeded
    if(self.addIngredient) then
        numberOfGoodDays = numberOfGoodDays + 1 --if number of good days is greater than 1 this will mean the game is won
    end
    self:drawAllText()
end
function scene:drawAllText()
    self.textSprite = gfx.sprite.spriteWithText(self.message, 400, 200)
    self.textSprite:moveTo(200, 100)
    self.textSprite:add()
end
function scene:removeAllText()
    self.textSprite:remove()
end
function scene:update()
    scene.super.update()
    if pd.buttonIsPressed(pd.kButtonB) then
        scene.exit(self)
        pd.timer.performAfterDelay(1000, function() Noble.transition(ResturauntScene, nil, Noble.Transition.DipToBlack) end)
    end
end
function scene:exit()
    self:removeAllText()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
end