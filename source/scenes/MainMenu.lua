
MainMenu = {}
class("MainMenu").extends(NobleScene)
local scene = MainMenu

function scene:setValues()
	self.background = Graphics.image.new("assets/images/background2")

	self.color1 = Graphics.kColorBlack
	self.color2 = Graphics.kColorWhite

	self.menu = nil
	self.sequence = nil

	self.menuX = 15

	self.menuYFrom = -50
	self.menuY = 15
	self.menuYTo = 240 --this is all taken from the ExampleScene.lua file, however this establishes the menu and the menu dimensions
end

function scene:init()
    scene.super.init(self)
    self:setValues()
    self.menu = Noble.Menu.new(false, Noble.Text.ALIGN_LEFT, false, self.color2, 4,6,0, Noble.Text.FONT_LARGE) --template, creates a menu for the main scene
    self:setUpMenu(self.menu)
    local crankTick = 0 --presuming this is related to number of cranks/how fast the crank moves
    self.inputHandler = { --again taken from examplescene as it already gives desired functionality for menu
		upButtonDown = function()
			self.menu:selectPrevious()
		end,
		downButtonDown = function()
			self.menu:selectNext()
		end,
		cranked = function(change, acceleratedChange)
			crankTick = crankTick + change
			if (crankTick > 30) then
				crankTick = 0
				self.menu:selectNext()
			elseif (crankTick < -30) then
				crankTick = 0
				self.menu:selectPrevious()
			end
		end,
		AButtonDown = function()
			self.menu:click()
		end
	}
end

function scene:enter()
	scene.super.enter(self)
	self.sequence = Sequence.new():from(self.menuYFrom):to(self.menuY, 1.5, Ease.outBounce):start()
end

function scene:start()
	scene.super.start(self)

	self.menu:activate()
end

function scene:drawBackground()
	scene.super.drawBackground(self)

	self.background:draw(0, 0)
end

function scene:update()
	scene.super.update(self)

	Graphics.setColor(self.color1)
	Graphics.setDitherPattern(0.2, Graphics.image.kDitherTypeScreen)
	Graphics.fillRoundRect(self.menuX, self.sequence:get() or self.menuY, 185, 200, 15)
	self.menu:draw(self.menuX+15, self.sequence:get() + 4 or self.menuY+4)

	--Graphics.setColor(Graphics.kColorBlack)

end

function scene:exit()
	scene.super.exit(self)
	self.sequence = Sequence.new():from(self.menuY):to(self.menuYTo, 0.5, Ease.inSine)
	self.sequence:start();
end

function scene:setUpMenu(__menu)
    __menu:addItem("Continue", function() Noble.transition(LoadSave, nil, Noble.Transition.CrossDissolve) end)
    __menu:addItem("Start Game", function() Noble.transition(CheckSave, nil, Noble.Transition.CrossDissolve) end)
    __menu:addItem("Endless", function() Noble.transition(CheckSave2, nil, Noble.Transition.CrossDissolve) end)
    __menu:addItem("Options", function() Noble.transition(BlankScene, nil, Noble.Transition.CrossDissolve) end)
	__menu:addItem("Sweet Talking", function() Noble.transition(SweetTalking, nil, Noble.Transition.CrossDissolve) end)
    --something to consider, if a player choses to pick endless/start game while a saved game exists, then we may need to include a warning message/scene before it loads
end