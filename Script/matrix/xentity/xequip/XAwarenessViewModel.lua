local XEquipViewModel = require("XEntity/XEquip/XEquipViewModel")
local XAwarenessViewModel = XClass(XEquipViewModel, "XAwarenessViewModel")

function XAwarenessViewModel:CheckPosIsAwaken(pos)
    if not self.AwakeSlotList then return end
    for _, slot in pairs(self.AwakeSlotList) do
        if slot == pos then
            return true
        end
    end
    return false
end

-- 适配XEquip方法
function XAwarenessViewModel:IsEquipPosAwaken(pos)
    return self:GetEquip():IsEquipPosAwaken(pos)
end

function XAwarenessViewModel:GetSite()
    return self.__SlotPos
end

return XAwarenessViewModel