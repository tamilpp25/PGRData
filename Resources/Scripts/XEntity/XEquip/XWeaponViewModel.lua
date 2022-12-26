local XEquipViewModel = require("XEntity/XEquip/XEquipViewModel")
local XWeaponViewModel = XClass(XEquipViewModel, "XWeaponViewModel")

-- 适配XEquip方法
function XWeaponViewModel:IsEquipPosAwaken(pos)
    return self:GetEquip():IsEquipPosAwaken(pos)
end

return XWeaponViewModel