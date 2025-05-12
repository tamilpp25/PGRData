---@class XTheatre4EffectSubControl : XControl
---@field private _Model XTheatre4Model
---@field _MainControl XTheatre4Control
local XTheatre4EffectSubControl = XClass(XControl, "XTheatre4EffectSubControl")
function XTheatre4EffectSubControl:OnInit()
    --初始化内部变量
    self._SpecialType = {
        [XEnumConst.Theatre4.EffectType.Type32] = Handler(self, self.GetSpecialEffectCountType32),
        [XEnumConst.Theatre4.EffectType.Type35] = Handler(self, self.GetSpecialEffectCountType32),
    }
end

function XTheatre4EffectSubControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XTheatre4EffectSubControl:RemoveAgencyEvent()

end

function XTheatre4EffectSubControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
    self._SpecialType = nil
end

--region 效果配置相关

-- 获取效果类型
function XTheatre4EffectSubControl:GetEffectTypeById(effectId)
    return self._Model:GetEffectTypeById(effectId)
end

-- 获取效果描述
function XTheatre4EffectSubControl:GetEffectDescById(effectId)
    return self._Model:GetEffectDescById(effectId)
end

-- 获取效果描述
function XTheatre4EffectSubControl:GetEffectOtherDescById(effectId)
    return self._Model:GetEffectOtherDescById(effectId)
end

-- 获取效果参数
function XTheatre4EffectSubControl:GetEffectParams(effectId)
    return self._Model:GetEffectParamsById(effectId)
end

-- 获取效果配置中的建筑Id
function XTheatre4EffectSubControl:GetBuildIdByEffectId(effectId)
    local effectType = self:GetEffectTypeById(effectId)
    if effectType == XEnumConst.Theatre4.EffectType.Type101 then
        local params = self:GetEffectParams(effectId)
        return params[1] or 0
    end
    if effectType == XEnumConst.Theatre4.EffectType.Type414 then
        local params = self:GetEffectParams(effectId)
        return params[1] or 0
    end
    XLog.Warning("[XTheatre4EffectSubControl] 建筑id获取失败, 是否有新增的建筑技能?")
    return 0
end

-- 获取效果配置中的颜色Id
function XTheatre4EffectSubControl:GetColorIdByEffectId(effectId)
    local effectType = self:GetEffectTypeById(effectId)
    if effectType == XEnumConst.Theatre4.EffectType.Type115 then
        local params = self:GetEffectParams(effectId)
        return params[1] or 0
    end
    return 0
end

-- 通过天赋Id获取天赋配置的效果Ids
function XTheatre4EffectSubControl:GetEffectIdsByTalentId(talentId)
    local effectGroupId = self._Model:GetColorTalentEffectGroupIdById(talentId)
    if not XTool.IsNumberValid(effectGroupId) then
        return nil
    end
    return self._Model:GetEffectGroupEffectsById(effectGroupId)
end

-- 获取惩罚效果配置中的扣除血量
---@param fightId number 战斗Id
---@return number 扣除血量
function XTheatre4EffectSubControl:GetPunishEffectGroupHp(fightId)
    local punishEffectGroup = self._Model:GetFightPunishEffectGroupById(fightId)
    if not XTool.IsNumberValid(punishEffectGroup) then
        return 0
    end
    local effects = self._Model:GetEffectGroupEffectsById(punishEffectGroup)
    if XTool.IsTableEmpty(effects) then
        return 0
    end
    local hp = 0
    for _, effectId in pairs(effects) do
        local effectType = self:GetEffectTypeById(effectId)
        if effectType == XEnumConst.Theatre4.EffectType.Type407 then
            local params = self:GetEffectParams(effectId)
            hp = hp + (params[1] or 0)
        end
    end
    return hp
end

