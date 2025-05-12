---@class XUiGridFpsGameWeapon : XUiNode
local XUiGridFpsGameWeapon = XClass(XUiNode, "XUiGridFpsGameWeapon")

function XUiGridFpsGameWeapon:OnStart(weapon)
    self._Weapon = weapon
    self.RImgWeapon:SetRawImage(self._Weapon.Icon)

    self:SetUse(false)
    self:SetReceive(false)
    self:SetPosition(0)
    self.GridWeapon:SetButtonState(CS.UiButtonState.Normal)
end

function XUiGridFpsGameWeapon:SetPosition(pos)
    self._Pos = pos
    self.ImgBgBlue.gameObject:SetActiveEx(pos == 1)
    self.ImgBgRed.gameObject:SetActiveEx(pos == 2)
    self.ImgBgYellow.gameObject:SetActiveEx(pos == 3)
end

function XUiGridFpsGameWeapon:GetPosition()
    return self._Pos
end

function XUiGridFpsGameWeapon:SetReceive(bo)
    self.PanelReceive.gameObject:SetActiveEx(bo)
end

function XUiGridFpsGameWeapon:SetUse(bo)
    self.PanelUse.gameObject:SetActiveEx(bo)
end

function XUiGridFpsGameWeapon:RefreshCondition()
    if not XTool.IsNumberValid(self._Weapon.UnlockCondition) or XConditionManager.CheckCondition(self._Weapon.UnlockCondition) then
        self:SetLock(false)
    else
        self:SetLock(true)
    end
end

function XUiGridFpsGameWeapon:SetLock(bo)
    self.PanelLock.gameObject:SetActiveEx(bo)
    self._IsLock = bo
    if bo then
        self.GridWeapon:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiGridFpsGameWeapon:IsLock()
    return self._IsLock
end

function XUiGridFpsGameWeapon:AddClick(func)
    self.GridWeapon.CallBack = func
end

return XUiGridFpsGameWeapon