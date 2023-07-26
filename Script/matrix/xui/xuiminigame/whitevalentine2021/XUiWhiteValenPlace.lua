-- 白色情人节约会小游戏地点UI控件
local XUiWhiteValenPlace = XClass(nil, "XUiWhiteValenPlace")

function XUiWhiteValenPlace:Ctor(rootUi, ui, place)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.Place = place
    self:Refresh()
    self.BtnDispatch.CallBack = function() self:OnBtnDispatch() end
    self.BtnReward.CallBack = function() self:OnBtnReward() end
end

function XUiWhiteValenPlace:Refresh()
    if not self.Place:GetIsOpen() then self.GameObject:SetActiveEx(false) return end
    self.TxtRank.text = self.Place:GetEventRankName()
    self.AttrIcon:SetRawImage(self.Place:GetEventAttrIcon())
    self.PanelReward.gameObject:SetActiveEx(self.Place:CheckCanFinishEvent())
    self.PanelTime.gameObject:SetActiveEx(self.Place:GetIsDispatching())
    self.TxtDispatchCountDown.text = self.Place:GetEventEndTimeString()
    local dispatchingChara = self.Place:GetDispatchingChara()
    self.RImgHead.gameObject:SetActiveEx(dispatchingChara ~= nil)
    if dispatchingChara then self.RImgHead:SetRawImage(dispatchingChara:GetIconPath()) end
    if self.Place:GetIsDispatching() then self:SetDispatchingTimer() end
    self.BtnDispatch.gameObject:SetActiveEx(not self.Place:CheckCanFinishEvent())
    self.BtnReward.gameObject:SetActiveEx(self.Place:CheckCanFinishEvent())
    self.GameObject:SetActiveEx(true)
end

function XUiWhiteValenPlace:SetDispatchingTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        local checkExist
        local gameObject = self.GameObject
        if gameObject and gameObject.Exist then
            checkExist = function() return gameObject:Exist() end
        end
        if checkExist() then
            self.TxtDispatchCountDown.text = self.Place:GetEventEndTimeString()
            self.PanelTime.gameObject:SetActiveEx(self.Place:GetIsDispatching())
            if not self.Place:GetIsDispatching() then
                self:RemoveDispatchingTimer()
                self:Refresh()
            end
        else
            self:RemoveDispatchingTimer()
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiWhiteValenPlace:RemoveDispatchingTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiWhiteValenPlace:OnBtnDispatch()
    if self.Place:GetIsDispatching() then
        XLuaUiManager.Open("UiDialog",
        CS.XTextManager.GetText("WhiteValentineCancelConfirm"),
        CS.XTextManager.GetText("WhiteValentineCancelConfirmContent"),
        XUiManager.DialogType.Normal,
        nil,
        function() XDataCenter.WhiteValentineManager.CancelDispatch(self.Place) end)
    else
        XLuaUiManager.Open("UiWhitedayReady", self.Place)
    end
end

function XUiWhiteValenPlace:OnBtnReward()
    if self.Place:CheckCanFinishEvent() then
        XDataCenter.WhiteValentineManager.FinishEvent(self.Place)
    end
end

return XUiWhiteValenPlace