--===========================
--超限乱斗模式管理器
--模块负责：吕天元
--===========================
local XSmashBModeManager = {}
local Modes
local ModeSortByPriority
local LineStageDic
local ModeScript = require("XEntity/XSuperSmashBros/XSmashBMode")
--=============
--初始化管理器
--=============
function XSmashBModeManager.Init(activityId)
    Modes = {}
    ModeSortByPriority = {}
    local modeCfgs = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Activity2ModeDic, activityId)
    for _, modeCfg in pairs(modeCfgs or {}) do
        local mode = ModeScript.New(modeCfg)
        Modes[modeCfg.Id] = mode
        ModeSortByPriority[modeCfg.Priority] = mode
    end
end
--=============
--获取根据优先度排序的模式列表
--=============
function XSmashBModeManager.GetModeSortByPriority()
    return ModeSortByPriority
end
--=============
--刷新后台推送活动数据
--@param data:
--List<SuperSmashBrosModeDb>
--SuperSmashBrosModeDb:
--int ModeId
--List<int> CurFightMonsterGroupId
--Dictionary<int, int> MonsterGroupWinCount
--int Score
--List<int> TakedRewardList
--SuperSmashBrosBattleDb BattleDb
--int LastRankScore
--=============
function XSmashBModeManager.RefreshNotifyModeData(data)
    for _, mode in pairs(Modes) do
        mode:SetIsPlaying(data.CurModeId == mode:GetId())
    end
    for _, modeDb in pairs(data.ModeDbList or {}) do
        local mode = Modes[modeDb.ModeId]
        if mode then
            mode:RefreshNotifyModeData(modeDb)
        end
    end
end
--=============
--刷新模式战斗结果
--=============
function XSmashBModeManager.RefreshBattleResultDb(data, isWin)
    local mode = XSmashBModeManager.GetPlayingMode()
    mode:RefreshBattleResult(data, isWin)
end
--=============
--设置进行游玩的模式
--请注意设置时机，不能与其他冲突
--@param modeId : 设置进行游玩的模式
--=============
function XSmashBModeManager.SetModeIsPlaying(modeId)
    for _, mode in pairs(Modes) do
        mode:SetIsPlaying(modeId == mode:GetId())
    end
end
--=============
--获取连战模式记录的时间挑战数据
--=============
function XSmashBModeManager.GetLastTimeAttackData()
    local mode = XSmashBModeManager.GetModeByModeType(XSuperSmashBrosConfig.ModeType.Survive)
    return mode and mode:GetLastTimeAttackData() or {}
end
--=============
--初始化所有关卡的StageInfo
--=============
function XSmashBModeManager.InitModeStages()
    LineStageDic = {}
    for _, mode in pairs(Modes) do
        local libraryId = mode:GetMapLibraryId()
        local maps = XSuperSmashBrosConfig.GetCfgByIdKey(XSuperSmashBrosConfig.TableKey.Group2SceneDic, libraryId, true)
        local isLine = mode:GetIsLinearStage()
        for _, mapInfo in pairs(maps) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(mapInfo.Id)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.SuperSmashBros
            end
            if isLine then
                LineStageDic[mapInfo.Id] = true
            end
        end
    end
end
--=============
--判断是否线性关卡
--=============
function XSmashBModeManager.CheckIsLineStage(stageId)
    return LineStageDic[stageId]
end
--=============
--获取所有模式(按优先度排序)
--=============
function XSmashBModeManager.GetAllModes()
    return ModeSortByPriority
end
--=============
--获取给定模式类型(对应Id)返回该模式的对象
--若没有查到对象，返回空值
--@params
--modeType : XSuperSmashBrosConfig.ModeType枚举项
--=============
function XSmashBModeManager.GetModeByModeType(modeType)
    return Modes and Modes[modeType]
end
--=============
--获取正在进行的模式
--若没有，则返回未完成的最前面的模式
--=============
function XSmashBModeManager.GetPlayingMode()
    for _, mode in pairs(Modes) do
        if mode:CheckIsPlaying() then
            return mode
        end
    end
    return XSmashBModeManager.GetFirstModeNotCompelete()
