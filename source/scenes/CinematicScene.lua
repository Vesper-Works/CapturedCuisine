import "CoreLibs/graphics" --note that any libraries from playdate can be used with noble
import "libraries/panels-main/Panels" --using the panels module
import "sequences/s01.lua"
CinematicScene = {}
class("CinematicScene").extends(NobleScene)
local scene = CinematicScene
local pd = playdate
local gfx = pd.graphics
local comicData = { --create a number of sequences in the sequences folder, then add them in order here. Use the same format as in s01.
    s01
}
function scene:setValues()
    --self.background = Graphics.image.new("assets/images/comicImages/sky.png")
    self.color1 = Graphics.kColorBlack
	self.color2 = Graphics.kColorWhite
    Noble.Text.setFont(Graphics.font.new("assets/fonts/Beastfont-Regular"))
end
function scene:init() 
    scene.super.init(self)
    scene.setValues(self)
    Panels.startCutscene(comicData, function() scene:exit() end) --takes two arguments, the comicData which are the panel sequences and the function called once the cutscene ends
end

function scene:update()
    Panels.update() --needs to be called
    if pd.buttonIsPressed(pd.kButtonB) then --to skip cutscene
         --cutscene should stop and go to next scene
        self:exit()
    end
end
function scene:exit() 
    Panels.haltCutscene()
    Noble.Text.setFont(Noble.Text.FONT_MEDIUM)
    Noble.transition(ResturauntScene, nil, Noble.Transition.DipToBlack)
end