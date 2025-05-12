local XUiGuildWarReinforceDetailEvent = require("XUi/XUiGuildWar/Node/XUiGuildWarReinforceDetailEvent")

---显示各种状态、buff等
---@class XUiPanelReinforce
---@field _Entity XGWReinforcements
local XUiPanelReinforce = XClass(XUiNode, "XUiPanelReinforce")

local ReinforcementsState = {
    Ready = 1, -- 准备状态
    Rush = 2, -- 进攻状态
}

function XUiPanelReinforce:OnStart()
    self._Entity = false
    self.PanelUiDetail01 = {}
    XTool.InitUiObjectByUi(self.PanelUiDetail01, self.PanelDetail01)

    ---@type XUiGuildWarStageDetailEvent[]
    self._UiEvent = {}
    self.PanelBuf.gameObject:SetActiveEx(false)
    self._State = 0
end

function XUiPanelReinforce:OnEnable()
    self:InitShow()
end

function XUiPanelReinforce:OnDisable()
    self:StopTimer()
end

--region 进攻倒计时相关
function XUiPanelReinforce:StartTimer()
    self:StopTimer()
    self:RefreshTime()
    self._TimeId = XScheduleManager.ScheduleForever(handler(self, self.RefreshTime), XScheduleManager.SECOND)
end

function XUiPanelReinforce:StopTimer()
    if self._TimeId then
        XScheduleManager.UnSchedule(self._TimeId)
        self._TimeId = nil
    end
end
    
function XUiPanelReinforce:RefreshTime()
    local nextTimeFormat = XGuildWarConfig.GetClientConfigValues('ReinforcementsRushNextTime')[1]

    local nowTime = XTime.GetServerNowTimestamp()
    local readyTime = self._Entity and self._Entity:GetReadyTime() or 0

    if XTool.IsNumberValid(readyTime) and nowTime < readyTime then
        if self._State ~= ReinforcementsState.Ready then
            self._State = ReinforcementsState.Ready
            self.TxtExplainTitle.text = XGuildWarConfig.GetClientConfigValues('ReinforcementsRushStateDesc')[1]
        end
        
        local leftTime = math.max(0, readyTime - nowTime)

        self.TxtTime.text = XUiHelper.FormatText(nextTimeFormat,XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND))
    else
        if self._State ~= ReinforcementsState.Rush then
            self._State = ReinforcementsState.Rush
            self.TxtExplainTitle.text = XGuildWarConfig.GetClientConfigValues('ReinforcementsRushStateDesc')[2]
        end
        local nextTime = self._Entity and self._Entity:GetNextMoveTime() or 0
        local leftTime = math.max(0, nextTime - nowTime)

        self.TxtTime.text = XUiHelper.FormatText(nextTimeFormat,XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND))
    end
end

--endregion

function XUiPanelReinforce:InitShow()
    self.TxtAreaDetails.text = XGuildWarConfig.GetClientConfigValues('ReinforcementsRushDesc')[1]

end

---@param node XGWReinforcements
function XUiPanelReinforce:SetData(entity)
    self._Entity = entity

    local eventIds = self._Entity:GetShowFightEvents()
    
    local eventDetails = self:GetAllFightEventDetailConfig(eventIds)
    for i = 1, #eventDetails do
        local uiEvent = self._UiEvent[i]
        if not uiEvent then
            local ui = XUiHelper.Instantiate(self.PanelBuf.gameObject, self.PanelBuf.transform.parent.transform)
            uiEvent = XUiGuildWarReinforceDetailEvent.New(ui)
            uiEvent:SetEntity(self._Entity)
            self._UiEvent[i] = uiEvent
        end
        local event = eventDetails[i]
        uiEvent:Update(event)
        uiEvent.GameObject:SetActiveEx(true)
    end
    for i = #eventDetails + 1, #self._UiEvent do
        local uiEvent = self._UiEvent[i]
        uiEvent.GameObject:SetActiveEx(false)
    end

    self:StartTimer()

end

function XUiPanelReinforce:RefreshBuffShow()
    for i, v in ipairs(self._UiEvent) do
        if v.GameObject.activeSelf and v.RefreshShow then
            v:RefreshShow()
        end
    end
end

function XUiPanelReinforce:GetAllFightEventDetailConfig(eventIds)
    local result = {}
    
    if not XTool.IsTableEmpty(eventIds) then
        for i, id in ipairs(eventIds) do
            local detail = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(id)
            table.insert(result, detail)
        end
    end
    
    return result
end

return XUiPanelReinforce
