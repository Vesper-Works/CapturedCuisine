-- Define the IngredientHandler table
IngredientHandler = {}

-- Global table for storing ingredient data
IngredientHandler.ingredients = {}
local ingredientNameToIndex = {}

local pd = playdate

-- Method to load ingredient data from a CSV file
function IngredientHandler.loadIngredients()
    -- Your code to load ingredient data from the CSV file using the Playdate SDK goes here
    -- For example, you can use the Playdate SDK's file I/O functions to read the CSV file

    --io.write(pd.file.listFiles(".", true))

    local file = playdate.file.open("Ingredients.tsv", pd.file.kFileRead)
    local csvLine = file:readline()

    repeat
        

        -- Assuming you have loaded the CSV data into a string called "csvLine"
        local csvData = {}
        for value in csvLine:gmatch("[^	]+") do
            table.insert(csvData, value)
        end
        ingredientNameToIndex[csvData[1]] = #IngredientHandler.ingredients + 1
        
        local ingredient = {
            name = csvData[1],
            properties = csvData[2],
            preferredPreparationMethods = csvData[3],
            dislikedPreparationMethods = csvData[4],
            orderOfPreparation = csvData[5],
            pairingSuggestions = csvData[6],
            sentient = csvData[7] ~= "",
            personality = csvData[8],
            diagAngry = csvData[9] and table.pack(csvData[9]:gmatch("[^,]+")),
            diagHappy = csvData[10] and table.pack(csvData[10]:gmatch("[^,]+")),
            diagConfused = csvData[11] and table.pack(csvData[11]:gmatch("[^,]+"))
        }
        table.insert(IngredientHandler.ingredients, ingredient)
        csvLine = file:readline()
    until csvLine == nil
end

function IngredientHandler.getIngredientByName(name)
    return IngredientHandler.ingredients[ingredientNameToIndex[name]]
end

function IngredientHandler.createIngredientInstanceByName(name)
    local newIngredient =  table.deepcopy(IngredientHandler.getIngredientByName(name))
    return newIngredient
end

function IngredientHandler.getRandomIngredient()
    return IngredientHandler.ingredients[math.random(1, #IngredientHandler.ingredients)]
end
function IngredientHandler.createRandomIngredientInstance()
    return table.deepcopy(IngredientHandler.ingredients[math.random(1, #IngredientHandler.ingredients)])
end

-- test all get/create functions
function IngredientHandler.test()
    -- Test the getIngredientByName function
    local ingredient = IngredientHandler.getIngredientByName("Whispcream")
    print(ingredient.name) -- Output: Tomato

    -- Test the createIngredientInstanceByName function
    local instance = IngredientHandler.createIngredientInstanceByName("Glow Leeks")
    instance.name = "glorpus" -- Output: Random ingredient name
    print(instance.name) -- Output: Random ingredient name
    -- Test the getRandomIngredient function
    local randomIngredient = IngredientHandler.getRandomIngredient()
    print(randomIngredient.name) -- Output: Random ingredient name

    -- Test the createRandomIngredientInstance function
    local randomInstance = IngredientHandler.createRandomIngredientInstance()
    print(randomInstance.name) -- Output: Random ingredient name

    local dingredient = IngredientHandler.getIngredientByName("glorpus")
    print(dingredient.name) -- Output: Tomato

end

function IngredientHandler.getSpriteForIngredient(ingredient)
    if playdate.file.exists("assets/images/ingredients/" .. ingredient.name) then
        return playdate.graphics.image.new("assets/images/ingredients/" .. ingredient.name)
    end
    return playdate.graphics.image.new("assets/images/default")
end
function IngredientHandler.getSpriteForIngredientByName(ingredient)
    if playdate.file.exists("assets/images/ingredients/" .. ingredient) then
        return playdate.graphics.image.new("assets/images/ingredients/" .. ingredient)
    end
    return playdate.graphics.image.new("assets/images/default")
end
-- Return the IngredientHandler table
return IngredientHandler