-- 获取变化的资产通过事件选项Id
---@param id number 事件选项Id
---@return number, number, number 资产类型, 资产Id, 变化数量
function XTheatre4EffectSubControl:GetChangeAssetCountByEventOptionId(id)
    local effectGroupId = self._Model:GetEventOptionEffectGroupIdById(id)
    if not XTool.IsNumberValid(effectGroupId) then
        return 0, 0, 0
    end
    local effectIds = self._Model:GetEffectGroupEffectsById(effectGroupId)
    if XTool.IsTableEmpty(effectIds) then
        return 0, 0, 0
    end
    if #effectIds > 1 then
        XLog.Warning("<color=#F1D116>Theatre4:</color> 事件选项配置了多个效果，事件选项Id:" .. id)
    end
    return self:GetEffect409ChangeAssetCount(effectIds[1])
end

-- 获取效果409变化后的资产数量
---@param effectConfigId number 效果配置Id
---@return number, number, number 资产类型, 资产Id, 变化数量
function XTheatre4EffectSubControl:GetEffect409ChangeAssetCount(effectConfigId)
    if not XTool.IsNumberValid(effectConfigId) then
        return 0, 0, 0
    end

    local effectType = self:GetEffectTypeById(effectConfigId)
    if effectType ~= XEnumConst.Theatre4.EffectType.Type409 then
        return 0, 0, 0
    end

    local params = self:GetEffectParams(effectConfigId)
    local opt = params[1] or 0
    local assetType = params[4] or 0
    local assetId = params[5] or 0
    local assetCount = self._MainControl.AssetSubControl:GetAssetCount(assetType, assetId)
    local newAssetCount = assetCount

    if opt == XEnumConst.Theatre4.Effect409OptType.Add then
        newAssetCount = assetCount + (params[2] or 0)
    elseif opt == XEnumConst.Theatre4.Effect409OptType.Sub then
        newAssetCount = assetCount - (params[2] or 0)
    elseif opt == XEnumConst.Theatre4.Effect409OptType.Multiply then
        newAssetCount = math.floor(assetCount * (params[3] or 0) / XEnumConst.Theatre4.RatioDenominator)
    elseif opt == XEnumConst.Theatre4.Effect409OptType.Division and params[3] > 0 then
        newAssetCount = math.floor(assetCount / (params[3] / XEnumConst.Theatre4.RatioDenominator))
    end

    newAssetCount = math.max(newAssetCount, 0)
    local changeCount = newAssetCount - assetCount
    return assetType, assetId, changeCount
end

-- 根据效果410获取每日结束时获得的资产数量
---@return boolean, number 是否有效果, 资产数量
function XTheatre4EffectSubControl:GetEffect410OnDailySettleAssetCount()
    local effects = self:GetEffectsByType(XEnumConst.Theatre4.EffectType.Type410)
    if XTool.IsTableEmpty(effects) then
        return false, 0
    end

    local currentAp = self._MainControl.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.ActionPoint)
    if currentAp <= 0 then
        return true, 0
    end

    local params = self:GetEffectParams(effects[1]:GetEffectId())
    local requiredAp = params[1] or 0
    if requiredAp <= 0 then
        return true, 0
    end

    local times = math.max(math.floor(currentAp / requiredAp), 0)
    return true, (params[4] or 0) * times
end

-- 控制建筑开关
function XTheatre4EffectSubControl:GetEffect414ControlBuildSwitch()
    local effects = self:GetEffectsByType(XEnumConst.Theatre4.EffectType.Type414)
    if XTool.IsTableEmpty(effects) then
        return false
    end
    local openStatus = {}
    for _, effect in pairs(effects) do
        local params = self:GetEffectParams(effect:GetEffectId())
        if #params > 0 then
            -- 关闭他们
            for i = 1, #params do
                openStatus[params[i]] = false
            end
        end
    end
    return openStatus
end

--endregion

--region 效果相关

-- 获取所有的天赋效果
---@return table<number, XTheatre4Effect>
function XTheatre4EffectSubControl:GetAllTalentEffects()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return {}
    end
    return adventureData:GetAllTalentEffects()
end

-- 获取天赋效果通过colorId
---@param colorId number 颜色Id
---@return table<number, XTheatre4Effect>
function XTheatre4EffectSubControl:GetTalentEffectsByColorId(colorId)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return {}
    end
    return adventureData:GetTalentEffectsByColorId(colorId)
end

