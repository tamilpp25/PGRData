local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
local XGuildDormFurnitureEffectModel = require("XEntity/XGuildDorm/Furniture/XGuildDormFurnitureEffectModel")
---@class XGDFurnitureEffectComponent : XGDComponet
local XGDFurnitureEffectComponent = XClass(XGDComponet, "XGDFurnitureEffectComponent")

---@param furniture XGuildDormFurniture
function XGDFurnitureEffectComponent:Ctor(furniture)
    self.Furniture = furniture
    ---@type XGuildDormFurnitureEffectModel[]
    self.EffectModelList = {}
end

function XGDFurnitureEffectComponent:Init()
    XGDFurnitureEffectComponent.Super.Init(self)
    self:SetUpdateIntervalTime(1)
    self.GroupId = self.Furniture:GetEffectGroupId()
    self:GenerateEffectInfo()
end

function XGDFurnitureEffectComponent:GenerateEffectInfo()
    local furnitureEffectConfigs = XGuildDormConfig.GetFurnitureEffectCfgByGroupId(self.GroupId)
    for _, config in pairs(furnitureEffectConfigs or {}) do
        local effectModel = XGuildDormFurnitureEffectModel.New()
        effectModel:SetEffectConfig(config)
        table.insert(self.EffectModelList, effectModel)
    end
end

function XGDFurnitureEffectComponent:Update(dt)
    for _, effectModel in pairs(self.EffectModelList) do
        local isCondition = effectModel:CheckCondition()
        local isCreateEffect = effectModel:GetIsCreateEffect()
        if isCondition and not isCreateEffect then
            self:FurniturePlayEffect(effectModel)
        end
        if not isCondition and isCreateEffect then
            self:FurnitureHideEffect(effectModel)
        end
    end
end

---@param effectModel XGuildDormFurnitureEffectModel
function XGDFurnitureEffectComponent:FurniturePlayEffect(effectModel)
    -- 标记已经创建特效
    effectModel:SetIsCreateEffect(true)
    self.Furniture:FurniturePlayEffect(effectModel:GetEffectId(), effectModel:GetEffectLocalPosition(), effectModel:CheckIsSpecialPos(), effectModel:GetSpecialPosName())
end

---@param effectModel XGuildDormFurnitureEffectModel
function XGDFurnitureEffectComponent:FurnitureHideEffect(effectModel)
    -- 标记已经隐藏特效
    effectModel:SetIsCreateEffect(false)
    self.Furniture:FurnitureHideEffect({ effectModel:GetEffectId() })
end

function XGDFurnitureEffectComponent:Dispose()

end

return XGDFurnitureEffectComponent