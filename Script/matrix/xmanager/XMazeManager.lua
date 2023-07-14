local XExFubenActivityManager = require("XEntity/XFuben/XExFubenActivityManager")

-- 2023年情人节活动
XMazeManagerCreator = function()
    local RequestProto = {
        GetTicket = "MazeGetTicketRequest",
        SetRobotId = "MazeSetRobotRequest",
    }

    ---@class XMazeManager
    local XMazeManager = XExFubenActivityManager.New(XFubenConfigs.ChapterType.Maze, "MazeManager")

    local _IsGetTicket = false
    local _PartnerRobotId = false
    local _Stage = {}

    function XMazeManager.SetActivityData(data)
        --// 当前重置计数
        --public int ResetCount;
        --
        --// 领取重置计数
        --public int AwardResetCount;

        if data.ActivityId then
            XMazeConfig.SetActivityId(data.ActivityId)
        end
        _IsGetTicket = data.IsGetTicket
        _PartnerRobotId = data.RobotId
        _Stage = data.PassStages
    end

    function XMazeManager.IsOpen()
        local timeId = XMazeConfig.GetTimeId()
        if XFunctionManager.CheckInTimeByTimeId(timeId) then
            return true
        end
        return false
    end

    function XMazeManager.OpenMain()
        if XMazeManager.IsOpen() then
            XLuaUiManager.Open("UiMazeMain")
        else
            XUiManager.TipText("CommonActivityNotStart")
        end
    end

    function XMazeManager:ExGetProgressTip()
        local str = ""
        if not self:ExGetIsLocked() then
            local finishCount, totalCount = XMazeManager.GetTaskProgress()
            str = XUiHelper.GetText("StrongholdActivityProgress", finishCount, totalCount)
        end
        return str
    end

    function XMazeManager.GetPassedStageAmount()
        local allStage = _Stage
        local amountPassed = 0
        for i, stage in pairs(allStage) do
            if stage.MaxScore >= 0 then
                amountPassed = amountPassed + 1
            end
        end
        return amountPassed
    end

    function XMazeManager.IsStagePassed(stageId)
        local allStage = _Stage
        for i, stage in pairs(allStage) do
            if stage.StageId == stageId then
                return true
            end
        end
        return false
    end

    function XMazeManager.GetTaskList()
        local taskId = XMazeConfig.GetTaskId()
        return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskId)
    end

    local TaskState = XDataCenter.TaskManager.TaskState
    function XMazeManager.GetTaskProgress()
        local taskAmount, finishAmount = 0, 0
        local taskId = XMazeConfig.GetTaskId()
        if taskId and taskId > 0 then
            local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskId, false)
            if taskList then
                for i = 1, #taskList do
                    local taskData = taskList[i]
                    if taskData.State == TaskState.Finish then
                        finishAmount = finishAmount + 1
                    end
                    taskAmount = taskAmount + 1
                end
            end
        end
        return finishAmount, taskAmount
    end

    function XMazeManager.IsTaskCanGetReward()
        local taskId = XMazeConfig.GetTaskId()
        if taskId and taskId > 0 then
            local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskId, false)
            if taskList then
                for i = 1, #taskList do
                    local taskData = taskList[i]
                    if taskData.State == TaskState.Achieved then
                        return true
                    end
                end
            end
        end
        return false
    end

    function XMazeManager.IsGetTicket()
        return _IsGetTicket
    end

    function XMazeManager.GetPartnerRobotId()
        return _PartnerRobotId
    end

    function XMazeManager.InitStageInfo()
        -- 关卡池的关卡
        local configs = XMazeConfig.GetAllStageConfig()
        local stageInfo = nil
        for _, stageConfig in pairs(configs) do
            local stageId = stageConfig.StageId
            stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.Maze
            else
                XLog.Error("[XMazeManager] 找不到配置的关卡id：", stageId)
            end
        end
    end

    function XMazeManager.PreFight(stage, teamId, isAssist, challengeCount)
        local robotId = XMazeManager.GetPartnerRobotId()
        return {
            StageId = stage.StageId,
            IsHasAssist = isAssist,
            ChallengeCount = challengeCount,
            CaptainPos = 1,
            FirstFightPos = 1,
            CardIds = {},
            RobotIds = { robotId },
        }
    end

    function XMazeManager.ShowReward(winData)
        local data = winData.SettleData.MazeResult
        XLuaUiManager.Open("UiMazeSettle", data)
    end

    function XMazeManager.RequestSetPartnerRobotId(robotId)
        XNetwork.Call(RequestProto.SetRobotId, {
            RobotId = robotId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _PartnerRobotId = robotId
            XEventManager.DispatchEvent(XEventId.EVENT_MAZE_UPDATE_ROBOT_SELECTED)
        end)
    end

    function XMazeManager.AutoRequestGetTicket()
        if _IsGetTicket then
            return
        end
        if not XMazeManager.IsOpen() then
            return
        end
        XNetwork.Call(RequestProto.GetTicket, {}, function(res)
            if res.Code ~= XCode.Success then
                --XUiManager.TipCode(res.Code)
                return
            end
            _IsGetTicket = true
            local rewardGoodList = res.RewardGoodsList
            if #rewardGoodList > 0 then
                XUiManager.OpenUiObtain(rewardGoodList)
            end
        end)
    end

    function XMazeManager.GetPlayerPrefsKey()
        return string.format("ValentinesDay2023_Open_UI_First_Time_%s", XPlayer.Id)
    end
    
    function XMazeManager.IsFirstTime()
        local isFirstTimeOpenUi = CS.UnityEngine.PlayerPrefs.GetInt(XMazeManager.GetPlayerPrefsKey(), 1)
        return isFirstTimeOpenUi == 1
    end

    return XMazeManager
end

XRpc.NotifyMazeData = function(res)
    XDataCenter.MazeManager.SetActivityData(res)
end