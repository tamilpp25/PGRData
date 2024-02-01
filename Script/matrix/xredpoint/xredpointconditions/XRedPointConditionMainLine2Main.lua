-- 主线2主章节红点检测
local XRedPointConditionMainLine2Main = {}

function XRedPointConditionMainLine2Main.Check(mainId)
    return XMVCA:GetAgency(ModuleId.XMainLine2):IsMainRed(mainId)
end

return XRedPointConditionMainLine2Main