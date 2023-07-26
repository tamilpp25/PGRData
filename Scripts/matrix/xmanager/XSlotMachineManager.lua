local tableInsert = table.insert
local XSlotMachineDataEntity = require("XEntity/XSlotMachine/XSlotMachineDataEntity")

XSlotMachineManagerCreator = function()
    ---@class XSlotMachineManager
    local XSlotMachineManager = {}
    local ActId = 0
    ---@type table<number, XSlotMachineDataEntity[]>
    local SlotMachineDataEntityAllList = {}  --再加一层以满足多个老虎机活动存在

    local SLOT_MACHINE_PROTO = {
        GetSlotMachineInfoRequest = "GetSlotMachineInfoRequest", -- 老虎机数据请求
        SlotMachineRequest = "SlotMachineRequest", -- 老虎机抽奖请求
        SlotMachineRewardRequest = "SlotMachineRewardRequest", -- 老虎机领奖请求
    }
    function XSlotMachineManager.Init()

    end

    function XSlotMachineManager.GetSlotMachineInfoRequest(actId, cb)
        XNetwork.Call(SLOT_MACHINE_PROTO.GetSlotMachineInfoRequest, { ActivityId = actId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            ActId = actId
            XSlotMachineManager.SlotMachineInfoListHandle(res.SlotMachineDataList)
            if cb then
                cb()
            end
        end)
    end

    function XSlotMachineManager.SlotMachineInfoListHandle(slotMachineDataList)
        if XTool.IsTableEmpty(slotMachineDataList) then
            return
        end
        SlotMachineDataEntityAllList[ActId] = {}
        for _, slotMachineInfo in ipairs(slotMachineDataList) do
            local slotMachineTmp = XSlotMachineConfigs.GetSlotMachinesTemplateById(slotMachineInfo.Id)
            local slotMachineDataEntity = XSlotMachineDataEntity.New(slotMachineTmp, slotMachineInfo)
            tableInsert(SlotMachineDataEntityAllList[ActId], slotMachineDataEntity)
        end
    end

    function XSlotMachineManager.SlotMachineAllInfoListHandle(slotMachineDataList)
        if XTool.IsTableEmpty(slotMachineDataList) then
            return
        end
        for _, slotMachineInfo in ipairs(slotMachineDataList) do
            local slotMachineTmp = XSlotMachineConfigs.GetSlotMachinesTemplateById(slotMachineInfo.Id)
            local slotMachineDataEntity = XSlotMachineDataEntity.New(slotMachineTmp, slotMachineInfo)
            local tmpActId = XSlotMachineManager.CheckMachineActId(slotMachineInfo.Id)
            if tmpActId and not SlotMachineDataEntityAllList[tmpActId] then
                SlotMachineDataEntityAllList[tmpActId] = {}
            end
            tableInsert(SlotMachineDataEntityAllList[tmpActId], slotMachineDataEntity)
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
        XLog.Error("can't check actId in slotmachinesActivity, machineId is:" .. machineId)
        return nil
    end

    function XSlotMachineManager.NotifySlotMachineActivityInfo(req)
        SlotMachineDataEntityAllList = {}
        local activityIds = req.ActivityIdList or {}
        for _, activityId in pairs(activityIds) do
            local slotMachinesIds = XSlotMachineConfigs.GetSlotMachinesIdsByActivityId(activityId)
            for _, id in pairs(slotMachinesIds) do
                local slotMachineTmp = XSlotMachineConfigs.GetSlotMachinesTemplateById(id)
                local slotMachineDataEntity = XSlotMachineDataEntity.New(slotMachineTmp)
                if not SlotMachineDataEntityAllList[activityId] then
                    SlotMachineDataEntityAllList[activityId] = {}
                end
                tableInsert(SlotMachineDataEntityAllList[activityId], slotMachineDataEntity)
            end
        end
        for _, slotMachineInfo in pairs(req.SlotMachineDataList or {}) do
            local tmpActId = XSlotMachineManager.CheckMachineActId(slotMachineInfo.Id)
            local machineDataEntity = XSlotMachineManager.GetSlotMachineDataEntityById(slotMachineInfo.Id, tmpActId)
            if machineDataEntity then
                machineDataEntity:RefreshItem(slotMachineInfo)
            end
        end
    end

    function XSlotMachineManager.StartSlotMachine(machineId, targetRockTimes, cb)
        -- 校验
        if not XTool.IsNumberValid(machineId) or not XTool.IsNumberValid(targetRockTimes) then
            return
        end
        local isEnough, lackCount = XSlotMachineManager.CheckConsumeItemIsEnough(machineId, targetRockTimes)
        if isEnough then
            XNetwork.Call(SLOT_MACHINE_PROTO.SlotMachineRequest, { ActivityId = ActId, Id = machineId, TargetRockTimes = targetRockTimes }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local machineDataEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId)
                if machineDataEntity then
                    machineDataEntity:SetRockTimes(res.RockTimes)
                    machineDataEntity:SetTotalScore(res.TotalScore)
                    machineDataEntity:SetSlotMachineRecords(res.SlotMachineRecords)
                    if cb then
                        cb(res.RockResults)
                    end
                end
            end)
        else
            if lackCount > 0 and XTool.IsNumberValid(ActId) then
                XUiManager.TipText("SlotMachineCoinNotEnough")
            end
        end

    end

    function XSlotMachineManager.GetSlotMachineReward(machineId, index, cb)
        if not XTool.IsNumberValid(machineId) or not XTool.IsNumberValid(index) then
            XLog.Error("The Proto SlotMachineRewardRequest Param Invalid")
            return
        end

        XNetwork.Call(SLOT_MACHINE_PROTO.SlotMachineRewardRequest, { ActivityId = ActId, Id = machineId, Index = index }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.OpenUiObtain(res.RewardList)

            local machineDataEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId)

            machineDataEntity:SetRecvIndex(index)
            if cb then
                cb(machineId)
            end
        end)
    end

    ---@return XSlotMachineDataEntity[]
    function XSlotMachineManager.GetSlotMachineDataEntityList()
        return SlotMachineDataEntityAllList[ActId]
    end

    ---@return XSlotMachineDataEntity
    function XSlotMachineManager.GetSlotMachineDataEntityById(id, actId)
        local tempId = ActId
        if actId then
            tempId = actId
        end
        for _, slotMachineDataEntity in pairs(SlotMachineDataEntityAllList[tempId]) do
            if slotMachineDataEntity.Id == id then
                return slotMachineDataEntity
            end
        end
        XLog.Error("Not find SlotMachineDataEntity by Id:" .. id)
    end

    function XSlotMachineManager.OpenSlotMachine(actId, isOpenTask)
        if not XTool.IsNumberValid(actId) then
            return
        end

        local startTime, endTime = XSlotMachineManager.GetActivityTime(actId)
        local nowTime = XTime.GetServerNowTimestamp()
        if nowTime < startTime then
            XUiManager.TipText("SlotMachineTimeNotOpen")
            return
        elseif nowTime > endTime then
            XUiManager.TipText("SlotMachineTimeEnd")
            return
        end

        -- 存在老虎机数据就不请求
        if not XTool.IsTableEmpty(SlotMachineDataEntityAllList[actId]) then
            ActId = actId
            XSlotMachineManager.OpenMainUi(isOpenTask)
            return
        end

        -- 不存在老虎机数据
        if XTool.IsNumberValid(actId) then
            XSlotMachineManager.GetSlotMachineInfoRequest(actId, function()
                XSlotMachineManager.OpenMainUi(isOpenTask)
            end)
        end
    end

    function XSlotMachineManager.OpenMainUi(isOpenTask)
        local uiSlot = XLuaUiManager.FindTopUi("UiSlotmachine")
        if uiSlot then
            if isOpenTask then
                uiSlot.UiProxy.UiLuaTable:OnBtnTaskClick()
            end
        else
            XLuaUiManager.OpenWithCallback("UiSlotmachine", function(ui)
                if isOpenTask then
                    ui.UiProxy.UiLuaTable:OnBtnTaskClick()
                end
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
        if XTool.IsNumberValid(activityId) then
            local timeId = XSlotMachineConfigs.GetActivityTimeIdByActId(activityId)
            return XFunctionManager.GetTimeByTimeId(timeId)
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
                        local lastMachineEntity = SlotMachineDataEntityAllList[ActId][i - 1]
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

    function XSlotMachineManager.CheckRewardState(machineId, rewardIdx, actId)
        local machineEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId, actId)
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
                if SlotMachineDataEntityAllList[ActId][index + 1] then
                    return SlotMachineDataEntityAllList[ActId][index + 1]:GetId()
                else
                    return SlotMachineDataEntityAllList[ActId][1]:GetId()
                end
            end
        end
    end

    function XSlotMachineManager.CheckIconListIsPrix(iconIdList)
        if not XTool.IsTableEmpty(iconIdList) then
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

    function XSlotMachineManager.CheckConsumeItemIsEnough(machineId, targetRockTimes)
        if not XTool.IsNumberValid(machineId) or not XTool.IsNumberValid(targetRockTimes) then
            return false
        end

        local machineEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId)
        local itemCount = XDataCenter.ItemManager.GetCount(machineEntity:GetConsumeItemId())
        local onceNeedCount = machineEntity:GetConsumeCount()
        local totalNeedCount = onceNeedCount * targetRockTimes

        if itemCount >= totalNeedCount then
            return true, 0
        else
            return false, (totalNeedCount - itemCount)
        end
    end
    
    function XSlotMachineManager.CheckHasRewardCanTake(machineId, actId)
        if not XTool.IsNumberValid(machineId) then
            return
        end
        local machineEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId, actId)
        if machineEntity then
            local rewardIds = machineEntity:GetRewardIds()
            for index, _ in ipairs(rewardIds) do
                if XSlotMachineManager.CheckRewardState(machineId, index, actId) == XSlotMachineConfigs.RewardTakeState.NotTook then
                    return true
                end
            end
        end

        return false
    end

    function XSlotMachineManager.CheckTaskCanTakeByMachineId(machineId, actId)
        local machineEntity = XSlotMachineManager.GetSlotMachineDataEntityById(machineId, actId)
        if not machineEntity then
            return false
        end
        -- 日常任务
        if XDataCenter.TaskManager.CheckLimitTaskList(machineEntity:GetTaskDailyLimitId()) then
            return true
        end
        -- 累计任务
        if XDataCenter.TaskManager.CheckLimitTaskList(machineEntity:GetTaskCumulativeLimitId()) then
            return true
        end
        return false
    end

    function XSlotMachineManager.CheckRedPoint(actId)
        local isRewardCanTake = false
        local isTaskCanFinish = false
        if not SlotMachineDataEntityAllList[actId] then
            return false
        end
        for _, machineData in ipairs(SlotMachineDataEntityAllList[actId]) do
            local machineID = machineData:GetId()
            if XSlotMachineManager.CheckHasRewardCanTake(machineID, actId) then
                isRewardCanTake = true
                break
            end
            if XSlotMachineManager.CheckTaskCanTakeByMachineId(machineID, actId) then
                isTaskCanFinish = true
                break
            end
        end
        local result = isRewardCanTake or isTaskCanFinish
        return result
    end
    
    function XSlotMachineManager.OnActivityEnd()
        XLuaUiManager.RunMain()
        XUiManager.TipText("SlotMachineTimeEnd")
    end

    function XSlotMachineManager.GetSkipAnimationKey()
        if XTool.IsNumberValid(ActId) then
            return string.format("SlotMachineSkipAnimationKey_%s_%s", XPlayer.Id, ActId)
        end
    end

    function XSlotMachineManager.GetSkipAnimationValue()
        local key = XSlotMachineManager.GetSkipAnimationKey()
        local data = XSaveTool.GetData(key) or 0
        return data == 1
    end

    function XSlotMachineManager.SaveSkipAnimationValue(value)
        local key = XSlotMachineManager.GetSkipAnimationKey()
        local isSave = value == true and 1 or 0
        XSaveTool.SaveData(key, isSave)
    end

    XSlotMachineManager.Init()
    return XSlotMachineManager
end

XRpc.NotifySlotMachineActivityInfo = function(req)
    XDataCenter.SlotMachineManager.NotifySlotMachineActivityInfo(req)
end