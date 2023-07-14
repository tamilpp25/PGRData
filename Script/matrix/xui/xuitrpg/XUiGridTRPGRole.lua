local XUiGridTRPGRole = XClass(nil, "XUiGridTRPGRole")

function XUiGridTRPGRole:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.BtnGridRole.CallBack = function() self:OnClickBtnRole() end
end

function XUiGridTRPGRole:Refresh(roleId)
    if not roleId then
        self.BtnGridRole:ShowTag(false)
        self.BtnGridRole:SetDisable(true, false)
        return
    end

    self.BtnGridRole:ShowTag(true)
    self.BtnGridRole:SetDisable(false)

    local image = XTRPGConfigs.GetRoleHeadIcon(roleId)
    self.RImgRole1:SetRawImage(image)
    self.RImgRole2:SetRawImage(image)

    local isUp = XDataCenter.TRPGManager.IsRoleHaveBuffUp(roleId)
    self.PanelUp.gameObject:SetActiveEx(isUp)
    local isDown = XDataCenter.TRPGManager.IsRoleHaveBuffDown(roleId)
    self.PanelDown.gameObject:SetActiveEx(isDown)
end

function XUiGridTRPGRole:OnClickBtnRole()
end

return XUiGridTRPGRole