---@class XEquipControl : XControl
---@field _Model XEquipControl
local XEquipControl = XClass(XControl, "XEquipControl")
function XEquipControl:OnInit()
    --初始化内部变量
end

function XEquipControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XEquipControl:RemoveAgencyEvent()

end

function XEquipControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

-- 获取装备实例
---@param equipId number 装备Id
function XEquipControl:GetEquip(equipId)
    return self._Model:GetEquip(equipId)
end

-- 获取所有装备的XEquip对象实例
function XEquipControl:GetEquipDic()
    return self._Model:GetEquipDic()
end

--- 获取装备的配置表Id
---@param equipId number 装备Id
function XEquipControl:GetEquipTemplateId(equipId)
    local equip = self:GetEquip(equipId)
    return equip.TemplateId
end

--- 获取成员对应部位的装备Id
---@param characterId number 成员Id
---@param site number 装备部位
function XEquipControl:GetCharacterEquipId(characterId, site)
    return self._Model:GetCharacterEquipId(characterId, site)
end

--- 获取成员身上的所有装备Id列表
---@param characterId number 成员Id
---@param isUseTempList table 是否使用复用的临时列表
function XEquipControl:GetCharacterEquipIds(characterId, isUseTempList)
    return self._Model:GetCharacterEquipIds(characterId, isUseTempList)
end

--- 获取成员身上的所有装备实例
---@param characterId number 成员Id
---@param isUseTempList table 是否使用复用的临时列表
function XEquipControl:GetCharacterEquips(characterId, isUseTempList)
    return self._Model:GetCharacterEquips(characterId, isUseTempList)
end

--- 获取成员的武器Id
---@param characterId number 成员Id
function XEquipControl:GetCharacterWeaponId(characterId)
    return self._Model:GetCharacterWeaponId(characterId)
end

--- 获取成员的意识Id列表
---@param characterId number 成员Id
---@param isUseTempList table 是否使用复用的临时列表
function XEquipControl:GetCharacterAwarenessIds(characterId, isUseTempList)
    return self._Model:GetCharacterAwarenessIds(characterId, isUseTempList)
end

-- 装备是否适配角色类型
function XEquipControl:IsFitCharacterType(equipTemplateId, charType)
    local fitCharType = XMVCA:GetAgency(ModuleId.XEquip):GetEquipCharacterType(equipTemplateId)
    return fitCharType == XEnumConst.EQUIP.USER_TYPE.ALL or fitCharType == charType
end

-- 获取角色身上穿戴的意识
function XEquipControl:GetCharacterWearingAwarenesss(characterId)
    local equips = {}
    local equipDic = self._Model:GetEquipDic()
    for _, equip in pairs(equipDic) do
        if characterId > 0 and equip.CharacterId == characterId and equip:IsAwareness() then
            table.insert(equips, equip)
        end
    end

    return equips
end

--------------------region 升级、突破 --------------------
--- 获取装备突破次数对应图片
function XEquipControl:GetEquipBreakThroughIcon(breakthroughTimes)
    return self._Model:GetEquipBreakThroughIcon(breakthroughTimes)
end

-- 检测是否满足强化条件
function XEquipControl:CheckBreakthroughCondition(templateId, targetBreakthrough)
    local conditionId = self:GetBreakthroughConditionId(templateId, targetBreakthrough)
    if conditionId and conditionId ~= 0 then
        return XConditionManager.CheckCondition(conditionId)
    end

    return true, ""
end
--------------------endregion 升级、突破 --------------------

--------------------region 共鸣 --------------------
-- 通过配置表Id判断能否共鸣
function XEquipControl:CanResonanceByTemplateId(templateId)
    local count = 0

    local equipResonanceCfg = self._Model:GetConfigEquipResonance(templateId)
    if not equipResonanceCfg then
        return count
    end

    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        if equipResonanceCfg.WeaponSkillPoolId and equipResonanceCfg.WeaponSkillPoolId[pos] and equipResonanceCfg.WeaponSkillPoolId[pos] > 0 then
            count = count + 1
        elseif equipResonanceCfg.AttribPoolId and equipResonanceCfg.AttribPoolId[pos] and equipResonanceCfg.AttribPoolId[pos] > 0 then
            count = count + 1
        elseif equipResonanceCfg.CharacterSkillPoolId and equipResonanceCfg.CharacterSkillPoolId[pos] and equipResonanceCfg.CharacterSkillPoolId[pos] > 0 then
            count = count + 1
        end
    end

    return count
end

