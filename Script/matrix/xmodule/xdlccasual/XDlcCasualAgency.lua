local XDlcActivityAgency = require("XModule/XBase/XDlcActivityAgency")
local XDlcCasualRoom = require("XModule/XDlcCasual/XEntity/XDlcCasualRoom")
local XDlcCasualWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcCasualWorldFight")

---@class XDlcCasualAgency : XDlcActivityAgency
---@field private _Model XDlcCasualModel
local XDlcCasualAgency = XClass(XDlcActivityAgency, "XDlcCasualAgency")

function XDlcCasualAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
end

function XDlcCasualAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyDlcCasualCubeData = Handler(self, self.OnNotifyDlcCasualCubeData)
end

function XDlcCasualAgency:InitEvent()
    --实现跨Agency事件注册
end

function XDlcCasualAgency:OnNotifyDlcCasualCubeData(data)
    local activityId = data.Id

    XMVCA.XDlcRoom:InitFight()
    self._Model:SetActivityId(activityId)
    self:DispatchEvent(XEventId.EVENT_DLC_CASUAL_ACTIVITY_UPDATE_NOTIFY)
end

function XDlcCasualAgency:GetNpcIdById(characterId)
    return self._Model:GetCharacterNpcIdById(characterId)
end

--region 副本入口相关
function XDlcCasualAgency:ExCheckInTime()
    if not self.Super.ExCheckInTime(self) then
        return false
    end

    return self:_CheckActivityOpen()
end

function XDlcCasualAgency:ExGetConfig()
    if not XTool.IsTableEmpty(self.ExConfig) then
        return self.ExConfig
    end
    self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)

    return self.ExConfig
end

function XDlcCasualAgency:ExGetProgressTip()
    return ""
end

function XDlcCasualAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.DlcCasual
end

--endregion

--region Dlc活动相关
function XDlcCasualAgency:DlcGetRoomProxy()
    return XDlcCasualRoom.New()
end

function XDlcCasualAgency:DlcGetFightEvent()
    return XDlcCasualWorldFight.New()
end

function XDlcCasualAgency:DlcReconnect()
    XLuaUiManager.Open("UiDlcHuntDialog", nil, nil, function()
        XMVCA.XDlcRoom:ReconnectToRoom(function()
            XMVCA.XDlcRoom:ReconnectToWorld()
        end)
    end, function()
        XMVCA.XDlcRoom:ClearReconnectData()
    end)
end

--endregion

function XDlcCasualAgency:GetOpenLevelLimit()
    local config = self:ExGetConfig()
    local funcId = config.FunctionNameId
    local conditionId = XFunctionConfig.GetFuncOpenCfg(funcId).Condition[1]
    local levelLimit = XConditionManager.GetConditionParams(conditionId)

    return levelLimit
end

function XDlcCasualAgency:CheckAllTasksAchieved()
    if self._Model:GetActivityId() == nil then
        return false
    end

    return self:CheckDailyTasksAchieved() or self:CheckAccumulatedTasksAchieved()
end

function XDlcCasualAgency:CheckDailyTasksAchieved()
    return self:_CheckTaskAchievedByType(XEnumConst.DlcCasualGame.TaskGroupType.Daily)
end

function XDlcCasualAgency:CheckAccumulatedTasksAchieved()
    return self:_CheckTaskAchievedByType(XEnumConst.DlcCasualGame.TaskGroupType.Normal)
end

--region 私有方法
function XDlcCasualAgency:_CheckActivityOpen()
    local activityId = self._Model:GetActivityId()

    if not activityId then
        return false
    end

    local timeId = self._Model:GetActivityTimeIdById(activityId)

    return XFunctionManager.CheckInTimeByTimeId(timeId, false)
end

function XDlcCasualAgency:_GetTaskGroupIdByType(taskType)
    local activityId = self._Model:GetActivityId()
    local taskGroupIds = self._Model:GetActivityTaskGroupIdsById(activityId)

    return taskGroupIds[taskType]
end

function XDlcCasualAgency:_CheckTaskAchievedByType(taskType)
    local taskGroupId = self:_GetTaskGroupIdByType(taskType)

    return XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId)
end

--endregion

return XDlcCasualAgency
