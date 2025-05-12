local XUiGridTalent = XClass(nil, "XUiGridTalent")

function XUiGridTalent:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridTalent:Refresh(characterId, talentCfg)
    local isEquip = XMVCA.XBossInshot:IsCharacterTalentSelect(characterId, talentCfg.Id)
    local isUnlock, tips = XMVCA.XBossInshot:IsCharacterTalentUnlock(characterId, talentCfg.Id)
    self.RImgIcon:SetRawImage(talentCfg.Icon)
    self.TxtName.text = isUnlock and talentCfg.Name or ""
    self.TxtDesc.text = talentCfg.Desc
    self.ImgEquip.gameObject:SetActiveEx(isEquip)
    self.ImgLock.gameObject:SetActiveEx(not isUnlock)
    self.TxtUnlockTips.text = tips
    self.TxtUnlockTips.gameObject:SetActiveEx(not isUnlock)
end

function XUiGridTalent:SetSelected(status)
    self.ImgSelect.gameObject:SetActiveEx(status)
end

function XUiGridTalent:IsSelected()
    return self.ImgSelect.gameObject.activeSelf
end


return XUiGridTalent