-- 获取装备共鸣预览技能
function XEquipControl:GetResonancePreviewSkillInfoList(equipId, characterId, slot)
    local skillInfoList = {}
    local XSkillInfoObj = require("XEntity/XEquip/XSkillInfoObj")
    local equip = self._Model:GetEquip(equipId)
    local resonanceCfg = self._Model:GetConfigEquipResonance(equip.TemplateId)

    if characterId then
        if equip:IsWeapon() then
            local poolId = resonanceCfg.WeaponSkillPoolId[slot]
            local skillIds = self._Model:GetWeaponSkillPoolSkillIds(poolId, characterId)
            for _, skillId in ipairs(skillIds) do
                local skillInfo = XSkillInfoObj.New(XEnumConst.EQUIP.RESONANCE_TYPE.WEAPON_SKILL, skillId)
                table.insert(skillInfoList, skillInfo)
            end
        else
            local skillPoolId = resonanceCfg.CharacterSkillPoolId[slot]
            local skillInfos = XMVCA.XCharacter:GetCharacterSkillPoolSkillInfos(skillPoolId, characterId)
            for _, v in ipairs(skillInfos) do
                local skillInfo = XSkillInfoObj.New(XEnumConst.EQUIP.RESONANCE_TYPE.CHARACTER_SKILL, v.SkillId)
                table.insert(skillInfoList, skillInfo)
            end
        end
    end

    -- 属性技能
    local attrPoolId = resonanceCfg.AttribPoolId[slot]
    if attrPoolId then
        local attrInfos = XAttribConfigs.GetAttribGroupTemplateByPoolId(attrPoolId)
        local attribIdDic = {} -- 过滤重复AttribId，五星武器的共鸣技能
        for _, v in ipairs(attrInfos) do
            if not attribIdDic[v.AttribId] then
                local skillInfo = XSkillInfoObj.New(XEnumConst.EQUIP.RESONANCE_TYPE.ATTRIB, v.Id)
                table.insert(skillInfoList, skillInfo)
                attribIdDic[v.AttribId] = true
            end
        end
    end

    return skillInfoList
end

-- 获取装备可以共鸣的角色列表
function XEquipControl:GetCanResonanceCharacterList(equipId)
    local canResonanceCharacterList = {}

    local equip = self._Model:GetEquip(equipId)
    local equipType = XMVCA:GetAgency(ModuleId.XEquip):GetEquipType(equip.TemplateId)
    local characterType = XMVCA:GetAgency(ModuleId.XEquip):GetEquipCharacterType(equip.TemplateId)
    local ownCharacterList = XMVCA:GetAgency(ModuleId.XCharacter):GetOwnCharacterList(characterType)
    for _, character in pairs(ownCharacterList) do
        if character.Id == equip.CharacterId then
            table.insert(canResonanceCharacterList, 1, character)
        else
            local characterEquipType = XMVCA.XCharacter:GetCharacterEquipType(character.Id)
            if equipType == XEnumConst.EQUIP.EQUIP_TYPE.UNIVERSAL or equipType == characterEquipType then
                table.insert(canResonanceCharacterList, character)
            end
        end
    end

    return canResonanceCharacterList
end

--- 获取武器共鸣可以消耗的装备列表
---@param equipId number 装备Id
function XEquipControl:GetWeaponResonanceCanEatEquipIds(equipId)
    --武器消耗同星级
    local equip = self:GetEquip(equipId)
    local star = equip:GetStar()

    local equipIds = {}
    local equipDic = self:GetEquipDic()
    for _, tEquip in pairs(equipDic) do
        if tEquip.Id ~= equipId and star == tEquip:GetStar() and tEquip:IsWeapon() and not tEquip:IsWearing() and not tEquip.IsLock then
            table.insert(equipIds, tEquip.Id)
        end
    end

    --加个默认排序
    XMVCA.XEquip:SortEquipIdListByPriorType(equipIds)
    return equipIds
end

--- 获取意识共鸣可以消耗的装备列表
---@param equipId number 装备Id
function XEquipControl:GetAwarenessResonanceCanEatEquipIds(equipId)
    --意识消耗同套装
    local equip = self:GetEquip(equipId)
    local suitId = equip:GetSuitId()

    local equipIds = {}
    local equipDic = self:GetEquipDic()
    for _, tEquip in pairs(equipDic) do
        if tEquip.Id ~= equipId and suitId == tEquip:GetSuitId() and tEquip:IsAwareness() and not tEquip:IsWearing() and not tEquip.IsLock
        and not self._Model:IsInSuitPrefab(tEquip.Id) then
            table.insert(equipIds, tEquip.Id)
        end
    end

    --加个默认排序
    XMVCA.XEquip:SortEquipIdListByPriorType(equipIds)
    return equipIds
