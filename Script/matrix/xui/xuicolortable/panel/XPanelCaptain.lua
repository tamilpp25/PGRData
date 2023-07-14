-- 队长详情
local XPanelCaptain = XClass(nil, "XPanelCaptain")

function XPanelCaptain:Ctor(root, ui, captainId, skillClickCB)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    self.CaptainId = captainId
    self.SkillClickCB = skillClickCB

    self:_InitUiObject()
    self:_AddBtnListener()
end

function XPanelCaptain:Refresh(data, cb)
    self:RefreshRound(data.CurRoundId)
    self:RefreshActionPoint(data.CurActionPoint)
    self:RefreshNewRound(data.CurRoundId, cb)
end

function XPanelCaptain:RefreshRound(value)
    self.TxtRound.text = XUiHelper.GetText("ColorTableRoundTxt", value)
end

function XPanelCaptain:RefreshActionPoint(value)
    self.TxtActionPoint.text = value
end

function XPanelCaptain:RefreshNewRound(round, cb)
    self.PanelBegin.gameObject:SetActiveEx(true)
    self.TxtBegin.text = XUiHelper.GetText("ColorTableNewRoundTxt", round)
    self.PanelBeginEnable:PlayTimelineAnimation(function ()
        self.PanelBegin.gameObject:SetActiveEx(false)
        if cb then cb() end
    end)
end

function XPanelCaptain:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_NEWROUND, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_ACTIONPOINTCHANGE, self.RefreshActionPoint, self)
end

function XPanelCaptain:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_NEWROUND, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_COLOR_TABLE_ACTION_ACTIONPOINTCHANGE, self.RefreshActionPoint, self)
end

-- private
---------------------------------------------------------------------

function XPanelCaptain:_InitUiObject()
    XTool.InitUiObject(self)
    self.PanelBegin = self.Root.Transform:Find("SafeAreaContentPane/PanelMain/PanelBegin")
    self.PanelBeginEnable = self.Root.Transform:Find("SafeAreaContentPane/PanelMain/PanelBegin/PanelBeginEnable")
    self.TxtBegin = self.PanelBegin.transform:Find("TxtBegin"):GetComponent("Text")
    self.RImgHead:SetRawImage(XColorTableConfigs.GetCaptainFaceIcon(self.CaptainId))
    self.RImgIcon:SetRawImage(XColorTableConfigs.GetCaptainSkillIcon(self.CaptainId))
    self.TxtName.text = XColorTableConfigs.GetCaptainName(self.CaptainId)
end

function XPanelCaptain:_AddBtnListener()
    if self.Btn then
        XUiHelper.RegisterClickEvent(self, self.Btn, self._OnBtnBuffClick)
    end
end

function XPanelCaptain:_OnBtnBuffClick()
    if self.SkillClickCB then
        self.SkillClickCB()
    end
end

---------------------------------------------------------------------

return XPanelCaptain