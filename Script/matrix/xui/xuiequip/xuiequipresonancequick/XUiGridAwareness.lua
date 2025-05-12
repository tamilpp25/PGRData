local XUiGridAwareness = XClass(XUiNode, "XUiGridAwareness")

function XUiGridAwareness:OnStart()
    self:RegisterUiEvents()
end

function XUiGridAwareness:OnEnable()

end

function XUiGridAwareness:OnDisable()
    if self.XUiGridEquip then
        self.XUiGridEquip:Close()
    end
end

function XUiGridAwareness:RegisterUiEvents()
    self.Parent:RegisterClickEvent(self.BtnAwareness, function()
        self:OnBtnAwarenessClick()
    end)
end

function XUiGridAwareness:OnBtnAwarenessClick()
    if not self.IsCanSelect then
        return
    end

    local selectSkillId = self.Parent:GetSelectSkillId()
    if selectSkillId and selectSkillId == self:GetResonanceSkillId() and self.CharacterId == self:GetResonanceCharacterId() then
        XUiManager.TipText("ResonanceSameSkillTips")
        return
    end

    -- 切换选中状态
    self:SetSelected(not self.IsSelected)

    -- 共鸣结果未确认弹窗
    local equip = self._Control:GetEquip(self.EquipId)
    local unconfirmInfo = equip:GetResonanceUnConfirmInfo(self.Pos)
    if unconfirmInfo then
        XLuaUiManager.Open("UiEquipResonanceSelectAfter", self.EquipId, self.Pos, self.CharacterId, nil, nil, function()
            self:RefreshResonanceSkill()
        end)
    end

    self.Parent:OnSelectAwarenessChange()
end

--- 尝试选中，失败不弹窗提示
function XUiGridAwareness:TrySelectAwareness(onlyNoSkill)
    if not self.IsCanSelect then
        return false
    end
    
    local selfResonanceSkillId = self:GetResonanceSkillId()
    -- 只能选择未共鸣的
    if onlyNoSkill and (XTool.IsNumberValid(selfResonanceSkillId) and self:GetResonanceCharacterId() == self.CharacterId) then
        return false
    end

    local selectSkillId = self.Parent:GetSelectSkillId()
    if selectSkillId and selectSkillId == selfResonanceSkillId and self.CharacterId == self:GetResonanceCharacterId() then
        return false
    end

    -- 切换选中状态
    self:SetSelected(true)
    
    return true
end

function XUiGridAwareness:Refresh(characterId, site, pos)
    self.CharacterId = characterId
    self.Site = site -- 装备部位Id
    self.Pos = pos -- 共鸣位置，1为上位，2为下位

    self.EquipId = self._Control:GetCharacterEquipId(self.CharacterId, self.Site)
    self.IsWearing = self.EquipId and self.EquipId > 0
    self.IsCanSelect = self:GetIsCanSelect() -- 是否可选中
    self.IsSelected = false -- 当前是否被选中
    self.ImgSelect.gameObject:SetActiveEx(false)

    self:RefreshEquip()
    self:RefreshResonanceSkill()
end

-- 刷新装备
function XUiGridAwareness:RefreshEquip()
    -- 未穿戴装备
    self.GridEquip.gameObject:SetActiveEx(self.IsWearing)
    self.PanelNoEquip.gameObject:SetActiveEx(not self.IsWearing)
    if not self.IsWearing then
        return
    end

    -- 刷新装备
    if not self.XUiGridEquip then
        local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
        self.XUiGridEquip = XUiGridEquip.New(self.GridEquip, self.Parent, self.EquipId)
    end
    self.XUiGridEquip:Open()
    self.XUiGridEquip:Refresh(self.EquipId)
end

-- 刷新共鸣技能
function XUiGridAwareness:RefreshResonanceSkill()
    self.PanelUnResnoance.gameObject:SetActiveEx(false)
    self.PanelNoResnoanceSkill.gameObject:SetActiveEx(false)
    self.GridResnanceSkill.gameObject:SetActiveEx(false)

    -- 不可选中，不可快速共鸣
    if not self.IsCanSelect then
        self.PanelUnResnoance.gameObject:SetActiveEx(true)
        return 
    end

    -- 没有共鸣技能
    local equip = self._Control:GetEquip(self.EquipId)
    local resonanceInfo = equip:GetResonanceInfo(self.Pos)
    if resonanceInfo == nil then
        self.PanelNoResnoanceSkill.gameObject:SetActiveEx(true)
        return
    end

    -- 刷新共鸣技能
    self.GridResnanceSkill.gameObject:SetActiveEx(true)
    if not self.XUiGridResonanceSkill then
        local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
        self.XUiGridResonanceSkill = XUiGridResonanceSkill.New(self.GridResnanceSkill, self.EquipId, self.Pos, self.CharacterId)
    end
    self.XUiGridResonanceSkill:SetEquipIdAndPos(self.EquipId, self.Pos)
    self.XUiGridResonanceSkill:Refresh()
end

-- 获取是否可选中
function XUiGridAwareness:GetIsCanSelect()
    -- 未穿戴装备
    if not self.IsWearing then
        return false
    end

    -- 装备非6星
    local equip = self._Control:GetEquip(self.EquipId)
    local star = equip:GetStar()
    if star < XEnumConst.EQUIP.SIX_STAR then
        return false
    end

    return true
end

-- 设置选中状态
function XUiGridAwareness:SetSelected(isSelected)
    self.IsSelected = isSelected
    self.ImgSelect.gameObject:SetActiveEx(self.IsSelected)
end

function XUiGridAwareness:GetIsSelected()
    return self.IsSelected
end

-- 获取当前共鸣技能Id
function XUiGridAwareness:GetResonanceSkillId()
    if self.EquipId then
        local equip = self._Control:GetEquip(self.EquipId)
        local resonanceInfo = equip:GetResonanceInfo(self.Pos)
        if resonanceInfo then
            return resonanceInfo.TemplateId
        end
    end
end

-- 获取当前共鸣角色Id
function XUiGridAwareness:GetResonanceCharacterId()
    if self.EquipId then
        local equip = self._Control:GetEquip(self.EquipId)
        local resonanceInfo = equip:GetResonanceInfo(self.Pos)
        if resonanceInfo then
            return resonanceInfo.CharacterId
        end
    end
end

return XUiGridAwareness