---@class XUiDlcMultiPlayerSkillDescGrid : XLuaUi
---@field BtnBuffIcon XUiComponent.XUiButton
---@field TxtCondition UnityEngine.UI.Text
---@field SelectObject UnityEngine.RectTransform
local XUiDlcMultiPlayerSkillDescGrid = XClass(XUiNode, "XUiDlcMultiPlayerSkillDescGrid")

function XUiDlcMultiPlayerSkillDescGrid:Refresh(skillId, unlockCallback)
    self._SkillId = skillId
    self._UnlockCallback = unlockCallback
    self._SkillConfig = self._Control:GetDlcMultiplayerSkillConfigById(skillId)

    self.BtnBuffIcon:SetName(self._SkillConfig.Name)
    self.BtnBuffIcon:SetRawImage(self._SkillConfig.Icon)
    self.TxtCondition.text = XUiHelper.GetText("NotUnlock")
    if self._Control:CheckSkillUnlock(skillId) then
        XUiHelper.RegisterClickEvent(self, self.BtnBuffIcon, self.OnBtnBuffIconUnlockClick)
        self:UnSelect()
    else
        XUiHelper.RegisterClickEvent(self, self.BtnBuffIcon, self.OnBtnBuffIconLockClick)
        self:Lock()
    end

    self.BtnBuffIcon:ShowReddot(self._Control:CheckNewSkillRedPoint(skillId))
end

function XUiDlcMultiPlayerSkillDescGrid:Select()
    self.BtnBuffIcon:SetButtonState(CS.UiButtonState.Normal)
    self.SelectObject.gameObject:SetActiveEx(true)
end

function XUiDlcMultiPlayerSkillDescGrid:UnSelect()
    self.BtnBuffIcon:SetButtonState(CS.UiButtonState.Normal)
    self.SelectObject.gameObject:SetActiveEx(false)
end

function XUiDlcMultiPlayerSkillDescGrid:Lock()
    self.BtnBuffIcon:SetButtonState(CS.UiButtonState.Disable)
    self.SelectObject.gameObject:SetActiveEx(false)
end

function XUiDlcMultiPlayerSkillDescGrid:OnBtnBuffIconLockClick()
    XUiManager.TipMsg(XConditionManager.GetConditionDescById(self._SkillConfig.Condition))
end

function XUiDlcMultiPlayerSkillDescGrid:OnBtnBuffIconUnlockClick()
    self._Control:RemoveNewSkill(self._SkillId)
    if self._UnlockCallback then
        self._UnlockCallback(self)
    end
end

function XUiDlcMultiPlayerSkillDescGrid:GetSkillConfig()
    return self._SkillConfig
end

return XUiDlcMultiPlayerSkillDescGrid