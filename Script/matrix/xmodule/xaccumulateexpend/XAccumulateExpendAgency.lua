---@class XAccumulateExpendAgency : XAgency
---@field private _Model XAccumulateExpendModel
local XAccumulateExpendAgency = XClass(XAgency, "XAccumulateExpendAgency")
function XAccumulateExpendAgency:OnInit()
    -- 初始化一些变量
    self._OpenKey = "ACCUMULATE_EXPEND_OPEN_"
end

function XAccumulateExpendAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
    XRpc.NotifyAccumulateExpendData = Handler(self, self.OnNotifyAccumulateExpendData)
end

function XAccumulateExpendAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XAccumulateExpendAgency:CheckIsOpen()
    local activityId = self._Model:GetActivityId()

    if not XTool.IsNumberValid(activityId) then
        return false
    end
    
    local conditionIds = self._Model:GetActivityConditionIdsById(activityId)

    if not XTool.IsTableEmpty(conditionIds) then
        for _, conditionId in pairs(conditionIds) do
            if XTool.IsNumberValid(conditionId) then
                if not XConditionManager.CheckCondition(conditionId) then
                    return false
                end
            end
        end
    end

    local timeId = self._Model:GetActivityTimeIdById(activityId)

    return XFunctionManager.CheckInTimeByTimeId(timeId, false)
end

function XAccumulateExpendAgency:CheckIsFirstOpen()
    local activityId = self._Model:GetActivityId()

    if not XTool.IsNumberValid(activityId) then
        return false
    end

    local isOpened = XSaveTool.GetData(self._OpenKey .. XPlayer.Id .. activityId)

    return not isOpened
end

function XAccumulateExpendAgency:CheckHasReward()
    local configs = self._Model:GetRewardConfigs()

    for _, config in pairs(configs) do
        local taskData = XDataCenter.TaskManager.GetTaskDataById(config.TaskId)

        if taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end

    return false
end

function XAccumulateExpendAgency:OnEnterActivity()
    if self:CheckIsOpen() then
        local activityId = self._Model:GetActivityId()

        -- 活动分包资源检测
        if not XMVCA.XSubPackage:CheckSubpackage() then
            return
        end
        if not XTool.IsNumberValid(activityId) then
            return
        end

        XSaveTool.SaveData(self._OpenKey .. XPlayer.Id .. activityId, true)
        XLuaUiManager.Open("UiAccumulateDraw")
    end
end

function XAccumulateExpendAgency:OnNotifyAccumulateExpendData(data)
    self._Model:SetActivityId(data.ActivityId)
    XEventManager.DispatchEvent(XEventId.EVENT_ACCUMULATE_DRWA_UPDATE)
end

return XAccumulateExpendAgency
