local XDlcHuntChipGroup = require("XEntity/XDlcHunt/XDlcHuntChipGroup")
local XDlcHuntChip = require("XEntity/XDlcHunt/XDlcHuntChip")

XDlcHuntChipManagerCreator = function()
    ---@class XDlcHuntChipManager
    local XDlcHuntChipManager = {}

    ---@type XDlcHuntChipGroup[]
    local _ChipGroup = {}

    ---@type XDlcHuntChip[]
    local _Chip = {}

    local _AssistantChipUid2Others = false

    local _AssistantChip2Myself = false
    local _AssistantChipTime2Myself = 0
    local _AssistantChipList2Myself = {
        [XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.FRIEND] = {}, -- 好友
        [XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.TEAMMATE] = {}, -- 队友
        [XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.RANDOM] = {}, -- 随机芯片
        [XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.CONFIG] = {}, -- 策划配的
    }
    local ASSISTANT_CHIP_FROM = XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM
    local _IsInitAssistantListFromConfig = false

    local RequestProto = {
        SetLock = "DlcChipUpdateLockRequest",
        LevelUp = "DlcChipLevelUpRequest",
        Breakthrough = "DlcChipBreakthroughRequest",
        SetAssistant = "DlcChipAssistSetRequest",
        SetGroupName = "DlcChipFormChangeNameRequest",
        Wear = "DlcChipFormWearChipRequest",
        TakeOffChipFromAllGroup = "DlcTakeOffChipRequest",
        Decompose = "DlcChipDecomposeRequest",
        AssistantChipList = "DlcPlayerSupplyChipDataRequest",
        SetAssistantChipToMyself = "DlcSelectAssistChipRequest",
    }

    function XDlcHuntChipManager.InitDataFromServer(chipList)
        XDlcHuntChipManager.HandleChipDataList(chipList)
    end

    function XDlcHuntChipManager.Init()
    end

    function XDlcHuntChipManager.ClearAssistantChip2Myself()
        _AssistantChip2Myself = false
    end

    ---@return XDlcHuntChipGroup
    function XDlcHuntChipManager.GetChipGroup(chipGroupId)
        return _ChipGroup[chipGroupId]
    end

    ---@return XDlcHuntChipGroup[]
    function XDlcHuntChipManager.GetAllChipGroup()
        return _ChipGroup
    end

    ---@return XDlcHuntChip
    function XDlcHuntChipManager.GetChip(chipUid)
        return _Chip[chipUid]
    end

    function XDlcHuntChipManager.GetAllChip()
        return _Chip
    end

    function XDlcHuntChipManager.GetAssistantChip2Others()
        return XDlcHuntChipManager.GetChip(_AssistantChipUid2Others)
    end

    function XDlcHuntChipManager.GetAssistantChip2Myself()
        return _AssistantChip2Myself
    end

    function XDlcHuntChipManager.GetChipList2AssistantOthers()
        local allChip = XDlcHuntChipManager.GetAllChip()
        local result = {}
        for uid, chip in pairs(allChip) do
            if chip:IsCanAssistant() then
                result[#result + 1] = chip
            end
        end
        return result
    end

    function XDlcHuntChipManager.OpenUiChipMain(chipGroup, character)
        if not chipGroup and not character then
            local room = XDataCenter.DlcRoomManager.GetRoom()
            if room then
                local member = room:GetTeam():GetSelfMember()
                if member then
                    character = member:GetMyCharacter()
                    if character then
                        chipGroup = character:GetChipGroup()
                    end
                end
            end
        end
        if not character then
            return
        end

        local callback = function(selectedChipGroup)
            if selectedChipGroup then
                XDataCenter.DlcHuntCharacterManager.RequestSetChipGroup2Character(character, selectedChipGroup)
            end
        end
        XLuaUiManager.Open("UiDlcHuntChipMain", chipGroup, callback)
    end

    local _AssistantIndex = {
        [XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.FRIEND] = 0,
        [XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.TEAMMATE] = 0,
        [XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.RANDOM] = 0,
        [XDlcHuntChipConfigs.ASSISTANT_CHIP_FROM.CONFIG] = 0,
    }
    -- 顺序
    local _AssistantFromTypeIndex = {
        ASSISTANT_CHIP_FROM.CONFIG,
        ASSISTANT_CHIP_FROM.FRIEND, --15
        ASSISTANT_CHIP_FROM.TEAMMATE, --10
        ASSISTANT_CHIP_FROM.RANDOM, --5
    }
    function XDlcHuntChipManager.GetChipList2AssistantMySelf(isRefresh)
        local result = {}
        local amountConfig = XDlcHuntConfigs.GetAmountAssistantChip()
        local repeatPlayerIdDict = {}
        repeatPlayerIdDict[XPlayer.Id] = true   -- 自己的芯片不显示

        for index = 1, #_AssistantFromTypeIndex do
            local fromType = _AssistantFromTypeIndex[index]
            local list = _AssistantChipList2Myself[fromType]
            local chipAmount = amountConfig[fromType]
            if isRefresh then
                _AssistantIndex[fromType] = _AssistantIndex[fromType] + chipAmount
                if _AssistantIndex[fromType] >= #list then
                    _AssistantIndex[fromType] = 0
                end
            end
            local beginIndex = _AssistantIndex[fromType] + 1
            local endIndex = beginIndex + chipAmount - 1
            endIndex = math.min(endIndex, #list)
            for i = beginIndex, endIndex do
                ---@type XDlcHuntChip
                local chip = list[i]
                if chip then
                    local playerId = chip:GetPlayerId()
                    if playerId > 0 and repeatPlayerIdDict[playerId] then
                        endIndex = endIndex + 1
                        endIndex = math.min(endIndex, #list)
                    else
                        result[#result + 1] = chip
                        repeatPlayerIdDict[playerId] = true
                    end
                end
            end
        end
        return result
    end

    function XDlcHuntChipManager.DecomposeChips(chips)
        local title = CS.XTextManager.GetText("TipTitle")
        XLuaUiManager.Open("UiDlcHuntDialog", title, XUiHelper.GetText("DlcHuntChipDecompose"),
                function()
                    XDlcHuntChipManager.RequestDecomposeChips(chips)
                end
        )
    end

    function XDlcHuntChipManager.TakeOffChipsOnGroup(group)
        local title = CS.XTextManager.GetText("TipTitle")
        XLuaUiManager.Open("UiDlcHuntDialog", title, XUiHelper.GetText("DlcHuntChipUndress"),
                function()
                    XDlcHuntChipManager.RequestTakeOffChipGroup(group, function()
                        XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_ALL_CHIP_TAKE_OFF)
                    end)
                end
        )
    end

    function XDlcHuntChipManager.GetChipAmountMain()
        local amount = 0
        for uid, chip in pairs(_Chip) do
            if chip:IsMainChip() then
                amount = amount + 1
            end
        end
        return amount
    end

    function XDlcHuntChipManager.GetChipAmountSub()
        local amount = 0
        for uid, chip in pairs(_Chip) do
            if chip:IsSubChip() then
                amount = amount + 1
            end
        end
        return amount
    end

    function XDlcHuntChipManager.GetChipAmountByItemId(itemId)
        local amount = 0
        for uid, chip in pairs(_Chip) do
            if chip:GetId() == itemId then
                amount = amount + 1
            end
        end
        return amount
    end

    function XDlcHuntChipManager._RemoveChip(chipId)
        _Chip[chipId] = nil
    end

    function XDlcHuntChipManager._RemoveChips(chipIdArray)
        for i = 1, #chipIdArray do
            XDlcHuntChipManager._RemoveChip(chipIdArray[i])
        end
    end

    function XDlcHuntChipManager.IsAllChipLevelZero()
        local allChip = XDataCenter.DlcHuntChipManager.GetAllChip()
        for uid, chip in pairs(allChip) do
            if chip:GetLevel() > 1 or chip:GetBreakthroughTimes() > 0 then
                return false
            end
        end
        return true
    end

    function XDlcHuntChipManager.IsAllChipGroupEmpty()
        local allChipGroup = XDataCenter.DlcHuntChipManager.GetAllChipGroup()
        for _, chipGroup in pairs(allChipGroup) do
            if chipGroup:GetAmount() ~= 0 then
                return false
            end
        end
        return true
    end

    --region notify
    function XDlcHuntChipManager.HandleChipDataList(chipDataList)
        local player = XPlayer
        for i = 1, #chipDataList do
            local chipData = chipDataList[i]
            ---@type XDlcHuntChip
            local chip = XDlcHuntChip.New()
            chip:SetData(chipData)
            chip:SetPlayerId(player.Id)
            chip:SetPlayerName(player.Name)
            if XDlcHuntChipConfigs.IsExist(chip:GetId()) then
                _Chip[chip:GetUid()] = chip
            end
        end
    end

    function XDlcHuntChipManager.NotifyChipGroup(chipGroupDataList)
        for i = 1, #chipGroupDataList do
            local chipGroupData = chipGroupDataList[i]
            local chipGroupId = chipGroupData.FormId
            local chipGroup = XDlcHuntChipManager.GetChipGroup(chipGroupId)
            if not chipGroup then
                chipGroup = XDlcHuntChipGroup.New(chipGroupId)
                _ChipGroup[chipGroupId] = chipGroup
            end
            chipGroup:SetData(chipGroupData)
        end
    end

    function XDlcHuntChipManager.NotifyAssistantChip(uid)
        _AssistantChipUid2Others = uid
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_UPDATE)
    end
    --endregion notify

    --region request
    function XDlcHuntChipManager.RequestUpgradeChip(chipId, chipsToBeExp)
        XNetwork.Call(RequestProto.LevelUp, {
            ChipId = chipId,
            UseChipIds = chipsToBeExp,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDlcHuntChipManager._RemoveChips(chipsToBeExp)
            local chip = XDlcHuntChipManager.GetChip(chipId)
            chip:SetIsLock(true)
            chip:SetLevel(res.Level)
            chip:SetExp(res.Exp)
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_UPDATE, chip)
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_UP_SUCCESS)
            XMVCA.XEquip:TipEquipOperation(nil, XUiHelper.GetText("DlcHuntStrengthenSuccess"))
        end)
    end

    function XDlcHuntChipManager.RequestTakeOffChipGroup(group, callback)
        XDlcHuntChipManager.RequestWearBatchChip(group, {}, callback)
    end

    ---@param chip XDlcHuntChip
    function XDlcHuntChipManager.RequestLock(chip, isLock)
        local chipId = chip:GetUid()
        XNetwork.Call(RequestProto.SetLock, { ChipId = chipId, IsLock = isLock }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            chip:SetIsLock(isLock)
        end)
    end

    ---@param chips XDlcHuntChip[]
    function XDlcHuntChipManager.RequestDecomposeChips(chips)
        local uidArray = {}
        for i = 1, #chips do
            local chip = chips[i]
            local uid = chip:GetUid()
            if XDlcHuntChipManager.GetChip(uid) then
                uidArray[#uidArray + 1] = uid
            end
        end
        XNetwork.Call(RequestProto.Decompose, {
            UseChipIds = uidArray
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if res.RewardGoodsList[1] and res.RewardGoodsList[1].TemplateId ~= 0 then
                XDataCenter.DlcHuntManager.OpenUiObtain(res.RewardGoodsList)
            end
            XDlcHuntChipManager._RemoveChips(uidArray)
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_UPDATE)
        end)
    end

    function XDlcHuntChipManager.RequestBreakthrough(chipId, chipsToBeExp)
        XNetwork.Call(RequestProto.Breakthrough, {
            ChipId = chipId,
            UseChipIds = chipsToBeExp
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XDlcHuntChipManager._RemoveChips(chipsToBeExp)
            local chip = XDlcHuntChipManager.GetChip(chipId)
            local chipBefore = chip:Clone()
            chip:SetBreakthroughTimes(chip:GetBreakthroughTimes() + 1)
            chip:SetExp(0)
            chip:SetIsLock(true)
            chip:SetLevel(1)
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_UPDATE)
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_UP_SUCCESS)
            XLuaUiManager.Open("UiDlcHuntChipUp", chip, chipBefore)
            --XUiManager.OpenUiObtain(res.RewardGoodsList)
        end)
    end

    ---@param chip XDlcHuntChip
    function XDlcHuntChipManager.RequestSetAssistantChip(chip)
        if not chip then
            return
        end
        local chipId = chip:GetUid()
        XNetwork.Call(RequestProto.SetAssistant, {
            ChipId = chipId,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _AssistantChipUid2Others = chipId
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_UPDATE)
        end)
    end

    ---@param chipGroup XDlcHuntChipGroup
    ---@param chip XDlcHuntChip
    function XDlcHuntChipManager.RequestUndressChip(chipGroup, chip)
        if not chipGroup or not chip then
            return
        end
        local isContain, pos = chipGroup:IsContain(chip)
        if not isContain then
            return
        end
        XNetwork.Call(RequestProto.Wear, {
            ChipFormId = chipGroup:GetUid(),
            WearInfos = { {
                              ChipId = 0,
                              Pos = pos }
            },
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            chipGroup:SetChip(0, pos)
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE)
        end)
    end

    ---@param chipGroup XDlcHuntChipGroup
    ---@param chip XDlcHuntChip
    function XDlcHuntChipManager.RequestDressChip(chipGroup, chip, pos)
        if not chipGroup or not chip then
            return false
        end
        local isContain = chipGroup:IsContain(chip)
        if isContain then
            XUiManager.TipMsg(XUiHelper.GetText("DlcHuntChipEquiped"))
            return false
        end
        XNetwork.Call(RequestProto.Wear, {
            ChipFormId = chipGroup:GetUid(),
            WearInfos = { {
                              ChipId = chip:GetUid(),
                              Pos = pos }
            },
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            chipGroup:SetChip(chip:GetUid(), pos)
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE)
        end)
        return true
    end

    ---@param chipGroup XDlcHuntChipGroup
    function XDlcHuntChipManager.RequestWearBatchChip(chipGroup, chipIdArray2Wear, callback)
        chipIdArray2Wear = XTool.Clone(chipIdArray2Wear)
        ---@type XDlcHuntChip[]
        local wearPosDict = {}
        local capacity = #chipIdArray2Wear
        -- 放入已装备的芯片
        for i = 1, capacity do
            local chipId = chipIdArray2Wear[i]
            local chip = XDlcHuntChipManager.GetChip(chipId)
            local isContain, pos = chipGroup:IsContain(chip)
            if isContain then
                wearPosDict[pos] = chip
                chipIdArray2Wear[i] = nil
            end
        end

        -- 检查主芯片数量
        local mainChipAmount = 0
        for i = 1, capacity do
            local chipId = chipIdArray2Wear[i]
            if chipId then
                local chip = XDlcHuntChipManager.GetChip(chipId)
                if chip:IsMainChip() then
                    mainChipAmount = mainChipAmount + 1
                end
            end
        end
        if mainChipAmount > XDlcHuntChipConfigs.CHIP_MAIN_AMOUNT then
            XLog.Error("[XDlcHuntChipManager] too much main chip")
            return
        end

        -- 检查副芯片数量
        local subChipAmount = 0
        for i = 1, capacity do
            local chipId = chipIdArray2Wear[i]
            if chipId then
                local chip = XDlcHuntChipManager.GetChip(chipId)
                if chip:IsSubChip() then
                    subChipAmount = subChipAmount + 1
                end
            end
        end
        if subChipAmount > XDlcHuntChipConfigs.CHIP_SUB_AMOUNT then
            XLog.Error("[XDlcHuntChipManager] too much sub chip")
            return
        end

        -- 放入未装备的芯片
        for i = 1, capacity do
            local chipId = chipIdArray2Wear[i]
            if chipId then
                local chip = XDlcHuntChipManager.GetChip(chipId)
                for j = 1, chipGroup:GetCapacity() do
                    if not wearPosDict[j] then
                        -- 位置有类型要求
                        local type = XDlcHuntChipConfigs.GetChipTypeByGroupPos(j)
                        if chip:GetType() == type then
                            wearPosDict[j] = chip
                            break
                        end
                    end
                end
            end
        end

        -- 忽略无变化的位置
        local wearArray = {}
        for pos = 1, chipGroup:GetCapacity() do
            local chip = wearPosDict[pos]
            local chipOnGroup = chipGroup:GetChip(pos)
            -- 一样的芯片
            if chip ~= chipOnGroup then
                wearArray[#wearArray + 1] = {
                    ChipId = chip and chip:GetUid() or 0,
                    Pos = pos
                }
            end
        end

        if #wearArray == 0 then
            XLog.Warning("[XDlcHuntChipManager] nothing change")
            return
        end

        XNetwork.Call(RequestProto.Wear, {
            ChipFormId = chipGroup:GetUid(),
            WearInfos = wearArray,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            for i = 1, #wearArray do
                local data = wearArray[i]
                chipGroup:SetChip(data.ChipId, data.Pos)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE)
            if callback then
                callback()
            end
        end)
    end

    ---@param chip XDlcHuntChip
    function XDlcHuntChipManager.RequestTakeOffChipFromAllGroup(chip)
        XNetwork.Call(RequestProto.TakeOffChipFromAllGroup, {
            ChipId = chip:GetUid()
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local groups = XDlcHuntChipManager.GetAllChipGroup()
            for id, group in pairs(groups) do
                group:TakeOffChip(chip)
            end
        end)
    end

    ---@param chipGroup XDlcHuntChipGroup
    function XDlcHuntChipManager.RequestRenameChipGroup(chipGroup, name)
        XNetwork.Call(RequestProto.SetGroupName, {
            ChipFormId = chipGroup:GetUid(),
            Name = name
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            chipGroup:SetName(name)
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE)
        end)
    end

    local function InstantiateChipList(dataList, fromType)
        local list = {}
        for i = 1, #dataList do
            local data = dataList[i]
            local playerId = data.PlayerId
            local playerName = data.Name
            local chipData = data.ChipData
            if chipData then
                ---@type XDlcHuntChip
                local chip = XDlcHuntChip.New()
                chip:SetData(chipData)
                chip:SetPlayerId(playerId)
                chip:SetPlayerName(playerName)
                chip:SetUid(data.Id or i)
                if fromType then
                    chip:SetFromType(fromType)
                end
                list[#list + 1] = chip
            end
        end
        return list
    end

    function XDlcHuntChipManager.RequestAssistantChip2Myself(isGuide)
        if not isGuide then
            -- friend
            local duration = XDlcHuntConfigs.GetDurationRequestFriendAssistantChipClient()
            if XTime.GetServerNowTimestamp() - _AssistantChipTime2Myself > duration then
                XNetwork.Call(RequestProto.AssistantChipList, {
                    Type = ASSISTANT_CHIP_FROM.FRIEND
                }, function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        return
                    end
                    _AssistantChipList2Myself[ASSISTANT_CHIP_FROM.FRIEND] = InstantiateChipList(res.SupplyChipDataList, ASSISTANT_CHIP_FROM.FRIEND)
                    XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_LIST_UPDATE)
                end)
            end

            -- teammate
            _AssistantChipList2Myself[ASSISTANT_CHIP_FROM.TEAMMATE] = {}
            local room = XDataCenter.DlcRoomManager.GetRoom()
            if room then
                local team = room:GetTeam()
                if team then
                    local list = {}
                    for pos = 1, team:GetMemberAmount() do
                        local member = team:GetMember(pos)
                        if not member:IsMyCharacter() then
                            local chip = member:GetAssistantChip()
                            list[#list + 1] = chip
                        end
                    end
                    _AssistantChipList2Myself[ASSISTANT_CHIP_FROM.TEAMMATE] = list
                end
            end

            -- random
            XNetwork.Call(RequestProto.AssistantChipList, {
                Type = ASSISTANT_CHIP_FROM.RANDOM
            }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                _AssistantChipList2Myself[ASSISTANT_CHIP_FROM.RANDOM] = InstantiateChipList(res.SupplyChipDataList, ASSISTANT_CHIP_FROM.RANDOM)
                XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_LIST_UPDATE)
            end)
        end
        
        -- from config
        if not _IsInitAssistantListFromConfig then
            _IsInitAssistantListFromConfig = true
            _AssistantChipList2Myself[ASSISTANT_CHIP_FROM.CONFIG] = XDlcHuntChipConfigs.GetAssistantChipList()
        end
    end

    ---@param chip XDlcHuntChip
    function XDlcHuntChipManager.RequestSetAssistantChipToMyself(chip)
        if not chip then
            return false
        end
        XNetwork.Call(RequestProto.SetAssistantChipToMyself, {
            AssistPlayerId = chip:GetPlayerId(),
            SelectType = chip:GetFromType(),
            SelectNumber = chip:GetUid()
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _AssistantChip2Myself = chip
            XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_UPDATE)
            XDataCenter.DlcRoomManager.EndSelectRequest()
        end)
        return true
    end

    function XDlcHuntChipManager.SetAssistantChipToMyself(chipData)
        if chipData then
            ---@type XDlcHuntChip
            local chip = XDlcHuntChip.New(chipData)
            chip:SetData(chipData)
            if not chip:IsEmpty() then
                _AssistantChip2Myself = chip
            end
        else
            _AssistantChip2Myself = false
        end
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_UPDATE)
    end
    --endregion request

    XDlcHuntChipManager.Init()
    return XDlcHuntChipManager
end

XRpc.NotifyDlcChipDataList = function(data)
    XDataCenter.DlcHuntChipManager.HandleChipDataList(data.ChipDataList)
end

XRpc.NotifyDlcChipFormDataList = function(data)
    XDataCenter.DlcHuntChipManager.NotifyChipGroup(data.ChipFormDataList)
end

XRpc.NotifyDlcChipAssistChipId = function(data)
    XDataCenter.DlcHuntChipManager.NotifyAssistantChip(data.AssistChipId)
end