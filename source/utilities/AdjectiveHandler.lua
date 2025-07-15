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