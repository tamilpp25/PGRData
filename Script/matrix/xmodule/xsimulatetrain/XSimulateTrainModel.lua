-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey = 
{
    SimulateTrainActivity = { CacheType = XConfigUtil.CacheType.Normal },
    SimulateTrainActivityBoss = { CacheType = XConfigUtil.CacheType.Normal },
    SimulateTrainSkill = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
}

---@class XSimulateTrainModel : XModel
local XSimulateTrainModel = XClass(XModel, "XSimulateTrainModel")
function XSimulateTrainModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    
    --config相关
    self._ConfigUtil:InitConfigByTableKey("Fuben/SimulateTrain", TableKey)
end

function XSimulateTrainModel:ClearPrivate()

    --这里执行内部数据清理
    --XLog.Error("请对内部数据进行清理")
end

function XSimulateTrainModel:ResetAll()
    --这里执行重登数据清理
    --XLog.Error("重登数据清理")
    self.ActivityId = nil
end

---------------------------------------- #region Rpc ----------------------------------------
--- 通知数据演习数据
function XSimulateTrainModel:NotifySimulateTrainData(data)
    self.ActivityId = data.ActivityId
end

---------------------------------------- #endregion Rpc ----------------------------------------


---------------------------------------- #region 配置表 ----------------------------------------
--- 获取活动配置表
function XSimulateTrainModel:GetConfigActivity(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.SimulateTrainActivity)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Fuben/SimulateTrain/SimulateTrainActivity.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XSimulateTrainModel:GetActivityName(id)
    local config = self:GetConfigActivity(id)
    return config and config.Name or ""
end

function XSimulateTrainModel:GetActivityBossIds(id)
    local config = self:GetConfigActivity(id)
    return config and config.BossIds or {}
end

--- 获取活动的结束时间戳
--- @param id number 活动Id
function XSimulateTrainModel:GetActivityEndTime(id)
    local config = self:GetConfigActivity(id)
    return config and XFunctionManager.GetEndTimeByTimeId(config.TimeId) or 0
end

--- 获取Boss配置表
function XSimulateTrainModel:GetConfigBoss(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.SimulateTrainActivityBoss)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Fuben/SimulateTrain/SimulateTrainActivityBoss.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XSimulateTrainModel:GetBossMonsterId(id)
    local config = self:GetConfigBoss(id)
    return config and config.MonsterId or 0
end

function XSimulateTrainModel:GetBossTimeId(id)
    local config = self:GetConfigBoss(id)
    return config and config.TimeId or 0
end

function XSimulateTrainModel:GetBossModelId(id)
    local config = self:GetConfigBoss(id)
    return config and config.ModelId or ""
end

function XSimulateTrainModel:GetBossIcon(id)
    local config = self:GetConfigBoss(id)
    return config and config.Icon or ""
end

function XSimulateTrainModel:GetBossRobotIds(id)
    local config = self:GetConfigBoss(id)
    return config and config.RobotIds or {}
end

function XSimulateTrainModel:GetBossTaskIds(id)
    local config = self:GetConfigBoss(id)
    return config and config.TaskIds or {}
end

function XSimulateTrainModel:GetBossTaskTypes(id)
    local config = self:GetConfigBoss(id)
    return config and config.TaskTypes or {}
end

function XSimulateTrainModel:GetBossUiDetailBgs(id)
    local config = self:GetConfigBoss(id)
    return config and config.UiDetailBgs or {}
end

function XSimulateTrainModel:GetBossSkillIds(id)
    local config = self:GetConfigBoss(id)
    return config and config.SkillIds or {}
end

function XSimulateTrainModel:GetBossIdByMonsterId(monsterId)
    local configs = self:GetConfigBoss()
    for i, cfg in pairs(configs) do
        if cfg.MonsterId == monsterId then
            return cfg.Id
        end
    end
end

--- 获取技能配置表
function XSimulateTrainModel:GetConfigSkill(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.SimulateTrainSkill)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Fuben/SimulateTrain/SimulateTrainSkill.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end
---------------------------------------- #endregion 配置表 ----------------------------------------

