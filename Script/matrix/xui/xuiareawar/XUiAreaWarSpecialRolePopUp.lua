local XUiGridAreaWarSpecialRole = require("XUi/XUiAreaWar/XUiGridAreaWarSpecialRole")

--特攻角色解锁弹窗
local XUiAreaWarSpecialRolePopUp = XLuaUiManager.Register(XLuaUi, "UiAreaWarSpecialRolePopUp")

function XUiAreaWarSpecialRolePopUp:OnAwake()
    self.BtnClose.CallBack = handler(self,self.OnClickBtnClose)

    self.GridSpecialRole.gameObject:SetActiveEx(false)
end

function XUiAreaWarSpecialRolePopUp:OnStart(roleId,closeCb)
    self.RoleId = roleId
    self.CloseCb = closeCb
    self:Refresh()
end

function XUiAreaWarSpecialRolePopUp:Refresh()
    local roleId = self.RoleId

    local buffId = XAreaWarConfigs.GetSpecialRoleBuffId(roleId)
    self.RImgIcon:SetRawImage(XAreaWarConfigs.GetBuffIcon(buffId))
    self.TxtName.text = XAreaWarConfigs.GetBuffName(buffId)
    self.TxtDesc.text = XAreaWarConfigs.GetBuffDesc(buffId)

    local isUnlock = XDataCenter.AreaWarManager.IsSpecialRoleUnlock(roleId)
    self.Txtjs.gameObject:SetActiveEx(isUnlock)
    self.Txtwjs.gameObject:SetActiveEx(not isUnlock)

    self.GridRole = self.GridRole or XUiGridAreaWarSpecialRole.New(self.GridSpecialRole)
    self.GridRole:Refresh(roleId)
    self.GridRole.GameObject:SetActiveEx(true)
end

function XUiAreaWarSpecialRolePopUp:OnClickBtnClose()
    if self.CloseCb then 
        self.CloseCb()
    end
    self:Close()
end
