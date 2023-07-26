local XUiGridPokemonMonsterSelectSkill = XClass(nil, "XUiGridPokemonMonsterSelectSkill")

function XUiGridPokemonMonsterSelectSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.UiButton.CallBack = function() self:OnClickBtn() end
end

function XUiGridPokemonMonsterSelectSkill:Refresh(monsterId, skillId, clickCb)
    self.ClickCb = clickCb

    local uiButton = self.UiButton

    local icon = XPokemonConfigs.GetMonsterSkillIcon(skillId)
    uiButton:SetRawImage(icon)

    local name = XPokemonConfigs.GetMonsterSkillName(skillId)
    uiButton:SetNameByGroup(0, name)

    local desc = XPokemonConfigs.GetMonsterSkillDescription(skillId)
    uiButton:SetNameByGroup(1, desc)

    local isDisable = not XDataCenter.PokemonManager.IsMonsterSkillUnlock(monsterId, skillId)
    uiButton:SetDisable(isDisable)
    self._IsDisable = isDisable

    local isSelect = XDataCenter.PokemonManager.IsMonsterSkillUsing(monsterId, skillId)
    self:SetSelect(isSelect)
end

function XUiGridPokemonMonsterSelectSkill:OnClickBtn()
    if self._IsSelect then return end
    if self._IsDisable then
        XUiManager.TipText("PokemonMonsterSwitchSkillUnlock")
        return
    end

    self.ClickCb()
end

function XUiGridPokemonMonsterSelectSkill:SetSelect(value)
    if self._IsDisable then return end
    self._IsSelect = value
    self.UiButton.enabled = not value
    self.UiButton:SetButtonState(value and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

return XUiGridPokemonMonsterSelectSkill