import "CoreLibs/object"
import "CoreLibs/sprites"
Dialogue = {}
local pd = playdate
local gfx = pd.graphics
class('Dialogue').extends(gfx.sprite)
function Dialogue:init(dial, response, success)
    self.dial = dial --json attributes for the dialogue system are parsed through here
    self.response = response
    self.success = success
end
function Dialogue:getDialogue() 
    return self.dial
end
function Dialogue:setDialogue(newDial) 
    self.dial = newDial
end
function Dialogue:getResponse() 
    return self.response
end
function Dialogue:setResponse(newResponse) 
    self.response = newResponse
end
function Dialogue:getSuccess()
    return self.success
end
function Dialogue:setSuccess(newSuccess) 
    self.success = newSuccess
end
function Dialogue:setAllValues(newDial, newResponse, newSuccess) 
    self.dial = newDial
    self.response = newResponse
    self.success = newSuccess
end
