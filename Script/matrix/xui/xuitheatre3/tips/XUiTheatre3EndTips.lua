---@class XUiTheatre3EndTips : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3EndTips = XLuaUiManager.Register(XLuaUi, "UiTheatre3EndTips")

function XUiTheatre3EndTips:OnAwake()
    self:AddBtnListener()
end

---@param exData table 额外文本{SureText,CancelText}
function XUiTheatre3EndTips:OnStart(sureCb, title, content, closeCb, key, exData)
    self.SureCb = sureCb
    self.CloseCb = closeCb
    self.Key = key
    if title then
        self.TxtName.text = title
    end
    if content then
        self.TxtDescription.text = content
    end
    if not XTool.IsTableEmpty(exData) then
        if exData.SureText then
            self.BtnSure:SetNameByGroup(0, exData.SureText)
        end
        if exData.CancelText then
            self.BtnCancel:SetNameByGroup(0, exData.CancelText)
        end
    else
        -- 默认文本为确认
        self.BtnSure:SetNameByGroup(0, XUiHelper.GetText("BabelTowerNewRoomBtnName"))
    end
    if key then
        self.IsCheck = self._Control:GetTodayDontShowValue(self.Key)
        self.BtnCheck:SetButtonState(self.IsCheck and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
    self.BtnCheck.gameObject:SetActiveEx(key ~= nil)
end

--region Ui - BtnListener
function XUiTheatre3EndTips:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.BtnOk, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnCancel, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnSure, self.OnBtnSureClick)
    self._Control:RegisterClickEvent(self, self.BtnCheck, self.OnBtnCheckClick)
end

function XUiTheatre3EndTips:OnBtnBackClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiTheatre3EndTips:OnBtnSureClick()
    self._Control:SaveTodayDontShowValue(self.Key, not self.IsCheck) -- 勾了后 点确定才生效
    self:Close()
    if self.SureCb then
        self.SureCb()
    end
end

function XUiTheatre3EndTips:OnBtnCheckClick()
    self.IsCheck = not self.IsCheck
end
--endregion

return XUiTheatre3EndTips