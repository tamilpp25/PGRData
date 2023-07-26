-- 战双大秘境队伍加点
local XRiftAttributeTemplete = XClass(nil, "RiftAttributeTemplete")


function XRiftAttributeTemplete:Ctor(id, attrList)
    self.Id = id
    self.AttrList = attrList or {}

    if attrList == nil then
        for id = 1, XRiftConfig.AttrCnt do
            self:SetAttrLevel(id, 0)
        end
    end
end

function XRiftAttributeTemplete:GetAttrLevel(attrId)
    if self.AttrList[attrId] then
        return self.AttrList[attrId].Level
    else
        return 0
    end
end

function XRiftAttributeTemplete:SetAttrLevel(attrId, level)
    self.AttrList[attrId] = { Id = attrId, Level = level}
end

function XRiftAttributeTemplete:GetAllLevel()
    local allLevel = 0
    for _, attr in ipairs(self.AttrList) do
        allLevel = allLevel + attr.Level
    end
    return allLevel
end

function XRiftAttributeTemplete:GetAbility()
    local effectCfgList = self:GetEffectCfgList()
    local allAbility = 0
    for _, effectCfg in ipairs(effectCfgList) do
        allAbility = allAbility + effectCfg.Ability
    end

    return allAbility
end

function XRiftAttributeTemplete:GetEffectList()
    local effectCfgList = self:GetEffectCfgList()

    -- 读取效果属性详情
    local effectList = {}
    for index, effectCfg in ipairs(effectCfgList) do
        local effect = { EffectType = effectCfg.EffectType, EffectValue = effectCfg.EffectValue }
        table.insert(effectList, effect)
    end
    return effectList
end

function XRiftAttributeTemplete:GetEffectCfgList()
    local effectCfgList = {}
    local configs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTeamAttribute)
    for _, attr in ipairs(self.AttrList) do
        if attr.Level > 0 then 
            local effectGroupIds = configs[attr.Id].EffectGroupIds
            for _, groupId in ipairs(effectGroupIds) do
                local effectCfg = XRiftConfig.GetAttributeEffectConfig(groupId, attr.Level)
                table.insert(effectCfgList, effectCfg)
            end
        end
    end

    return effectCfgList
end

return XRiftAttributeTemplete