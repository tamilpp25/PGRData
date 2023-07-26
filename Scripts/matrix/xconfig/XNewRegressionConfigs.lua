XNewRegressionConfigs = XNewRegressionConfigs or {}

-- 配置表
local SHARE_TABLE_PATH = "Share/Regression2/"
local CLIENT_TABLE_PATH = "Client/Regression2/"

XNewRegressionConfigs.ActivityState = {
    None = 0,
    NotInRegression = 1,    --活跃玩家
    InRegression = 2,       --回归玩家
    RegressionEnded = 3,    --回归玩家活动结束
    Max = 4
}

XNewRegressionConfigs.GachaType = {
    None = 0,
    InRegression = 1,
    NotInRegression = 2,
    Max = 3,
}

XNewRegressionConfigs.TaskType = {
    Daily = 1,
    Weekly = 2,
    Normal = 3
}

XNewRegressionConfigs.GachaGroupState = {
    Begin = 0,
    CoreFinished = 1,
    Done = 2,
}

--邀请类型
XNewRegressionConfigs.InviteState = {
    Inviter = 1,   --活跃玩家邀请
    Invitee = 2,   --回归玩家被邀请
}

function XNewRegressionConfigs.Init()
    XConfigCenter.CreateGetPropertyByFunc(XNewRegressionConfigs, "Regression2Activity", function()
        return XTableManager.ReadByIntKey(SHARE_TABLE_PATH .. "Regression2Activity.tab", XTable.XTableRegression2Activity, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XNewRegressionConfigs, "Regression2Gacha", function()
        return XTableManager.ReadByIntKey(SHARE_TABLE_PATH .. "Regression2Gacha.tab", XTable.XTableRegression2Gacha, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XNewRegressionConfigs, "Regression2GachaGroup", function()
        return XTableManager.ReadByIntKey(SHARE_TABLE_PATH .. "Regression2GachaGroup.tab", XTable.XTableRegression2GachaGroup, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XNewRegressionConfigs, "Regression2GachaReward", function()
        return XTableManager.ReadByIntKey(SHARE_TABLE_PATH .. "Regression2GachaReward.tab", XTable.XTableRegression2GachaReward, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XNewRegressionConfigs, "Regression2Invite", function()
        return XTableManager.ReadByIntKey(SHARE_TABLE_PATH .. "Regression2Invite.tab", XTable.XTableRegression2Invite, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XNewRegressionConfigs, "Regression2InviteReward", function()
        return XTableManager.ReadByIntKey(SHARE_TABLE_PATH .. "Regression2InviteReward.tab", XTable.XTableRegression2InviteReward, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XNewRegressionConfigs, "Regression2SignIn", function()
        return XTableManager.ReadByIntKey(SHARE_TABLE_PATH .. "Regression2SignIn.tab", XTable.XTableRegression2SignIn, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XNewRegressionConfigs, "Regression2Task", function()
        return XTableManager.ReadByIntKey(SHARE_TABLE_PATH .. "Regression2Task.tab", XTable.XTableRegression2Task, "Id")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XNewRegressionConfigs, "Regression2ClienConfig", function()
        return XTableManager.ReadByStringKey(CLIENT_TABLE_PATH .. "Regression2ClienConfig.tab", XTable.XTableRegression2ClienConfig, "Key")
    end)
    XConfigCenter.CreateGetPropertyByFunc(XNewRegressionConfigs, "Regression2ShareConfig", function()
        return XTableManager.ReadByIntKey(CLIENT_TABLE_PATH .. "Regression2ShareConfig.tab", XTable.XTableRegression2ShareConfig, "Id")
    end)
end

function XNewRegressionConfigs.GetActivityConfig(id)
    return XNewRegressionConfigs.GetRegression2Activity(id)
end

function XNewRegressionConfigs.GetSignInConfigByActivityId(activityId)
    local configs = XNewRegressionConfigs.GetRegression2SignIn()
    local result = {}
    for id, config in pairs(configs) do
        if config.ActivityId == activityId then
            table.insert(result, config)
        end
    end
    table.sort(result, function(configA, configB)
        return configA.Id < configB.Id
    end)
    return result
end

function XNewRegressionConfigs.GetTaskConfig(id)
    return XNewRegressionConfigs.GetRegression2Task(id)
end

function XNewRegressionConfigs.GetGachaConfig(id)
    return XNewRegressionConfigs.GetRegression2Gacha(id)
end

function XNewRegressionConfigs.GetGachaGroupConfig(id)
    return XNewRegressionConfigs.GetRegression2GachaGroup(id)
end

function XNewRegressionConfigs.GetGachaGroupIds(gachaId)
    local result = {}
    for _, config in pairs(XNewRegressionConfigs.GetRegression2GachaGroup()) do
        if config.GachaId == gachaId then
            table.insert(result, config.Id)
        end
    end
    table.sort(result, function(idA, idB)
        return idA < idB
    end)
    return result
end

function XNewRegressionConfigs.GetGachaRewardConfig(id)
    return XNewRegressionConfigs.GetRegression2GachaReward(id)
end

function XNewRegressionConfigs.GetGachaRewardIds(rewardGroupId)
    local result = {}
    for _, config in ipairs(XNewRegressionConfigs.GetRegression2GachaReward()) do
        if config.RewardGroupId == rewardGroupId then
            table.insert(result, config.Id)
        end
    end
    table.sort(result, function(idA, idB)
        return idA < idB
    end)
    return result
end

function XNewRegressionConfigs.GetChildActivityConfig(activityKey)
    return XNewRegressionConfigs.GetRegression2ClienConfig(activityKey).Values[1]
end

------------------Regression2Invite begin----------------------
function XNewRegressionConfigs.GetDefaultInviteId()
    local config = XNewRegressionConfigs.GetRegression2Invite()
    for id in pairs(config) do
        return id
    end
end

function XNewRegressionConfigs.GetInviteDailyPointMax(id)
    local config = XNewRegressionConfigs.GetRegression2Invite(id)
    return config.DailyPointMax
end

function XNewRegressionConfigs.GetInviteCountMax(id)
    local config = XNewRegressionConfigs.GetRegression2Invite(id)
    return config.InviteCountMax
end

function XNewRegressionConfigs.GetInviteTimeId(id)
    local config = XNewRegressionConfigs.GetRegression2Invite(id)
    return config.TimeId
end
------------------Regression2Invite end------------------------

------------------Regression2InviteReward begin----------------------
function XNewRegressionConfigs.GetInviteRewardId(id)
    local config = XNewRegressionConfigs.GetRegression2InviteReward(id)
    return config.RewardId
end

function XNewRegressionConfigs.GetInviteNeedPoint(id)
    local config = XNewRegressionConfigs.GetRegression2InviteReward(id)
    return config.NeedPoint
end

function XNewRegressionConfigs.GetInviteRewardIsPrimeReward(id)
    local config = XNewRegressionConfigs.GetRegression2InviteReward(id)
    return config.IsPrimeReward
end

function XNewRegressionConfigs.GetInviteRewardData(id)
    local rewardId = XNewRegressionConfigs.GetInviteRewardId(id)
    local rewards = XTool.IsNumberValid(rewardId) and XRewardManager.GetRewardList(rewardId)
    return rewards and rewards[1]
end

function XNewRegressionConfigs.GetInviteRewardIdList(type, inviteId)
    local rewardIdList = {}
    for _, v in pairs(XNewRegressionConfigs.GetRegression2InviteReward()) do
        if v.Type == type and v.InviteId == inviteId then
            table.insert(rewardIdList, v.Id)
        end
    end
    table.sort(rewardIdList, function(idA, idB)
        return idA < idB
    end)
    return rewardIdList
end

function XNewRegressionConfigs.GetShareConfig(platformType)
    local channelId = 0 -- 默认值
    if XUserManager.IsUseSdk() then
        channelId = CS.XHeroSdkAgent.GetChannelId()
    end
    local configs = XNewRegressionConfigs.GetRegression2ShareConfig()
    for _, config in pairs(configs) do
        if config.PlatformType == platformType and 
            config.ChannelId == channelId then
            return config
        end
    end
    return nil
end
------------------Regression2InviteReward end------------------------