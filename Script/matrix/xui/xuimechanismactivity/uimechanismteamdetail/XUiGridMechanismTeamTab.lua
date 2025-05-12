---@class XUiGridMechanismTeamTab
---@field _Control XMechanismActivityControl
---@field Parent XUiMechanismTeamDetail
local XUiGridMechanismTeamTab = XClass(XUiNode, 'XUiGridMechanismTeamTab')

function XUiGridMechanismTeamTab:OnStart(index)
    self._Index = index;
end

---@param cfg XTableMechanismCharacter
function XUiGridMechanismTeamTab:Refresh(cfg)
    self._MechanismCharaIndex = cfg.Id
    self.Btn:SetRawImage(XMVCA.XCharacter:GetCharBigHeadIcon(cfg.CharacterId))
    self.Btn:ShowReddot(self._Control:CheckCharacterHasNewBuff(self._MechanismCharaIndex))
end

function XUiGridMechanismTeamTab:SetSelection(isSelect)
    if isSelect then
        self._IsSelect = true
        self.Btn:SetButtonState(CS.UiButtonState.Select)
    else
        -- 如果是上一次点击选中
        if self._IsSelect then
            self._IsSelect = false
            self._Control:SetCharacterBuffsToOld(self._MechanismCharaIndex)
        end
        self.Btn:SetButtonState(CS.UiButtonState.Normal)
    end
    self.Btn:ShowReddot(self._Control:CheckCharacterHasNewBuff(self._MechanismCharaIndex))
end

function XUiGridMechanismTeamTab:GetMechanismCharacterId()
    return self._MechanismCharaIndex
end

return XUiGridMechanismTeamTab