-- 获取所有的藏品效果
---@return table<number, XTheatre4Effect>
function XTheatre4EffectSubControl:GetAllItemEffects()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return {}
    end
    return adventureData:GetAllItemEffects()
end

-- 获取藏品效果通过UId
---@param uid number 自增Id
---@return table<number, XTheatre4Effect>
function XTheatre4EffectSubControl:GetItemEffectsByUid(uid)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetItemEffectsByUid(uid)
end

-- 获取所有线索道具效果
---@return table<number, XTheatre4Effect>
function XTheatre4EffectSubControl:GetAllPropEffects()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return {}
    end
    return adventureData:GetAllPropEffects()
end

-- 获取线索道具效果通过UId
---@param uid number 自增Id
---@return table<number, XTheatre4Effect>
function XTheatre4EffectSubControl:GetPropEffectsByUid(uid)
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return nil
    end
    return adventureData:GetPropEffectsByUid(uid)
end

-- 获取公公共效果集
---@return table<number, XTheatre4Effect>
function XTheatre4EffectSubControl:GetAllCustomEffects()
    local adventureData = self._Model:GetAdventureData()
    if not adventureData then
        return {}
    end
    return adventureData:GetCustomEffects()
end

-- 获取所有的效果
---@return table<number, XTheatre4Effect>
function XTheatre4EffectSubControl:GetAllEffects()
    local effects = {}
    local allEffects = { self:GetAllTalentEffects(), self:GetAllItemEffects(), self:GetAllPropEffects(), self:GetAllCustomEffects() }
    for _, effectGroup in ipairs(allEffects) do
        for index, effect in pairs(effectGroup) do
            effects[index] = effect
        end
    end
    return effects
end

-- 通过效果类型获取效果
---@param effectType number 效果类型
---@param count number 获取数量
---@return XTheatre4Effect[]
function XTheatre4EffectSubControl:GetEffectsByType(effectType, count)
    local effects = self:GetAllEffects()
    local list = {}
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        if self:GetEffectTypeById(id) == effectType then
            table.insert(list, effect)
            -- 获取指定数量
            if XTool.IsNumberValid(count) and #list >= count then
                break
            end
        end
    end
    return list
end

--endregion

--region 效果消耗相关

-- 检查效果需要的资源是否足够
---@param effectId number 效果Id
---@param isNotTips boolean 是否不提示
function XTheatre4EffectSubControl:CheckEffectAssetEnough(effectId, isNotTips)
    local costCount, costType, costId = self:GetEffectCostInfo(effectId)
    if not self._MainControl.AssetSubControl:CheckAssetEnough(costType, costId, costCount, isNotTips) then
        return false
    end
    return true
end

-- 获取效果消耗信息
---@param effectId number 效果Id
---@return number, number, number 消耗数量, 消耗类型, 资产Id
function XTheatre4EffectSubControl:GetEffectCostInfo(effectId)
    local effectCfg = self._Model:GetEffectConfigById(effectId)
    if not effectCfg then
        return 0, 0, 0
    end
    local price = 0
    local costUp = self._Model:GetEffectSkillCostUpById(effectId)
    -- 根据次数涨价
    local useTimes = self:GetEffectUseTimes(effectId)
    if useTimes == 0 or #costUp == 0 then
        local skillCostCount = self._Model:GetEffectSkillCostCountById(effectId)
        price = price + skillCostCount
    else
        local size = #costUp
        if useTimes > size then
            useTimes = size
            --XLog.Debug("[XTheatre4EffectSubControl] 涨价到极限了")
        end
        local increase = costUp[useTimes]
        if increase then
            price = price + increase
            --XLog.Debug("[XTheatre4EffectSubControl] 涨价了:" .. increase)
        end
    end

    local costExtraCount = self:GetEffectSkillExtraCost(effectId)
    price = price + costExtraCount
    if price < 0 then
        price = 0
    end
    return price, effectCfg.SkillCostType, effectCfg.SkillCostId
end

