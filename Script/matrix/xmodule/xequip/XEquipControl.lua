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

-- 装备是否适配角色类型
function XEquipControl:IsFitCharacterType(equipTemplateId, charType)
    local fitCharType = XMVCA:GetAgency(ModuleId.XEquip):GetEquipCharacterType(equipTemplateId)
    return fitCharType == XEnumConst.EQUIP.USER_TYPE.ALL or fitCharType == charType
end

--------------------region 升级、突破 --------------------
function XEquipControl:GetEquipBreakThroughIcon(breakthroughTimes)
    local key = "EquipBreakThrough" .. breakthroughTimes
    return CS.XGame.ClientConfig:GetString(key)
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
            local skillIds = XEquipConfig.GetWeaponSkillPoolSkillIds(poolId, characterId)
            for _, skillId in ipairs(skillIds) do
                local skillInfo = XSkillInfoObj.New(XEnumConst.EQUIP.RESONANCE_TYPE.WEAPON_SKILL, skillId)
                table.insert(skillInfoList, skillInfo)
            end
        else
            local skillPoolId = resonanceCfg.CharacterSkillPoolId[slot]
            local skillInfos = XCharacterConfigs.GetCharacterSkillPoolSkillInfos(skillPoolId, characterId)
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
--------------------endregion 共鸣 --------------------

--------------------region 超频 --------------------
function XEquipControl:IsEquipCanAwake(templateId)
    local star = XMVCA:GetAgency(ModuleId.XEquip):GetEquipStar(templateId)
    local minAwakeStar = XEquipConfig.GetMinAwakeStar()
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
    local cfgs = self._Model:GetWeaponOverrunCfgsByTemplateId(templateId)
    local canDeregulate = cfgs and #cfgs > 0
    return canDeregulate
end
--------------------endregion 超限 --------------------


--------------------region 意识 --------------------
-- 获取意识列表
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
        and (suitId == 0 or suitId == agency:GetEquipSuitId(equip.TemplateId)) then
            table.insert(awarenessList, equip)
        end
    end

    -- 排序
    local agency = XMVCA:GetAgency(ModuleId.XEquip)
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

        -- 星级高的优先
        local starA = agency:GetEquipStar(a.TemplateId)
        local starB = agency:GetEquipStar(b.TemplateId)
        if starA ~= starB then
            return starA > starB
        end

        -- suitId高的优先
        local suitIdA = agency:GetEquipSuitId(a.TemplateId)
        local suitIdB = agency:GetEquipSuitId(b.TemplateId)
        if suitIdA ~= suitIdB then
            return suitIdA > suitIdB
        end

        -- 最后按照Id从大到小
        return a.Id > b.Id
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
            local suitId = agency:GetEquipSuitId(equip.TemplateId)
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

--------------------region EquipBreakThrough --------------------
-- 获取装备的最大突破次数
function XEquipControl:GetEquipMaxBreakthrough(templateId)
    local cfgs = self._Model:GetEquipBreakthroughCfgs(templateId)
    if not cfgs then
        return 0
    end

    local times = 0
    for _, config in pairs(cfgs) do
        if config.Times > times then
            times = config.Times
        end
    end
    return times
end

--获取指定突破次数下最大等级限制
function XEquipControl:GetBreakthroughLevelLimit(templateId, times)
    local equipBreakthroughCfg = self._Model:GetEquipBreakthroughCfg(templateId, times)
    return equipBreakthroughCfg.LevelLimit
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
--------------------endregion EquipBreakThrough --------------------

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
--endregion EquipSuitEffect

--------------------region EquipDecompose --------------------
function XEquipControl:GetEquipDecomposeSite(id)
    return self._Model:GetConfigEquipDecompose(id).Site
end

function XEquipControl:GetEquipDecomposeStar(id)
    return self._Model:GetConfigEquipDecompose(id).Star
end

function XEquipControl:GetEquipDecomposeBreakthrough(id)
    return self._Model:GetConfigEquipDecompose(id).Breakthrough
