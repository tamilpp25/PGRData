local XUiRpgMakerGameCharacterGrid = XClass(nil, "XUiRpgMakerGameCharacterGrid")

function XUiRpgMakerGameCharacterGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiRpgMakerGameCharacterGrid:Refresh(characterId)
    local isUnlock = XDataCenter.RpgMakerGameManager.IsUnlockRole(characterId)
    self.ImgLock.gameObject:SetActiveEx(not isUnlock)

    local headPath = isUnlock and XRpgMakerGameConfigs.GetRpgMakerGameRoleHeadPath(characterId) or CS.XGame.ClientConfig:GetString("RpgMakerGameRoleUnLockHeadPath")
    self.RImgHeadIcon:SetRawImage(headPath)

    local name = XRpgMakerGameConfigs.GetRpgMakerGameRoleName(characterId)
    self.TextName1.text = isUnlock and name or ""

    local style = XRpgMakerGameConfigs.GetRpgMakerGameRoleStyle(characterId)
    self.TextName2.text = isUnlock and style or ""

    self.ImgRedPoint.gameObject:SetActiveEx(false)
end

function XUiRpgMakerGameCharacterGrid:SetSelect(isSelect)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(isSelect)
    end
end

return XUiRpgMakerGameCharacterGrid