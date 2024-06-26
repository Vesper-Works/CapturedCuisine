import 'dialogue/ingredientdialogue'
SweetTalking = {}
class("SweetTalking").extends(NobleScene)

local scene = SweetTalking
local pd = playdate
local left_dialogue
local right_dialogue
local middle_dialogue
-- Function to set initial values for the scene
function scene:setValues()
    self.background = Graphics.image.new("assets/images/background1")
    self.color1 = Graphics.kColorBlack
    self.color2 = Graphics.kColorWhite
    self.currentIngredient = "Onion_1"
    Noble.Text.setFont(Graphics.font.new("assets/fonts/Beastfont-Regular"))
end

-- Function to initialize the scene
function scene:init()
    scene.super.init(self)
    self:setValues()
    self.file = "dialogue/onion_1.json"
    self.dialoguebranches = json.decodeFile(self.file)

    if not self.dialoguebranches or not self.dialoguebranches[self.currentIngredient] then
        print("Failed to load dialogues or current ingredient not found.")
        return -- Exit if there is no data to work with
    end
    self:setupDialogues()
end

-- Helper function to setup dialogues
function scene:setupDialogues()
    local dialogues = self.dialoguebranches[self.currentIngredient]
    left_dialogue = dialogues["left_dialogue"]
    middle_dialogue = dialogues["middle_dialogue"]
    right_dialogue = dialogues["right_dialogue"]
end

-- Function to handle updating logic based on user input
function scene:update()
    if pd.buttonJustReleased(pd.kButtonLeft) then
        if left_dialogue["success"] == true then
            print("Left success: " .. left_dialogue["response"])
            scene:refreshDialogue(left_dialogue)
        else
            print("Left response: " .. left_dialogue["response"])
        end
    elseif pd.buttonJustReleased(pd.kButtonRight) then
        if right_dialogue["success"] == true then
            print("Right success: " .. right_dialogue["response"])
            scene:refreshDialogue(right_dialogue)
        else
            print("Right response: " .. right_dialogue["response"])
        end
    elseif pd.buttonJustReleased(pd.kButtonUp) then
        if middle_dialogue["success"] == true then
            print("Middle success: " .. middle_dialogue["response"])
            scene:refreshDialogue(middle_dialogue)
        else
            print("Middle response: " .. middle_dialogue["response"])
        end
    end
end

-- Function to refresh dialogue based on the current branch
function scene:refreshDialogue(branch)
    if not branch or not branch["branch"] then
        print("No further branches available or branch data is missing.")
        scene:exit()
        return
    end

    local newBranch = branch["branch"]
    if newBranch == self.current_branch then
        print("refreshDialogue: Branch did not change, exiting")
        scene:exit()
        return
    end

    self.current_branch = newBranch
    print("refreshDialogue: Current branch is " .. tostring(self.current_branch))

    -- Print out the structure of the current branch for debugging

    if not branch then
        print("resetDialogues: Branch is nil")
        return
    end
    left_dialogue = newBranch["left_dialogue"]
    middle_dialogue = newBranch["middle_dialogue"]
    right_dialogue = newBranch["right_dialogue"]
end