function XTheatre4EffectSubControl:GetEffectUseTimes(effectId)
    local useTimes = 0
    local effects = self:GetAllEffects()
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        if id == effectId then
            useTimes = useTimes + effect:GetUseTimes()
            --if useTimes > 0 then
            --    XLog.Error("[XTheatre4EffectSubControl] effect数量不唯一:" .. effectId)
            --end
        end
    end
    return useTimes
end

-- 获取创建建筑技能消耗额外值
function XTheatre4EffectSubControl:GetEffectSkillExtraCost(effectId)
    local extraCost = 0
    local effects = self:GetAllEffects()
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        local params = self:GetEffectParams(id)
        local effectType = self:GetEffectTypeById(id)
        if effectType == XEnumConst.Theatre4.EffectType.Type102 and params[1] == effectId then
            extraCost = extraCost + params[2] or 0
        end
    end
    return extraCost
end

--endregion

--region 效果描述相关

-- 获取藏品效果描述
---@param UId number 自增Id
---@param itemId number 道具Id
---@param isBubble boolean 是否展示在主界面
function XTheatre4EffectSubControl:GetItemEffectDesc(UId, itemId, isBubble)
    local effects = self:GetItemEffectsByUid(UId) or self:GetPropEffectsByUid(UId) or {}
    if XTool.IsTableEmpty(effects) then
        return nil
    end
    local effectDescId = self._Model:GetItemEffectDescIdById(itemId)
    if not XTool.IsNumberValid(effectDescId) then
        return nil
    end
    local effectType = self._Model:GetItemEffectCountEffectTypeById(effectDescId)
    local count = 0
    for _, effect in pairs(effects) do
        count = count + self:GetItemEffectCount(effect, effectType)
    end
    count = self:GetSpecialEffectCount(effectType, effects, count)
    if count <= 0 then
        return nil
    end

    count = math.roundDecimals(count, 1)

    local desc = ""
    if isBubble then
        desc = self._Model:GetItemEffectCountBubbleDescById(effectDescId)
    else
        desc = self._Model:GetItemEffectCountDescById(effectDescId)
    end
    return XUiHelper.ReplaceTextNewLine(XUiHelper.FormatText(desc, count))
end

-- 获取藏品效果累计的数量
---@param effect XTheatre4Effect 效果
---@param effectType number 效果类型
function XTheatre4EffectSubControl:GetItemEffectCount(effect, effectType)
    if not XTool.IsNumberValid(effectType) then
        return 0
    end
    if self:GetEffectTypeById(effect:GetEffectId()) == effectType then
        effectType = self:GetConvertEffectType(effectType)
        local methodName = string.format("GetEffectAccumulateType%s", effectType)
        return self[methodName] and self[methodName](self, effect) or 0
    end
    return 0
end

-- 获取转换效果类型
---@param effectType number 效果类型
---@return number 转换后的效果类型
function XTheatre4EffectSubControl:GetConvertEffectType(effectType)
    -- 1、2 -> 1
    local type1 = {
        XEnumConst.Theatre4.EffectType.Type1,
        XEnumConst.Theatre4.EffectType.Type2
    }
    -- 12、13、20、28、29、32、35、36、38 -> 12
    local type12 = {
        XEnumConst.Theatre4.EffectType.Type12,
        XEnumConst.Theatre4.EffectType.Type13,
        XEnumConst.Theatre4.EffectType.Type20,
        XEnumConst.Theatre4.EffectType.Type28,
        XEnumConst.Theatre4.EffectType.Type29,
        XEnumConst.Theatre4.EffectType.Type32,
        XEnumConst.Theatre4.EffectType.Type35,
        XEnumConst.Theatre4.EffectType.Type36,
        XEnumConst.Theatre4.EffectType.Type38
    }
    -- 14、16、17、19、22、34 -> 14
    local type14 = {
        XEnumConst.Theatre4.EffectType.Type14,
        XEnumConst.Theatre4.EffectType.Type16,
        XEnumConst.Theatre4.EffectType.Type17,
        XEnumConst.Theatre4.EffectType.Type19,
        XEnumConst.Theatre4.EffectType.Type22,
        XEnumConst.Theatre4.EffectType.Type34
    }
    if table.contains(type1, effectType) then
        return XEnumConst.Theatre4.EffectType.Type1
    elseif table.contains(type12, effectType) then
        return XEnumConst.Theatre4.EffectType.Type12
    elseif table.contains(type14, effectType) then
        return XEnumConst.Theatre4.EffectType.Type14
    end
    return effectType
