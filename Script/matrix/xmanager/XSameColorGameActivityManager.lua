local XSCRoleSkill = require("XEntity/XSameColorGame/Skill/XSCRoleSkill")
-- 三消游戏活动管理器
XSameColorGameActivityManagerCreator = function()
    local XSameColorGameActivityManager = {
        DEBUG = false
    }

    local METHOD_NAME = {
        SameColorGameEnterStageRequest = "SameColorGameEnterStageRequest",--进入关卡
        SameColorGameSwapItemRequest = "SameColorGameSwapItemRequest",--交换
        SameColorGameUseItemRequest = "SameColorGameUseItemRequest",--使用技能
        SameColorGameOpenRankRequest = "SameColorGameOpenRankRequest",--打开排行榜
        SameColorGameGiveUpRequest = "SameColorGameGiveUpRequest",--中途放弃
        SameColorGameCancelUseItemRequest = "SameColorGameCancelUseItemRequest",--放弃使用技能（只有多步操作型技能使用（例：进行n次交换，直到造成消除），且需要使用过一次以上）
    }

    local BossManager = nil
    local RoleManager = nil
    local BattleManager = nil
    local RoleShowSkillDic = {}
    local Config = nil
    local FirstOpenObtainKey = "FirstOpenObtainKey"

    -- 初始化
    function XSameColorGameActivityManager.Init()
        Config = XSameColorGameConfigs.GetCurrentConfig()
        local script = require("XEntity/XSameColorGame/Boss/XSCBossManager")
        BossManager = script.New()
        
        script = require("XEntity/XSameColorGame/Role/XSCRoleManager")
        RoleManager = script.New()
        
        script = require("XEntity/XSameColorGame/Battle/XSCBattleManager")
        BattleManager = script.New()
    end

    -- data { ActivityId, BossRecords : List<XSameColorGameBossRecord> }
    function XSameColorGameActivityManager.InitWithServerData(data)
        -- 不相等重新初始化
        if Config.Id ~= data.ActivityId then
            XSameColorGameActivityManager.Init()
        end
        BossManager:InitWithServerData(data.BossRecords)
    end

    function XSameColorGameActivityManager.GetInitRoleIds()
        return Config.InitRoleId
    end

    function XSameColorGameActivityManager.GetAvailableChapters()
        local result = {}
        if not XSameColorGameActivityManager.GetIsInTime() then
            return result
        end
        table.insert(result, {
                Id = Config.Id,
                Type = XDataCenter.FubenManager.ChapterType.SameColor,
                Name = XSameColorGameActivityManager.GetName(),
                Icon = XSameColorGameActivityManager.GetBannerIcon()
            })
        return result
    end

    -- 打开活动主界面
    function XSameColorGameActivityManager.OpenMainUi()
        if not XSameColorGameActivityManager.GetIsOpen(true) then
            return
        end
        XLuaUiManager.Open("UiSameColorGameBossMain")
    end

    function XSameColorGameActivityManager.OpenShopUi(callback)
        if not XSameColorGameActivityManager.GetIsOpen(true) then
            return
        end
        XLuaUiManager.Open("UiShop", XShopManager.ShopType.SameColorGame, callback)
    end

    function XSameColorGameActivityManager.GetIsFirstOpenRoleObtainUi()
        return not XSaveTool.GetData(XSameColorGameActivityManager.GetLocalSaveKey() .. FirstOpenObtainKey)
    end

    function XSameColorGameActivityManager.SetIsFirstOpenRoleObtainUi()
        XSaveTool.SaveData(XSameColorGameActivityManager.GetLocalSaveKey() .. FirstOpenObtainKey, true)
    end

    -- 检查是否为初始角色
    function XSameColorGameActivityManager.CheckIsInitRole(id)
        for _, v in ipairs(Config.InitRoleId) do
            if v == id then
                return true
            end
        end
        return false
    end

    -- 获取活动开始时间
    function XSameColorGameActivityManager.GetStartTime()
        return XFunctionManager.GetStartTimeByTimeId(Config.TimerId)
    end

    -- 获取活动结束时间
    function XSameColorGameActivityManager.GetEndTime()
        -- if XSameColorGameActivityManager.DEBUG then
        --     if XSameColorGameActivityManager.__DEBUG_END_TIME == nil then
        --         XSameColorGameActivityManager.__DEBUG_END_TIME = XTime.GetServerNowTimestamp() + 10
        --     end
        --     return XSameColorGameActivityManager.__DEBUG_END_TIME
        -- end
        return XFunctionManager.GetEndTimeByTimeId(Config.TimerId)
    end

    -- 获取活动名称
    function XSameColorGameActivityManager.GetName()
        return XSameColorGameConfigs.GetActivityConfigValue("Name")[1]
    end

    function XSameColorGameActivityManager.GetBannerIcon()
        return XSameColorGameConfigs.GetActivityConfigValue("BannerIcon")[1]
    end

    -- 获取活动剩余时间描述
    function XSameColorGameActivityManager.GetLeaveTimeStr()
        local endTime = XSameColorGameActivityManager.GetEndTime()
        return XUiHelper.GetTime(endTime - XTime.GetServerNowTimestamp()
            , XUiHelper.TimeFormatType.ACTIVITY)
    end

    -- 获取活动是否在开启时间内
    function XSameColorGameActivityManager.GetIsInTime()
        if XSameColorGameActivityManager.DEBUG then
            return true
        end
        return XFunctionManager.CheckInTimeByTimeId(Config.TimerId)
    end

    function XSameColorGameActivityManager.GetIsOpen(showTip)
        -- 未满足功能条件
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SameColor, nil, not showTip) then
            return
        end
        -- 未满足开放时间
        if not XSameColorGameActivityManager.GetIsInTime() then
            if showTip then
                XUiManager.TipError(CS.XTextManager.GetText("FunctionNotDuringOpening"))
            end
            return
        end
        return true
    end

    function XSameColorGameActivityManager.GetRoleShowSkill(skillGroupId)
        local result = RoleShowSkillDic[skillGroupId]
        if result == nil then
            result = XSCRoleSkill.New(skillGroupId)
            RoleShowSkillDic[skillGroupId] = result
        end
        return result
    end

    -- 获取活动帮助id
    function XSameColorGameActivityManager.GetHelpId()
        local helpId = tonumber(XSameColorGameConfigs.GetActivityConfigValue("HelpId")[1])
        return XHelpCourseConfig.GetHelpCourseTemplateById(helpId).Function
    end

    -- 获取活动资源id数组
    function XSameColorGameActivityManager.GetAssetItemIds()
        local result = {}
        for _, v in ipairs(XSameColorGameConfigs.GetActivityConfigValue("AssetItemIds")) do
            table.insert(result, tonumber(v))
        end
        return result
    end

    function XSameColorGameActivityManager.GetShopId()
        return XSameColorGameConfigs.GetActivityConfigValue("ShopId")[1]
    end

    function XSameColorGameActivityManager.GetRankIcons()
        return XSameColorGameConfigs.GetActivityConfigValue("RankIcons")
    end

    -- taskType : XSameColorGameConfigs.TaskType
    function XSameColorGameActivityManager.GetTaskDatas(taskType, isSort)
        taskType = taskType or XSameColorGameConfigs.TaskType
        local groupId = nil
        if taskType == XSameColorGameConfigs.TaskType.Day then
            groupId = tonumber(XSameColorGameConfigs.GetActivityConfigValue("TaskGroupId")[1])
        elseif taskType == XSameColorGameConfigs.TaskType.Reward then
            groupId = tonumber(XSameColorGameConfigs.GetActivityConfigValue("TaskGroupId")[2])
        end
        return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, isSort)
    end

    -- 获取boss管理器
    function XSameColorGameActivityManager.GetBossManager()
        return BossManager
    end

    -- 获取角色管理器
    function XSameColorGameActivityManager.GetRoleManager()
        return RoleManager
    end

    -- 获取战斗管理器
    function XSameColorGameActivityManager.GetBattleManager()
        return BattleManager
    end

    function XSameColorGameActivityManager.GetLocalSaveKey()
        return Config.Id .. XPlayer.Id .. "XSameColorGameActivityManager"
    end

    -- 获取当前能够使用的技能数据
    function XSameColorGameActivityManager.GetAllUsableSkillGroupIds()
        local result = {}
        local itemManager = XDataCenter.ItemManager
        local configDic = XSameColorGameConfigs.GetSkillGroupConfigDic()
        for _, config in pairs(configDic) do
            if itemManager.GetCount(config.ShopItemId) > 0 then
                table.insert(result, config.Id)
            end
        end
        table.sort(result, function(a, b)
                return a < b
            end)
        return result
    end

    function XSameColorGameActivityManager.HandleActivityEndTime()
        if XSameColorGameActivityManager.DEBUG then
            return
        end
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("SCBossActivityTimeOut"))
    end

    function XSameColorGameActivityManager.SetMainUiModelInfo(UiModel, UiModelGo, UiSceneInfo)
        XSameColorGameActivityManager.UiModel = UiModel
        XSameColorGameActivityManager.UiModelGo = UiModelGo
        XSameColorGameActivityManager.UiSceneInfo = UiSceneInfo
    end

    function XSameColorGameActivityManager.GetMainUiModelInfo()
        return XSameColorGameActivityManager.UiModel
            , XSameColorGameActivityManager.UiModelGo
            , XSameColorGameActivityManager.UiSceneInfo
    end

    function XSameColorGameActivityManager.ClearMainUiModelInfo()
        if XSameColorGameActivityManager.UiSceneInfo then
            XSameColorGameActivityManager.UiSceneInfo.GameObject:SetActiveEx(false)
        end
        XSameColorGameActivityManager.UiModel = nil
        XSameColorGameActivityManager.UiModelGo = nil
        XSameColorGameActivityManager.UiSceneInfo = nil
    end

    --######################## 请求 ########################

    -- bossId : 为0时是总榜的数据
    function XSameColorGameActivityManager.RequestRankData(bossId, callback)
        XNetwork.Call(METHOD_NAME.SameColorGameOpenRankRequest, { BossId = bossId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                -- XSameColorGameRankInfo
                local myRankInfo = res.MyRankInfo
                -- List<XSameColorGameRankInfo>
                local rankList = res.RankList
                -- for i = #rankList, 1, -1 do
                --     if rankList[i].RoleId <= 0 then
                --         table.remove(rankList, i)
                --     end
                -- end
                if callback then
                    callback(rankList, myRankInfo)
                end
            end)
    end

    function XSameColorGameActivityManager.RequestEnterStage(roleId, bossId, skillGroupIds, callback)
        local requestBody = {
            BossId = bossId,
            RoleId = roleId,
            SkillIds = skillGroupIds
        }
        -- res : { List<XSameColorGameAction> Actions }
        XNetwork.Call(METHOD_NAME.SameColorGameEnterStageRequest, requestBody, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                BossManager:SetCurrentChallengeBoss(BossManager:GetBoss(bossId))
                BattleManager:SetActionList(res.Actions)
                if callback then
                    callback()
                end
            end)
    end

    function XSameColorGameActivityManager.RequestSwapBall(startPos, endPos, callback)
        -- res : { List<XSameColorGameAction> Actions }
        local serverStartPos = {PositionX = startPos.PositionX - 1, PositionY = startPos.PositionY - 1}
        local serverEndPos = {PositionX = endPos.PositionX - 1, PositionY = endPos.PositionY - 1}
        XNetwork.Call(METHOD_NAME.SameColorGameSwapItemRequest, {Source = serverStartPos,Destination = serverEndPos}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                
                BattleManager:SetActionList(res.Actions)
                if callback then
                    callback()
                end
            end)
    end

    function XSameColorGameActivityManager.RequestUseItem(skillGroupId, skillId, useItemParam, callback)
        -- res : { List<XSameColorGameAction> Actions }
        local serverUseItemParam = {}
        for key,item in pairs(useItemParam or {}) do
            local serverItem = {}
            if next(item) then
                serverItem = {ItemId = item.ItemId, PositionX = item.PositionX - 1, PositionY = item.PositionY - 1}
            end
            serverUseItemParam[key] = serverItem
        end
        
        XNetwork.Call(METHOD_NAME.SameColorGameUseItemRequest, {GroupId = skillGroupId, ItemId = skillId,UseItemParam = serverUseItemParam}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                BattleManager:SetActionList(res.Actions)
                if callback then
                    callback()
                end
                
                local IsInCD = false
                
                for _,action in pairs(res.Actions or {}) do
                    if action.ActionType == XSameColorGameConfigs.ActionType.ActionCdChange and action.SkillId == skillGroupId then
                        IsInCD = true
                        break
                    end
                end
                
                local skill = BattleManager:GetBattleRoleSkill(skillGroupId)
                if IsInCD then
                    skill:ClearUsedCount()
                    BattleManager:ShowEnergyChange(XSameColorGameConfigs.EnergyChangeFrom.UseSkill,1)--技能耗能
                    XEventManager.DispatchEvent(XEventId.EVENT_SC_SKILL_USED)
                else
                    skill:AddUsedCount()
                end
                
                
                BattleManager:CheckActionList()
            end)
    end
    
    function XSameColorGameActivityManager.RequestCancelUseItem(skillGroupId, skillId, callback)
        XNetwork.Call(METHOD_NAME.SameColorGameCancelUseItemRequest, {GroupId = skillGroupId, ItemId = skillId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                BattleManager:SetActionList(res.Actions)
                if callback then
                    callback()
                end
                local skill = BattleManager:GetBattleRoleSkill(skillGroupId)
                skill:ClearUsedCount()
                XEventManager.DispatchEvent(XEventId.EVENT_SC_SKILL_USED)
                BattleManager:CheckActionList()
            end)
    end
    
    function XSameColorGameActivityManager.RequestGiveUp(bossId, callback)
        XNetwork.Call(METHOD_NAME.SameColorGameGiveUpRequest, {BossId = bossId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if callback then
                    callback()
                end
            end)
    end
    -- 初始化
    XSameColorGameActivityManager.Init()

    return XSameColorGameActivityManager
end

XRpc.NotifySameColorGameData = function(data)
    XDataCenter.SameColorActivityManager.InitWithServerData(data)
end