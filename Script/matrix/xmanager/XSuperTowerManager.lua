--===========================
--超级爬塔管理器
--模块负责：吕天元，陈思亮，张爽
--===========================

--====================
--打印没有当前活动配置错误日志
--====================
local DebugNoCurrentActivityCfg = function()
    --XLog.Error("【超级爬塔】XSuperTowerManager：当前活动配置为空！")
end
--====================
--管理器
--====================
XSuperTowerManagerCreator = function()
    local XSuperTowerManager = {}
    local StageManager --关卡管理器
    local RoleManager --角色管理器
    local BagManager --仓库管理器
    local TeamManager --队伍管理器
    local FunctionManager --特权管理器
    local ShopManager --商店管理器
    local IsShowSettleDark --结算遮罩控制
    local IsCallFinishBattle --是否已经调用FinishBattle
    local HoldFinishBattle --是否挂起了结算战斗
    local HoldSettleData --挂起时缓存的结算数据
    local InitialManagers = false
    local DEBUG = false
    ------------------------------------------------------------------
    ------------------------------------------------------------------
    --===============
    --超级爬塔关卡类型枚举
    --===============
    XSuperTowerManager.StageType = {
        None = 0, -- 缺省类型，表示空值(用于查询时)
        SingleTeamOneWave = 1, -- 单队伍单波
        SingleTeamMultiWave = 2, -- 单队伍多波
        MultiTeamMultiWave = 3, -- 多队伍多波
        LllimitedTower = 4, -- 无限爬塔
    }
    --===============
    --超级爬塔关卡队伍字典
    --===============
    XSuperTowerManager.TeamId = {
        [XSuperTowerManager.StageType.SingleTeamOneWave] = 1, -- 单队伍单波
        [XSuperTowerManager.StageType.SingleTeamMultiWave] = 1, -- 单队伍多波
        [XSuperTowerManager.StageType.LllimitedTower] = 2, -- 无限爬塔
        [XSuperTowerManager.StageType.MultiTeamMultiWave] = 3, -- 多队多波
    }
    --===============
    --超级爬塔队伍类型枚举
    --===============
    XSuperTowerManager.TeamType = {
        SingleTeam = 1, --单队伍
        Tier = 2, --爬塔
    }
    --===============
    --超级爬塔 爬塔结算分数项枚举
    --===============
    XSuperTowerManager.ScoreType = {
        Tier = 1, --通关层数
        NormalBattle = 2, --普通战斗层
        EliteBattle = 3, --精英战斗层
        BossBattle = 4, --Boss战斗层
        EnhancerGet = 5, --获得增益数
        PluginsGet = 6 --获得插件数
    }
    --===============
    --超级爬塔 目标关卡奖励获取状态
    --===============
    XSuperTowerManager.StageRewardState = {
        Complete = 1, --已获得
        CanGet = 2, --可获得
        Lock = 3, --未解锁
    }
    --===============
    --超级爬塔 基础配置Key值枚举
    --===============
    XSuperTowerManager.BaseCfgKey = {
        ScoreItemId = "ScoreItemId", --积分物品id
        InitBagCapacity = "InitBagCapacity", --初始背包容量
        MaxBagCapacity = "MaxBagCapacity", --最大背包容量
        MaxTeamPluginCount = "MaxTeamPluginCount",
        SingleCapacityCount = "SingleCapacityCount", --单次扩容数量
        BagCacheCapacity = "BagCacheCapacity", --背包缓存容量
        MainAssetsPanelItem1 = "CurrencyItem1", --主界面和角色货币栏道具1
        MainAssetsPanelItem2 = "CurrencyItem2", --主界面和角色货币栏道具2
        MainAssetsPanelItem3 = "CurrencyItem3", --主界面和角色货币栏道具3
        BagAssetsPanelItem1 = "CurrencyItemOther1", --商店和背包货币栏道具1
        BagAssetsPanelItem2 = "CurrencyItemOther2", --商店和背包货币栏道具2
        BagAssetsPanelItem3 = "CurrencyItemOther3", --商店和背包货币栏道具3
    }
    --===============
    --超级爬塔 特权Key枚举
    --===============
    XSuperTowerManager.FunctionName = {
        Shop = "CheckMallIsOpen", --商店
        Transfinite = "CheckSuperLimitIsOpen", --角色超限
        BonusChara = "CheckSpecialCharacterIsOpen", --特典角色
        MultiTeam = "CheckMultiTeamChallengeOpen", --多队伍挑战
        Exclusive = "CheckSlotIsOpen" --专属槽
    }
    --===============
    --超级爬塔 主题Index
    --===============
    XSuperTowerManager.ThemeIndex = {
        ThemeAll = 0, --主题区域总览
    }
    --===============
    --超级爬塔 关卡Index
    --===============
    XSuperTowerManager.StageIndex = {
        StageAll = 0, --关卡区域总览
    }
    --===============
    --超级爬塔 协议名
    --===============
    local METHOD_NAME = {
        StConfirmTargetResultRequest = "StConfirmTargetResultRequest",--确认目标关卡战斗结果
    }
    --===============
    --超级爬塔 道具类型
    --===============
    XSuperTowerManager.ItemType = {
        Enhance = 1,
        Plugin = 2,
    }
    --===============
    --目标关卡 目标关卡属性类型
    --===============
    XSuperTowerManager.StageElement = {
        None = 0, --无
        NextFloor = 2, --下一层
        Keep = 3, --保持现状，暂时离开
    }
    ------------------------------------------------------------------
    ------------------------------------------------------------------
    --===============
    --初始化
    --===============
    function XSuperTowerManager.Init()
        XSuperTowerManager.InitActivityCfg()
        if not XSuperTowerManager.CheckActivityIsInTime() and not DEBUG then
            return
        end
        XSuperTowerManager.InitManagers()
    end
    
    function XSuperTowerManager.InitManagers()
        if InitialManagers then return end
        XSuperTowerManager.InitStageManager()
        XSuperTowerManager.InitRoleManager()
        XSuperTowerManager.InitBagManager()
        XSuperTowerManager.InitTeamManager()
        XSuperTowerManager.InitFunctionManager()
        XSuperTowerManager.InitShopManager()
        InitialManagers = true
    end
    --===============
    --初始化活动配置
    --===============
    local CurrentActivityCfg
    function XSuperTowerManager.InitActivityCfg()
        CurrentActivityCfg = XSuperTowerConfigs.GetCurrentActivity()
    end
    --===============
    --初始化关卡管理器
    --===============
    function XSuperTowerManager.InitStageManager()
        local script = require("XEntity/XSuperTower/Stages/XSuperTowerStageManager")
        StageManager = script.New(XSuperTowerManager)
    end
    --===============
    --初始化角色管理器
    --===============
    function XSuperTowerManager.InitRoleManager()
        local script = require("XEntity/XSuperTower/Role/XSuperTowerRoleManager")
        RoleManager = script.New(XSuperTowerManager)
    end

    function XSuperTowerManager.InitFunctionManager()
        local script = require("XEntity/XSuperTower/Function/XSuperTowerFunctionManager")
        FunctionManager = script.New(XSuperTowerManager)
    end
    --===============
    --初始化队伍管理器
    --===============
    function XSuperTowerManager.InitTeamManager()
        local script = require("XEntity/XSuperTower/XSuperTowerTeamManager")
        TeamManager = script.New(XSuperTowerManager)
    end
    --===============
    --获取队伍管理器
    --===============
    function XSuperTowerManager.InitBagManager()
        local script = require("XEntity/XSuperTower/XSuperTowerBagManager")
        BagManager = script.New(XSuperTowerManager)
    end
    --===============
    --初始化商店管理器
    --===============
    function XSuperTowerManager.InitShopManager()
        local script = require("XEntity/XSuperTower/Shop/XSuperTowerShopManager")
        ShopManager = script.New(XSuperTowerManager)
    end
    --===============
    --FubenManager代理方法:检查stageId是否有通关
    --===============
    function XSuperTowerManager.CheckPassedByStageId(stageId)
        local targetStage = StageManager:GetTargetStageByStageId(stageId)
        if targetStage then
            return targetStage:CheckIsClear()
        else
            return false
        end
    end
    --===============
    --FubenManager代理方法:出战前检查
    --===============
    function XSuperTowerManager.CheckPreFight(stage, challengeCount)
        local stageType = XSuperTowerManager.GetStageTypeByStageId(stage.StageId)
        if stageType == XSuperTowerManager.StageType.None then
            XUiManager.TipError("关卡不存在!")
            return false
        elseif stageType == XSuperTowerManager.StageType.LllimitedTower then
            local team = XSuperTowerManager.GetTeamByStageId(stage.StageId)
            --爬塔需要3个人
            local isFullMember = team:GetIsFullMember()
            if not isFullMember then XUiManager.TipText("STTierStageNotFullMemember") end
            return isFullMember
        else
            --XUiManager.TipMsg("TODO -- 目标关卡战斗前检查")
            return true
        end
    end
    --===============
    --FubenManager代理方法:准备出战数据
    --===============
    function XSuperTowerManager.PreFight(stage, team, isAssist, challengeCount, challengeId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.RobotIds = {}
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1
        local stageType = XSuperTowerManager.GetStageTypeByStageId(stage.StageId)
        if stageType == XSuperTowerManager.StageType.None then
            return nil
        else
            local team = XSuperTowerManager.GetTeamByStageId(stage.StageId)
            if team then
                for i = 1, 3 do
                    local entityId = team:GetEntityIdByTeamPos(i)
                    local role = RoleManager:GetRole(entityId)
                    preFight.CardIds[i] = role and role:GetCharacterId() or 0
                    if role and role:GetIsRobot() then
                        preFight.RobotIds[i] = role:GetId()
                    else
                        preFight.RobotIds[i] = 0
                    end
                end
                preFight.CaptainPos = team:GetCaptainPos()
                preFight.FirstFightPos = team:GetFirstFightPos()
            end
        end
        return preFight
    end
    --===============
    --FubenManager代理方法:结束战斗
    --===============
    function XSuperTowerManager.FinishFight(settleData)
        if not IsCallFinishBattle then
            HoldFinishBattle = true
            HoldSettleData = settleData
            return
        end
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(settleData.StageId)
        if stageInfo.Type ~= XDataCenter.FubenManager.StageType.SuperTower then
           return 
        end
        
        local stageId = settleData.StageId
        local stageType = XSuperTowerManager.GetStageTypeByStageId(stageId)
        if stageType == XSuperTowerManager.StageType.LllimitedTower then
            XSuperTowerManager.TierStageFinish(settleData)
        else
            XSuperTowerManager.TargetStageFinish(settleData)
        end
        
        IsShowSettleDark = false
        HoldFinishBattle = false
        IsCallFinishBattle = false
        HoldSettleData = nil
    end
    --===============
    --FubenManager代理方法:调用结算战斗时
    --===============
    function XSuperTowerManager.CallFinishFight()
        local res = XMVCA.XFuben:GetFubenSettleResult()
        XMVCA.XFuben:SetFubenSettling(false)
        XMVCA.XFuben:SetFubenSettleResult(nil)

        --通知战斗结束，关闭战斗设置页面
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)

        if not res then
            IsShowSettleDark = true
            IsCallFinishBattle = true
            return
        end

        if res.Code ~= XCode.Success then
            CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SETTLE_FAIL, res.Code)
            return
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_RESULT, res.Settle)
        IsCallFinishBattle = true
        if HoldFinishBattle then
            XSuperTowerManager.FinishFight(HoldSettleData)
        end
    end
    --===============
    --进入战斗
    --===============
    function XSuperTowerManager.EnterFight(stageId)
        local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageType = XSuperTowerManager.GetStageTypeByStageId(stageId)
        if stageType == XSuperTowerManager.StageType.None then
            XUiHelper.GetText("STNoStageType")
            return
        elseif stageType == XSuperTowerManager.StageType.LllimitedTower then --爬塔直接调用EnterFight
            local isAssist = false
            local challengeCount = 1
            XDataCenter.FubenManager.EnterFight(stageConfig, nil, isAssist, challengeCount)
        else --目标关卡需先设定队伍信息，成功后再进入关卡
            local isAssist = false
            local challengeCount = 1
            XDataCenter.FubenManager.EnterFight(stageConfig, nil, isAssist, challengeCount)
        end
    end
    --===============
    --爬塔关卡结束时
    --===============
    function XSuperTowerManager.TierStageFinish(settleData)
        local theme = StageManager:GetThemeByStageId(settleData.StageId)
        XSuperTowerManager:GetStageManager():RefreshStMapTierData(settleData.StMapTierDataOperation)
        --[[if settleData.IsWin then
            if theme:GetResetFlag() then
                XLuaUiManager.Open("UiSuperTowerInfiniteSettleWin", settleData)
            end
        else
            if theme:GetResetFlag() then
                XLuaUiManager.Open("UiSuperTowerInfiniteSettleWin", settleData)
            end
        end]]
        --XLog.Debug("================爬塔关卡结束:SettleData:", settleData)
        if theme:GetResetFlag() then
            XLuaUiManager.Open("UiSuperTowerInfiniteSettleWin", settleData)
        end
    end
    --===============
    --目标关卡结束时
    --===============
    function XSuperTowerManager.TargetStageFinish(settleData)
        local stageId = settleData.StageId
        local stageType = XSuperTowerManager.GetStageTypeByStageId(stageId)
        local targetStage = XSuperTowerManager.GetTargetStageByStageId(stageId)
        XSuperTowerManager.GetStageManager():SetTempProgress(settleData.StTargetStageFightResult)
        local tempProgress = StageManager:GetTempProgressByTargetId(targetStage:GetId())
        local IsMultiTeam = stageType ==XSuperTowerManager.StageType.MultiTeamMultiWave
        local teamList = IsMultiTeam and XSuperTowerManager.GetTeamByStageId(stageId) or
        {XSuperTowerManager.GetTeamByStageId(stageId)}

        if IsMultiTeam then
            local teamCount = targetStage:GetTeamCount()
            teamList = XSuperTowerManager.GetTeamByStageType(stageType,teamCount)
        else
            teamList = {XSuperTowerManager.GetTeamByStageId(stageId)}
        end

        local battledTeamList = {}
        local pulginList = {}
        for index,team in pairs(teamList or {}) do
            if index <= tempProgress then
                local pluginSlotManger = team:GetExtraData()
                local plugins = pluginSlotManger:GetPlugins()
                for _,plugin in pairs(plugins or {}) do
                    if type(plugin) == "table" then
                        table.insert(pulginList, plugin)
                    end
                end
                table.insert(battledTeamList, team)
            end
        end
        if settleData.IsWin and IsMultiTeam then
            if not StageManager:IsSetTempProgress() then
                XLog.Error("SuperTower SetTempProgress Is Late!")
            end
            StageManager:ClearTempProgressMark()
            
            if tempProgress < targetStage:GetProgress() then
                local nextIndex = tempProgress + 1
                local nextStageId = targetStage:GetStageIdByIndex(nextIndex)
                local nextTeam = XSuperTowerManager.GetTeamByStageId(nextStageId)
                XSuperTowerManager.EnterFight(nextStageId)
            else
                XLuaUiManager.Open("UiSuperTowerSettleWin",targetStage, pulginList, tempProgress, battledTeamList)
            end
        else
            XLuaUiManager.Open("UiSuperTowerSettleWin",targetStage, pulginList, tempProgress, battledTeamList)
        end
    end
    ------------------------------------------------------------------
    ------------------------------------------------------------------
    --===============
    --获取当前活动配置ID
    --===============
    function XSuperTowerManager.GetActivityId()
        if not CurrentActivityCfg then
            DebugNoCurrentActivityCfg()
            return 1
        end
        return CurrentActivityCfg.Id
    end
    --===============
    --获取当前活动TimeId
    --===============
    function XSuperTowerManager.GetActivityTimeId()
        if not CurrentActivityCfg then
            DebugNoCurrentActivityCfg()
            return 0
        end
        return CurrentActivityCfg.TimeId
    end
    --===============
    --获取当前活动的主题组ID
    --===============
    function XSuperTowerManager.GetThemeIds()
        if not CurrentActivityCfg then
            DebugNoCurrentActivityCfg()
            return {}
        end
        return CurrentActivityCfg.MapId
    end
    --===============
    --获取当前活动的名字
    --===============
    function XSuperTowerManager.GetActivityName()
        if not CurrentActivityCfg then
            DebugNoCurrentActivityCfg()
            return {}
        end
        return CurrentActivityCfg.Name
    end
    
    function XSuperTowerManager.GetActivityEntryImage()
        if not CurrentActivityCfg then
            DebugNoCurrentActivityCfg()
            return ""
        end
        return CurrentActivityCfg.EntryImage
    end
    --===============
    --获取当前活动序言故事ID
    --===============
    function XSuperTowerManager.GetPrefaceStoryId()
        if not CurrentActivityCfg then
            DebugNoCurrentActivityCfg()
            return {}
        end
        return CurrentActivityCfg.PrefaceStoryId
    end
    --===============
    --获取背包管理器
    --===============
    function XSuperTowerManager.GetBagManager()
        return BagManager
    end
    --===============
    --获取角色管理器
    --===============
    function XSuperTowerManager.GetRoleManager()
        return RoleManager
    end
    --===============
    --获取关卡管理器
    --===============
    function XSuperTowerManager.GetStageManager()
        return StageManager
    end
    --===============
    --获取队伍管理器
    --===============
    function XSuperTowerManager.GetTeamManager()
        return TeamManager
    end
    --===============
    --获取特权管理器
    --===============
    function XSuperTowerManager.GetFunctionManager()
        return FunctionManager
    end
    --===============
    --获取商店管理器
    --===============
    ---@return XSuperTowerShopManager
    function XSuperTowerManager.GetShopManager()
        return ShopManager
    end
    --===============
    --检测结算遮罩是否打开
    --===============
    ---@return IsShowSettleDark
    function XSuperTowerManager.CheckShowSettleDark()
        return IsShowSettleDark
    end
    --===============
    --获取当前活动开始时间戳(根据TimeId)
    --===============
    function XSuperTowerManager.GetActivityStartTime()
        return XFunctionManager.GetStartTimeByTimeId(XSuperTowerManager.GetActivityTimeId())
    end
    --===============
    --获取当前活动结束时间戳(根据TimeId)
    --===============
    function XSuperTowerManager.GetActivityEndTime()
        return XFunctionManager.GetEndTimeByTimeId(XSuperTowerManager.GetActivityTimeId())
    end
    --===============
    --根据关卡Id获取关卡类型(XSuperTowerManager.StageType)
    --若查不到结果，会返回XSuperTowerManager.StageType.None
    --@param stageId:关卡Id
    --===============
    function XSuperTowerManager.GetStageTypeByStageId(stageId)
        return StageManager:GetStageTypeByStageId(stageId)
    end
    --===============
    --根据关卡Id获取关卡序号
    --若查不到结果，会返回0
    --@param stageId:关卡Id
    --===============
    function XSuperTowerManager.GetStageIndexByStageId(stageId)
        return StageManager:GetStageIndexByStageId(stageId)
    end
    --===============
    --根据关卡Id获取队伍ID
    --若查不到结果，会返回nil
    --@param stageId:关卡Id
    --===============
    function XSuperTowerManager.GetTeamIdByStageId(stageId)
        local stageType = XSuperTowerManager.GetStageTypeByStageId(stageId)
        return XSuperTowerManager.GetTeamIdByStageType(stageType)
    end
    --===============
    --根据关卡类型获取队伍ID
    --若查不到结果，会返回nil
    --@param stageType:(XSuperTowerManager.StageType)
    --===============
    function XSuperTowerManager.GetTeamIdByStageType(stageType)
        return XSuperTowerManager.TeamId[stageType]
    end
    --===============
    --根据关卡ID获取队伍对象
    --若查不到结果，会返回nil
    --@param stageId:关卡Id
    --===============
    function XSuperTowerManager.GetTeamByStageId(stageId)
        local teamId = XSuperTowerManager.GetTeamIdByStageId(stageId)
        local stageIndex = XSuperTowerManager.GetStageIndexByStageId(stageId)

        if teamId and stageIndex > 0 then
            return TeamManager:GetTeamById(teamId, stageIndex)
        end
        return nil
    end
    --===============
    --===============
    --根据关卡类型获取队伍对象(多队伍时会返回该类型所有队伍对象)
    --若查不到结果，会返回nil
    --@param stageType:(XSuperTowerManager.StageType)
    --@param teamCount:多队伍类型时需要获取的队伍数
    --===============
    function XSuperTowerManager.GetTeamByStageType(stageType, teamCount)
        local teamId = XSuperTowerManager.GetTeamIdByStageType(stageType)
        if teamId then
            if stageType == XSuperTowerManager.StageType.MultiTeamMultiWave then
                local teamList = {}
                local count = teamCount or 0
                for index = 1, count do
                    table.insert(teamList, TeamManager:GetTeamById(teamId, index))
                end
                return next(teamList) and teamList
            else
                return TeamManager:GetTeamById(teamId)--单队伍时不需要设置关卡序号（有且仅有1），默认为1
            end
        end
        return nil
    end
    --===============
    --根据关卡ID获取目标关卡ID
    --===============
    function XSuperTowerManager.GetTargetStageIdByStageId(stageId)
        return StageManager:GetTargetStageIdByStageId(stageId)
    end
    --===============
    --根据关卡ID获取目标关卡的关卡数量
    --===============
    function XSuperTowerManager.GetTargetStageCountByStageId(stageId)
        local targetStage = StageManager:GetTargetStageByStageId(stageId)
        if targetStage == nil then return 0 end
        return #targetStage:GetStageId()
    end
    --===============
    --根据关卡ID获取目标关卡数据实体
    --===============
    function XSuperTowerManager.GetTargetStageByStageId(stageId)
        return StageManager:GetTargetStageByStageId(stageId)
    end
    --===============
    --根据关卡Id获取关卡在目标关卡中的序号
    --===============
    function XSuperTowerManager.GetStageIndexByStageId(stageId)
        return StageManager:GetStageIndexByStageId(stageId)
    end
    --===============
    --根据队伍实体获取该队伍中所有角色ID
    --===============
    function XSuperTowerManager.GetCharacterIdListByTeamEntity(stTeam)
        local characterIds = {}
        if stTeam then
            for index,id in pairs(stTeam:GetEntityIds()) do
                local role = RoleManager:GetRole(id)
                if role then
                    characterIds[index] = role:GetCharacterId()
                else
                    characterIds[index] = 0
                end
            end
        end
        return characterIds
    end
    --===============
    --清除多队伍关卡的所有队伍数据
    --===============
    function XSuperTowerManager.ClearAllMultiTeamsData()
        local teamMaxCount = StageManager:GetMaxStageCount()
        local teamId = XSuperTowerManager.TeamId[XSuperTowerManager.StageType.MultiTeamMultiWave]
        for index = 1,teamMaxCount do
            TeamManager:ClearTeam(teamId, index)
        end
    end
    --===============
    --一键上阵
    --===============
    function XSuperTowerManager.AutoTeam(stStage)
        local normalRoleList = RoleManager:GetCanFightRoles(XEnumConst.CHARACTER.CharacterType.Normal)
        local isomerRoleList = RoleManager:GetCanFightRoles(XEnumConst.CHARACTER.CharacterType.Isomer)
        
        XSuperTowerManager.ClearAllMultiTeamsData()
        
        local stageIdList = stStage:GetStageId()

        table.sort(normalRoleList, function(a, b)
                return a:GetAbility() > b:GetAbility()
            end)
        table.sort(isomerRoleList, function(a, b)
                return a:GetAbility() > b:GetAbility()
            end)

        -- 正在使用的角色id字典
        local usingCharacterIdDic = {}

        for index,stageId in pairs(stageIdList or {}) do --优先选择倾向构造体
            local memberCount = stStage:GetMemberCountByIndex(index)
            local recommendType = XFubenConfigs.GetStageRecommendCharacterType(stageId) or XEnumConst.CHARACTER.CharacterType.Normal
            local team = XSuperTowerManager.GetTeamByStageId(stageId)
            team:Clear()
            local charIndex = 1
            local curCount = 1

            local roleList
            if recommendType == XEnumConst.CHARACTER.CharacterType.Isomer then
                roleList = isomerRoleList
            elseif recommendType == XEnumConst.CHARACTER.CharacterType.Normal then
                roleList = normalRoleList
            end

            while curCount <= memberCount do
                local role = roleList[charIndex]
                if role then
                    if XFubenConfigs.IsStageRecommendCharacterType(stageId, role:GetId()) and
                        -- not team:CheckHasSameCharacterId(role:GetId()
                        not usingCharacterIdDic[role:GetCharacterId()] then

                        team:UpdateEntityTeamPos(role:GetId(), curCount, true)
                        usingCharacterIdDic[role:GetCharacterId()] = true
                        if curCount == 1 then
                            team:UpdateFirstFightPos(curCount)
                            team:UpdateCaptainPos(curCount)
                        end

                        table.remove(roleList,charIndex)
                        charIndex = charIndex - 1
                        curCount = curCount + 1
                    end
                else
                    break
                end
                charIndex = charIndex + 1
            end
        end

        for index,stageId in pairs(stageIdList or {}) do --补足非倾向构造体
            local memberCount = stStage:GetMemberCountByIndex(index)
            local recommendType = XFubenConfigs.GetStageRecommendCharacterType(stageId) or XEnumConst.CHARACTER.CharacterType.Normal
            local team = XSuperTowerManager.GetTeamByStageId(stageId)
            local charIndex = 1
            local curCount = 1

            local roleList
            if recommendType == XEnumConst.CHARACTER.CharacterType.Isomer then
                roleList = isomerRoleList
            elseif recommendType == XEnumConst.CHARACTER.CharacterType.Normal then
                roleList = normalRoleList
            end

            while curCount <= memberCount do
                if team:GetEntityIdByTeamPos(curCount) == 0 then
                    local role = roleList[charIndex]
                    if role then
                        -- not team:CheckHasSameCharacterId(role:GetId())
                        if not usingCharacterIdDic[role:GetCharacterId()] then
                            team:UpdateEntityTeamPos(role:GetId(), curCount, true)
                            usingCharacterIdDic[role:GetCharacterId()] = true
                            if curCount == 1 then
                                team:UpdateFirstFightPos(curCount)
                                team:UpdateCaptainPos(curCount)
                            end

                            table.remove(roleList,charIndex)
                            charIndex = charIndex - 1
                            curCount = curCount + 1
                        end
                    else
                        break
                    end
                    charIndex = charIndex + 1
                else
                    curCount = curCount + 1
                end
            end
        end
    end

    --===============
    --一键填充插件
    --stStage : XSuperTowerTargetStage
    --===============
    function XSuperTowerManager.AutoPulgin(stStage)
        local teamManager = XDataCenter.SuperTowerManager.GetTeamManager()
        local teams = teamManager:GetTeamsByIdAndCount(XDataCenter.SuperTowerManager.TeamId[stStage:GetStageType()]
            , XSuperTowerConfigs.MaxMultiTeamCount)
        teamManager:AutoSelectPlugins2Teams(teams)
    end
    --===============
    --检查背包与特权弹窗
    --===============
    function XSuperTowerManager.CheckPopupWindow(callBack)
        local unLockFuncList = FunctionManager:GetUnlockList()
        if unLockFuncList and #unLockFuncList > 0 then
            XLuaUiManager.Open("UiSuperTowerUnlockTips", unLockFuncList, function()
                    XSuperTowerManager.CheckPopupWindow(callBack)
                end)
            return
        end
        local hasUpdate, last, current = BagManager:CheckMaxCapacityUpdate()
        if hasUpdate then
            XLuaUiManager.Open("UiSupertowerUpTips", last, current, function()
                    XSuperTowerManager.CheckPopupWindow(callBack)
                end)
            return
        end
        if callBack then
            callBack()
        end
    end
    --===============
    --根据关卡ID获取队伍对象
    --若查不到结果，会返回nil
    --@param stStage:目标关卡
    --===============
    function XSuperTowerManager.CheckTeamListAllHasCaptainAndFirstPos(stStage)
        local IsNotHasCaptain = false
        local IsNotHasFirstPos =  false
        for index,stageId in pairs(stStage:GetStageId() or {}) do
            local teamId = XSuperTowerManager.GetTeamIdByStageId(stageId)
            if teamId then
                local team = TeamManager:GetTeamById(teamId, index)
                if not team:GetCaptainPosEntityId() or team:GetCaptainPosEntityId() == 0 then
                    IsNotHasCaptain = true
                end
                if not team:GetFirstFightPosEntityId() or team:GetFirstFightPosEntityId() == 0 then
                    IsNotHasFirstPos = true
                end
            end
        end
        return not IsNotHasCaptain, not IsNotHasFirstPos
    end
    --===============
    --检查现在是否在活动时间内(根据TimeId)
    --===============
    function XSuperTowerManager.CheckActivityIsInTime()
        local now = XTime.GetServerNowTimestamp()
        return (now >= XSuperTowerManager.GetActivityStartTime())
        and (now < XSuperTowerManager.GetActivityEndTime())
    end
    --===============
    --根据特权Key检查特权是否解锁
    --@param key:特权键值 XSuperTowerManager.FunctionName
    --===============
    function XSuperTowerManager.CheckFunctionUnlockByKey(key)
        return FunctionManager:CheckFunctionUnlockByKey(key)
    end
    ------------------------------------------------------------------
    ------------------------------------------------------------------
    --===============
    --获取主题选择状态的本地数据
    --
    --===============
    function XSuperTowerManager.GetCurSelectThemeIndex()
        local activityId = XSuperTowerManager.GetActivityId()
        return XSaveTool.GetData(string.format( "%sSuperTowerCurSelectThemeIndex%s", XPlayer.Id, activityId))
    end
    --===============
    --保存主题选择状态的本地数据
    --index:主题序号
    --===============
    function XSuperTowerManager.SaveCurSelectThemeIndex(index)
        local activityId = XSuperTowerManager.GetActivityId()
        local data = XSaveTool.GetData(string.format( "%sSuperTowerCurSelectThemeIndex%s", XPlayer.Id, activityId))
        if not data then
            XSaveTool.SaveData(string.format( "%sSuperTowerCurSelectThemeIndex%s", XPlayer.Id, activityId), index)
        end
    end
    --===============
    --删除主题选择状态的本地数据
    --===============
    function XSuperTowerManager.RemoveCurSelectThemeIndex()
        local activityId = XSuperTowerManager.GetActivityId()
        local data = XSaveTool.GetData(string.format( "%sSuperTowerCurSelectThemeIndex%s", XPlayer.Id, activityId))
        if data then
            XSaveTool.RemoveData(string.format( "%sSuperTowerCurSelectThemeIndex%s", XPlayer.Id, activityId))
        end
    end
    ------------------------------------------------------------------
    ------------------------------------------------------------------
    --=====================
    --确认目标关卡战斗结果
    --@param targetStageId :目标关卡ID
    --@response res.RewardGoodsList :奖励列表
    --=====================
    function XSuperTowerManager.ConfirmTargetResultRequest(targetStageId, cb)
        XNetwork.Call(METHOD_NAME.StConfirmTargetResultRequest, {TargetId = targetStageId}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb(res.RewardGoodsList) end
            end)
    end
    ------------------------------------------------------------------
    ------------------------------------------------------------------
    --=====================
    --处理登陆活动内容推送
    --@data : {
    -- 活动id public int Id,
    -- 地图信息列表 public List<StMapInfo> MapInfos,
    -- 超限角色信息 public List<StTransfiniteCharacterInfo> CharacterInfos,
    -- 背包信息 public StBagInfo BagInfo }
    --=====================
    function XSuperTowerManager.RefreshLoginData(data)
        if data and next(data) and not InitialManagers then
            XSuperTowerManager.InitManagers()
        end
        StageManager:RefreshNotifyMapInfo(data.MapInfos)
        RoleManager:InitWithServerData(data.CharacterInfos)
        BagManager:InitWithServerData(data.BagInfo)
        ShopManager:UpdateShopData(data.MallInfo)
        FunctionManager:SetUnLockEvent() --初始化特权需要在首次刷新关卡数据的时候
    end
    --=====================
    --替换fubenmanager里的OpenFightLoading()
    --=====================
    function XSuperTowerManager.OpenFightLoading(stageId)
        local stageType = XSuperTowerManager.GetStageTypeByStageId(stageId)
        if stageType == XSuperTowerManager.StageType.MultiTeamMultiWave then
            local targetStage = XSuperTowerManager.GetTargetStageByStageId(stageId)
            local tempProgress = StageManager:GetTempProgressByTargetId(targetStage:GetId())
            XLuaUiManager.Open("UiSuperTowerLoading", targetStage, tempProgress + 1)
        else
            XDataCenter.FubenManager.OpenFightLoading(stageId)
        end
    end
    --=====================
    --替换fubenmanager里的CloseFightLoading()
    --=====================
    function XSuperTowerManager.CloseFightLoading(stageId)
        local stageType = XSuperTowerManager.GetStageTypeByStageId(stageId)
        if stageType == XSuperTowerManager.StageType.MultiTeamMultiWave then
            if XLuaUiManager.IsUiLoad("UiSuperTowerLoading") then
                XLuaUiManager.Remove("UiSuperTowerLoading")
            end
        else
            XDataCenter.FubenManager.CloseFightLoading(stageId)
        end
    end
    --=================================入口，跳转相关=============================
    --===================
    --获取活动配置简表
    --===================
    function XSuperTowerManager.GetActivityChapters()
        --只有活动开启期间显示入口
        local isEnd = XSuperTowerManager.GetIsEnd()
        if isEnd then return {} end
        local chapters = {}
        local tempChapter = {}
        tempChapter.Type = XDataCenter.FubenManager.ChapterType.SuperTower
        tempChapter.Id = XSuperTowerManager.GetActivityId()
        table.insert(chapters, tempChapter)
        return chapters
    end
    --================
    --跳转到活动主界面
    --================
    function XSuperTowerManager.JumpTo()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SuperTower) then
            local canGoTo, notStart = XSuperTowerManager.CheckCanGoTo()
            if canGoTo then
                XLuaUiManager.Open("UiSuperTowerMain")
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
    function XSuperTowerManager.CheckCanGoTo()
        local isActivityEnd, notStart = XSuperTowerManager.GetIsEnd()
        return not isActivityEnd, notStart
    end
    --================
    --跳转到爬塔关卡准备界面
    --若有正在爬的塔则跳转到正在爬的塔
    --没有的话跳转到最新章节的塔
    --================
    function XSuperTowerManager.SkipToSuperTowerTier()
        local playingId = StageManager:GetPlayingTierId()
        local theme
        if playingId > 0 then
            theme = StageManager:GetThemeById(playingId)
        else
            theme = StageManager:GetThemeByClearProgress()
        end
        XLuaUiManager.Open("UiSuperTowerStageDetail04", theme)
    end
    --================
    --获取玩法是否关闭(用于判断玩法入口，进入活动条件等)
    --@return param1:玩法是否关闭
    --@return param2:是否活动未开启
    --================
    function XSuperTowerManager.GetIsEnd()
        local timeNow = XTime.GetServerNowTimestamp()
        local isEnd = timeNow >= XSuperTowerManager.GetActivityEndTime()
        local isStart = timeNow >= XSuperTowerManager.GetActivityStartTime()
        local inActivity = (not isEnd) and (isStart)
        return not inActivity, timeNow < XSuperTowerManager.GetActivityStartTime()
    end
    --================
    --玩法关闭时弹出主界面
    --================
    function XSuperTowerManager.HandleActivityEndTime()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("STActivityTimeEnd"))
    end
    --=====================================================================
    XSuperTowerManager.Init()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD,XSuperTowerManager.FinishFight)
    return XSuperTowerManager