end

--- 共鸣道具是否显示在代币页签
function XEquipControl:IsResonanceItemShowInTokenTab(itemId)
    return self._Model:IsResonanceItemShowInTokenTab(itemId)
end

--- 共鸣是否显示代币
--- @param templateId number 装备配置表Id
function XEquipControl:IsResonanceShowToken(templateId)
    local config = self:GetEquipResonanceUseItem(templateId)
    for _, itemId in ipairs(config.ItemId) do
        local inTokenTab = self:IsResonanceItemShowInTokenTab(itemId)
        if inTokenTab then
            return true
        end
    end
    for _, itemId in ipairs(config.SelectSkillItemId) do
        local inTokenTab = self:IsResonanceItemShowInTokenTab(itemId)
        if inTokenTab then
            return true
        end
    end
    return false
end

--- 获取共鸣代币列表
--- @param templateId number 装备配置表Id
function XEquipControl:GetResonanceTokenInfoList(templateId)
    local tokenInfoList = {}
    local config = self:GetEquipResonanceUseItem(templateId)
    for i, itemId in ipairs(config.ItemId) do
        local inTokenTab = self:IsResonanceItemShowInTokenTab(itemId)
        if inTokenTab then
            local discount, discountCount = self:CheckAndGetDiscountItemCount(templateId, itemId)
            local fixedCount = discount and discountCount or config.ItemCount[i]
            table.insert(tokenInfoList, { TemplateId = itemId, CostCnt = fixedCount})
        end
    end
    for i, itemId in ipairs(config.SelectSkillItemId) do
        local inTokenTab = self:IsResonanceItemShowInTokenTab(itemId)
        if inTokenTab then
            local discount, discountCount = self:CheckAndGetDiscountItemCount(templateId, itemId)
            local fixedCount = discount and discountCount or config.SelectSkillItemCount[i]
            table.insert(tokenInfoList, { TemplateId = itemId, CostCnt = fixedCount })
        end
    end
    return tokenInfoList
end

--- 获取共鸣代币列表
--- @param templateId number 装备配置表Id
function XEquipControl:GetResonanceTokenInfoDic(templateId)
    local tokenInfoDic = {}
    local config = self:GetEquipResonanceUseItem(templateId)
    for i, itemId in ipairs(config.ItemId) do
        local inTokenTab = self:IsResonanceItemShowInTokenTab(itemId)
        if inTokenTab then
            local discount, discountCount = self:CheckAndGetDiscountItemCount(templateId, itemId)
            local fixedCount = discount and discountCount or config.ItemCount[i]
            tokenInfoDic[itemId] = { TemplateId = itemId, CostCnt = fixedCount }
        end
    end
    for i, itemId in ipairs(config.SelectSkillItemId) do
        local inTokenTab = self:IsResonanceItemShowInTokenTab(itemId)
        if inTokenTab then
            local discount, discountCount = self:CheckAndGetDiscountItemCount(templateId, itemId)
            local fixedCount = discount and discountCount or config.SelectSkillItemCount[i]
            tokenInfoDic[itemId] = { TemplateId = itemId, CostCnt = fixedCount }
        end
    end
    return tokenInfoDic
end

--- 检查当前装备共鸣代币是否使用打折数目
function XEquipControl:CheckAndGetDiscountItemCount(templateId, itemId)
    local equipCfg = self._Model:GetConfigEquip(templateId)
    if XTool.IsTableEmpty(equipCfg) then
        return false
    end
    local suitId = equipCfg.SuitId
    local discountSuitIds = self._Model:GetEquipConfigValuesByKey('ChipResonanceUseItemDiscountSuitId')
    local discountItemIds = self._Model:GetEquipConfigValuesByKey('ChipResonanceUseItemDiscountItemId')
    local discountItemCounts = self._Model:GetEquipConfigValuesByKey('ChipResonanceUseItemDiscountItemCount')
    for i, sId in ipairs(discountSuitIds) do
        if suitId == sId and itemId == discountItemIds[i] then
            return true, discountItemCounts[i]
        end
    end
    return false
end

function XEquipControl:GetResonanceSkillInfo(equipId, pos)
    return self._Model:GetResonanceSkillInfo(equipId, pos)
end

--------------------endregion 共鸣 --------------------

--------------------region 超频 --------------------
function XEquipControl:IsEquipCanAwake(templateId)
    local star = self:GetEquipStar(templateId)
    local minAwakeStar = self._Model:GetMinAwakeStar()
    return star >= minAwakeStar
