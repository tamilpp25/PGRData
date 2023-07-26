--猜拳小游戏管理器
XFingerGuessingManagerCreator = function()
    ---@class FingerGuessingManager
    local FingerGuessingManager = {}
    -- 出拳种类
    FingerGuessingManager.FINGER_TYPE = {
        Rock = 0, -- 石头
        Paper = 1, -- 布
        Scissors = 2, -- 剪刀
    }
    -- 对局结果枚举
    FingerGuessingManager.DUEL_RESULT = {
        Win = 0, -- 胜利
        Draw = 1, -- 平局
        Lose = 2, -- 失败
    }
    --================
    --请求协议名称
    --================
    local REQUEST_NAMES = { --请求名称
        StartGame = "FingerGuessingGameStartStageRequest", -- 进入关卡
        OpenEyes = "FingerGuessingGameChangeCheatStatusRequest", -- 开启天眼
        FingerPlay = "FingerGuessingGamePlayerActionRequest", -- 出拳
    }
    ---@type XFingerGuessingGameController
    local GameControl
    function FingerGuessingManager.Init()
        local XGame = require("XEntity/XMiniGame/FingerGuessing/XFingerGuessingGameController")
        GameControl = XGame.New()
    end
    --=======================
    --刷新活动数据
    --@param data: {
    --    int ActivityId //当前活动Id
    --    List<FingerGuessingStageInfo> FingerGuessingStageData //已开启的关卡信息
    --    FingerGuessingCurrentStageInfo CurrentStageData //当前关卡信息
    --}
    --=======================
    function FingerGuessingManager.RefreshActivityData(data)
        GameControl:RefreshActivityData(data)
    end
    --=======================
    --请求出拳
    --=======================
    function FingerGuessingManager.PlayFinger(fingerId)
        XNetwork.Call(REQUEST_NAMES.FingerPlay, { PlayerTrick = fingerId }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                GameControl:RefreshCurrentStage(reply.CurrentStageInfo)
                GameControl:RefreshStageData(reply.StageChangeData)
                XEventManager.DispatchEvent(XEventId.EVENT_FINGER_GUESS_PLAY_FINGER, fingerId, reply.IsRoundWin, reply.IsStageEnd)
                if reply.IsStageEnd then GameControl:SetIsGaming(false) end
            end)
    end
    --================
    --请求开启天眼
    --================
    function FingerGuessingManager.OpenEyes(stage)
        XNetwork.Call(REQUEST_NAMES.OpenEyes, { Status = not GameControl:GetIsOpenEye() }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                GameControl:SetIsOpenEye(not GameControl:GetIsOpenEye()) 
                XEventManager.DispatchEvent(XEventId.EVENT_FINGER_GUESS_OPEN_EYE, stage:GetId())
            end)
    end
    --================
    --请求开始游戏
    --================    
    function FingerGuessingManager.StartGame(stage)
        XNetwork.Call(REQUEST_NAMES.StartGame, { StageId = stage:GetStageId()}, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                GameControl:RefreshCurrentStage(reply.CurrentStageData)
                XEventManager.DispatchEvent(XEventId.EVENT_FINGER_GUESS_GAME_START, stage)
            end)
    end
    --================
    --跳转到玩法
    --================    
    function FingerGuessingManager.JumpTo()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FingerGuessing) then
            local canGoTo, notStart = FingerGuessingManager.CheckCanGoTo()
            if canGoTo then
                if GameControl:GetIsGaming() then
                    XLuaUiManager.Open("UiFingerGuessingGame", GameControl:GetCurrentStage())
                else
                    XLuaUiManager.Open("UiFingerGuessingSelectStage")
                end
            elseif notStart then
                XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityNotStart"))
            else
                XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
            end
        end
    end
    --================
    --检查是否能进入玩法
    --@return param1:是否在活动时间内(true为在活动时间内)
    --@return param2:是否未开始活动(true为未开始活动)
    --================
    function FingerGuessingManager.CheckCanGoTo()
        local endTime = GameControl:GetActivityEndTime()
        local startTime = GameControl:GetActivityStartTime()
        local nowTime = XTime.GetServerNowTimestamp()
        local isActivityEnd = (nowTime >= endTime) and (nowTime > startTime)
        local notStart = nowTime < startTime
        return not isActivityEnd, notStart
    end
    --================
    --获取游戏控制器
    --================
    function FingerGuessingManager.GetGameController()
        return GameControl
    end
    --================
    --获取游戏控制器
    --================
    function FingerGuessingManager.GetStageByStageId(stageId)
        GameControl:GetStageByStageId()
    end
    function FingerGuessingManager.GetFirstInKey()
        return string.format("FingerGuessFirstIn_%s_%s", XPlayer.Id, GameControl:GetId())
    end
    --================
    --判断是否第一次进入玩法(本地存储纪录)
    --================
    function FingerGuessingManager.GetIsFirstIn()
        local key = FingerGuessingManager.GetFirstInKey()
        local value = XSaveTool.GetData(key) or 0
        if value == 0 then
            XSaveTool.SaveData(key, 1)
            return true
        end
        return false
    end
    function FingerGuessingManager.GetStartPlayMovieKey(stageId)
        return string.format("FingerGuessingStartPlayMovie_%s_%s_%s", XPlayer.Id, GameControl:GetId(), stageId)
    end
    -- 判断是否第一次进入关卡
    function FingerGuessingManager.GetIsFirstStartInStage(stageId)
        local key = FingerGuessingManager.GetStartPlayMovieKey(stageId)
        local value = XSaveTool.GetData(key) or 0
        if value == 0 then
            XSaveTool.SaveData(key, 1)
            return true
        end
        return false
    end
    function FingerGuessingManager.GetEndPlayMovieKey(stageId)
        return string.format("FingerGuessingEndPlayMovie_%s_%s_%s", XPlayer.Id, GameControl:GetId(), stageId)
    end
    -- 判断是否第一次结束关卡
    function FingerGuessingManager.GetIsFirstEndInStage(stageId)
        local key = FingerGuessingManager.GetEndPlayMovieKey(stageId)
        local value = XSaveTool.GetData(key) or 0
        if value == 0 then
            XSaveTool.SaveData(key, 1)
            return true
        end
        return false
    end
    FingerGuessingManager.Init()
    return FingerGuessingManager
end
--=======================
--登陆通知活动数据
--@param data: {
--    int ActivityId //当前活动Id
--    List<FingerGuessingStageInfo> FingerGuessingStageData //已开启的关卡信息
--    FingerGuessingCurrentStageInfo CurrentStageData //当前关卡信息
--}
--=======================
XRpc.NotifyFingerGuessingGameData = function(data)
    XDataCenter.FingerGuessingManager.RefreshActivityData(data)
end