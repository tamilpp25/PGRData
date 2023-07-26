XDoomsdayManagerCreator = function()
    local tableInsert = table.insert
    local pairs = pairs
    local tonumber = tonumber
    local stringFormat = string.format
    local tableUnpack = table.unpack
    local IsTableEmpty = XTool.IsTableEmpty
    local IsNumberValid = XTool.IsNumberValid

    local XDoomsdayManager = {}

    -----------------活动入口 begin----------------
    local _ActivityId = XDoomsdayConfigs.GetDefaultActivityId() --当前开放活动Id
    local _IsOpening = false --活动是否开启中（根据服务端下发活动有效Id判断）
    local _ActivityEnd = false --活动是否结束

    local function UpdateActivityId(activityId)
        XCountDown.RemoveTimer(XCountDown.GTimerName.Doomsday)

        if not IsNumberValid(activityId) then
            _ActivityId = XDoomsdayConfigs.GetDefaultActivityId()
            return
        end

        _ActivityId = activityId

        local nowTime = XTime.GetServerNowTimestamp()
        local leftTime = XDoomsdayManager.GetEndTime() - nowTime
        if leftTime > 0 then
            XCountDown.CreateTimer(XCountDown.GTimerName.Doomsday, leftTime)
        end
        if IsNumberValid(_ActivityId) and leftTime > 0 then
            XDoomsdayManager.ClearActivityEnd()
        end
        _IsOpening = true
    end

    function XDoomsdayManager.GetActivityStageIds()
        if not XDoomsdayManager.IsOpen() then
            return
        end

        local stageIds = {}
        for _, stageId in ipairs(XDoomsdayConfigs.ActivityConfig:GetProperty(_ActivityId, "StageId")) do
            if IsNumberValid(stageId) then
                tableInsert(stageIds, stageId)
            end
        end
        return stageIds
    end

    function XDoomsdayManager.IsOpen()
        if not IsNumberValid(_ActivityId) then
            return false
        end

        if not _IsOpening then
            return false
        end

        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime = XDoomsdayManager.GetStartTime()
        local endTime = XDoomsdayManager.GetEndTime()
        return beginTime <= nowTime and nowTime < endTime
    end

    function XDoomsdayManager.GetStartTime()
        return XFunctionManager.GetStartTimeByTimeId(
            XDoomsdayConfigs.ActivityConfig:GetProperty(_ActivityId, "OpenTimeId")
        ) or 0
    end

    function XDoomsdayManager.GetEndTime()
        return XFunctionManager.GetEndTimeByTimeId(
            XDoomsdayConfigs.ActivityConfig:GetProperty(_ActivityId, "OpenTimeId")
        ) or 0
    end

    function XDoomsdayManager.SetActivityEnd()
        _ActivityEnd = true

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_DOOMSDAY_ACTIVITY_END)
    end

    function XDoomsdayManager.ClearActivityEnd()
        _ActivityEnd = nil
    end

    function XDoomsdayManager.OnActivityEnd()
        if not _ActivityEnd then
            return false
        end

        if
            CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") or XLuaUiManager.IsUiLoad("UiSettleLose") or
                XLuaUiManager.IsUiLoad("UiSettleWin")
         then
            return false
        end

        --延迟是为了防止打断UI动画
        XScheduleManager.ScheduleOnce(
            function()
                XLuaUiManager.RunMain()
                XUiManager.TipText("DoomsdayActivityEnd")
            end,
            1000
        )

        XDoomsdayManager.ClearActivityEnd()

        return true
    end

    --任务分组（1.普通任务；2.日记碎片）
    local function GetTaskGroupId(index)
        if index == 1 then
            return XDoomsdayConfigs.ActivityConfig:GetProperty(_ActivityId, "TaskGroupId")
        elseif index == 2 then
            return XDoomsdayConfigs.ActivityConfig:GetProperty(_ActivityId, "DiaryTaskGroupId")
        end
    end

    --根据index获取分组任务
    function XDoomsdayManager.GetGroupTasksByIndex(index)
        return XDataCenter.TaskManager.GetTaskList(TaskType.Doomsday, GetTaskGroupId(index))
    end

    function XDoomsdayManager.CheckTaskRewardToGet(index)
        return XDataCenter.TaskManager.GetIsRewardForEx(TaskType.Doomsday, GetTaskGroupId(index))
    end

    --请求打开活动主界面
    function XDoomsdayManager.EnterUiMain()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Doomsday) then
            return
        end

        if not XDoomsdayManager.IsOpen() then
            XUiManager.TipText("DoomsdayActivityNotOpen")
            return
        end

        XLuaUiManager.Open("UiDoomsdayChapter")
    end
    
    function XDoomsdayManager.GetActivityChapters()
        local chapters = {}
        if not IsNumberValid(_ActivityId) 
                or not XFunctionManager.CheckInTimeByTimeId(XDoomsdayConfigs.ActivityConfig:GetProperty(_ActivityId, "OpenTimeId")) then
            return chapters
        end
        table.insert(chapters, {
            Id       = _ActivityId,
            Type     = XDataCenter.FubenManager.ChapterType.Doomsday,
            BannerBg = XDoomsdayConfigs.ActivityConfig:GetProperty(_ActivityId, "BannerBg"),
            Name     =  XDoomsdayConfigs.ActivityConfig:GetProperty(_ActivityId, "Name")
        })
        return chapters
    end
    -----------------活动入口 end------------------
    -----------------玩法战斗相关（单局生存解谜） begin------------------
    local XDoomsdayStage = require("XEntity/XDoomsday/XDoomsdayStage")

    local _StageDataDic = {} --每一关战斗数据
    local _HistoryStageDataDic = {} --每一关历史战斗数据（只记录前一天）
    local _StageFinishedMainTargetDic = {} --每一关通关后达成的主目标（主目标全部达成后算作通关）
    local _StageFinishedSubTargetDic = {} --每一关通关后达成的子目标
    local _StageFinishedEndingIds = {} --每一关达成的结局Id

    local function GetStageData(stageId)
        if not IsNumberValid(stageId) then
            XLog.Error("XDoomsdayManager GetStageData error: Invalid stageId: ", stageId)
            return
        end

        local stageData = _StageDataDic[stageId]
        if not stageData then
            stageData = XDoomsdayStage.New(stageId)
            _StageDataDic[stageId] = stageData
        end
        return stageData
    end
    XDoomsdayManager.GetStageData = GetStageData

    local function ResetStageData(stageId)
        _StageDataDic[stageId]:Reset()
        XDoomsdayManager.UpdateStageState(stageId)
        _HistoryStageDataDic[stageId] = nil
    end

    local function RecordHistoryStageData(stageId, data)
        if not IsNumberValid(stageId) then
            return
        end

        local stageData = XDoomsdayStage.New(stageId)
        stageData:UpdateData(data)
        _HistoryStageDataDic[stageId] = stageData
    end

    local function GetHistoryStageData(stageId)
        if not IsNumberValid(stageId) then
            XLog.Error("XDoomsdayManager GetHistoryStageData error: Invalid stageId: ", stageId)
            return
        end
        return _HistoryStageDataDic[stageId]
    end
    XDoomsdayManager.GetHistoryStageData = GetHistoryStageData

    local function UpdateStageData(data)
        if XTool.IsTableEmpty(data) then
            return
        end
        GetStageData(data.Id):UpdateData(data)
        --XDoomsdayManager.CheckSettle(data.Id)
    end

    local function UpdateStageDataEx(data)
        local stageId = data.Id
        --更新已经达成的结局
        XDoomsdayManager.UpdateStageFinishedEndingIds(stageId, data.HistoryEndingIds)
        --更新关卡信息
        local stageInfo = data.Cur
        if not IsTableEmpty(stageInfo) then
            UpdateStageData(stageInfo)
        end

        local lastDayData = data.LastDay
        if not XTool.IsTableEmpty(lastDayData) then
            if lastDayData.DayCount + 1 == stageInfo.DayCount then
                RecordHistoryStageData(stageId, lastDayData)
            end
        end

        XDoomsdayManager.UpdateStageFinishedMainTargetDic(stageId, {data.MainTaskId}, data.SubTaskId)
    end

    --更新已完成关卡主目标/子目标
    function XDoomsdayManager.UpdateStageFinishedMainTargetDic(stageId, targetIds, subTargetIds)
        local targetDic = _StageFinishedMainTargetDic[stageId]
        if not targetDic then
            targetDic = {}
            _StageFinishedMainTargetDic[stageId] = targetDic
        end
        for _, targetId in pairs(targetIds) do
            if XTool.IsNumberValid(targetId) then
                targetDic[targetId] = targetId
            end
        end

        targetDic = _StageFinishedSubTargetDic[stageId]
        if not targetDic then
            targetDic = {}
            _StageFinishedSubTargetDic[stageId] = targetDic
        end
        for _, targetId in pairs(subTargetIds) do
            if XTool.IsNumberValid(targetId) then
                targetDic[targetId] = targetId
            end
        end

        XDoomsdayManager.UpdateStageState(stageId)
    end
    
    --更新关卡的结局Id
    function XDoomsdayManager.UpdateStageFinishedEndingIds(stageId, endingIds)
        _StageFinishedEndingIds[stageId] = endingIds
    end

    --检查关卡开放
    local function CheckStageOpening()
        for _, stageId in pairs(XDoomsdayManager.GetActivityStageIds(_ActivityId) or {}) do
            GetStageData(stageId):SetProperty("_Opening", XDoomsdayManager.IsStageOpening(stageId))
        end
    end

    function XDoomsdayManager.CheckHasStageIncomplete()
        for _, stageId in pairs(XDoomsdayManager.GetActivityStageIds(_ActivityId) or {}) do
            if XDoomsdayManager.IsStageOpening(stageId) and (not XDoomsdayManager.IsStagePassed(stageId)) then
                return true
            end
        end
        return false
    end

    --更新关卡已通关状态
    function XDoomsdayManager.UpdateStageState(stageId)
        local stageData = GetStageData(stageId)

        stageData:SetProperty("_Star", XTool.GetTableCount(_StageFinishedSubTargetDic[stageId]))

        --local passed = not IsTableEmpty(_StageFinishedMainTargetDic[stageId])
        local passed = XDoomsdayManager.IsStagePassed(stageId)
        stageData:SetProperty("_Passed", passed)

        CheckStageOpening()
    end

    --关卡是否开放
    function XDoomsdayManager.IsStageOpening(stageId)
        local preStageId = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "PreStage")
        if not IsNumberValid(preStageId) then
            return true
        end
        return XDoomsdayManager.IsStagePassed(preStageId)
    end

    --关卡是否通关
    function XDoomsdayManager.IsStagePassed(stageId)
        --return _StageFinishedMainTargetDic[stageId] and not IsTableEmpty(_StageFinishedMainTargetDic[stageId]) or false
        local endingIds = _StageFinishedEndingIds[stageId]
        if XTool.IsTableEmpty(endingIds) then
            return false
        end
        for _, endingId in ipairs(endingIds) do
            local passed = XDoomsdayConfigs.StageEndingConfig:GetProperty(endingId, "IsSuccess")
            if passed then
                return true
            end
        end
        return false
    end

    --关卡子目标是否达成
    function XDoomsdayManager.IsStageSubTargetFinished(stageId, targetId)
        return _StageFinishedSubTargetDic[stageId] and IsNumberValid(_StageFinishedSubTargetDic[stageId][targetId]) or
            false
    end

    --获取指定关卡通关星数（达成目标数量）,总星数（总目标数量）
    function XDoomsdayManager.GetStageStarProgress(stageId)
        local finisedCount, totalCount = 0, 0
        local totalTargetIds = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "SubTaskId")
        for _, targetId in pairs(totalTargetIds) do
            if IsNumberValid(targetId) then
                if XDoomsdayManager.IsStageSubTargetFinished(stageId, targetId) then
                    finisedCount = finisedCount + 1
                end
                totalCount = totalCount + 1
            end
        end
        return finisedCount, totalCount
    end

    --获取当天居民死亡人数
    function XDoomsdayManager.GetInhabitantDeadCount(stageId)
        return GetStageData(stageId):GetProperty("_CurDeathCount")
    end

    --获取和前一天历史数据对比: 居民死亡人数文本描述
    function XDoomsdayManager.GetInhabitantDeadCountText(stageId)
        local str = ""

        local num = XDoomsdayManager.GetInhabitantDeadCount(stageId)
        if num > 0 then
            str = XDoomsdayConfigs.GetNumberText(-num, false, false, true)
        end

        return str
    end
    
    --获取和前一天历史数据对比：居民人数变化
    function XDoomsdayManager.GetInhabitantCountChangeText(stageId)
        local str = ""
        local today     = GetStageData(stageId):GetProperty("_InhabitantCount") or 0
        local yesterdayStage = GetHistoryStageData(stageId)
        local yesterday = yesterdayStage and yesterdayStage:GetProperty("_InhabitantCount") or 0
        local num = today - yesterday
        if num ~= 0 then
            str = XDoomsdayConfigs.GetNumberText(num, false, false, true)
        end
        return str
    end

    --获取和前一天历史数据对比: 居民平均属性文本描述
    function XDoomsdayManager.GetAverageInhabitantAttrValueText(stageId, attrType)
        local str = ""

        local history = GetHistoryStageData(stageId)
        if not history then
            return str
        end

        local num =
            GetStageData(stageId):GetAverageInhabitantAttr(attrType):GetProperty("_Value") -
            history:GetAverageInhabitantAttr(attrType):GetProperty("_Value")

        if num > 0 then
            str = XDoomsdayConfigs.GetNumberText(num, false, false, true)
        end

        return str
    end

    --获取和前一天历史数据对比: 异常状态居民数量变化记录列表
    function XDoomsdayManager.GetUnhealthyInhabitantChangeCountList(stageId)
        local list = {}

        local history = GetHistoryStageData(stageId)
        if not history then
            return {}
        end

        local tmpDic = {}
        for _, info in pairs(history:GetProperty("_UnhealthyInhabitantInfoList")) do
            tmpDic[info.AttrType] = info.Count
        end

        for _, info in pairs(GetStageData(stageId):GetProperty("_UnhealthyInhabitantInfoList")) do
            local oldCount = tmpDic[info.AttrType] or 0
            tableInsert(
                list,
                {
                    AttrType = info.AttrType,
                    Count = info.Count,
                    ChangeCount = info.Count - oldCount
                }
            )
        end

        return list
    end

    --获取和前一天历史数据对比: 居民属性变化记录列表
    function XDoomsdayManager.GetInhabitantAttrChangeList(stageId)
        local list = {}

        local history = GetHistoryStageData(stageId)
        if not history then
            return {}
        end

        local stageData = GetStageData(stageId)
        local oldInfoList = history:GetProperty("_AverageInhabitantAttrList")
        local newInfoList = stageData:GetProperty("_AverageInhabitantAttrList")
        for index, info in pairs(newInfoList) do
            if oldInfoList[index] then
                tableInsert(
                    list,
                    {
                        AttrType = info._Type,
                        Count = info._Value,
                        ChangeCount = info._Value - oldInfoList[index]._Value
                    }
                )
            end
        end

        return list
    end

    --生成资源报告
    local ResourceReportIds = {
        XDoomsdayConfigs.REPORT_ID.BUILDING_ADD, --营地增加资源
        XDoomsdayConfigs.REPORT_ID.TEAM_ADD --探索小队增加资源/居民数量
    }
    function XDoomsdayManager.GenerateResourceReports(stageId)
        local reports = {}
        local stageData = XDoomsdayManager.GetStageData(stageId)
        for _, reportId in ipairs(ResourceReportIds) do
            local addResourceDic = {}
            local addInhabitantCount = 0
            if reportId == XDoomsdayConfigs.REPORT_ID.BUILDING_ADD then
                addResourceDic = stageData:GetProperty("_BuildingHistoryResourceDic")
            elseif reportId == XDoomsdayConfigs.REPORT_ID.TEAM_ADD then
                addResourceDic = stageData:GetProperty("_TeamHistoryResourceDic")
                addInhabitantCount = stageData:GetProperty("_TeamHistoryAddInhabitant")
            end

            local report = XDoomsdayConfigs.GetRandomReportTextFix(reportId, addResourceDic, addInhabitantCount)
            if not string.IsNilOrEmpty(report) then
                table.insert(reports, report)
            end
        end
        return reports
    end

    --生成居民报告
    local InHabitantReportIds = {
        XDoomsdayConfigs.REPORT_ID.DEAD, --死去居民文本显示
        XDoomsdayConfigs.REPORT_ID.HOMELESS, --不良状态随机文本(无家可归)
        XDoomsdayConfigs.REPORT_ID.UNHEALTHY, --不良状态随机文本(不健康)
        XDoomsdayConfigs.REPORT_ID.HUNGER, --不良状态随机文本(饥饿)
        XDoomsdayConfigs.REPORT_ID.LOW_SAN --不良状态随机文本(精神值过低)
    }
    function XDoomsdayManager.GenerateInhabitantReports(stageId)
        local reports = {}
        local stageData = XDoomsdayManager.GetStageData(stageId)
        local finishEndingId = stageData:GetProperty("_FinishEndingId")
        local isFinishEnd = XTool.IsNumberValid(finishEndingId)
        --达成失败结局
        if isFinishEnd and not stageData:IsWin() then
            local desc = XDoomsdayConfigs.StageEndingConfig:GetProperty(finishEndingId, "Desc")
            tableInsert(reports, desc)
            return reports
        end
        for _, reportId in ipairs(InHabitantReportIds) do
            local addInhabitantCount = 0
            if reportId == XDoomsdayConfigs.REPORT_ID.DEAD then
                addInhabitantCount = XDataCenter.DoomsdayManager.GetInhabitantDeadCount(stageId)
                if not XTool.IsNumberValid(addInhabitantCount) then
                    reportId = nil
                end
            elseif reportId == XDoomsdayConfigs.REPORT_ID.HOMELESS then
                if not stageData:CheckInhabitantAttrBad(XDoomsdayConfigs.HOMELESS_ATTR_TYPE) then
                    reportId = XDoomsdayConfigs.REPORT_ID.HOMELESS_RT
                end
            elseif reportId == XDoomsdayConfigs.REPORT_ID.UNHEALTHY then
                if not stageData:CheckInhabitantAttrBad(XDoomsdayConfigs.ATTRUBUTE_TYPE.HEALTH) then
                    reportId = XDoomsdayConfigs.REPORT_ID.UNHEALTHY_RT
                end
            elseif reportId == XDoomsdayConfigs.REPORT_ID.HUNGER then
                if not stageData:CheckInhabitantAttrBad(XDoomsdayConfigs.ATTRUBUTE_TYPE.HUNGER) then
                    reportId = XDoomsdayConfigs.REPORT_ID.HUNGER_RT
                end
            elseif reportId == XDoomsdayConfigs.REPORT_ID.LOW_SAN then
                if not stageData:CheckInhabitantAttrBad(XDoomsdayConfigs.ATTRUBUTE_TYPE.SAN) then
                    reportId = XDoomsdayConfigs.REPORT_ID.LOW_SAN_RT
                end
            end

            local report = reportId and XDoomsdayConfigs.GetRandomReportTextBad(reportId, addInhabitantCount) or nil
            if not string.IsNilOrEmpty(report) then
                table.insert(reports, report)
            end
        end
        return reports
    end
    
    --获取和前一天历史数据对比，资源产/消
    function XDoomsdayManager.GetResourceChangeCountList(stageId)
        local list = {}
        
        local history = GetHistoryStageData(stageId)
        if not history then
            return list
        end
        
        local tmpDic = {}
        local resourceIds = XDoomsdayConfigs.GetResourceIds()
        for _, rId in ipairs(resourceIds) do
            local lastResource = history:GetResource(rId)
            local curResource = GetStageData(stageId):GetResource(rId)
            local curCount = curResource:GetProperty("_Count")
            local lastCount = lastResource:GetProperty("_Count")
            tableInsert(list, {
                Id = rId,
                CurCount = curCount,
                LastCount = lastCount,
                ChangeCount = curCount - lastCount
            })
        end
        return list
    end
    
    --==============================
     ---@desc 往播报队列内插入数据
     ---@stageId 关卡Id 
     ---@type 播报类型 
     ---@count 数量，目前只有死亡播报需要数量
    --==============================
    function XDoomsdayManager.UpdateBroadcast(stageId, type, count)
        local stageData = XDoomsdayManager.GetStageData(stageId)
        if not stageData then
            return
        end
        stageData:PushBroadcast(type, count)
    end
    
    --请求进入战斗
    local function DoomsdayEnterStageRequest(stageId, cb)
        local req = {StageId = stageId}
        XNetwork.Call(
            "DoomsdayEnterStageRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateStageData(res.StageDb)

                if cb then
                    cb()
                end
            end
        )
    end

    --请求重新开始
    local function DoomsdayResetStageRequest(stageId, cb)
        local req = {StageId = stageId}
        XNetwork.Call(
            "DoomsdayResetStageRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                ResetStageData(stageId)
                UpdateStageData(res.StageDb)

                if cb then
                    cb()
                end
            end
        )
    end

    --进入关卡界面
    function XDoomsdayManager.EnterFight(stageId, restart)
        local stageData = XDoomsdayManager.GetStageData(stageId)

        local asynReqEnter = asynTask(DoomsdayEnterStageRequest)
        local asynReqRestart = asynTask(DoomsdayResetStageRequest)
        local asynOpen = asynTask(XLuaUiManager.Open)
        local asynEnterEventUI = asynTask(XDoomsdayManager.EnterEventUiPurely)
        RunAsyn(
            function()
                if restart then
                    asynReqRestart(stageId)
                else
                    asynReqEnter(stageId)
                end
                --清除已弹出事件
                stageData:ClearPoppedEvent()
                
                XLuaUiManager.Open("UiDoomsdayFubenMainGameMovie", stageId) --黑幕弹窗

                asynWaitSecond(XDoomsdayConfigs.BLACK_MASK_DURATION)

                XLuaUiManager.Close("UiDoomsdayFubenMainGameMovie") --黑幕弹窗关闭

                XLuaUiManager.Open("UiDoomsdayFubenMain", stageId) --玩法主UI

                --存在自动弹出事件时全部按顺序自动弹出（进入关卡/下一天/完成上一个事件之后检查）
                --local popedEventIdDic = {}
                --while true do
                --    --if XDoomsdayManager.CheckSettle(stageId) then
                --    --    return
                --    --end
                --
                --    local autoEvent = stageData:GetNextPopupEvent(popedEventIdDic)
                --    if XTool.IsTableEmpty(autoEvent) then
                --        break
                --    end
                --
                --    asynEnterEventUI(stageId, autoEvent)
                --end
                local autoEvent = stageData:GetNextPopupEvent()
                if autoEvent then
                    asynEnterEventUI(stageId, autoEvent)
                end

                --asynOpen("UiDoomsdayAllot", stageId) --资源分配弹窗
            end
        )
    end

    --请求进入下一天
    local function DoomsdayNextDayRequest(stageId, cb)
        local req = {StageId = stageId}
        XNetwork.Call(
            "DoomsdayNextDayRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateStageDataEx(res.StageDbExt)

                local stageData = GetStageData(stageId)
                stageData:UpdateBuildingHistoryResource(res.BuildingAddResource)
                stageData:UpdateTeamHistoryResource(res.TeamAddResource)
                stageData:SetProperty("_IsLastDay", res.IsEnd)
                local curDeathCount = res.DeathCount or 0
                stageData:SetProperty("_CurDeathCount", curDeathCount)
                if cb then
                    cb()
                end
            end
        )
    end

    --开始下一天
    function XDoomsdayManager.EnterNextDay(stageId)
        local stageData = GetStageData(stageId)
        --检查主要事件是否完成
        if not stageData:IsEventsFinished(XDoomsdayConfigs.EVENT_TYPE.MAIN) then
            XUiManager.TipText("DoomsdayMainEventNotFinish")
            return
        end

        local asynReq = asynTask(DoomsdayNextDayRequest)
        local asynOpen = asynTask(XLuaUiManager.Open)
        local asynEnterEventUI = asynTask(XDoomsdayManager.EnterEventUiPurely)
        local asyncBroadcast = asynTask(stageData.DispatchBroadcast)
        RunAsyn(
            function()
                asynReq(stageId)

                --if XDoomsdayManager.CheckSettle(stageId) then
                --    return
                --end

                XLuaUiManager.Open("UiDoomsdayFubenMainGameMovie", stageId) --黑幕弹窗
                asynWaitSecond(XDoomsdayConfigs.BLACK_MASK_DURATION)
                XLuaUiManager.Close("UiDoomsdayFubenMainGameMovie")

                asynOpen("UidoomsdayReport", stageId) --结算报告

                --存在自动弹出事件时全部按顺序自动弹出（进入关卡/下一天/完成上一个事件之后检查）
                --local popedEventIdDic = {}
                --while true do
                --    --if XDoomsdayManager.CheckSettle(stageId) then
                --    --    return
                --    --end
                --    local autoEvent = stageData:GetNextPopupEvent(popedEventIdDic)
                --    if XTool.IsTableEmpty(autoEvent) then
                --        break
                --    end
                --    asynEnterEventUI(stageId, autoEvent)
                --end

                local autoEvent = stageData:GetNextPopupEvent()
                if autoEvent then
                    asynEnterEventUI(stageId, autoEvent)
                end

                asyncBroadcast(stageData)

                --asynOpen("UiDoomsdayAllot", stageId) --资源分配弹窗
            end
        )
    end

    --检查结算（失败结局直接弹结算）
    local Settling = false --结算UI展示中
    function XDoomsdayManager.CheckSettle(stageId)
        if Settling then
            return true
        end

        local stageData = GetStageData(stageId)
        if not stageData:GetProperty("_Fighting") then
            return false
        end

        --仅在强制失败/正常到达最后一天时进行结算流程
        if not stageData:GetProperty("_ForceLose") and not stageData:GetProperty("_IsLastDay") then
            return false
        end

        if not XLuaUiManager.IsUiLoad("UiDoomsdayFubenMain") then
            return false
        end
        
        local finishEndingId = stageData:GetProperty("_FinishEndingId")
        local isFinishEnd = XTool.IsNumberValid(finishEndingId)
        --未达成任何结局
        if not isFinishEnd then
            return false
        end
        --达成成功结局，结算权交给玩家
        if isFinishEnd and stageData:IsWin() then
            return false
        end

        local asynOpen = asynTask(XLuaUiManager.Open)
        RunAsyn(
            function()
                Settling = true
                --达成结局，但是失败结局
                XLuaUiManager.Open("UiDoomsdayFubenMainGameMovie", stageId, true) --黑幕弹窗
                asynWaitSecond(XDoomsdayConfigs.BLACK_MASK_DURATION)
                XLuaUiManager.Close("UiDoomsdayFubenMainGameMovie")

                XLuaUiManager.Remove("UidoomsdayEvent") --关闭玩法事件UI
                XLuaUiManager.Remove("UiDoomsdayFubenMain") --关闭玩法主UI
                XLuaUiManager.Remove("UiDoomsdayExplore") --关闭玩法探索UI

                asynOpen("UiDoomsdaySettle", stageId) --副本结算UI
                ResetStageData(stageId)

                Settling = false
            end
        )

        return true
    end
    
    --请求结束关卡
    local function DoomsdayStageFinishRequest(stageId, cb) 
        XNetwork.Call("DoomsdayStageFinishRequest", {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            UpdateStageDataEx(res.StageDbExt)

            if cb then cb() end
        end)
    end
    
    --结束本关
    function XDoomsdayManager.FinishStage(stageId)
        local stageData = GetStageData(stageId)
        --检查主要事件是否完成
        if not stageData:CheckEndEventFinish() then
            XUiManager.TipText("DoomsdayMainEventNotFinish")
            return
        end
        local asyncReq = asynTask(DoomsdayStageFinishRequest)
        local asyncOpen = asynTask(XLuaUiManager.Open)
        RunAsyn(function()
            --请求结束关卡
            asyncReq(stageId)
            --结算黑幕
            XLuaUiManager.Open("UiDoomsdayFubenMainGameMovie", stageId, true)
            asynWaitSecond(XDoomsdayConfigs.BLACK_MASK_DURATION)
            XLuaUiManager.Close("UiDoomsdayFubenMainGameMovie")
            --移除UI
            XLuaUiManager.Remove("UidoomsdayEvent") --关闭玩法事件UI
            XLuaUiManager.Remove("UiDoomsdayFubenMain") --关闭玩法主UI
            XLuaUiManager.Remove("UiDoomsdayExplore") --关闭玩法探索UI
            --副本结算
            asyncOpen("UiDoomsdaySettle", stageId) --副本结算UI
            --重置副本数据
            ResetStageData(stageId)
        end)
    end

    --打开事件弹窗/跳转到事件指定UI
    function XDoomsdayManager.EnterEventUi(stageId, event, closeCb)
        local stageData = GetStageData(stageId)
        local placeId = stageData:GetEventPlaceId(event._Id)
        if XTool.IsNumberValid(placeId) then
            if not XLuaUiManager.IsUiShow("UiDoomsdayExplore") then
                XLuaUiManager.Open("UiDoomsdayExplore", stageId, placeId)
            end
        end

        XLuaUiManager.Open("UidoomsdayEvent", stageId, event, closeCb)
    end

    --仅打开事件弹窗
    function XDoomsdayManager.EnterEventUiPurely(stageId, event, closeCb)
        XLuaUiManager.Open("UidoomsdayEvent", stageId, event, closeCb)
    end

    --请求创建探索队伍
    function XDoomsdayManager.DoomsdayCreateTeamRequest(stageId, teamIndex, cb)
        local stageData = GetStageData(stageId)
        local inhabitantIds =
            stageData:GetSortedIdleInhabitantIdsByCount(
            XDoomsdayConfigs.CreatTeamConfig:GetProperty(teamIndex, "CostInhabitantCount"),
            nil,
            true
        )

        local req = {MemberIdList = inhabitantIds}
        XNetwork.Call(
            "DoomsdayCreateTeamRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                stageData:AddTeam(teamIndex, res.TeamDb)
                stageData:UpdateInhabitants(res.PeopleDbs)
                stageData:UpdateResourceList(res.ResourceList)
                stageData:UpdateTargets(res.TaskDbList)

                if cb then
                    cb()
                end
            end
        )
    end

    --请求使用指定队伍探索地点
    function XDoomsdayManager.DoomsdayTargetPlaceRequest(stageId, teamIndex, placeId, cb)
        local stageData = GetStageData(stageId)

        local team = stageData:GetTeam(teamIndex)
        if team:IsEmpty() then
            XLog.Error(
                "XDoomsdayManager.DoomsdayCreateTeamRequest error: team not exist, teamIndex: ",
                teamIndex,
                stageData
            )
            return
        end

        local req = {TeamId = team:GetProperty("_Id"), PlaceId = placeId}
        XNetwork.Call(
            "DoomsdayTargetPlaceRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                team:Explore(placeId)
                stageData:UpdateTeamState()

                XUiManager.TipMsg(
                    CsXTextManagerGetText(
                        "DoomsdayExploreTarget",
                        XDoomsdayConfigs.PlaceConfig:GetProperty(placeId, "Name")
                    )
                )

                if cb then
                    cb()
                end
            end
        )
    end

    --请求完成事件
    function XDoomsdayManager.DoomsdayDoEventRequest(stageId, eventId, selectIndex, cb)
        --SelectIndex从0开始
        local req = {EventId = eventId, SelectIndex = selectIndex - 1}
        XNetwork.Call(
                "DoomsdayDoEventRequest", req, function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        return
                    end

                    UpdateStageData(res.StageDb)

                    if cb then cb() end

                    XDoomsdayManager.CheckSettle(stageId)

                    local stageData = XDoomsdayManager.GetStageData(stageId)
                    local autoEvent = stageData:GetNextPopupEvent()
                    if autoEvent then
                        XDoomsdayManager.EnterEventUiPurely(stageId, autoEvent)
                    end
                end
        )
    end

    --请求放弃关卡目标
    function XDoomsdayManager.DoomsdayGiveUpTargetRequest(stageId, taskId, cb)
        local req = {TaskId = taskId}
        XNetwork.Call(
            "DoomsdayDiveupTaskRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                UpdateStageData(res.StageDb)
                if cb then
                    cb()
                end
            end
        )
    end

    --请求分配居民
    function XDoomsdayManager.DoomsdayOpPeopleRequest(stageId, buildingIndex, inhabitantCount, isReplace, cb)
        local stageData = GetStageData(stageId)
        local tmpInhabitantIdDic = isReplace and stageData:GetBuildingWorkingInhabitantIdDic(buildingIndex) or {} --临时撤下的居民Id字典
        local inhabitantIds = stageData:GetSortedIdleInhabitantIdsByCount(inhabitantCount, tmpInhabitantIdDic)
        local buildingId = stageData:GetBuilding(buildingIndex):GetProperty("_Id")
        local req = {BuildingId = buildingId, Ids = inhabitantIds}
        XNetwork.Call(
            "DoomsdayOpPeopleRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                stageData:AllocateInhabitants(inhabitantIds, buildingIndex)

                if cb then
                    cb()
                end
            end
        )
    end

    --请求撤回已分配居民
    function XDoomsdayManager.ZeroDoomsdayOpPeopleRequest(stageId, buildingIndex, cb)
        local inhabitantIds = XDoomsdayManager.GetStageData(stageId):GetBuildingWorkingInhabitantIds(buildingIndex)
        local req = {BuildingId = 0, Ids = inhabitantIds}
        XNetwork.Call(
            "DoomsdayOpPeopleRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                GetStageData(stageId):RecallInhabitants(inhabitantIds)

                if cb then
                    cb()
                end
            end
        )
    end

    --请求建造建筑
    function XDoomsdayManager.DoomsdayAddBuildingRequest(
        stageId,
        buildingIndex,
        buildingCfgId,
        inhabitantCount,
        isReplace,
        cb)
        local tmpInhabitantIdDic =
            isReplace and GetStageData(stageId):GetBuildingWorkingInhabitantIdDic(buildingIndex) or {} --临时撤下的居民Id字典
        local inhabitantIds =
            XDoomsdayManager.GetStageData(stageId):GetSortedIdleInhabitantIdsByCount(
            inhabitantCount,
            tmpInhabitantIdDic
        )
        local req = {BuildingCfgId = buildingCfgId, Pos = buildingIndex - 1, PeopleIds = inhabitantIds}
        XNetwork.Call(
            "DoomsdayAddBuildingRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                UpdateStageData(res.StageDb)

                if cb then
                    cb()
                end
            end
        )
    end

    --请求拆除建筑
    function XDoomsdayManager.DoomsdayRemoveBuildingRequest(stageId, buildingIndex, cb)
        local stageData = GetStageData(stageId)
        local buildingId = stageData:GetBuilding(buildingIndex):GetProperty("_Id")
        local req = {BuildingId = buildingId}
        XNetwork.Call(
            "DoomsdayRemoveBuildingRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                stageData:DeleteBuilding(buildingIndex)
                stageData:UpdateInhabitants(res.PeopleList)
                stageData:UpdateResourceList(res.ResourceList)
                stageData:SetProperty("_UnlockTeamCount", res.UnlockTeamCount)

                if cb then
                    cb()
                end
            end
        )
    end

    --请求分配资源
    function XDoomsdayManager.DoomsdayOpResourceRequest(stageId, allocations, cb)
        local req = {Ops = {}} --服务端请求协议格式
        local result = {} --分配操作结果缓存
        local alloated = false --是否进行了分配操作

        for _, allocation in pairs(allocations) do
            local resourceId = allocation.ResourceId

            local allocationInfo = result[resourceId]
            if not allocationInfo then
                allocationInfo = {}
                result[resourceId] = allocationInfo
            end
            local stageData = GetStageData(stageId)
            allocationInfo.AllocatedCount, allocationInfo.InhabitantResourceDic =
                stageData[allocation.AllocationType](stageData, allocation.ResourceId)

            --是否进行分配操作
            if
                not (XTool.IsTableEmpty(allocationInfo.InhabitantResourceDic) or
                    not XTool.IsNumberValid(allocationInfo.AllocatedCount))
             then
                alloated = true
            end

            --重组协议格式
            if not XTool.IsTableEmpty(allocationInfo.InhabitantResourceDic) then
                local data = {
                    Id = resourceId,
                    TargetList = {}
                }
                for inhabitantId, resourceCount in pairs(allocationInfo.InhabitantResourceDic) do
                    tableInsert(
                        data.TargetList,
                        {
                            Type = 0,
                            Id = inhabitantId,
                            Count = resourceCount
                        }
                    )
                end
                tableInsert(req.Ops, data)
            end
        end

        if not alloated then
            if cb then
                cb()
            end
            return
        end

        XNetwork.Call(
            "DoomsdayOpResourceRequest",
            req,
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                --扣除已分配资源
                local addResourceDic = {}
                for resourceId, allocationInfo in pairs(result) do
                    addResourceDic[resourceId] = -allocationInfo.AllocatedCount
                end
                GetStageData(stageId):AddResource(addResourceDic)

                if cb then
                    cb()
                end
            end
        )
    end
    -----------------玩法战斗相关（单局生存解谜） end------------------
    -----------------Cookie begin------------------
    function XDoomsdayManager.GetCookieKey(keyStr)
        if not keyStr then
            return
        end
        if not IsNumberValid(_ActivityId) then
            return
        end
        return stringFormat("XDoomsdayManager_%d_%d_%s", XPlayer.Id, _ActivityId, keyStr)
    end

    --检查Cookie是否存在
    function XDoomsdayManager.CheckCookieExist(keyStr)
        return XDoomsdayManager.GetCookie(keyStr) and true or false
    end

    --获取Cookie
    function XDoomsdayManager.GetCookie(keyStr)
        local key = XDoomsdayManager.GetCookieKey(keyStr)
        if not key then
            return
        end
        return XSaveTool.GetData(key)
    end

    --设置Cookie
    function XDoomsdayManager.SetCookie(keyStr, value)
        local key = XDoomsdayManager.GetCookieKey(keyStr)
        if not key then
            return
        end
        value = value or 1
        XSaveTool.SaveData(key, value)
    end
    -----------------Cookie end------------------
    local function ResetData()
        XDoomsdayManager.SetActivityEnd()

        _ActivityId = 0 --当前开放活动Id
        _IsOpening = false -- 活动是否开启中（根据服务端下发活动有效Id判断）
        _StageDataDic = {} --每一关战斗数据
        _HistoryStageDataDic = {} --每一关历史战斗数据（只记录前一天）
        _StageFinishedMainTargetDic = {} --每一关通关后达成的主目标（主目标全部达成后算作通关）
        _StageFinishedSubTargetDic = {} --每一关通关后达成的子目标
    end

    local function UpdateActivityData(data)
        for _, info in pairs(data or {}) do
            UpdateStageDataEx(info)
        end

        --检查关卡开放
        CheckStageOpening()
    end

    --登录下发
    function XDoomsdayManager.NotifyDoomsdayDbChange(data)
        local aData = data.ActivityDb

        local activityId = aData.ActivityId
        if IsNumberValid(_ActivityId) and activityId ~= _ActivityId then
            ResetData()
        end

        UpdateActivityId(activityId)
        UpdateActivityData(aData.StageDbExtList)
    end

    function XDoomsdayManager.NotifyDoomsdayStageChange(data)
        UpdateStageData(data.StageDb)
    end
    
    --播报更新
    function XDoomsdayManager.NotifyDoomsdayBroadcastAction(data)
        local action = data.Action
        local stageId = action.StageId
        XDoomsdayManager.UpdateBroadcast(stageId, action.ActionType, action.DeathCount)
    end

    return XDoomsdayManager
end
---------------------Notify begin------------------
XRpc.NotifyDoomsdayDbChange = function(data)
    XDataCenter.DoomsdayManager.NotifyDoomsdayDbChange(data)
end

XRpc.NotifyDoomsdayStageChange = function(data)
    XDataCenter.DoomsdayManager.NotifyDoomsdayStageChange(data)
end

XRpc.NotifyDoomsdayBroadcastAction = function(data) 
    XDataCenter.DoomsdayManager.NotifyDoomsdayBroadcastAction(data)
end
---------------------Notify end------------------
