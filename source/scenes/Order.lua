Order = {}
local pd = playdate
local gfx = pd.graphics
local adjectives = {'crunchy', 'fried', 'grilled', 'happy'}
class('Order').extends(gfx.sprite) 
function Order:init(sentence1, sentence2, sentence3, imagePath)
    Order.super.init(self)
    self.firstSentence = sentence1
    self.secondSentence = sentence2
    self.thirdSentence = sentence3
    self.path = imagePath
    self.firstSentence = self:replaceAdjective(self.firstSentence)
    self.secondSentence = self:replaceAdjective(self.secondSentence)
    self.thirdSentence = self:replaceAdjective(self.thirdSentence)
end
function Order:returnFirstSentence()
    
    return self.firstSentence
end
function Order:returnSecondSentence()
    
    return self.secondSentence
end
function Order:returnThirdSentence()
    
    return self.thirdSentence
end
function Order:returnPath()
    return self.path
end
function Order:replaceAdjective(sentence)
    local adjective = math.random(#adjectives)
    sentence = sentence:gsub("adjective", adjectives[adjective])
    print(sentence)
    return sentence --replace placeholder with required adjective
end
--use this class to insert adjectives into the sentences