end

-- 获取特殊处理的效果累计的数量
function XTheatre4EffectSubControl:GetSpecialEffectCount(effectType, effects, count)
    if self._SpecialType[effectType] then
        return self._SpecialType[effectType](effectType, effects, count)
    end
    return count
end

---@param effect XTheatre4Effect
function XTheatre4EffectSubControl:GetEffectAccumulateType1(effect)
    local count = 0
    for _, colorId in pairs(XEnumConst.Theatre4.ColorType) do
        count = count + (effect:GetCustomData(colorId) or 0)
    end
    return count
end

---@param effect XTheatre4Effect
function XTheatre4EffectSubControl:GetEffectAccumulateType4(effect)
    local count = effect:GetCount()
    local params = self:GetEffectParams(effect:GetEffectId())
    return count / params[1] * params[2]
end

---@param effect XTheatre4Effect
function XTheatre4EffectSubControl:GetEffectAccumulateType8(effect)
    return self._MainControl:GetCharacterMaxStar()
end

---@param effect XTheatre4Effect
function XTheatre4EffectSubControl:GetEffectAccumulateType12(effect)
    return effect:GetAccumulate()
end

---@param effect XTheatre4Effect
function XTheatre4EffectSubControl:GetEffectAccumulateType14(effect)
    return effect:GetMarkupRate()
end

---@param effect XTheatre4Effect
function XTheatre4EffectSubControl:GetEffectAccumulateType27(effect)
    return effect:GetCount()
end

---@param effect XTheatre4Effect
function XTheatre4EffectSubControl:GetEffectAccumulateType33(effect)
    return effect:GetCustomData()
end

---@param effect XTheatre4Effect
function XTheatre4EffectSubControl:GetEffectAccumulateType37(effect)
    local accumulate = effect:GetAccumulate()
    if accumulate > 0 then
        return accumulate
    end
    local markupRate = effect:GetMarkupRate()
    if markupRate > 0 then
        return markupRate
    end
    return 0
end

--endregion

--region 效果计算相关

-- 获取改造格子颜色技能额外改造格子数量
function XTheatre4EffectSubControl:GetEffectAlterGridColorExtraGridCount()
    return self:GetEffectSimpleValue(XEnumConst.Theatre4.EffectType.Type116)
end

-- 获取移除障碍技能额外移除格子数量
function XTheatre4EffectSubControl:GetEffectRemoveHurdleExtraGridCount()
    return self:GetEffectSimpleValue(XEnumConst.Theatre4.EffectType.Type119)
end

-- 获取商店刷新是否可用
function XTheatre4EffectSubControl:GetEffectShopRefreshAvailable()
    return self:CheckTalentEffectContainEffect(XEnumConst.Theatre4.EffectType.Type204)
end

-- 获取怪物扫荡(诏安)功能是否开启
function XTheatre4EffectSubControl:GetEffectMonsterSweepAvailable()
    return self:CheckTalentEffectContainEffect(XEnumConst.Theatre4.EffectType.Type205)
end

-- 红色买死功能是否开启
function XTheatre4EffectSubControl:GetEffectRedBuyDeadAvailable()
    return self:CheckTalentEffectContainEffect(XEnumConst.Theatre4.EffectType.Type422)
end

-- 觉醒值额外加成功能是否开启
function XTheatre4EffectSubControl:GetEffectRedBuyDeadIncreaseAvailable()
    return self:CheckTalentEffectContainEffect(XEnumConst.Theatre4.EffectType.Type416)
end

-- 红色买死半价功能是否开启
function XTheatre4EffectSubControl:GetEffectRedBuyDeadHalfDiscountAvailable()
    return self:CheckTalentEffectContainEffect(XEnumConst.Theatre4.EffectType.Type421)
end

