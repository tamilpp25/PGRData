-- 战双大秘境队伍加点
local XRiftAttributeTemplate = XClass(nil, "RiftAttributeTemplate")


function XRiftAttributeTemplate:Ctor(id, attrList)
    self.Id = id
    self.AttrList = attrList or {}

    if attrList == nil then
        for id = 1, XRiftConfig.AttrCnt do
            self:SetAttrLevel(id, 0)
        end
    end
end

function XRiftAttributeTemplate:GetName()
    local key = "RiftAttributeTemplateName"..self.Id
    return XUiHelper.GetText(key)
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
    for index, effectCfg in ipairs(effectCfgList) do
        local showValue = effectCfg.EffectValue
        local effectTypeCfg = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftTeamAttributeEffectType, effectCfg.EffectType)
        if effectTypeCfg.ShowType == XRiftConfig.AttributeFixEffectType.Percent then
            showValue = string.format("%.1f", effectCfg.EffectValue / 100)
            showValue = self:FormatNum(showValue)
        end
        local effect = { EffectType = effectCfg.EffectType, EffectValue = showValue }
        table.insert(effectList, effect)
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
                table.insert(effectCfgList, effectCfg)
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

return XRiftAttributeTemplate