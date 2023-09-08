
---@class XUiPanelBattleSkill : XUiNode
---@field _Control XBlackRockChessControl
---@field Parent XUiBlackRockChessBattle
local XUiPanelBattleSkill = XClass(XUiNode, "XUiPanelBattleSkill")

local MAX_SKILL_COUNT = 3 --最大技能数量

function XUiPanelBattleSkill:OnStart(weaponId)
    self.WeaponId = weaponId
    self.LongClicker = {}
    self:InitView()
end

function XUiPanelBattleSkill:OnEnable()
    self:RefreshView()
end

function XUiPanelBattleSkill:OnDisable()
    self:ResetSelect()
end

function XUiPanelBattleSkill:OnDestroy()
    for _, clicker in pairs(self.LongClicker) do
        clicker:Destroy()
    end
    self.LongClicker = nil
end

function XUiPanelBattleSkill:InitView()
    self.LastSelectIndex = -1
    self.SelectIndex = -1
    --local componentType = typeof(CS.XUiPointer)
    local skillIds = self._Control:GetWeaponSkillIds(self.WeaponId)
    for i = 1, MAX_SKILL_COUNT do
        --local pointer = self:TryGetComponent(self["BtnSkill" .. i], componentType)
        self["BtnSkill" .. i].CallBack = function()
            self:OnBtnClick(i)
        end
        local btnPc = self.Transform:FindTransform("BtnSkill" .. i .. "PC")
        if btnPc then
            if XDataCenter.UiPcManager.IsPc() then
                self.Parent:SetPcKeyCover(btnPc, "ALPHA"..i)
            else
                btnPc.gameObject:SetActiveEx(false)
            end
        end
        
        local effect = self["BtnSkill" .. i].transform:FindTransform("PanelEffect")
        if not effect then
            effect = self["BtnSkill" .. i].transform:FindTransform("PanelEffect1")
        end

        if effect then
            self["Effect"..skillIds[i]] =  effect
        end
        
        --local clicker = XUiButtonLongClick.New(pointer, self._Control:GetLongPressTimer(), self, nil, function()
        --    self:OnBtnLongClick(i)
        --end)
        --
        --table.insert(self.LongClicker, clicker)
    end
    
    
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
    local skillIds = self._Control:GetWeaponSkillIds(self.WeaponId)
    for i = 1, MAX_SKILL_COUNT do
        local btn = self["BtnSkill" .. i]
        local skillId = skillIds[i]
        local unlock = self._Control:IsSkillUnlock(skillId)
        btn:SetDisable(not unlock, unlock)
        btn:SetRawImage(self._Control:GetWeaponSkillIcon(skillId))
        local cost = self._Control:GetWeaponSkillCost(skillId)
        btn:SetNameByGroup(0, cost)
    end
    
    self:ShowButtonEffect(self._Control:GetChessGamer():IsUsePassiveSkill())
end

function XUiPanelBattleSkill:OnBtnClick(selectIndex)
    if self.SelectIndex == selectIndex then
return
    end
    --拦截操作
    if self._Control:IsWaiting() then
        return
    end
    if self._Control:IsGamerMoving() then
        self._Control:GetChessGamer():ShowDialog(self._Control:GetIsMovingText(1))
        return
    end
    local curWeaponId = self._Control:GetCurrentWeaponId()
    local skillIds = self._Control:GetWeaponSkillIds(curWeaponId)
    local skillId = skillIds[selectIndex]
    --技能未解锁
    if not self._Control:IsSkillUnlock(skillId) then
        self._Control:GetChessGamer():ShowDialog(self._Control:GetSkillLockText(1))
        self.Parent:ChangeState(true, true)
        return
    end
    --不能使用技能
    if not self._Control:CouldUseSkill(skillId) then
        self._Control:GetChessGamer():ShowDialog(self._Control:GetEnergyNotEnoughText(1))
        self.Parent:ChangeState(true, true)
        return
    end

    if self.LastSelectIndex > 0 then
        self:SetButtonState(self["BtnSkill"..self.LastSelectIndex], CS.UiButtonState.Normal)
    end
    self.SelectIndex = selectIndex
    self.LastSelectIndex = self.SelectIndex
    self:SetButtonState(self["BtnSkill"..self.SelectIndex], CS.UiButtonState.Select)
    self.Parent:ChangeState(false, false)self.Parent:ShowBubbleSkill(skillId, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON_SKILL)
end

function XUiPanelBattleSkill:OnBtnLongClick(selectIndex)
    if self.ShowBubbleIndex == selectIndex then
        return
    end
    self.ShowBubbleIndex = selectIndex
    local skillIds = self._Control:GetWeaponSkillIds(self.WeaponId)
    XLuaUiManager.Open("UiBlackRockChessBubbleSkill", skillIds[selectIndex], self["BtnSkill"..selectIndex], XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON_SKILL)
end

function XUiPanelBattleSkill:ResetSelect()
    if self.SelectIndex > 0 then
        self:SetButtonState(self["BtnSkill"..self.SelectIndex], CS.UiButtonState.Normal)
    end

    if self.LastSelectIndex > 0 then
        self:SetButtonState(self["BtnSkill"..self.LastSelectIndex], CS.UiButtonState.Normal)
    end
    self.SelectIndex = -1
    self.LastSelectIndex = -1
end

function XUiPanelBattleSkill:GetSelectIndex()
    return self.SelectIndex
end

function XUiPanelBattleSkill:OnBubbleClose()
    self.ShowBubbleIndex = nil
end

function XUiPanelBattleSkill:GetSkillCost()
    if self.SelectIndex <= 0 then
        return 0
    end
    local skillIds = self._Control:GetWeaponSkillIds(self.WeaponId)
    local skillId = skillIds[self:GetSelectIndex()]
    
    return self._Control:GetWeaponSkillCost(skillId)
end

--- 
---@param btn XUiComponent.XUiButton
--------------------------
function XUiPanelBattleSkill:SetButtonState(btn, state)
    btn:SetButtonState(state)
    if state == CS.UiButtonState.Select then
        btn.enabled = false
    else
        btn.enabled = true
    end 
end

function XUiPanelBattleSkill:ShowButtonEffect(value)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    local skillIds = self._Control:GetWeaponSkillIds(self.WeaponId)
    for _, skillId in pairs(skillIds) do
        local effect = self["Effect" .. skillId]
        if effect then
            effect.gameObject:SetActiveEx(value and self._Control:IsSkillUnlock(skillId))
        end
    end
end

return XUiPanelBattleSkill