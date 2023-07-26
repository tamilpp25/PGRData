local Default = {
    _Id = 0,
    _CfgId = 0, --配置Id
    _Select = -1, --记录已选项
    _PlaceId = 0, --关联地点Id
    _Type = XDoomsdayConfigs.EVENT_TYPE.NORMAL, --事件类型
    -------------UI数据（ViewModel）---------
    _Finished = false, --是否完成
    _DayCountUnlock = 0 --生存x天后解锁
}

--末日生存玩法-关卡事件
local XDoomsdayEvent = XClass(XDataEntityBase, "XDoomsdayEvent")

function XDoomsdayEvent:Ctor()
    self:Init(Default)
end

function XDoomsdayEvent:UpdateData(data)
    self:SetProperty("_Id", data.Id)
    self:SetProperty("_CfgId", data.CfgId)
    self:SetProperty("_Select", data.Select)
    self:SetProperty("_PlaceId", data.PlaceId)
    self:SetProperty("_Finished", self._Select ~= -1)
    self:SetProperty("_DayCountUnlock", data.DayCountUnlock)

    local eventType = XDoomsdayConfigs.EVENT_TYPE.NORMAL
    if XDoomsdayConfigs.EventConfig:GetProperty(self._CfgId, "ForceFinish") then
        eventType = XDoomsdayConfigs.EVENT_TYPE.MAIN
    elseif XTool.IsNumberValid(self._PlaceId) then
        eventType = XDoomsdayConfigs.EVENT_TYPE.EXPLORE
    end
    self:SetProperty("_Type", eventType)
end

function XDoomsdayEvent:GetName()
    return XDoomsdayConfigs.EventConfig:GetProperty(self._CfgId, "Name")
end

function XDoomsdayEvent:GetDesc()
    return XDoomsdayConfigs.EventConfig:GetProperty(self._CfgId, "Desc")
end

function XDoomsdayEvent:IsAutoPopupEvent()
    return XDoomsdayConfigs.EventConfig:GetProperty(self._CfgId, "AutoPopup")
end

--==============================
 ---@desc 事件被激活且未完成
 ---@curDay 当前天数 
 ---@return boolean
--==============================
function XDoomsdayEvent:IsActive(curDay)
    return not self:GetProperty("_Finished") and curDay >= self:GetProperty("_DayCountUnlock")
end

--获取选项Id列表
function XDoomsdayEvent:GetSubEventIds()
    local subEventIds = XDoomsdayConfigs.EventConfig:GetProperty(self._CfgId, "SubEventId")
    if XTool.IsTableEmpty(subEventIds) then
        XLog.Error(
            string.format(
                "XDoomsdayEvent:GetSubEventIds error: 关卡事件选项为空, eventId:%d, 配置路径:%s",
                self._CfgId,
                XDoomsdayConfigs.EventConfig:GetPath()
            )
        )
        return {}
    end
    return subEventIds
end

function XDoomsdayEvent:GetSubEventIdAndConditions()
    local subEventIds = self:GetSubEventIds()
    local subConditions = XDoomsdayConfigs.EventConfig:GetProperty(self._CfgId, "SubConditionId")
    local list = {}
    for i, subEventId in ipairs(subEventIds) do
        table.insert(list, {SubEventId = subEventId, SubConditionId = subConditions[i]})
    end
    return list
end

return XDoomsdayEvent
