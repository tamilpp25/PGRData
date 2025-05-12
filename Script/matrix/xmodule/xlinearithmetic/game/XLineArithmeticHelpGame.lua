local XLineArithmeticGame = require("XModule/XLineArithmetic/Game/XLineArithmeticGame")

---@class XLineArithmeticHelpGame:XLineArithmeticGame
local XLineArithmeticHelpGame = XClass(XLineArithmeticGame, "XLineArithmeticHelpGame")

function XLineArithmeticHelpGame:Ctor()
    self._IsOnline = false
end

---@param model XLineArithmeticModel
function XLineArithmeticHelpGame:Update(model)
    ---@type XLineArithmeticAction
    local action = self._ActionList:Dequeue()
    if not action then
        return false
    end
    action:SetEatFinalGrid(false)
    action:Execute(self, model)
    --self:Execute(model)
    --self:ExecuteEat(model)
    return true
end

return XLineArithmeticHelpGame
