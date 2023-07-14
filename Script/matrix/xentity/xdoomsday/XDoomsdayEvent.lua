local Default = {
    _Id = 0,
    _CfgId = 0, --配置Id
    _Select = -1, --记录已选项
    _PlaceId = 0, --关联地点Id
    _Type = XDoomsdayConfigs.EVENT_TYPE.NORMAL, --事件类型
    -------------UI数据（ViewModel）---------
    _Finished = false --是否完成
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

return XDoomsdayEvent