end
--------------------endregion 超频 --------------------

--------------------region 超限 --------------------
-- 获取武器对应所有超限配置
function XEquipControl:GetWeaponOverrunCfgsByTemplateId(templateId)
    return self._Model:GetWeaponOverrunCfgsByTemplateId(templateId)
end

-- 通过配置表Id判断能否超限
function XEquipControl:CanOverrunByTemplateId(templateId)
    return self._Model:CanOverrunByTemplateId(templateId)
end

--- 获取武器等级对应的UI显示
function XEquipControl:GetConfigWeaponDeregulateUI(lv)
    return self._Model:GetConfigWeaponDeregulateUI(lv)
end
--------------------endregion 超限 --------------------


--------------------region 意识 --------------------
--- 获取意识列表
---@param suitId number 指定套装Id
function XEquipControl:GetAwarenessList(characterId, site, suitId)
    local awarenessList = {}
    local agency = XMVCA:GetAgency(ModuleId.XEquip)
    local charType = XMVCA.XCharacter:GetCharacterType(characterId)
    local equipDic = self._Model:GetEquipDic()
    for _, equip in pairs(equipDic) do
        -- 筛选非狗粮、意识类型、适配角色类型、适配套装id
        if agency:GetEquipType(equip.TemplateId) ~= XEnumConst.EQUIP.EQUIP_TYPE.FOOD 
        and equip:IsAwareness(site) 
        and self:IsFitCharacterType(equip.TemplateId, charType) 
        and (suitId == 0 or suitId == self._Model:GetEquipSuitId(equip.TemplateId)) then
            table.insert(awarenessList, equip)
        end
    end

    -- 套装排序优先级
    local priorityDic = {}
    local suitPriorityCfg = self:GetConfigCharacterSuitPriority(characterId)
    if suitPriorityCfg then
        for index, suitType in ipairs(suitPriorityCfg.PriorityType) do
            priorityDic[suitType] = math.maxinteger - index
        end
    end

    -- 排序
    table.sort(awarenessList, function(a, b)
        -- 穿戴在当前角色身上的意识优先
        local isCurCharA = a.CharacterId == characterId
        local isCurCharB = b.CharacterId == characterId
        if isCurCharA ~= isCurCharB then
            return isCurCharA
        end

        -- 无角色穿戴优先
        local isNotWearingA = not a:IsWearing()
        local isNotWearingB = not b:IsWearing()
        if isNotWearingA ~= isNotWearingB then
            return isNotWearingA
        end

        -- 有任一共鸣技能与当前角色绑定优先
        local isBindCurCharA = a:IsResonanceBindCharacter(characterId)
        local isBindCurCharB = b:IsResonanceBindCharacter(characterId)
        if isBindCurCharA ~= isBindCurCharB then
            return isBindCurCharA
        end

        -- 未共鸣过优先
        local isNotResonanceA = not a:IsResonance()
        local isNotResonanceB = not b:IsResonance()
        if isNotResonanceA ~= isNotResonanceB then
            return isNotResonanceA
        end

        -- 意识等级高的优先
        if a.Level ~= b.Level then
            return a.Level > b.Level
        end

        local suitIdA = self._Model:GetEquipSuitId(a.TemplateId)
        local suitIdB = self._Model:GetEquipSuitId(b.TemplateId)
        -- 专属套装优先
        if suitPriorityCfg and suitPriorityCfg.ExclusiveSuitId ~= 0 then
            local isExclusiveA = suitPriorityCfg.ExclusiveSuitId == suitIdA
            local isExclusiveB = suitPriorityCfg.ExclusiveSuitId == suitIdB
            if isExclusiveA ~= isExclusiveB then
                return isExclusiveA
            end
        end

        -- 根据意识套装优先级排序
        local suitTypeA = agency:GetEquipSuitSuitType(suitIdA)
        local suitTypeB = agency:GetEquipSuitSuitType(suitIdB)
        local priorityA = priorityDic[suitTypeA] or 100000
        local priorityB = priorityDic[suitTypeB] or 100000
        if priorityA ~= priorityB then
            return priorityA > priorityB
        end

        -- 按照意识套装ID从大到小排序
        return suitIdA > suitIdB
    end)
    return awarenessList
end

