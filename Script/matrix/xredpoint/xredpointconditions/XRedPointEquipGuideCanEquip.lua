
local XRedPointEquipGuideCanEquip = {}


function XRedPointEquipGuideCanEquip.Check(equipId)
    return XDataCenter.EquipGuideManager.CheckEquipCanEquip(equipId)
end 

return XRedPointEquipGuideCanEquip