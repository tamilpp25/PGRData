
---@class XUiPanelHandbookRole : XUiNode
---@field _Control XBlackRockChessControl
---@field BtnRole XUiComponent.XUiButton
local XUiPanelHandbookRole = XClass(XUiNode, "XUiPanelHandbookRole")

---@param handData XTableBlackRockChessHandbook
function XUiPanelHandbookRole:OnStart(handData)
    self.BtnRole.CallBack = function() 
        self:OnBtnRoleClick()
    end
    self:InitView(handData)
end

---@param handData XTableBlackRockChessHandbook
function XUiPanelHandbookRole:InitView(handData)
    local roleId = handData.Param
    self.RoleId = roleId
    self.ConditionId = handData.Condition
    local unlock, _ =self:CheckRoleUnlock()
    local weaponId = self._Control:GetRoleWeaponId(roleId)
    local skillIds = self._Control:GetWeaponSkillIds(weaponId)
    
    self.TxtName.text = self._Control:GetRoleName(roleId)
    local rectIcon = self._Control:GetRoleRectIcon(roleId)
    if not string.IsNilOrEmpty(rectIcon) then
        self.BtnRole:SetRawImage(rectIcon)
    end
    self.BtnRole:SetDisable(not unlock)

    for i, skillId in ipairs(skillIds) do
        local btn = self["BtnSkill" .. i]
        if not btn then
            goto continue
        end
        btn:SetRawImage(self._Control:GetWeaponSkillIcon(skillId))
        btn:SetButtonState((unlock and self._Control:IsSkillUnlock(skillId)) and CS.UiButtonState.Normal or CS
            .UiButtonState
                .Disable)
        btn:SetNameByGroup(0, self._Control:GetWeaponSkillCost(roleId, skillId, true))
        btn.CallBack = function() 
            self:OnBtnSkillClick(skillId, btn.transform)
        end
        ::continue::
    end
end

function XUiPanelHandbookRole:OnBtnRoleClick()
    local unlock, desc = true, ""
    if self.ConditionId and self.ConditionId > 0 then
        unlock, desc = XConditionManager.CheckCondition(self.ConditionId)
    end

    if not unlock then
        XUiManager.TipMsg(desc)
        return
    end
    
    self._Control:OpenBubblePreview(self.RoleId, self.BtnRole.transform, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.CHARACTER)
end

function XUiPanelHandbookRole:OnBtnSkillClick(skillId, transform)
    local unlock, desc = self:CheckRoleUnlock()
    if not unlock then
        XUiManager.TipMsg(desc)
        return
    end
    
    if not self._Control:IsSkillUnlock(skillId) then
        XUiManager.TipMsg(self._Control:GetWeaponSkillUnlockDesc(skillId))
        return
    end
    
    self._Control:OpenBubblePreview(skillId, transform, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON_SKILL)
end

function XUiPanelHandbookRole:CheckRoleUnlock()
    local unlock, desc = true, ""
    if self.ConditionId and self.ConditionId > 0 then
        unlock, desc = XConditionManager.CheckCondition(self.ConditionId)
    end
    
    return unlock, desc
end

return XUiPanelHandbookRole