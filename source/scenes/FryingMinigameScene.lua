import "CoreLibs/graphics"
import "utilities/IngredientHandler"
import "CoreLibs/utilities/sampler"

FryingMinigameScene = {}
class("FryingMinigameScene").extends(NobleScene)
--local scene = FryingMinigameScene --when refering to scene, it's referring to an instance of the OpeningScene object
local pd <const> = playdate
local gfx <const> = pd.graphics
local fluidSettings = { 30, 0, 200, 200 }
local backgroundImage = gfx.image.new("assets/images/FryingBackground")

local fluidSpawningSequences = {
    { 
        Sequence.new():from(1):to(0, 3, "linear"):mirror():start(), --Strength
        Sequence.new():from(0):to(1, 7, "linear"):mirror():start(),--X
        Sequence.new():from(0):to(1, 5, "linear"):mirror():start() --Y
    },
    { 
        Sequence.new():from(1):to(0, 5, "linear"):mirror():start(), --Strength
        Sequence.new():from(0):to(1, 8, "linear"):mirror():start(),--X
        Sequence.new():from(0):to(1, 4, "linear"):mirror():start() --Y
    }
     
    


}
FryingMinigameScene.inputHandler = {
}

function FryingMinigameScene:setValues()
    self.color1 = gfx.kColorBlack
    self.color2 = gfx.kColorWhite
end

function FryingMinigameScene:start()
    --fluidUpdateSequence:start()
    Noble.Input.setHandler(FryingMinigameScene.inputHandler)
end

function FryingMinigameScene:drawBackground(__x, __y, __width, __height)
    --FryingMinigameScene.super.drawBackground(self)


    backgroundImage:draw(0, 0)
end

function FryingMinigameScene:init()
    gfx.sprite.setAlwaysRedraw(false)
    FryingMinigameScene.super.init(self) --calls parent constructor
    --pd.display.setRefreshRate(500)
    self:setValues()

    local menu = pd.getSystemMenu()
    local updating = false
    local updateSimulation = Sequence.new():from(20):to(80, 0.1, "linear"):callback(function()
        fluid.reinitialise(fluidSettings[1], fluidSettings[2], fluidSettings[3], fluidSettings[4])
        updating = false
    end)

    menu:addOptionsMenuItem("Fluid",
        { "20", "25", "30", "35", "40", "45", "50", "55", "60", "65", "70", "75", "80" }, "30",
        function(option)
            fluidSettings[1] = tonumber(option)
            if not updating then
                updating = true
                updateSimulation:restart()
            end
        end)
    menu:addOptionsMenuItem("Res",
        { "40x40", "60x60", "80x80", "100x100", "120x120", "140x140", "160x160", "180x180", "200x200", "300x180",
            "400x240" }, "200x200",
        function(option)
            fluidSettings[3] = tonumber(option:match("%d+"))
            fluidSettings[4] = tonumber(option:match("x(%d+)"))
            if not updating then
                updating = true
                updateSimulation:restart()
            end
        end)

    menu:addCheckmarkMenuItem("Interp", 0, function(checked)
        fluidSettings[2] = checked == true and 1 or 0
        if not updating then
            updating = true
            updateSimulation:restart()
        end
    end)

    fluid.initialise()
end

function FryingMinigameScene:update()
    
    
    for index, value in ipairs(fluidSpawningSequences) do
        local temp,temp2,temp3 = value[1]:get(), value[2]:get(), value[3]:get()
        fluid.addSource(temp, value[2]:get(), value[3]:get())
    end
    
    fluid.update()
    FryingMinigameScene.super.update(self)

   
end

function FryingMinigameScene:exit()
    Noble.transition(ExampleScene, nil, Noble.Transition.DipToBlack) --move to the main scene
end
