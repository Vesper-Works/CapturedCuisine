import 'dialogue/ingredientdialogue'
SweetTalking = {}
class("SweetTalking").extends(NobleScene)

local scene = SweetTalking
local pd = playdate

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
    self.left_dialogue = dialogues["left_dialogue"]
    self.middle_dialogue = dialogues["middle_dialogue"]
    self.right_dialogue = dialogues["right_dialogue"]

    if self.left_dialogue and self.middle_dialogue and self.right_dialogue then
        self.left = Dialogue(self.left_dialogue["dialogue"], self.left_dialogue["response"], self.left_dialogue["success"])
        self.middle = Dialogue(self.middle_dialogue["dialogue"], self.middle_dialogue["response"], self.middle_dialogue["success"])
        self.right = Dialogue(self.right_dialogue["dialogue"], self.right_dialogue["response"], self.right_dialogue["success"])
        print("Initialized dialogues")
    else
        print("Dialogue branches are incomplete.")
    end
end

function scene:resetDialogues(branch)
    if not branch then
        print("resetDialogues: Branch is nil")
        return
    end

    print("resetDialogues: Received branch")
    print("resetDialogues: left_dialogue: " .. branch["left_dialogue"]["dialogue"])
    print("resetDialogues: middle_dialogue: " .. branch["middle_dialogue"]["dialogue"])
    print("resetDialogues: right_dialogue: " .. branch["right_dialogue"]["dialogue"])

    self.left_dialogue = branch["left_dialogue"]
    self.middle_dialogue = branch["middle_dialogue"]
    self.right_dialogue = branch["right_dialogue"]

    if self.left_dialogue and self.middle_dialogue and self.right_dialogue then
        print("resetDialogues: Updating dialogues with new branch data")

        -- Ensure dialogue objects are not nil
        if not self.left or not self.middle or not self.right then
            print("resetDialogues: Dialogue objects are nil, reinitializing")
            self.left = Dialogue(self.left_dialogue["dialogue"], self.left_dialogue["response"], self.left_dialogue["success"])
            self.middle = Dialogue(self.middle_dialogue["dialogue"], self.middle_dialogue["response"], self.middle_dialogue["success"])
            self.right = Dialogue(self.right_dialogue["dialogue"], self.right_dialogue["response"], self.right_dialogue["success"])
        else
            print("resetDialogues: Using existing Dialogue objects")
            self.left:setAllValues(self.left_dialogue["dialogue"], self.left_dialogue["response"], self.left_dialogue["success"])
            self.middle:setAllValues(self.middle_dialogue["dialogue"], self.middle_dialogue["response"], self.middle_dialogue["success"])
            self.right:setAllValues(self.right_dialogue["dialogue"], self.right_dialogue["response"], self.right_dialogue["success"])
        end

        print("resetDialogues: Dialogues successfully reset")
    else
        print("resetDialogues: Dialogue branches are incomplete.")
    end
end

-- Function to handle updating logic based on user input
function scene:update()
    if pd.buttonJustReleased(pd.kButtonLeft) then
        if self.left and self.left:getSuccess() then
            print("Left success: " .. self.left:getResponse())
            scene:refreshDialogue(self.left_dialogue)
        elseif self.left then
            print("Left response: " .. self.left:getResponse())
        end
    elseif pd.buttonJustReleased(pd.kButtonRight) then
        if self.right and self.right:getSuccess() then
            print("Right success: " .. self.right:getResponse())
            scene:refreshDialogue(self.right_dialogue)
        elseif self.right then
            print("Right response: " .. self.right:getResponse())
        end
    elseif pd.buttonJustReleased(pd.kButtonUp) then
        if self.middle and self.middle:getSuccess() then
            print("Middle success: " .. self.middle:getResponse())
            scene:refreshDialogue(self.middle_dialogue)
        elseif self.middle then
            print("Middle response: " .. self.middle:getResponse())
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
    for k, v in pairs(self.current_branch) do
        print("Branch key: " .. k .. ", value: " .. tostring(v))
    end

    self:resetDialogues(self.current_branch)
end