end
--=====================
--登陆活动内容推送
--@data : {
-- 活动id public int Id,
-- 地图信息列表 public List<StMapInfo> MapInfos,
-- 超限角色信息 public List<StTransfiniteCharacterInfo> CharacterInfos,
-- 背包信息 public StBagInfo BagInfo }
--=====================
XRpc.NotifySuperTowerLoginData = function(data)
    XDataCenter.SuperTowerManager.RefreshLoginData(data)
end
--[[
XRpc.NotifyStMapTierData = function(data)
    XDataCenter.SuperTowerManager.GetStageManager():RefreshStMapTierData(data)
end
]]
XRpc.NotifyStMapTargetData = function(data)
    XDataCenter.SuperTowerManager.GetStageManager():RefreshStMapTargetData(data)
end
--[[
XRpc.NotifyTargetStageFightResult = function(data)
    XDataCenter.SuperTowerManager.GetStageManager():SetTempProgress(data)
end
]]
XRpc.NotifySuperTowerMallRefreshData = function(data)
    local shopManager = XDataCenter.SuperTowerManager.GetShopManager()
    if shopManager then
        shopManager:OnrMallRefreshData(data)
    end
end
XRpc.NotifySuperTowerMallData = function(data)
    local shopManager = XDataCenter.SuperTowerManager.GetShopManager()
    if shopManager then
        shopManager:UpdateShopData(data.MallInfo)
    end
end
-- 背包最大容量
XRpc.NotifyStBagCapacity = function(data)
    XDataCenter.SuperTowerManager.GetBagManager():UpdateMaxCapacity(data.Capacity)
end
-- 背包插件更新
XRpc.NotifyStBagPluginChange = function(data)
    XDataCenter.SuperTowerManager.GetBagManager():OnBagPluginChange(data)
end
-- 通知背包插件合成数据
-- data : List<StPluginSynthesisInfo>
XRpc.NotifyStBagPluginSynthesisData = function(pluginSynthesisInfos)
    XDataCenter.SuperTowerManager.GetBagManager():OnBagPluginSynthesisData(pluginSynthesisInfos)
end