--- 获取当前开启活动
function XSimulateTrainModel:GetActivityId()
    return self.ActivityId
end

function XSimulateTrainModel:IsActivityOpen()
    -- 开启条件未达成
    local functionName = XFunctionManager.FunctionName.SimulateTrain
    if not XFunctionManager.JudgeCanOpen(functionName) then
        return false, XFunctionManager.GetFunctionOpenCondition(functionName)
    end

    -- 服务端未下发活动数据
    local activityId = self:GetActivityId()
    if not activityId or activityId == 0 then
        return false, XUiHelper.GetText("SpecialTrainNotOpen")
    end

    -- 活动结束
    local config = self:GetConfigActivity(activityId)
    local isInTime = XFunctionManager.CheckInTimeByTimeId(config.TimeId)
    if not isInTime then
        return false, XUiHelper.GetText("ActivityAlreadyOver")
    end

    return true
end

--- 是否显示活动红点
function XSimulateTrainModel:IsShowActivityRedPoint()
    local isOpen, tips = self:IsActivityOpen()
    if not isOpen then
        return false
    end

    -- 检测是否有boss的任务已完成未领奖
    local activityId = self:GetActivityId()
    local bossIds = self:GetActivityBossIds(activityId)
    for _, bossId in ipairs(bossIds) do
        if self:IsShowBossRedPoint(bossId) then
            return true
        end
    end

    -- 新boss解锁
    if self:GetIsShowBossUnlock() then 
        return true
    end

    return false
end

--- 是否显示Boss红点
function XSimulateTrainModel:IsShowBossRedPoint(bossId)
    -- 是否有任务已完成未领奖
    local taskIds = self:GetBossTaskIds(bossId)
    for _, taskId in ipairs(taskIds) do
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then 
            return true
        end
    end

    return false
end

function XSimulateTrainModel:GetIsShowBossUnlock()
    local activityId = self:GetActivityId()
    local saveKey = self:GetBossUnlockSaveKey(activityId)
    local saveData = XSaveTool.GetData(saveKey)
    if not saveData then 
        return true 
    end

    local bossIds = self:GetActivityBossIds(activityId)
    for _, bossId in ipairs(bossIds) do
        local timeId = self:GetBossTimeId(bossId)
        local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
        if isInTime and not saveData[bossId] then
            return true
        end
    end

    return false
end

function XSimulateTrainModel:SaveBossUnlock()
    local activityId = self:GetActivityId()
    local saveKey = self:GetBossUnlockSaveKey(activityId)
    local saveData = XSaveTool.GetData(saveKey) or {}

    local bossIds = self:GetActivityBossIds(activityId)
    for _, bossId in ipairs(bossIds) do
        local timeId = self:GetBossTimeId(bossId)
        local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
        if isInTime then
            saveData[bossId] = true
        end
    end
    XSaveTool.SaveData(saveKey, saveData)
end

function XSimulateTrainModel:GetBossUnlockSaveKey(activityId)
    return string.format("XSimulateTrainModel:GetBossUnlockSaveKey_PlayerId:%s_ActivityId:%s", XPlayer.Id, activityId)
end

--- 处理活动结束
function XSimulateTrainModel:HandleActivityEnd()
    XUiManager.TipText("ActivityAlreadyOver")
    XLuaUiManager.RunMain()
end

-- 怪物是否在活动中
function XSimulateTrainModel:IsMonsterInActivity(monsterId)
    local isOpen, tips = self:IsActivityOpen()
    if not isOpen then
        return false
    end

    local activityId = self:GetActivityId()
    local bossIds = self:GetActivityBossIds(activityId)
    for _, bossId in ipairs(bossIds) do
        local bossMonsterId = self:GetBossMonsterId(bossId)
        local timeId = self:GetBossTimeId(bossId)
        if bossMonsterId == monsterId and XFunctionManager.CheckInTimeByTimeId(timeId) then
            return true
        end
    end
    
    return false
end

return XSimulateTrainModel
