import "CoreLibs/Graphics"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "CoreLibs/sprites"
MainMenuGrid = {}
class("MainMenuGrid").extends(NobleScene)
local scene = MainMenuGrid
local pd = playdate
local gfx = pd.graphics
local gridview = pd.ui.gridview.new(0, 32) --used for list view
local allScenes = {"Continue", "Start Game", "Endless", "Options", "SweetTalking", "Crank"} --not sure why I need an empty item at the end
local loadScenes = {LoadSave, CheckSave, CheckSave2, BlankScene, SweetTalking, CrankScene}
gridview:setNumberOfRows(#allScenes) --set rows to number of items in list
gridview:setCellPadding(2, 2, 2, 2) --creates a small border for each cell
local gridviewSprite = gfx.sprite.new() --sprite created to prevent smearing
gridviewSprite:setCenter(0, 0)
gridviewSprite:moveTo(100, 35)
gridviewSprite:add()
function scene:init()
    scene.super.init(self) 
    self.menu = nil
end
function gridview:drawCell(section, row, column, selected, x, y, width, height) --use this method to overwrite the drawing of each cell with sprite (later)
    if selected then
        gfx.fillRoundRect(x, y, width, height, 4)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    else
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    end
    local fontHeight = gfx.getSystemFont():getHeight() --gets height of system font (function may need changing later)
    gfx.drawTextInRect(allScenes[row], x, y + (height / 2 - fontHeight / 2) + 2, width, height, nil, nil, kTextAlignment.left) --text is row number, offset for text calculated for y
end
function scene:update()
    if pd.buttonJustPressed(pd.kButtonUp) then
        gridview:selectPreviousRow(true)
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        gridview:selectNextRow(true)
    end
    if gridview.needsDisplay then
        local gridviewImage = gfx.image.new(200, 100)
        gfx.pushContext(gridviewImage)
            gridview:drawInRect(0, 0, 200, 100)
        gfx.popContext()
        gridviewSprite:setImage(gridviewImage)
    end
    if pd.buttonJustPressed(pd.kButtonA) then
        local selectedScene = gridview:getSelectedRow()
        print(loadScenes[selectedScene])
        Noble.transition(loadScenes[selectedScene], nil, Noble.Transition.CrossDissolve)
    end
end
function scene:exit()
    gridviewSprite:remove() 
end
