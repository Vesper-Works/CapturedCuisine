import 'dialogue/ingredientdialogue'
import 'CoreLibs/Graphics'
SweetTalking = {}
class("SweetTalking").extends(NobleScene)

local scene = SweetTalking
local pd = playdate
local interact = true
local MAX_ATTEMPTS = 3 --constant for now, though this may change to a variable based on how future dialogue files are configured
-- Function to set initial values for the scene
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    self.currentIngredient = "hatred"
    self.reputation = 1.00
    self.attempts = 0
    --Noble.Text.setFont(Graphics.font.new("assets/fonts/Beastfont-Regular"))
    pd.graphics.setFont(Graphics.font.new("assets/fonts/Beastfont-Regular"))
    interact = true
end

-- Function to initialize the scene
function scene:init(__sceneProperties)
    self.likesThisMethod = __sceneProperties.prefferedMethods
    self.hatesThisMethod = __sceneProperties.hatedMethods
    print(self.likesThisMethod)
    if self.hatesThisMethod == true then
        print("I hate this laser method")
        MAX_ATTEMPTS = 5
    elseif self.likesThisMethod == true then
        print("I love this method")
    end
    scene.super.init(self)
    self:setValues()
    self.file = "dialogue/" .. self.currentIngredient .. ".json"
    print(self.file)
    self.dialoguebranches = json.decodeFile(self.file)

    if not self.dialoguebranches or not self.dialoguebranches[self.currentIngredient] then
        print("Failed to load dialogues or current ingredient not found.")
        return -- Exit if there is no data to work with
    end
    self:setupDialogues()
    self.currentResponse = ""
end

-- Helper function to setup dialogues
function scene:setupDialogues()
    local dialogues = self.dialoguebranches[self.currentIngredient]
    self.current_branch = dialogues
end


-- Function to handle updating logic based on user input
function scene:update()
    if self.currentResponse ~= "" then
        pd.graphics.drawTextInRect(self.currentResponse, 20, 180, 400, 100)
    end
    if interact == false then
        pd.graphics.drawTextInRect("Scenes Over, Going Home", 20, 20, 400, 100)
        return
    end
    pd.graphics.drawTextInRect("Left: " .. self.current_branch["left_dialogue"]["dialogue"], 20, 20, 400, 100)
    pd.graphics.drawTextInRect("Middle: " .. self.current_branch["middle_dialogue"]["dialogue"], 20, 60, 400, 100)
    pd.graphics.drawTextInRect("Right: " .. self.current_branch["right_dialogue"]["dialogue"], 20, 100, 400, 100)
    if pd.buttonJustReleased(pd.kButtonLeft) then
        self.currentResponse = self.current_branch["left_dialogue"]["response"]
        self:processDialogue(self.current_branch["left_dialogue"])
    elseif pd.buttonJustReleased(pd.kButtonRight) then
        self.currentResponse = self.current_branch["right_dialogue"]["response"]
        self:processDialogue(self.current_branch["right_dialogue"])
    elseif pd.buttonJustReleased(pd.kButtonUp) then
        self.currentResponse = self.current_branch["middle_dialogue"]["response"]
        self:processDialogue(self.current_branch["middle_dialogue"])
    end
end
function scene:backToMenu()
    pd.timer.performAfterDelay(3000, function () Noble.transition(PickIngredientScene, nil, Noble.Transition.DipToBlack)  end)
    interact = false
end
-- Function to refresh dialogue based on the current branch
function scene:processDialogue(dialogue)
    self.attempts = self.attempts + 1
    if dialogue["success"] == false then
        if self.attempts > MAX_ATTEMPTS then
            PickIngredientScene.updateReputation(0)
            self:backToMenu()
        end
        return --prevents scene from exiting early
    end
    if not dialogue["branch"] then
        print("No further branches available or branch data is missing.")
        if self.likesThisMethod == true then
            PickIngredientScene.updateReputation(2) --correct cooking method picked and done successfully
        else
            PickIngredientScene.updateReputation(1)
        end
        self:backToMenu()
        return
    end

    local newBranch = dialogue["branch"]
    self.current_branch = newBranch
    print("refreshDialogue: Current branch is " .. tostring(self.current_branch))
    print("refreshDialogue: left_dialogue: " .. self.current_branch["left_dialogue"]["dialogue"])
    print("refreshDialogue: middle_dialogue: " .. self.current_branch["middle_dialogue"]["dialogue"])
    print("refreshDialogue: right_dialogue: " .. self.current_branch["right_dialogue"]["dialogue"])

    -- Print out the structure of the current branch for debugging
    for k, v in pairs(self.current_branch) do
        print("Branch key: " .. k .. ", value: " .. tostring(v))
    end
end
function scene:exit() 
    pd.graphics.setFont(Noble.Text.FONT_MEDIUM)
    print("Scene exited")
end