-- 获取时间回溯功能是否开启
function XTheatre4EffectSubControl:GetEffectTimeBackAvailable()
    local chapterData = self._Model:GetLastChapterData()
    if chapterData then
        local mapId = chapterData:GetMapId()
        local mapConfig = self._Model:GetMapConfigById(mapId)
        if mapConfig then
            local traceBackGroupId = mapConfig.TracebackGroupId
            if traceBackGroupId and traceBackGroupId > 0 then
                local difficulty = self._MainControl:GetDifficulty()
                local traceBackConfig = self._Model:GetTraceBackConfigByIdAndDifficulty(traceBackGroupId, difficulty)
                -- 存在时间回溯配置才开启
                if traceBackConfig then
                    return self:CheckTalentEffectContainEffect(XEnumConst.Theatre4.EffectType.Type423)
                end
            end
        end
    end
    return false
end

-- 觉醒功能是否开启
function XTheatre4EffectSubControl:GetEffectAwakeAvailable()
    return self:CheckTalentEffectContainEffect(XEnumConst.Theatre4.EffectType.Type424)
end

-- 获取怪物扫荡(诏安)折扣 (万分比）
function XTheatre4EffectSubControl:GetEffectSweepDiscount()
    local discount = self:GetEffectSimpleValue(XEnumConst.Theatre4.EffectType.Type206)
    -- 无折扣
    if discount == 0 then
        return 1
    end
    discount = discount + XEnumConst.Theatre4.RatioDenominator
    if discount <= 0 then
        return 0
    end
    return discount / XEnumConst.Theatre4.RatioDenominator
end

-- 获取利息额外上限
---@return number, number 额外利息上限, 额外最终利息奖励
function XTheatre4EffectSubControl:GetEffectInterestExtraParams()
    local effects = self:GetAllEffects()
    local extraAwardLimit = 0
    local extraAwardLimit2 = 0
    local extraFinalAwardCount = 0
    local sweepTimes = self._MainControl:GetEffectSweepTimes()
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        local type = self:GetEffectTypeById(id)
        local params = self:GetEffectParams(id)
        if type == XEnumConst.Theatre4.EffectType.Type207 then
            extraFinalAwardCount = extraFinalAwardCount + (params[1] or 0) * sweepTimes
        end
        if type == XEnumConst.Theatre4.EffectType.Type208 then
            extraAwardLimit = extraAwardLimit + (params[1] or 0)
        end
        if type == XEnumConst.Theatre4.EffectType.Type210 then
            -- 效果210 只能有一个生效
            extraAwardLimit2 = effect:GetCustomData()
        end
    end
    extraAwardLimit = extraAwardLimit + extraAwardLimit2
    return extraAwardLimit, extraFinalAwardCount
end

-- 获取利息满时额外上限
function XTheatre4EffectSubControl:EffectWhenInterestFullExtra()
    local effects = self:GetEffectsByType(XEnumConst.Theatre4.EffectType.Type210, 1)
    if #effects <= 0 then
        return 0
    end
    local effect = effects[1]
    local id = effect:GetEffectId()
    local params = self:GetEffectParams(id)
    local maxExtraLimit = params[2] or 0
    local extraLimit = effect:GetCustomData()
    if extraLimit >= maxExtraLimit then
        return 0
    end
    local newExtraLimit = math.min(extraLimit + params[1], maxExtraLimit)
    return newExtraLimit - extraLimit
end

-- 获取天赋刷新额外消耗
function XTheatre4EffectSubControl:GetEffectRefreshTalentExtraCost()
    return self:GetEffectSimpleValue(XEnumConst.Theatre4.EffectType.Type301)
end

-- 获取天赋刷新额外消耗
function XTheatre4EffectSubControl:GetEffectSweepHpDiscount()
    local effectType = XEnumConst.Theatre4.EffectType.Type421
    local effects = self:GetAllEffects()
    local value = 0
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        local type = self:GetEffectTypeById(id)
        local params = self:GetEffectParams(id)
        if params[1] == XEnumConst.Theatre4.SweepType.Yellow then
            if type == effectType then
                if params[2] then
                    value = params[2]
                    break
                end
            end
        end
    end
    return value
end

-- 简单累加的效果
---@param effectType number 效果类型
function XTheatre4EffectSubControl:GetEffectSimpleValue(effectType)
    local effects = self:GetAllEffects()
    local value = 0
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        local type = self:GetEffectTypeById(id)
        local params = self:GetEffectParams(id)
        if type == effectType then
            value = value + (params[1] or 0)
        end
    end
    return value
end

-- 简单集合的效果
---@param effectType number 效果类型
function XTheatre4EffectSubControl:GetEffectSimpleList(effectType)
    local effects = self:GetAllEffects()
    local list = {}
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        local type = self:GetEffectTypeById(id)
        local params = self:GetEffectParams(id)
        if type == effectType then
            table.insert(list, params[1] or 0)
        end
    end
    return list
end

-- 检查天赋效果里是否包含某个效果类型
---@param effectType number 效果类型
function XTheatre4EffectSubControl:CheckTalentEffectContainEffect(effectType)
    local effects = self:GetAllEffects()
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        local type = self:GetEffectTypeById(id)
        if type == effectType then
            return true, id
        end
    end
    return false
end

-- 检查效果禁止战斗标记
---@param fightId number 战斗Id theatre4fight.tab里面的Id
---@param mapId number 地图Id
---@return boolean, number 是否禁止, 禁止类型 1可以扫荡,2不可以扫荡
function XTheatre4EffectSubControl:CheckEffectForbiddenFightType(fightId, mapId)
    if not XTool.IsNumberValid(fightId) or not XTool.IsNumberValid(mapId) then
        return false, 0
    end
    local fightType = self._MainControl:GetFightTypeById(fightId)
    if not XTool.IsNumberValid(fightType) then
        return false, 0
    end
    local effects = self:GetEffectsByType(XEnumConst.Theatre4.EffectType.Type411)
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        local params = self:GetEffectParams(id)
        if #params < 3 then
            XLog.Warning("<color=#F1D116>Theatre4:</color> 效果411参数不足")
            return false, 0
        end
        local found = false
        for i = 3, #params do
            if params[i] == mapId then
                found = true
                break
            end
        end
        if params[1] == fightType and found then
            return true, params[2] or 0
        end
    end
    return false, 0
end

-- 获取增加的资源数量
---@param params table 参数
---@param assetType number 资产类型
---@param times number 倍数
function XTheatre4EffectSubControl:GetAddAssetCount(params, assetType, times)
    times = XTool.IsNumberValid(times) and times or 1
    local count = params[1] == assetType and params[3] or 0
    return count * times
end

-- 获取每回合开始时加的建造点 (效果111 + 效果113 建筑数量相关)
function XTheatre4EffectSubControl:GetEffectBuildPointAdds()
    local buildingCount = self._MainControl.MapSubControl:GetBuildingCount()
    local effects = self:GetAllEffects()
    local value = 0
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        local type = self:GetEffectTypeById(id)
        local params = self:GetEffectParams(id)
        if type == XEnumConst.Theatre4.EffectType.Type111 then
            local count = self:GetAddAssetCount(params, XEnumConst.Theatre4.AssetType.BuildPoint)
            value = value + count
        end
        if type == XEnumConst.Theatre4.EffectType.Type113 and buildingCount > 0 then
            local count = self:GetAddAssetCount(params, XEnumConst.Theatre4.AssetType.BuildPoint, buildingCount)
            value = value + count
        end
    end
    return value
end

-- 获取每回合开始时加的金币 (效果113 建筑数量相关 + 效果209 未满利息结算时奖励 + 效果218 本局购物次数相关)
function XTheatre4EffectSubControl:GetEffectGoldAdds()
    local buildingCount = self._MainControl.MapSubControl:GetBuildingCount()
    local interest, interestAwardLimit = self:GetInterestAndLimit()
    local shopBuyTimes = self._MainControl:GetEffectShopBuyTimes()
    local effects = self:GetAllEffects()
    local value = 0
    for _, effect in pairs(effects) do
        local id = effect:GetEffectId()
        local type = self:GetEffectTypeById(id)
        local params = self:GetEffectParams(id)
        if type == XEnumConst.Theatre4.EffectType.Type113 and buildingCount > 0 then
            local count = self:GetAddAssetCount(params, XEnumConst.Theatre4.AssetType.Gold, buildingCount)
            value = value + count
        end
        if type == XEnumConst.Theatre4.EffectType.Type209 and interest < interestAwardLimit then
            local count = self:GetAddAssetCount(params, XEnumConst.Theatre4.AssetType.Gold)
            value = value + count
        end
        if type == XEnumConst.Theatre4.EffectType.Type218 and shopBuyTimes > 0 then
            local count = self:GetAddAssetCount(params, XEnumConst.Theatre4.AssetType.Gold, shopBuyTimes)
            value = value + count
        end
    end
    return value
end

-- 获取当前利息和利息上限
---@return number, number 当前利息, 利息上限
function XTheatre4EffectSubControl:GetInterestAndLimit()
    -- 单次利息需要金币
    local interestNeedCount = self._MainControl:GetConfig("InterestNeedCount")
    -- 单次利息奖励
    local interestAwardCount = self._MainControl:GetConfig("InterestAwardCount")
    -- 利息奖励上限
    local interestAwardLimit = self._MainControl:GetConfig("InterestAwardLimit")
    -- 额外利息上限, 额外最终利息奖励
    local extraAwardLimit, extraFinalAwardCount = self:GetEffectInterestExtraParams()
    interestAwardLimit = interestAwardLimit + extraAwardLimit
    local goldCount = self._MainControl.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Gold)
    local times = math.floor(goldCount / interestNeedCount)
    local interest = interestAwardCount * times + extraFinalAwardCount
    if interest >= interestAwardLimit then
        -- 利息满时, 额外利息上限2可能会成长
        interestAwardLimit = interestAwardLimit + self:EffectWhenInterestFullExtra()
        -- 溢出校正
        interest = math.min(interest, interestAwardLimit)
    end
    return interest, interestAwardLimit
