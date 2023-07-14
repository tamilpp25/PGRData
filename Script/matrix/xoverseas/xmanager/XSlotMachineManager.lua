local tableInsert = table.insert
local CSXTextManagerGetText = CS.XTextManager.GetText

local XSlotMachineDataEntity = require("XOverseas/XEntity/XSlotMachine/XSlotMachineDataEntity")

XSlotMachineManagerCreator = function()
    local XSlotMachineManager = {}
    local ActId = 0
    local SlotMachineDataEntityList = {}
    local SlotMachineDataEntityAllList = {}  --再加一层以满足多个老虎机活动存在

    local SLOT_MACHINE_PROTO = {
        GetSlotMachineInfoRequest = "GetSlotMachineInfoRequest", -- 老虎机数据请求
        SlotMachineRequest = "SlotMachineRequest", -- 老虎机抽奖请求
        SlotMachineRewardRequest = "SlotMachineRewardRequest", -- 老虎机领奖请求
        SlotMachineExchangeItemRequest = "SlotMachineExchangeItemRequest", -- 老虎机兑换道具请求
    }
    function XSlotMachineManager.Init()

    end

    function XSlotMachineManager.GetSlotMachineInfoRequest(actId, cb)
        XNetwork.Call(SLOT_MACHINE_PROTO.GetSlotMachineInfoRequest, {ActivityId = actId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            ActId = actId
            XSlotMachineManager.SlotMachineInfoListHandle(res.SlotMachineClientDataList)
            --XLog.Warning(res.SlotMachineClientDataList)
            if cb then cb() end
        end)
    end

    function XSlotMachineManager.SlotMachineInfoListHandle(slotMachineClientDataList)
        if slotMachineClientDataList and next(slotMachineClientDataList) then
            --SlotMachineDataEntityList = {}
            SlotMachineDataEntityAllList[ActId] = {}
            for _, slotMachineInfo in ipairs(slotMachineClientDataList) do
                local slotMachineTmp = XSlotMachineConfigs.GetSlotMachinesTemplateById(slotMachineInfo.Id)
                local slotMachineDataEntity = XSlotMachineDataEntity.New(slotMachineTmp, slotMachineInfo)
                tableInsert(SlotMachineDataEntityAllList[ActId], slotMachineDataEntity)
            end
        end
    end

    function XSlotMachineManager.SlotMachineAllInfoListHandle(slotMachineClientDataList)
        if slotMachineClientDataList and next(slotMachineClientDataList) then
            --SlotMachineDataEntityList = {}
            for _, slotMachineInfo in ipairs(slotMachineClientDataList) do
                local slotMachineTmp = XSlotMachineConfigs.GetSlotMachinesTemplateById(slotMachineInfo.Id)
                local slotMachineDataEntity = XSlotMachineDataEntity.New(slotMachineTmp, slotMachineInfo)
                local tmpActId = XSlotMachineManager.CheckMachineActId(slotMachineInfo.Id)
                if tmpActId and not SlotMachineDataEntityAllList[tmpActId] then
                    SlotMachineDataEntityAllList[tmpActId] = {}
                end
                tableInsert(SlotMachineDataEntityAllList[tmpActId], slotMachineDataEntity)
            end
        end
    end

    function XSlotMachineManager.CheckMachineActId(machineId)
        local lotMachineListTmp = XSlotMachineConfigs.GetSlotMachinesActivityTemplate()
        for _, slotMachineInfo in ipairs(lotMachineListTmp) do
            for _, machineTmpId in pairs(slotMachineInfo.SlotMachinesIds) do
                if machineTmpId == machineId then
                    return slotMachineInfo.Id
                end
            end
        end
        XLog.Error("can't check actId in slotmachinesActivity, machineId is:"..machineId)
        return nil
    end

    function XSlotMachineManager.NotifyAllSlotMachineInfo(req)
        XSlotMachineManager.SlotMachineAllInfoListHandle(req.SlotMachineClientDataList)
    end

    function XSlotMachineManager.StartSlotMachine(machineId)
        -- 校验
        if not machineId then
            return
        end
        local isEnough, lackCount = XSlotMachineManager.CheckConsumeItemIsEnough(machineId)
        if isEnough then
            XNetwork.Call(SLOT_MACHINE_PROTO.SlotMachineRequest, {ActivityId = ActId, Id = machineId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local machineDataEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId)
                if machineDataEntity then
                    local lastTotalScore = machineDataEntity:GetTotalScore()
                    machineDataEntity:SetRockTimes(res.RockTimes)
                    machineDataEntity:SetTotalScore(res.TotalScore)
                    machineDataEntity:SetSlotMachineRecords(res.SlotMachineRecords)

                    local addScore = res.TotalScore - lastTotalScore
                    --XEventManager.DispatchEvent(XEventId.EVENT_SLOT_MACHINE_STARTED, res.IconList, addScore)
                    CsXGameEventManager.Instance:Notify(XEventId.EVENT_SLOT_MACHINE_STARTED, res.IconList, addScore)
                end
            end)
        else
            if lackCount > 0 and ActId and ActId ~= 0 then
                if XDataCenter.SlotMachineManager.GetSlotMachineActExchangeType() == XSlotMachineConfigs.ExchangeType.Normal then
                    local exchangeRatio = XSlotMachineConfigs.GetSlotMachinesItemExchangeRatio(ActId)
                    XUiManager.DialogTip(CSXTextManagerGetText("SlotMachineExchangeTitle"), CSXTextManagerGetText("SlotMachineExchangeContent", exchangeRatio*lackCount, lackCount), XUiManager.DialogType.Normal, nil, function()
                        XSlotMachineManager.SlotMachineExchangeItem(machineId, lackCount)
                    end)
                elseif XDataCenter.SlotMachineManager.GetSlotMachineActExchangeType() == XSlotMachineConfigs.ExchangeType.OnlyTask then
                    XUiManager.TipError(CSXTextManagerGetText("SlotMachineCellBatteryNotEnough"))
                end
            end
        end

    end

    function XSlotMachineManager.GetSlotMachineReward(machineId, index)
        if not machineId or machineId == 0 or not index or index == 0 then
            XLog.Error("The Proto SlotMachineRewardRequest Param Invalid")
            return
        end

        XNetwork.Call(SLOT_MACHINE_PROTO.SlotMachineRewardRequest, {ActivityId = ActId, Id = machineId, Index = index}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.OpenUiObtain(res.RewardList)

            local machineDataEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId)

            machineDataEntity:SetRecvIndex(index)
            --XEventManager.DispatchEvent(XEventId.EVENT_SLOT_MACHINE_GET_REWARD)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_SLOT_MACHINE_GET_REWARD)
        end)
    end

    function XSlotMachineManager.SlotMachineExchangeItem(machineId, count)
        if not machineId or not count or count <= 0 then
            return
        end

        XNetwork.Call(SLOT_MACHINE_PROTO.SlotMachineExchangeItemRequest, {ActivityId = ActId, Id = machineId, ItemCount = count}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.TipText("SlotMachineExchangeSuccess", XUiManager.UiTipType.Tip)
        end)
    end

    function XSlotMachineManager.GetSlotMachineDataEntityList()
        return SlotMachineDataEntityAllList[ActId]
    end

    function XSlotMachineManager.GetSlotMachineDataEntityById(id,actId)
        local tempId = ActId
        if actId then
            tempId = actId
        end
        for _, slotMachineDataEntity in pairs(SlotMachineDataEntityAllList[tempId]) do
            if slotMachineDataEntity.Id == id then
                return slotMachineDataEntity
            end
        end
        XLog.Error("Not find SlotMachineDataEntity by Id:"..id)
    end

    function XSlotMachineManager.GetSlotMachineDataEntityByIndex(index)
        if not SlotMachineDataEntityAllList[ActId] then
            XLog.Error("Not find SlotMachineDataEntity by ActId:"..ActId)
            return
        end
        if not SlotMachineDataEntityAllList[ActId][index] then
            XLog.Error("Not find SlotMachineDataEntity by Index:"..index)
            return
        end

        return SlotMachineDataEntityAllList[ActId][index]
    end

    function XSlotMachineManager.OpenSlotMachine(actId)
        if not actId then
            return
        end

        local startTime, endTime = XSlotMachineManager.GetActivityTime(actId)
        local nowTime = XTime.GetServerNowTimestamp()
        if nowTime < startTime then
            XUiManager.TipMsg(CSXTextManagerGetText("SlotMachineTimeNotOpen"), XUiManager.UiTipType.Wrong)
            return
        elseif nowTime > endTime then
            XUiManager.TipMsg(CSXTextManagerGetText("SlotMachineTimeEnd"), XUiManager.UiTipType.Wrong)
            return
        end

        if SlotMachineDataEntityAllList[actId] and next(SlotMachineDataEntityAllList[actId]) then -- 存在老虎机数据就不请求
            ActId = actId
            XLuaUiManager.Open("UiSlotmachine")
            return
        end

        if actId and actId ~= 0 and actId ~= ActId then -- 不存在老虎机数据
            XSlotMachineManager.GetSlotMachineInfoRequest(actId, function()
                XLuaUiManager.Open("UiSlotmachine")
            end)
        end
    end

    function XSlotMachineManager.GetCurMachineId()
        local curMachineId = 0
        for _, machineDataEntity in ipairs(SlotMachineDataEntityAllList[ActId]) do
            curMachineId = machineDataEntity:GetId()
            if machineDataEntity:GetScoreLimit() > machineDataEntity:GetTotalScore() then
                return curMachineId
            end
        end
        return curMachineId
    end

    function XSlotMachineManager.GetActivityTime(actId)
        local activityId = actId or ActId
        if activityId and activityId ~= 0 then
            local startTimeStr, endTimeStr = XSlotMachineConfigs.GetActivityStartTimeByActId(activityId)
            local startTime = XTime.ParseToTimestamp(startTimeStr)
            local endTime = XTime.ParseToTimestamp(endTimeStr)
            return startTime, endTime
        end
    end

    function XSlotMachineManager.CheckSlotMachineState(machineId)
        local machineEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId)

        if not machineEntity then
            return XSlotMachineConfigs.SlotMachineState.Locked
        end

        if machineEntity:GetTotalScore() >= machineEntity:GetScoreLimit() then
            return XSlotMachineConfigs.SlotMachineState.Finish
        else
            for i = 1, #SlotMachineDataEntityAllList[ActId] do
                if SlotMachineDataEntityAllList[ActId][i]:GetId() == machineId then
                    if i == 1 then
                        return XSlotMachineConfigs.SlotMachineState.Running
                    else
                        local lastMachineEntity = SlotMachineDataEntityAllList[ActId][i-1]
                        if lastMachineEntity:GetTotalScore() >= lastMachineEntity:GetScoreLimit() then
                            return XSlotMachineConfigs.SlotMachineState.Running
                        else
                            return XSlotMachineConfigs.SlotMachineState.Locked
                        end
                    end
                end
            end
        end
    end

    function XSlotMachineManager.CheckRewardState(machineId, rewardIdx,actId)
        local machineEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId,actId)
        if not machineEntity then
            return XSlotMachineConfigs.RewardTakeState.NotFinish
        end

        if machineEntity:GetTotalScore() >= machineEntity:GetRewardScores()[rewardIdx] then
            local receiveIndex = machineEntity:GetRecvIndex()
            for _, receiveIdx in ipairs(receiveIndex) do
                if receiveIdx == rewardIdx then
                    return XSlotMachineConfigs.RewardTakeState.Took
                end
            end
            return XSlotMachineConfigs.RewardTakeState.NotTook
        else
            return XSlotMachineConfigs.RewardTakeState.NotFinish
        end
    end

    function XSlotMachineManager.GetNextMachineId(machineId)
        local machineEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId)
        if not machineEntity then
            return nil
        end

        for index, machineData in ipairs(SlotMachineDataEntityAllList[ActId]) do
            if machineData:GetId() == machineId then
                if SlotMachineDataEntityAllList[ActId][index+1] then
                    return SlotMachineDataEntityAllList[ActId][index+1]:GetId()
                else
                    return SlotMachineDataEntityAllList[ActId][1]:GetId()
                end
            end
        end
    end

    function XSlotMachineManager.FinishTask(taskId)
        XDataCenter.TaskManager.FinishTask(taskId, function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_SLOT_MACHINE_FINISH_TASK)
        end)
    end

    function XSlotMachineManager.CheckIconListIsPrix(iconIdList)
        if iconIdList and next(iconIdList) then
            local isPrix = XSlotMachineConfigs.GetSlotMachinesIconTemplateById(iconIdList[1]).IsPrix
            if not isPrix then
                return false
            end
            for _, iconId in ipairs(iconIdList) do
                if iconId ~= iconIdList[1] then
                    return false
                end
            end

            return true
        else
            return false
        end
    end

    function XSlotMachineManager.CheckConsumeItemIsEnough(machineId)
        if not machineId then
            return false
        end

        local machineEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId)
        local itemCount = XDataCenter.ItemManager.GetCount(machineEntity:GetConsumeItemId())
        local onceNeedCount = machineEntity:GetConsumeCount()

        if itemCount >= onceNeedCount then
            return true, 0
        else
            return false, (onceNeedCount - itemCount)
        end
    end

    function XSlotMachineManager.CheckCanFinishTaskByType(machineId, taskType,actId)
        if not machineId or not taskType then
            return
        end
        local machineEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId,actId)
        local taskIds = nil
        if taskType == XSlotMachineConfigs.TaskType.Daily then
            taskIds = XTaskConfig.GetTimeLimitTaskCfg(machineEntity:GetTaskDailyLimitId()).DayTaskId
        elseif taskType == XSlotMachineConfigs.TaskType.Cumulative then
            taskIds = XTaskConfig.GetTimeLimitTaskCfg(machineEntity:GetTaskCumulativeLimitId()).TaskId
        end
        if taskIds then
            for _, taskId in pairs(taskIds) do
                if XDataCenter.TaskManager.GetTaskDataById(taskId).State == XDataCenter.TaskManager.TaskState.Achieved then
                    return true
                end
            end
        end

        return false
    end

    function XSlotMachineManager.CheckHasRewardCanTake(machineId,actId)
        if not machineId then
            return
        end
        local machineEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId,actId)
        if machineEntity then
            local rewardIds = machineEntity:GetRewardIds()
            for index, _ in ipairs(rewardIds) do
                if XSlotMachineManager.CheckRewardState(machineId, index,actId) == XSlotMachineConfigs.RewardTakeState.NotTook then
                    return true
                end
            end
        end

        return false
    end

    function XSlotMachineManager.CheckTaskCanTakeByAllType(machineId,actId)
        for _, taskType in pairs(XSlotMachineConfigs.TaskType) do
            if XSlotMachineManager.CheckCanFinishTaskByType(machineId, taskType,actId) then
                return true
            end
        end

        return false
    end

    function XSlotMachineManager.GetSlotMachineActExchangeType()
        if ActId and ActId ~= 0 then
            return XSlotMachineConfigs.GetSlotMachinesItemExchangeType(ActId)
        end
    end

    function XSlotMachineManager.CheckRedPoint()
        local isRewardCanTake = false
        local isTaskCanFinish = false
        local actId = 1
        local configs = XActivityBriefConfigs.GetNowActivityEntryConfig()
        for key, value in pairs(configs) do
            if value.SkipId == 1400008 then
                actId = value.Id
            end
        end
        if not SlotMachineDataEntityAllList[actId] then
            return false
        end
        for index, machineData in ipairs(SlotMachineDataEntityAllList[actId]) do
            local machineID = machineData:GetId()
            if XSlotMachineManager.CheckHasRewardCanTake(machineID,actId) then
                isRewardCanTake = true
                break
            end
            if XSlotMachineManager.CheckTaskCanTakeByAllType(machineID,actId) then
                isTaskCanFinish = true
                break
            end
        end
        local result = isRewardCanTake or isTaskCanFinish
        return result
    end

    function XSlotMachineManager.CheckRedPointL()
        local isRewardCanTake = false
        local isTaskCanFinish = false
        local actId = 2
        local configs = XActivityBriefConfigs.GetNowActivityEntryConfig()
        for key, value in pairs(configs) do
            if value.SkipId == 1400009 then
                actId = value.Id
            end
        end
        if not SlotMachineDataEntityAllList[actId] then
            return false
        end
        for index, machineData in ipairs(SlotMachineDataEntityAllList[actId]) do
            local machineID = machineData:GetId()
            if XSlotMachineManager.CheckHasRewardCanTake(machineID,actId) then
                isRewardCanTake = true
                break
            end
            if XSlotMachineManager.CheckTaskCanTakeByAllType(machineID,actId) then
                isTaskCanFinish = true
                break
            end
        end
        local result = isRewardCanTake or isTaskCanFinish
        return result
    end

    XSlotMachineManager.Init()
    return XSlotMachineManager
    end
    
    XRpc.NotifyAllSlotMachineInfo = function(req)
        XDataCenter.SlotMachineManager.NotifyAllSlotMachineInfo(req)
    end