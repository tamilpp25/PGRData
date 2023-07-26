--===========================
--超限乱斗玩法管理器
--模块负责：吕天元
--===========================
XSuperSmashBrosManagerCreator = function()
    --===================================
    --DEBUG相关
    --===================================
    local DEBUG = false
    local _printDebug = function(...)
        if not DEBUG then return end
        XLog.Debug(...)
    end
    -- local MANAGER_INITIAL = false
    -------------------------------------
    -------------------------------------
    ---@class XSuperSmashBrosManager
    local XSuperSmashBrosManager = {}
    local Config = XSuperSmashBrosConfig

    local TimeManager = require("XEntity/XSuperSmashBros/XSmashBActivityTimeManager")
    local ActivityManager = require("XEntity/XSuperSmashBros/XSmashBActivityManager")

    local Managers = {
        TimeManager,
        ActivityManager,
    }
    --===============
    --超限乱斗 协议名
    --===============
    local METHOD_NAME = {
        SetStage = "SuperSmashBrosSetTeamRequest", --设置关卡
        EquipCore = "SuperSmashBrosMountCoreRequest", --装备核心
        CoreLevelUp = "SuperSmashBrosUpgradeCoreRequest", --升级核心
        CoreAtkUpgrade = "SuperSmashBrosStrongAttackRequest", --强化攻击等级
        CoreLifeUpgrade = "SuperSmashBrosStrongHpRequest", --强化生命等级
        BattleConfirm = "SuperSmashBrosConfirmRequest",
        GetRankingInfo = "SuperSmashBrosGetRankRequest", --获取排行榜信息
        TakeScoreReward = "SuperSmashBrosTakeScoreRewardRequest", --获取积分奖励
        RollBackRecord = "SuperSmashBrosStageRollBackRequest", --回滚战斗
        ChangeStage = "SuperSmashBrosChangeStageRequest",
    }
    --===============
    --初始化
    --===============
    local HasSettle -- 结算过了
    local TempSettleResult
    function XSuperSmashBrosManager.Init()
        XSuperSmashBrosManager.InitActivityCfg()
        XSuperSmashBrosManager.SetMetaTable()
        XSuperSmashBrosManager.InitManagers()
        -- if not TimeManager.CheckActivityIsInTime() then -- 在这里检测服务器时间太早了，服务器还未下发时间列表， 暂时屏蔽MANAGER_INITIAL
        --     MANAGER_INITIAL = false
        --     return
        -- end
        --[[ abandoned
        XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD,
            function(settleData)
                XSuperSmashBrosManager.OnSettle(settleData)
                local isLiner = XSuperSmashBrosManager.CheckIsLineStage(settleData.StageId)
                if isLiner then
                    if settleData.IsWin then
                        if not XLuaUiManager.IsUiShow("UiSuperSmashBrosBattleResult")  then
                            XLuaUiManager.Open("UiSuperSmashBrosBattleResult", nil)
                        end
                    else
                        CS.XFight.ExitForClient(true)
                    end
                    HasSettle = nil
                    TempSettleResult = nil
                end
            end)
        ]]
        -- MANAGER_INITIAL = true
    end
    --===============
    --初始化活动配置
    --===============
    function XSuperSmashBrosManager.InitActivityCfg()
        XSuperSmashBrosManager.CurrentActivityCfg = Config.GetCurrentActivity()
        TimeManager.SetConfig(XSuperSmashBrosManager.CurrentActivityCfg)
        ActivityManager.SetConfig(XSuperSmashBrosManager.CurrentActivityCfg)
    end
    --===============
    --设置索引
    --===============
    function XSuperSmashBrosManager.SetMetaTable()
        local _mTable = {__index = function(baseTable, key)
                for _, manager in pairs(Managers) do
                    if manager and manager[key] then
                        local v = manager[key]
                        baseTable[key] = v
                        return v
                    end
                end
                return nil
            end}
        setmetatable(XSuperSmashBrosManager, _mTable)
    end
    --===============
    --初始化具体管理器
    --===============
    local InitManager = function(managerName)
        local manager = require("XEntity/XSuperSmashBros/XSmashB" .. managerName .. "Manager")
        if manager then
            manager.Init(XSuperSmashBrosManager.GetActivityId())
            table.insert(Managers, manager)
        end
    end
    --===============
    --初始化管理器
    --===============
    function XSuperSmashBrosManager.InitManagers()
        InitManager("Mode")
        InitManager("Core")
        InitManager("Role")
        InitManager("Monster")
        InitManager("Ranking")
        InitManager("Team")
    end
    --===============
    --接受活动数据推送
    --===============
    function XSuperSmashBrosManager.OnNotifySuperSmashBrosChange(data)
        XSuperSmashBrosManager.RefreshNotifyActivityData(data)
        XSuperSmashBrosManager.RefreshNotifyModeData(data)
        XSuperSmashBrosManager.RefreshNotifyCoreData(data)
        XSuperSmashBrosManager.RefreshNotifyMonsterData(data)
        XSuperSmashBrosManager.RefreshNotifyRoleData(data)
    end
    --===============
    --FubenManager代理方法:初始化StageInfo
    --===============
    function XSuperSmashBrosManager.InitStageInfo()
        -- if not MANAGER_INITIAL then return end
        XSuperSmashBrosManager.InitModeStages()
    end
    --===============
    --FubenManager代理方法:准备出战数据
    --===============
    function XSuperSmashBrosManager.PreFight(stage, teamIds, isAssist, challengeCount, challengeId)
        ---@type XSmashBMode
        local playingMode = XSuperSmashBrosManager.GetPlayingMode()
        local preFight = {}
        preFight.CardIds = {}
        preFight.RobotIds = {}
        preFight.StageId = stage.StageId
        preFight.IsHasAssist = isAssist and true or false
        preFight.ChallengeCount = challengeCount or 1
        local modeId = playingMode:GetId()
        preFight.CaptainPos = XSuperSmashBrosManager.GetCaptainPosByModeId(modeId)
        local teamId = playingMode:GetBattleMember()
        local teamCaptainPos = 1
        for index, id in pairs(teamId) do
            if id > 0 then
                local pos = XSuperSmashBrosManager.GetColorByIndexAndModeId(index, modeId)
                if pos == preFight.CaptainPos then
                    teamCaptainPos = index
                    break
                end
            end
        end

        --是否是重新挑战(仅适用多个角色上场的模式)通过重新挑战进入战斗的，一定是全部角色死亡，所以重新挑战时队长位要找到再上一次的队伍中首个存活的
        local allHp = 0
        for i = 1, 3 do
            if teamId[i] then
                local role = XSuperSmashBrosManager.GetRoleById(teamId[i])     
                if role then
                    allHp = allHp + role:GetHpLeft()
                end
            end
        end
        local isRetry = allHp <= 0
        if isRetry then
            local mode = XDataCenter.SuperSmashBrosManager.GetModeByModeType(modeId)
            local lastAliveBattleResult = mode:GetResult()
            local charaList = lastAliveBattleResult.CharacterResultList
            
            local retryFindNewCaptain = true
            for i = 1, 3 do
                if charaList[i] and not playingMode:IsAssistancePos(i) then
                    local dataValue = charaList[i]
                    local role = XSuperSmashBrosManager.GetRoleById(teamId[i]) 
                    preFight.CardIds[i] = role and dataValue.HpPercent > 0 and role:GetCharacterId() or 0
                    if role and dataValue.HpPercent > 0 then
                        if not preFight.FirstFightPos then
                            --首发位默认为队伍最前面存活的人员
                            preFight.FirstFightPos = XSuperSmashBrosManager.GetColorByIndexAndModeId(i, modeId)
                        end
                        if retryFindNewCaptain then
                            preFight.CaptainPos = XSuperSmashBrosManager.GetColorByIndexAndModeId(i, modeId)
                            retryFindNewCaptain = false
                        end
                    end
                    if role and dataValue.HpPercent > 0 and role:GetIsRobot() then
                        preFight.RobotIds[i] = role:GetId()
                    else
                        preFight.RobotIds[i] = 0
                    end
                else
                    preFight.CardIds[i] = 0
                    preFight.RobotIds[i] = 0
                end
            end
        end

        local captainRole = XSuperSmashBrosManager.GetRoleById(teamId[teamCaptainPos])
        local needNewCaptainPos = captainRole and captainRole:GetHpLeft() <= 0
        if teamId and not isRetry then
            for i = 1, 3 do
                if teamId[i] and not playingMode:IsAssistancePos(i) then
                    ---@type XSmashBCharacter
                    local role = XSuperSmashBrosManager.GetRoleById(teamId[i])
                    preFight.CardIds[i] = role and role:GetHpLeft() > 0 and role:GetCharacterId() or 0
                    if role and role:GetHpLeft() > 0 then
                        if not preFight.FirstFightPos then
                            --首发位默认为队伍最前面存活的人员
                            preFight.FirstFightPos = XSuperSmashBrosManager.GetColorByIndexAndModeId(i, modeId)
                        end
                        if needNewCaptainPos then
                            preFight.CaptainPos = XSuperSmashBrosManager.GetColorByIndexAndModeId(i, modeId)
                            needNewCaptainPos = false
                        end
                    end
                    if role and role:GetHpLeft() > 0 and role:GetIsRobot() then
                        preFight.RobotIds[i] = role:GetId()
                    else
                        preFight.RobotIds[i] = 0
                    end
                else
                    preFight.CardIds[i] = 0
                    preFight.RobotIds[i] = 0
                end
            end
        end
        return preFight
    end
    --===============
    --战斗是否自动退出(连战模式时需要手动退出战斗界面)
    --===============
    function XSuperSmashBrosManager.CheckAutoExitFight(stageId)
        return not XSuperSmashBrosManager.CheckIsLineStage(stageId)
    end

    function XSuperSmashBrosManager.OnSettle(settleData)
        if not settleData then return end
        local stageId = settleData.StageId
        if not stageId then return end
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if not stageInfo or (stageInfo.Type ~= XDataCenter.FubenManager.StageType.SuperSmashBros) then
            return
        end
        HasSettle = true
        XSuperSmashBrosManager.RefreshBattleResultDb(settleData.SuperSmashBrosBattleResult, settleData.IsWin)
        TempSettleResult = settleData.IsWin
    end
    --===============
    --FubenManager代理方法:结束战斗
    --===============
    local _IsJustFail = false
    function XSuperSmashBrosManager.FinishFight(settleData)
        if not settleData.IsWin then
            XDataCenter.FubenManager.ChallengeLose(settleData)
        end
        --XSuperSmashBrosManager.RefreshBattleResultDb(settleData.SuperSmashBrosBattleResult, settleData.IsWin)
    end
    --===============
    --FubenManager代理方法:显示战斗总结
    --===============
    function XSuperSmashBrosManager.ShowSummary(stageId)
        local isLiner = XSuperSmashBrosManager.CheckIsLineStage(stageId)
        if isLiner then
            if TempSettleResult then
                if not XLuaUiManager.IsUiShow("UiSuperSmashBrosBattleResult") then
                    XLuaUiManager.Open("UiSuperSmashBrosBattleResult", nil)
                end
            else
                -- 如果没有结算，判断是结算还未下发还是因为战斗结算失败没下发
                if HasSettle then
                    CS.XFight.ExitForClient(true)
                end
            end
            TempSettleResult = nil
            HasSettle = nil
        end
    end
    --=====================
    --进入战斗准备
    --@param :
    --stageId : 关卡Id
    --=====================
    function XSuperSmashBrosManager.SetStage(mode, envId, stageId, ownTeamIdList, monsterGroupIdList, cb)
        local modeId = mode:GetId()
        local charaIdList, posList, captainPos, firstFightPos = XSuperSmashBrosManager.GetSetTeamRoleTeam(modeId, ownTeamIdList)
        local data = {
            ModeId = modeId,
            StageId = stageId,
            EnvId = envId or 0,
            CaptainPos = captainPos,
            CharacterIdList = charaIdList,
            CharacterPosIndexList = posList,
            MonsterGroupIdList = XSuperSmashBrosManager.SelectRandomMonster(monsterGroupIdList, stageId, modeId),
            FirstFightPos = firstFightPos
        }
        --XLog.Debug("超限乱斗Setteam Data:", data)
        XNetwork.Call(METHOD_NAME.SetStage, data, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XSuperSmashBrosManager.SetModeIsPlaying(modeId)
                mode:RefreshNotifyModeData(res.ModeDb)
                if cb then
                    cb()
                end
            end)
    end

    function XSuperSmashBrosManager.EquipCore(core, role, cb)
        XNetwork.Call(METHOD_NAME.EquipCore, {CoreId = core and core:GetId() or 0, CharacterId = role:GetId()}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                role:SetCore(core and core:GetId() or nil)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_SSB_CORE_REFRESH)
            end)
    end

    function XSuperSmashBrosManager.UpgradeCoreAttack(core, value)
        if value > 0 then
            if XDataCenter.SuperSmashBrosManager.GetNotUsedEnergy() < XDataCenter.SuperSmashBrosManager.GetEnergyCostOnUpgrade() * value then
                XUiManager.TipText("SSBEnergyNotEnough")
                return
            end
        end
        XNetwork.Call(METHOD_NAME.CoreAtkUpgrade, {CoreId = core:GetId(), Value = value}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local coreData = res.CoreDb
                core:SetStar(coreData.Level)
                core:SetAtkLevel(coreData.StrongAttack or 0)
                core:SetLifeLevel(coreData.StrongHp or 0)
                XSuperSmashBrosManager.RefreshNotifyEnergyData(res.EnergyDb)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_SSB_CORE_REFRESH)
            end)
    end

    function XSuperSmashBrosManager.UpgradeCoreLife(core, value)
        if value > 0 then
            if XDataCenter.SuperSmashBrosManager.GetNotUsedEnergy() < XDataCenter.SuperSmashBrosManager.GetEnergyCostOnUpgrade() * value then
                XUiManager.TipText("SSBEnergyNotEnough")
                return
            end
        end
        XNetwork.Call(METHOD_NAME.CoreLifeUpgrade, {CoreId = core:GetId(), Value = value}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local coreData = res.CoreDb
                core:SetStar(coreData.Level)
                core:SetAtkLevel(coreData.StrongAttack or 0)
                core:SetLifeLevel(coreData.StrongHp or 0)
                XSuperSmashBrosManager.RefreshNotifyEnergyData(res.EnergyDb)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_SSB_CORE_REFRESH)
            end)
    end

    function XSuperSmashBrosManager.CoreLevelUp(core)
        XNetwork.Call(METHOD_NAME.CoreLevelUp, {CoreId = core:GetId()}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                core:SetStar(core:GetStar())
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_SSB_CORE_REFRESH, true)
            end)
    end

    function XSuperSmashBrosManager.BattleConfirm(cb, isGiveUp)
        XNetwork.Call(METHOD_NAME.BattleConfirm, { IsGiveup = isGiveUp }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if res.ModeDb then
                    local mode = XSuperSmashBrosManager.GetPlayingMode()
                    mode:RefreshNotifyModeData(res.ModeDb)
                end
                if res.StageHistory then
                    XSuperSmashBrosManager.RefreshNotifyTimeAttackData(res.StageHistory)
                end
                local addEnergy = 0
                if res.EnergyDb then
                    addEnergy = res.EnergyDb.MaxValue - XSuperSmashBrosManager.GetCurrentEnergy()
                    XSuperSmashBrosManager.RefreshNotifyEnergyData(res.EnergyDb)
                end
                local addLevelItem = 0
                if res.TeamLevel then
                    addLevelItem = res.AddTeamItem
                    XSuperSmashBrosManager.RefreshNotifyTeamLevelData(res)
                end
                if cb then
                    --AddScore是奖励的积分(非道具，这里单独处理)
                    --增加的能量(特殊处理的道具，差值也是前面计算的)
                    cb(res.ResultList, res.AddScore, addLevelItem)
                end
            end)
    end

    function XSuperSmashBrosManager.GetRankingInfo(career, cb)
        XNetwork.Call(METHOD_NAME.GetRankingInfo, {
            Career = career
        }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XSuperSmashBrosManager.RefreshRankingData(career, res)
                if cb then
                    cb()
                end
            end)
    end

    function XSuperSmashBrosManager.TakeScoreReward(rewardCfg, cb)
        XNetwork.Call(METHOD_NAME.TakeScoreReward, {RewardId = rewardCfg.Id}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                local mode = XSuperSmashBrosManager.GetModeByModeType(rewardCfg.ModeId)
                mode:SetReceiveStateByRewardId(rewardCfg.Id)
                if cb then
                    cb(res.ResultList)
                end
            end)
    end
    
    function XSuperSmashBrosManager.RollBackRecord(index, cb)
        XNetwork.Call(METHOD_NAME.RollBackRecord, {
            Index = index - 1
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if res.ModeDb then
                local mode = XSuperSmashBrosManager.GetPlayingMode()
                mode:RefreshNotifyModeData(res.ModeDb)
            end
            if cb then
                cb()
            end
        end)
    end
    
    function XSuperSmashBrosManager.ChangeStage(stageId, cb)
        XNetwork.Call(METHOD_NAME.ChangeStage, {
            StageId = stageId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if res.ModeDb then
                local mode = XSuperSmashBrosManager.GetPlayingMode()
                mode:RefreshNotifyModeData(res.ModeDb)
            end
            if cb then
                cb()
            end
        end)
    end

    local KEY_HINT_ROLL_BACK = "SuperSmashRollBackRecord"
    function XSuperSmashBrosManager.DialogRollBack(callback)
        local key = KEY_HINT_ROLL_BACK
        local status = XSaveTool.GetData(key)
        if status then
            callback()
            return
        end
        local hitInfo =
        {
            SetHintCb = function(isSelected)
                XSaveTool.SaveData(key, isSelected)
            end,
            Status = status
        }
        XUiManager.DialogHintTip(
                XUiHelper.GetText("SuperSmashRollBackTitle"),
                XUiHelper.ReadTextWithNewLine("SuperSmashRollBack"),
                "",
                nil,
                callback,
                hitInfo
        )
    end
    
    function XSuperSmashBrosManager.IsJustFail()
        local value = _IsJustFail
        _IsJustFail = false
        return value
    end

    function XSuperSmashBrosManager.SetJustFail()
        _IsJustFail = true
    end

    XSuperSmashBrosManager.Init()
    return XSuperSmashBrosManager
end
--=========================
--XSuperSmashBrosDb 结构:
--{
--public int ActivityId --活动Id
--public List<SuperSmashBrosSuperCoreDb> SuperCoreDbList = new List<SuperSmashBrosSuperCoreDb>() --核心数据
--public List<SuperSmashBrosModeDb> ModeDbList = new List<SuperSmashBrosModeDb>() --模式数据
--public Dictionary<int, int> CharacterMountCore = new Dictionary<int, int>() --角色装备核心状态
--public int UpgradeCorePoint --核心升级点数
--public int ModeId --正在进行的模式Id
--public Dictionary<int, bool> StageHistory = new Dictionary<int, bool>() --首通情况
--}
--=========================
--=========================
--SuperSmashBrosModeDb 结构
--{
--public int ModeId;
--public Dictionary<int, int> MonsterGroupWinCount = new Dictionary<int, int>()
--public int Score;
--public List<int> TakedRewardList = new List<int>() --已经领取的积分奖励
--public int ElectricEnergy
--public SuperSmashBrosBattleDb BattleDb
--public int LastRankScore
--}
--=========================
--=========================
--SuperSmashBrosSuperCoreDb 结构
--{
--public int Id 核心Id
--public int Level 核心星级
--}
--=========================
--================
--活动数据推送
--@param
--data :
--XSuperSmashBrosDb ActivityDb
--================
XRpc.NotifySuperSmashBrosChange = function(data)
    XDataCenter.SuperSmashBrosManager.OnNotifySuperSmashBrosChange(data.ActivityDb)
end