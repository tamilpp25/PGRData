
---@class XUiPanelBattleSkill : XUiNode
---@field _Control XBlackRockChessControl
---@field Parent XUiBlackRockChessBattle
local XUiPanelBattleSkill = XClass(XUiNode, "XUiPanelBattleSkill")

function XUiPanelBattleSkill:OnStart(roleId)
    self.RoleId = roleId
    self:InitView()
end

function XUiPanelBattleSkill:OnEnable()
    self:RefreshView()
end

function XUiPanelBattleSkill:OnDisable()
    self:ResetSelect()
end

function XUiPanelBattleSkill:OnDestroy()
    
end

function XUiPanelBattleSkill:InitView()
    self.LastSelectIndex = -1
    self.SelectIndex = -1
    local actor = self._Control:GetChessGamer():GetRole(self.RoleId)
    local skillIds = self._Control:GetWeaponSkillIds(actor:GetWeaponId())
    self.SkillIds = skillIds
    for i = 1, #skillIds do
        --local pointer = self:TryGetComponent(self["BtnSkill" .. i], componentType)
        local btn = self["BtnSkill" .. i]
        btn.CallBack = function()
            self:OnBtnClick(i)
        end
        local skillId = skillIds[i]
        self:InitBtnSkill(btn, skillId)
        local btnPc = self.Transform:FindTransform("BtnSkill" .. i .. "PC")
        if btnPc then
            if XDataCenter.UiPcManager.IsPc() then
                self.Parent:SetPcKeyCover(btnPc, "ALPHA"..i)
            else
                btnPc.gameObject:SetActiveEx(false)
            end
        end
        
        local effect = btn.transform:GetComponentInChildren(typeof(CS.XUiEffectLayer))
        --if not effect then
        --    effect = btn.transform:FindTransform("PanelEffect1")
        --end
        
        if effect then
            self["Effect"..skillId] =  effect
        end
        
        local panelCd = btn.transform:FindTransform("PanelCd")
        if panelCd then
            self["PanelCd" .. skillId] = panelCd
        end
    end
    self.RImgHead:SetRawImage(self._Control:GetRoleCircleIcon(self.RoleId))
end

function XUiPanelBattleSkill:InitBtnSkill(btn, skillId)
    local unlock = self._Control:IsSkillUnlock(skillId)
    btn:SetDisable(not unlock, unlock)
    btn:SetRawImage(self._Control:GetWeaponSkillIcon(skillId))
end

function XUiPanelBattleSkill:TryGetComponent(component, componentType)
    if not component then
        return
    end
    local c = component.gameObject:GetComponent(componentType)
    if not c then
        c = component.gameObject:AddComponent(componentType)
    end
    return c
end

function XUiPanelBattleSkill:RefreshView()
    local skillIds = self.SkillIds
    for i = 1, #skillIds do
        local btn = self["BtnSkill" .. i]
        local skillId = skillIds[i]
        local cost = self._Control:GetWeaponSkillCost(self.RoleId, skillId)
        btn:SetNameByGroup(1, cost)
        local cd = self._Control:GetWeaponSkillCd(self.RoleId, skillId)
        local panelCd = self["PanelCd" .. skillId]
        if panelCd then
            panelCd.gameObject:SetActiveEx(cd > 0)
            btn:SetNameByGroup(0, cd)
        end
    end
    
    self:ShowButtonEffect()
end

function XUiPanelBattleSkill:IsOperate()
    return (self._Control:IsEnterMove() or self._Control:IsEnterSkill()) and self._Control:IsOperate()
end

function XUiPanelBattleSkill:OnBtnClick(selectIndex)
    if self.SelectIndex == selectIndex then
        return
    end
    --拦截操作
    if not self:IsOperate() then
        return
    end
    local actor = self._Control:GetChessGamer():GetRole(self.RoleId)
    if not actor then
        return
    end
    if self._Control:IsGamerMoving() then
        actor:ShowBubbleText(self._Control:GetIsMovingText(1))
        return
    end
    local curWeaponId = self._Control:GetCurrentWeaponId()
    local skillIds = self._Control:GetWeaponSkillIds(curWeaponId)
    if selectIndex > #skillIds then
        return
    end
    local skillId = skillIds[selectIndex]
    
    local skill = actor:TryGetSkill(skillId)
    --技能未解锁
    if not skill:IsUnlock() then
        actor:ShowBubbleText(self._Control:GetSkillLockText(1))
        self.Parent:ChangeState(true, true)
        return
    end
    --不能使用技能
    if not skill:IsEnoughEnergy() then
        actor:ShowBubbleText(self._Control:GetEnergyNotEnoughText(1))
        self.Parent:ChangeState(true, true)
        return
    end

    --不能使用技能
    if not skill:IsCountDown() then
        actor:ShowBubbleText(self._Control:GetEnergyNotEnoughText(2))
        self.Parent:ChangeState(true, true)
        return
    end

    if skill:IsDisableSkill() then
        actor:ShowBubbleText(self._Control:GetEnergyNotEnoughText(3))
        self.Parent:ChangeState(true, true)
        return
    end

    if self.LastSelectIndex > 0 then
        self:SetButtonState(self["BtnSkill"..self.LastSelectIndex], CS.UiButtonState.Normal)
    end
    self.SelectIndex = selectIndex
    self.LastSelectIndex = self.SelectIndex
    self:SetButtonState(self["BtnSkill"..self.SelectIndex], CS.UiButtonState.Select)
    self.Parent:ChangeState(false, false)
    self.Parent:ShowBubbleSkill(self.RoleId, skillId, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON_SKILL)
    self.PanelHead.gameObject:SetActiveEx(false)
end

function XUiPanelBattleSkill:ResetSelect()
    if XTool.IsNumberValid(self.SelectIndex) and self.SelectIndex > 0 then
        self:SetButtonState(self["BtnSkill"..self.SelectIndex], CS.UiButtonState.Normal)
    end

    if XTool.IsNumberValid(self.LastSelectIndex) and self.LastSelectIndex > 0 then
        self:SetButtonState(self["BtnSkill"..self.LastSelectIndex], CS.UiButtonState.Normal)
    end
    self.SelectIndex = -1
    self.LastSelectIndex = -1
    self.PanelHead.gameObject:SetActiveEx(true)
end

function XUiPanelBattleSkill:GetSelectIndex()
    return self.SelectIndex
end

function XUiPanelBattleSkill:GetSelectSkillId()
    if self.SelectIndex <= 0 then
        return 0
    end
    local skillIds = self.SkillIds
    local skillId = skillIds[self:GetSelectIndex()]
    
    return skillId
end

function XUiPanelBattleSkill:OnBubbleClose()
    self.ShowBubbleIndex = nil
end

function XUiPanelBattleSkill:GetSkillCost()
    local skillId = self:GetSelectSkillId()
    if skillId <= 0 then
        return 0
    end
    return self._Control:GetWeaponSkillCost(self.RoleId, skillId)
end

--- 
---@param btn XUiComponent.XUiButton
--------------------------
function XUiPanelBattleSkill:SetButtonState(btn, state)
    if not btn then
        return
    end
    btn:SetButtonState(state)
    if state == CS.UiButtonState.Select then
        btn.enabled = false
    else
        btn.enabled = true
    end 
end

function XUiPanelBattleSkill:ShowButtonEffect()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    local skillIds = self.SkillIds
    for _, skillId in pairs(skillIds) do
        local effect = self["Effect" .. skillId]
        if effect then
            effect.gameObject:SetActiveEx(self._Control:CouldUseSkill(self.RoleId, skillId))
        end
    end
end

return XUiPanelBattleSkill