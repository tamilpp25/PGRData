local XPassportBaseInfo = require("XEntity/XPassport/XPassportBaseInfo")
local XPassportInfo = require("XEntity/XPassport/XPassportInfo")

XPassportManagerCreator = function()
    local BaseInfo = XPassportBaseInfo.New()            --基础信息
    local PassportInfosDic = {}                         --已解锁通行证字典
    local LastTimeBaseInfo = XPassportBaseInfo.New()    --上一期活动基础信息
    local CurrMainViewSelectTagIndex                    --缓存主界面选择的页签

    ---------------------本地接口 begin------------------
    local UpdatePassportInfosDic = function(passportInfos)
        local passportInfo
        for _, data in pairs(passportInfos) do
            passportInfo = PassportInfosDic[data.Id]
            if not passportInfo then
                passportInfo = XPassportInfo.New()
                PassportInfosDic[data.Id] = passportInfo
            end
            passportInfo:UpdateData(data)
        end
    end

    local SetPassportReceiveReward = function(passportId, passportRewardId)
        local passportInfo = XDataCenter.PassportManager.GetPassportInfos(passportId)
        if passportInfo then
            passportInfo:SetReceiveReward(passportRewardId)
        end
    end
    ---------------------本地接口 end------------------
    local XPassportManager = {}

    --获得玩家通行证信息
    --id：通行证id
    function XPassportManager.GetPassportInfos(passportId)
        return PassportInfosDic[passportId]
    end

    --是否已领取奖励
    function XPassportManager.IsReceiveReward(passportId, passportRewardId)
        local rewardId = XPassportConfigs.GetPassportRewardId(passportRewardId)
        if not XTool.IsNumberValid(rewardId) then   --没配置奖励作已领取处理
            return true
        end

        local passportInfo = XPassportManager.GetPassportInfos(passportId)
        return passportInfo and passportInfo:IsReceiveReward(passportRewardId)
    end

    --是否可领取奖励
    function XPassportManager.IsCanReceiveReward(passportId, passportRewardId)
        local passportInfo = XPassportManager.GetPassportInfos(passportId)
        local isUnLock = passportInfo and true or false
        local baseInfo = XPassportManager.GetPassportBaseInfo()
        local currLevel = baseInfo:GetLevel()
        local levelCfg = XPassportConfigs.GetPassportRewardLevel(passportRewardId)
        return currLevel >= levelCfg and isUnLock
    end

    function XPassportManager.GetPassportBaseInfo()
        return BaseInfo
    end

    function XPassportManager.GetPassportLastTimeBaseInfo()
        return LastTimeBaseInfo
    end

    ---------------------红点 begin---------------------
    --通行证检查是否可领取等级奖励
    function XPassportManager.CheckPassportRewardRedPoint()
        local baseInfo = XPassportManager.GetPassportBaseInfo()
        local currLevel = baseInfo:GetLevel()
        local typeInfoIdList = XPassportConfigs.GetPassportActivityIdToTypeInfoIdList()
        local passportRewardIdList
        local levelCfg

        for _, passportId in ipairs(typeInfoIdList) do
            if XPassportManager.GetPassportInfos(passportId) then
                passportRewardIdList = XPassportConfigs.GetPassportRewardIdList(passportId)
                for _, passportRewardId in ipairs(passportRewardIdList) do
                    levelCfg = XPassportConfigs.GetPassportRewardLevel(passportRewardId)
                    if currLevel < levelCfg then
                        break
                    end
                    if not XPassportManager.IsReceiveReward(passportId, passportRewardId) then
                        return true
                    end
                end
            end
        end
        return false
    end

    function XPassportManager.CheckPassportAchievedTaskRedPoint(taskType)
        local taskIdList = taskType == XPassportConfigs.TaskType.Activity and XPassportConfigs.GetPassportBPTask() or XPassportConfigs.GetPassportTaskGroupCurrOpenTaskIdList(taskType)
        for _, taskId in pairs(taskIdList) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                return true
            end
        end
        return false
    end
    ---------------------红点 end-----------------------

    ---------------------活动入口 begin---------------------
    --活动是否已结束
    function XPassportManager.IsActivityClose()
        local nowServerTime = XTime.GetServerNowTimestamp()
        local timeId = XPassportConfigs.GetPassportActivityTimeId()
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        return nowServerTime >= endTime
    end

    --检查活动没开回主界面
    function XPassportManager.CheckActivityIsOpen(isNotRunMain)
        local timeId = XPassportConfigs.GetPassportActivityTimeId()
        if not XFunctionManager.CheckInTimeByTimeId(timeId) then
            if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
                return false
            end

            XUiManager.TipText("CommonActivityNotStart")
            if not isNotRunMain then
                XLuaUiManager.RunMain()
            end
            return false
        end
        return true
    end

    function XPassportManager.OpenMainUi()
        if not XDataCenter.PassportManager.CheckActivityIsOpen(true) then
            return
        end
        XLuaUiManager.Open("UiPassport")
    end
    ---------------------活动入口 end-----------------------

    ---------------------主界面 begin---------------------
    function XPassportManager.CatchCurrMainViewSelectTagIndex(currSelectTagIndex)
        CurrMainViewSelectTagIndex = currSelectTagIndex
    end

    function XPassportManager.GetCurrMainViewSelectTagIndex()
        return CurrMainViewSelectTagIndex or 1
    end
    ---------------------主界面 end-----------------------

    ---------------------任务 begin------------------
    function XPassportManager.GetClearTaskCount(taskType)
        local taskIdList = taskType == XPassportConfigs.TaskType.Activity and XPassportConfigs.GetPassportBPTask() or XPassportConfigs.GetPassportTaskGroupCurrOpenTaskIdList(taskType)
        local clearTotalCount = 0
        for _, taskId in ipairs(taskIdList) do
            if XDataCenter.TaskManager.CheckTaskFinished(taskId) then
                clearTotalCount = clearTotalCount + 1
            end
        end
        return clearTotalCount
    end

    function XPassportManager.GetPassportTask(taskType)
        local taskIdList = taskType == XPassportConfigs.TaskType.Activity and XPassportConfigs.GetPassportBPTask() or XPassportConfigs.GetPassportTaskGroupCurrOpenTaskIdList(taskType)
        local taskList = {}
        local tastData
        for _, taskId in pairs(taskIdList) do
            tastData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if tastData then
                table.insert(taskList, tastData)
            end
        end

        local achieved = XDataCenter.TaskManager.TaskState.Achieved
        local finish = XDataCenter.TaskManager.TaskState.Finish
        table.sort(taskList, function(a, b)
            if a.State ~= b.State then
                if a.State == achieved then
                    return true
                end
                if b.State == achieved then
                    return false
                end
                if a.State == finish then
                    return false
                end
                if b.State == finish then
                    return true
                end
            end

            local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(a.Id)
            local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(b.Id)
            return templatesTaskA.Priority > templatesTaskB.Priority
        end)

        return taskList
    end

    --返回当前任务列表中已获得的经验，和能获得的总经验
    function XPassportManager.GetPassportTaskExp(passportTaskGroupId)
        if not XTool.IsNumberValid(passportTaskGroupId) then
            return 0, 0
        end

        local taskIdList = XPassportConfigs.GetPassportTaskGroupTaskIdList(passportTaskGroupId)
        local rewardId
        local totalExp = 0
        local currExp = 0
        local rewards
        local itemId = XDataCenter.ItemManager.ItemId.PassportExp
        local isTaskFinish

        for _, taskId in ipairs(taskIdList) do
            rewardId = XTaskConfig.GetTaskRewardId(taskId)
            rewards = XRewardManager.GetRewardList(rewardId)
            isTaskFinish = XDataCenter.TaskManager.CheckTaskFinished(taskId)
            for _, v in pairs(rewards) do
                if v.TemplateId == itemId then
                    totalExp = totalExp + v.Count
                    if isTaskFinish then
                        currExp = currExp + v.Count
                    end
                end
            end
        end

        return currExp, totalExp
    end

    function XPassportManager.GetPassportAchievedTaskIdList(taskType)
        local taskIdList = taskType == XPassportConfigs.TaskType.Activity and XPassportConfigs.GetPassportBPTask() or XPassportConfigs.GetPassportTaskGroupCurrOpenTaskIdList(taskType)
        local achievedTaskIdList = {}
        local tastData
        for _, taskId in pairs(taskIdList) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                table.insert(achievedTaskIdList, taskId)
            end
        end
        return achievedTaskIdList
    end
    ---------------------任务 end--------------------

    ---------------------奖励 begin-----------------------
    function XPassportManager.GetCookieAutoGetTaskRewardList()
        local key = XPassportManager.GetAutoGetTaskRewardListCookieKey()
        return XSaveTool.GetData(key)
    end

    function XPassportManager.InsertCookieAutoGetTaskRewardList(rewardList)
        local key = XPassportManager.GetAutoGetTaskRewardListCookieKey()
        local cookieRewardList = XPassportManager.GetCookieAutoGetTaskRewardList()
        if cookieRewardList then
            for _, rewardData in ipairs(rewardList) do
                table.insert(cookieRewardList, rewardData)
            end
        end
        XSaveTool.SaveData(key, cookieRewardList or rewardList)
    end

    function XPassportManager.ClearCookieAutoGetTaskRewardList()
        local key = XPassportManager.GetAutoGetTaskRewardListCookieKey()
        XSaveTool.RemoveData(key)
    end

    function XPassportManager.GetAutoGetTaskRewardListCookieKey()
        local activityId = XPassportConfigs.GetDefaultActivityId()
        return XPlayer.Id .. "_XPassportManager_AutoGetTaskRewardList" .. activityId
    end
    ---------------------奖励 end-----------------------
    
    ---------------------protocol begin------------------
    --登录推送数据
    function XPassportManager.NotifyPassportData(data)
        XPassportConfigs.SetDefaultActivityId(data.ActivityId)
        BaseInfo:SetToLevel(data.Level or data.BaseInfo.Level)
        LastTimeBaseInfo:UpdateData(data.LastTimeBaseInfo)

        UpdatePassportInfosDic(data.PassportInfos)
        XEventManager.DispatchEvent(XEventId.EVENT_NOTIFY_PASSPORT_DATA)
    end

    --通知基础信息变化
    function XPassportManager.NotifyPassportBaseInfo(data)
        BaseInfo:UpdateData(data.Level or data.BaseInfo.Level)
        XEventManager.DispatchEvent(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO)
    end

    --通知自动领取任务奖励列表
    function XPassportManager.NotifyPassportAutoGetTaskReward(data)
        XPassportManager.InsertCookieAutoGetTaskRewardList(data.RewardList or {})
        XEventManager.DispatchEvent(XEventId.EVENT_AUTO_GET_TASK_REWARD_LIST)
    end

    --购买通行证请求
    function XPassportManager.RequestPassportBuyPassport(id, cb)
        -- 英文服还原日服改动
        XNetwork.Call("PassportBuyPassportRequest", { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local name = XPassportConfigs.GetPassportTypeInfoName(id)
            local msg = CS.XTextManager.GetText("SuccessfulItemPurchase", name)
            XUiManager.TipMsg(msg)
            
            if not XTool.IsTableEmpty(res.RewardList) then
                XUiManager.OpenUiObtain(res.RewardList)
            end
            UpdatePassportInfosDic({res.PassportInfo})
            
            if cb then
                cb()
            end

            XEventManager.DispatchEvent(XEventId.EVENT_BUY_PASSPORT_COMPLEATE)
        end)

        -- -- 检查购买时间限制
        -- local earlyEndTime = XPassportConfigs.GetPassportBuyPassPortEarlyEndTime()
        -- local timeNow = XTime.GetServerNowTimestamp()
        -- local endTime = XFunctionManager.GetEndTimeByTimeId(XPassportConfigs.GetPassportActivityTimeId())
        -- if timeNow  >= endTime - earlyEndTime then
        --     XUiManager.TipText("PassportBuyTimeAlreadyEnd")
        --     return
        -- end
        -- local payKeySuffix = XPassportConfigs.GetPassportTypeInfoPayKeySuffix(id)
        -- if string.IsNilOrEmpty(payKeySuffix) then
        --     XNetwork.Call("PassportBuyPassportRequest", { Id = id }, function(res)
        --         if res.Code ~= XCode.Success then
        --             XUiManager.TipCode(res.Code)
        --             return
        --         end

        --         local name = XPassportConfigs.GetPassportTypeInfoName(id)
        --         local msg = CS.XTextManager.GetText("SuccessfulItemPurchase", name)
        --         XUiManager.TipMsg(msg)

        --         if not XTool.IsTableEmpty(res.RewardList) then
        --             XUiManager.OpenUiObtain(res.RewardList)
        --         end
        --         UpdatePassportInfosDic({res.PassportInfo})

        --         if cb then
        --             cb()
        --         end

        --         XEventManager.DispatchEvent(XEventId.EVENT_BUY_PASSPORT_COMPLEATE)
        --     end)
        -- else
        --     XDataCenter.PayManager.PayOfAutoTemplate(payKeySuffix, XPayConfigs.PayTargetModuleTypes.Passport, { id })
        --     XPassportManager.PayCallBack = cb
        -- end
    end

    --购买通行证经验（等级）请求
    function XPassportManager.RequestPassportBuyExp(toLevel, cb)
        XNetwork.Call("PassportBuyExpRequest", { ToLevel = toLevel }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XUiManager.TipText("PassportBuyExpCompleate")
            BaseInfo:SetToLevel(toLevel)

            if cb then
                cb()
            end

            XEventManager.DispatchEvent(XEventId.EVENT_BUY_EXP_COMPLEATE)
        end)
    end

    --领取单个奖励请求
    function XPassportManager.RequestPassportRecvReward(passportRewardId, cb)
        XNetwork.Call("PassportRecvRewardRequest", { Id = passportRewardId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local passportId = XPassportConfigs.GetPassportRewardPassportId(passportRewardId)
            SetPassportReceiveReward(passportId, passportRewardId)

            XUiManager.OpenUiObtain(res.RewardList or {})

            if cb then
                cb()
            end

            XEventManager.DispatchEvent(XEventId.EVENT_BUY_RECV_REWARD_COMPLEATE)
        end)
    end

    --一键领取奖励请求
    function XPassportManager.RequestPassportRecvAllReward(cb)
        XNetwork.Call("PassportRecvAllRewardRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local horizontalNormalizedPosition = 0
            XUiManager.OpenUiObtain(res.RewardList or {}, nil, nil, nil, horizontalNormalizedPosition)
            UpdatePassportInfosDic(res.PassportInfos)

            if cb then
                cb()
            end

            XEventManager.DispatchEvent(XEventId.EVENT_BUY_RECV_ALL_REWARD_COMPLEATE)
        end)
    end

    --批量领取任务奖励
    function XPassportManager.FinishMultiTaskRequest(taskType)
        local taskIds = XPassportManager.GetPassportAchievedTaskIdList(taskType)
        if XTool.IsTableEmpty(taskIds) then
            return
        end

        XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)
            local horizontalNormalizedPosition = 0
            XUiManager.OpenUiObtain(rewardGoodsList, nil, nil, nil, horizontalNormalizedPosition)
        end)
    end

    -- function XPassportManager.PassportBuyPassportResponse(res)
    --     if res.Code ~= XCode.Success then
    --         XUiManager.TipCode(res.Code)
    --         return
    --     end

    --     local name = XPassportConfigs.GetPassportTypeInfoName(res.PassportInfo.Id)
    --     local msg = CS.XTextManager.GetText("SuccessfulItemPurchase", name)
    --     XUiManager.TipMsg(msg)

    --     if not XTool.IsTableEmpty(res.RewardList) then
    --         XUiManager.OpenUiObtain(res.RewardList)
    --     end
    --     UpdatePassportInfosDic({res.PassportInfo})

    --     if XPassportManager.PayCallBack and XLuaUiManager.IsUiShow("UiPassportCard") then
    --         XPassportManager.PayCallBack()
    --         XPassportManager.PayCallBack = nil
    --     end

    --     XEventManager.DispatchEvent(XEventId.EVENT_BUY_PASSPORT_COMPLEATE)
    -- end
    ---------------------protocol end------------------
    return XPassportManager
end

---------------------(服务器推送)begin------------------
XRpc.NotifyPassportData = function(data)
    XDataCenter.PassportManager.NotifyPassportData(data)
end

XRpc.NotifyPassportBaseInfo = function(data)
    XDataCenter.PassportManager.NotifyPassportBaseInfo(data)
end

XRpc.NotifyPassportAutoGetTaskReward = function(data)
    XDataCenter.PassportManager.NotifyPassportAutoGetTaskReward(data)
end

-- XRpc.PassportBuyPassportResponse = function(data)
--     XDataCenter.PassportManager.PassportBuyPassportResponse(data)
-- end
---------------------(服务器推送)end--------------------