local XTheatre4ConfigBase = require("XModule/XTheatre4/XEntity/System/XConfig/XTheatre4ConfigBase")

---@class XTheatre4BattlePassConfig : XTheatre4ConfigBase
local XTheatre4BattlePassConfig = XClass(XTheatre4ConfigBase, "XTheatre4BattlePassConfig")

function XTheatre4BattlePassConfig:GetLevel()
    return self:_GetValueOrDefaultByKey("Level", 0)
end

function XTheatre4BattlePassConfig:GetNextLvExp()
    return self:_GetValueOrDefaultByKey("NeedExp", 0)
end

function XTheatre4BattlePassConfig:GetRewardId()
    return self:_GetValueOrDefaultByKey("RewardId", 0)
end

function XTheatre4BattlePassConfig:GetIsDisplay()
    return self:_GetValueOrDefaultByKey("Display", 0) == 1
end

---@param config XTheatre4BattlePassConfig
function XTheatre4BattlePassConfig:IsEquals(config)
    if self:IsEmpty() and config:IsEmpty() then
        return true
    end
    if self:IsEmpty() or config:IsEmpty() then
        return false
    end

    return self:GetLevel() == config:GetLevel()
end

return XTheatre4BattlePassConfig