-- 获取意识套装列表，筛选适配角色 and 统计已有套装数量
function XEquipControl:GetSuitInfoList(characterId, site)
    local suitInfoDic = {}
    local suitInfoList = {}
    local agency = XMVCA:GetAgency(ModuleId.XEquip)
    local charType = XMVCA.XCharacter:GetCharacterType(characterId)
    local equipDic = self._Model:GetEquipDic()
    for _, equip in pairs(equipDic) do
        -- 筛选意识类型、适配角色类型
        if equip:IsAwareness(site) and self:IsFitCharacterType(equip.TemplateId, charType) then
            -- 筛选suitType不为0
            local suitId = self._Model:GetEquipSuitId(equip.TemplateId)
            local suitType = agency:GetEquipSuitSuitType(suitId)
            if suitType ~= 0 then
                local suitInfo = suitInfoDic[suitId]
                if not suitInfo then
                    suitInfo = { SuitId = suitId, Count = 0}
                    suitInfoDic[suitId] = suitInfo
                    table.insert(suitInfoList, suitInfo)
                end
                suitInfo.Count = suitInfo.Count + 1
            end
        end
    end

    return suitInfoList
end

-- 获取套装最大数量
function XEquipControl:GetSuitMaxCnt(suitId)
    local suitCfg = self._Model:GetConfigEquipSuit(suitId)
    local maxCnt = 0
    for i, des in pairs(suitCfg.SkillDescription) do
        if des and i > maxCnt then
            maxCnt = i
        end
    end
    return maxCnt
end

--------------------endregion 意识 --------------------

-- 获取装备匹配角色
function XEquipControl:GetEquipMatchRole(templateId)
    local equipCfg = self._Model:GetConfigEquip(templateId)
    local charCfgs = XMVCA.XCharacter:GetCharacterTemplates()
    local charInfoList = {}
    for _, charCfg in pairs(charCfgs) do
        if charCfg.EquipType == equipCfg.Type then
            local isRecommend = charCfg.Id == equipCfg.RecommendCharacterId
            local charInfo = { Id = charCfg.Id, Name = charCfg.LogName, IsRecommend = isRecommend }
            table.insert(charInfoList, charInfo)
        end
    end

    return charInfoList
end

--------------------------------------------------------------------config start---------------------------------------

---------------------------------------- #region Equip ----------------------------------------
--- 获取装备名称
--- @param templateId number 装备配置表Id
function XEquipControl:GetEquipName(templateId)
    return self._Model:GetEquipName(templateId)
end

--- 获取装备部位
--- @param templateId number 装备配置表Id
function XEquipControl:GetEquipSite(templateId)
    return self._Model:GetEquipSite(templateId)
end

--- 获取装备星级
--- @param templateId number 装备配置表Id
function XEquipControl:GetEquipStar(templateId)
    return self._Model:GetEquipStar(templateId)
end

--- 装备是否是武器
--- @param templateId number 装备配置表Id
function XEquipControl:IsEquipWeapon(templateId)
    return self._Model:IsEquipWeapon(templateId)
end

--- 装备是否是意识
--- @param templateId number 装备配置表Id
--- @param site number 装备部位Id
function XEquipControl:IsEquipAwareness(templateId, site)
    return self._Model:IsEquipAwareness(templateId, site)
end
---------------------------------------- #endregion Equip ----------------------------------------


---------------------------------------- #region EquipBreakThrough ----------------------------------------
-- 获取装备的最大突破次数
function XEquipControl:GetEquipMaxBreakthrough(templateId)
    return self._Model:GetEquipMaxBreakthrough(templateId)
end

--获取指定突破次数下最大等级限制
function XEquipControl:GetBreakthroughLevelLimit(templateId, times)
    return self._Model:GetEquipBreakthroughLevelLimit(templateId, times)
end

--检查指定突破次数下的突破条件
function XEquipControl:GetBreakthroughConditionId(templateId, breakthrough)
    local cfgs = self._Model:GetEquipBreakthroughCfgs(templateId)
    for _, config in pairs(cfgs) do
        if config.Times == breakthrough - 1 then
            return config.ConditionId
        end
    end

    return
end

--- 升级单位转换为突破次数，等级
function XEquipControl:ConvertToBreakThroughAndLevel(templateId, levelUnit)
    return self._Model:ConvertToBreakThroughAndLevel(templateId, levelUnit)
end

--- 突破次数，等级转换为升级单位
function XEquipControl:ConvertToLevelUnit(templateId, breakthrough, level)
    return self._Model:ConvertToLevelUnit(templateId, breakthrough, level)
end

--- 获取装备最大升级单位（全突破）
function XEquipControl:GetEquipMaxLevelUnit(templateId)
    return self._Model:GetEquipMaxLevelUnit(templateId)
end

--- 获取装备当前升级单位（当前突破次数等级之和+当前等级）
function XEquipControl:GetEquipLevelUnit(equipId)
    return self._Model:GetEquipLevelUnit(equipId)
end

