local next = next
local pairs = pairs
local table = table
local tableInsert = table.insert
local tableSort = table.sort
local XWeaponFashion = require("XEntity/XEquip/XWeaponFashion")

XWeaponFashionManagerCreator = function()
    local XWeaponFashionManager = {}

    local OwnWeaponFashions = {}

    XWeaponFashionManager.FashionStatus = {
        UnOwned = 0, -- 未拥有
        UnLock = 1, -- 已解锁
        Dressed = 2, -- 已穿戴
    }

    local IsNotifyWeaponFashionTransform = false

    function XWeaponFashionManager.InitWeaponFashions(fashions)
        if not fashions then return end

        for _, data in pairs(fashions) do
            OwnWeaponFashions[data.Id] = XWeaponFashion.New(data)
        end
    end

    function XWeaponFashionManager.RecycleWeaponFashions(fashionIds)
        if not fashionIds then return end

        for _, fashionId in pairs(fashionIds) do
            OwnWeaponFashions[fashionId] = nil
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FASHION_WEAPON_EXPIRED_REFRESH, fashionIds)
    end

    function XWeaponFashionManager.NotifyWeaponFashionInfo(data)
        XWeaponFashionManager.InitWeaponFashions(data.WeaponFashionDataList)
        XWeaponFashionManager.RecycleWeaponFashions(data.ExpireList)
    end

    function XWeaponFashionManager.NotifyWeaponFashionTransform(data)
        IsNotifyWeaponFashionTransform = true
        if not data or not next(data) then return end
        local rewards = {}
        tableInsert(rewards, { TemplateId = data.ItemId, Count = data.ItemCount })
        if XDataCenter.LottoManager.GetIsInterceptUiObtain() then
            XDataCenter.LottoManager.CacheWeaponFashionRewards(data)
        else
            XUiManager.OpenUiObtain(rewards)
        end
    end

    function XWeaponFashionManager.GetIsNotifyWeaponFashionTransform()
        return IsNotifyWeaponFashionTransform
    end

    function XWeaponFashionManager.ResetIsNotifyWeaponFashionTransform()
        IsNotifyWeaponFashionTransform = false
    end

    function XWeaponFashionManager.CheckHasFashion(id)
        if not id then return false end
        if XWeaponFashionConfigs.IsDefaultId(id) then return true end
        return OwnWeaponFashions[id] ~= nil
    end

    function XWeaponFashionManager.IsFashionTimeLimit(id)
        local fashion = XWeaponFashionManager.GetWeaponFashion(id)
        if not fashion then return false end
        return fashion:IsTimeLimit()
    end

    function XWeaponFashionManager.CheckFashionTimeLimit(id)
        local beginTime = XWeaponFashionConfigs.GetFashionBeginTime(id)
        local endTime = XWeaponFashionConfigs.GetFashionExpireTime(id)
        return beginTime ~= 0 or endTime ~= 0
    end

    function XWeaponFashionManager.IsFashionInTime(id)
        local fitBegin
        local beginTime = XWeaponFashionConfigs.GetFashionBeginTime(id)
        if beginTime == 0 then
            fitBegin = true
        else
            local nowTime = XTime.GetServerNowTimestamp()
            fitBegin = nowTime >= beginTime
        end

        local fitEnd
        local endTime = XWeaponFashionConfigs.GetFashionExpireTime(id)
        if endTime == 0 then
            fitEnd = true
        else
            local nowTime = XTime.GetServerNowTimestamp()
            fitEnd = nowTime < endTime
        end

        return fitBegin and fitEnd and true
    end

    function XWeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
        local weaponFashionId = XWeaponFashionConfigs.DefaultWeaponFashionId

        for _, fashion in pairs(OwnWeaponFashions) do
            if fashion:IsDressed(characterId) then
                weaponFashionId = fashion:GetId()
                break
            end
        end

        return weaponFashionId
    end

    function XWeaponFashionManager.GetWeaponFashion(id)
        return OwnWeaponFashions[id]
    end

    function XWeaponFashionManager.GetOwnWeaponFashion()
        return XTool.Clone(OwnWeaponFashions)
    end

    local SortStatusPriority = {
        [XWeaponFashionManager.FashionStatus.UnOwned] = 1,
        [XWeaponFashionManager.FashionStatus.UnLock] = 2,
        [XWeaponFashionManager.FashionStatus.Dressed] = 3,
    }

    function XWeaponFashionManager.GetSortedWeaponFashionIdsByCharacterId(characterId)
        local sortedFashionIds = {}

        local characterEquipType = XCharacterConfigs.GetCharacterEquipType(characterId)
        local fashionIds = XWeaponFashionConfigs.GetWeaponFashionIdsByEquipType(characterEquipType)
        for _, id in pairs(fashionIds) do
            if XWeaponFashionManager.IsFashionInTime(id) then
                tableInsert(sortedFashionIds, id)
            end
        end
        tableInsert(sortedFashionIds, XWeaponFashionConfigs.DefaultWeaponFashionId)

        tableSort(sortedFashionIds, function(a, b)
            local status1, status2 = XWeaponFashionManager.GetFashionStatus(a, characterId), XWeaponFashionManager.GetFashionStatus(b, characterId)
            if status1 ~= status2 then
                return SortStatusPriority[status1] > SortStatusPriority[status2]
            end

            local aIsDefault = XWeaponFashionConfigs.IsDefaultId(a)
            local bIsDefault = XWeaponFashionConfigs.IsDefaultId(b)
            if aIsDefault ~= bIsDefault then
                return aIsDefault
            end

            return XWeaponFashionConfigs.GetFashionPriority(a) > XWeaponFashionConfigs.GetFashionPriority(b)
        end)

        return sortedFashionIds
    end

    function XWeaponFashionManager.GetFashionStatus(fashionId, characterId)
        if XWeaponFashionConfigs.IsDefaultId(fashionId) then
            for _, fashion in pairs(OwnWeaponFashions) do
                if fashion:IsDressed(characterId) then
                    return XWeaponFashionManager.FashionStatus.UnLock
                end
            end
            return XWeaponFashionManager.FashionStatus.Dressed
        end

        local fashion = XWeaponFashionManager.GetWeaponFashion(fashionId)
        if not fashion then
            return XWeaponFashionManager.FashionStatus.UnOwned
        end

        return fashion:IsDressed(characterId) and XWeaponFashionManager.FashionStatus.Dressed or XWeaponFashionManager.FashionStatus.UnLock
    end

    function XWeaponFashionManager.IsCharacterFashion(fashionId, characterId)
        local fashionList = XWeaponFashionManager.GetSortedWeaponFashionIdsByCharacterId(characterId)
        for _, fashionIdTemp in pairs(fashionList) do
            if fashionIdTemp == fashionId then
                return true
            end
        end
        return false
    end

    function XWeaponFashionManager.GetWeaponFashionName(weaponFashionId, characterId)
        local fashionName

        if XWeaponFashionConfigs.IsDefaultId(weaponFashionId) then
            local templateId
            if not XDataCenter.CharacterManager.IsOwnCharacter(characterId) then
                templateId = XCharacterConfigs.GetCharacterDefaultEquipId(characterId)
            else
                local equipId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
                templateId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
            end
            fashionName = XDataCenter.EquipManager.GetEquipName(templateId)
        else
            fashionName = XWeaponFashionConfigs.GetFashionName(weaponFashionId)
        end

        return fashionName
    end

    function XWeaponFashionManager.GetWeaponModelCfg(weaponFashionId, characterId, uiName)
        local modelConfig = {}

        local IsOwnCharacter = XDataCenter.CharacterManager.IsOwnCharacter(characterId)
        if XWeaponFashionConfigs.IsDefaultId(weaponFashionId) then
            if not IsOwnCharacter then
                local templateId = XCharacterConfigs.GetCharacterDefaultEquipId(characterId)
                modelConfig = XDataCenter.EquipManager.GetWeaponModelCfg(templateId, uiName, 0, 0)
            else
                local equipId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
                local templateId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
                local breakthroughTimes = XDataCenter.EquipManager.GetBreakthroughTimes(equipId)
                local resonanceCount = XDataCenter.EquipManager.GetResonanceCount(equipId)
                modelConfig = XDataCenter.EquipManager.GetWeaponModelCfg(templateId, uiName, breakthroughTimes, resonanceCount)
            end
        else
            local resonanceCount = 0
            local equipType = XWeaponFashionConfigs.GetFashionEquipType(weaponFashionId)
            if IsOwnCharacter then
                local equipId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
                resonanceCount = XDataCenter.EquipManager.GetResonanceCount(equipId)
            end
            local modelId = XWeaponFashionConfigs.GetWeaponResonanceModelId(XEquipConfig.WeaponCase.Case1, weaponFashionId, resonanceCount)
            modelConfig.ModelId = modelId
            modelConfig.TransformConfig = XEquipConfig.GetEquipModelTransformCfg(nil, uiName, resonanceCount, modelId, equipType)
        end

        return modelConfig
    end

    function XWeaponFashionManager.UseFashion(fashionId, characterId, cb)
        if not XDataCenter.CharacterManager.IsOwnCharacter(characterId) then
            XUiManager.TipText("CharacterLock")
            return
        end

        if not XWeaponFashionManager.CheckHasFashion(fashionId) then
            XUiManager.TipText("WeaponFashionNotOwn")
            return
        end

        XNetwork.Call("WeaponFashionUseRequest", { Id = fashionId, CharacterId = characterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local oldFashion = XWeaponFashionManager.GetWeaponFashion(fashionId)
            if oldFashion then
                oldFashion:TakeOff(characterId)
            end

            local fashion = XWeaponFashionManager.GetWeaponFashion(fashionId)
            if fashion then
                fashion:Dress(characterId)
            end

            if cb then cb() end
        end)
    end

    function XWeaponFashionManager.GetEquipTypeByTemplateId(itemTemplateId)
        local subTypeParams = XItemConfigs.GetItemSubTypeParams(itemTemplateId)
        if subTypeParams and #subTypeParams > 0 then
            local fashionId = subTypeParams[1]
            if XWeaponFashionConfigs.IsWeaponFashion(fashionId) then
                return XWeaponFashionConfigs.GetFashionEquipType(fashionId)
            end
        end
        return nil
    end

    return XWeaponFashionManager
end

XRpc.NotifyWeaponFashionInfo = function(data)
    XDataCenter.WeaponFashionManager.NotifyWeaponFashionInfo(data)
end

XRpc.NotifyWeaponFashionTransform = function(data)
    XDataCenter.WeaponFashionManager.NotifyWeaponFashionTransform(data)
end