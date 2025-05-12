local XTheatre4ConfigBase = require("XModule/XTheatre4/XEntity/System/XConfig/XTheatre4ConfigBase")

---@class XTheatre4ColorTalentConfig : XTheatre4ConfigBase
local XTheatre4ColorTalentConfig = XClass(XTheatre4ConfigBase, "XTheatre4ColorTalentConfig")

function XTheatre4ColorTalentConfig:GetId()
    return self:_GetValueOrDefaultByKey("Id", 0)
end

function XTheatre4ColorTalentConfig:GetName()
    return self:_GetValueOrDefaultByKey("Name", "")
end

function XTheatre4ColorTalentConfig:GetIcon()
    return self:_GetValueOrDefaultByKey("Icon", "")
end

function XTheatre4ColorTalentConfig:GetDesc()
    return XUiHelper.ReplaceTextNewLine(self:_GetValueOrDefaultByKey("Desc", ""))
end

function XTheatre4ColorTalentConfig:GetType()
    return self:_GetValueOrDefaultByKey("Type", 0)
end

function XTheatre4ColorTalentConfig:GetRelationGroup()
    return self:_GetValueOrDefaultByKey("RelationGroup", 0)
end

function XTheatre4ColorTalentConfig:GetEffectGroupId()
    return self:_GetValueOrDefaultByKey("EffectGroupId", 0)
end

function XTheatre4ColorTalentConfig:GetJoinSettle()
    return self:_GetValueOrDefaultByKey("JoinSettle", 0)
end

function XTheatre4ColorTalentConfig:GetColorType()
    return self:_GetValueOrDefaultByKey("ColorType", 0)
end

function XTheatre4ColorTalentConfig:GetCondition()
    return self:_GetValueOrDefaultByKey("Condition", 0)
end

function XTheatre4ColorTalentConfig:GetShowLevel()
    return self:_GetValueOrDefaultByKey("ShowLevel", 1)
end

function XTheatre4ColorTalentConfig:GetParam()
    return self:_GetValueOrDefaultByKey("Param", {})
end

return XTheatre4ColorTalentConfig