end
--=============
--获取未完成的最前面的模式
--顺序根据优先级排列
--若全部模式都已经完成，返回最后一个模式
--=============
function XSmashBModeManager.GetFirstModeNotCompelete()
    --按模式优先级逐个检查通关条件
    for priority, mode in pairs(ModeSortByPriority) do
        --当有模式已开放且没有通关时
        if not mode:CheckComplete() and mode:CheckUnlock() then
            return mode
        end
    end
    return ModeSortByPriority[#ModeSortByPriority]
end
--=============
--获取拥有未领取且可领取奖励的最前面的模式
--顺序根据优先级排列
--若全部模式都没有奖励可领取，返回未完成的最前面的模式
--第二个返回是指有没 未领取的可领取奖励
--=============
function XSmashBModeManager.GetFirstModeHaveRewardGet()
    --按模式优先级逐个检查通关条件
    for priority, mode in pairs(ModeSortByPriority) do
        --当有模式已开放且没有通关时
        if mode:CheckUnlock() then
            local rewardCfg = mode:GetFirstRewardCfgNotGet()
            if rewardCfg then return mode, true end
        end
    end
    return XSmashBModeManager.GetFirstModeNotCompelete(), false
end
--=============
--检查是否所有模式都完成了
--=============
function XSmashBModeManager.CheckIsAllComplete()
    --按模式优先级逐个检查
    for priority, mode in pairs(ModeSortByPriority) do
        --当有模式没有完成时
        if not mode:CheckComplete() then
            return false
        end
    end
    return true
end
--=============
--检查给定模式的其他模式没有正在进行
--@params:
--mode : 给定模式的对象
--=============
function XSmashBModeManager.CheckOtherModeNotPlaying(checkPriority)
    for priority, mode in pairs(ModeSortByPriority) do
        if priority ~= checkPriority and mode:CheckIsPlaying() then
            return false
        end
    end
    return true
end
--=============
--获取所有已解锁模式剩余的未首通怪物数
--=============
function XSmashBModeManager.GetAllLeftMonsters()
    local monsterNum = 0
    --按模式优先级检查
    for priority, mode in pairs(ModeSortByPriority) do
        --按优先级排序的模式，若未解锁，则后面全部模式未解锁
        local unlock = mode:CheckUnlock()
        if not unlock then break end
        --当模式已解锁且未全完成时，统计进剩余怪物数
        if not mode:CheckComplete() then
            monsterNum = monsterNum + mode:GetMonstersNotPass()
        end
    end
    return monsterNum
end

local TotalNum
--=============
--获取所有模式的奖励数，只做一次统计
--=============
function XSmashBModeManager.GetTotalRewardsNum()
    if not TotalNum then
        TotalNum = 0
        for priority, mode in pairs(ModeSortByPriority) do
            TotalNum = TotalNum + #mode:GetAllRewardCfgs()
        end
    end
    return TotalNum
end
--=============
--获取所有模式可获取的奖励档数
--=============
function XSmashBModeManager.GetCurrentRewardsNum()
    local result = 0
    for priority, mode in pairs(ModeSortByPriority) do
        if not mode:CheckUnlock() then
            break
        end       
        result = result + mode:GetScoreArriveNum()
    end
    return result
end
--=============
--获取所有模式已领取的奖励数
--=============
function XSmashBModeManager.GetCurrentGetRewardsNum()
    local result = 0
    for priority, mode in pairs(ModeSortByPriority) do
        if not mode:CheckUnlock() then
            break
        end
        result = result + mode:GetRewardReceivedNum()
    end
    return result
end
--=============
--获取任务进度，↑超限乱斗2期弃用积分奖励，改为任务系统
--=============
function XSmashBModeManager.GetTaskProgress()
    local totalTaskCount = 0
    local finishArchiveTaskCount = 0  --完成的任务
    for priority, mode in pairs(ModeSortByPriority) do
        if not mode:CheckUnlock() then
            break
        end
        local taskGroupId = mode:GetTaskGroupId()
        local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
        totalTaskCount = totalTaskCount + #taskList
        for key, value in pairs(taskList) do
            local taskId = value.Id
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if taskData.State == XDataCenter.TaskManager.TaskState.Finish then
                finishArchiveTaskCount = finishArchiveTaskCount + 1
            end
        end
    end

    return finishArchiveTaskCount, totalTaskCount
end
--=============
--重置正在游玩的模式临时战斗数据
--=============
function XSmashBModeManager:ResetMode()
    XSmashBModeManager.GetPlayingMode():ResetPlaying()
end

return XSmashBModeManager