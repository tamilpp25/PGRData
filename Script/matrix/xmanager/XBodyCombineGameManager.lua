
XBodyCombineGameManagerCreator = function()

    --region 局部变量
    local XBodyCombineGameManager   = {}
    local _ActivityId               = {}
    local _IsOpening                = false
    local _CurActivityStageData     = {} --当前活动的关卡数据
    local _CurActivityStageIds      = {} --当前活动的关卡id
    local _UnLockStageIds           = {} --已解锁关卡
    local _PassStage                = {}
    local _RequestFunctionName      = {
        BodyCombineUnlockRequest = "BodyCombineUnlockRequest",
        BodyCombineFinishRequest = "BodyCombineFinishRequest",
    }
    local _IsCheckFinishAll         = false --检查是否存在未通过关卡，每次登陆只提示一次


    --引用
    local XBodyCombineStage = require("XEntity/XBodyCombineGame/XBodyCombineStage")

    --endregion

    --region 全局变量

    --关卡状态
    XBodyCombineGameManager.StageState = {
        --可进入
        Come = 1,
        --已通过
        Pass = 2,
        --锁定
        Lock = 3,
    }

    --解锁的状态
    XBodyCombineGameManager.LockState = {
        --已经解锁
        Unlocked = 1,
        --前置关卡未通
        NoPassPreStage = 2,
        --金币不足
        NoEnoughCoin = 3,
        --可解锁
        CanUnlock = 4
    }
    --endregion

    --region 局部函数

    --===========================================================================
    ---@desc 初始化活动Id
    --===========================================================================
    local InitActivity = function(activityId)
        if XTool.IsNumberValid(activityId) then
            _ActivityId = activityId
        else
            _ActivityId = XBodyCombineGameConfigs.GetDefaultActivityId()
        end
    end

    --===========================================================================
    ---@desc 初始化活动数据
    --===========================================================================
    local InitStageData = function(activityId, stageInfos)
        local stageData = XBodyCombineGameConfigs.GetStageData()
        local curStageData = {}
        _CurActivityStageIds = {}
        
        --获取符合当前活动的关卡数据
        for _, config in ipairs(stageData) do
            local actId = config.ActivityId
            if actId == activityId then
                local stageId = config.StageId
                if not curStageData[stageId] then
                    curStageData[stageId] = {}
                    --相同关卡Id只插入一次
                    table.insert(_CurActivityStageIds, stageId)
                end
                table.insert(curStageData[stageId], config)
            end
        end
        
        --创建关卡类
        for idx, stageId in ipairs(_CurActivityStageIds) do
            local stageName = CSXTextManagerGetText("BodyCombineGameStageName", XTool.ConvertNumberString(idx))
            local data = curStageData[stageId]
            if data then
                local stage = XBodyCombineStage.New(stageId, data, stageName)
                _CurActivityStageData[stageId] = stage
            end
        end

        --根据服务端信息初始化关卡信息
        for _, info in ipairs(stageInfos or {}) do
            if info then
                _PassStage[info.StageId] = info.IsFinish == 1
                _UnLockStageIds[info.StageId] = true
            end
        end
    end

    --endregion

    --region 外部接口

    --===========================================================================
    ---@desc 活动是否开放
    --===========================================================================
    function XBodyCombineGameManager.IsOpen()
        if not XTool.IsNumberValid(_ActivityId) then
            return false
        end

        if not _IsOpening then
            return false
        end

        return XBodyCombineGameManager.IsDuringOpenTime()
    end

    --===========================================================================
    ---@desc 是否在活动持续时间内
    --===========================================================================
    function XBodyCombineGameManager.IsDuringOpenTime()
        local timeOfNow = XTime.GetServerNowTimestamp()
        local timeOfBgn = XBodyCombineGameConfigs.GetActivityStartTime(_ActivityId)
        local timeOfEnd = XBodyCombineGameConfigs.GetActivityEndTime(_ActivityId)

        return timeOfNow >= timeOfBgn and timeOfNow < timeOfEnd
    end

    --===========================================================================
    ---@desc 跳转到活动内
    --===========================================================================
    function XBodyCombineGameManager.JumpTo()

        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.BodyCombineGame) then
            return
        end

        if not XBodyCombineGameManager.IsOpen() then
           XUiManager.TipText("CommonActivityNotStart")
           return
        end

        XLuaUiManager.Open("UiBodyCombineGameMain")
    end

    --===========================================================================
    ---@desc 任务进度
    ---@return {int} finish 已经完成
    ---@return {int} total  总任务
    --===========================================================================
    function XBodyCombineGameManager.TaskProgress()
        local taskList = XDataCenter.TaskManager.GetTaskList(TaskType.BodyCombineGame)
        local finish = 0
        local total = #taskList
        if not taskList then
            return  finish, total
        end

        for _, task in ipairs(taskList or {}) do
            if task.State == XDataCenter.TaskManager.TaskState.Finish then
                finish = finish + 1
            end
        end
        return finish, total
    end

    --===========================================================================
    ---@desc 当前活动的关卡Id
    --===========================================================================
    function XBodyCombineGameManager.GetCurActivityStageIds()
        return _CurActivityStageIds
    end
    
    --===========================================================================
     ---@desc 当前关卡
     ---@return @type XBodyCombineStage
    --===========================================================================
    function XBodyCombineGameManager.GetStage(stageId)
        return _CurActivityStageData[stageId]
    end

    --===========================================================================
    ---@desc 关卡状态
    --===========================================================================
    function XBodyCombineGameManager.GetStageState(stageId)
        if _PassStage[stageId] then
            return XBodyCombineGameManager.StageState.Pass
        elseif _UnLockStageIds[stageId] then
            return XBodyCombineGameManager.StageState.Come
        else
            return XBodyCombineGameManager.StageState.Lock
        end

    end

    --===========================================================================
    ---@desc 活动货币Id
    --===========================================================================
    function XBodyCombineGameManager.GetCoinItemId()
        return XBodyCombineGameConfigs.GetCoinItemId()
    end

    --===========================================================================
    ---@desc 活动Title图
    --===========================================================================
    function XBodyCombineGameManager.GetActivityTitle()
        return XBodyCombineGameConfigs.GetActivityTitle(_ActivityId)
    end

    --===========================================================================
    ---@desc 获取活动剩余时间，带单位
    --===========================================================================
    function XBodyCombineGameManager.GetActivityLeftTime()
        local timeOfNow = XTime.GetServerNowTimestamp()
        local timeOfEnd = XBodyCombineGameConfigs.GetActivityEndTime(_ActivityId)
        return XUiHelper.GetTime(timeOfEnd - timeOfNow, XUiHelper.TimeFormatType.ACTIVITY)
    end

    --===========================================================================
    ---@desc 是否全部通过
    --===========================================================================
    function XBodyCombineGameManager.IsFinishAll()
        local pass = 0
        for _, state in ipairs(_PassStage or {}) do
            if state then
                pass = pass + 1
            end
        end
        local total = XTool.GetTableCount(_CurActivityStageData)
        return total ~= 0 and pass == total
    end

    --===========================================================================
    ---@desc 完成所有关卡的图
    --===========================================================================
    function XBodyCombineGameManager.GetFinishBanner()
        return XBodyCombineGameConfigs.GetActivityFinishBanner(_ActivityId)
    end
    
    --===========================================================================
     ---@desc 检查活动是否结束
    --===========================================================================
    function XBodyCombineGameManager.CheckIsActivityFinish()

        if not _IsOpening or not XBodyCombineGameManager.IsOpen() then
            XEventManager.DispatchEvent(XEventId.EVENT_BODYCOMBINEGAME_ACTIVITY_END)
        end
    end

    --===========================================================================
     ---@desc 活动结束回调
    --===========================================================================
    function XBodyCombineGameManager.OnActivityEnd()
        XLuaUiManager.RunMain()
        XUiManager.TipText("CommonActivityEnd")
    end

    --===========================================================================
     ---@desc 获取关卡解锁状态
    --===========================================================================
    function XBodyCombineGameManager.GetLockState(stageId)
        if not XTool.IsNumberValid(stageId) then
            return XBodyCombineGameManager.LockState.Unlocked
        end
        local state = XBodyCombineGameManager.GetStageState(stageId)
        if state ~= XBodyCombineGameManager.StageState.Lock then
            return XBodyCombineGameManager.LockState.Unlocked
        end

        local stage = XBodyCombineGameManager.GetStage(stageId)
        local preStageId = stage:GetPreStageId()
        --前置关卡未通
        if not _PassStage[preStageId] and XTool.IsNumberValid(preStageId) then
            return XBodyCombineGameManager.LockState.NoPassPreStage
        end
        local cost = stage:GetCost()
        local itemId = XDataCenter.BodyCombineGameManager.GetCoinItemId()
        local hasCount = XDataCenter.ItemManager.GetCount(itemId)
        --金币不足
        if cost > hasCount then
            return XBodyCombineGameManager.LockState.NoEnoughCoin
        end
        --可解锁
        return XBodyCombineGameManager.LockState.CanUnlock
    end
    
    --==============================
     ---@desc 首次进入活动
     ---@return boolean
    --==============================
    function XBodyCombineGameManager.IsFirstTimeIn()
        local key = "XBodyCombineGameManager_"..XPlayer.Id.."_".._ActivityId.."_FistTimeIn"
        local data = XSaveTool.GetData(key)
        if not data then
            XSaveTool.SaveData(key, true)
            return true
        end
        return false
    end


    --endregion

    --region 双端交互


    --===========================================================================
    ---@desc 请求解锁关卡
    --===========================================================================
    function XBodyCombineGameManager.BodyCombineUnlockRequest(stageId, cb)
        local req = { StageId = stageId }

        XNetwork.Call(_RequestFunctionName.BodyCombineUnlockRequest, req, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            --解锁关卡成功
            _UnLockStageIds[stageId] = true

            if cb then
                cb()
            end
        end)
    end

    --===========================================================================
    ---@desc 完成关卡
    --===========================================================================
    function XBodyCombineGameManager.BodyCombineFinishRequest(stageId, scrollData, cb)
        local req = { StageId = stageId, ScrollData = scrollData }

        XNetwork.Call(_RequestFunctionName.BodyCombineFinishRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            --关卡通关成功
            _PassStage[stageId] = true
            if cb then
                cb()
            end
        end)
    end

    --===========================================================================
    ---@desc 登录下发 data = XBodyCombineGameDataDb
    --public class XBodyCombineGameDataDb
    --{
    --      public int ActivityId;
    --      -- 已经解锁的关卡
    --      public List<XBodyCombineGameStageInfo> StageInfos = new List<XBodyCombineGameStageInfo>();
    --}
    --public calss XBodyCombineGameStageInfo
    --{
    --      public int StageId;
    --      public int Finishid; 0 解锁但未完成， 1 解锁且已经完成
    --}
    --===========================================================================
    function XBodyCombineGameManager.NotifyBodyCombineGame(data)
        local actId = data.ActivityId
        _IsOpening = actId > 0 and true or false
        InitActivity(actId)
        XBodyCombineGameManager.CheckIsActivityFinish()
        InitStageData(actId, data.StageInfos)
    end

    --endregion

    --region 红点检测

    --===========================================================================
     ---@desc 有奖励可领取
    --===========================================================================
    function XBodyCombineGameManager.CheckRewardRedPoint()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.BodyCombineGame) then
            return false
        end

        if not XBodyCombineGameManager.IsOpen() then
            return false
        end

        local taskList = XDataCenter.TaskManager.GetTaskList(TaskType.BodyCombineGame)
        for _, task in ipairs(taskList) do
            if task.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
        return false
    end
    
    --===========================================================================
     ---@desc 检测是否全部通关-每次登陆检查一次
    --===========================================================================
    function XBodyCombineGameManager.CheckIsFinishAll()     
        --已经检查过
        if _IsCheckFinishAll then
            return false
        end

        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.BodyCombineGame) then
            return false
        end

        if not XBodyCombineGameManager.IsOpen() then
            return false
        end
   
        if not XBodyCombineGameManager.IsFinishAll() then
            _IsCheckFinishAll = true
            return true
        end
        
        return false
    end
    
    --===========================================================================
     ---@desc 检查是否有新的关卡可解锁
    --===========================================================================
    function XBodyCombineGameManager.CheckUnlockedStage(stageId)
        if not XTool.IsNumberValid(stageId) then
            return false
        end
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.BodyCombineGame) then
            return false
        end

        if not XBodyCombineGameManager.IsOpen() then
            return false
        end

        -- 有新关卡可解锁
        local lockState = XBodyCombineGameManager.GetLockState(stageId)
        if lockState == XBodyCombineGameManager.LockState.CanUnlock then
            return true
        end    
        return false
    end
    --endregion
    
    return XBodyCombineGameManager
end

---==============================
   ---@desc: XRPC 
---==============================
XRpc.NotifyBodyCombineGame = function(data) 
    XDataCenter.BodyCombineGameManager.NotifyBodyCombineGame(data.BodyCombineGameDataDb)
end