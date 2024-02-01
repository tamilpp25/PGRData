---@class XUiPanelRogueSimEvent : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimEvent = XClass(XUiNode, "XUiPanelRogueSimEvent")

function XUiPanelRogueSimEvent:OnStart()
    self:RegisterUiEvents()
end

function XUiPanelRogueSimEvent:OnGetLuaEvents()
    return {
        XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE,
        XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP,
        XEventId.EVENT_ROGUE_SIM_BUILDING_ADD,
        XEventId.EVENT_ROGUE_SIM_BUILDING_BUY,
        XEventId.EVENT_ROGUE_SIM_EVENT_ADD,
        XEventId.EVENT_ROGUE_SIM_EVENT_REMOVE,
        XEventId.EVENT_ROGUE_SIM_REWARDS_CHANGE,
        XEventId.EVENT_ROGUE_SIM_EVENT_UPDATE,
        XEventId.EVENT_ROGUE_SIM_TURN_NUMBER_CHANGE,
    }
end

function XUiPanelRogueSimEvent:OnNotify(event, ...)
    self:Refresh()
end

function XUiPanelRogueSimEvent:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.GridLevelUp, self.OnGridLevelUpClick)
    XUiHelper.RegisterClickEvent(self, self.GridBuild, self.OnGridBuildClick)
    XUiHelper.RegisterClickEvent(self, self.GridEvent, self.OnGridEventClick)
    XUiHelper.RegisterClickEvent(self, self.GridItem, self.OnGridItemClick)
end

function XUiPanelRogueSimEvent:OnGridLevelUpClick()
    self._Control:CameraFocusMainGrid(function()
        XLuaUiManager.Open("UiRogueSimLv")
    end)
end

function XUiPanelRogueSimEvent:OnGridBuildClick()
    self._Control.MapSubControl:ExploreBuildingGrid(self.BuildingId)
end

function XUiPanelRogueSimEvent:OnGridEventClick()
    self._Control.MapSubControl:ExploreEventGrid(self.EventId)
end

function XUiPanelRogueSimEvent:OnGridItemClick()
    self._Control.MapSubControl:ExplorePropGrid(self.ItemId)
end

function XUiPanelRogueSimEvent:Refresh()
    -- 主城升级
    --local isCanLevelUp = self._Control:CheckMainLevelCanLevelUp()
    --self.GridLevelUp.gameObject:SetActiveEx(isCanLevelUp)
    self.GridLevelUp.gameObject:SetActiveEx(false)

    -- 建筑购买
    local buildingIds = self._Control.MapSubControl:GetUnBuyBuildingIds()
    self.BuildingId = #buildingIds > 0 and buildingIds[1] or nil
    self.GridBuild.gameObject:SetActiveEx(self.BuildingId ~= nil)

    -- 事件
    local eventIds = self._Control.MapSubControl:GetPendingEventIds()
    table.sort(eventIds, function(a, b)
        local isDurEventA = self._Control.MapSubControl:CheckIsEventDurationById(a) and 1 or 0
        local isDurEventB = self._Control.MapSubControl:CheckIsEventDurationById(a) and 1 or 0
        if isDurEventA ~= isDurEventB then
            return isDurEventA > isDurEventB
        end
        return a > b
    end)
    self.GridEvent.gameObject:SetActiveEx(#eventIds > 0)
    if #eventIds > 0 then
        self.EventId = eventIds[1]
        local isDurEvent = self._Control.MapSubControl:CheckIsEventDurationById(self.EventId)
        local remainDur = self._Control.MapSubControl:GetEventRemainingDuration(self.EventId)
        self.GridEventUiObj:GetObject("ImgNormalNum").gameObject:SetActiveEx(isDurEvent)
        self.GridEventUiObj:GetObject("TxtNormalNum").text = tostring(remainDur)
        self.GridEventUiObj:GetObject("ImgPressNum").gameObject:SetActiveEx(isDurEvent)
        self.GridEventUiObj:GetObject("TxtPressNum").text = tostring(remainDur)
    end

    -- 格子奖励
    local rewardDic = self._Control:GetRewardData()
    local rewardList = {}
    for _, reward in pairs(rewardDic) do
        table.insert(rewardList, reward)
    end
    local rewardCnt = #rewardList
    self.GridItem.gameObject:SetActiveEx(rewardCnt > 0)
    if rewardCnt > 0 then
        self.ItemId = rewardList[1]:GetId()
        self.GridItemUiObj:GetObject("ImgNormalNum").gameObject:SetActiveEx(rewardCnt > 1)
        self.GridItemUiObj:GetObject("TxtNormalNum").text = tostring(rewardCnt)
        self.GridItemUiObj:GetObject("ImgPressNum").gameObject:SetActiveEx(rewardCnt > 1)
        self.GridItemUiObj:GetObject("TxtPressNum").text = tostring(rewardCnt)
    end
end

return XUiPanelRogueSimEvent
