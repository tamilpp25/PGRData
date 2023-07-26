---@class XGuildDormFurnitureEffectModel
local XGuildDormFurnitureEffectModel = XClass(nil, "XGuildDormFurnitureEffectModel")

function XGuildDormFurnitureEffectModel:Ctor()
    self.IsCreateEffect = false
    self.ConditionType = XGuildDormConfig.FurnitureConditionType.None
end

function XGuildDormFurnitureEffectModel:SetEffectConfig(config)
    self.Config = config
    self.ConditionType = self.Config.ConditionType
    self.ConditionArg = self.Config.ConditionArg
    self.ConditionState = self.Config.ConditionState == 1
    if self.ConditionType == XGuildDormConfig.FurnitureConditionType.Time or self.ConditionType == XGuildDormConfig.FurnitureConditionType.Condition then
        self.ConditionArg = tonumber(self.ConditionArg)
    end
end

function XGuildDormFurnitureEffectModel:GetEffectId()
    return self.Config.EffectId
end

function XGuildDormFurnitureEffectModel:CheckIsSpecialPos()
    return self.Config.IsSpecialPos == 1
end

function XGuildDormFurnitureEffectModel:GetSpecialPosName()
    return self.Config.SpecialPosName
end

function XGuildDormFurnitureEffectModel:GetEffectLocalPosition()
    local x = self.Config.EffectX or 0
    local y = self.Config.EffectY or 0
    local z = self.Config.EffectZ or 0
    return Vector3(x, y, z)
end

function XGuildDormFurnitureEffectModel:SetIsCreateEffect(value)
    self.IsCreateEffect = value
end

function XGuildDormFurnitureEffectModel:GetIsCreateEffect()
    return self.IsCreateEffect
end

function XGuildDormFurnitureEffectModel:CheckCondition()
    local isCheck = false
    if self.ConditionType == XGuildDormConfig.FurnitureConditionType.Time then
        isCheck = XFunctionManager.CheckInTimeByTimeId(self.ConditionArg)
    end
    if self.ConditionType == XGuildDormConfig.FurnitureConditionType.Condition then
        isCheck = XConditionManager.CheckCondition(self.ConditionArg)
    end
    if self.ConditionType == XGuildDormConfig.FurnitureConditionType.RedPointCondition then
        isCheck = XRedPointManager.CheckConditions({ self.ConditionArg })
    end
    return self.ConditionState == isCheck
end

return XGuildDormFurnitureEffectModel