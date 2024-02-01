---@class XSCBattleActionInfo
---@field ActionType number XEnumConst.SAME_COLOR_GAME.ACTION_TYPE
---@field CurrentScore number
---@field Step number
---@field LeftCd number
---@field SkillGroupId number
---@field SourceBall XSCBattleBallInfo
---@field DestinationBall XSCBattleBallInfo
---@field SourceBallList XSCBattleBallInfo[]
---@field DestinationBallList XSCBattleBallInfo[]
---@field BallList XSCBattleBallInfo[]
---@field AddBallList XSCBattleBallInfo[]
---@field RemoveBallList XSCBattleBallInfo[]
---@field DropBallList XSCBattleDropBallInfo[]
---@field CurrentSkillId number

---@class XSCBattleBallInfo
---@field ItemId number
---@field PositionX number
---@field PositionY number
---@field ItemType number XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE

---@class XSCBattleSkillEffectParam
---@field EffectPositionList UnityEngine.Vector3[]
---@field LifuEffectIsRowList boolean[] 是否row光波
---@field LifuEffectPos table[] 是否row光波

---@class XSCBattleDropBallInfo
---@field ItemId number
---@field StartPositionX number
---@field StartPositionY number
---@field EndPositionX number
---@field EndPositionY number

local XSCRoleSkill = require("XEntity/XSameColorGame/Skill/XSCRoleSkill")
-- 三消游戏活动管理器
XSameColorGameActivityManagerCreator = function()
    ---@class XSameColorActivityManager
    local XSameColorGameActivityManager = {}
    XSameColorGameActivityManager.DEBUG = false

    local METHOD_NAME = {
        SameColorGameEnterStageRequest = "SameColorGameEnterStageRequest",--进入关卡
        SameColorGameSwapItemRequest = "SameColorGameSwapItemRequest",--交换
        SameColorGameUseItemRequest = "SameColorGameUseItemRequest",--使用技能
        SameColorGameOpenRankRequest = "SameColorGameOpenRankRequest",--打开排行榜
        SameColorGameGiveUpRequest = "SameColorGameGiveUpRequest",--中途放弃
        SameColorGameCancelUseItemRequest = "SameColorGameCancelUseItemRequest",--放弃使用技能（只有多步操作型技能使用（例：进行n次交换，直到造成消除），且需要使用过一次以上）
        SameColorGamePauseResumeRequest = "SameColorGamePauseResumeRequest",--暂停/继续
        SameColorGameCountDownRequest = "SameColorGameCountDownRequest",--3 2 1结束后，请求服务器开始游戏倒计时
    }

    ---@type XSCBossManager
    local BossManager = nil
    ---@type XSCRoleManager
    local RoleManager = nil
    ---@type XSCBattleManager
    local BattleManager = nil
    ---@type XSCRoleSkill[]
    local RoleShowSkillDic = {}
    ---@type XTableSameColorGameActivity
    local Config = nil
    local FirstOpenObtainKey = "FirstOpenObtainKey"
    local IsPause = false -- 当前是否暂停
    ---@type number
    local _GameRunningTime = 0
    ---@type number
    local _GameRunningTimer = false

    -- 初始化
    function XSameColorGameActivityManager.Init()
        Config = XSameColorGameConfigs.GetCurrentConfig()
        local script = require("XEntity/XSameColorGame/Boss/XSCBossManager")
        BossManager = script.New()
        
        script = require("XEntity/XSameColorGame/Role/XSCRoleManager")
        RoleManager = script.New()
        
        script = require("XEntity/XSameColorGame/Battle/XSCBattleManager")
        BattleManager = script.New()

        _GameRunningTime = 0
        XSameColorGameActivityManager.StopRecordRunningTime()
    end

    -- data { ActivityId, BossRecords : List<XSameColorGameBossRecord> }
    function XSameColorGameActivityManager.InitWithServerData(data)
        -- 不相等重新初始化
        if Config.Id ~= data.ActivityId then
            XSameColorGameActivityManager.Init()
        end
        BossManager:InitWithServerData(data.BossRecords)
    end

    function XSameColorGameActivityManager.GetAvailableChapters()
        local result = {}
        if not XSameColorGameActivityManager.GetIsInTime() then
            return result
        end
        table.insert(result, {
                Id = Config.Id,
                Type = XDataCenter.FubenManager.ChapterType.SameColor,
                Name = XMVCA.XSameColor:GetClientCfgStringValue("Name"),
                Icon = XMVCA.XSameColor:GetClientCfgStringValue("BannerIcon")
            })
        return result
    end

    --region Ui
    -- 打开活动主界面
    function XSameColorGameActivityManager.OpenMainUi()
        if not XSameColorGameActivityManager.GetIsOpen(true) then
            return
        end
        XLuaUiManager.Open("UiSameColorGameBossMain")
    end
    --endregion
    
    --region Activity
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

    -- 获取活动剩余时间描述
    function XSameColorGameActivityManager.GetLeaveTimeStr()
        local endTime = XSameColorGameActivityManager.GetEndTime()
        return XUiHelper.GetTime(endTime - XTime.GetServerNowTimestamp()
        , XUiHelper.TimeFormatType.ACTIVITY)
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

    function XSameColorGameActivityManager.HandleActivityEndTime()
        if XSameColorGameActivityManager.DEBUG then
            return
        end
        XLuaUiManager.RunMain()
        local tipUiNameList = {
            "UiSameColorGameSetUp",
            "UiSameColorGameDialog",
        }
        for _, uiName in ipairs(tipUiNameList) do
            if XLuaUiManager.IsUiLoad(uiName) then
                XLuaUiManager.Remove(uiName)
            end
        end
        
        XUiManager.TipMsg(XUiHelper.GetText("SCBossActivityTimeOut"))
    end

    -- 活动界面是否显示 可挑战 页签
    function XSameColorGameActivityManager.IsShowChallengable()
        local bosses = BossManager:GetBosses()
        for _, boss in ipairs(bosses) do
            local isOpen, desc = boss:GetIsOpen()
            local maxScore = boss:GetMaxScore()
            if isOpen and maxScore == 0 then
                return true
            end
        end

        return false
    end
    --endregion

    --region GameRunning
    function XSameColorGameActivityManager.GetGameRunningRecordTime()
        return _GameRunningTime
    end
    
    function XSameColorGameActivityManager.StartRecordRunningTime()
        _GameRunningTime = 0
        local time = CS.UnityEngine.Time
        _GameRunningTimer = XScheduleManager.ScheduleForever(function()
            _GameRunningTime = _GameRunningTime + time.deltaTime
        end, 0, 0)
    end

    function XSameColorGameActivityManager.StopRecordRunningTime()
        if _GameRunningTimer then
            XScheduleManager.UnSchedule(_GameRunningTimer)
        end
        _GameRunningTimer = nil
    end
    --endregion
    
    --region Cache
    function XSameColorGameActivityManager.GetLocalSaveKey()
        return Config.Id .. "_" .. XPlayer.Id .. "XSameColorGameActivityManager"
    end
    
    function XSameColorGameActivityManager.GetIsFirstOpenRoleObtainUi()
        return not XSaveTool.GetData(XSameColorGameActivityManager.GetLocalSaveKey() .. FirstOpenObtainKey)
    end

    function XSameColorGameActivityManager.SetIsFirstOpenRoleObtainUi()
        XSaveTool.SaveData(XSameColorGameActivityManager.GetLocalSaveKey() .. FirstOpenObtainKey, true)
    end
    --endregion
    
    function XSameColorGameActivityManager.GetIsPause()
        return IsPause
    end

    --region Manager
    -- 获取boss管理器
    ---@return XSCBossManager
    function XSameColorGameActivityManager.GetBossManager()
        return BossManager
    end

    -- 获取角色管理器
    ---@return XSCRoleManager
    function XSameColorGameActivityManager.GetRoleManager()
        return RoleManager
    end

    -- 获取战斗管理器
    ---@return XSCBattleManager
    function XSameColorGameActivityManager.GetBattleManager()
        return BattleManager
    end
    --endregion
    
    --region Skill
    ---@return XSCRoleSkill
    function XSameColorGameActivityManager.GetRoleShowSkill(skillGroupId)
        local result = RoleShowSkillDic[skillGroupId]
        if result == nil then
            result = XSCRoleSkill.New(skillGroupId)
            RoleShowSkillDic[skillGroupId] = result
        end
        return result
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
    --endregion

    --region SceneControl
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
        if XSameColorGameActivityManager.UiSceneInfo and XSameColorGameActivityManager.UiSceneInfo.GameObject then
            XSameColorGameActivityManager.UiSceneInfo.GameObject:SetActiveEx(false)
        end
        XSameColorGameActivityManager.UiModel = nil
        XSameColorGameActivityManager.UiModelGo = nil
        XSameColorGameActivityManager.UiSceneInfo = nil
    end
    --endregion
    
    --region Rpc
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
            XSameColorGameActivityManager.StartRecordRunningTime()
            IsPause = false
            BossManager:SetCurrentChallengeBoss(BossManager:GetBoss(bossId))
            BattleManager:SetCurRole(RoleManager:GetRole(roleId))
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
                -- 过滤20143032技能已经结束提示，存在服务器收到使用技能协议时，刚好技能时间结束
                if res.Code == 20143032 then return end

                XUiManager.TipCode(res.Code)
                return
            end
            BattleManager:SetCurUsingSkillId(skillId)
            BattleManager:SetActionList(res.Actions)
            BattleManager:ShowEnergyChange(XEnumConst.SAME_COLOR_GAME.ENERGY_CHANGE_FROM.USE_SKILL, XEnumConst.SAME_COLOR_GAME.TIME_USE_SKILL_MASK)--技能耗能
            if callback then
                callback()
            end
            
            local IsInCD = false
            
            for _,action in pairs(res.Actions or {}) do
                if action.ActionType == XEnumConst.SAME_COLOR_GAME.ACTION_TYPE.SKILL_CD_CHANGE and action.SkillId == skillGroupId then
                    --[[ v4.0统一在action里处理
                    -- 提前刷新CD避免刷新问题
                    BattleManager:ClearPrepSkill()
                    local param = {SkillGroupId = skillGroupId, LeftCd = action.LeftCd, ActionType = XSameColorGameConfigs.ActionType.ActionCdChange}
                    XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_CDCHANGE, param)
                    ]]
                    IsInCD = true
                    break
                end
            end
            
            local skill = BattleManager:GetBattleRoleSkill(skillGroupId)
            if not IsInCD then
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
            BattleManager:ClearPrepSkill()
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

    -- 限时模式请求暂停/继续
    function XSameColorGameActivityManager.RequestPauseResume(isPause, sendProto, callback)
        if isPause == IsPause or not sendProto then
            IsPause = isPause
            if callback then
                callback()
            end
            return
        end

        XNetwork.Call(METHOD_NAME.SameColorGamePauseResumeRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            IsPause = not IsPause
            if callback then
                callback()
            end
        end)
    end

    function XSameColorGameActivityManager.RequestCountDown()
        XNetwork.Call(METHOD_NAME.SameColorGameCountDownRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
        end)
    end
    --endregion
    
    --region FubenEx
    function XSameColorGameActivityManager.GetProgressTips()
        local curProcess = 0
        local bossCount = 0
        local bosses = BossManager:GetBosses()
        for _, boss in ipairs(bosses) do
            if boss:GetIsOpen() and boss:GetMaxScore() > 0 then
                curProcess = curProcess + 1
            end
            bossCount = bossCount + 1
        end
        return XUiHelper.GetText("StrongholdActivityProgress", curProcess, bossCount)
    end
    --endregion
    
    -- 初始化
    XSameColorGameActivityManager.Init()

    return XSameColorGameActivityManager
end

XRpc.NotifySameColorGameData = function(data)
    XDataCenter.SameColorActivityManager.InitWithServerData(data)
end

XRpc.NotifySameColorGameUpdate = function(data)
    local battleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    battleManager:DoUpdateActionList(data.Actions)
end