local XUiGridMechanismBuff = XClass(XUiNode, 'XUiGridMechanismBuff')


function XUiGridMechanismBuff:Refresh(characterIndex, buffIndex, ignoreReddot)
    ---@type XTableMechanismCharacter
    local characterCfg = self._Control:GetMechanismCharacterCfgByIndex(characterIndex)

    self.RImgBuff:SetRawImage(characterCfg.BuffIcons[buffIndex])
    self._UnLock = true
    
    local defaultOpenBuffCondition = self._Control:GetMechanismClientConfigNum('DefaultBuffCondition') or 0
    -- 判断buff是否默认开启
    if characterCfg.BuffConditions[buffIndex] ~= defaultOpenBuffCondition then
        self._UnLock = XConditionManager.CheckCondition(characterCfg.BuffConditions[buffIndex])
    else
        if not self._Control:CheckBuffIsOld(characterIndex, buffIndex) then
            self._Control:SetBuffToOld(characterIndex, buffIndex)
        end
    end

    self.PanelLock.gameObject:SetActiveEx(not self._UnLock)

    if self.Red then
        self.Red.gameObject:SetActiveEx(self._UnLock and not self._Control:CheckBuffIsOld(characterIndex, buffIndex) and not ignoreReddot)
    end

    if self.TxtDetail then
        self.TxtDetail.gameObject:SetActiveEx(true)
        self.TxtDetail.text = characterCfg.BuffDesc[buffIndex]
    end

    if self.TxtLockTips then
        self.TxtLockTips.gameObject:SetActiveEx(not self._UnLock)
        if not self._UnLock then
            self.TxtLockTips.text = XConditionManager.GetConditionDescById(characterCfg.BuffConditions[buffIndex])
        end
    end

    if self.TxtName then
        self.TxtName.text = characterCfg.BuffNames[buffIndex]
    end
end

return XUiGridMechanismBuff