--获取装备从当前到目标突破次数总消耗道具
function XEquipControl:GetMutiBreakthroughConsumeItems(equipId, targetBreakthrough)
    return self._Model:GetMutiBreakthroughConsumeItems(equipId, targetBreakthrough)
end

--获取装备从当前到目标突破次数总消耗货币
function XEquipControl:GetMutiBreakthroughUseMoney(equipId, targetBreakthrough)
    return self._Model:GetMutiBreakthroughUseMoney(equipId, targetBreakthrough)
end
---------------------------------------- #endregion EquipBreakThrough ----------------------------------------

---------------------------------------- #region EquipSuit ----------------------------------------
function XEquipControl:GetConfigEquipSuit(suitId)
    return self._Model:GetConfigEquipSuit(suitId)
end

--- 获取意识套装列表
--- @param isFilterType0 boolean 是否筛选类型为0的套装，即不包括意识强化素材
--- @param isOverrun boolean 是否筛选超限套装
function XEquipControl:GetSuitIdsByCharacterType(charType, minQuality, isFilterType0, isOverrun)
    return self._Model:GetSuitIdsByCharacterType(charType, minQuality, isFilterType0, isOverrun)
end

--- 获取套装星级
function XEquipControl:GetSuitStar(suitId)
    return self._Model:GetSuitStar(suitId)
end

function XEquipControl:GetSuitQualityIcon(suitId)
    return self._Model:GetSuitQualityIcon(suitId)
end

--- 获取意识套装的品质
function XEquipControl:GetSuitQuality(suitId)
    return self._Model:GetSuitQuality(suitId)
end
---------------------------------------- #endregion Equip ----------------------------------------


--------------------region EquipSuitEffect --------------------
function XEquipControl:GetEquipSuitEffectBornMagic(id)
    return self._Model:GetConfigEquipSuitEffect(id).BornMagic
end

function XEquipControl:GetEquipSuitEffectSkillId(id)
    return self._Model:GetConfigEquipSuitEffect(id).SkillId
end

function XEquipControl:GetEquipSuitEffectAbility(id)
    return self._Model:GetConfigEquipSuitEffect(id).Ability
end
--------------------endregion EquipSuitEffect --------------------


--------------------region EquipResonance --------------------
function XEquipControl:GetEquipResonanceAttribPoolId(id)
    return self._Model:GetConfigEquipResonance(id).AttribPoolId
end

function XEquipControl:GetEquipResonanceAttribPoolWeight(id)
    return self._Model:GetConfigEquipResonance(id).AttribPoolWeight
end

function XEquipControl:GetEquipResonanceCharacterSkillPoolId(id)
    return self._Model:GetConfigEquipResonance(id).CharacterSkillPoolId
end

function XEquipControl:GetEquipResonanceCharacterSkillPoolWeight(id)
    return self._Model:GetConfigEquipResonance(id).CharacterSkillPoolWeight
end

function XEquipControl:GetEquipResonanceWeaponSkillPoolId(id)
    return self._Model:GetConfigEquipResonance(id).WeaponSkillPoolId
end

function XEquipControl:GetEquipResonanceWeaponSkillPoolWeight(id)
    return self._Model:GetConfigEquipResonance(id).WeaponSkillPoolWeight
end
--------------------endregion EquipResonance --------------------

--------------------region EquipResonanceUseItem --------------------
function XEquipControl:GetEquipResonanceUseItem(id)
    return self._Model:GetConfigEquipResonanceUseItem(id)
end
--------------------endregion EquipResonanceUseItem --------------------

--------------------region WeaponSkill --------------------
function XEquipControl:GetWeaponSkillBornMagic(id)
    return self._Model:GetConfigWeaponSkill(id).BornMagic
end

function XEquipControl:GetWeaponSkillSubSkillId(id)
    return self._Model:GetConfigWeaponSkill(id).SubSkillId
end

function XEquipControl:GetWeaponSkillAbility(id)
    return self._Model:GetConfigWeaponSkill(id).Ability
end

function XEquipControl:GetWeaponSkillIcon(id)
    return self._Model:GetConfigWeaponSkill(id).Icon
end

function XEquipControl:GetWeaponSkillName(id)
    return self._Model:GetConfigWeaponSkill(id).Name
end

function XEquipControl:GetWeaponSkillDescription(id)
    return self._Model:GetConfigWeaponSkill(id).Description
end

function XEquipControl:GetWeaponSkillDesLinkCharacterSkillId(id)
    return self._Model:GetConfigWeaponSkill(id).DesLinkCharacterSkillId
end

