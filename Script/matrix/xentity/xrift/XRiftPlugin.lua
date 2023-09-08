---@class XRiftPlugin 战双大秘境插件
local XRiftPlugin = XClass(nil, "XRiftPlugin")
local CommonText = XUiHelper.GetText("Common")

function XRiftPlugin:Ctor(config)
    ---@type XTableRiftPlugin
    self.Config = config
    self.IsHave = false
end

function XRiftPlugin:GetId()
    return self.Config.Id
end

function XRiftPlugin:GetName()
    return self.Config.Name
end

function XRiftPlugin:GetStar()
    return self.Config.Star
end

function XRiftPlugin:GetFilterTags()
    return self.Config.Tags
end

function XRiftPlugin:IsContainTag(tagId)
    return table.indexof(self.Config.Tags, tagId)
end

function XRiftPlugin:GetIcon()
    return self.Config.Icon
end

function XRiftPlugin:GetQuality()
    return self.Config.Quality
end

function XRiftPlugin:GetTag()
    if self.Config.CharacterId ~= 0 then
        return XMVCA.XCharacter:GetCharacterName(self.Config.CharacterId)
    else
        return CommonText
    end
end

function XRiftPlugin:GetQualityImage()
    local config = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftPluginQuality, self.Config.Quality)
    return config.Image, config.ImageBg
end

function XRiftPlugin:GetImageDropHead()
    local config = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftPluginQuality, self.Config.Quality)
    return config.ImageDropHead
end

-- 插件总描述
function XRiftPlugin:GetDesc(isDetailTxt)
    if isDetailTxt == nil then
        isDetailTxt = true
    end
    local attrLevel = XDataCenter.RiftManager.GetDefaultTemplateAttrLevel(self.Config.DescFixAttrId)
    local descInitValue = self.Config.DescInitValue / 10000 -- DescInitValue配表按*10000填写
    local descCoefficient = self.Config.DescCoefficient / 10000 -- DescCoefficient配表按*10000填写
    local attrAddValue = attrLevel * descCoefficient
    local desc = isDetailTxt and self.Config.Desc or self.Config.SimpleDesc
    desc = desc or ""
    desc = string.gsub(desc, "{0}", self:FormatNum(descInitValue + attrAddValue))
    desc = string.gsub(desc, "{1}", self:FormatNum(descInitValue))
    desc = string.gsub(desc, "{2}", self:FormatNum(attrAddValue))
    desc = string.gsub(desc, "{3}", attrLevel)
    desc = string.gsub(desc, "{4}", self:FormatNum(descCoefficient))
    if self.Config.DescTips then
        desc = desc .. self.Config.DescTips
    end
    return desc
end

---暗金描述
function XRiftPlugin:GetGoldDesc()
    return self.Config.GoldDesc or ""
end

-- 保留到小数点一位，小数如果为0，则去掉
function XRiftPlugin:FormatNum(num)
    num = string.format("%.1f", num)
    num = tonumber(num)
    local t1, t2 = math.modf(num)
    if t2 > 0 then
        return num
    else
        return t1
    end
end

-- 获取插件补正类型，如：能量：S、体力：A
function XRiftPlugin:GetAttrFixTypeList()
    if self.Config.FixAttrIds == nil then
        return {}
    end

    local attrTypeList = {}
    for index, attrId in ipairs(self.Config.FixAttrIds) do
        local level = self.Config.FixAttrLevels[index]
        local attrType = XRiftConfig.GetAttrName(attrId) .. "：" .. XRiftConfig.AttributeLevelStr[level]
        table.insert(attrTypeList, attrType)
    end
    return attrTypeList
end

---获取属性标签
function XRiftPlugin:GetPropTag()
    local tagNames = {}
    local element = self.Config.Element
    local configs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftFilterTag)
    local specialTagId = tonumber(XDataCenter.RiftManager:GetClientConfig("PropStrengthTagId"))
    for _, tagId in pairs(self.Config.Tags) do
        if tagId == specialTagId then
            --【属性强化】要根据Element替换成【火属性强化】等
            table.insert(tagNames, configs[tagId].Params[element])
        elseif configs[tagId] then
            table.insert(tagNames, configs[tagId].Name)
        end
    end
    -- 暗金装备额外显示【暗金】标签
    if self:IsSpecialQuality() then
        table.insert(tagNames, XUiHelper.GetText("RiftGoldTagName"))
    end
    return tagNames
end

-- 获取插件总的战力值
-- 不传属性加点模板xAttrTemplate，则用默认的
function XRiftPlugin:GetAbility(xAttrTemplate)
    local ability = self.Config.Ability
    local attrFixCfgList = self:GetAttrFixConfigList(xAttrTemplate)
    for _, attrFixCfg in ipairs(attrFixCfgList) do
        ability = ability + attrFixCfg.Ability
    end

    return ability
end

