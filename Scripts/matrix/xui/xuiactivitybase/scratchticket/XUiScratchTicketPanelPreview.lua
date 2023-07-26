---@class XUiScratchTicketPanelPreview
local XUiScratchTicketPanelPreview = XClass(nil, "XUiScratchTicketPanelPreview")

function XUiScratchTicketPanelPreview:Ctor(uiGameObject, gameController, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.Controller = gameController
    self.RootUi = rootUi
    self:InitPanel()
end

function XUiScratchTicketPanelPreview:InitPanel()
    self:Refresh()
end

function XUiScratchTicketPanelPreview:Refresh()
    if not self.RootUi.Ticket then return end
    self.TxtCount.text = self.RootUi.Ticket:GetOpenGridNum()
    self.TxtMaxCount.text = "/" .. self.Controller:GetPreviewCount()
end

function XUiScratchTicketPanelPreview:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiScratchTicketPanelPreview:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiScratchTicketPanelPreview