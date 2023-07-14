local XUiPanelThemeSelect = XClass(nil, "XUiPanelThemeSelect")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelThemeSelect:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
end

function XUiPanelThemeSelect:UpdatePanel()
    self:UpdateInfo()
end

function XUiPanelThemeSelect:UpdateInfo()
    self.TxtName.text = XDataCenter.SuperTowerManager.GetActivityName()
end

function XUiPanelThemeSelect:UpdateTime(time)
    self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiPanelThemeSelect:ShowPanel(IsShow)
    self.GameObject:SetActiveEx(IsShow)
end

return XUiPanelThemeSelect