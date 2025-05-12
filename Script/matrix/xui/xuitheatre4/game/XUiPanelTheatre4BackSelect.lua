---@class XUiPanelTheatre4BackSelect : XUiNode
---@field private _Control XTheatre4Control
local XUiPanelTheatre4BackSelect = XClass(XUiNode, "XUiPanelTheatre4BackSelect")

function XUiPanelTheatre4BackSelect:OnStart()
    self._Control:RegisterClickEvent(self, self.BtnBackSelect, self.OnBtnBackSelectClick)
end

function XUiPanelTheatre4BackSelect:Refresh(enterType)
    self.EnterType = enterType
    local enterName = self._Control:GetClientConfig("EntryViewMapPopupName", enterType) or ""
    local content = self._Control:GetClientConfig("ViewMapTipContent") or ""
    self.TxtDesc.text = XUiHelper.FormatText(content, enterName)
    self._Control:StartViewMap(enterType)
end

function XUiPanelTheatre4BackSelect:OnBtnBackSelectClick()
    self._Control:EndViewMap()
    self:Close()
end

return XUiPanelTheatre4BackSelect
