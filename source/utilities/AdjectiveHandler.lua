import "scenes/PickIngredientScene.lua"
AdjectiveHandler = {}
local pd = playdate
local currentIngredient = ""
local adjectiveDictionary = {
    ["Glimmering Lumina"] = "happy",
    ["Ironleaf Krast"] = "crunchy",
    ["Spiral Zentar"] = "fried",
    ["Orbule Zest"] = "happy",
    ["Pulsefruit Spark"] = "crunchy",
    ["Glowcitrus Zing"] = "happy",
    ["Gravibean Stout"] = "fried",
    ["Telepathic Morch"] = "grilled",
    ["Metalliflare Meat"] = "grilled",
    ["Starry Quinoa"] = "crunchy"
    }
function AdjectiveHandler.setIngredient(ingredient)
    currentIngredient = ingredient
end
function AdjectiveHandler.clearIngredient()
    currentIngredient = ""
end
function AdjectiveHandler.returnAdjective()
    return adjectiveDictionary[currentIngredient]
end
function AdjectiveHandler.checkAdjective()
    local currentAdjectives = PickIngredientScene.getAdjectives()
    for i = #currentAdjectives, 1, -1 do
        if (currentAdjectives[i] == AdjectiveHandler.returnAdjective()) then
            PickIngredientScene.removeAdjective(currentAdjectives[i])
            return true
        end
    end
    return false
end