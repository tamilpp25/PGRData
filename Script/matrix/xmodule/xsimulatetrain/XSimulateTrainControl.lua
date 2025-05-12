---@class XSimulateTrainControl : XControl
---@field _Model XSimulateTrainModel
local XSimulateTrainControl = XClass(XControl, "XSimulateTrainControl")
function XSimulateTrainControl:OnInit()
    --初始化内部变量
end

function XSimulateTrainControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XSimulateTrainControl:RemoveAgencyEvent()

end

function XSimulateTrainControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

---------------------------------------- #region 配置表 ----------------------------------------
function XSimulateTrainControl:GetConfigActivity(id)
    return self._Model:GetConfigActivity(id)
end

function XSimulateTrainControl:GetActivityName(id)
    return self._Model:GetActivityName(id)
end

function XSimulateTrainControl:GetActivityBossIds(id)
    return self._Model:GetActivityBossIds(id)
end

function XSimulateTrainControl:GetActivityEndTime(id)
    return self._Model:GetActivityEndTime(id)
end

function XSimulateTrainControl:GetConfigBoss(id)
    return self._Model:GetConfigBoss(id)
end

function XSimulateTrainControl:GetBossTimeId(id)
    return self._Model:GetBossTimeId(id)
end

function XSimulateTrainControl:GetBossMonsterId(id)
    return self._Model:GetBossMonsterId(id)
end

function XSimulateTrainControl:GetBossModelId(id)
    return self._Model:GetBossModelId(id)
end

function XSimulateTrainControl:GetBossIcon(id)
    return self._Model:GetBossIcon(id)
end

function XSimulateTrainControl:GetBossTaskIds(id)
    return self._Model:GetBossTaskIds(id)
end

function XSimulateTrainControl:GetBossTaskTypes(id)
    return self._Model:GetBossTaskTypes(id)
end

function XSimulateTrainControl:GetBossUiDetailBgs(id)
    return self._Model:GetBossUiDetailBgs(id)
end
---------------------------------------- #endregion 配置表 ----------------------------------------

--- 获取当前开启活动Id
function XSimulateTrainControl:GetActivityId()
    return self._Model:GetActivityId()
end

--- 获取活动是否开启
function XSimulateTrainControl:IsActivityOpen()
    return self._Model:IsActivityOpen()
end

--- 是否显示boss红点
function XSimulateTrainControl:IsShowBossRedPoint(bossId)
    return self._Model:IsShowBossRedPoint(bossId)
end

--- 保存boss的解锁情况
function XSimulateTrainControl:SaveBossUnlock()
    self._Model:SaveBossUnlock()
end

--- 处理活动结束
function XSimulateTrainControl:HandleActivityEnd()
    self._Model:HandleActivityEnd()
end

return XSimulateTrainControl