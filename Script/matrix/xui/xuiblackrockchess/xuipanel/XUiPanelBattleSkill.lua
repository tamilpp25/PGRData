
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
    self:RefreshHead()
end

function XUiPanelBattleSkill:OnDisable()
    self:ResetSelect()
end

function XUiPanelBattleSkill:OnDestroy()
    
end

function XUiPanelBattleSkill:InitView()
    self.LastSelectIndex = -1
    self.SelectIndex = -1
    self.ImgCostBgDict = {}
    self.ImgBgDict = {}
    local actor = self._Control:GetChessGamer():GetRole(self.RoleId)
    local skillIds = self._Control:GetWeaponSkillIds(actor:GetWeaponId())
    self.SkillIds = skillIds
    for i = 1, #skillIds do
        local btn = self["BtnSkill" .. i]
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, btn)
        btn.CallBack = function()
            self:OnBtnClick(i)
        end
        
        if uiObject.BtnSkillPC then
            if XDataCenter.UiPcManager.IsPc() then
                self.Parent:SetPcKeyCover(uiObject.BtnSkillPC, "ALPHA"..i)
            else
                uiObject.BtnSkillPC.gameObject:SetActiveEx(false)
            end
        end
        
        local effect = btn.transform:GetComponentInChildren(typeof(CS.XUiEffectLayer))
        if effect then
            self["Effect" .. i] = effect
        end
        
        if uiObject.PanelCd then
            self["PanelCd" .. i] = uiObject.PanelCd
        end

        if uiObject.LockTip then
            self["LockTip" .. i] = uiObject.LockTip
        end

        if uiObject.EnergyTip then
            self["EnergyTip" .. i] = uiObject.EnergyTip
        end

        self.ImgCostBgDict[i] = {}
        if uiObject.ImgCostBg1 then
            table.insert(self.ImgCostBgDict[i], uiObject.ImgCostBg1)
        end
        if uiObject.ImgCostBg2 then
            table.insert(self.ImgCostBgDict[i], uiObject.ImgCostBg2)
        end
        if uiObject.ImgCostBg3 then
            table.insert(self.ImgCostBgDict[i], uiObject.ImgCostBg3)
        end
        if uiObject.ImgCostBg4 then
            table.insert(self.ImgCostBgDict[i], uiObject.ImgCostBg4)
        end

        self.ImgBgDict[i] = {}
        if uiObject.ImgBg1 then
            table.insert(self.ImgBgDict[i], uiObject.ImgBg1)
        end
        if uiObject.ImgBg2 then
            table.insert(self.ImgBgDict[i], uiObject.ImgBg2)
        end
        if uiObject.ImgBg3 then
            table.insert(self.ImgBgDict[i], uiObject.ImgBg3)
        end
        if uiObject.ImgBg4 then
            table.insert(self.ImgBgDict[i], uiObject.ImgBg4)
        end
    end
end

function XUiPanelBattleSkill:UpdateBtnSkill(btn, i)
    local skillId = self.SkillIds[i]
    local unlock = self._Control:IsSkillUnlock(skillId)
    local skillType = self._Control:GetWeaponSkillType(skillId)
    local isEnoughEnergy = self._Control:CouldUseSkill(self.RoleId, skillId)
    local cost = self._Control:GetWeaponSkillCost(self.RoleId, skillId)
    local isShowCost = XTool.IsNumberValid(cost)

    local lockTip = self["LockTip" .. i]
    local energyTip = self["EnergyTip" .. i]
    
    -- 未解锁
    if not unlock then
        btn:SetButtonState(XUiButtonState.Disable)
        lockTip.gameObject:SetActiveEx(true)
        energyTip.gameObject:SetActiveEx(false)
    -- 能量不够
    elseif not isEnoughEnergy then
        btn:SetButtonState(XUiButtonState.Disable)
        lockTip.gameObject:SetActiveEx(false)
        energyTip.gameObject:SetActiveEx(true)
    else
        btn:SetButtonState(self.SelectIndex == i and XUiButtonState.Select or XUiButtonState.Normal)
    end
    
    btn:SetRawImage(self._Control:GetWeaponSkillIcon(skillId))
    --[[
    local lockTip = self["LockTip" .. i]
    local energyTip = self["EnergyTip" .. i]
    if skillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3 then
        if lockTip then
            lockTip.gameObject:SetActiveEx(not unlock or not isEnoughEnergy)
        end
        if energyTip then
            energyTip.gameObject:SetActiveEx(false)
        end
    else
        if lockTip then
            lockTip.gameObject:SetActiveEx(not unlock) -- 技能未解锁
        end
        if energyTip then
            energyTip.gameObject:SetActiveEx(unlock and not isEnoughEnergy) -- 能量不足
        end
    end
    ]]
    local energyBg = self._Control:GetEnergyBgByActorRedModel()
    for _, imgCostBg in pairs(self.ImgCostBgDict[i]) do
        imgCostBg.gameObject:SetActiveEx(isShowCost) -- 技能不消耗能量 隐藏能量显示
        imgCostBg:SetRawImage(energyBg)
    end
    for _, imgBg in pairs(self.ImgBgDict[i]) do
        imgBg:SetRawImage(self._Control:GetWeaponSkillBg(skillId))
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
    local actor = self._Control:GetChessGamer():GetRole(self.RoleId)
    local weaponId = actor:GetWeaponId()
    if not weaponId then
        return
    end
    local skillIds = self._Control:GetWeaponSkillIds(weaponId)
    self.SkillIds = skillIds
    for i = 1, #skillIds do
        local btn = self["BtnSkill" .. i]
        local skillId = skillIds[i]
        local cost = self._Control:GetWeaponSkillCost(self.RoleId, skillId)
        btn:SetNameByGroup(1, cost)
        local cd = self._Control:GetWeaponSkillCd(self.RoleId, skillId)
        local panelCd = self["PanelCd" .. i]
        if panelCd then
            panelCd.gameObject:SetActiveEx(cd > 0)
            btn:SetNameByGroup(0, cd)
        end
        self:UpdateBtnSkill(btn, i)
    end
    self:ShowButtonEffect()
end

-- 实时更新角色头像 不依赖于服务端返回的数据
function XUiPanelBattleSkill:RefreshHead()
    local energy = self._Control:GetChessGamer():GetEnergy()
    local target = self._Control:GetEnterRedModelEnergy()
    local index = energy < target and 1 or 2
    local weaponId = self._Control:GetRoleWeaponId(self.RoleId, index)
    self.RImgHead:SetRawImage(self._Control:GetWeaponCircleIcon(weaponId))
end

function XUiPanelBattleSkill:IsOperate()
    return (self._Control:IsEnterMove() or self._Control:IsEnterSkill() or self._Control:IsEnemySelect()) and self._Control:IsOperate()
end

function XUiPanelBattleSkill:OnBtnClick(selectIndex)
    --非玩家回合 屏蔽选择技能
    if CS.XBlackRockChess.XBlackRockChessManager.IsLimitClick then
        return
    end

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
        if skill:GetSkillType() == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3 then
            actor:ShowBubbleText(self._Control:GetEnergyNotEnoughText(4))
        else
            actor:ShowBubbleText(self._Control:GetEnergyNotEnoughText(1))
        end
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
    for i, skillId in ipairs(skillIds) do
        local effect = self["Effect" .. i]
        if effect then
            effect.gameObject:SetActiveEx(self._Control:CouldUseSkill(self.RoleId, skillId))
        end
    end
end

return XUiPanelBattleSkill