function XEquipControl:GetWeaponSkillAccount(id)
    return self._Model:GetConfigWeaponSkill(id).Account
end
--------------------endregion WeaponSkill --------------------

--------------------region WeaponSkillPool --------------------
function XEquipControl:GetWeaponSkillPoolPoolId(id)
    return self._Model:GetConfigWeaponSkillPool(id).PoolId
end

function XEquipControl:GetWeaponSkillPoolWeight(id)
    return self._Model:GetConfigWeaponSkillPool(id).Weight
end

function XEquipControl:GetWeaponSkillPoolCharacterId(id)
    return self._Model:GetConfigWeaponSkillPool(id).CharacterId
end

function XEquipControl:GetWeaponSkillPoolSkillId(id)
    return self._Model:GetConfigWeaponSkillPool(id).SkillId
end
--------------------endregion WeaponSkillPool --------------------

--------------------region EquipAwake --------------------

function XEquipControl:GetEquipAwakeAwarenessAttrDesc(id)
    return self._Model:GetConfigEquipAwake(id).AwarenessAttrDesc
end

function XEquipControl:GetEquipAwakeAwarenessAttrValue(id)
    return self._Model:GetConfigEquipAwake(id).AwarenessAttrValue
end

function XEquipControl:GetAwakeConsumeCrystalCoin(equipId, awakeCnt)
    return self._Model:GetAwakeConsumeCrystalCoin(equipId, awakeCnt)
end

function XEquipControl:GetAwakeConsumeItemCrystalList(equipId, awakeCnt)
    return self._Model:GetAwakeConsumeItemCrystalList(equipId, awakeCnt)
end
--------------------endregion EquipAwake --------------------


--------------------region CharacterSuitPriority --------------------
function XEquipControl:GetConfigCharacterSuitPriority(id)
    return self._Model:GetConfigCharacterSuitPriority(id)
end
--------------------endregion CharacterSuitPriority --------------------


--------------------region EquipRes --------------------
function XEquipControl:GetEquipResBigIconPath(id)
    return self._Model:GetConfigEquipRes(id).BigIconPath
end

function XEquipControl:GetEquipResIconPath(id)
    return self._Model:GetConfigEquipRes(id).IconPath
end

function XEquipControl:GetEquipResLiHuiPath(id)
    return self._Model:GetConfigEquipRes(id).LiHuiPath
end

function XEquipControl:GetEquipResModelTransId(id)
    return self._Model:GetConfigEquipRes(id).ModelTransId
end

function XEquipControl:GetEquipResResonanceModelTransId1(id)
    return self._Model:GetConfigEquipRes(id).ResonanceModelTransId1
end

function XEquipControl:GetEquipResResonanceModelTransId2(id)
    return self._Model:GetConfigEquipRes(id).ResonanceModelTransId2
end

function XEquipControl:GetEquipResResonanceModelTransId3(id)
    return self._Model:GetConfigEquipRes(id).ResonanceModelTransId3
end

function XEquipControl:GetEquipResPainterName(id)
    return self._Model:GetConfigEquipRes(id).PainterName
end
--------------------endregion EquipRes --------------------

--------------------region EquipModel --------------------
function XEquipControl:GetEquipModelModelName(id)
    return self._Model:GetConfigEquipModel(id).ModelName
end

function XEquipControl:GetEquipModelAnimController(id)
    return self._Model:GetConfigEquipModel(id).AnimController
end

function XEquipControl:GetEquipModelUiAnimStateName(id)
    return self._Model:GetConfigEquipModel(id).UiAnimStateName
end

function XEquipControl:GetEquipModelUiAnimCueId(id)
    return self._Model:GetConfigEquipModel(id).UiAnimCueId
end

function XEquipControl:GetEquipModelUiAnimDelay(id)
    return self._Model:GetConfigEquipModel(id).UiAnimDelay
end

function XEquipControl:GetEquipModelUiAutoRotateDelay(id)
    return self._Model:GetConfigEquipModel(id).UiAutoRotateDelay
end
--------------------endregion EquipModel --------------------

--------------------region EquipModelTransform --------------------
function XEquipControl:GetEquipModelTransformIndexId(id)
    return self._Model:GetConfigEquipModelTransform(id).IndexId
end

function XEquipControl:GetEquipModelTransformUiName(id)
    return self._Model:GetConfigEquipModelTransform(id).UiName
end

function XEquipControl:GetEquipModelTransformPositionX(id)
    return self._Model:GetConfigEquipModelTransform(id).PositionX
end

function XEquipControl:GetEquipModelTransformPositionY(id)
    return self._Model:GetConfigEquipModelTransform(id).PositionY
