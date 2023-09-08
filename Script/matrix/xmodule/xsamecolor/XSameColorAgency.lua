---@class XSameColorAgency : XAgency
---@field private _Model XSameColorModel
local XSameColorAgency = XClass(XAgency, "XSameColorAgency")
function XSameColorAgency:OnInit()
    --初始化一些变量
end

function XSameColorAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XSameColorAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region RedPoint
function XSameColorAgency:CheckTaskRedPoint(taskType)
    local taskList = {}
    if taskType == nil then
        taskList = appendArray(self:GetTaskData(XEnumConst.SAME_COLOR_GAME.TASK_TYPE.DAY)
        , self:GetTaskData(XEnumConst.SAME_COLOR_GAME.TASK_TYPE.REWARD))
    else
        taskList = self:GetTaskData(taskType)
    end
    for _, taskData in pairs(taskList) do
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
end
--endregion

--region Data
function XSameColorAgency:GetTaskData(taskType)
    return self._Model:GetTaskData(taskType)
end
--endregion

--region Cfg - ClientConfig
function XSameColorAgency:GetClientCfgStringValue(key, index)
    return self._Model:GetClientCfgStringValue(key, index)
end

function XSameColorAgency:GetClientCfgValue(key)
    return self._Model:GetClientCfgValue(key)
end
--endregion

return XSameColorAgency