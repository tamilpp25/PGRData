
local XRedPointEquipGuideHasStrongerWeapon = {}

function XRedPointEquipGuideHasStrongerWeapon.Check(target)
    return XDataCenter.EquipGuideManager.CheckHasStrongerWeapon(target)
end 

return XRedPointEquipGuideHasStrongerWeapon