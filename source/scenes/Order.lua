Order = {}
local pd = playdate
local gfx = pd.graphics
class('Order').extends(gfx.sprite) 
function Order:init(sentence1, sentence2, sentence3, imagePath)
    Order.super.init(self)
    self.firstSentence = sentence1
    self.secondSentence = sentence2
    self.thirdSentence = sentence3
    self.path = imagePath
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
--use this class to insert adjectives into the sentences