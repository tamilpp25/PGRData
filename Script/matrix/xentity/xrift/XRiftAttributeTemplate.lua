---@class XRiftAttributeTemplate 战双大秘境队伍加点
local XRiftAttributeTemplate = XClass(nil, "RiftAttributeTemplate")


function XRiftAttributeTemplate:Ctor(id, attrList, name)
    self.Id = id
    self.AttrList = attrList or {}
    self.CustomName = name
    self.DefaultName = XUiHelper.GetText("RiftAttributeTemplateName" .. self.Id)

    if attrList == nil then
        for id = 1, XRiftConfig.AttrCnt do
            self:SetAttrLevel(id, 0)
        end
    end
end

function XRiftAttributeTemplate:SetName(name)
    self.CustomName = name
end

function XRiftAttributeTemplate:GetName()
    return self.CustomName or self.DefaultName
end

function XRiftAttributeTemplate:GetAttrLevel(attrId)
    if self.AttrList[attrId] then
        return self.AttrList[attrId].Level
    else
        return 0
    end
end

function XRiftAttributeTemplate:SetAttrLevel(attrId, level)
    self.AttrList[attrId] = { Id = attrId, Level = level}
end

function XRiftAttributeTemplate:GetAllLevel()
    local allLevel = 0
    for _, attr in ipairs(self.AttrList) do
        allLevel = allLevel + attr.Level
    end
    return allLevel
end

function XRiftAttributeTemplate:GetAbility()
    local effectCfgList = self:GetEffectCfgList()
    local allAbility = 0
    for _, effectCfg in ipairs(effectCfgList) do
        allAbility = allAbility + effectCfg.Ability
    end

    return allAbility
end

function XRiftAttributeTemplate:GetEffectList()
    local effectCfgList = self:GetEffectCfgList()

    -- 读取效果属性详情
    local effectList = {}
    for _, effectCfg in ipairs(effectCfgList) do
        local showValue = effectCfg.EffectValue
        if showValue > 0 then
            local isPercent
            if effectCfg.PropType == XEnumConst.Rift.PropType.Battle then
                local effectTypeCfg = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftTeamAttributeEffectType, effectCfg.EffectType)
                isPercent = effectTypeCfg.ShowType == XRiftConfig.AttributeFixEffectType.Percent
            elseif effectCfg.PropType == XEnumConst.Rift.PropType.System then
                local effectTypeCfg = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftSystemAttributeEffectType, effectCfg.EffectType)
                isPercent = effectTypeCfg.ShowType == XRiftConfig.AttributeFixEffectType.Percent
            end
            if isPercent then
                showValue = string.format("%.1f", effectCfg.EffectValue / 100)
                showValue = self:FormatNum(showValue)
            end
            local effect = { EffectType = effectCfg.EffectType, EffectValue = showValue, PropType = effectCfg.PropType }
            table.insert(effectList, effect)
        end
    end
    return effectList
end

function XRiftAttributeTemplate:GetEffectCfgList()
    local effectCfgList = {}
    local configs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTeamAttribute)
    for _, attr in ipairs(self.AttrList) do
        if attr.Level > 0 then 
            local effectGroupIds = configs[attr.Id].EffectGroupIds
            for _, groupId in ipairs(effectGroupIds) do
                local effectCfg = XRiftConfig.GetAttributeEffectConfig(groupId, attr.Level)
                local battleData = {}
                battleData.PropType = XEnumConst.Rift.PropType.Battle
                battleData.EffectType = effectCfg.EffectType
                battleData.EffectValue = effectCfg.EffectValue
                battleData.Ability = effectCfg.Ability
                table.insert(effectCfgList, battleData)

                if XTool.IsNumberValid(effectCfg.SystemEffectType) then
                    local sysData = {}
                    sysData.PropType = XEnumConst.Rift.PropType.System
                    sysData.EffectType = effectCfg.SystemEffectType
                    sysData.EffectValue = XDataCenter.RiftManager:GetSystemAttrValue(effectCfg.SystemEffectType, attr.Level)
                    sysData.Ability = 0
                    table.insert(effectCfgList, sysData)
                end
            end
        end
    end

    return effectCfgList
end

-- 是否是空模板
function XRiftAttributeTemplate:IsEmpty()
    return self.Id ~= XRiftConfig.DefaultAttrTemplateId and self:GetAllLevel() == 0
end

-- 小数如果为0，则去掉
function XRiftAttributeTemplate:FormatNum(num)
    num = tonumber(num)
    local t1, t2 = math.modf(num)
    if t2 > 0 then
        return num
    else
        return t1
    end
end

---@param data XRiftAttributeTemplate
function XRiftAttributeTemplate:Copy(data)
    for attrId = 1, 4 do
        self:SetAttrLevel(attrId, data:GetAttrLevel(attrId))
    end
end

-- 有足够加一级的货币and至少一个属性的加点没有达到上限
function XRiftAttributeTemplate:CanAddPoint()
    local attrLevelMax = 0
    local totalLevel = 0
    for attrId = 1, 4 do
        totalLevel = totalLevel + self:GetAttrLevel(attrId)
        attrLevelMax = attrLevelMax + XDataCenter.RiftManager.GetAttrLevelMax()
    end
    if totalLevel >= attrLevelMax then
        return false
    end
    local const = XDataCenter.RiftManager.GetAttributeCost(totalLevel)
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
    local goldEnough = ownCnt >= const

    local buyAttrLevel = XDataCenter.RiftManager.GetTotalAttrLevel()
    if totalLevel == buyAttrLevel then
        local nextLvCost = XDataCenter.RiftManager.GetAttributeCost(buyAttrLevel + 1)
        if nextLvCost > 0 then
            goldEnough = ownCnt >= nextLvCost
        end
    end

    return goldEnough
end

return XRiftAttributeTemplate