end

function XEquipControl:GetEquipModelTransformPositionZ(id)
    return self._Model:GetConfigEquipModelTransform(id).PositionZ
end

function XEquipControl:GetEquipModelTransformRotationX(id)
    return self._Model:GetConfigEquipModelTransform(id).RotationX
end

function XEquipControl:GetEquipModelTransformRotationY(id)
    return self._Model:GetConfigEquipModelTransform(id).RotationY
end

function XEquipControl:GetEquipModelTransformRotationZ(id)
    return self._Model:GetConfigEquipModelTransform(id).RotationZ
end

function XEquipControl:GetEquipModelTransformScaleX(id)
    return self._Model:GetConfigEquipModelTransform(id).ScaleX
end

function XEquipControl:GetEquipModelTransformScaleY(id)
    return self._Model:GetConfigEquipModelTransform(id).ScaleY
end

function XEquipControl:GetEquipModelTransformScaleZ(id)
    return self._Model:GetConfigEquipModelTransform(id).ScaleZ
end
--------------------endregion EquipModelTransform --------------------

--------------------region EquipSkipId --------------------
function XEquipControl:GetEquipEatSkipIds(eatType, site)
    return self._Model:GetEquipEatSkipIds(eatType, site)
end
--------------------endregion EquipSkipId --------------------

--------------------region EquipAnim --------------------
function XEquipControl:GetEquipAnimParams(id)
    return self._Model:GetConfigEquipAnim(id).Params
end
--------------------endregion EquipAnim --------------------

--------------------region EquipModelShow --------------------
function XEquipControl:GetEquipModelShowModelId(id)
    return self._Model:GetConfigEquipModelShow(id).ModelId
end

function XEquipControl:GetEquipModelShowUiName(id)
    return self._Model:GetConfigEquipModelShow(id).UiName
end

function XEquipControl:GetEquipModelShowHideNodeName(id)
    return self._Model:GetConfigEquipModelShow(id).HideNodeName
end
--------------------endregion EquipModelShow --------------------

--------------------region EquipResByFool --------------------
function XEquipControl:GetEquipResByFoolModelTransId(id)
    return self._Model:GetConfigEquipResByFool(id).ModelTransId
end

function XEquipControl:GetEquipResByFoolResonanceModelTransId1(id)
    return self._Model:GetConfigEquipResByFool(id).ResonanceModelTransId1
end

function XEquipControl:GetEquipResByFoolResonanceModelTransId2(id)
    return self._Model:GetConfigEquipResByFool(id).ResonanceModelTransId2
end

function XEquipControl:GetEquipResByFoolResonanceModelTransId3(id)
    return self._Model:GetConfigEquipResByFool(id).ResonanceModelTransId3
end
--------------------endregion EquipResByFool --------------------

--------------------region WeaponDeregulateUI --------------------
function XEquipControl:GetWeaponDeregulateUIName(id)
    return self._Model:GetConfigWeaponDeregulateUI(id).Name
end

function XEquipControl:GetWeaponDeregulateUILvUpTips(id)
    return self._Model:GetConfigWeaponDeregulateUI(id).LvUpTips
end

function XEquipControl:GetWeaponDeregulateUIIconQuality(id)
    return self._Model:GetConfigWeaponDeregulateUI(id).IconQuality
end

function XEquipControl:GetWeaponDeregulateUIItemsQuality(id)
    return self._Model:GetConfigWeaponDeregulateUI(id).ItemsQuality
end

function XEquipControl:GetWeaponDeregulateUIUIEffect(id)
    return self._Model:GetConfigWeaponDeregulateUI(id).UIEffect
end

function XEquipControl:GetWeaponDeregulateUILvUPAnimation(id)
    return self._Model:GetConfigWeaponDeregulateUI(id).LvUPAnimation
end

function XEquipControl:GetWeaponDeregulateUISceneStartEffectPath(id)
    return self._Model:GetConfigWeaponDeregulateUI(id).SceneStartEffectPath
end

function XEquipControl:GetWeaponDeregulateUISceneStartEffectTime(id)
    return self._Model:GetConfigWeaponDeregulateUI(id).SceneStartEffectTime
end

function XEquipControl:GetWeaponDeregulateUISceneLoopEffectPath(id)
    return self._Model:GetConfigWeaponDeregulateUI(id).SceneLoopEffectPath
end

--------------------endregion WeaponDeregulateUI --------------------

function XEquipControl:GetLevelUpCfg(templateId, times, level)
    return self._Model:GetLevelUpCfg(templateId, times, level)
end

----------config end----------

return XEquipControl