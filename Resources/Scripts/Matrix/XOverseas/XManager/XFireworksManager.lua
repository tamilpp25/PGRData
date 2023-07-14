--Description
--烟花活动管理器
--涉及修改
--FireworksManager.lua
--XTable.XTableFireworks
--XTable.XTableSignFireworks
--SignFireworks.tab
--XAutoWindowConfigs - 增加autoWindowConfig 1001
--XDateCenter 增加管理器入口
--XUiSign增加界面lua绑定相关
--XSignInConfigs增加相关配置
--XRedPoint相关红点
--XUISignBanner
--XAutoWindowController.tab
--XSkipFunctional.tab

XFireworksManagerCreator = function()
    local FIREWORK_CONFIG_PATH = "Share/EnKrFireworks/Fireworks.tab"
    local FIREWORK_REWARD_CONFIG_PATH = "Share/EnKrFireworks/FireworksReward.tab"
    local FIREWORK_RULE_PATH = "Client/EnKrFireworks/FireworksRules.tab"

    local FireworksManager = {}

    local curFireworksActivityId = 1

    local FireworksProto = {
        Fire = "FireworksRequest"
    }

    local config
    local rewardConfigs

    local hadFireTimes

    local records

    local ruleConfigs

    local function InitData()
        records = {}
        hadFireTimes = 0;
    end

    function FireworksManager.Init()
        config = XTableManager.ReadByIntKey(FIREWORK_CONFIG_PATH, XTable.XTableFireworks, "Id")[curFireworksActivityId]
        rewardConfigs = XTableManager.ReadByIntKey(FIREWORK_REWARD_CONFIG_PATH, XTable.XTableFireworksReward, "Id")
        if config == nil then
            XLog.Error("烟花活动Id配置不存在,Id为" .. curFireworksActivityId)
            return
        end
        ruleConfigs = XTableManager.ReadByIntKey(FIREWORK_RULE_PATH, XTable.XTableFireworksRules, "Id")
        InitData()
    end

    function FireworksManager.IsActivityOpen()
        if config == nil then return false end
        local startTime = XTime.ParseToTimestamp(config.StartTimeStr)
        local endTime = XTime.ParseToTimestamp(config.CloseTimeStr)
        local nowTime = XTime.GetServerNowTimestamp()
        return startTime <= nowTime and nowTime <= endTime
    end

    function FireworksManager.IsPlayerQualified()
        return XPlayer.Level >= config.OpenLevel and (config.OpenStage == nil or config.OpenStage <= 0 or XDataCenter.FubenManager.CheckStageIsPass(config.OpenStage))
    end

    function FireworksManager.HasAvailableFireTimes()
        return hadFireTimes < config.DailyResetTimes
    end

    function FireworksManager.HasRedDot()
        return FireworksManager.IsActivityOpen() and FireworksManager.HasAvailableFireTimes()
    end


    function FireworksManager.SyncData(remoteData)
        local found = false
        for i = 1, #remoteData.Fireworks do
            if (remoteData.Fireworks[i].Id == curFireworksActivityId) then
                found = true
                FireworksManager.SyncRecords(remoteData.Fireworks[i].Records)
                hadFireTimes = remoteData.Fireworks[i].UseTimes
                break
            end
        end

        if not found then
            InitData()
        end
    end

    function FireworksManager.SyncRecords(recordList)
        records = recordList
        table.sort(records, function(a, b) return a.Time > b.Time end)
    end

    function FireworksManager.OnFire(callback)
        XNetwork.Call(FireworksProto.Fire, {FireworksId = curFireworksActivityId}, function(res)
            if res.Code ~= XCode.Success then
                callback(false, nil)
                return
            end
            hadFireTimes = hadFireTimes + 1 --服务端未同步，手动同步
            table.insert(records, 1, res.Record)
            if #records > 10 then
                table.remove(records)
            end
            callback(true, res)
        end)
    end

    function FireworksManager.GetRules()
        local config = ruleConfigs[curFireworksActivityId]
        if config == nil then
            XLog.Error("Fireworks rule does not exists, id is " .. curFireworksActivityId)
            return {}
        end
        return config
    end

    function FireworksManager.GetRecords()
        return records
    end

    function FireworksManager.GetLastRecordType()
        if #records <= 0 then
            return nil
        end
        local dropId = records[1].DropId
        local effectId = FireworksManager.GetEffectIdByDropId(dropId)
        if effectId  == nil then
            XLog.Error("FireworksReward Id " .. lastRecordId .. "不存在")
        end
        return effectId
    end

    function FireworksManager.GetEffectIdByDropId(dropId)
        if rewardConfigs[dropId] == nil then
            return nil
        end
        return rewardConfigs[dropId].FireworksEffects
    end

    function FireworksManager.GetDropNameByDropId(dropId)
        if rewardConfigs[dropId] == nil then
            return "Mystery"
        end
        return rewardConfigs[dropId].FireworksDes
    end

    function FireworksManager.GetRecordString(record)
        local name = FireworksManager.GetDropNameByDropId(record.DropId)
        local infoStr = ""
        local rewards = record.FireworksReward
        for i = 1, #rewards do
            local common = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(rewards[i].TemplateId)
            infoStr = infoStr .. string.format("%s*%d", common.Name, rewards[i].Count) .. " "
        end
        local time = XTime.TimestampToGameDateTimeString(record.Time)
        return name, infoStr, time
    end

    FireworksManager.Init()
    return FireworksManager
end

XRpc.NotifyFireworksData = function(data)
    XDataCenter.FireworksManager.SyncData(data)
end