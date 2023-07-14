-- 横纵列选择按钮控件
local XUiScratchTicketPanelChose = XClass(nil, "XUiScratchTicketPanelChose")

function XUiScratchTicketPanelChose:Ctor(uiGameObject, gameController, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.Controller = gameController
    self.RootUi = rootUi
    self:InitPanel()
end

function XUiScratchTicketPanelChose:InitPanel()
    for i = 1, 8 do
        local button = self["Btn" .. i]
        if button then
            button.CallBack = function() self:OnClickChoseButton(i) end
        end
    end
end

function XUiScratchTicketPanelChose:OnClickChoseButton(index)
    self.RootUi:SelectChose(index)
end

function XUiScratchTicketPanelChose:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiScratchTicketPanelChose:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiScratchTicketPanelChose