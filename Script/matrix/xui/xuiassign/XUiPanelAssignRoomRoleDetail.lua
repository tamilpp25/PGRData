local XUiPanelAssignRoomRoleDetail = XClass(nil, "XUiPanelAssignRoomRoleDetail")

function XUiPanelAssignRoomRoleDetail:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

function XUiPanelAssignRoomRoleDetail:SetData(ablityRequire, order)
    self.TxtRequireAbility.text = ablityRequire and ablityRequire or ""
    self.TxtEchelonName.text = CS.XTextManager.GetText("AssignTeamTitle", order)
end

return XUiPanelAssignRoomRoleDetail