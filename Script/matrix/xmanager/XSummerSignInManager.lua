XSummerSignInManagerCreator = function()
    local XSummerSignInManager = {}

    local ActivityId = 0 -- 活动Id
    local SurplusTimes = 0 -- 剩余可签到次数
    local MsgIdList = {} -- 已领取的留言Id列表
    
    local RequestProto = {
        SummerSignInRequest = "SummerSignInRequest" -- 夏日签到
    }
    
    -- 打开活动主界面
    function XSummerSignInManager.OnOpenMain()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SummerSignIn) then
            return
        end
        
        if not XSummerSignInManager.IsOpen() then
            XUiManager.TipText("CommonActivityNotStart")
            return
        end
        
        XLuaUiManager.Open("UiSummerSignInMain")
    end
    
    function XSummerSignInManager.GetEndTime()
        if not XTool.IsNumberValid(ActivityId) then
            return 0
        end
        local timeId = XSummerSignInConfigs.GetActivityTimeId(ActivityId)
        return XFunctionManager.GetEndTimeByTimeId(timeId)
    end
    
    function XSummerSignInManager.IsOpen()
        if not XTool.IsNumberValid(ActivityId) then
            return false
        end
        local timeId = XSummerSignInConfigs.GetActivityTimeId(ActivityId)
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end
    
    function XSummerSignInManager.GetActivityMessageId()
        if not XTool.IsNumberValid(ActivityId) then
            return {}
        end
        
        return XSummerSignInConfigs.GetActivityMessageId(ActivityId)
    end
    
    function XSummerSignInManager.HandleActivityEndTime()
        XUiManager.TipText("CommonActivityEnd")
        XLuaUiManager.RunMain()
    end
    
    -- 夏日签到
    -- messageId 留言Id
    function XSummerSignInManager.SummerSignInRequest(messageId, cb)
        local req = { MessageId = messageId }

        XNetwork.Call(RequestProto.SummerSignInRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            XSummerSignInManager.UpdateMsgIdList(messageId)
            SurplusTimes = SurplusTimes - 1
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_SUMMER_SIGNIN_UPDATE)
            
            if cb then
                cb(res.RewardGoodsList)
            end
        end)
    end
    
    -- 获取签到进度
    function XSummerSignInManager.GetActivitySignInProgress()
        if not XTool.IsNumberValid(ActivityId) then
            return 0, 0
        end
        local MessageIds = XSummerSignInConfigs.GetActivityMessageId(ActivityId)
        local currentProgress = 0
        local totalProgress = #MessageIds

        for _, messageId in pairs(MessageIds) do
            if XSummerSignInManager.CheckCanMsgIdList(messageId) then
                currentProgress = currentProgress + 1
            end
        end
        return currentProgress, totalProgress
    end

    -- 检测是否打开打脸界面
    function XSummerSignInManager.CheckIsNeedAutoWindow()
        -- 有未打开的便签
        if not XSummerSignInManager.CheckCanFinishAllSignIn() then
            return true
        end
        return false
    end
    
    -- 检测是否完成所以签到
    function XSummerSignInManager.CheckCanFinishAllSignIn()
        if not XTool.IsNumberValid(ActivityId) then
            return true
        end
        local MessageIds = XSummerSignInConfigs.GetActivityMessageId(ActivityId)
        for _, messageId in pairs(MessageIds) do
            if not XSummerSignInManager.CheckCanMsgIdList(messageId) then
                return false
            end
        end
        return true
    end
    
    -- 检测剩余签到次数， 小于等于0是返回true
    function XSummerSignInManager.CheckSurplusTimes()
        return SurplusTimes <= 0
    end
    
    -- 检测MsgId是否已签到
    function XSummerSignInManager.CheckCanMsgIdList(msgId)
        for _, v in pairs(MsgIdList or {}) do
            if v == msgId then
                return true
            end
        end
        return false
    end
    
    function XSummerSignInManager.UpdateMsgIdList(msgId)
        for _, v in pairs(MsgIdList or {}) do
            if v == msgId then
                return
            end
        end
        
        MsgIdList[#MsgIdList + 1] = msgId
    end
    
    function XSummerSignInManager.NotifySummerSignInData(data)
        if XTool.IsNumberValid(data.ActId) then
            ActivityId = data.ActId
        end
        SurplusTimes = data.SurplusTimes
        MsgIdList = data.MsgIdList
    end
    
    function XSummerSignInManager.Init()
    end

    XSummerSignInManager.Init()
    return XSummerSignInManager
end

XRpc.NotifySummerSignInData = function(data)
    XDataCenter.SummerSignInManager.NotifySummerSignInData(data)
end