end

--endregion

--region 特殊效果处理

-- 获取特殊效果类型32的处理
function XTheatre4EffectSubControl:GetSpecialEffectCountType32(effectType, effects, count)
    if not XTool.IsNumberValid(effectType) then
        return count
    end

    if not XTool.IsTableEmpty(effects) then
        local sum = 0
        local number = 0

        for _, effect in pairs(effects) do
            if self:GetEffectTypeById(effect:GetEffectId()) == effectType then
                sum = sum + self:GetItemEffectCount(effect, effectType)
                number = number + 1
            end
        end

        if number == 0 then
            return count
        end

        return count - sum + math.floor(sum / number)
    end

    return count or 0
end

--endregion

--region time back
function XTheatre4EffectSubControl:TimeBack()
    if self:GetEffectTimeBackAvailable() then
        local times = self._MainControl.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.TimeBack)
        if times > 0 then
            self._MainControl:TimeBackRequest()
        end
    end
end

function XTheatre4EffectSubControl:HasEnoughTimeBackData()
    -- 如果服务端没有可回溯的事件数据
    local curMapId = self._MainControl.MapSubControl:GetCurrentMapId()
    local adventureData = self._Model:GetAdventureData()
    local chapterData = adventureData:GetChapterData(curMapId)
    if chapterData then
        local timeBackDays = chapterData:GetMaxTracebackDays()
        if timeBackDays == 0 then
            XLog.Warning("XTheatre4EffectSubControl:TimeBack 服务端可回溯的天数为0")
        end
        local day = adventureData:GetDays() - timeBackDays
        local timeBackData = adventureData:GetTracebackDataByDays(day)
        if timeBackData then
            return true
        end
    end
    return false
end

function XTheatre4EffectSubControl:GetTracebackDatas()
    return self._Model:GetAdventureData():GetTracebackDatas()
end

function XTheatre4EffectSubControl:GetTimeBackDescList()
    local list = {}
    for i = 1, 99 do
        local clientConfig = self._Model:GetClientConfigParams("TimeBackTips" .. i)
        if clientConfig then
            list[i] = clientConfig
        else
            break
        end
    end
    return list
end

--endregion

return XTheatre4EffectSubControl
