-- Define the IngredientHandler table
IngredientHandler = {}

-- Global table for storing ingredient data
IngredientHandler.ingredients = {}

local ingredientNameToIndex = {}

local pd = playdate

---Splits a string into a table based on a split character
---@param string string
---@param splitChar string
---@return table
local function stringToTable(string, splitChar)
    local result = {}
    if string then
        for value in string:gmatch("[^(" .. splitChar .. ")]+") do --Iterate through segements seperated by splitChar
            value = value:match("^%s*(.*)"):match("(.-)%s*$")      --Remove leading and trailing spaces
            table.insert(result, value)
        end
    end
    return result
end

-- Method to load ingredient data from a TSV file, call on game startup
function IngredientHandler.loadIngredients()
    local file = playdate.file.open("assets/data/Ingredients.tsv", pd.file.kFileRead)
    local tsvLine = file:readline()

    repeat
        local tsvData = {}
        for value in tsvLine:gmatch("[^	]+") do
            table.insert(tsvData, value)
        end
        ingredientNameToIndex[tsvData[1]] = #IngredientHandler.ingredients + 1

        local ingredient = {
            name = tsvData[1],
            properties = tsvData[2],
            dislikedPreparationMethods = tsvData[3],
            preferredPreparationMethods = stringToTable(tsvData[4], "→"),
            pairingSuggestions = stringToTable(tsvData[5], ","),
            sentient = tsvData[6] ~= "",
            personality = tsvData[7],
            startingIngredient = tsvData[8] ~= "",
            diagAngry = stringToTable(tsvData[9], ","),
            diagHappy = stringToTable(tsvData[10], ","),
            diagConfused = stringToTable(tsvData[11], ",")
        }
        table.insert(IngredientHandler.ingredients, ingredient)
        tsvLine = file:readline()
    until tsvLine == nil
end

function IngredientHandler.getIngredientByName(name)
    return IngredientHandler.ingredients[ingredientNameToIndex[name]]
end

function IngredientHandler.createIngredientInstanceByName(name)
    local newIngredient = table.deepcopy(IngredientHandler.getIngredientByName(name))
    newIngredient["preparedMethods"] = {}
    newIngredient["methodScores"] = {}

    table.insert(newIngredient["methodScores"], { "Chopping", 0.56 })
    return newIngredient
end

function IngredientHandler.getRandomIngredient()
    return IngredientHandler.ingredients[math.random(1, #IngredientHandler.ingredients)]
end

function IngredientHandler.createRandomIngredientInstance()
    return IngredientHandler.createIngredientInstanceByName(IngredientHandler.getRandomIngredient().name)
end

-- test all get/create functions
function IngredientHandler.test()
    -- Test the getIngredientByName function
    local ingredient = IngredientHandler.getIngredientByName("Whispcream")
    print(ingredient.name) -- Output: Tomato

    -- Test the createIngredientInstanceByName function
    local instance = IngredientHandler.createIngredientInstanceByName("Glow Leeks")
    instance.name = "glorpus" -- Output: Random ingredient name
    print(instance.name)      -- Output: Random ingredient name
    -- Test the getRandomIngredient function
    local randomIngredient = IngredientHandler.getRandomIngredient()
    print(randomIngredient.name) -- Output: Random ingredient name

    -- Test the createRandomIngredientInstance function
    local randomInstance = IngredientHandler.createRandomIngredientInstance()
    print(randomInstance.name) -- Output: Random ingredient name
end

function IngredientHandler.getSpriteForIngredient(ingredient)
    if playdate.file.exists("assets/images/ingredients/" .. ingredient.name) then
        return playdate.graphics.image.new("assets/images/ingredients/" .. ingredient.name)
    end
    local image = playdate.graphics.image.new("assets/images/default")
    image:setMaskImage(playdate.graphics.image.new("assets/images/default_mask"))
    return image
end

function IngredientHandler.getSpriteForIngredientByName(ingredient)
    if playdate.file.exists("assets/images/ingredients/" .. ingredient) then
        return playdate.graphics.image.new("assets/images/ingredients/" .. ingredient)
    end
    return playdate.graphics.image.new("assets/images/default")
end

-- Return the IngredientHandler table
return IngredientHandler
