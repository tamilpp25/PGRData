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

    self.TxtTitle.text = XDoomsdayConfigs.EventConfig:GetProperty(cfgId, "Name")
    self.TxtEvent.text = XDoomsdayConfigs.EventConfig:GetProperty(cfgId, "Desc")

    --事件选项按钮
    self.SubEventIds = event:GetSubEventIds()
    self:RefreshTemplateGrids(
        self.GridOption,
        self.SubEventIds,
        self.PanelList,
        nil,
        "OptionGrids",
        function(grid, subEventId)
            local btn = grid.BtnTongBlack
            btn:SetNameByGroup(0, XDoomsdayConfigs.EventConfig:GetProperty(subEventId, "Name"))
            btn.CallBack = function()
                self:OnClickBtnOption(grid.Index)
            end

            local desc = XDoomsdayConfigs.EventConfig:GetProperty(subEventId, "Desc")
            grid.TxtOption.text = desc
            grid.Transform:FindTransform("Image").gameObject:SetActiveEx(not string.IsNilOrEmpty(desc))
        end
    )
end

function XUiDoomsdayEvent:AutoAddListener()
    self.BtnTanchuangClose.CallBack = handler(self, self.OnClickBtnClose)
end

function XUiDoomsdayEvent:OnClickBtnClose()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiDoomsdayEvent:OnClickBtnOption(index)
    XDataCenter.DoomsdayManager.DoomsdayDoEventRequest(
        self.StageId,
        self.Event:GetProperty("_Id"),
        index,
        handler(self, self.OnClickBtnClose)
    )
end
