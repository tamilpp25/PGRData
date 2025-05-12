XKujiequManagerCreator = function()
    local XKujiequManager = {}
    local IgnoreTips = false
    local ChannelIds = {}

    function XKujiequManager.Init()
        
    end

    function XKujiequManager.IsShowEntrance()
        local timeId = CS.XGame.ClientConfig:GetInt("KujiequTimeId")
        local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
        if not isInTime then
            return false
        end

        local isAllow = XKujiequManager.IsChannelAllow()
        if not isAllow then
            return false
        end

        return true
    end

    function XKujiequManager.SetIgnoreTips()
        IgnoreTips = true
    end

    function XKujiequManager.OpenKujiequ()
        --活动分包资源检测
        if not XMVCA.XSubPackage:CheckSubpackage() then
            return
        end
        if IgnoreTips then
            XKujiequManager.OpenURL()
        else
            XLuaUiManager.Open("UiKujiequTips")
        end
    end

    function XKujiequManager.OpenURL()
        -- 请求完成任务
        local taskId = XKujiequManager.GetTaskId()
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if taskData.State ~= XDataCenter.TaskManager.TaskState.Finish then
            XKujiequManager.RequestFinishTask(taskId)
        end

        -- 打开链接
        local url = CS.XGame.ClientConfig:GetString("KujiequUrl")
        CS.UnityEngine.Application.OpenURL(url)
    end

    function XKujiequManager.GetTaskId()
        return CS.XGame.ClientConfig:GetInt("KujiequTaskId")
    end

    -- 请求完成任务
    function XKujiequManager.RequestFinishTask(taskId)
        local taskCfg = XTaskConfig.GetTaskCfgById(taskId)
        local conditionTemplates = XTaskConfig.GetTaskCondition(taskCfg.Condition[1])
        local taskType = conditionTemplates.Params[2]
            
        -- 请求任务条件完成
        local req = { ClientTaskType = taskType }
        XNetwork.Call("DoClientTaskEventRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            -- 领取奖励
            XDataCenter.TaskManager.FinishTask(taskId, function(rewardGoodsList)
                XUiManager.OpenUiObtain(rewardGoodsList)
            end)
        end)
    end

    -- 刷新渠道id列表
    function XKujiequManager.RefreshChannelIds(channelIds)
        ChannelIds = channelIds or {}
    end

    -- 渠道是否允许
    function XKujiequManager.IsChannelAllow()
        local channelId = CS.XHeroSdkAgent.GetChannelId()
        for _, id in ipairs(ChannelIds) do
            if channelId == id then
                return true
            end
        end

        return false
    end

    XKujiequManager.Init()
    return XKujiequManager
end

-- 通知库街区数据
XRpc.NotifyCommunityData = function(data)
    XDataCenter.KujiequManager.RefreshChannelIds(data.DisplayChannels)
end