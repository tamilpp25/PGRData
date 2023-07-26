local XUiSuperSmashBrosRoleSelectionGrid = XClass(nil, "XUiSuperSmashBrosRoleSelectionGrid")

function XUiSuperSmashBrosRoleSelectionGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self._Role = false
end

---@param role XSmashBCharacter
function XUiSuperSmashBrosRoleSelectionGrid:Refresh(role)
    self._Role = role
    self.RImgHeadIcon:SetRawImage(role:GetSmallHeadIcon())
    self.TxtAbility.text = role:GetAbility()
    self.TxtName.text = role:GetName()
    self.ImgDemo.gameObject:SetActiveEx(role:GetIsRobot())
end

function XUiSuperSmashBrosRoleSelectionGrid:UpdateSelected(roleSelected)
    self:UpdateFighting(roleSelected)
    if self._Role == roleSelected then
        self.ImgSelected.gameObject:SetActiveEx(true)
        return
    end
    self.ImgSelected.gameObject:SetActiveEx(false)
end

function XUiSuperSmashBrosRoleSelectionGrid:UpdateFighting(roleFighting)
    if self._Role == roleFighting then
        self.ImgBg.gameObject:SetActiveEx(true)
        return
    end
    self.ImgBg.gameObject:SetActiveEx(false)
end

return XUiSuperSmashBrosRoleSelectionGrid