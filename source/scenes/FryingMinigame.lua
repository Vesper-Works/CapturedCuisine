import "CoreLibs/graphics"
import "utilities/IngredientHandler"
import "CoreLibs/utilities/sampler"

IncredientTestScene = {}
class("IncredientTestScene").extends(NobleScene)
--local scene = IncredientTestScene --when refering to scene, it's referring to an instance of the OpeningScene object
local pd <const> = playdate
local gfx <const> = pd.graphics
local fluidSettings = { 30, 0, 200, 200 }

IncredientTestScene.inputHandler = {
}

function IncredientTestScene:setValues()
    self.color1 = gfx.kColorBlack
    self.color2 = gfx.kColorWhite
end

function IncredientTestScene:start()

    Noble.Input.setHandler(IncredientTestScene.inputHandler)
end

function IncredientTestScene:init()
    gfx.sprite.setAlwaysRedraw(false)
    IncredientTestScene.super.init(self) --calls parent constructor
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
        { "40x40", "60x60", "80x80", "100x100", "120x120", "140x140", "160x160", "180x180", "200x200", "300x180","400x240" }, "200x200",
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

function IncredientTestScene:update()
    IncredientTestScene.super.update(self)
    fluid.update()
end
function IncredientTestScene:exit()
    Noble.transition(ExampleScene, nil, Noble.Transition.DipToBlack) --move to the main scene
end