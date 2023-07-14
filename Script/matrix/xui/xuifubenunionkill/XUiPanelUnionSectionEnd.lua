local XUiPanelUnionSectionEnd = XClass(nil, "XUiPanelUnionSectionEnd")

function XUiPanelUnionSectionEnd:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self.BtnTongBlack.CallBack = function() self:OnBackClick() end
    self.BtnTongBlack:SetNameByGroup(0, CS.XTextManager.GetText("UnionSectionSureCount", 10))
end

function XUiPanelUnionSectionEnd:Refresh(sec)
    self.BtnTongBlack:SetNameByGroup(0, CS.XTextManager.GetText("UnionSectionSureCount", sec))
end

function XUiPanelUnionSectionEnd:OnBackClick()
    self.RootUi:LeaveRoomCheckFightState()
end

return XUiPanelUnionSectionEnd