end

function XEquipControl:GetEquipDecomposeExpToOneCoin(id)
    return self._Model:GetConfigEquipDecompose(id).ExpToOneCoin
end

function XEquipControl:GetEquipDecomposeExpToItemId(id)
    return self._Model:GetConfigEquipDecompose(id).ExpToItemId
end

function XEquipControl:GetEquipDecomposeRewardId(id)
    return self._Model:GetConfigEquipDecompose(id).RewardId
end
--------------------endregion EquipDecompose --------------------

--------------------region EatEquipCost --------------------
function XEquipControl:GetEatEquipCostSite(id)
    return self._Model:GetConfigEatEquipCost(id).Site
end

function XEquipControl:GetEatEquipCostStar(id)
    return self._Model:GetConfigEatEquipCost(id).Star
end

function XEquipControl:GetEatEquipCostUseMoney(id)
    return self._Model:GetConfigEatEquipCost(id).UseMoney
end
--------------------endregion EatEquipCost --------------------

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
function XEquipControl:GetEquipResonanceUseItemItemId(id)
    return self._Model:GetConfigEquipResonanceUseItem(id).ItemId
end

function XEquipControl:GetEquipResonanceUseItemItemCount(id)
    return self._Model:GetConfigEquipResonanceUseItem(id).ItemCount
end

function XEquipControl:GetEquipResonanceUseItemSelectSkillItemId(id)
    return self._Model:GetConfigEquipResonanceUseItem(id).SelectSkillItemId
end

function XEquipControl:GetEquipResonanceUseItemSelectSkillItemCount(id)
    return self._Model:GetConfigEquipResonanceUseItem(id).SelectSkillItemCount
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

function XEquipControl:GetEquipAwakeAttribId(id)
    return self._Model:GetConfigEquipAwake(id).AttribId
end

function XEquipControl:GetEquipAwakeAttribDes1(id)
    return self._Model:GetConfigEquipAwake(id).AttribDes1
end

function XEquipControl:GetEquipAwakeAttribDes2(id)
    return self._Model:GetConfigEquipAwake(id).AttribDes2
end

function XEquipControl:GetEquipAwakeItemId(id)
    return self._Model:GetConfigEquipAwake(id).ItemId
end

function XEquipControl:GetEquipAwakeItemCount(id)
    return self._Model:GetConfigEquipAwake(id).ItemCount
end

function XEquipControl:GetEquipAwakeItemCrystalId(id)
    return self._Model:GetConfigEquipAwake(id).ItemCrystalId
end

function XEquipControl:GetEquipAwakeItemCrystalCount(id)
    return self._Model:GetConfigEquipAwake(id).ItemCrystalCount
end

function XEquipControl:GetEquipAwakeAwarenessAttrDesc(id)
    return self._Model:GetConfigEquipAwake(id).AwarenessAttrDesc
end

function XEquipControl:GetEquipAwakeAwarenessAttrValue(id)
    return self._Model:GetConfigEquipAwake(id).AwarenessAttrValue
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

function XEquipControl:GetEquipModelResonanceEffectPath(id)
    return self._Model:GetConfigEquipModel(id).ResonanceEffectPath
end

function XEquipControl:GetEquipModelResonanceEffectShowDelay(id)
    return self._Model:GetConfigEquipModel(id).ResonanceEffectShowDelay
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
function XEquipControl:GetEquipSkipIdSite(id)
    return self._Model:GetConfigEquipSkipId(id).Site
end

function XEquipControl:GetEquipSkipIdEquipType(id)
    return self._Model:GetConfigEquipSkipId(id).EquipType
end

function XEquipControl:GetEquipSkipIdEatType(id)
    return self._Model:GetConfigEquipSkipId(id).EatType
end

function XEquipControl:GetEquipSkipIdSkipIdParams(id)
    return self._Model:GetConfigEquipSkipId(id).SkipIdParams
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