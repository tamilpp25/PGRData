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

    local XEquipManager = {}
    local Equips = {}   -- 装备数据
    local WeaponTypeCheckDic = {}
    local AwarenessTypeCheckDic = {}
    local OverLimitTexts = {}
    local AwarenessSuitPrefabInfoList = {}     --意识组合预设
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
    function XEquipManager.InitEquipData(equipsData)
        for _, equip in pairs(equipsData) do
            Equips[equip.Id] = XEquipManager.NewEquip(equip)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_DATA_INIT_NOTIFY)
    end

    function XEquipManager.NewEquip(protoData)
        return XEquip.New(protoData)
    end

    function XEquipManager.NotifyEquipDataList(data)
        local syncList = data.EquipDataList
        if not syncList then
            return
        end

        for _, equip in pairs(syncList) do
            XEquipManager.OnSyncEquip(equip)
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_DATA_LIST_UPDATE_NOTYFY)
    end

    function XEquipManager.NotifyEquipChipGroupList(data)
        AwarenessSuitPrefabInfoList = {}
        local chipGroupDataList = data.ChipGroupDataList
        for _, chipGroupData in ipairs(chipGroupDataList) do
            tableInsert(AwarenessSuitPrefabInfoList, XEquipSuitPrefab.New(chipGroupData))
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
    end

    function XEquipManager.OnSyncEquip(protoData)
        local equip = Equips[protoData.Id]
        if not equip then
            equip = XEquipManager.NewEquip(protoData)
            Equips[protoData.Id] = equip

            -- local templateId = protoData.TemplateId
            -- if XEquipManager.CheckFirstGet(templateId) then
            --     XUiHelper.PushInFirstGetIdList(templateId, XArrangeConfigs.Types.Weapon)
            -- end
        else
            equip:SyncData(protoData)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_DATA_CHANGE_NOTIFY, equip)
    end

    function XEquipManager.DeleteEquip(equipProtoId)
        Equips[equipProtoId] = nil
    end

    function XEquipManager.GetEquip(equipId)
        local equip = Equips[equipId]
        if not equip then
            XLog.Error("XEquipManager.GetEquip错误, 无法根据equipId: " .. equipId .. "从服务端返回的装备列表中获得数据")
            return
        end
        return equip
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
            [XEquipConfig.UserType.Normal] = 3,
        }
        tableSort(suitIds, function(lSuitID, rSuitID)
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
        end)

        tableInsert(suitIds, 1, XEquipConfig.DEFAULT_SUIT_ID.Normal)
        tableInsert(suitIds, 2, XEquipConfig.DEFAULT_SUIT_ID.Isomer)

        return suitIds
    end

    function XEquipManager.GetDecomposeRewardEquipCount(equipId)
        local weaponCount, awarenessCount = 0, 0

        local rewards = XEquipManager.GetDecomposeRewards({ equipId })
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
        XTool.LoopCollection(equipIds, function(equipId)
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
        end)

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
        if not index then return end
        tableRemove(AwarenessSuitPrefabInfoList, index)
    end

    function XEquipManager.GetUnSavedSuitPrefabInfo(characterId)
        local equipGroupData = {
            Name = "",
            ChipIdList = XEquipManager.GetCharacterWearingAwarenessIds(characterId),
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

        tableSort(equipIdList, function(aId, bId)
            --强制优先插入装备中排序
            local aWearing = XEquipManager.IsWearing(aId) and 1 or 0
            local bWearing = XEquipManager.IsWearing(bId) and 1 or 0
            if aWearing ~= bWearing then
                return aWearing < bWearing
            end

            return sortFunc(aId, bId)
        end)
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
            None = 3, --无共鸣
        }
        local resonanceTypeToEquipIdsDic = {
            [ResonanceType.CurCharacter] = {},
            [ResonanceType.Others] = {},
            [ResonanceType.None] = {},
        }

        local characterType = XCharacterConfigs.GetCharacterType(characterId)
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
    function XEquipManager.PutOn(characterId, equipId)
        if not XDataCenter.CharacterManager.IsOwnCharacter(characterId) then
            XUiManager.TipText("EquipPutOnNotChar")
            return
        end

        local equipSpecialCharacterId = XEquipManager.GetEquipSpecialCharacterId(equipId)
        if equipSpecialCharacterId and equipSpecialCharacterId ~= characterId then
            local char = XDataCenter.CharacterManager.GetCharacter(equipSpecialCharacterId)
            if char then
                local characterName = XCharacterConfigs.GetCharacterName(equipSpecialCharacterId)
                local gradeName = XCharacterConfigs.GetCharGradeName(equipSpecialCharacterId, char.Grade)
                XUiManager.TipMsg(CSXTextManagerGetText("EquipPutOnSpecialCharacterIdNotEqual", characterName, gradeName))
            end
            return
        end

        local characterEquipType = XCharacterConfigs.GetCharacterEquipType(characterId)
        if not XEquipManager.IsTypeEqual(equipId, characterEquipType) then
            XUiManager.TipText("EquipPutOnEquipTypeError")
            return
        end

        local req = { CharacterId = characterId, Site = XEquipManager.GetEquipSite(equipId), EquipId = equipId }
        XNetwork.Call("EquipPutOnRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local equipSite = XEquipManager.GetEquipSite(equipId)
            local oldEquipId = XEquipManager.GetWearingEquipIdBySite(characterId, equipSite)
            if oldEquipId and oldEquipId ~= 0 then
                local oldEquip = XEquipManager.GetEquip(oldEquipId)
                if XEquipManager.IsWeapon(oldEquipId) then
                    local switchCharacterId = XEquipManager.GetEquipWearingCharacterId(equipId)
                    oldEquip:PutOn(switchCharacterId)
                else
                    oldEquip:TakeOff()
                end
            end

            local equip = XEquipManager.GetEquip(equipId)
            equip:PutOn(characterId)

            XEquipManager.TipEquipOperation(nil, CSXTextManagerGetText("EquipPutOnSuc"))

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_PUTON_NOTYFY, equipId)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_PUTON_NOTYFY, equipId)

            if XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Weapon) then
                XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_PUTON_WEAPON_NOTYFY, characterId, equipId)
            end
        end)
    end

    function XEquipManager.TakeOff(equipIds)
        if not equipIds or not next(equipIds) then
            XLog.Error("XEquipManager.TakeOff错误, 参数equipIds不能为为空")
            return
        end

        for _, equipId in pairs(equipIds) do
            if not XEquipManager.IsWearing(equipId) then
                XUiManager.TipText("EquipTakeOffNotChar")
                return
            end
        end

        local req = { EquipIds = equipIds }
        XNetwork.Call("EquipTakeOffRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XEquipManager.TipEquipOperation(nil, CSXTextManagerGetText("EquipTakeOffSuc"))

            for _, equipId in pairs(equipIds) do
                local equip = XEquipManager.GetEquip(equipId)
                equip:TakeOff()
                XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_TAKEOFF_NOTYFY, equipId)
            end

            XEventManager.DispatchEvent(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, equipIds)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, equipIds)
        end)
    end

    function XEquipManager.SetLock(equipId, isLock)
        if not equipId then
            XLog.Error("XEquipManager.SetLock错误: 参数equipId不能为空")
            return
        end

        local req = { EquipId = equipId, IsLock = isLock }
        XNetwork.Call("EquipUpdateLockRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local equip = XEquipManager.GetEquip(equipId)
            equip:SetLock(isLock)

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY, equipId, isLock)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY, equipId, isLock)
        end)
    end

    function XEquipManager.LevelUp(equipId, equipIdCheckList, useItemDic, callBackBeforeEvent)
        if not equipId then
            XLog.Error("XEquipManager.LevelUp错误: 参数equipId不能为空")
            return
        end

        if XEquipManager.IsMaxLevel(equipId) then
            XUiManager.TipText("EquipLevelUpMaxLevel")
            return
        end

        local costEmpty = true
        local costMoney = 0
        if equipIdCheckList and next(equipIdCheckList) then
            costEmpty = nil
            costMoney = costMoney + XEquipManager.GetEatEquipsCostMoney(equipIdCheckList)
        end

        if useItemDic and next(useItemDic) then
            costEmpty = nil
            costMoney = costMoney + XEquipManager.GetEatItemsCostMoney(useItemDic)
            XMessagePack.MarkAsTable(useItemDic)
        end

        if costEmpty then
            XUiManager.TipText("EquipLevelUpItemEmpty")
            return
        end

        if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.Coin, costMoney, 1, function()
            XEquipManager.LevelUp(equipId, equipIdCheckList, useItemDic, callBackBeforeEvent)
        end, "EquipBreakCoinNotEnough") then
            return
        end

        local useEquipIdList = {}
        local containPrecious = false
        local canNotAutoEatStar = XEquipConfig.CAN_NOT_AUTO_EAT_STAR
        for tmpEquipId in pairs(equipIdCheckList) do
            containPrecious = containPrecious or XEquipManager.GetEquipStar(GetEquipTemplateId(tmpEquipId)) >= canNotAutoEatStar
            tableInsert(useEquipIdList, tmpEquipId)
        end

        local req = { EquipId = equipId, UseEquipIdList = useEquipIdList, UseItems = useItemDic }
        local callFunc = function()
            XNetwork.Call("EquipLevelUpRequest", req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                for _, id in pairs(useEquipIdList) do
                    XEquipManager.DeleteEquip(id)
                end

                local equip = XEquipManager.GetEquip(equipId)
                equip:SetLevel(res.Level)
                equip:SetExp(res.Exp)

                local closeCb
                if XEquipManager.CanBreakThrough(equipId) then
                    closeCb = function()
                        XEquipManager.TipEquipOperation(equipId, nil, nil, true)
                    end
                end
                XEquipManager.TipEquipOperation(nil, CSXTextManagerGetText("EquipStrengthenSuc"), closeCb, true)

                if callBackBeforeEvent then callBackBeforeEvent() end
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, equipId)
                XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, equipId)
            end)
        end

        if containPrecious then
            local title = CSXTextManagerGetText("EquipStrengthenPreciousTipTitle")
            local content = CSXTextManagerGetText("EquipStrengthenPreciousTipContent")
            XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
        else
            callFunc()
        end
    end

    function XEquipManager.Breakthrough(equipId)
        if not equipId then
            XLog.Error("XEquipManager.Breakthrough错误: 参数equipId不能为空")
            return
        end

        if XEquipManager.IsMaxBreakthrough(equipId) then
            XUiManager.TipText("EquipBreakMax")
            return
        end

        if not XEquipManager.IsReachBreakthroughLevel(equipId) then
            XUiManager.TipText("EquipBreakMinLevel")
            return
        end

        local consumeItems = XEquipManager.GetBreakthroughConsumeItems(equipId)
        if not XDataCenter.ItemManager.CheckItemsCount(consumeItems) then
            XUiManager.TipText("EquipBreakItemNotEnough")
            return
        end

        if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XEquipManager.GetBreakthroughUseItemId(equipId),
        XEquipManager.GetBreakthroughUseMoney(equipId),
        1,
        function()
            XEquipManager.Breakthrough(equipId)
        end,
        "EquipBreakCoinNotEnough") then
            return
        end

        local title = CSXTextManagerGetText("EquipBreakthroughConfirmTiltle")
        local content = CSXTextManagerGetText("EquipBreakthroughConfirmContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
            XNetwork.Call("EquipBreakthroughRequest", { EquipId = equipId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local equip = XEquipManager.GetEquip(equipId)
                equip:BreakthroughOneTime()

                CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, equipId)
                XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, equipId)
            end)
        end)
    end

    function XEquipManager.AwarenessTransform(suitId, site, usedIdList, cb)
        if not suitId then
            XLog.Error("XEquipManager.SetLock错误: 参数suitId不能为空")
            return
        end

        local req = { SuitId = suitId, Site = site, UseIdList = usedIdList }
        XNetwork.Call("EquipTransformChipRequest", req, function(res)
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
        end)
    end

    -- 服务端接口begin
    function XEquipManager.Resonance(equipId, slot, characterId, useEquipId, useItemId, selectSkillId, equipResonanceType)
        if useEquipId and XEquipManager.IsLock(useEquipId) then
            XUiManager.TipText("EquipIsLock")
            return
        end

        if characterId and not XDataCenter.CharacterManager.IsOwnCharacter(characterId) then
            XUiManager.TipText("EquipResonanceNotOwnCharacter")
            return
        end

        local callFunc = function()
            local req = {
                EquipId = equipId,
                Slot = slot,
                CharacterId = characterId,
                UseEquipId = useEquipId,
                UseItemId = useItemId,
                SelectSkillId = selectSkillId,
                SelectType = equipResonanceType,
            }
            XNetwork.Call("EquipResonanceRequest", req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if useEquipId then
                    XEquipManager.DeleteEquip(useEquipId)
                end

                local equip = XEquipManager.GetEquip(equipId)
                if XDataCenter.EquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Weapon) then
                    equip:Resonance(res.ResonanceData, selectSkillId ~= nil)
                else
                    equip:Resonance(res.ResonanceData)
                end

                --5星及以上的装备（包括武器、意识）共鸣操作成功之后，将该装备自动上锁
                if XEquipManager.CanResonance(equipId) then
                    equip:SetLock(true)
                end

                CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_RESONANCE_NOTYFY, equipId, slot)
                XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_RESONANCE_NOTYFY, equipId)
            end)
        end

        local containPreciousConfirmFunc = function()
            local containPrecious = useEquipId and XEquipManager.GetEquipStar(GetEquipTemplateId(useEquipId)) >= XEquipConfig.CAN_NOT_AUTO_EAT_STAR
            if containPrecious then
                local title = CSXTextManagerGetText("EquipResonancePreciousTipTitle")
                local content = CSXTextManagerGetText("EquipResonancePreciousTipContent")
                XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
            else
                callFunc()
            end
        end

        containPreciousConfirmFunc()
    end

    function XEquipManager.ResonanceConfirm(equipId, slot, isUse)
        local req = { EquipId = equipId, Slot = slot, IsUse = isUse }
        XNetwork.Call("EquipResonanceConfirmRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local equip = XEquipManager.GetEquip(equipId)
            equip:ResonanceConfirm(slot, isUse)

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY, equipId, slot)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_RESONANCE_ACK_NOTYFY, equipId)
        end)
    end

    function XEquipManager.Awake(equipId, slot, costType)
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipAwake) then
            return
        end

        XNetwork.Call("EquipAwakeRequest",
        {
            EquipId = equipId,
            Slot = slot,
            CostType = costType,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local equip = XEquipManager.GetEquip(equipId)
            equip:SetAwake(slot)

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_AWAKE_NOTYFY, equipId, slot)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_AWAKE_NOTYFY, equipId)
        end)
    end

    function XEquipManager.EquipDecompose(equipIds, cb)
        local req = { EquipIds = equipIds }
        XNetwork.Call("EquipDecomposeRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local rewardGoodsList = res.RewardGoodsList
            for _, id in pairs(equipIds) do
                XEquipManager.DeleteEquip(id)
            end

            if cb then cb(rewardGoodsList) end
        end)
    end

    --characterId:专属组合角色Id，通用组合为0
    function XEquipManager.EquipSuitPrefabSave(suitPrefabInfo, characterId)
        if not suitPrefabInfo then return end

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
            CharacterId = characterId,
        }
        XNetwork.Call("EquipAddChipGroupRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XEquipManager.SaveSuitPrefabInfo(res.ChipGroupData)
            XUiManager.TipText("EquipSuitPrefabSaveSuc")
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
        end)
    end

    function XEquipManager.EquipSuitPrefabEquip(prefabIndex, characterId, afterCheckCb)
        if not characterId then return end
        local suitPrefabInfo = XEquipManager.GetSuitPrefabInfo(prefabIndex)
        if not suitPrefabInfo then return end

        local oldEquipSiteToIdDic = {}
        local oldEquipIds = XEquipManager.GetCharacterWearingAwarenessIds(characterId)
        for _, equipId in pairs(oldEquipIds) do
            local equipSite = XEquipManager.GetEquipSite(equipId)
            oldEquipSiteToIdDic[equipSite] = equipId
        end

        local isDifferent = false
        local newEquipSiteToIdDic = {}
        local newEquipIds = suitPrefabInfo:GetEquipIds()
        local newEquipIdDic = {}
        for _, equipId in pairs(newEquipIds) do
            local equipSpecialCharacterId = XEquipManager.GetEquipSpecialCharacterId(equipId)
            if equipSpecialCharacterId and equipSpecialCharacterId ~= characterId then
                local char = XDataCenter.CharacterManager.GetCharacter(equipSpecialCharacterId)
                local characterName = XCharacterConfigs.GetCharacterName(equipSpecialCharacterId)
                local gradeName = XCharacterConfigs.GetCharGradeName(equipSpecialCharacterId, char.Grade)
                XUiManager.TipMsg(CSXTextManagerGetText("EquipPutOnSpecialCharacterIdNotEqual", characterName, gradeName))
                return
            end

            local equipSite = XEquipManager.GetEquipSite(equipId)
            newEquipSiteToIdDic[equipSite] = equipId
            newEquipIdDic[equipId] = true
            if oldEquipSiteToIdDic[equipSite] ~= equipId then
                isDifferent = true
            end
        end

        for _, oldequipId in pairs(oldEquipIds) do
            if not newEquipIdDic[oldequipId] then
                isDifferent = true
            end
        end

        if not isDifferent then
            XUiManager.TipText("EquipSuitPrefabEquipSame")
            return
        end

        local req = { CharacterId = characterId, GroupId = suitPrefabInfo:GetGroupId() }
        XNetwork.Call("EquipPutOnChipGroupRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            for _, equipId in pairs(oldEquipIds) do
                local equip = XEquipManager.GetEquip(equipId)
                equip:TakeOff()
            end

            for _, equipId in pairs(newEquipIds) do
                local equip = XEquipManager.GetEquip(equipId)
                equip:PutOn(characterId)
            end

            local equipIds = {}
            for _, equipSite in pairs(XEquipConfig.EquipSite.Awareness) do
                local equipId = oldEquipSiteToIdDic[equipSite] or newEquipSiteToIdDic[equipSite]
                if equipId then
                    tableInsert(equipIds, equipId)
                end
            end

            XUiManager.TipText("EquipSuitPrefabEquipSuc")
            if afterCheckCb then afterCheckCb() end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, equipIds)
            XEventManager.DispatchEvent(XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY, equipIds)
        end)
    end

    function XEquipManager.EquipSuitPrefabDelete(prefabIndex)
        local suitPrefabInfo = XEquipManager.GetSuitPrefabInfo(prefabIndex)
        if not suitPrefabInfo then return end

        local req = { GroupId = suitPrefabInfo:GetGroupId() }
        XNetwork.Call("EquipDeleteChipGroupRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XEquipManager.DeleteSuitPrefabInfo(prefabIndex)
            XUiManager.TipText("EquipSuitPrefabDeleteSuc")
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
        end)
    end

    function XEquipManager.EquipSuitPrefabRename(prefabIndex, newName)
        local suitPrefabInfo = XEquipManager.GetSuitPrefabInfo(prefabIndex)
        if not suitPrefabInfo then return end

        local equipGroupData = {
            GroupId = suitPrefabInfo:GetGroupId(),
            Name = newName,
            ChipIdList = suitPrefabInfo:GetEquipIds(),
            CharacterId = suitPrefabInfo:GetCharacterId(),
        }
        local req = { GroupData = equipGroupData }

        XNetwork.Call("EquipUpdateChipGroupRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            suitPrefabInfo:UpdateData(equipGroupData)
            XUiManager.TipText("EquipSuitPrefabRenameSuc")
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SUIT_PREFAB_DATA_UPDATE_NOTIFY)
        end)
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
        if not equipId then return false end
        local equip = XEquipManager.GetEquip(equipId)
        return equip and equip.CharacterId and equip.CharacterId > 0
    end

    function XEquipManager.IsInSuitPrefab(equipId)
        if not equipId then return false end
        local suitPrefabList = GetSuitPrefabInfoList()
        for _, suitPrefabInfo in pairs(suitPrefabList) do
            if suitPrefabInfo:IsEquipIn(equipId) then
                return true
            end
        end
        return false
    end

    function XEquipManager.IsLock(equipId)
        if not equipId then return false end
        local equip = XEquipManager.GetEquip(equipId)
        return equip and equip.IsLock
    end

    function XEquipManager.IsMaxLevel(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return equip.Level >= XEquipManager.GetBreakthroughLevelLimit(equipId)
    end

    function XEquipManager.IsMaxLevelByTemplateId(templateId, breakThrough, level)
        return level >= XEquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, breakThrough)
    end

    function XEquipManager.IsMaxBreakthrough(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        local equipBorderCfg = GetEquipBorderCfg(equipId)
        return equip.Breakthrough >= equipBorderCfg.MaxBreakthrough
    end

    function XEquipManager.IsReachBreakthroughLevel(equipId)
        local equip = XEquipManager.GetEquip(equipId)
        return equip.Level >= XEquipManager.GetBreakthroughLevelLimit(equipId)
    end

    function XEquipManager.IsCanBeGift(equipId)--是否能作为师徒系统的礼物
        local IsNotWearing = not XEquipManager.IsWearing(equipId)
        local IsNotInSuit = not XEquipManager.IsInSuitPrefab(equipId)
        local IsUnLock = not XEquipManager.IsLock(equipId)
        local templateId = GetEquipTemplateId(equipId)
        local IsCanGive = not XMentorSystemConfigs.IsCanNotGiveWafer(templateId)
        local equip = XEquipManager.GetEquip(equipId)
        local resonanCecount = XEquipManager.GetResonanceCount(equipId)
        local breakthrough = equip and equip.Breakthrough or 0
        local level = equip and equip.Level or 1

        return IsNotWearing and IsNotInSuit and IsUnLock and IsCanGive and resonanCecount == 0 and level == 1 and breakthrough == 0
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
        local isReachBreakthroughLevel = level >= XEquipManager.GetBreakthroughLevelLimitByTemplateId(templateId, breakThrough)
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
        return equip and not XTool.IsTableEmpty(equip.ResonanceInfo) or not XTool.IsTableEmpty(equip.UnconfirmedResonanceInfo)
    end

    function XEquipManager.CheckEquipStarCanAwake(equipId)
        local templateId = GetEquipTemplateId(equipId)
        local star = XEquipManager.GetEquipStar(templateId)
        if star < XEquipConfig.GetMinAwakeStar() then
            return false
        end
        return true
    end

    function XEquipManager.CheckEquipCanAwake(equipId)
        if not XEquipManager.CheckEquipStarCanAwake(equipId) then
            return false
        end

        local templateId = GetEquipTemplateId(equipId)
        local maxLevel = XEquipManager.GetEquipMaxLevel(templateId)
        local equip = XEquipManager.GetEquip(equipId)
        if equip.Level ~= maxLevel then
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

    function XEquipManager.IsEquipPosAwaken(equipId, pos)
        local equip = XEquipManager.GetEquip(equipId)
        return equip:IsEquipPosAwaken(pos)
    end

    function XEquipManager.CheckEquipPosUnconfirmedResonanced(equipId, pos)
        local equip = XEquipManager.GetEquip(equipId)
        return equip.UnconfirmedResonanceInfo and equip.UnconfirmedResonanceInfo[pos]
    end

    function XEquipManager.CheckFirstGet(templateId)
        local needFirstShow = XEquipConfig.GetNeedFirstShow(templateId)
        if not needFirstShow or needFirstShow == 0 then return false end

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
    function XEquipManager.IsEquipRecomendedToBeEat(strengthenEquipId, equipId)
        if not equipId then return false end
        local equip = XEquipManager.GetEquip(equipId)
        local canNotAutoEatStar = XEquipConfig.CAN_NOT_AUTO_EAT_STAR
        local equipClassify = XEquipManager.GetEquipClassify(strengthenEquipId)

        if XEquipManager.GetEquipClassify(equipId) == equipClassify --武器吃武器，意识吃意识
        and not XEquipManager.IsWearing(equipId)     --不能吃穿戴中
        and not XEquipManager.IsInSuitPrefab(equipId)    --不能吃预设中
        and not XEquipManager.IsLock(equipId)      --不能吃上锁中
        and XEquipManager.GetEquipStar(equip.TemplateId) < canNotAutoEatStar    --不自动吃大于该星级的装备
        and equip.Breakthrough == 0     --不吃突破过的
        and equip.Level == 1 and equip.Exp == 0     --不吃强化过的
        and not equip.ResonanceInfo and not equip.UnconfirmedResonanceInfo  --不吃共鸣过的
        then
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
                tableInsert(equipAttrMap, {
                    AttrIndex = attrIndex,
                    Name = XAttribManager.GetAttribNameByIndex(attrIndex),
                    Value = value or 0,
                })
            end
        end

        return equipAttrMap
    end

    function XEquipManager.GetEquipAttrMap(equipId, preLevel)
        local attrMap = {}

        if not equipId then
            return attrMap
        end
        local equip = XEquipManager.GetEquip(equipId)
        local attrs = XFightEquipManager.GetEquipAttribs(equip, preLevel)
        attrMap = ConstructEquipAttrMap(attrs)

        return attrMap
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
            Level = 1,
        }
        local attrs = XFightEquipManager.GetEquipAttribs(equipData, preLevel)
        return ConstructEquipAttrMap(attrs)
    end

    function XEquipManager.ConstructTemplateEquipAttrMap(templateId, breakthroughTimes, level)
        local equipData = {
            TemplateId = templateId,
            Breakthrough = breakthroughTimes,
            Level = level,
        }
        local attrs = XFightEquipManager.GetEquipAttribs(equipData)
        return ConstructEquipAttrMap(attrs)
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
            if equip.CharacterId == characterId and
            XEquipManager.IsWearing(equip.Id) and
            XEquipManager.IsClassifyEqual(equip.Id, XEquipConfig.Classify.Weapon) then
                return equip.Id
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

    --desc: 获取符合当前角色使用类型的所有武器equipId
    function XEquipManager.GetCanUseWeaponIds(characterId)
        local weaponIds = {}
        local requireEquipType = XCharacterConfigs.GetCharacterEquipType(characterId)
        for k, v in pairs(Equips) do
            if XEquipManager.IsClassifyEqual(v.Id, XEquipConfig.Classify.Weapon) and XEquipManager.IsTypeEqual(v.Id, requireEquipType) then
                tableInsert(weaponIds, k)
            end
        end
        return weaponIds
    end

    --desc: 获取符合当前角色使用类型的所有武器templateId
    function XEquipManager.GetCanUseWeaponTemplateIds(characterId)
        local weaponTemplateIds = {}
        local requireEquipType = XCharacterConfigs.GetCharacterEquipType(characterId)
        local equipTemplates = XEquipConfig.GetEquipTemplates()
        for _, v in pairs(equipTemplates) do
            if XEquipManager.IsClassifyEqualByTemplateId(v.Id, XEquipConfig.Classify.Weapon) and v.Type == requireEquipType then
                tableInsert(weaponTemplateIds, v.Id)
            end
        end
        return weaponTemplateIds
    end

    --desc: 获取符合当前武器使用角色的所有templateId
    function XEquipManager.GetWeaponUserTemplateIds(weaponTemplateIds)
        local characters = XCharacterConfigs.GetCharacterTemplates()
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
            if XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Awareness)
            and (not characterType or XEquipManager.IsCharacterTypeFit(equipId, characterType)) then
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
            if v.Id ~= equipId and XEquipManager.IsClassifyEqual(v.Id, XEquipConfig.Classify.Weapon)
            and not XEquipManager.IsWearing(v.Id) and not XEquipManager.IsLock(v.Id) then
                tableInsert(weaponIds, k)
            end
        end
        tableSort(weaponIds, CanEatEquipSort)
        return weaponIds
    end

    local function GetCanEatAwarenessIds(equipId)
        local awarenessIds = {}
        for k, v in pairs(Equips) do
            if v.Id ~= equipId and XEquipManager.IsClassifyEqual(v.Id, XEquipConfig.Classify.Awareness)
            and not XEquipManager.IsWearing(v.Id) and not XEquipManager.IsInSuitPrefab(v.Id) and not XEquipManager.IsLock(v.Id) then
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

    function XEquipManager.GetRecomendEatEquipIds(equipId)
        local equipIds = {}

        for _, v in pairs(Equips) do
            local tmpEquipId = v.Id
            if tmpEquipId ~= equipId    --不能吃自己
            and XEquipManager.IsEquipRecomendedToBeEat(equipId, tmpEquipId)
            then
                tableInsert(equipIds, tmpEquipId)
            end
        end
        tableSort(equipIds, CanEatEquipSort)

        return equipIds
    end

    function XEquipManager.GetCanDecomposeWeaponIds()
        local weaponIds = {}
        for k, v in pairs(Equips) do
            if XEquipManager.IsClassifyEqual(v.Id, XEquipConfig.Classify.Weapon)
            and not XEquipManager.IsWearing(v.Id) and not XEquipManager.IsLock(v.Id) then
                tableInsert(weaponIds, k)
            end
        end
        return weaponIds
    end

    function XEquipManager.GetCanDecomposeAwarenessIdsBySuitId(suitId)
        local awarenessIds = {}

        local equipIds = XEquipManager.GetEquipIdsBySuitId(suitId)
        for _, v in pairs(equipIds) do
            if XEquipManager.IsClassifyEqual(v, XEquipConfig.Classify.Awareness)
            and not XEquipManager.IsWearing(v) and not XEquipManager.IsInSuitPrefab(v) and not XEquipManager.IsLock(v) then
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
        if not XEquipConfig.CheckTemplateIdIsEquip(templateId) then return end
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
        if equip.Breakthrough == 0 then return end
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
        if XEquipConfig.IsDefaultSuitId(suitId) then return "" end
        local suitCfg = XEquipConfig.GetEquipSuitCfg(suitId)
        return suitCfg.Name
    end

    function XEquipManager.GetSuitDescription(suitId)
        if XEquipConfig.IsDefaultSuitId(suitId) then return "" end
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
        if XEquipConfig.IsDefaultSuitId(suitId) then return 0 end
        local templateId = GetSuitPresentEquipTemplateId(suitId)
        return XEquipManager.GetEquipStar(templateId)
    end

    function XEquipManager.GetSuitQualityIcon(suitId)
        if XEquipConfig.IsDefaultSuitId(suitId) then return end
        local templateId = GetSuitPresentEquipTemplateId(suitId)
        return XEquipManager.GetEquipBgPath(templateId)
    end

    function XEquipManager.GetCharacterWearingSuitMergeActiveSkillDesInfoList(characterId)
        local wearingAwarenessIds = XEquipManager.GetCharacterWearingAwarenessIds(characterId)
        return XEquipManager.GetSuitMergeActiveSkillDesInfoList(wearingAwarenessIds)
    end

    function XEquipManager.GetSuitMergeActiveSkillDesInfoList(wearingAwarenessIds)
        local skillDesInfoList = {}

        local suitIdSet = {}
        for _, equipId in pairs(wearingAwarenessIds) do
            local suitId = XEquipManager.GetSuitId(equipId)
            if suitId > 0 then
                local count = suitIdSet[suitId]
                suitIdSet[suitId] = count and count + 1 or 1
            end
        end

        for suitId, count in pairs(suitIdSet) do
            local activeskillDesList = XEquipManager.GetSuitActiveSkillDesList(suitId, count)
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

    function XEquipManager.GetSuitActiveSkillDesList(suitId, count)
        local activeskillDesList = {}

        local skillDesList = XEquipManager.GetSuitSkillDesList(suitId)
        if skillDesList[2] then
            tableInsert(activeskillDesList, {
                SkillDes = skillDesList[2] or "",
                PosDes = CSXTextManagerGetText("EquipSuitSkillPrefix2"),
                IsActive = count and count >= 2
            })
        end
        if skillDesList[4] then
            tableInsert(activeskillDesList, {
                SkillDes = skillDesList[4] or "",
                PosDes = CSXTextManagerGetText("EquipSuitSkillPrefix4"),
                IsActive = count and count >= 4
            })
        end
        if skillDesList[6] then
            tableInsert(activeskillDesList, {
                SkillDes = skillDesList[6] or "",
                PosDes = CSXTextManagerGetText("EquipSuitSkillPrefix6"),
                IsActive = count and count >= 6
            })
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
            resonanceCount = equip.ResonanceInfo and (equip.ResonanceInfo.Count or XTool.GetTableCount(equip.ResonanceInfo)) or 0
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
        local modelId = XEquipConfig.GetWeaponResonanceModelId(XEquipConfig.WeaponCase.Case1, template.Id, resonanceCount)
        modelCfg.ModelId = modelId
        modelCfg.TransformConfig = XEquipConfig.GetEquipModelTransformCfg(templateId, uiName, resonanceCount)
        return modelCfg
    end

    -- 获取装备模型id列表
    function XEquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
        local idList = {}
        local template = XEquipConfig.GetEquipResCfg(equip.TemplateId, equip.Breakthrough)
        local resonanceCount = equip and equip.ResonanceInfo and (equip.ResonanceInfo.Count or XTool.GetTableCount(equip.ResonanceInfo)) or 0
        local isWeaponFashion = weaponFashionId and not XWeaponFashionConfigs.IsDefaultId(weaponFashionId)

        for case, modelTransId in pairs(template.ModelTransId) do
            if XTool.IsNumberValid(modelTransId) then
                local modelId = isWeaponFashion and XWeaponFashionConfigs.GetWeaponResonanceModelId(case, weaponFashionId, resonanceCount)
                or XEquipConfig.GetWeaponResonanceModelId(case, equip.TemplateId, resonanceCount)
                idList[case] = modelId
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
        local weaponFashionId = fightNpcData.WeaponFashionId or XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
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
        local weaponFashionId = fightNpcData.WeaponFashionId or XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
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
        local weaponFashionId = fightNpcData.WeaponFashionId or XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
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
                local templateId = XCharacterConfigs.GetCharacterDefaultEquipId(characterId)
                local equip = { TemplateId = templateId }
                return XEquipManager.GetEquipModelIdListByEquipData(equip, weaponFashionId)
            end
        end

        -- 默认武器预览
        if isDefault or not isOwnCharacter then
            local idList = {}
            local templateId = XCharacterConfigs.GetCharacterDefaultEquipId(characterId)
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
        if not equipId then return end
        local equip = XEquipManager.GetEquip(equipId)
        local modelId = XEquipConfig.GetWeaponResonanceModelId(XEquipConfig.WeaponCase.Case1, equip.TemplateId, resonanceCount)
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
            XLog.Error("XEquipManager.GetWeaponResonanceEffectPathByFight错误, 参数fightNpcData：" .. tostring(fightNpcData) .. "中不包含武器")
            return
        end

        local resonanceCount = equip.ResonanceInfo and (equip.ResonanceInfo.Count or XTool.GetTableCount(equip.ResonanceInfo)) or 0
        local modelId = XEquipConfig.GetWeaponResonanceModelId(XEquipConfig.WeaponCase.Case1, equip.TemplateId, resonanceCount)
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
            XLog.ErrorTableDataNotFound("XEquipManager.GetSuitBigIconBagPath", "suitCfg", path, "suitId", tostring(suitId))
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
            XLog.ErrorTableDataNotFound("XEquipManager.GetOriginWeaponSkillInfo", "weaponSkillId", path, "templateId", tostring(templateId))
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
            tableInsert(consumeItems, {
                Id = equipBreakthroughCfg.ItemId[i],
                Count = equipBreakthroughCfg.ItemCount[i],
            })
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
                tableInsert(consumeItems, {
                    ItemId = itemId,
                    Count = config.ItemCount[i],
                })
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
                tableInsert(consumeItems, {
                    ItemId = itemId,
                    Count = config.ItemCrystalCount[i],
                })
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
        if not equipResonanceCfg then return count end

        for pos = 1, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
            if equipResonanceCfg.WeaponSkillPoolId and equipResonanceCfg.WeaponSkillPoolId[pos] and equipResonanceCfg.WeaponSkillPoolId[pos] > 0 then
                count = count + 1
            elseif equipResonanceCfg.AttribPoolId and equipResonanceCfg.AttribPoolId[pos] and equipResonanceCfg.AttribPoolId[pos] > 0 then
                count = count + 1
            elseif equipResonanceCfg.CharacterSkillPoolId and equipResonanceCfg.CharacterSkillPoolId[pos]
            and equipResonanceCfg.CharacterSkillPoolId[pos] > 0 then
                count = count + 1
            end
        end

        return count
    end

    function XEquipManager.GetResonancePreSkillInfoList(equipId, characterId, slot)
        local preSkillInfoList = {}
        local templateId = GetEquipTemplateId(equipId)
        local equipResonanceCfg = XEquipConfig.GetEquipResonanceCfg(templateId)

        if XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Weapon) then
            local poolId = equipResonanceCfg.WeaponSkillPoolId[slot]
            local skillIds = XEquipConfig.GetWeaponSkillPoolSkillIds(poolId, characterId)

            for _, skillId in ipairs(skillIds) do
                tableInsert(preSkillInfoList, XSkillInfoObj.New(XEquipConfig.EquipResonanceType.WeaponSkill, skillId))
            end
        else
            local skillPoolId = equipResonanceCfg.CharacterSkillPoolId[slot]
            local skillInfos = XCharacterConfigs.GetCharacterSkillPoolSkillInfos(skillPoolId, characterId)
            local attrPoolId = equipResonanceCfg.AttribPoolId[slot]
            local attrInfos = XAttribConfigs.GetAttribGroupTemplateByPoolId(attrPoolId)

            for i, v in ipairs(skillInfos) do
                tableInsert(preSkillInfoList, XSkillInfoObj.New(XEquipConfig.EquipResonanceType.CharacterSkill, v.SkillId))
            end

            for i, v in ipairs(attrInfos) do
                tableInsert(preSkillInfoList, XSkillInfoObj.New(XEquipConfig.EquipResonanceType.Attrib, v.Id))
            end
        end

        return preSkillInfoList
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
            skillInfo = XSkillInfoObj.New(equip.UnconfirmedResonanceInfo[pos].Type, equip.UnconfirmedResonanceInfo[pos].TemplateId)
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
        return equip.UnconfirmedResonanceInfo and equip.UnconfirmedResonanceInfo[pos] and equip.UnconfirmedResonanceInfo[pos].CharacterId
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
                if equip.Id ~= equipId and star == XEquipManager.GetEquipStar(equip.TemplateId)
                and XEquipManager.IsClassifyEqual(equip.Id, XEquipConfig.Classify.Weapon)
                and not XEquipManager.IsWearing(equip.Id) and not XEquipManager.IsLock(equip.Id) then
                    tableInsert(equipIds, equip.Id)
                end
            end
        else
            --意识消耗同套装
            local resonanceSuitId = XEquipManager.GetSuitId(equipId)

            for _, equip in pairs(Equips) do
                if equip.Id ~= equipId and resonanceSuitId == XEquipManager.GetSuitId(equip.Id)
                and XEquipManager.IsClassifyEqual(equip.Id, XEquipConfig.Classify.Awareness)
                and not XEquipManager.IsWearing(equip.Id) and not XEquipManager.IsInSuitPrefab(equip.Id) and not XEquipManager.IsLock(equip.Id) then
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
                local characterEquipType = XCharacterConfigs.GetCharacterEquipType(characterId)
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
                XLog.ErrorTableDataNotFound("XEquipManager.GetWeaponSkillAbility",
                "weaponAbility", path, "WeaponSkillId", tostring(template.WeaponSkillId))
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
                            XLog.ErrorTableDataNotFound("XEquipManager.GetWeaponSkillAbility",
                            "weaponAbility", path, "WeaponSkillId", tostring(resonanceData.TemplateId))
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

    function XEquipManager.GetEquipSkipIds(eatType, equipId)
        local site = XEquipManager.GetEquipSite(equipId)
        local template = XEquipConfig.GetEquipSkipIdTemplate(eatType, site)
        return template.SkipIdParams
    end

    function XEquipManager.CheckBoxOverLimitOfDraw()--武器意识拦截检测
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

        max = CS.XGame.Config:GetInt("MailCountLimit")
        cur = #XDataCenter.MailManager.GetMailList()
        if (max - cur) < 1 then
            XUiManager.TipMsg(CS.XTextManager.GetText("MailBoxIsFull"))
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

    function XEquipManager.CheckBoxOverLimitOfGetAwareness()--意识拦截检测
        OverLimitTexts["Wafer"] = nil

        local max = XEquipConfig.GetMaxAwarenessCount()
        local cur = XEquipManager.GetAwarenessCount()
        if (max - cur) < 1 then
            OverLimitTexts["Wafer"] = CS.XTextManager.GetText("WaferBoxIsFull")
        end

        max = CS.XGame.Config:GetInt("MailCountLimit")
        cur = #XDataCenter.MailManager.GetMailList()
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

    function XEquipManager.GetMaxCountOfBoxOverLimit(EquipId, MaxCount, Count)--武器意识拦截检测
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

    function XEquipManager.ShowBoxOverLimitText()--武器意识拦截检测
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

    function XEquipManager.GetAwakeItemApplicationScope(itemId)--获取觉醒道具能够生效的意识列表
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
            [4] = true,
        },
        Days = 0, --设置回收天数, 0为不回收
    }

    local function UpdateAwarenessRecycleInfo(recycleInfo)
        if XTool.IsTableEmpty(recycleInfo) then return end

        local starDic = {}
        for _, star in pairs(recycleInfo.RecycleStar or {}) do
            starDic[star] = true
        end
        AwarenessRecycleInfo.StarCheckDic = starDic

        AwarenessRecycleInfo.Days = recycleInfo.Days or 0
    end

    function XEquipManager.IsEquipCanRecycle(equipId)
        if not equipId then return false end
        local equip = XEquipManager.GetEquip(equipId)
        if not equip then return false end

        local equipId = equip.Id
        return
        XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Awareness) --是意识（后续开放武器回收）
        and XEquipManager.GetEquipStar(equip.TemplateId) <= XEquipConfig.CAN_NOT_AUTO_EAT_STAR --星级≤5
        and equip.Breakthrough == 0     --无突破
        and equip.Level == 1 and equip.Exp == 0     --无强化
        and not equip.ResonanceInfo and not equip.UnconfirmedResonanceInfo  --无共鸣
        and not XEquipManager.IsEquipAwaken(equipId)     --无觉醒
        and not XEquipManager.IsWearing(equipId)     --未被穿戴
        and not XEquipManager.IsInSuitPrefab(equipId)    --未被预设在意识组合中
        and not XEquipManager.IsLock(equipId)      --未上锁
    end

    --是否待回收
    function XEquipManager.IsRecycle(equipId)
        if not equipId then return false end
        local equip = XEquipManager.GetEquip(equipId)
        if not equip then return false end

        return equip.IsRecycle
    end

    function XEquipManager.GetCanRecycleWeaponIds()
        local weaponIds = {}
        for k, v in pairs(Equips) do
            local equipId = v.Id

            if XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Weapon)
            and XEquipManager.IsEquipCanRecycle(equipId)
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
            if XEquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Awareness)
            and XEquipManager.IsEquipCanRecycle(equipId)
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
        if totalExp == 0 then return itemInfoList end

        local precent = XEquipConfig.GetEquipRecycleItemPercent()
        local itemInfo = {
            TemplateId = XEquipConfig.GetEquipRecycleItemId(),
            Count = mathFloor(precent * totalExp),
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
        local req = { ChipIds = equipIds }
        XNetwork.Call("EquipChipRecycleRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local rewardGoodsList = res.RewardGoodsList
            for _, id in pairs(equipIds) do
                XEquipManager.DeleteEquip(id)
            end

            if cb then cb(rewardGoodsList) end
        end)
    end

    --装备意识设置自动回收请求
    function XEquipManager.EquipChipSiteAutoRecycleRequest(starList, days, cb)
        local req = { StarList = starList, Days = days }
        XNetwork.Call("EquipChipSiteAutoRecycleRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            UpdateAwarenessRecycleInfo({
                RecycleStar = starList,
                Days = days,
            })

            if cb then cb() end
        end)
    end

    function XEquipManager.IsSetRecycleNeedConfirm(equipId)
        if XEquipManager.IsHaveRecycleCookie() then return false end
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
            if XEquipManager.IsHaveRecycleCookie() then return end
            local updateTime = XTime.GetSeverTomorrowFreshTime()
            XSaveTool.SaveData(key, updateTime)
        end
    end

    --装备更新回收标志请求
    function XEquipManager.EquipUpdateRecycleRequest(equipId, isRecycle, cb)
        isRecycle = isRecycle and true or false

        local callFunc = function()
            local req = { EquipId = equipId, IsRecycle = isRecycle }
            XNetwork.Call("EquipUpdateRecycleRequest", req, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local equip = XEquipManager.GetEquip(equipId)
                equip:SetRecycle(isRecycle)

                if cb then cb() end

                CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY, equipId, isRecycle)
                XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY, equipId, isRecycle)
            end)
        end

        if isRecycle and XEquipManager.IsSetRecycleNeedConfirm(equipId) then
            local title = CSXTextManagerGetText("EquipSetRecycleConfirmTitle")
            local content = CSXTextManagerGetText("EquipSetRecycleConfirmContent")
            local days = XEquipManager.GetRecycleSettingDays()
            local content2 = days > 0 and CSXTextManagerGetText("EquipSetRecycleConfirmContentExtra", days) or CSXTextManagerGetText("EquipSetRecycleConfirmContentExtraNegative")
            local hintInfo = {
                SetHintCb = XEquipManager.SetRecycleCookie,
                Status = XEquipManager.IsHaveRecycleCookie,
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
        if XTool.IsTableEmpty(equipIds) then return end

        for _, equipId in pairs(equipIds) do
            XEquipManager.DeleteEquip(equipId)
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_RECYCLE_NOTIFY, equipIds)
    end
    --装备回收相关 end
    -----------------------------------------Getter End------------------------------------
    XEquipManager.GetEquipTemplateId = GetEquipTemplateId

    return XEquipManager
end

XRpc.NotifyEquipDataList = function(data)
    XDataCenter.EquipManager.NotifyEquipDataList(data)
end

XRpc.NotifyEquipChipGroupList = function(data)
    XDataCenter.EquipManager.NotifyEquipChipGroupList(data)
end

XRpc.NotifyEquipChipAutoRecycleSite = function(data)
    XDataCenter.EquipManager.NotifyEquipChipAutoRecycleSite(data)
end

XRpc.NotifyEquipAutoRecycleChipList = function(data)
    XDataCenter.EquipManager.NotifyEquipAutoRecycleChipList(data)
end