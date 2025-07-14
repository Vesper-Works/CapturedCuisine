AdjectiveHandler = {}
local pd = playdate
local currentIngredient = ""

function AdjectiveHandler.setIngredient(ingredient)
    currentIngredient = ingredient
end
function AdjectiveHandler.clearIngredient()
    currentIngredient = ""
end