-- 获取补正效果，未拼接好字符串，可与队伍属性加点效果叠加处理
-- 不传属性加点模板xAttrTemplate，则用默认的
function XRiftPlugin:GetEffectList(xAttrTemplate)
    local attrFixCfgList = self:GetAttrFixConfigList(xAttrTemplate)
    if #attrFixCfgList == 0 then
        return {}
    end

    local effectList = {}
    for _, attrFixCfg in ipairs(attrFixCfgList) do
        local showValue = attrFixCfg.EffectValue
        local effectTypeCfg = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftTeamAttributeEffectType, attrFixCfg.EffectType)
        if effectTypeCfg.ShowType == XRiftConfig.AttributeFixEffectType.Percent then
            showValue = self:FormatNum(attrFixCfg.EffectValue / 100)
        end
        local effect = { EffectType = attrFixCfg.EffectType, EffectValue = showValue }
        table.insert(effectList, effect)
    end

    return effectList
end

-- 获取补正效果，已拼接好效果值字符串
function XRiftPlugin:GetEffectStringList()
    local attrFixCfgList = self:GetAttrFixConfigList()
    if #attrFixCfgList == 0 then
        return {}
    end

    local effectList = {}
    for _, attrFixCfg in ipairs(attrFixCfgList) do
        local valueString
        local attrName = XRiftConfig.GetAttrName(attrFixCfg.FixAttrId)
        local attrLevel = XDataCenter.RiftManager.GetDefaultTemplateAttrLevel(attrFixCfg.FixAttrId)

        local effectTypeCfg = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftTeamAttributeEffectType, attrFixCfg.EffectType)
        if effectTypeCfg.ShowType == XRiftConfig.AttributeFixEffectType.Percent then
            local showValue = self:FormatNum(attrFixCfg.EffectValue / 100)
            valueString = string.format("+%s（%s%s）", showValue .. "%", attrName, attrLevel)
        else
            valueString = string.format("+%s（%s%s）", attrFixCfg.EffectValue, attrName, attrLevel)
        end

        local effect = { Name = effectTypeCfg.Name, ValueString = valueString, Order = effectTypeCfg.Order }
        table.insert(effectList, effect)
    end
    table.sort(effectList,  function(a, b)
        return a.Order < b.Order
    end)

    return effectList
end

function XRiftPlugin:SetHave()
    self.IsHave = true
end

function XRiftPlugin:GetHave()
    return self.IsHave
end

function XRiftPlugin:IsUnlock()
    local needSeason = self.Config.Season
    if not XTool.IsNumberValid(needSeason) or XDataCenter.RiftManager:CheckSeasonOpen(needSeason) then
        return true, ""
    end
    return false, XUiHelper.GetText("RiftPluginLock", XDataCenter.RiftManager:GetSeasonNameByIndex(needSeason))
end

-- 是否为展示插件，用于UI上刷新显示，不会掉落，不在插件背包显示
function XRiftPlugin:GetIsDisplay()
    return self.Config.IsDisplay == 1
end

-- 获取补正的configList（根据当前默认加点模板属性值）
-- 不传属性加点模板xAttrTemplate，则用默认的
function XRiftPlugin:GetAttrFixConfigList(xAttrTemplate)
    if xAttrTemplate == nil then
        xAttrTemplate = XDataCenter.RiftManager.GetAttrTemplate(XRiftConfig.DefaultAttrTemplateId)
    end

    local attrFixCfgList = {}
    for _, groupId in ipairs(self.Config.AttrFixGroupIds) do
        local attrId = XRiftConfig.GetAttrIdByFixGroupId(groupId)
        local attrLevel = xAttrTemplate:GetAttrLevel(attrId)
        local attrFixCfg = XRiftConfig.GetPluginAttrFixConfig(groupId, attrId, attrLevel)
        table.insert(attrFixCfgList, attrFixCfg)
    end

    return attrFixCfgList
end

-- 检测该插件是否有角色条件限制
function XRiftPlugin:CheckCharacterWearLimit(characterId)
    if not XTool.IsNumberValid(self.Config.CharacterId) then
        return false
    end

    return self.Config.CharacterId ~= characterId
end

-- 检测当前插件是有相同类型穿戴限制
function XRiftPlugin:CheckCurPluginTypeLimit(xRole)
    for k, xPlugin in pairs(xRole:GetPlugIns()) do
        if xPlugin.Config.Type == self.Config.Type then
            return true
        end
    end
end

-- 检测该角色是否可以穿戴该插件
function XRiftPlugin:GetCharacterUpgradeRedpoint()
    local redKey = "RiftCharacterPluginRed"..XPlayer.Id.."PluginId:"..self:GetId()
    local isShowRed = XSaveTool.GetData(redKey)

    return isShowRed
end

function XRiftPlugin:SetCharacterUpgradeRedpoint(flag)
    local redKey = "RiftCharacterPluginRed"..XPlayer.Id.."PluginId:"..self:GetId()
    XSaveTool.SaveData(redKey, flag)
end

---是否暗金品质
function XRiftPlugin:IsSpecialQuality()
    return self.Config.Quality >= 5
end

---构界突破
function XRiftPlugin:IsStageUpgrade()
    local stageUpgradeType = tonumber(XDataCenter.RiftManager:GetClientConfig("BreakType"))
    return self.Config.Type == stageUpgradeType
end

return XRiftPlugin