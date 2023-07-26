local MaxHintCount = 3

local XUiRpgMakerGamePanelLoseTip = XClass(nil, "XUiRpgMakerGamePanelLoseTip")

function XUiRpgMakerGamePanelLoseTip:Ctor(ui, tipOutCb, tipResetCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.TipOutCb = tipOutCb
    self.TipResetCb = tipResetCb

    XUiHelper.RegisterClickEvent(self, self.BtnTipOut, self.OnBtnTipOutClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTipReset, self.OnBtnTipResetClick)
end

function XUiRpgMakerGamePanelLoseTip:Show(stageId, actionType)
    self:RefreshTxt(stageId)
    self:RefreshTitle(actionType)
    self.GameObject:SetActiveEx(true)
end

function XUiRpgMakerGamePanelLoseTip:RefreshTitle(actionType)
    local title = XRpgMakerGameConfigs.GetRpgMakerGameDeathTitle(actionType)
    self.TextTitle.text = title
end

function XUiRpgMakerGamePanelLoseTip:RefreshTxt(stageId)
    local loseHintList = XRpgMakerGameConfigs.GetRpgMakerGameStageLoseHintList(stageId)
    for i, desc in ipairs(loseHintList or {}) do
        if self["TextHint" .. i] then
            self["TextHint" .. i].text = desc
        end
    end

    for i = #loseHintList + 1, MaxHintCount do
        if self["TextHint" .. i] then
            self["TextHint" .. i].text = ""
        end
    end
end

function XUiRpgMakerGamePanelLoseTip:Hide()
    self.GameObject:SetActiveEx(false)
end

--回到活动主界面
function XUiRpgMakerGamePanelLoseTip:OnBtnTipOutClick()
    if self.TipOutCb then
        self:Hide()
        self.TipOutCb()
    end
end

--重置当前关卡
function XUiRpgMakerGamePanelLoseTip:OnBtnTipResetClick()
    if self.TipResetCb and self.TipResetCb() then
        self:Hide()
    end
end

return XUiRpgMakerGamePanelLoseTip