XEquipManagerCreator = function()
    local pairs = pairs
    local type = type
    local table = table
    local next = next
    local tableInsert = table.insert
    local tableRemove = table.remove
    local tableSort = table.sort
    local mathMin = math.min
    local mathFloor = math.floor
    local CSXTextManagerGetText = CS.XTextManager.GetText

    ---@class XEquipManager
    local XEquipManager = {}
    local Equips = {} -- 装备数据
    local WeaponTypeCheckDic = {}
    local AwarenessTypeCheckDic = {}
    local OverLimitTexts = {}
    local AwarenessSuitPrefabInfoList = {} --意识组合预设
    local AwakeItemTypeDic = {}

    local EQUIP_FIRST_GET_KEY = "EquipFirstGetTemplateIds"
    local EQUIP_DECOMPOSE_RETURN_RATE = CS.XGame.Config:GetInt("EquipDecomposeReturnRate") / 10000
    local EQUIP_SUIT_PREFAB_MAX_NUM = CS.XGame.Config:GetInt("EquipSuitPrefabMaxNum")
    local EQUIP_SUIT_CHARACTER_PREFAB_MAX_NUM = CS.XGame.Config:GetInt("EquipSuitCharacterPrefabMaxNum")

    local XEquip = require("XEntity/XEquip/XEquip")
    local XEquipSuitPrefab = require("XEntity/XEquip/XEquipSuitPrefab")
    local XSkillInfoObj = require("XEntity/XEquip/XSkillInfoObj")
    -----------------------------------------Privite Begin------------------------------------
    local function GetEquipTemplateId(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return equip.TemplateId
    end

    local function GetEquipCfg(equipId)
        local templateId = GetEquipTemplateId(equipId)
        return XEquipConfig.GetEquipCfg(templateId)
    end

    local function CheckEquipExist(equipId)
        return Equips[equipId]
    end

    local function GetEquipBorderCfg(equipId)
        local templateId = GetEquipTemplateId(equipId)
        return XEquipConfig.GetEquipBorderCfg(templateId)
    end

    local function GetSuitPresentEquipTemplateId(suitId)
        local templateIds = XEquipConfig.GetEquipTemplateIdsBySuitId(suitId)
        return templateIds and templateIds[1]
    end

    local function GetEquipBreakthroughCfg(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return XEquipConfig.GetEquipBreakthroughCfg(equip.TemplateId, equip.Breakthrough)
    end

    local function GetEquipBreakthroughCfgNext(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return XEquipConfig.GetEquipBreakthroughCfg(equip.TemplateId, equip.Breakthrough + 1)
    end

    local function InitEquipTypeCheckDic()
        WeaponTypeCheckDic[XEquipConfig.EquipSite.Weapon] = XEquipConfig.Classify.Weapon
        for _, site in pairs(XEquipConfig.EquipSite.Awareness) do
            AwarenessTypeCheckDic[site] = XEquipConfig.Classify.Awareness
        end
    end

    local function GetSuitPrefabInfoList()
        return AwarenessSuitPrefabInfoList
    end

    local function GetEquipAwakeCfg(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return XEquipConfig.GetEquipAwakeCfg(equip.TemplateId)
    end

    local function InitAwakeItemTypeDic()
        local equipAwakeCfgs = XEquipConfig.GetEquipAwakeCfgs()
        for _, equipAwakeCfg in pairs(equipAwakeCfgs) do
            local itemIds = equipAwakeCfg.ItemId
            if itemIds then
                for _, itemId in pairs(itemIds) do
                    local awakeItemType = AwakeItemTypeDic[itemId]
                    if not awakeItemType then
                        awakeItemType = {}
                        AwakeItemTypeDic[itemId] = awakeItemType
                    end
                    local equipCfg = XEquipConfig.GetEquipCfg(equipAwakeCfg.Id)
                    if not awakeItemType[equipCfg.SuitId] then
                        awakeItemType[equipCfg.SuitId] = equipCfg.SuitId
                    end
                end
            end
        end
    end

    InitEquipTypeCheckDic()
    InitAwakeItemTypeDic()
    -----------------------------------------Privite End------------------------------------
    function XEquipManager.InitEquipData(equipDic)
        Equips = equipDic
    end

    function XEquipManager.NotifyEquipChipGroupList(data)
        AwarenessSuitPrefabInfoList = {}
        local chipGroupDataList = data.ChipGroupDataList
        for _, chipGroupData in ipairs(chipGroupDataList) do
            tableInsert(AwarenessSuitPrefabInfoList, XEquipSuitPrefab.New(chipGroupData))
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
    end


    function XEquipManager.DeleteEquip(equipId)
        XMVCA:GetAgency(ModuleId.XEquip):DeleteEquip(equipId)
    end

    function XEquipManager.GetEquip(equipId)
        return XMVCA:GetAgency(ModuleId.XEquip):GetEquip(equipId)
    end

    -- 是否拥有这件装备
    function XEquipManager.IsOwnEquip(templateId)
        for _, equip in pairs(Equips) do
            if equip.TemplateId == templateId then
                return true
            end
        end
        return  false
    end
    
    --==============================
     ---@desc 通过templateId获取背包中或目标角色身上的装备
     ---@templateId 装备真实Id 
     ---@return table
    --==============================
    function XEquipManager.GetEnableEquipIdsByTemplateId(templateId, targetCharacterId)
        local equipIds = {}
        for id, equip in pairs(Equips) do
            if equip.TemplateId == templateId and
                    (equip.CharacterId <= 0 or equip.CharacterId == targetCharacterId) then
                table.insert(equipIds, id)
            end
        end
        return equipIds
    end
    
    --==============================
     ---@desc 目标装备是否可用（未被其他角色装备）
     ---@templateId 装备真实Id 
     ---@return boolean
    --==============================
    function XEquipManager.IsEquipActive(templateId, characterId)
        for id, equip in pairs(Equips) do
            if equip.TemplateId == templateId and
                    (equip.CharacterId <= 0 or equip.CharacterId == characterId) then
                return true
            end
        end
        return false
    end

    --desc: 获取所有武器equipId
    function XEquipManager.GetWeaponIds()
        local weaponIds = {}
        for k, v in pairs(Equips) do
            if XEquipManager.IsClassifyEqual(v.Id, XEquipConfig.Classify.Weapon) then
                tableInsert(weaponIds, k)
            end
        end
        return weaponIds
    end

    function XEquipManager.GetWeaponCount()
        local weaponIds = XEquipManager.GetWeaponIds()
        return weaponIds and #weaponIds or 0
    end

    function XEquipManager.GetAwarenessCount(characterType)
        local awarenessIds = XEquipManager.GetAwarenessIds(characterType)
        return awarenessIds and #awarenessIds or 0
    end

    function XEquipManager.GetSuitIdsByStars(starCheckList)
        local suitIds = {}

        local doNotRepeatSuitIds = {}
        local equipIds = XEquipManager.GetAwarenessIds()
        for _, equipId in pairs(equipIds) do
            local templateId = GetEquipTemplateId(equipId)
            local star = XEquipManager.GetEquipStar(templateId)

            if starCheckList[star] then
                local suitId = XEquipManager.GetSuitId(equipId)
                if suitId > 0 then
                    doNotRepeatSuitIds[suitId] = true
                end
            end
        end

        for suitId in pairs(doNotRepeatSuitIds) do
            tableInsert(suitIds, suitId)
        end

        --展示排序:构造体〉感染体〉通用
        local UserTypeSortPriority = {
            [XEquipConfig.UserType.All] = 1,
            [XEquipConfig.UserType.Isomer] = 2,
            [XEquipConfig.UserType.Normal] = 3
        }
        tableSort(
            suitIds,
            function(lSuitID, rSuitID)
                local lStar = XEquipManager.GetSuitStar(lSuitID)
                local rStar = XEquipManager.GetSuitStar(rSuitID)
                if lStar ~= rStar then
                    return lStar > rStar
                end

                local aCharacterType = XEquipManager.GetSuitCharacterType(lSuitID)
                local bCharacterType = XEquipManager.GetSuitCharacterType(rSuitID)
                if aCharacterType ~= bCharacterType then
                    return UserTypeSortPriority[aCharacterType] > UserTypeSortPriority[bCharacterType]
                end
            end
        )

        tableInsert(suitIds, 1, XEquipConfig.DEFAULT_SUIT_ID.Normal)
        tableInsert(suitIds, 2, XEquipConfig.DEFAULT_SUIT_ID.Isomer)

        return suitIds
    end

    function XEquipManager.GetDecomposeRewardEquipCount(equipId)
        local weaponCount, awarenessCount = 0, 0

        local rewards = XEquipManager.GetDecomposeRewards({equipId})
        for _, v in pairs(rewards) do
            if XArrangeConfigs.GetType(v.TemplateId) == XArrangeConfigs.Types.Weapon then
                weaponCount = weaponCount + v.Count
            elseif XArrangeConfigs.GetType(v.TemplateId) == XArrangeConfigs.Types.Wafer then
                awarenessCount = awarenessCount + v.Count
            end
        end

        return weaponCount, awarenessCount
    end

    function XEquipManager.GetDecomposeRewards(equipIds)
        local itemInfoList = {}

        local rewards = {}
        local coinId = XDataCenter.ItemManager.ItemId.Coin
        XTool.LoopCollection(
            equipIds,
            function(equipId)
                local equip = XEquipManager.GetEquip(equipId)
                local decomposeconfig = XEquipConfig.GetEquipDecomposeCfg(equip.TemplateId, equip.Breakthrough)
                local levelUpCfg = XEquipConfig.GetLevelUpCfg(equip.TemplateId, equip.Breakthrough, equip.Level)
                local equipBreakthroughCfg = GetEquipBreakthroughCfg(equipId)
                local exp = (equip.Exp + levelUpCfg.AllExp + equipBreakthroughCfg.Exp)

                local expToCoin = mathFloor(exp / decomposeconfig.ExpToOneCoin)
                if expToCoin > 0 then
                    local coinReward = rewards[coinId]
                    if coinReward then
                        coinReward.Count = coinReward.Count + expToCoin
                    else
                        rewards[coinId] = XRewardManager.CreateRewardGoods(coinId, expToCoin)
                    end
                end

                local ratedExp = exp * EQUIP_DECOMPOSE_RETURN_RATE
                local expToFoodId = decomposeconfig.ExpToItemId
                local singleExp = XDataCenter.ItemManager.GetItemsAddEquipExp(expToFoodId)
                local expToFoodCount = mathFloor(ratedExp / (singleExp))
                if expToFoodCount > 0 then
                    local foodReward = rewards[expToFoodId]
                    if foodReward then
                        foodReward.Count = foodReward.Count + expToFoodCount
                    else
                        rewards[expToFoodId] = XRewardManager.CreateRewardGoods(expToFoodId, expToFoodCount)
                    end
                end

                if decomposeconfig.RewardId > 0 then
                    local rewardList = XRewardManager.GetRewardList(decomposeconfig.RewardId)
                    for _, item in pairs(rewardList) do
                        if rewards[item.TemplateId] then
                            rewards[item.TemplateId].Count = rewards[item.TemplateId].Count + item.Count
                        else
                            rewards[item.TemplateId] = XRewardManager.CreateRewardGoodsByTemplate(item)
                        end
                    end
                end
            end
        )

        for _, reward in pairs(rewards) do
            tableInsert(itemInfoList, reward)
        end
        itemInfoList = XRewardManager.SortRewardGoodsList(itemInfoList)

        return itemInfoList
    end

    function XEquipManager.GetSuitPrefabNum()
        return #AwarenessSuitPrefabInfoList
    end

    function XEquipManager.GetSuitPrefabNumMax()
        return EQUIP_SUIT_PREFAB_MAX_NUM
    end

    function XEquipManager.GetEquipSuitCharacterPrefabMaxNum()
        return EQUIP_SUIT_CHARACTER_PREFAB_MAX_NUM
    end

    function XEquipManager.GetSuitPrefabIndexList(characterType)
        local prefabIndexList = {}

        for index, suitPrefab in pairs(AwarenessSuitPrefabInfoList) do
            if not characterType or suitPrefab:GetCharacterType() == characterType then
                tableInsert(prefabIndexList, index)
            end
        end

        return prefabIndexList
    end

    function XEquipManager.GetSuitPrefabInfo(index)
        return index and AwarenessSuitPrefabInfoList[index]
    end

    function XEquipManager.SaveSuitPrefabInfo(equipGroupData)
        tableInsert(AwarenessSuitPrefabInfoList, XEquipSuitPrefab.New(equipGroupData))
    end

    function XEquipManager.DeleteSuitPrefabInfo(index)
        if not index then
            return
        end
        tableRemove(AwarenessSuitPrefabInfoList, index)
    end

    function XEquipManager.GetUnSavedSuitPrefabInfo(characterId)
        local equipGroupData = {
            Name = "",
            ChipIdList = XEquipManager.GetCharacterWearingAwarenessIds(characterId)
        }
        return XEquipSuitPrefab.New(equipGroupData)
    end
    -----------------------------------------Function Begin------------------------------------
    local DefaultSort = function(a, b, exclude)
        if not exclude or exclude ~= XEquipConfig.PriorSortType.Star then
            local aStar = XEquipManager.GetEquipStar(a.TemplateId)
            local bStar = XEquipManager.GetEquipStar(b.TemplateId)
            if aStar ~= bStar then
                return aStar > bStar
            end
        end

        -- 是否超限
        local isOverrunA = a:IsOverrun() and 1 or 0
        local isOverrunB = b:IsOverrun() and 1 or 0
        if isOverrunA ~= isOverrunB then
            return isOverrunA > isOverrunB
        end

        if not exclude or exclude ~= XEquipConfig.PriorSortType.Breakthrough then
            if a.Breakthrough ~= b.Breakthrough then
                return a.Breakthrough > b.Breakthrough
            end
        end

        if not exclude or exclude ~= XEquipConfig.PriorSortType.Level then
            if a.Level ~= b.Level then
                return a.Level > b.Level
            end
        end

        if a.IsRecycle ~= b.IsRecycle then
            return a.IsRecycle == false
        end

        return XEquipManager.GetEquipPriority(a.TemplateId) > XEquipManager.GetEquipPriority(b.TemplateId)
    end

    function XEquipManager.SortEquipIdListByPriorType(equipIdList, priorSortType)
        local sortFunc

        if priorSortType == XEquipConfig.PriorSortType.Level then
            sortFunc = function(aId, bId)
                local a = XEquipManager.GetEquip(aId)
                local b = XEquipManager.GetEquip(bId)
                if a.Level ~= b.Level then
                    return a.Level > b.Level
                end
                return DefaultSort(a, b, priorSortType)
            end
        elseif priorSortType == XEquipConfig.PriorSortType.Breakthrough then
            sortFunc = function(aId, bId)
                local a = XEquipManager.GetEquip(aId)
                local b = XEquipManager.GetEquip(bId)
                if a.Breakthrough ~= b.Breakthrough then
                    return a.Breakthrough > b.Breakthrough
                end
                return DefaultSort(a, b, priorSortType)
            end
        elseif priorSortType == XEquipConfig.PriorSortType.Star then
            sortFunc = function(aId, bId)
                local a = XEquipManager.GetEquip(aId)
                local b = XEquipManager.GetEquip(bId)
                local aStar = XEquipManager.GetEquipStar(a.TemplateId)
                local bStar = XEquipManager.GetEquipStar(b.TemplateId)
                if aStar ~= bStar then
                    return aStar > bStar
                end
                return DefaultSort(a, b, priorSortType)
            end
        elseif priorSortType == XEquipConfig.PriorSortType.Proceed then
            sortFunc = function(aId, bId)
                local a = XEquipManager.GetEquip(aId)
                local b = XEquipManager.GetEquip(bId)
                if a.CreateTime ~= b.CreateTime then
                    return a.CreateTime < b.CreateTime
                end
                return DefaultSort(a, b, priorSortType)
            end
        else
            sortFunc = function(aId, bId)
                local a = XEquipManager.GetEquip(aId)
                local b = XEquipManager.GetEquip(bId)
                return DefaultSort(a, b)
            end
        end

        tableSort(
            equipIdList,
            function(aId, bId)
                --强制优先插入装备中排序
                local aWearing = XEquipManager.IsWearing(aId) and 1 or 0
                local bWearing = XEquipManager.IsWearing(bId) and 1 or 0
                if aWearing ~= bWearing then
                    return aWearing < bWearing
                end

                return sortFunc(aId, bId)
            end
        )
    end

    function XEquipManager.ConstructAwarenessStarToSiteToSuitIdsDic(characterType, IsGift)
        local starToSuitIdsDic = {}

        local doNotRepeatSuitIds = {}
        local equipIds = XEquipManager.GetAwarenessIds(characterType)
        for _, equipId in pairs(equipIds) do
            local templateId = GetEquipTemplateId(equipId)

            local star = XEquipManager.GetEquipStar(templateId)
            doNotRepeatSuitIds[star] = doNotRepeatSuitIds[star] or {}

            local site = XEquipManager.GetEquipSite(equipId)
            doNotRepeatSuitIds[star][site] = doNotRepeatSuitIds[star][site] or {}
            doNotRepeatSuitIds[star].Total = doNotRepeatSuitIds[star].Total or {}

            local suitId = XEquipManager.GetSuitId(equipId)
            if suitId > 0 then
                local IsCanBeGift = XEquipManager.IsCanBeGift(equipId)
                if not IsGift or IsCanBeGift then
                    doNotRepeatSuitIds[star][site][suitId] = true
                    doNotRepeatSuitIds[star]["Total"][suitId] = true
                end
            end
        end

        for star = 1, XEquipConfig.MAX_STAR_COUNT do
            starToSuitIdsDic[star] = {}

            for _, site in pairs(XEquipConfig.EquipSite.Awareness) do
                starToSuitIdsDic[star][site] = {}

                if doNotRepeatSuitIds[star] and doNotRepeatSuitIds[star][site] then
                    for suitId in pairs(doNotRepeatSuitIds[star][site]) do
                        tableInsert(starToSuitIdsDic[star][site], suitId)
                    end
                end
            end

            starToSuitIdsDic[star].Total = {}
            if doNotRepeatSuitIds[star] then
                for suitId in pairs(doNotRepeatSuitIds[star]["Total"]) do
                    tableInsert(starToSuitIdsDic[star]["Total"], suitId)
                end
            end
        end

        return starToSuitIdsDic
    end

    function XEquipManager.ConstructAwarenessSiteToEquipIdsDic(characterType, IsGift)
        local siteToEquipIdsDic = {}

        for _, site in pairs(XEquipConfig.EquipSite.Awareness) do
            siteToEquipIdsDic[site] = {}
        end

        local equipIds = XEquipManager.GetAwarenessIds(characterType)
        for _, equipId in pairs(equipIds) do
            local IsCanBeGift = XEquipManager.IsCanBeGift(equipId)
            if not IsGift or IsCanBeGift then
                local site = XEquipManager.GetEquipSite(equipId)
                tableInsert(siteToEquipIdsDic[site], equipId)
            end
        end

        return siteToEquipIdsDic
    end

    function XEquipManager.ConstructAwarenessSuitIdToEquipIdsDic(characterType, IsGift)
        local suitIdToEquipIdsDic = {}

        local equipIds = XEquipManager.GetAwarenessIds(characterType)
        for _, equipId in pairs(equipIds) do
            local suitId = XEquipManager.GetSuitId(equipId)
            suitIdToEquipIdsDic[suitId] = suitIdToEquipIdsDic[suitId] or {}

            if suitId > 0 then
                local site = XEquipManager.GetEquipSite(equipId)
                suitIdToEquipIdsDic[suitId]["Total"] = suitIdToEquipIdsDic[suitId]["Total"] or {}
                suitIdToEquipIdsDic[suitId][site] = suitIdToEquipIdsDic[suitId][site] or {}

                local IsCanBeGift = XEquipManager.IsCanBeGift(equipId)
                if not IsGift or IsCanBeGift then
                    tableInsert(suitIdToEquipIdsDic[suitId][site], equipId)
                    tableInsert(suitIdToEquipIdsDic[suitId]["Total"], equipId)
                end
            end
        end

        return suitIdToEquipIdsDic
    end

    function XEquipManager.ConstructAwarenessResonanceTypeToEquipIdsDic(characterId)
        local ResonanceType = {
            CurCharacter = 1, --当前角色共鸣
            Others = 2, --其他角色共鸣
            None = 3 --无共鸣
        }
        local resonanceTypeToEquipIdsDic = {
            [ResonanceType.CurCharacter] = {},
            [ResonanceType.Others] = {},
            [ResonanceType.None] = {}
        }

        local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
        local equipIds = XEquipManager.GetAwarenessIds(characterType)
        for _, equipId in pairs(equipIds) do
            local resonanceType = ResonanceType.None

            local isFive = XEquipManager.IsFiveStar(equipId)
            local equip = XEquipManager.GetEquip(equipId)

            local resonanceInfo = equip.ResonanceInfo
            if resonanceInfo then
                for _, data in pairs(resonanceInfo) do
                    --五星共鸣过的意识属于【当前角色共鸣】分类中
                    if isFive then
                        resonanceType = ResonanceType.CurCharacter
                        break
                    end

                    if data.CharacterId == characterId then
                        resonanceType = ResonanceType.CurCharacter
                        break
                    end

                    resonanceType = ResonanceType.Others
                end
            end

            tableInsert(resonanceTypeToEquipIdsDic[resonanceType], equipId)
        end

        return resonanceTypeToEquipIdsDic
    end

    function XEquipManager.TipEquipOperation(equipId, changeTxt, closeCb, setMask)
        local uiName = "UiEquipCanBreakthroughTip"
        if XLuaUiManager.IsUiShow(uiName) then
            XLuaUiManager.Remove(uiName)
        end
        XLuaUiManager.Open(uiName, equipId, changeTxt, closeCb, setMask)
    end
    -----------------------------------------Function End------------------------------------
    -----------------------------------------Protocol Begin------------------------------------
    function XEquipManager.SetLock(equipId, isLock)
        if not equipId then
            XLog.Error("XEquipManager.SetLock错误: 参数equipId不能为空")
            return
        end

        local req = {EquipId = equipId, IsLock = isLock}
        XNetwork.Call(
            "EquipUpdateLockRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local equip = XEquipManager.GetEquip(equipId)
                equip:SetLock(isLock)

                CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY, equipId, isLock)
                XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY, equipId, isLock)
            end
        )
    end

    function XEquipManager.AwarenessTransform(suitId, site, usedIdList, cb)
        if not suitId then
            XLog.Error("XEquipManager.SetLock错误: 参数suitId不能为空")
            return
        end

        local req = {SuitId = suitId, Site = site, UseIdList = usedIdList}
        XNetwork.Call(
            "EquipTransformChipRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                for _, id in pairs(usedIdList) do
                    XEquipManager.DeleteEquip(id)
                end

                if cb then
                    cb(res.EquipData)
                end
            end
        )
    end

    --characterId:专属组合角色Id，通用组合为0
    function XEquipManager.EquipSuitPrefabSave(suitPrefabInfo, characterId)
        if not suitPrefabInfo then
            return
        end

        local name = suitPrefabInfo:GetName()
        if not name or name == "" then
            XUiManager.TipText("EquipSuitPrefabSaveNotName")
            return
        end

        local chipIds = suitPrefabInfo:GetEquipIds()
        if not next(chipIds) then
            XUiManager.TipText("EquipSuitPrefabSaveNotEquipIds")
            return
        end

        local req = {
            Name = name,
            ChipIds = chipIds,
            CharacterId = characterId
        }
        XNetwork.Call(
            "EquipAddChipGroupRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                XEquipManager.SaveSuitPrefabInfo(res.ChipGroupData)
                XUiManager.TipText("EquipSuitPrefabSaveSuc")
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
            end
        )
    end

    function XEquipManager.EquipSuitPrefabDelete(prefabIndex)
        local suitPrefabInfo = XEquipManager.GetSuitPrefabInfo(prefabIndex)
        if not suitPrefabInfo then
            return
        end

        local req = {GroupId = suitPrefabInfo:GetGroupId()}
        XNetwork.Call(
            "EquipDeleteChipGroupRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                XEquipManager.DeleteSuitPrefabInfo(prefabIndex)
                XUiManager.TipText("EquipSuitPrefabDeleteSuc")
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
            end
        )
    end

    function XEquipManager.EquipSuitPrefabRename(prefabIndex, newName)
        local suitPrefabInfo = XEquipManager.GetSuitPrefabInfo(prefabIndex)
        if not suitPrefabInfo then
            return
        end

        local equipGroupData = {
            GroupId = suitPrefabInfo:GetGroupId(),
            Name = newName,
            ChipIdList = suitPrefabInfo:GetEquipIds(),
            CharacterId = suitPrefabInfo:GetCharacterId()
        }
        local req = {GroupData = equipGroupData}

        XNetwork.Call(
            "EquipUpdateChipGroupRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                suitPrefabInfo:UpdateData(equipGroupData)
                XUiManager.TipText("EquipSuitPrefabRenameSuc")
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
            end
        )
    end
    -----------------------------------------Protocol End------------------------------------
    -----------------------------------------Checker Begin-----------------------------------
    function XEquipManager.CheckMaxCount(equipType, count)
        if equipType == XEquipConfig.Classify.Weapon then
            local maxWeaponCount = XEquipConfig.GetMaxWeaponCount()
            if count and count > 0 then
                return XEquipManager.GetWeaponCount() + count > maxWeaponCount
            else
                return XEquipManager.GetWeaponCount() >= maxWeaponCount
            end
        elseif equipType == XEquipConfig.Classify.Awareness then
            local maxAwarenessCount = XEquipConfig.GetMaxAwarenessCount()
            if count and count > 0 then
                return XEquipManager.GetAwarenessCount() + count > maxAwarenessCount
            else
                return XEquipManager.GetAwarenessCount() >= maxAwarenessCount
            end
        end
    end

    function XEquipManager.CheckBagCount(count, equipType)
        if XEquipManager.CheckMaxCount(equipType, count) then
            local messageTips
            if equipType == XEquipConfig.Classify.Weapon then
                messageTips = CSXTextManagerGetText("WeaponBagFull")
            elseif equipType == XEquipConfig.Classify.Awareness then
                messageTips = CSXTextManagerGetText("ChipBagFull")
            end

            XUiManager.TipMsg(messageTips, XUiManager.UiTipType.Tip)
            return false
        end

        return true
    end

    function XEquipManager.IsWeapon(equipId)
        return XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Weapon)
    end

    function XEquipManager.IsWeaponByTemplateId(templateId)
        return XEquipManager.IsClassifyEqualByTemplateId(templateId, XEquipConfig.Classify.Weapon)
    end

    function XEquipManager.IsAwareness(equipId)
        return XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Awareness)
    end

    function XEquipManager.IsAwarenessByTemplateId(templateId)
        return XEquipManager.IsClassifyEqualByTemplateId(templateId, XEquipConfig.Classify.Awareness)
    end

    function XEquipManager.IsFood(equipId)
        local equipCfg = GetEquipCfg(equipId)
        return equipCfg.Type == XEquipConfig.EquipType.Food
    end

    function XEquipManager.IsClassifyEqual(equipId, classify)
        local templateId = GetEquipTemplateId(equipId)
        return XEquipManager.IsClassifyEqualByTemplateId(templateId, classify)
    end

    function XEquipManager.IsCharacterTypeFit(equipId, characterType)
        local templateId = GetEquipTemplateId(equipId)
        return XEquipManager.IsCharacterTypeFitByTemplateId(templateId, characterType)
    end

    function XEquipManager.IsCharacterTypeFitByTemplateId(templateId, characterType)
        local configCharacterType = XEquipConfig.GetEquipCharacterType(templateId)
        return configCharacterType == XEquipConfig.UserType.All or configCharacterType == characterType
    end

    function XEquipManager.IsClassifyEqualByTemplateId(templateId, classify)
        local equipClassify = XEquipManager.GetEquipClassifyByTemplateId(templateId)
        return classify and equipClassify and classify == equipClassify
    end

    function XEquipManager.IsTypeEqual(equipId, equipType)
        local equipCfg = GetEquipCfg(equipId)
        return equipCfg.Type == XEquipConfig.EquipType.Universal or equipType and equipType == equipCfg.Type
    end

    function XEquipManager.IsWearing(equipId)
        if not equipId then
            return false
        end
        local equip = XEquipManager.GetEquip(equipId)
        return equip and equip.CharacterId and equip.CharacterId > 0
    end

    function XEquipManager.IsInSuitPrefab(equipId)
        if not equipId then
            return false
        end
        local suitPrefabList = GetSuitPrefabInfoList()
        for _, suitPrefabInfo in pairs(suitPrefabList) do
            if suitPrefabInfo:IsEquipIn(equipId) then
                return true
            end
        end
        return false
    end

    function XEquipManager.IsLock(equipId)
        if not equipId then
            return false
        end
        local equip = XEquipManager.GetEquip(equipId)
        return equip and equip.IsLock
    end

    function XEquipManager.GetEquipLevel(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return equip.Level
    end

    function XEquipManager.IsMaxLevel(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return equip.Level >= XEquipManager.GetBreakthroughLevelLimit(equipId)
    end

    function XEquipManager.IsMaxLevelByTemplateId(templateId, breakThrough, level)
        return level >= XEquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, breakThrough)
    end

    function XEquipManager.IsMaxBreakthrough(equipId)
        if not CheckEquipExist(equipId) then return false end
        local equip = XEquipManager.GetEquip(equipId)
        local equipBorderCfg = GetEquipBorderCfg(equipId)
        return equip.Breakthrough >= equipBorderCfg.MaxBreakthrough
    end

    function XEquipManager.IsMaxLevelAndBreakthrough(equipId)
        if not CheckEquipExist(equipId) then return false end
        return XEquipManager.IsMaxBreakthrough(equipId) and XEquipManager.IsReachBreakthroughLevel(equipId)
    end

    function XEquipManager.IsReachBreakthroughLevel(equipId)
        if not CheckEquipExist(equipId) then return false end
        local equip = XEquipManager.GetEquip(equipId)
        return equip.Level >= XEquipManager.GetBreakthroughLevelLimit(equipId)
    end

    function XEquipManager.IsCanBeGift(equipId) --是否能作为师徒系统的礼物
        local IsNotWearing = not XEquipManager.IsWearing(equipId)
        local IsNotInSuit = not XEquipManager.IsInSuitPrefab(equipId)
        local IsUnLock = not XEquipManager.IsLock(equipId)
        local templateId = GetEquipTemplateId(equipId)
        local IsCanGive = not XMentorSystemConfigs.IsCanNotGiveWafer(templateId)
        local equip = XEquipManager.GetEquip(equipId)
        local resonanCecount = XEquipManager.GetResonanceCount(equipId)
        local breakthrough = equip and equip.Breakthrough or 0
        local level = equip and equip.Level or 1

        return IsNotWearing and IsNotInSuit and IsUnLock and IsCanGive and resonanCecount == 0 and level == 1 and
            breakthrough == 0
    end

    function XEquipManager.CanBreakThrough(equipId)
        return not XEquipManager.IsMaxBreakthrough(equipId) and XEquipManager.IsReachBreakthroughLevel(equipId)
    end

    function XEquipManager.CanBreakThroughByEquipData(equip)
        local equipBorderCfg = XEquipConfig.GetEquipBorderCfg(equip.TemplateId)
        local isMaxBreakthrough = equip.Breakthrough >= equipBorderCfg.MaxBreakthrough
        local isReachBreakthroughLevel = equip.Level >= XEquipManager.GetBreakthroughLevelLimitByEquipData(equip)
        return not isMaxBreakthrough and isReachBreakthroughLevel
    end

    function XEquipManager.CanBreakThroughByTemplateId(templateId, breakThrough, level)
        local equipBorderCfg = XEquipConfig.GetEquipBorderCfg(templateId)
        local isMaxBreakthrough = breakThrough >= equipBorderCfg.MaxBreakthrough
        local isReachBreakthroughLevel =
            level >= XEquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, breakThrough)
        return not isMaxBreakthrough and isReachBreakthroughLevel
    end

    function XEquipManager.IsFiveStar(equipId)
        local templateId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
        local quality = XDataCenter.EquipManager.GetEquipQuality(templateId)
        return quality == XEquipConfig.MIN_RESONANCE_EQUIP_STAR_COUNT
    end

    function XEquipManager.CanResonance(equipId)
        local templateId = GetEquipTemplateId(equipId)
        local star = XEquipManager.GetEquipStar(templateId)
        return star >= XEquipConfig.MIN_RESONANCE_EQUIP_STAR_COUNT
    end

    function XEquipManager.CanResonanceByTemplateId(templateId)
        local resonanceSkillNum = XEquipManager.GetResonanceSkillNumByTemplateId(templateId)
        return resonanceSkillNum > 0
    end

    function XEquipManager.CanResonanceBindCharacter(equipId)
        local templateId = GetEquipTemplateId(equipId)
        local star = XEquipManager.GetEquipStar(templateId)
        return star >= XEquipConfig.GetMinResonanceBindStar()
    end

    function XEquipManager.CheckResonanceConsumeItemEnough(equipId)
        local itemIds = {}
        local consumeItemId = XEquipManager.GetResonanceConsumeItemId(equipId)
        local haveCount = XDataCenter.ItemManager.GetCount(consumeItemId)
        local consumeCount = XEquipManager.GetResonanceConsumeItemCount(equipId)

        local consumeSelectSkillItemId = XEquipManager.GetResonanceConsumeSelectSkillItemId(equipId)
        local haveSelectCount = XDataCenter.ItemManager.GetCount(consumeSelectSkillItemId)
        local consumeSelectSkillItemCount = XEquipManager.GetResonanceConsumeSelectSkillItemCount(equipId)

        local isEnough = false
        if consumeItemId and haveCount >= consumeCount then
            table.insert(itemIds, consumeItemId)
            isEnough = true
        end

        if consumeSelectSkillItemId and haveSelectCount >= consumeSelectSkillItemCount then
            table.insert(itemIds, consumeSelectSkillItemId)
            isEnough = true
        end

        return isEnough, itemIds
    end

    function XEquipManager.CheckEquipPosResonanced(equipId, pos)
        local equip = XEquipManager.GetEquip(equipId)
        return equip.ResonanceInfo and equip.ResonanceInfo[pos]
    end

    --装备是否共鸣过
    function XEquipManager.IsEquipResonanced(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return equip and not XTool.IsTableEmpty(equip.ResonanceInfo) or
            not XTool.IsTableEmpty(equip.UnconfirmedResonanceInfo)
    end

    function XEquipManager.CheckEquipStarCanAwake(equipId)
        local templateId = GetEquipTemplateId(equipId)
        local star = XEquipManager.GetEquipStar(templateId)
        if star < XEquipConfig.GetMinAwakeStar() then
            return false
        end
        return true
    end

    function XEquipManager.CheckEquipCanAwake(equipId, pos)
        if not XEquipManager.CheckEquipStarCanAwake(equipId) then
            return false
        end

        local templateId = GetEquipTemplateId(equipId)
        local maxLevel = XEquipManager.GetEquipMaxLevel(templateId)
        local equip = XEquipManager.GetEquip(equipId)
        if equip.Level ~= maxLevel then
            return false
        end

        if not XDataCenter.EquipManager.CheckEquipPosResonanced(equipId, pos) then
            return false
        end

        return true
    end

    function XEquipManager.IsEquipAwaken(equipId)
        for pos = 1, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
            if XEquipManager.IsEquipPosAwaken(equipId, pos) then
                return true
            end
        end
        return false
    end

    function XEquipManager.GetEquipAwakeNum(equipId)
        local num = 0
        for pos = 1, XEquipConfig.MAX_AWAKE_COUNT  do
            if XEquipManager.IsEquipPosAwaken(equipId, pos) then
                num = num + 1
            end
        end
        return num
    end

    function XEquipManager.IsEquipPosAwaken(equipId, pos)
        local equip = XEquipManager.GetEquip(equipId)
        return equip:IsEquipPosAwaken(pos)
    end

    -- 根据意识id 获得对应的公约加成描述字符串
    function XEquipManager.GetEquipAwarenessOccupyHarmDesc(equipId, forceNum)
        local str = ""
        if XTool.IsNumberValid(equipId) then
            local curr = 0
            for i = 1, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
                local awaken = XEquipManager.IsEquipPosAwaken(equipId, i)
                if awaken then
                    curr = curr + 1
                end
            end
            
            local equipData = XEquipManager.GetEquip(equipId)
            if curr > 0 then
                local awakeCfg = XEquipConfig.GetEquipAwakeCfg(equipData.TemplateId)
                str = awakeCfg.AwarenessAttrDesc..((forceNum or curr) * awakeCfg.AwarenessAttrValue).."%"
            end
        end
        return str
    end

    function XEquipManager.CheckEquipPosUnconfirmedResonanced(equipId, pos)
        local equip = XEquipManager.GetEquip(equipId)
        return equip.UnconfirmedResonanceInfo and equip.UnconfirmedResonanceInfo[pos]
    end

    function XEquipManager.CheckFirstGet(templateId)
        local needFirstShow = XEquipConfig.GetNeedFirstShow(templateId)
        if not needFirstShow or needFirstShow == 0 then
            return false
        end

        local firstGetTemplateIds = XSaveTool.GetData(XPlayer.Id .. EQUIP_FIRST_GET_KEY) or {}
        if firstGetTemplateIds[templateId] then
            return false
        else
            firstGetTemplateIds[templateId] = true
            XSaveTool.SaveData(XPlayer.Id .. EQUIP_FIRST_GET_KEY, firstGetTemplateIds)
            return true
        end
    end

    --狗粮
    function XEquipManager.IsEquipRecomendedToBeEat(strengthenEquipId, equipId, doNotLimitStar)
        if not equipId then
            return false
        end
        local equip = XEquipManager.GetEquip(equipId)
        local equipClassify = XEquipManager.GetEquipClassify(strengthenEquipId)
        local canNotAutoEatStar = not doNotLimitStar and XEquipConfig.CAN_NOT_AUTO_EAT_STAR

        if
            XEquipManager.GetEquipClassify(equipId) == equipClassify and --武器吃武器，意识吃意识
                not XEquipManager.IsWearing(equipId) and --不能吃穿戴中
                not XEquipManager.IsInSuitPrefab(equipId) and --不能吃预设中
                not XEquipManager.IsLock(equipId) and --不能吃上锁中
                (not canNotAutoEatStar or XEquipManager.GetEquipStar(equip.TemplateId) < canNotAutoEatStar) and --不自动吃大于该星级的装备
                equip.Breakthrough == 0 and --不吃突破过的
                equip.Level == 1 and
                equip.Exp == 0 and --不吃强化过的
                not equip.ResonanceInfo and
                not equip.UnconfirmedResonanceInfo
         then --不吃共鸣过的
            return true
        end

        return false
    end

    --强化默认使用装备条件，不满足则使用道具
    function XEquipManager.IsStrengthenDefaultUseEquip(StrenthenEquipId)
        local equipIdList = XDataCenter.EquipManager.GetCanEatEquipIds(StrenthenEquipId)
        for _, equipId in pairs(equipIdList) do
            if XEquipManager.IsEquipRecomendedToBeEat(StrenthenEquipId, equipId) then
                return true
            end
        end

        local itemIdList = XDataCenter.EquipManager.GetCanEatItemIds(StrenthenEquipId)
        if next(itemIdList) then
            return false
        end

        return true
    end
    -----------------------------------------Checker End------------------------------------
    -----------------------------------------Getter Begin------------------------------------
    local function ConstructEquipAttrMap(attrs, isIncludeZero, remainDigitTwo)
        local equipAttrMap = {}

        for _, attrIndex in ipairs(XEquipConfig.AttrSortType) do
            local value = attrs and attrs[attrIndex]

            --默认保留两位小数
            if not remainDigitTwo then
                value = value and FixToInt(value)
            else
                value = value and tonumber(string.format("%0.2f", FixToDouble(value)))
            end

            if isIncludeZero or value and value > 0 then
                tableInsert(
                    equipAttrMap,
                    {
                        AttrIndex = attrIndex,
                        Name = XAttribManager.GetAttribNameByIndex(attrIndex),
                        Value = value or 0
                    }
                )
            end
        end

        return equipAttrMap
    end

    function XEquipManager.GetEquipAttrMap(equipId, preLevel)
        return XMVCA:GetAgency(ModuleId.XEquip):GetEquipAttrMap(equipId, nil, preLevel)
    end

    function XEquipManager.GetEquipAttrMapByEquipData(equip)
        local attrMap = {}
        if not equip then
            return attrMap
        end
        local attrs = XFightEquipManager.GetEquipAttribs(equip)
        attrMap = ConstructEquipAttrMap(attrs)

        return attrMap
    end

    function XEquipManager.GetTemplateEquipAttrMap(templateId, preLevel)
        local equipData = {
            TemplateId = templateId,
            Breakthrough = 0,
            Level = 1
        }
        local attrs = XFightEquipManager.GetEquipAttribs(equipData, nil, preLevel)
        return ConstructEquipAttrMap(attrs)
    end

    --构造装备属性字典
    function XEquipManager.ConstructTemplateEquipAttrMap(templateId, breakthroughTimes, level)
        local equipData = {
            TemplateId = templateId,
            Breakthrough = breakthroughTimes,
            Level = level
        }
        local attrs = XFightEquipManager.GetEquipAttribs(equipData)
        return ConstructEquipAttrMap(attrs)
    end

    --构造装备提升属性字典
    function XEquipManager.ConstructTemplateEquipPromotedAttrMap(templateId, breakthroughTimes)
        local equipBreakthroughCfg = XEquipConfig.GetEquipBreakthroughCfg(templateId, breakthroughTimes)
        local map = XAttribManager.GetPromotedAttribs(equipBreakthroughCfg.AttribPromotedId)
        return ConstructEquipAttrMap(map, false, true)
    end

    function XEquipManager.GetWearingAwarenessMergeAttrMap(characterId)
        local wearingAwarenessIds = XEquipManager.GetCharacterWearingAwarenessIds(characterId)
        return XEquipManager.GetAwarenessMergeAttrMap(wearingAwarenessIds)
    end

    function XEquipManager.GetAwarenessMergeAttrMap(equipIds)
        local equipList = {}
        for _, equipId in pairs(equipIds) do
            tableInsert(equipList, XEquipManager.GetEquip(equipId))
        end
        local attrs = XFightEquipManager.GetEquipListAttribs(equipList)
        return ConstructEquipAttrMap(attrs, true)
    end

    function XEquipManager.GetBreakthroughPromotedAttrMap(equipId, preBreakthrough)
        local equipBreakthroughCfg

        if preBreakthrough then
            equipBreakthroughCfg = GetEquipBreakthroughCfgNext(equipId)
        else
            equipBreakthroughCfg = GetEquipBreakthroughCfg(equipId)
        end

        local map = XAttribManager.GetPromotedAttribs(equipBreakthroughCfg.AttribPromotedId)
        return ConstructEquipAttrMap(map, false, true)
    end

    function XEquipManager.GetCharacterWearingEquips(characterId)
        local equips = {}

        for _, equip in pairs(Equips) do
            if characterId > 0 and equip.CharacterId == characterId then
                tableInsert(equips, equip)
            end
        end

        return equips
    end

    function XEquipManager.GetCharacterWearingWeaponId(characterId)
        for _, equip in pairs(Equips) do
            if
                equip.CharacterId == characterId and XEquipManager.IsWearing(equip.Id) and
                    XEquipManager.IsClassifyEqual(equip.Id, XEquipConfig.Classify.Weapon)
             then
                return equip.Id
            end
        end
    end

    function XEquipManager.GetCharacterWearingWeapon(characterId)
        for _, equip in pairs(Equips) do
            if
                equip.CharacterId == characterId and XEquipManager.IsWearing(equip.Id) and
                    XEquipManager.IsClassifyEqual(equip.Id, XEquipConfig.Classify.Weapon)
             then
                return equip
            end
        end
    end

    function XEquipManager.GetWearingEquipIdBySite(characterId, site)
        for _, equip in pairs(Equips) do
            if equip.CharacterId == characterId and XEquipManager.GetEquipSite(equip.Id) == site then
                return equip.Id
            end
        end
    end

    function XEquipManager.GetWearingEquipBySite(characterId, site)
        for _, equip in pairs(Equips) do
            if equip.CharacterId == characterId and XEquipManager.GetEquipSite(equip.Id) == site then
                return equip
            end
        end
    end

    function XEquipManager.GetCharacterWearingAwarenessIds(characterId)
        local awarenessIds = {}
        local equips = XEquipManager.GetCharacterWearingEquips(characterId)
        for _, equip in pairs(equips) do
            if XEquipManager.IsClassifyEqual(equip.Id, XEquipConfig.Classify.Awareness) then
                tableInsert(awarenessIds, equip.Id)
            end
        end
        return awarenessIds
    end

    function XEquipManager.GetCharacterWearingAwarenessIdCount(characterId)
        local awarenessIds = XEquipManager.GetCharacterWearingAwarenessIds(characterId)
        return #awarenessIds
    end

    --desc: 获取符合当前角色使用类型的所有武器equipId
    function XEquipManager.GetCanUseWeaponIds(characterId)
        local weaponIds = {}
        local requireEquipType = XMVCA.XCharacter:GetCharacterEquipType(characterId)
        for k, v in pairs(Equips) do
            if
                XEquipManager.IsClassifyEqual(v.Id, XEquipConfig.Classify.Weapon) and
                    XEquipManager.IsTypeEqual(v.Id, requireEquipType)
             then
                tableInsert(weaponIds, k)
            end
        end
        return weaponIds
    end

    --desc: 获取符合当前角色使用类型的所有武器templateId
    function XEquipManager.GetCanUseWeaponTemplateIds(characterId)
        local weaponTemplateIds = {}
        local requireEquipType = XMVCA.XCharacter:GetCharacterEquipType(characterId)
        local equipTemplates = XEquipConfig.GetEquipTemplates()
        for _, v in pairs(equipTemplates) do
            if
                XEquipManager.IsClassifyEqualByTemplateId(v.Id, XEquipConfig.Classify.Weapon) and
                    v.Type == requireEquipType
             then
                tableInsert(weaponTemplateIds, v.Id)
            end
        end
        return weaponTemplateIds
    end

    --desc: 获取符合当前武器使用角色的所有templateId
    function XEquipManager.GetWeaponUserTemplateIds(weaponTemplateIds)
        local characters = XMVCA.XCharacter:GetCharacterTemplates()
        local canUesCharacters = {}
        for _, character in pairs(characters) do
            local weaponIds = XEquipManager.GetCanUseWeaponTemplateIds(character.Id)
            for _, weaponId in pairs(weaponIds) do
                if weaponTemplateIds == weaponId then
                    tableInsert(canUesCharacters, character)
                end
            end
        end
        return canUesCharacters
    end

    --desc: 获取所有意识
    function XEquipManager.GetAwarenessIds(characterType)
        local awarenessIds = {}
        for k, v in pairs(Equips) do
            local equipId = v.Id
            if
                XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Awareness) and
                    (not characterType or XEquipManager.IsCharacterTypeFit(equipId, characterType))
             then
                tableInsert(awarenessIds, k)
            end
        end
        return awarenessIds
    end

    local CanEatEquipSort = function(lEquipId, rEquipId)
        local ltemplateId = GetEquipTemplateId(lEquipId)
        local rtemplateId = GetEquipTemplateId(rEquipId)
        local lEquip = XEquipManager.GetEquip(lEquipId)
        local rEquip = XEquipManager.GetEquip(rEquipId)

        local lStar = XEquipManager.GetEquipStar(ltemplateId)
        local rStar = XEquipManager.GetEquipStar(rtemplateId)
        if lStar ~= rStar then
            return lStar < rStar
        end

        local lIsFood = XEquipManager.IsFood(lEquipId)
        local rIsFood = XEquipManager.IsFood(rEquipId)
        if lIsFood ~= rIsFood then
            return lIsFood
        end

        if lEquip.Breakthrough ~= rEquip.Breakthrough then
            return lEquip.Breakthrough < rEquip.Breakthrough
        end

        if lEquip.Level ~= rEquip.Level then
            return lEquip.Level < rEquip.Level
        end

        return XEquipManager.GetEquipPriority(ltemplateId) < XEquipManager.GetEquipPriority(rtemplateId)
    end

    local function GetCanEatWeaponIds(equipId)
        local weaponIds = {}
        for k, v in pairs(Equips) do
            if
                v.Id ~= equipId and XEquipManager.IsClassifyEqual(v.Id, XEquipConfig.Classify.Weapon) and
                    not XEquipManager.IsWearing(v.Id) and
                    not XEquipManager.IsLock(v.Id)
             then
                tableInsert(weaponIds, k)
            end
        end
        tableSort(weaponIds, CanEatEquipSort)
        return weaponIds
    end

    local function GetCanEatAwarenessIds(equipId)
        local awarenessIds = {}
        for k, v in pairs(Equips) do
            if
                v.Id ~= equipId and XEquipManager.IsClassifyEqual(v.Id, XEquipConfig.Classify.Awareness) and
                    not XEquipManager.IsWearing(v.Id) and
                    not XEquipManager.IsInSuitPrefab(v.Id) and
                    not XEquipManager.IsLock(v.Id)
             then
                tableInsert(awarenessIds, k)
            end
        end
        tableSort(awarenessIds, CanEatEquipSort)
        return awarenessIds
    end

    function XEquipManager.GetCanEatEquipIds(equipId)
        local equipIds = {}
        if XEquipManager.IsAwareness(equipId) then
            equipIds = GetCanEatAwarenessIds(equipId)
        elseif XEquipManager.IsWeapon(equipId) then
            equipIds = GetCanEatWeaponIds(equipId)
        end
        return equipIds
    end

    function XEquipManager.GetCanEatItemIds(equipId)
        local itemIds = {}

        local equipClassify = XEquipManager.GetEquipClassify(equipId)
        local items = XDataCenter.ItemManager.GetEquipExpItems(equipClassify)
        for _, item in pairs(items) do
            tableInsert(itemIds, item.Id)
        end

        return itemIds
    end

    function XEquipManager.GetRecomendEatEquipIds(equipId, requireStarDic, ignoreSort, doNotLimitStar)
        local equipIds = {}

        --根据星级筛选一遍
        local CheckStar = function(equipId)
            if not requireStarDic then
                return true
            end
            local equip = XEquipManager.GetEquip(equipId)
            return requireStarDic[XEquipManager.GetEquipStar(equip.TemplateId)] and true or false
        end

        for _, v in pairs(Equips) do
            local tmpEquipId = v.Id
            if
                tmpEquipId ~= equipId and XEquipManager.IsEquipRecomendedToBeEat(equipId, tmpEquipId, doNotLimitStar) and
                    CheckStar(tmpEquipId)
             then
                tableInsert(equipIds, tmpEquipId)
            end
        end

        --排序
        if not ignoreSort then
            tableSort(equipIds, CanEatEquipSort)
        end

        return equipIds
    end

    function XEquipManager.GetCanDecomposeWeaponIds()
        local weaponIds = {}
        for k, v in pairs(Equips) do
            if
                XEquipManager.IsClassifyEqual(v.Id, XEquipConfig.Classify.Weapon) and not XEquipManager.IsWearing(v.Id) and
                    not XEquipManager.IsLock(v.Id)
             then
                tableInsert(weaponIds, k)
            end
        end
        return weaponIds
    end

    function XEquipManager.GetCanDecomposeAwarenessIdsBySuitId(suitId)
        local awarenessIds = {}

        local equipIds = XEquipManager.GetEquipIdsBySuitId(suitId)
        for _, v in pairs(equipIds) do
            if
                XEquipManager.IsClassifyEqual(v, XEquipConfig.Classify.Awareness) and not XEquipManager.IsWearing(v) and
                    not XEquipManager.IsInSuitPrefab(v) and
                    not XEquipManager.IsLock(v)
             then
                tableInsert(awarenessIds, v)
            end
        end

        return awarenessIds
    end

    function XEquipManager.GetEquipSite(equipId)
        local equipCfg = GetEquipCfg(equipId)
        return equipCfg.Site
    end

    function XEquipManager.GetEquipSiteByEquipData(equip)
        local equipCfg = XEquipConfig.GetEquipCfg(equip.TemplateId)
        return equipCfg.Site
    end

    function XEquipManager.GetEquipType(equipId)
        local equipCfg = GetEquipCfg(equipId)
        return equipCfg.Type
    end

    function XEquipManager.GetEquipSiteByTemplateId(templateId)
        local equipCfg = XEquipConfig.GetEquipCfg(templateId)
        return equipCfg.Site
    end

    function XEquipManager.GetEquipTypeByTemplateId(templateId)
        local equipCfg = XEquipConfig.GetEquipCfg(templateId)
        return equipCfg.Type
    end

    function XEquipManager.GetEquipWearingCharacterId(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return equip.CharacterId > 0 and equip.CharacterId or nil
    end

    function XEquipManager.IsEquipWearingByCharacterId(equipId, characterId)
        if not XTool.IsNumberValid(characterId) then
            return false
        end
        return XEquipManager.GetEquipWearingCharacterId(equipId) == characterId
    end

    --专属角色Id
    function XEquipManager.GetEquipSpecialCharacterId(equipId)
        local equipCfg = GetEquipCfg(equipId)
        if equipCfg.CharacterId > 0 then
            return equipCfg.CharacterId
        end
    end

    function XEquipManager.GetEquipSpecialCharacterIdByTemplateId(templateId)
        local equipCfg = XEquipConfig.GetEquipCfg(templateId)
        if equipCfg.CharacterId > 0 then
            return equipCfg.CharacterId
        end
    end

    function XEquipManager.GetEquipClassify(equipId)
        local site = XEquipManager.GetEquipSite(equipId)
        if site == XEquipConfig.EquipSite.Weapon then
            return XEquipConfig.Classify.Weapon
        end

        return XEquipConfig.Classify.Awareness
    end

    function XEquipManager.GetEquipClassifyByTemplateId(templateId)
        if not XEquipConfig.CheckTemplateIdIsEquip(templateId) then
            return
        end
        local equipSite = XEquipManager.GetEquipSiteByTemplateId(templateId)
        return WeaponTypeCheckDic[equipSite] or AwarenessTypeCheckDic[equipSite]
    end

    function XEquipManager.GetSuitId(equipId)
        local equipCfg = GetEquipCfg(equipId)
        return equipCfg.SuitId
    end

    function XEquipManager.GetSuitIdByTemplateId(templateId)
        local equipCfg = XEquipConfig.GetEquipCfg(templateId)
        return equipCfg.SuitId
    end

    function XEquipManager.GetEquipTemplateIdsBySuitId(suitId)
        local equipTemplateIds = XEquipConfig.GetEquipTemplateIdsBySuitId(suitId)
        return equipTemplateIds
    end

    function XEquipManager.GetWeaponTypeIconPath(equipId)
        local templateId = GetEquipTemplateId(equipId)
        if XEquipManager.IsClassifyEqualByTemplateId(templateId, XEquipConfig.Classify.Weapon) then
            return XEquipConfig.GetWeaponTypeIconPath(templateId)
        end
    end

    function XEquipManager.GetEquipBreakThroughIcon(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return XEquipConfig.GetEquipBreakThroughIcon(equip.Breakthrough)
    end

    function XEquipManager.GetEquipBreakThroughIconByBreakThrough(breakthrough)
        return XEquipConfig.GetEquipBreakThroughIcon(breakthrough)
    end

    function XEquipManager.GetEquipBreakThroughSmallIcon(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        if equip.Breakthrough == 0 then
            return
        end
        return XEquipConfig.GetEquipBreakThroughSmallIcon(equip.Breakthrough)
    end

    function XEquipManager.GetEquipBreakThroughBigIcon(equipId, preBreakthrough)
        local equip = XEquipManager.GetEquip(equipId)
        local breakthrough = equip.Breakthrough
        if preBreakthrough then
            breakthrough = breakthrough + preBreakthrough
        end
        return XEquipConfig.GetEquipBreakThroughBigIcon(breakthrough)
    end

    function XEquipManager.GetEquipIdsBySuitId(suitId, site)
        if suitId == XEquipConfig.DEFAULT_SUIT_ID.Normal then
            return XEquipManager.GetAwarenessIds(XCharacterConfigs.CharacterType.Normal)
        elseif suitId == XEquipConfig.DEFAULT_SUIT_ID.Isomer then
            return XEquipManager.GetAwarenessIds(XCharacterConfigs.CharacterType.Isomer)
        end

        local equipIds = {}

        for _, equip in pairs(Equips) do
            local equipId = equip.Id
            if suitId == XEquipManager.GetSuitId(equipId) then
                if type(site) ~= "number" or XEquipManager.GetEquipSite(equipId) == site then
                    tableInsert(equipIds, equipId)
                end
            end
        end

        return equipIds
    end

    function XEquipManager.GetSuitName(suitId)
        if XEquipConfig.IsDefaultSuitId(suitId) then
            return ""
        end
        local suitCfg = XEquipConfig.GetEquipSuitCfg(suitId)
        return suitCfg.Name
    end

    function XEquipManager.GetSuitDescription(suitId)
        if XEquipConfig.IsDefaultSuitId(suitId) then
            return ""
        end
        local suitCfg = XEquipConfig.GetEquipSuitCfg(suitId)
        return suitCfg.Description
    end

    function XEquipManager.GetSuitSites(templateId)
        local suitId = XEquipManager.GetSuitIdByTemplateId(templateId)
        return XEquipConfig.GetSuitSites(suitId)
    end

    function XEquipManager.GetSuitCharacterType(suitId)
        if suitId == XEquipConfig.DEFAULT_SUIT_ID.Normal then
            return XEquipConfig.UserType.Normal
        elseif suitId == XEquipConfig.DEFAULT_SUIT_ID.Isomer then
            return XEquipConfig.UserType.Isomer
        end

        local templateId = GetSuitPresentEquipTemplateId(suitId)
        return XEquipConfig.GetEquipCharacterType(templateId)
    end

    function XEquipManager.GetSuitStar(suitId)
        if XEquipConfig.IsDefaultSuitId(suitId) then
            return 0
        end
        local templateId = GetSuitPresentEquipTemplateId(suitId)
        return XEquipManager.GetEquipStar(templateId)
    end

    function XEquipManager.GetSuitQualityIcon(suitId)
        if XEquipConfig.IsDefaultSuitId(suitId) then
            return
        end
        local templateId = GetSuitPresentEquipTemplateId(suitId)
        return XEquipManager.GetEquipBgPath(templateId)
    end

    function XEquipManager.GetCharacterWearingSuitMergeActiveSkillDesInfoList(characterId)
        local wearingAwarenessIds = XEquipManager.GetCharacterWearingAwarenessIds(characterId)
        return XEquipManager.GetSuitMergeActiveSkillDesInfoList(wearingAwarenessIds, characterId)
    end

    function XEquipManager.GetSuitMergeActiveSkillDesInfoList(wearingAwarenessIds, characterId)
        local skillDesInfoList = {}
        local overrunSuitId = 0 -- 超限绑定的套装id
        local isAddOverrun = false
        if characterId then
            local usingWeaponId = XEquipManager.GetCharacterWearingWeaponId(characterId)
            if usingWeaponId ~= 0 then
                local equip = XEquipManager.GetEquip(usingWeaponId)
                if equip:CanOverrun() and equip:IsOverrunBlindMatch() then
                    overrunSuitId = equip:GetOverrunChoseSuit()
                end
            end
        end

        local suitIdSet = {}
        for _, equipId in pairs(wearingAwarenessIds) do
            local suitId = XEquipManager.GetSuitId(equipId)
            if suitId > 0 then
                local count = suitIdSet[suitId]
                suitIdSet[suitId] = count and count + 1 or 1
            end
        end
        if overrunSuitId ~= 0 and not suitIdSet[overrunSuitId] then
            suitIdSet[overrunSuitId] = 0
        end

        for suitId, count in pairs(suitIdSet) do
            local isOverrun = suitId == overrunSuitId
            isAddOverrun = isAddOverrun or isOverrun
            local activeskillDesList = XEquipManager.GetSuitActiveSkillDesList(suitId, count, isOverrun, isOverrun)
            for _, info in pairs(activeskillDesList) do
                if info.IsActive then
                    tableInsert(skillDesInfoList, info)
                end
            end
        end

        return skillDesInfoList
    end

    function XEquipManager.GetActiveSuitEquipsCount(characterId, suitId)
        local count = 0
        local siteCheckDic = {}

        local wearingAwarenessIds = XEquipManager.GetCharacterWearingAwarenessIds(characterId)
        for _, equipId in pairs(wearingAwarenessIds) do
            local wearingSuitId = XEquipManager.GetSuitId(equipId)
            if suitId > 0 and suitId == wearingSuitId then
                count = count + 1
                local site = XEquipManager.GetEquipSite(equipId)
                siteCheckDic[site] = true
            end
        end

        return count, siteCheckDic
    end

    function XEquipManager.GetSuitActiveSkillDesList(suitId, count, isOverrun, isAddOverrunTips)
        count = count or 0
        local activeskillDesList = {}

        local skillDesList = XEquipManager.GetSuitSkillDesList(suitId)
        if skillDesList[2] then
            local isActive = count >= 2
            local isActiveWithOverrun = count + XEquipConfig.OVERRUN_ADD_SUIT_CNT >= 2
            local skillInfo = {}
            skillInfo.SkillDes = skillDesList[2] or ""
            skillInfo.PosDes = CSXTextManagerGetText("EquipSuitSkillPrefix2")
            skillInfo.IsActive = isOverrun and isActiveWithOverrun or isActive
            skillInfo.IsActiveByOverrun = isOverrun and not isActive and isActiveWithOverrun
            if skillInfo.IsActiveByOverrun then
                skillInfo.OverrunTips = CSXTextManagerGetText("EquipOverrunActive2")
                if isAddOverrunTips then
                    skillInfo.SkillDes = skillInfo.SkillDes .. CSXTextManagerGetText("EquipOverrunActiveTips")
                end
            end
            tableInsert(activeskillDesList, skillInfo)
        end
        if skillDesList[4] then
            local isActive = count >= 4
            local isActiveWithOverrun = count + XEquipConfig.OVERRUN_ADD_SUIT_CNT >= 4
            local skillInfo = {}
            skillInfo.SkillDes = skillDesList[4] or ""
            skillInfo.PosDes = CSXTextManagerGetText("EquipSuitSkillPrefix4")
            skillInfo.IsActive = isOverrun and isActiveWithOverrun or isActive
            skillInfo.IsActiveByOverrun = isOverrun and not isActive and isActiveWithOverrun
            if skillInfo.IsActiveByOverrun then
                skillInfo.OverrunTips = CSXTextManagerGetText("EquipOverrunActive4")
                if isAddOverrunTips then
                    skillInfo.SkillDes = skillInfo.SkillDes .. CSXTextManagerGetText("EquipOverrunActiveTips")
                end
            end
            tableInsert(activeskillDesList, skillInfo)
        end
        if skillDesList[6] then
            local isActive = count >= 6
            local isActiveWithOverrun = count + XEquipConfig.OVERRUN_ADD_SUIT_CNT >= 6
            local skillInfo = {}
            skillInfo.SkillDes = skillDesList[6] or ""
            skillInfo.PosDes = CSXTextManagerGetText("EquipSuitSkillPrefix6")
            skillInfo.IsActive = isOverrun and isActiveWithOverrun or isActive
            skillInfo.IsActiveByOverrun = isOverrun and not isActive and isActiveWithOverrun
            if skillInfo.IsActiveByOverrun then
                skillInfo.OverrunTips = CSXTextManagerGetText("EquipOverrunActive6")
                if isAddOverrunTips then
                    skillInfo.SkillDes = skillInfo.SkillDes .. CSXTextManagerGetText("EquipOverrunActiveTips")
                end
            end
            tableInsert(activeskillDesList, skillInfo)
        end

        return activeskillDesList
    end

    function XEquipManager.GetSuitSkillDesList(suitId)
        if not suitId or suitId == 0 or XEquipConfig.IsDefaultSuitId(suitId) then
            return {}
        end
        local suitCfg = XEquipConfig.GetEquipSuitCfg(suitId)
        return suitCfg and suitCfg.SkillDescription or {}
    end

    function XEquipManager.GetEquipCountInSuit(suitId, site)
        return #XEquipManager.GetEquipIdsBySuitId(suitId, site)
    end

    function XEquipManager.GetMaxSuitCount()
        return XEquipConfig.GetMaxSuitCount()
    end

    function XEquipManager.GetWeaponModelCfgByEquipId(equipId, uiName)
        local templateId = GetEquipTemplateId(equipId)
        local breakthroughTimes = XEquipManager.GetBreakthroughTimes(equipId)
        local resonanceCount = XEquipManager.GetResonanceCount(equipId)
        return XEquipManager.GetWeaponModelCfg(templateId, uiName, breakthroughTimes, resonanceCount)
    end

    function XEquipManager.GetBreakthroughTimes(equipId)
        local breakthroughTimes = 0

        if CheckEquipExist(equipId) then
            local equip = XEquipManager.GetEquip(equipId)
            breakthroughTimes = equip.Breakthrough
        end

        return breakthroughTimes
    end

    function XEquipManager.GetResonanceCount(equipId)
        local resonanceCount = 0
        if CheckEquipExist(equipId) then
            local equip = XEquipManager.GetEquip(equipId)
            resonanceCount =
                equip.ResonanceInfo and (equip.ResonanceInfo.Count or XTool.GetTableCount(equip.ResonanceInfo)) or 0
        end
        return resonanceCount
    end

    --desc: 获取装备模型配置列表
    function XEquipManager.GetWeaponModelCfg(templateId, uiName, breakthroughTimes, resonanceCount)
        local modelCfg = {}

        if not templateId then
            XLog.Error("XEquipManager.GetWeaponModelCfg错误: 参数templateId不能为空")
            return modelCfg
        end

        local template = XEquipConfig.GetEquipResCfg(templateId, breakthroughTimes)
        local modelId =
            XEquipConfig.GetWeaponResonanceModelId(XEquipConfig.WeaponCase.Case1, template.Id, resonanceCount)
        modelCfg.ModelId = modelId
        modelCfg.TransformConfig = XEquipConfig.GetEquipModelTransformCfg(templateId, uiName, resonanceCount)
        return modelCfg
    end

    -- 获取装备模型id列表
    function XEquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
        local idList = {}
        local templateId = equip.TemplateId
        local isWeaponFashion = weaponFashionId and not XWeaponFashionConfigs.IsDefaultId(weaponFashionId)
        local isAprilFoolDay = XDataCenter.AprilFoolDayManager.IsInTitleTime()

        local template = (not isWeaponFashion and isAprilFoolDay) and XEquipConfig.GetFoolEquipResCfg(templateId) or XEquipConfig.GetEquipResCfg(templateId, equip.Breakthrough)
        local resonanceCount =
            equip and equip.ResonanceInfo and (equip.ResonanceInfo.Count or XTool.GetTableCount(equip.ResonanceInfo)) or
            0

        if template then
            for case, modelTransId in pairs(template.ModelTransId) do
                if modelTransId then
                    local modelId = isWeaponFashion and XWeaponFashionConfigs.GetWeaponResonanceModelId(case, weaponFashionId, resonanceCount)
                    if not modelId then
                        modelId = isAprilFoolDay and
                                XEquipConfig.GetFoolWeaponResonanceModelId(case, templateId, resonanceCount) or
                                XEquipConfig.GetWeaponResonanceModelId(case, templateId, resonanceCount)
                    end
                    idList[case] = modelId
                end
            end
        end

        return idList
    end

    --desc: 获取武器模型名字列表(战斗用)
    function XEquipManager.GetWeaponModelNameList(templateId)
        local nameList = {}

        local usage = XEquipConfig.WeaponUsage.Battle
        local template = XEquipConfig.GetEquipResCfg(templateId)
        for _, modelId in pairs(template.ModelTransId) do
            local modelName = XEquipConfig.GetEquipModelName(modelId, usage)
            tableInsert(nameList, modelName)
        end
        return nameList
    end

    --desc: 获取武器模型名字列表(战斗用)
    function XEquipManager.GetWeaponModelNameListByFight(fightNpcData)
        local nameList = {}

        local characterId = fightNpcData.Character.Id
        local weaponFashionId =
            fightNpcData.WeaponFashionId or
            XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
        local usage = XEquipConfig.WeaponUsage.Battle
        for _, equip in pairs(fightNpcData.Equips) do
            if XEquipManager.IsWeaponByTemplateId(equip.TemplateId) then
                local idList = XEquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
                for _, modelId in ipairs(idList) do
                    tableInsert(nameList, XEquipConfig.GetEquipModelName(modelId, usage))
                end
                break
            end
        end

        return nameList or {}
    end

    --desc: 获取武器动画controller(战斗用)
    function XEquipManager.GetWeaponControllerList(templateId)
        local controllerList = {}
        local usage = XEquipConfig.WeaponUsage.Battle
        local template = XEquipConfig.GetEquipResCfg(templateId)
        for _, modelId in pairs(template.ModelTransId) do
            local controller = XEquipConfig.GetEquipAnimController(modelId, usage)
            tableInsert(controllerList, controller or "")
        end
        return controllerList
    end

    --desc: 获取武器模动画controller(战斗用)
    function XEquipManager.GetWeaponControllerListByFight(fightNpcData)
        local controllerList = {}
        local characterId = fightNpcData.Character.Id
        local weaponFashionId =
            fightNpcData.WeaponFashionId or
            XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
        local usage = XEquipConfig.WeaponUsage.Battle
        for _, equip in pairs(fightNpcData.Equips) do
            if XEquipManager.IsWeaponByTemplateId(equip.TemplateId) then
                local idList = XEquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
                for _, modelId in ipairs(idList) do
                    tableInsert(controllerList, XEquipConfig.GetEquipAnimController(modelId, usage))
                end
                break
            end
        end
        return controllerList
    end

    --desc: 获取武器模型id列表
    function XEquipManager.GetEquipModelIdListByFight(fightNpcData)
        local idList = {}
        local characterId = fightNpcData.Character.Id
        local weaponFashionId =
            fightNpcData.WeaponFashionId or
            XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
        for _, equip in pairs(fightNpcData.Equips) do
            if XEquipManager.IsWeaponByTemplateId(equip.TemplateId) then
                idList = XEquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
                break
            end
        end
        return idList
    end

    --desc: 通过角色id获取武器模型名字列表
    function XEquipManager.GetEquipModelIdListByCharacterId(characterId, isDefault, weaponFashionId)
        local isOwnCharacter = XDataCenter.CharacterManager.IsOwnCharacter(characterId)

        -- 武器时装预览
        if weaponFashionId then
            if isOwnCharacter then
                local equipId = XEquipManager.GetCharacterWearingWeaponId(characterId)
                local equip = XEquipManager.GetEquip(equipId)
                return XEquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
            else
                local templateId = XMVCA.XCharacter:GetCharacterDefaultEquipId(characterId)
                local equip = {TemplateId = templateId}
                return XEquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
            end
        end

        -- 默认武器预览
        if isDefault or not isOwnCharacter then
            local idList = {}
            local templateId = XMVCA.XCharacter:GetCharacterDefaultEquipId(characterId)
            local template = XEquipConfig.GetEquipResCfg(templateId)
            for _, id in pairs(template.ModelTransId) do
                tableInsert(idList, id)
            end
            return idList
        end

        -- 主角获取武器逻辑
        local equipId = XEquipManager.GetCharacterWearingWeaponId(characterId)
        local equip = XEquipManager.GetEquip(equipId)
        weaponFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
        return XEquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
    end

    -- 获取武器共鸣成功的特效显示时间
    function XEquipManager.GetWeaponResonanceEffectDelay(equipId, resonanceCount)
        if not equipId then
            return
        end
        local equip = XEquipManager.GetEquip(equipId)
        local modelId =
            XEquipConfig.GetWeaponResonanceModelId(XEquipConfig.WeaponCase.Case1, equip.TemplateId, resonanceCount)
        return XEquipConfig.GetWeaponResonanceEffectDelay(modelId)
    end

    -- 获取角色武器共鸣特效(战斗用)
    function XEquipManager.GetWeaponResonanceEffectPathByFight(fightNpcData)
        local equip

        for _, v in pairs(fightNpcData.Equips) do
            local equipTemplate = XEquipConfig.GetEquipCfg(v.TemplateId)
            if equipTemplate.Site == XEquipConfig.EquipSite.Weapon then
                equip = v
                break
            end
        end

        if not equip then
            XLog.Warning("参数fightNpcData：" .. tostring(fightNpcData) .. "中不包含武器")
            return
        end

        local resonanceCount =
            equip.ResonanceInfo and (equip.ResonanceInfo.Count or XTool.GetTableCount(equip.ResonanceInfo)) or 0
        local modelId =
            XEquipConfig.GetWeaponResonanceModelId(XEquipConfig.WeaponCase.Case1, equip.TemplateId, resonanceCount)
        return XEquipConfig.GetEquipModelEffectPath(modelId)
    end

    function XEquipManager.GetEquipCount(templateId)
        local count = 0
        for _, v in pairs(Equips) do
            if v.TemplateId == templateId then
                count = count + 1
            end
        end
        return count
    end

    function XEquipManager.GetFirstEquip(templateId)
        for _, v in pairs(Equips) do
            if v.TemplateId == templateId then
                return v
            end
        end
    end

    --desc: 获取装备大图标路径
    function XEquipManager.GetEquipBigIconPath(templateId)
        if not templateId then
            XLog.Error("XEquipManager.GetEquipBigIconPath错误, 参数templateId不能为空")
            return
        end

        local equipResCfg = XEquipConfig.GetEquipResCfg(templateId)
        return equipResCfg.BigIconPath
    end

    --desc: 获取装备图标路径
    function XEquipManager.GetEquipIconPath(templateId)
        if not templateId then
            XLog.Error("XEquipManager.GetEquipIconPath错误: 参数templateId不能为空")
            return
        end

        local equipResCfg = XEquipConfig.GetEquipResCfg(templateId)
        return equipResCfg.IconPath
    end

    --desc: 获取装备在背包中显示图标路径
    function XEquipManager.GetEquipIconBagPath(templateId, breakthroughTimes)
        local equipResCfg = XEquipConfig.GetEquipResCfg(templateId, breakthroughTimes)
        return equipResCfg.IconPath
    end

    --desc: 获取套装在背包中显示图标路径
    function XEquipManager.GetSuitIconBagPath(suitId)
        local suitCfg = XEquipConfig.GetEquipSuitCfg(suitId)
        return suitCfg.IconPath
    end

    --desc: 获取套装在背包中显示大图标路径
    function XEquipManager.GetSuitBigIconBagPath(suitId)
        local suitCfg = XEquipConfig.GetEquipSuitCfg(suitId)
        if not suitCfg then
            local path = XEquipConfig.GetEquipSuitPath()
            XLog.ErrorTableDataNotFound(
                "XEquipManager.GetSuitBigIconBagPath",
                "suitCfg",
                path,
                "suitId",
                tostring(suitId)
            )
            return
        end
        return suitCfg.BigIconPath
    end

    --desc: 获取意识立绘路径
    function XEquipManager.GetEquipLiHuiPath(templateId, breakthroughTimes)
        if not templateId then
            XLog.Error("XEquipManager.GetEquipLiHuiPath 错误: 参数templateId不能为空")
            return
        end

        local equipResCfg = XEquipConfig.GetEquipResCfg(templateId, breakthroughTimes)
        return equipResCfg.LiHuiPath
    end

    function XEquipManager.GetEquipPainterName(templateId, breakthroughTimes)
        local equipResCfg = XEquipConfig.GetEquipResCfg(templateId, breakthroughTimes)
        return equipResCfg.PainterName
    end

    function XEquipManager.GetEquipBgPath(templateId)
        return XEquipConfig.GetEquipBgPath(templateId)
    end

    function XEquipManager.GetEquipQualityPath(templateId)
        return XEquipConfig.GetEquipQualityPath(templateId)
    end

    function XEquipManager.GetEquipQuality(templateId)
        local equipCfg = XEquipConfig.GetEquipCfg(templateId)
        return equipCfg.Quality
    end

    function XEquipManager.GetEquipPriority(templateId)
        local equipCfg = XEquipConfig.GetEquipCfg(templateId)
        return equipCfg.Priority
    end

    function XEquipManager.GetEquipStar(templateId)
        local equipCfg = XEquipConfig.GetEquipCfg(templateId)
        return equipCfg.Star
    end

    function XEquipManager.GetEquipName(templateId)
        local equipCfg = XEquipConfig.GetEquipCfg(templateId)
        return equipCfg.Name or ""
    end

    function XEquipManager.GetEquipDescription(templateId)
        local equipCfg = XEquipConfig.GetEquipCfg(templateId)
        return equipCfg.Description or ""
    end

    function XEquipManager.GetOriginWeaponSkillInfo(templateId)
        local equipCfg = XEquipConfig.GetEquipCfg(templateId)

        local weaponSkillId = equipCfg.WeaponSkillId
        if not weaponSkillId then
            local path = XEquipConfig.GetEquipPath()
            XLog.ErrorTableDataNotFound(
                "XEquipManager.GetOriginWeaponSkillInfo",
                "weaponSkillId",
                path,
                "templateId",
                tostring(templateId)
            )
            return
        end

        return XSkillInfoObj.New(XEquipConfig.EquipResonanceType.WeaponSkill, weaponSkillId)
    end

    function XEquipManager.GetEquipMinLevel(templateId)
        local equipBorderCfg = XEquipConfig.GetEquipBorderCfg(templateId)
        return equipBorderCfg.MinLevel
    end

    function XEquipManager.GetEquipMaxLevel(templateId)
        local equipBorderCfg = XEquipConfig.GetEquipBorderCfg(templateId)
        return equipBorderCfg.MaxLevel
    end

    function XEquipManager.GetEquipMinBreakthrough(templateId)
        local equipBorderCfg = XEquipConfig.GetEquipBorderCfg(templateId)
        return equipBorderCfg.MinBreakthrough
    end

    function XEquipManager.GetEquipMaxBreakthrough(templateId)
        local equipBorderCfg = XEquipConfig.GetEquipBorderCfg(templateId)
        return equipBorderCfg.MaxBreakthrough
    end

    function XEquipManager.GetNextLevelExp(equipId, level)
        local equip = XDataCenter.EquipManager.GetEquip(equipId)
        level = level or equip.Level
        local levelUpCfg = XEquipConfig.GetLevelUpCfg(equip.TemplateId, equip.Breakthrough, level)
        return levelUpCfg.Exp
    end

    function XEquipManager.GetEquipAddExp(equipId, count)
        count = count or 1
        local exp

        local equip = XEquipManager.GetEquip(equipId)
        local levelUpCfg = XEquipConfig.GetLevelUpCfg(equip.TemplateId, equip.Breakthrough, equip.Level)
        local offerExp = XEquipManager.GetEquipOfferExp(equipId)

        --- 获得经验 = 装备已培养经验 * 继承比例 + 突破提供的经验
        exp = equip.Exp + levelUpCfg.AllExp
        exp = exp * XEquipConfig.GetEquipExpInheritPercent() / 100
        exp = exp + offerExp

        return exp * count
    end

    function XEquipManager.GetEquipLevelTotalNeedExp(equipId, targetLevel)
        local totalExp = 0

        local equip = XEquipManager.GetEquip(equipId)
        for level = equip.Level, targetLevel - 1 do
            totalExp = totalExp + XEquipManager.GetNextLevelExp(equipId, level)
        end
        totalExp = totalExp - equip.Exp

        return totalExp
    end

    function XEquipManager.GetEatEquipsCostMoney(equipIdKeys)
        local costMoney = 0

        for equipId in pairs(equipIdKeys) do
            local equipCfg = GetEquipCfg(equipId)
            costMoney = costMoney + XEquipConfig.GetEatEquipCostMoney(equipCfg.Site, equipCfg.Star)
        end

        return costMoney
    end

    function XEquipManager.GetEatItemsCostMoney(itemIdDic)
        local costMoney = 0

        for itemId, count in pairs(itemIdDic) do
            costMoney = costMoney + XDataCenter.ItemManager.GetItemsAddEquipCost(itemId, count)
        end

        return costMoney
    end

    --获取指定突破次数下最大等级限制
    function XEquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, times)
        local equipBreakthroughCfg = XEquipConfig.GetEquipBreakthroughCfg(templateId, times or 0)
        return equipBreakthroughCfg.LevelLimit
    end

    function XEquipManager.GetBreakthroughLevelLimit(equipId)
        local equipBreakthroughCfg = GetEquipBreakthroughCfg(equipId)
        return equipBreakthroughCfg.LevelLimit
    end

    function XEquipManager.GetBreakthroughLevelLimitByEquipData(equip)
        local equipBreakthroughCfg = XEquipConfig.GetEquipBreakthroughCfg(equip.TemplateId, equip.Breakthrough)
        return equipBreakthroughCfg.LevelLimit
    end

    function XEquipManager.GetBreakthroughLevelLimitNext(equipId)
        local equipBreakthroughCfg = GetEquipBreakthroughCfgNext(equipId)
        return equipBreakthroughCfg.LevelLimit
    end

    function XEquipManager.GetBreakthroughCondition(equipId)
        local equipBreakthroughCfg = GetEquipBreakthroughCfg(equipId)
        return equipBreakthroughCfg.ConditionId
    end

    function XEquipManager.GetBreakthroughUseMoney(equipId)
        local equipBreakthroughCfg = GetEquipBreakthroughCfg(equipId)
        return equipBreakthroughCfg.UseMoney
    end

    function XEquipManager.GetBreakthroughUseItemId(equipId)
        local equipBreakthroughCfg = GetEquipBreakthroughCfg(equipId)
        return equipBreakthroughCfg.UseItemId
    end

    function XEquipManager.GetBreakthroughConsumeItems(equipId)
        local consumeItems = {}

        local equipBreakthroughCfg = GetEquipBreakthroughCfg(equipId)
        for i = 1, #equipBreakthroughCfg.ItemId do
            tableInsert(
                consumeItems,
                {
                    Id = equipBreakthroughCfg.ItemId[i],
                    Count = equipBreakthroughCfg.ItemCount[i]
                }
            )
        end

        return consumeItems
    end

    function XEquipManager.GetAwakeConsumeCoin(equipId)
        local consumeCoin = 0

        local coinId = XDataCenter.ItemManager.ItemId.Coin
        local config = GetEquipAwakeCfg(equipId)
        for i = 1, #config.ItemId do
            local itemId = config.ItemId[i]
            if itemId == coinId then
                consumeCoin = config.ItemCount[i]
                break
            end
        end

        return consumeCoin
    end

    function XEquipManager.GetAwakeConsumeItemList(equipId)
        local consumeItems = {}

        local coinId = XDataCenter.ItemManager.ItemId.Coin
        local config = GetEquipAwakeCfg(equipId)
        for i = 1, #config.ItemId do
            local itemId = config.ItemId[i]
            if itemId ~= coinId then
                tableInsert(
                    consumeItems,
                    {
                        ItemId = itemId,
                        Count = config.ItemCount[i]
                    }
                )
            end
        end

        return consumeItems
    end

    function XEquipManager.GetAwakeConsumeItemCrystalList(equipId)
        local consumeItems = {}

        local coinId = XDataCenter.ItemManager.ItemId.Coin
        local config = GetEquipAwakeCfg(equipId)
        for i = 1, #config.ItemCrystalId do
            local itemId = config.ItemCrystalId[i]
            if itemId ~= coinId then
                tableInsert(
                    consumeItems,
                    {
                        ItemId = itemId,
                        Count = config.ItemCrystalCount[i]
                    }
                )
            end
        end

        return consumeItems
    end

    function XEquipManager.GetAwakeConsumeCrystalCoin(equipId)
        local consumeCoin = 0

        local coinId = XDataCenter.ItemManager.ItemId.Coin
        local config = GetEquipAwakeCfg(equipId)
        for i = 1, #config.ItemCrystalId do
            local itemId = config.ItemCrystalId[i]
            if itemId == coinId then
                consumeCoin = config.ItemCrystalCount[i]
                break
            end
        end

        return consumeCoin
    end

    function XEquipManager.GetAwakeSkillDesList(equipId, pos)
        local templateId = GetEquipTemplateId(equipId)
        return XEquipConfig.GetEquipAwakeSkillDesList(templateId, pos)
    end

    function XEquipManager.GetAwakeSkillDesListByEquipData(equip, pos)
        local templateId = equip.TemplateId
        return XEquipConfig.GetEquipAwakeSkillDesList(templateId, pos)
    end

    function XEquipManager.GetEquipOfferExp(equipId)
        local equipBreakthroughCfg = GetEquipBreakthroughCfg(equipId)
        return equipBreakthroughCfg.Exp
    end

    function XEquipManager.GetResonanceSkillNum(equipId)
        local templateId = GetEquipTemplateId(equipId)
        return XEquipManager.GetResonanceSkillNumByTemplateId(templateId)
    end

    function XEquipManager.GetResonanceSkillNumByTemplateId(templateId)
        local count = 0

        local equipResonanceCfg = XEquipConfig.GetEquipResonanceCfg(templateId)
        if not equipResonanceCfg then
            return count
        end

        for pos = 1, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
            if
                equipResonanceCfg.WeaponSkillPoolId and equipResonanceCfg.WeaponSkillPoolId[pos] and
                    equipResonanceCfg.WeaponSkillPoolId[pos] > 0
             then
                count = count + 1
            elseif
                equipResonanceCfg.AttribPoolId and equipResonanceCfg.AttribPoolId[pos] and
                    equipResonanceCfg.AttribPoolId[pos] > 0
             then
                count = count + 1
            elseif
                equipResonanceCfg.CharacterSkillPoolId and equipResonanceCfg.CharacterSkillPoolId[pos] and
                    equipResonanceCfg.CharacterSkillPoolId[pos] > 0
             then
                count = count + 1
            end
        end

        return count
    end

    function XEquipManager.GetResonanceSkillInfo(equipId, pos)
        local skillInfo = {}

        local equip = XEquipManager.GetEquip(equipId)
        if equip.ResonanceInfo and equip.ResonanceInfo[pos] then
            skillInfo = XSkillInfoObj.New(equip.ResonanceInfo[pos].Type, equip.ResonanceInfo[pos].TemplateId)
        end

        return skillInfo
    end

    function XEquipManager.GetResonanceSkillInfoByEquipData(equip, pos)
        local skillInfo = {}

        if equip.ResonanceInfo and equip.ResonanceInfo[pos] then
            skillInfo = XSkillInfoObj.New(equip.ResonanceInfo[pos].Type, equip.ResonanceInfo[pos].TemplateId)
        end

        return skillInfo
    end

    function XEquipManager.GetUnconfirmedResonanceSkillInfo(equipId, pos)
        local skillInfo = {}

        local equip = XEquipManager.GetEquip(equipId)
        if equip.UnconfirmedResonanceInfo and equip.UnconfirmedResonanceInfo[pos] then
            skillInfo =
                XSkillInfoObj.New(
                equip.UnconfirmedResonanceInfo[pos].Type,
                equip.UnconfirmedResonanceInfo[pos].TemplateId
            )
        end

        return skillInfo
    end

    function XEquipManager.GetResonanceBindCharacterId(equipId, pos)
        local equip = XEquipManager.GetEquip(equipId)
        return equip.ResonanceInfo and equip.ResonanceInfo[pos] and equip.ResonanceInfo[pos].CharacterId or 0
    end

    function XEquipManager.GetResonanceBindCharacterIdByEquipData(equip, pos)
        return equip.ResonanceInfo and equip.ResonanceInfo[pos] and equip.ResonanceInfo[pos].CharacterId or 0
    end

    function XEquipManager.GetUnconfirmedResonanceBindCharacterId(equipId, pos)
        local equip = XEquipManager.GetEquip(equipId)
        return equip.UnconfirmedResonanceInfo and equip.UnconfirmedResonanceInfo[pos] and
            equip.UnconfirmedResonanceInfo[pos].CharacterId
    end

    function XEquipManager.GetResonanceConsumeItemId(equipId)
        local templateId = GetEquipTemplateId(equipId)
        local equipResonanceItemCfg = XEquipConfig.GetEquipResonanceConsumeItemCfg(templateId)
        return equipResonanceItemCfg.ItemId[1]
    end

    function XEquipManager.GetResonanceConsumeItemCount(equipId)
        local templateId = GetEquipTemplateId(equipId)
        local equipResonanceItemCfg = XEquipConfig.GetEquipResonanceConsumeItemCfg(templateId)
        local count = equipResonanceItemCfg.ItemCount[1]

        return count
    end

    function XEquipManager.GetResonanceConsumeSelectSkillItemId(equipId)
        local templateId = GetEquipTemplateId(equipId)
        local equipResonanceItemCfg = XEquipConfig.GetEquipResonanceConsumeItemCfg(templateId)
        return equipResonanceItemCfg.SelectSkillItemId[1]
    end

    function XEquipManager.GetResonanceConsumeSelectSkillItemCount(equipId)
        local templateId = GetEquipTemplateId(equipId)
        local equipResonanceItemCfg = XEquipConfig.GetEquipResonanceConsumeItemCfg(templateId)
        local count = equipResonanceItemCfg.SelectSkillItemCount[1]

        return count
    end

    function XEquipManager.GetResonanceCanEatEquipIds(equipId)
        local equipIds = {}

        if XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Weapon) then
            --武器消耗同星级
            local resonanceEquip = XEquipManager.GetEquip(equipId)
            local star = XEquipManager.GetEquipStar(resonanceEquip.TemplateId)

            for _, equip in pairs(Equips) do
                if
                    equip.Id ~= equipId and star == XEquipManager.GetEquipStar(equip.TemplateId) and
                        XEquipManager.IsClassifyEqual(equip.Id, XEquipConfig.Classify.Weapon) and
                        not XEquipManager.IsWearing(equip.Id) and
                        not XEquipManager.IsLock(equip.Id)
                 then
                    tableInsert(equipIds, equip.Id)
                end
            end
        else
            --意识消耗同套装
            local resonanceSuitId = XEquipManager.GetSuitId(equipId)

            for _, equip in pairs(Equips) do
                if
                    equip.Id ~= equipId and resonanceSuitId == XEquipManager.GetSuitId(equip.Id) and
                        XEquipManager.IsClassifyEqual(equip.Id, XEquipConfig.Classify.Awareness) and
                        not XEquipManager.IsWearing(equip.Id) and
                        not XEquipManager.IsInSuitPrefab(equip.Id) and
                        not XEquipManager.IsLock(equip.Id)
                 then
                    tableInsert(equipIds, equip.Id)
                end
            end
        end

        --加个默认排序
        XEquipManager.SortEquipIdListByPriorType(equipIds)

        return equipIds
    end

    function XEquipManager.GetCanResonanceCharacterList(equipId)
        local canResonanceCharacterList = {}

        local wearingCharacterId = XEquipManager.GetEquipWearingCharacterId(equipId)
        if wearingCharacterId then
            tableInsert(canResonanceCharacterList, XDataCenter.CharacterManager.GetCharacter(wearingCharacterId))
        end

        local templateId = GetEquipTemplateId(equipId)
        local characterType = XEquipConfig.GetEquipCharacterType(templateId)
        local ownCharacterList = XDataCenter.CharacterManager.GetOwnCharacterList(characterType)
        for _, character in pairs(ownCharacterList) do
            local characterId = character.Id
            if characterId ~= wearingCharacterId then
                local characterEquipType = XMVCA.XCharacter:GetCharacterEquipType(characterId)
                if XEquipManager.IsTypeEqual(equipId, characterEquipType) then
                    tableInsert(canResonanceCharacterList, character)
                end
            end
        end

        return canResonanceCharacterList
    end

    --获取某TemplateID的装备的数量
    function XEquipManager.GetEquipCountByTemplateID(templateId)
        local count = 0
        for _, v in pairs(Equips) do
            if v.TemplateId == templateId then
                count = count + 1
            end
        end
        return count
    end

    local function GetWeaponSkillAbility(equip, characterId)
        local template = XEquipConfig.GetEquipCfg(equip.TemplateId)
        if not template then
            return
        end

        if template.Site ~= XEquipConfig.EquipSite.Weapon then
            XLog.Error("GetWeaponSkillAbility 错误: 参数equip不是武器, equip的Site是: " .. template.site)
            return
        end

        local ability = 0

        if template.WeaponSkillId > 0 then
            local weaponAbility = XEquipConfig.GetWeaponSkillAbility(template.WeaponSkillId)
            if not weaponAbility then
                local path = XEquipConfig.GetWeaponSkillPath()
                XLog.ErrorTableDataNotFound(
                    "XEquipManager.GetWeaponSkillAbility",
                    "weaponAbility",
                    path,
                    "WeaponSkillId",
                    tostring(template.WeaponSkillId)
                )
                return
            end

            ability = ability + weaponAbility
        end

        if equip.ResonanceInfo then
            for _, resonanceData in pairs(equip.ResonanceInfo) do
                if resonanceData.Type == XEquipConfig.EquipResonanceType.WeaponSkill then
                    if resonanceData.CharacterId == 0 or resonanceData.CharacterId == characterId then
                        local weaponAbility = XEquipConfig.GetWeaponSkillAbility(resonanceData.TemplateId)
                        if not weaponAbility then
                            local path = XEquipConfig.GetWeaponSkillPath()
                            XLog.ErrorTableDataNotFound(
                                "XEquipManager.GetWeaponSkillAbility",
                                "weaponAbility",
                                path,
                                "WeaponSkillId",
                                tostring(resonanceData.TemplateId)
                            )
                            return
                        end

                        ability = ability + weaponAbility
                    end
                end
            end
        end

        return ability
    end

    local function GetEquipSkillAbility(equipList, characterId)
        local suitCount = {}
        local ability = 0

        for _, equip in pairs(equipList) do
            local template = XEquipConfig.GetEquipCfg(equip.TemplateId)
            if not template then
                return 0
            end

            if template.Site == XEquipConfig.EquipSite.Weapon then
                local weaponAbility = GetWeaponSkillAbility(equip, characterId)
                if not weaponAbility then
                    return 0
                end

                ability = ability + weaponAbility
            end

            if template.SuitId > 0 then
                if not suitCount[template.SuitId] then
                    suitCount[template.SuitId] = 1
                else
                    suitCount[template.SuitId] = suitCount[template.SuitId] + 1
                end
            end
        end

        for suitId, count in pairs(suitCount) do
            local template = XEquipConfig.GetEquipSuitCfg(suitId)
            if not template then
                return 0
            end

            for i = 1, mathMin(count, XEquipConfig.MAX_SUIT_COUNT) do
                local effectId = template.SkillEffect[i]
                if effectId and effectId > 0 then
                    local effectTemplate = XEquipConfig.GetEquipSuitEffectCfg(effectId)
                    if not effectTemplate then
                        return 0
                    end

                    ability = ability + effectTemplate.Ability
                end
            end
        end

        return ability
    end

    function XEquipManager.GetEquipSkillAbility(characterId)
        local equipList = XEquipManager.GetCharacterWearingEquips(characterId)
        if not equipList or #equipList <= 0 then
            return 0
        end

        return GetEquipSkillAbility(equipList, characterId)
    end

    function XEquipManager.GetEquipSkillAbilityOther(character, equipList)
        if not equipList or #equipList <= 0 then
            return 0
        end
        return GetEquipSkillAbility(equipList, character.Id)
    end

    --- 计算装备战斗力（不包含角色共鸣相关）
    function XEquipManager.GetEquipAbility(characterId)
        local equipList = XEquipManager.GetCharacterWearingEquips(characterId)
        if not equipList or #equipList <= 0 then
            return 0
        end

        local skillAbility = GetEquipSkillAbility(equipList, 0)
        local equipListAttribs = XFightEquipManager.GetEquipListAttribs(equipList)
        local equipListAbility = XAttribManager.GetAttribAbility(equipListAttribs)

        return equipListAbility + skillAbility
    end

    --==============================
     ---@desc 获取装备升级消耗来源
     ---@eatType 消耗类型
     ---@equipId 装备Id
     ---@return table
    --==============================
    function XEquipManager.GetEquipEatSkipIds(eatType, equipId)
        local site = XEquipManager.GetEquipSite(equipId)
        local template = XEquipConfig.GetEquipEatSkipIdTemplate(eatType, site)
        return template.SkipIdParams
    end
    
    --==============================
     ---@desc 获取装备来源
     ---@templateId 装备Id 
     ---@return table
    --==============================
    function XEquipManager.GetEquipSkipIds(templateId)
        local equipType = XEquipManager.GetEquipClassifyByTemplateId(templateId)
        local template = XEquipConfig.GetEquipSkipIdTemplate(equipType)
        return template.SkipIdParams
    end

    function XEquipManager.CheckBoxOverLimitOfDraw() --武器意识拦截检测
        OverLimitTexts["Weapon"] = nil
        OverLimitTexts["Wafer"] = nil

        local max = XEquipConfig.GetMaxWeaponCount()
        local cur = XEquipManager.GetWeaponCount()
        if (max - cur) < 1 then
            OverLimitTexts["Weapon"] = CS.XTextManager.GetText("WeaponBoxIsFull")
        end

        max = XEquipConfig.GetMaxAwarenessCount()
        cur = XEquipManager.GetAwarenessCount()
        if (max - cur) < 1 then
            OverLimitTexts["Wafer"] = CS.XTextManager.GetText("WaferBoxIsFull")
        end

        ---@type XMailAgency
        local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
        if mailAgency:CheckMailIsOverLimit(true) then
            return true
        end

        if OverLimitTexts["Weapon"] then
            XUiManager.TipMsg(OverLimitTexts["Weapon"])
            return true
        end
        if OverLimitTexts["Wafer"] then
            XUiManager.TipMsg(OverLimitTexts["Wafer"])
            return true
        end
        return false
    end

    function XEquipManager.CheckBoxOverLimitOfGetAwareness() --意识拦截检测
        OverLimitTexts["Wafer"] = nil

        local max = XEquipConfig.GetMaxAwarenessCount()
        local cur = XEquipManager.GetAwarenessCount()
        if (max - cur) < 1 then
            OverLimitTexts["Wafer"] = CS.XTextManager.GetText("WaferBoxIsFull")
        end

        max = CS.XGame.Config:GetInt("MailCountLimit")
        ---@type XMailAgency
        local mailAgency = XMVCA:GetAgency(ModuleId.XMail)
        cur = mailAgency:GetMailListCount()
        if (max - cur) < 1 then
            XUiManager.TipMsg(CS.XTextManager.GetText("MailBoxIsFull"))
            return true
        end

        if OverLimitTexts["Wafer"] then
            XUiManager.TipMsg(OverLimitTexts["Wafer"])
            return true
        end
        return false
    end

    function XEquipManager.GetMaxCountOfBoxOverLimit(EquipId, MaxCount, Count) --武器意识拦截检测
        local maxCount = MaxCount
        OverLimitTexts["Weapon"] = nil
        OverLimitTexts["Wafer"] = nil
        OverLimitTexts["Item"] = nil

        if XArrangeConfigs.GetType(EquipId) == XArrangeConfigs.Types.Weapon then
            local max = XEquipConfig.GetMaxWeaponCount()
            local cur = XEquipManager.GetWeaponCount()
            if (max - cur) // Count < maxCount then
                maxCount = math.max(0, (max - cur) // Count)
                OverLimitTexts["Weapon"] = CS.XTextManager.GetText("WeaponBoxWillBeFull")
            end
        elseif XArrangeConfigs.GetType(EquipId) == XArrangeConfigs.Types.Wafer then
            local max = XEquipConfig.GetMaxAwarenessCount()
            local cur = XEquipManager.GetAwarenessCount()
            if (max - cur) // Count < maxCount then
                maxCount = math.max(0, (max - cur) // Count)
                OverLimitTexts["Wafer"] = CS.XTextManager.GetText("WaferBoxWillBeFull")
            end
        elseif XArrangeConfigs.GetType(EquipId) == XArrangeConfigs.Types.Item then
            local item = XDataCenter.ItemManager.GetItem(EquipId)
            local max = item.Template.MaxCount
            local cur = item:GetCount()
            if max > 0 then
                if (max - cur) // Count < maxCount then
                    maxCount = math.max(0, (max - cur) // Count)
                    OverLimitTexts["Item"] = CS.XTextManager.GetText("ItemBoxWillBeFull")
                end
            end
        end

        return maxCount
    end

    function XEquipManager.ShowBoxOverLimitText() --武器意识拦截检测
        if OverLimitTexts["Weapon"] then
            XUiManager.TipMsg(OverLimitTexts["Weapon"])
            return true
        end
        if OverLimitTexts["Wafer"] then
            XUiManager.TipMsg(OverLimitTexts["Wafer"])
            return true
        end
        if OverLimitTexts["Item"] then
            XUiManager.TipMsg(OverLimitTexts["Item"])
            return true
        end
        return false
    end

    function XEquipManager.GetAwakeItemApplicationScope(itemId) --获取觉醒道具能够生效的意识列表
        if not AwakeItemTypeDic then
            XLog.Error("EquipAwake.tab Is None or EquipAwakeItem Is None")
            return nil
        end
        return AwakeItemTypeDic[itemId]
    end

    --装备回收相关 begin
    --意识回收设置
    local AwarenessRecycleInfo = {
        --设置的回收星级（默认选中1-4星）
        StarCheckDic = {
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true
        },
        Days = 0 --设置回收天数, 0为不回收
    }

    local function UpdateAwarenessRecycleInfo(recycleInfo)
        if XTool.IsTableEmpty(recycleInfo) then
            return
        end

        local starDic = {}
        for _, star in pairs(recycleInfo.RecycleStar or {}) do
            starDic[star] = true
        end
        AwarenessRecycleInfo.StarCheckDic = starDic

        AwarenessRecycleInfo.Days = recycleInfo.Days or 0
    end

    function XEquipManager.IsEquipCanRecycle(equipId)
        if not equipId then
            return false
        end
        local equip = XEquipManager.GetEquip(equipId)
        if not equip then
            return false
        end

        local equipId = equip.Id
        return XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Awareness) and --是意识（后续开放武器回收）
            XEquipManager.GetEquipStar(equip.TemplateId) <= XEquipConfig.CAN_NOT_AUTO_EAT_STAR and --星级≤5
            equip.Breakthrough == 0 and --无突破
            equip.Level == 1 and
            equip.Exp == 0 and --无强化
            not equip.ResonanceInfo and
            not equip.UnconfirmedResonanceInfo and --无共鸣
            not XEquipManager.IsEquipAwaken(equipId) and --无觉醒
            not XEquipManager.IsWearing(equipId) and --未被穿戴
            not XEquipManager.IsInSuitPrefab(equipId) and --未被预设在意识组合中
            not XEquipManager.IsLock(equipId) --未上锁
    end

    --是否待回收
    function XEquipManager.IsRecycle(equipId)
        if not equipId then
            return false
        end
        local equip = XEquipManager.GetEquip(equipId)
        if not equip then
            return false
        end

        return equip.IsRecycle
    end

    function XEquipManager.GetCanRecycleWeaponIds()
        local weaponIds = {}
        for k, v in pairs(Equips) do
            local equipId = v.Id

            if
                XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Weapon) and
                    XEquipManager.IsEquipCanRecycle(equipId)
             then
                tableInsert(weaponIds, k)
            end
        end
        return weaponIds
    end

    function XEquipManager.GetCanRecycleAwarenessIdsBySuitId(suitId)
        local awarenessIds = {}

        local equipIds = XEquipManager.GetEquipIdsBySuitId(suitId)
        for _, equipId in pairs(equipIds) do
            if
                XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Awareness) and
                    XEquipManager.IsEquipCanRecycle(equipId)
             then
                tableInsert(awarenessIds, equipId)
            end
        end

        return awarenessIds
    end

    function XEquipManager.GetEquipRecycleItemCount(equipId, count)
        count = count or 1
        return precent * XEquipManager.GetEquipAddExp(equipId, count)
    end

    function XEquipManager.GetRecycleRewards(equipIds)
        local itemInfoList = {}

        local totalExp = 0
        for _, equipId in pairs(equipIds) do
            local addExp = XEquipManager.GetEquipAddExp(equipId)
            totalExp = totalExp + addExp
        end
        if totalExp == 0 then
            return itemInfoList
        end

        local precent = XEquipConfig.GetEquipRecycleItemPercent()
        local itemInfo = {
            TemplateId = XEquipConfig.GetEquipRecycleItemId(),
            Count = mathFloor(precent * totalExp)
        }
        tableInsert(itemInfoList, itemInfo)

        return itemInfoList
    end

    function XEquipManager.GetRecycleStarCheckDic()
        return XTool.Clone(AwarenessRecycleInfo.StarCheckDic)
    end

    function XEquipManager.GetRecycleSettingDays()
        return AwarenessRecycleInfo.Days or 0
    end

    function XEquipManager.CheckRecycleInfoDifferent(starCheckDic, days)
        if days ~= AwarenessRecycleInfo.Days then
            return true
        end

        for star, value in pairs(starCheckDic) do
            if value and not AwarenessRecycleInfo.StarCheckDic[star] then
                return true
            end
        end

        for star, value in pairs(AwarenessRecycleInfo.StarCheckDic) do
            if value and not starCheckDic[star] then
                return true
            end
        end

        return false
    end

    --装备意识回收请求
    function XEquipManager.EquipChipRecycleRequest(equipIds, cb)
        local req = {ChipIds = equipIds}
        XNetwork.Call(
            "EquipChipRecycleRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local rewardGoodsList = res.RewardGoodsList
                for _, id in pairs(equipIds) do
                    XEquipManager.DeleteEquip(id)
                end

                if cb then
                    cb(rewardGoodsList)
                end
            end
        )
    end

    --装备意识设置自动回收请求
    function XEquipManager.EquipChipSiteAutoRecycleRequest(starList, days, cb)
        local req = {StarList = starList, Days = days}
        XNetwork.Call(
            "EquipChipSiteAutoRecycleRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateAwarenessRecycleInfo(
                    {
                        RecycleStar = starList,
                        Days = days
                    }
                )

                if cb then
                    cb()
                end
            end
        )
    end

    function XEquipManager.IsSetRecycleNeedConfirm(equipId)
        if XEquipManager.IsHaveRecycleCookie() then
            return false
        end
        local equip = XEquipManager.GetEquip(equipId)
        return equip and XEquipManager.GetEquipStar(equip.TemplateId) == XEquipConfig.CAN_NOT_AUTO_EAT_STAR
    end

    function XEquipManager.GetRecycleCookieKey()
        return XPlayer.Id .. "IsHaveRecycleCookie"
    end

    function XEquipManager.IsHaveRecycleCookie()
        local key = XEquipManager.GetRecycleCookieKey()
        local updateTime = XSaveTool.GetData(key)
        if not updateTime then
            return false
        end
        return XTime.GetServerNowTimestamp() < updateTime
    end

    function XEquipManager.SetRecycleCookie(isSelect)
        local key = XEquipManager.GetRecycleCookieKey()
        if not isSelect then
            XSaveTool.RemoveData(key)
        else
            if XEquipManager.IsHaveRecycleCookie() then
                return
            end
            local updateTime = XTime.GetSeverTomorrowFreshTime()
            XSaveTool.SaveData(key, updateTime)
        end
    end

    --装备更新回收标志请求
    function XEquipManager.EquipUpdateRecycleRequest(equipId, isRecycle, cb)
        isRecycle = isRecycle and true or false

        local callFunc = function()
            local req = {EquipId = equipId, IsRecycle = isRecycle}
            XNetwork.Call(
                "EquipUpdateRecycleRequest",
                req,
                function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        return
                    end

                    local equip = XEquipManager.GetEquip(equipId)
                    equip:SetRecycle(isRecycle)

                    if cb then
                        cb()
                    end

                    CsXGameEventManager.Instance:Notify(
                        XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY,
                        equipId,
                        isRecycle
                    )
                    XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY, equipId, isRecycle)
                end
            )
        end

        if isRecycle and XEquipManager.IsSetRecycleNeedConfirm(equipId) then
            local title = CSXTextManagerGetText("EquipSetRecycleConfirmTitle")
            local content = CSXTextManagerGetText("EquipSetRecycleConfirmContent")
            local days = XEquipManager.GetRecycleSettingDays()
            local content2 =
                days > 0 and CSXTextManagerGetText("EquipSetRecycleConfirmContentExtra", days) or
                CSXTextManagerGetText("EquipSetRecycleConfirmContentExtraNegative")
            local hintInfo = {
                SetHintCb = XEquipManager.SetRecycleCookie,
                Status = XEquipManager.IsHaveRecycleCookie
            }
            XUiManager.DialogHintTip(title, content, content2, nil, callFunc, hintInfo)
        else
            callFunc()
        end
    end

    function XEquipManager.NotifyEquipChipAutoRecycleSite(data)
        UpdateAwarenessRecycleInfo(data.ChipRecycleSite)
    end

    function XEquipManager.NotifyEquipAutoRecycleChipList(data)
        local equipIds = data.ChipIds
        if XTool.IsTableEmpty(equipIds) then
            return
        end

        for _, equipId in pairs(equipIds) do
            XEquipManager.DeleteEquip(equipId)
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_RECYCLE_NOTIFY, equipIds)
    end
    --装备回收相关 end

    --region 一键培养(单位：升级单位/LevelUnit)
    local XEquipLevelUpConsume = require("XEntity/XEquip/XEquipLevelUpConsume")

    --升级单位转换为突破次数，等级
    function XEquipManager.ConvertToBreakThroughAndLevel(templateId, levelUnit)
        local breakthrough, level = 0, 0
        local maxBreakThrough = XEquipManager.GetEquipMaxBreakthrough(templateId)
        for i = 0, maxBreakThrough do
            local levelLimit = XEquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, i)
            if levelUnit <= levelLimit then
                level = levelUnit
                break
            end
            breakthrough = breakthrough + 1
            levelUnit = levelUnit - levelLimit
        end
        return breakthrough, level
    end

    --突破次数，等级转换为升级单位
    function XEquipManager.ConvertToLevelUnit(templateId, breakthrough, level)
        breakthrough = breakthrough or 0
        level = level or 1
        local levelUnit = 0
        for i = 0, breakthrough - 1 do
            levelUnit = levelUnit + XEquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, i)
        end
        levelUnit = levelUnit + level
        return levelUnit
    end

    --获取装备最大升级单位（全突破）
    function XEquipManager.GetEquipMaxLevelUnit(templateId)
        local breakThrough = XEquipManager.GetEquipMaxBreakthrough(templateId)
        local level = XEquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, breakThrough)
        return XEquipManager.ConvertToLevelUnit(templateId, breakThrough, level)
    end

    --获取装备当前升级单位（当前突破次数等级之和+当前等级）
    function XEquipManager.GetEquipLevelUnit(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return XEquipManager.ConvertToLevelUnit(equip.TemplateId, equip.Breakthrough, equip.Level)
    end

    --检查指定突破次数下的突破条件
    function XEquipManager.CheckBreakthroughCondition(templateId, breakthrough)
        local equipBreakthroughCfg = XEquipConfig.GetEquipBreakthroughCfg(templateId, breakthrough)
        local conditionId = equipBreakthroughCfg.ConditionId
        if not XTool.IsNumberValid(conditionId) then
            return true, ""
        end
        return XConditionManager.CheckCondition(conditionId)
    end

    --获取装备从当前到目标突破次数总消耗货币
    function XEquipManager.GetMutiBreakthroughUseMoney(templateId, originBreakthrough, targetBreakthrough)
        local costMoney = 0
        for i = originBreakthrough, targetBreakthrough - 1 do
            costMoney = costMoney + XEquipConfig.GetEquipBreakthroughCfg(templateId, i).UseMoney
        end
        return costMoney
    end

    --获取装备从当前到目标突破次数总消耗道具
    function XEquipManager.GetMutiBreakthroughConsumeItems(equipId, targetBreakthrough)
        local itemDic, canBreakThrough = {}, true

        local equip = XEquipManager.GetEquip(equipId)
        local templateId = equip.TemplateId

        --根据最后一次突破取所有消耗物品种类
        local consumeItems = {}
        local lastBreakThrough = XEquipManager.GetEquipMaxBreakthrough(templateId) - 1
        if lastBreakThrough < 0 then
            --没有突破配置
            return itemDic, canBreakThrough
        end
        local equipBreakthroughCfg = XEquipConfig.GetEquipBreakthroughCfg(templateId, lastBreakThrough)
        for index, itemId in ipairs(equipBreakthroughCfg.ItemId) do
            tableInsert(
                consumeItems,
                {
                    Id = itemId,
                    Count = 0
                }
            )
        end

        --取到达目标突破次数时消耗物品数量
        local originBreakthrough = equip.Breakthrough
        for i = equip.Breakthrough, targetBreakthrough - 1 do
            local equipBreakthroughCfg = XEquipConfig.GetEquipBreakthroughCfg(templateId, i)
            for index, itemId in pairs(equipBreakthroughCfg.ItemId) do
                if not itemDic[itemId] then
                    itemDic[itemId] = 0
                end
                itemDic[itemId] = itemDic[itemId] + equipBreakthroughCfg.ItemCount[index]
            end
        end

        for itemId, itemCount in pairs(itemDic) do
            if not XDataCenter.ItemManager.CheckItemCountById(itemId, itemCount) then
                canBreakThrough = false
            end
            for _, item in pairs(consumeItems) do
                if item.Id == itemId then
                    item.Count = itemCount
                end
            end
        end
        return consumeItems, canBreakThrough
    end

    --获取装备从当前到目标突破次数总消耗货币
    function XEquipManager.GetMutiBreakthroughUseMoney(equipId, targetBreakthrough)
        local costMoney = 0
        local equip = XEquipManager.GetEquip(equipId)
        for i = equip.Breakthrough, targetBreakthrough - 1 do
            costMoney = costMoney + XEquipConfig.GetEquipBreakthroughCfg(equip.TemplateId, i).UseMoney
        end
        return costMoney
    end

    --可消耗对象优先级排序
    local ConsumeSort = function(consumeA, consumeB)
        --提供经验从小到大
        if consumeA.AddExp ~= consumeB.AddExp then
            return consumeA.AddExp < consumeB.AddExp
        end

        --货币消耗从小到大
        if consumeA.CostMoney ~= consumeB.CostMoney then
            return consumeA.CostMoney < consumeB.CostMoney
        end

        --消耗类型（装备优先于道具）
        if consumeA.Type ~= consumeB.Type then
            return consumeA:IsEquip()
        end

        --Id从小到大
        return consumeA.Id < consumeB.Id
    end

    --根据传入的消耗类型字典 返回可消耗物品/装备排序列表
    function XEquipManager.GetMutiLevelUpRecommendItems(equipId, consumeTypeDic)
        local result = {}

        local requireStarDic = {}
        for consumeType, value in pairs(consumeTypeDic) do
            if value then
                if consumeType == 0 then
                    --0代表道具类型
                    local itemIdList = XEquipManager.GetCanEatItemIds(equipId)
                    for _, itemId in pairs(itemIdList) do
                        local obj = XEquipLevelUpConsume.New()
                        obj:InitItem(itemId)
                        tableInsert(result, obj)
                    end
                else
                    --其他数字代表装备星级
                    requireStarDic[consumeType] = true
                end
            end
        end

        local equipIds = XEquipManager.GetRecomendEatEquipIds(equipId, requireStarDic, true, true)
        for _, equipId in pairs(equipIds) do
            local obj = XEquipLevelUpConsume.New()
            obj:InitEquip(equipId)
            tableInsert(result, obj)
        end

        tableSort(result, ConsumeSort)

        return result
    end

    --单突破次数下强化到指定等级
    local function DoSingleLevelUp(templateId, breakthrough, curLevel, curExp, targetLevel, consumes, operations)
        --是否满足升级条件（经验达到目标等级）,消耗总提供经验（考虑溢出）,总消耗货币, 升到指定等级总所需经验,实际可到达等级（考虑所有消耗）
        local tmpCanLevelUp, tmpTotalExp, tmpCostMoney, needExp, canReachLevel = false, 0, 0, 0, 0

        --升级操作记录
        local operation = {
            OperationType = 1,
            UseEquipIdDic = {},
            UseItems = {},
            ConsumeInfoDic = {} --消耗信息字典
        }

        --先计算需要总经验
        for level = curLevel, targetLevel - 1 do
            local levelUpCfg = XEquipConfig.GetLevelUpCfg(templateId, breakthrough, level)
            needExp = needExp + levelUpCfg.Exp
        end
        needExp = needExp - curExp
        --从消耗队列中顺序消耗，直至累积经验达到/超过所需总经验
        for index, consume in ipairs(consumes) do
            local id = consume.Id
            local canEatItemCount = consume:GetLeftCount()

            --检查是否已被操作过
            for _, inOperation in pairs(operations) do
                --上一轮操作已经吃过这个装备
                if inOperation.UseEquipIdDic[id] then
                    goto CONTINUE_ONE
                end
                ----上一轮操作已经吃了部分这个道具
                --if inOperation.UseItems[id] then
                --    canEatItemCount = canEatItemCount - inOperation.UseItems[id]
                --end
            end

            --依次消耗
            for i = 1, canEatItemCount do
                if tmpTotalExp >= needExp then
                    goto CONTINUE_ONE
                end

                consume:Eat()
                tmpTotalExp = tmpTotalExp + consume:GetAddExp()
                tmpCostMoney = tmpCostMoney + consume:GetCostMoney()

                --记录消耗
                local count = 0
                if consume:IsEquip() then
                    count = 1
                    operation.UseEquipIdDic[id] = true
                else
                    count = operation.UseItems[id] or 0
                    count = count + 1
                    operation.UseItems[id] = count
                end
                operation.ConsumeInfoDic[index] = count
            end

            ::CONTINUE_ONE::
        end
        --尝试从消耗队列中顺序去除多余的消耗，直至累积经验刚好满足所需总经验
        for index, consume in ipairs(consumes) do
            local id = consume.Id
            local hasEatItemCount  --本轮强化吃掉的数量

            if consume:IsEquip() then
                --检查本轮是否有吃掉这个装备
                if not operation.UseEquipIdDic[id] then
                    goto CONTINUE_TWO
                end
                hasEatItemCount = 1
            else
                --检查本轮是否有吃掉这个道具
                hasEatItemCount = operation.UseItems[id]
                if not hasEatItemCount then
                    goto CONTINUE_TWO
                end
            end

            --依次去除消耗
            while true do
                if hasEatItemCount < 1 then
                    goto CONTINUE_TWO
                end

                --经验已经满足
                local exp = consume:GetAddExp()
                if tmpTotalExp - exp < needExp then
                    goto CONTINUE_TWO
                end

                consume:Vomit()
                tmpTotalExp = tmpTotalExp - exp
                tmpCostMoney = tmpCostMoney - consume:GetCostMoney()

                --记录去除消耗
                if consume:IsEquip() then
                    hasEatItemCount = 0
                    operation.UseEquipIdDic[consume.Id] = nil
                    operation.ConsumeInfoDic[index] = nil
                else
                    hasEatItemCount = hasEatItemCount - 1
                    operation.UseItems[consume.Id] = hasEatItemCount
                    operation.ConsumeInfoDic[index] = hasEatItemCount
                    if hasEatItemCount < 1 then
                        operation.UseItems[consume.Id] = nil
                        operation.ConsumeInfoDic[index] = nil
                    end
                end
            end

            ::CONTINUE_TWO::
        end

        --是否满足升级条件（经验达到目标等级）
        tmpCanLevelUp = tmpTotalExp >= needExp

        --将本次升级操作插入操作列表
        if needExp > 0 then
            tableInsert(operations, operation)
        end

        return tmpCanLevelUp, tmpTotalExp, tmpCostMoney, needExp
    end

    --根据传入的已排序消耗物品列表，计算出满足目标等级的最终经验及升级消耗（只计算升级消耗，不计算突破）
    function XEquipManager.TryMultiLevelUp(equipId, targetBreakthrough, targetLevel, consumes)
        --是否满足消耗条件, 总经验（包含溢出）, 升级总消耗货币, 实际到达等级, 记录每单次突破下升级消耗操作列表（服务端要求）
        local canLevelUp, totalExp, levelUpCostMoney, realTargetLevel, operations = true, 0, 0, targetLevel, {}

        --重置选择消耗列表
        for _, consume in pairs(consumes) do
            consume:Reset()
        end

        local templateId = GetEquipTemplateId(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        local curLevel = equip.Level
        local curExp = equip.Exp
        local tmpTargeLv, tmpMaxLv
        local curBreakthrough = equip.Breakthrough
        for breakthrough = curBreakthrough, targetBreakthrough do
            tmpMaxLv = XEquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, breakthrough)
            if breakthrough ~= targetBreakthrough then
                tmpTargeLv = tmpMaxLv
            else
                tmpTargeLv = targetLevel
            end
            --遍历时，阶段与装备当前阶段不同，装备的当前经验不参与计算
            if curBreakthrough ~= breakthrough then
                curExp = 0
            end

            local tmpCanLevelUp, tmpTotalExp, tmpCostMoney, needExp =
                DoSingleLevelUp(templateId, breakthrough, curLevel, curExp, tmpTargeLv, consumes, operations)
            if not tmpCanLevelUp then
                canLevelUp = false
            end
            --若不是最终突破次数, 修正总经验至当前突破次数满等级所需经验, 否则检查溢出经验是否足够再次升级
            if tmpTotalExp > needExp then
                if breakthrough == targetBreakthrough then
                    --尝试用溢出经验再次升级
                    local level = tmpTargeLv
                    local overExp = tmpTotalExp - needExp
                    while true do
                        if level == tmpMaxLv then
                            break
                        end
                        local levelUpCfg = XEquipConfig.GetLevelUpCfg(templateId, breakthrough, level)
                        overExp = overExp - levelUpCfg.Exp
                        if overExp < 0 then
                            break
                        end
                        realTargetLevel = realTargetLevel + 1
                        level = level + 1
                    end
                end
            end

            --将本次突破操作插入操作列表
            if breakthrough ~= targetBreakthrough then
                tableInsert(
                    operations,
                    {
                        OperationType = 2,
                        UseEquipIdDic = {},
                        UseItems = {}
                    }
                )
            end

            totalExp = totalExp + tmpTotalExp
            levelUpCostMoney = levelUpCostMoney + tmpCostMoney
            curLevel = 1
            curExp = 0
        end
        totalExp = XMath.ToInt(totalExp)

        --是否满足消耗条件, 总经验（包含溢出）, 升级总消耗货币, 实际到达等级, 记录每单次突破下升级消耗操作列表（服务端要求）
        return canLevelUp, totalExp, levelUpCostMoney, realTargetLevel, operations
    end

    --=============================
    ---@desc:[一键培养] 计算出最大可达到等级单元
    ---@param:equipId 装备id
    ---@param:consumes 升级材料列表
    ---@tips:不采用XEquipManager.GetMultiStrengthenMaxTarget，是因为它直接将满阶段满级作为目标，当材料足够时，可能会出现
    ---      以下情况： 从二段1级升级到二段10级经验满足，但是材料列表的材料单价超过了当前拥有的螺母，导致只能升级到小于10级
    --=============================
    function XEquipManager.GetStrengthenMaxTarget(equipId, consumes)
        local templateId = GetEquipTemplateId(equipId)
        --装备信息
        local equip = XEquipManager.GetEquip(equipId)
        --当前等级单元
        local curLevelUnit = XEquipManager.ConvertToLevelUnit(templateId, equip.Breakthrough, equip.Level)
        --最大突破阶段
        local maxBreakthrough = XDataCenter.EquipManager.GetEquipMaxBreakthrough(templateId)
        --最大突破阶段的最大等级
        local maxLevel = XDataCenter.EquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, maxBreakthrough)
        --最大等级单元
        local maxLevelUnit = XEquipManager.ConvertToLevelUnit(templateId, maxBreakthrough, maxLevel)
        --当前剩余的螺母
        local leftMoney = XDataCenter.ItemManager.GetCoinsNum()
        for levelUnit = curLevelUnit + 1, maxLevelUnit do
            local targetBreakthrough, targetLevel = XDataCenter.EquipManager.ConvertToBreakThroughAndLevel(templateId, levelUnit)
            local canLevelUp, totalExp, levelUpCostMoney, realTargetLevel, operations =
                    XDataCenter.EquipManager.TryMultiLevelUp(equipId, targetBreakthrough, targetLevel, consumes)
            --突破消耗的金币
            local breakthroughCostMoney = XDataCenter.EquipManager.GetMutiBreakthroughUseMoney(equipId, targetBreakthrough)
            local costMoney = breakthroughCostMoney + levelUpCostMoney
            if leftMoney < costMoney then -- 金币不足
                return levelUnit - 1
            end
            if not canLevelUp then  -- 强化素材不足
                return levelUnit - 1
            end
            --突破条件
            local tmpBreakthrough = targetBreakthrough
            if tmpBreakthrough == maxBreakthrough then
                --突破次数达到上限后已经没有条件限制，但策划要求以第一次突破的条件作为默认显示
                tmpBreakthrough = 0
            end
            local passCondition, _ = XDataCenter.EquipManager.CheckBreakthroughCondition(templateId, tmpBreakthrough)
            local _, canBreakThrough = XDataCenter.EquipManager.GetMutiBreakthroughConsumeItems(equipId, targetBreakthrough)
            if not (passCondition and canBreakThrough) then -- 不满足培养条件
                return levelUnit - 1
            end
            if levelUnit == maxLevelUnit then
                return levelUnit -- 达到最大等级
            end
        end
    end

    --根据传入的已排序消耗物品列表，计算出最大可到达等级单元（计算所有条件：突破道具，升级消耗，总货币，突破条件）
    function XEquipManager.GetMultiStrengthenMaxTarget(equipId, consumes)
        --最大可到达突破次数, 最大可到达等级
        local equip = XEquipManager.GetEquip(equipId)
        local maxTargetBreakthrough, maxTargetLevel = equip.Breakthrough, equip.Level
        local templateId = GetEquipTemplateId(equipId)
        local targetBreakthrough = XDataCenter.EquipManager.GetEquipMaxBreakthrough(templateId)
        local targetLevel =
            XDataCenter.EquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, targetBreakthrough)
        --尝试用满突破次数&&满等级作为目标进行升级，获得排序消耗操作队列
        local _, _, _, _, operations =
            XDataCenter.EquipManager.TryMultiLevelUp(equipId, targetBreakthrough, targetLevel, consumes)
        local leftMoney = XDataCenter.ItemManager.GetCoinsNum()
        local tmpTotalExp = 0
        --按照操作队列中顺序依次模拟消耗，直至货币不足/突破道具条件不满足/突破道具不足
        for index, operation in pairs(operations) do
            if operation.OperationType == 1 then
                --强化
                if equip.Breakthrough == maxTargetBreakthrough then
                    tmpTotalExp = equip.Exp
                end

                local consumeIndexList = {}
                for idx in pairs(operation.ConsumeInfoDic) do
                    tableInsert(consumeIndexList, consumes[idx])
                end
                tableSort(
                    consumeIndexList,
                    function(a, b)
                        -- 根据经验值从大到小排序
                        return a:GetAddExp() > b:GetAddExp()
                    end
                )


                -- 经验从大到小排序，在有限的螺母内获取最大的经验值
                for idx, consume in ipairs(consumeIndexList) do
                    local consumeCount = consume.SelectCount -- 选中的数量
                    for i = 1, consumeCount do
                        local tmpLeftMoney = leftMoney - consume:GetCostMoney()
                        if tmpLeftMoney >= 0 then
                            leftMoney = tmpLeftMoney
                            tmpTotalExp = tmpTotalExp + consume:GetAddExp()
                        end
                    end
                end

                ----检查货币消耗，获取最大可获得经验
                --for _, index in ipairs(consumeIndexList) do
                --    local consume = consumes[index]
                --    local consumeCount = operation.ConsumeInfoDic[index]
                --    for i = 1, consumeCount do
                --        leftMoney = leftMoney - consume:GetCostMoney()
                --        if leftMoney < 0 then
                --            goto LEVEL_CALC
                --        end
                --        tmpTotalExp = tmpTotalExp + consume:GetAddExp()
                --    end
                --end



                --计算等级
                ::LEVEL_CALC::
                local levelLimit =
                    XEquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, maxTargetBreakthrough)
                for level = maxTargetLevel, levelLimit - 1 do
                    local levelUpCfg = XEquipConfig.GetLevelUpCfg(templateId, maxTargetBreakthrough, level)
                    tmpTotalExp = tmpTotalExp - levelUpCfg.Exp
                    if tmpTotalExp < 0 then
                        goto RESULT
                    end
                    maxTargetLevel = maxTargetLevel + 1
                end

                --本轮操作结束后重置等级/经验
                tmpTotalExp = 0 --不保留溢出经验
            else
                --突破
                local targetBreakthrough = maxTargetBreakthrough + 1

                --突破条件不满足
                if not XEquipManager.CheckBreakthroughCondition(templateId, targetBreakthrough) then
                    goto RESULT
                end

                --突破道具不足
                local _, canBreakThrough =
                    XDataCenter.EquipManager.GetMutiBreakthroughConsumeItems(equipId, targetBreakthrough)
                if not canBreakThrough then
                    goto RESULT
                end

                --货币不足
                local breakthroughCostMoney = XEquipConfig.GetEquipBreakthroughCfg(equip.TemplateId, maxTargetBreakthrough).UseMoney
                leftMoney = leftMoney - breakthroughCostMoney
                if leftMoney < 0 then
                    goto RESULT
                end

                maxTargetBreakthrough = targetBreakthrough

                --本轮操作结束后重置等级/经验
                maxTargetLevel = 1 --等级重置为1级
            end
        end

        --最大可到达突破次数, 最大可到达等级
        ::RESULT::
        return XEquipManager.ConvertToLevelUnit(templateId, maxTargetBreakthrough, maxTargetLevel)
    end

    --消耗列表展示排序
    local consumeShowSort = function(consumeA, consumeB)
        --道具显示在前，装备显示在后
        if consumeA.Type ~= consumeB.Type then
            return consumeA:IsItem()
        end

        --品质
        local quality1 = consumeA:GetQuality()
        local quality2 = consumeB:GetQuality()
        if quality1 ~= quality2 then
            return quality1 > quality2
        end

        --星级
        local aStar = consumeA:GetStar()
        local bStar = consumeB:GetStar()
        if aStar ~= bStar then
            return aStar > bStar
        end

        --等级
        local aLevel = consumeA:GetLevel()
        local bLevel = consumeB:GetLevel()
        if aLevel ~= bLevel then
            return aLevel > bLevel
        end

        --优先级
        local priority1 = consumeA:GetPriority()
        local priority2 = consumeB:GetPriority()
        if priority1 ~= priority2 then
            return priority1 > priority2
        end

        --TemplateId
        return consumeA.TemplateId > consumeB.TemplateId
    end

    --获取排序后的消耗列表
    function XEquipManager.GetSortedConsumes(consumes)
        local result = {}

        for _, consume in pairs(consumes) do
            if consume:IsSelect() then
                tableInsert(result, consume)
            end
        end

        tableSort(result, consumeShowSort)

        return result
    end
    --endregion

    --region---------------------------------EquipSignboard--------------------------------
    function XEquipManager.GetEquipAnimControllerBySignboard(characterId, fashionId, actionId)
        return XEquipConfig.GetEquipAnimControllerBySignboard(characterId, fashionId, actionId)
    end

    function XEquipManager.CheckHasLoadEquipBySignboard(characterId, fashionId, actionId)
        return XEquipConfig.CheckHasLoadEquipBySignboard(characterId, fashionId, actionId)
    end
    --endregion

    --#region 武器超限
    -- 检测超限引导
    function XEquipManager.CheckOverrunGuide(weaponId)
        -- debug模式下，禁用引导时不播放
        if XMain.IsDebug then
            local isGuideDisable = XDataCenter.GuideManager.CheckFuncDisable()
            if isGuideDisable then
                return
            end
        end

        -- 功能未开启
        local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun)
        if not isOpen then
            return
        end

        -- 装备不可超限
        local equip = XEquipManager.GetEquip(weaponId)
        local canOverrun = XEquipConfig.CanOverrunByTemplateId(equip.TemplateId)
        if not canOverrun then
            return
        end

        -- 播放引导，已播过会跳过
        local guideId = CS.XGame.ClientConfig:GetInt("EquipOverrunGuideId")
        if guideId ~= 0 then
            local guide = XGuideConfig.GetGuideGroupTemplatesById(guideId)
            local isFinish = XDataCenter.GuideManager.CheckIsGuide(guideId)
            local isGuiding = XDataCenter.GuideManager.CheckIsInGuide()
            if not isFinish and not isGuiding then
                XDataCenter.GuideManager.TryActiveGuide(guide)
            end
        end
    end
    --#endregion 武器超限

    -----------------------------------------Getter End------------------------------------
    XEquipManager.GetEquipTemplateId = GetEquipTemplateId

    return XEquipManager
end