local XUiDoomsdayEvent = XLuaUiManager.Register(XLuaUi, "UidoomsdayEvent")

function XUiDoomsdayEvent:OnAwake()
    self:AutoAddListener()
end

function XUiDoomsdayEvent:OnStart(stageId, event, closeCb)
    self.StageId = stageId
    self.Event = event
    self.CloseCb = closeCb

    self:InitView()
end

function XUiDoomsdayEvent:InitView()
    local event = self.Event
    local cfgId = event:GetProperty("_CfgId")

    self.TxtReport.text = XDoomsdayConfigs.EventConfig:GetProperty(cfgId, "Name")
    self.TxtNewsInhabitant.text = XUiHelper.ReplaceTextNewLine(XDoomsdayConfigs.EventConfig:GetProperty(cfgId, "Desc"))

    local isNormalEvent = XDoomsdayConfigs.EventConfig:GetProperty(cfgId, "EventType") == XDoomsdayConfigs.EVENT_TYPE_EXPRESSION.NORMAL
    self.PanelLabel.gameObject:SetActiveEx(isNormalEvent)
    if isNormalEvent then
        self.TxtTitle.text = XDoomsdayConfigs.EventConfig:GetProperty(cfgId, "Title")
    end

    --事件选项按钮
    self.SubEventIds = event:GetSubEventIdAndConditions()
    self:RefreshTemplateGrids(
        self.GridOption,
        self.SubEventIds,
        self.PanelList,
        nil,
        "OptionGrids",
        function(grid, info)
            local btn = grid.BtnTongBlack
            local subEventId, subCondition = info.SubEventId, info.SubConditionId
            local tips = XDoomsdayConfigs.EventConfig:GetProperty(subEventId, "Desc")
            
            btn.CallBack = function()
                self:OnClickBtnOption(grid.Index)
            end
            
            local desc = XDoomsdayConfigs.EventConfig:GetProperty(subEventId, "Name")
            btn:SetNameByGroup(3, desc)
            local state = true
            if XTool.IsNumberValid(subCondition) then
                state, tips = XDoomsdayConfigs.CheckCondition(subCondition, self.StageId)
            end
            btn:SetDisable(not state, state)
            btn:SetNameByGroup(2, tips)
        end
    )
end

function XUiDoomsdayEvent:AutoAddListener()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.OnClickBtnClose)
    self.BtnClose.CallBack = handler(self, self.OnClickBtnClose)
end

function XUiDoomsdayEvent:OnClickBtnClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiDoomsdayEvent:OnClickBtnOption(index)
    local stageData = XDataCenter.DoomsdayManager.GetStageData(self.StageId)
    XDataCenter.DoomsdayManager.DoomsdayDoEventRequest(
        self.StageId,
        self.Event:GetProperty("_Id"),
        index,
        function() 
            self:OnClickBtnClose()
            stageData:DispatchBroadcast()
        end
    )
end
