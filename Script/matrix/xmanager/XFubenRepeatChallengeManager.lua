--V2.1 复刷关玩法重做(如果想找回旧复刷关的代码，请从V2.0分支获取。)
XFubenRepeatChallengeManagerCreator = function()
    local METHOD_NAME = { --请求协议
        Reward = "RepeatChallengeRewardRequest", --请求奖励
    }
    
    local pairs = pairs
    local tableInsert = table.insert
    local stringGsub = string.gsub

    local CurActivityId = XFubenRepeatChallengeConfigs.GetDefaultActivityId()
    local GotRewardIdCheckDic = {} -- 已领取奖励Id记录
    -- 活动等级信息
    local LevelInfo = {
        Level = 0,
        Exp = 0,
        DayExp = 0,
    }
    local AddLevelTip -- 权限等级增加提示

    local XFubenRepeatChallengeManager = {}
    
    ---是否要重设界面状态（不打开详细界面）
    local resetPanelState=false

    XFubenRepeatChallengeManager.ExCostItemId = CS.XGame.ClientConfig:GetInt("FubenRepeatChallengeExCostItemId")   --复刷关门票Id(展示用)

    local GetIsFirstAutoFightOpenCookieKey = function ()
        local activityId = XFubenRepeatChallengeConfigs.GetDefaultActivityId()
        return "FubenRepeatChallengeIsFirstAutoFightOpen" .. XPlayer.Id .. activityId
    end

    function XFubenRepeatChallengeManager.Init() end
    
    --======== 活动 功能开启相关 begin ============
    --region 活动 功能开启相关
    --活动是否开启
    function XFubenRepeatChallengeManager.IsOpen()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        if not config then
            return false
        end
        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime = XFubenRepeatChallengeManager.GetActivityBeginTime()
        local endTime = XFubenRepeatChallengeManager.GetActivityEndTime()
        return beginTime <= nowTime and nowTime < endTime
    end
    --获取活动开启时间
    function XFubenRepeatChallengeManager.GetActivityBeginTime()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        return XFunctionManager.GetStartTimeByTimeId(config.ActivityTimeId)
    end
    --获取挑战开启时间
    function XFubenRepeatChallengeManager.GetActivityChallengeBeginTime()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        return XFunctionManager.GetStartTimeByTimeId(config.ChallengeTimeId)
    end
    --获取战斗结束时间
    function XFubenRepeatChallengeManager.GetFightEndTime()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        return XFunctionManager.GetEndTimeByTimeId(config.FightTimeId)
    end
    --获取活动结束时间
    function XFubenRepeatChallengeManager.GetActivityEndTime()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        return XFunctionManager.GetEndTimeByTimeId(config.ActivityTimeId)
    end
    --判断当前是否挑战开始状态？
    function XFubenRepeatChallengeManager.IsStatusEqualChallengeBegin()
        local now = XTime.GetServerNowTimestamp()
        local challengeBeginTime = XFubenRepeatChallengeManager.GetActivityChallengeBeginTime()
        local endTime = XFubenRepeatChallengeManager.GetActivityEndTime()
        return challengeBeginTime <= now and now < endTime
    end
    --判断当前是否挑战结束状态？
    function XFubenRepeatChallengeManager.IsStatusEqualFightEnd()
        local now = XTime.GetServerNowTimestamp()
        local fightEndTime = XFubenRepeatChallengeManager.GetFightEndTime()
        local endTime = XFubenRepeatChallengeManager.GetActivityEndTime()
        return fightEndTime <= now and now < endTime
    end
    --结束活动
    function XFubenRepeatChallengeManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        XUiManager.TipText("ActivityRepeatChallengeOver")
        XLuaUiManager.RunMain()
    end
    --获取活动设置
    function XFubenRepeatChallengeManager.GetActivityConfig()
        return XFubenRepeatChallengeConfigs.GetActivityConfig(CurActivityId)
    end
    --endregion
    --======== 活动 功能开启相关 end ============
    
    --======== 活动UI相关 end ============
    --region 活动UI
    -- 获取进度提示
    function XFubenRepeatChallengeManager.ExGetProgressTip()
        if XFubenRepeatChallengeManager.IsAutoFightOpen() then
            return CS.XTextManager.GetText("ActivityRepeatChallengeAutoOpen")
        else
            local level = XFubenRepeatChallengeManager.GetLevel()
            local maxLevel = XFubenRepeatChallengeConfigs.GetMaxLevel()
            return CS.XTextManager.GetText("ActivityRepeatChallengeLevelTitle", level, maxLevel)
        end
    end
    --endregion
    -- 重写限时活动界面里基类的方法 在FubenManagerEx.Init()里使用
    function XFubenRepeatChallengeManager:ExOverrideBaseMethod()
        return {
            ExGetRunningTimeStr = function(proxy)
                local time = XTime.GetServerNowTimestamp()
                local fightEndTime = XFubenRepeatChallengeManager.GetFightEndTime()
                local activityEndTime = XFubenRepeatChallengeManager.GetActivityEndTime()
                local shopStr = CsXTextManagerGetText("ActivityBranchShopLeftTime")
                local fightStr = CsXTextManagerGetText("ActivityBranchFightLeftTime")
                if XFubenRepeatChallengeManager.IsStatusEqualFightEnd() then
                    return shopStr ..  XUiHelper.GetTime(activityEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
                else
                    return fightStr ..  XUiHelper.GetTime(fightEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
                end
            end,
            ExGetProgressTip = function(proxy)
                return XFubenRepeatChallengeManager.ExGetProgressTip()
            end,
        }
    end
    --======== 活动UI相关 end ============
    
    --======== UI操作 begin ==========
    --region UI操作
    -- v1.31 直接打开商店，不带播放效果
    function XFubenRepeatChallengeManager.OpenShop()
        local skipId = XDataCenter.FubenRepeatChallengeManager.GetActivityConfig().ShopSkipId
        XFunctionManager.SkipInterface(skipId)
    end
    -- v1.31 打开商店，可回调播放动画
    function XFubenRepeatChallengeManager.OpenShopByCB(closeCb, openCb)
        if not XFubenRepeatChallengeManager.IsOpen() then
            XUiManager.TipText("ShopIsNotOpen")
            return
        end
        
        local isOpen, desc = XActivityBrieIsOpen.Get(XActivityBriefConfigs.ActivityGroupId.ActivityBriefShop)
        if not isOpen then
            XUiManager.TipMsg(desc)
            return
        end
        
        local functionId = XFunctionManager.FunctionName.ShopActive
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        if not isOpen then
            XUiManager.TipError(XFunctionManager.GetFunctionOpenCondition(functionId))
            return
        end
        XDataCenter.ActivityBriefManager.OpenShop(closeCb, openCb)
    end
    --endregion
    --======== UI操作 end ==========
    
    --======== 获取UI数据 begin =========
    --region 获取UI数据
    --获取章节(改版后只有一个章节)
    function XFubenRepeatChallengeManager.GetChapterId()
        local chapterId = XFubenRepeatChallengeConfigs.GetActivityChapterId(CurActivityId)
        return chapterId
    end
    
    --获取战斗关卡ID(改版后只有一个关卡)
    function XFubenRepeatChallengeManager.GetStageId()
        local stageId = XFubenRepeatChallengeConfigs.GetActivityStageId(CurActivityId)
        return stageId
    end
    --获取权限等级
    function XFubenRepeatChallengeManager.GetLevel()
        return LevelInfo.Level
    end
    --获取下一个需要展示升级UI的权限等级
    function XFubenRepeatChallengeManager.GetNextShowLevel()
        for i = LevelInfo.Level + 1, XFubenRepeatChallengeConfigs.GetMaxLevel() do
            local levelConfig = XFubenRepeatChallengeConfigs.GetLevelConfig(i)
            if levelConfig.NeedShow then return i end
        end
    end
    --获取权限总经验值
    function XFubenRepeatChallengeManager.GetOriginExp()
        return LevelInfo.Exp
    end
    --获取当前权限等级的经验值
    function XFubenRepeatChallengeManager.GetExp()
        local totalExp = LevelInfo.Exp
        local level = XFubenRepeatChallengeManager.GetLevel()
        for lv = 1, level - 1 do
            local levelConfig = XFubenRepeatChallengeConfigs.GetLevelConfig(lv)
            totalExp = totalExp - levelConfig.UpExp
        end
        return totalExp
    end
    --获取当日经验值？
    function XFubenRepeatChallengeManager.GetDayExp()
        return LevelInfo.DayExp
    end
    --获取权限BUFF的描述
    function XFubenRepeatChallengeManager.GetBuffDes(buffId)
        local fightEventCfg = buffId and buffId ~= 0 and CS.XNpcManager.GetFightEventTemplate(buffId)
        return fightEventCfg and fightEventCfg.Description
    end
    --判断是否到达等级
    function XFubenRepeatChallengeManager.IsLevelReach(checkLevel)
        local level = XFubenRepeatChallengeManager.GetLevel()
        return level >= checkLevel
    end
    function XFubenRepeatChallengeManager.GetActDescription()
        local config = XFubenRepeatChallengeManager.GetActivityConfig()
        return stringGsub(config.ActDescription, "\\n", "\n")
    end
    --获取奖励数据
    function XFubenRepeatChallengeManager.GetRewardsData()
        local datas = {}
        local rewardConfigs = XFubenRepeatChallengeConfigs.GetRewardConfigs()
        for _,configs in pairs(rewardConfigs) do
            local data = {}
            data.RewardId = configs.Id
            data.RewardItemListId = configs.RewardId
            data.canObtain = XConditionManager.CheckCondition(configs.Condition)
            data.Desc = XConditionManager.GetConditionDescById(configs.Condition)
            data.Obtained = GotRewardIdCheckDic[configs.Id]
            table.insert(datas, data)
        end
        return datas
    end
    --endregion
    --======== 获取UI数据 end =========

    --======== 红点 begin =========
    --获取是否有奖励红点
    function XFubenRepeatChallengeManager.GetRewardRed()
        local datas = XFubenRepeatChallengeManager.GetRewardsData()
        for _,data in ipairs(datas) do
            if data.canObtain and not data.Obtained then
                return true
            end
        end
        return false
    end
    --======== 红点 end =========
    
    --======== 自动战斗 begin =========
    --region 自动战斗
    --检查是否开启了自动战斗
    function XFubenRepeatChallengeManager.IsAutoFightOpen()
        local level = XFubenRepeatChallengeManager.GetLevel()
        return level >= XFubenRepeatChallengeConfigs.GetMaxLevel()
    end
    --检查是否第一次开启自动战斗(用来播放教程？)
    function XFubenRepeatChallengeManager.GetIsFirstAutoFightOpen()
        local isFirstAutoFightOpen = GetIsFirstAutoFightOpenCookieKey()
        return XSaveTool.GetData(isFirstAutoFightOpen) or false
    end 
    -- 本地缓存是否第一次开启自动作战
    function XFubenRepeatChallengeManager.SetAutoFightOpen()
        local isFirstAutoFightOpen = GetIsFirstAutoFightOpenCookieKey()
        return XSaveTool.SaveData(isFirstAutoFightOpen, true)
    end
    --endregion
    --======== 自动战斗 end =========

    --==========请求 Begin===========--
    --region 请求
    -- 初始化关卡数据 设置关卡类型  （FubenManager调用）
    function XFubenRepeatChallengeManager.InitStageInfo()
        local configs = XFubenRepeatChallengeConfigs.GetStageConfigs()
        for stageId, config in pairs(configs) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.RepeatChallenge
            end
        end
    end
    --检查预战斗数据
    function XFubenRepeatChallengeManager.CheckPreFight(stage, challengeCount)
        if not XDataCenter.FubenRepeatChallengeManager.IsOpen() then
            XUiManager.TipText("ActivityRepeatChallengeOver")
            return false
        end

        if XDataCenter.FubenRepeatChallengeManager.IsStatusEqualFightEnd() then
            XUiManager.TipText("ActivityRepeatChallengeOver")
            return false
        end

        local itemId, itemNum = XDataCenter.FubenManager.GetStageExCost(stage.StageId)
        if XDataCenter.ItemManager.GetCount(itemId) < itemNum * challengeCount then
            XUiManager.TipText("ActivityRepeatChallengeCostNotEnough")
            return false
        end

        return true
    end
    --显示胜利结算
    function XFubenRepeatChallengeManager.ShowReward(winData)
        if not winData then return end
        XLuaUiManager.Open("UiRepeatChallengeSettleWin", winData, AddLevelTip)
    end
    --请求获取奖励
    function XFubenRepeatChallengeManager.RequesetGetReward(rewardId, rewardCB)
        if not rewardId or rewardId == 0 then return end
        if GotRewardIdCheckDic[rewardId] then return end
        XNetwork.Call(METHOD_NAME.Reward, { Id = rewardId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            GotRewardIdCheckDic[rewardId] = true
            if next(res.RewardGoodsList) then
                XUiManager.OpenUiObtain(res.RewardGoodsList, nil,rewardCB)
            end
        end)
    end
    --endregion
    --==========请求 End===========--

    --数据更新通知
    function XFubenRepeatChallengeManager.NotifyRepeatChallengeData(data)
        CurActivityId = data.Id
        LevelInfo = data.ExpInfo
        XFubenRepeatChallengeManager.UpdateChapterGotRewardIds(data.RewardIds)
    end
    function XFubenRepeatChallengeManager.UpdateChapterGotRewardIds(rewardIds)
        GotRewardIdCheckDic = {}
        if not rewardIds then return end
        for _, rewardId in pairs(rewardIds) do
            GotRewardIdCheckDic[rewardId] = true
        end
    end

    --权限等级数据通知
    function XFubenRepeatChallengeManager.NotifyRcExpChange(data)
        local addExp = data.ExpInfo.Exp - LevelInfo.Exp
        LevelInfo = data.ExpInfo
        if addExp > 0 then
            AddLevelTip = addExp
        end
    end
    function XFubenRepeatChallengeManager.ClearAddLevelTip()
        AddLevelTip = nil
    end
    
    function XFubenRepeatChallengeManager.ResetPanelState(bool)
        resetPanelState=bool
    end
    
    function XFubenRepeatChallengeManager.IsResetPanelState()
        return resetPanelState
    end
    
    XFubenRepeatChallengeManager.Init()
    return XFubenRepeatChallengeManager
end

XRpc.NotifyRepeatChallengeData = function(data)
    XDataCenter.FubenRepeatChallengeManager.NotifyRepeatChallengeData(data)
end

XRpc.NotifyRcExpChange = function(data)
    XDataCenter.FubenRepeatChallengeManager.NotifyRcExpChange(data)
end