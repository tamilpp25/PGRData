local XUiGridOverclockingAwareness = XClass(XUiNode, "XUiGridOverclockingAwareness")

function XUiGridOverclockingAwareness:OnStart(root)
    self.Root = root
    self.MAX_AWAKE_COUNT = XEnumConst.EQUIP.MAX_AWAKE_COUNT
    self:RegisterUiEvents()
end

function XUiGridOverclockingAwareness:OnEnable()

end

function XUiGridOverclockingAwareness:OnDisable()
    if self.XUiGridEquip then
        self.XUiGridEquip:Close()
    end
end

function XUiGridOverclockingAwareness:RegisterUiEvents()
    for i = 1, self.MAX_AWAKE_COUNT do
        local pos = i
        local resonanceUiObj = self["GridResonanceSkill" .. i]
        local btn = resonanceUiObj:GetObject("BtnResonance")
        self.Root:RegisterClickEvent(btn, function() self:BtnResonanceClick(pos) end)
    end
end

function XUiGridOverclockingAwareness:BtnResonanceClick(pos)
    if self:GetIsSelected(pos) then
        self:SetSelected(pos, false)
        self.Parent:OnSelectAwarenessChange()
        return
    end

    -- 未穿戴装备
    if not self.IsWearEquip then
        XUiManager.TipText("EquipNoEquipTips")
        return
    end

    -- 装备非6星，不可超频
    if not self:IsEquipStarCanAwake() then
        XUiManager.TipText("EquipNoSixStarTips")
        return
    end

    -- 装备未共鸣，不可超频
    if not self:IsEquipResonance(pos) then
        XUiManager.TipText("EquipAwakeNoResonanceTips")
        return
    end
    
    -- 装备未满级，不可超频
    if not self:IsEquipMaxLevelAndBreakthrough() then
        XUiManager.TipText("EquipNoMaxLevelTips")
        return
    end
    
    -- 已超频，不可选中
    if self:IsEquipAwake(pos) then
        XUiManager.TipText("EquipAwakeClickTips")
        return
    end

    self:SetSelected(pos, true)
    self.Parent:OnSelectAwarenessChange()
end

function XUiGridOverclockingAwareness:Refresh(characterId, site)
    self.CharacterId = characterId
    self.Site = site -- 装备部位Id

    self.EquipId = self._Control:GetCharacterEquipId(self.CharacterId, self.Site)
    self.IsWearEquip = self.EquipId and self.EquipId > 0

    self:RefreshEquip()
    for pos = 1, self.MAX_AWAKE_COUNT do
        self:SetSelected(pos, false)
        self:RefreshResonanceSkill(pos)
    end
end

-- 刷新装备
function XUiGridOverclockingAwareness:RefreshEquip()
    self.GridEquip.gameObject:SetActiveEx(false)
    self.PanelNoEquip.gameObject:SetActiveEx(false)
    self.TxtTips.text = ""
    
    -- 未穿戴装备
    if not self.IsWearEquip then
        self.PanelNoEquip.gameObject:SetActiveEx(true)
        self.TxtTips.text = XUiHelper.GetText("EquipNoEquip")
        return
    end

    -- 刷新装备
    self.GridEquip.gameObject:SetActiveEx(true)
    if not self.XUiGridEquip then
        local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
        self.XUiGridEquip = XUiGridEquip.New(self.GridEquip, self.Root, self.EquipId)
    end
    self.XUiGridEquip:Open()
    self.XUiGridEquip:Refresh(self.EquipId)
    
    -- 装备非6星，不可超频
    if not self:IsEquipStarCanAwake() then
        self.TxtTips.text = XUiHelper.GetText("EquipNoSixStar")
        return
    end

    -- 装备未满级，不可超频
    if not self:IsEquipMaxLevelAndBreakthrough() then
        self.TxtTips.text = XUiHelper.GetText("EquipNoMaxLevel")
        return
    end
end

-- 刷新共鸣技能
function XUiGridOverclockingAwareness:RefreshResonanceSkill(pos)
    local uiObj = self["GridResonanceSkill" .. tostring(pos)]
    local panelResonance = uiObj:GetObject("PanelResonance")
    local panelNoResonance = uiObj:GetObject("PanelNoResonance")
    local panelEmptyResonance = uiObj:GetObject("PanelEmptyResonance")
    panelResonance.gameObject:SetActiveEx(false)
    panelNoResonance.gameObject:SetActiveEx(false)
    panelEmptyResonance.gameObject:SetActiveEx(false)

    -- 未穿戴装备
    if not self.IsWearEquip then
        panelEmptyResonance.gameObject:SetActiveEx(true)
        return
    end

    -- 未共鸣
    if not self:IsEquipResonance(pos) then
        panelNoResonance.gameObject:SetActiveEx(true)
        return
    end

    -- 刷新共鸣技能
    local isAwake = self:IsEquipAwake(pos)
    local skillInfo = self._Control:GetResonanceSkillInfo(self.EquipId, pos)
    panelResonance.gameObject:SetActiveEx(true)
    uiObj:GetObject("RImgResonanceSkill"):SetRawImage(skillInfo.Icon)
    uiObj:GetObject("PanelOverclocking").gameObject:SetActiveEx(isAwake)
    uiObj:GetObject("PanelNoOverclocking").gameObject:SetActiveEx(not isAwake)
    if isAwake then
        uiObj:GetObject("TxtSkillDesOverclocking").text = skillInfo.Description
    else
        uiObj:GetObject("TxtSkillDesNoOverclocking").text = skillInfo.Description
    end
end

-- 穿戴装备对应位置是否共鸣
function XUiGridOverclockingAwareness:IsEquipResonance(pos)
    local equip = self._Control:GetEquip(self.EquipId)
    return equip:GetResonanceInfo(pos) ~= nil
end

-- 装备星级是否足够超频
function XUiGridOverclockingAwareness:IsEquipStarCanAwake()
    local equip = self._Control:GetEquip(self.EquipId)
    return equip:IsStarCanAwake()
end

--- 是否达到最大等级和突破阶段
function XUiGridOverclockingAwareness:IsEquipMaxLevelAndBreakthrough()
    local equip = self._Control:GetEquip(self.EquipId)
    return equip:IsMaxLevelAndBreakthrough()
end

-- 穿戴装备对应位置是否超频
function XUiGridOverclockingAwareness:IsEquipAwake(pos)
    local equip = self._Control:GetEquip(self.EquipId)
    return equip:IsEquipPosAwaken(pos)
end

-- 设置选中状态
function XUiGridOverclockingAwareness:SetSelected(pos, isSelected)
    self["IsSelected"..pos] = isSelected
    local uiObj = self["GridResonanceSkill" .. pos]
    uiObj:GetObject("ImgSelect").gameObject:SetActiveEx(isSelected)
end

function XUiGridOverclockingAwareness:GetIsSelected(pos)
    return self["IsSelected"..pos]
end

-- 获取选中位置列表
function XUiGridOverclockingAwareness:GetSelectPosList()
    local posList = {}
    for pos = 1, self.MAX_AWAKE_COUNT do
        if self:GetIsSelected(pos) then
            table.insert(posList, pos)
        end
    end
    return posList
end

-- 获取超频的消耗
function XUiGridOverclockingAwareness:GetCost()
    local selPosList = self:GetSelectPosList()
    local selCnt = #selPosList
    if selCnt == 0 then
        return {}, 0
    end
    
    local coinCnt = self._Control:GetAwakeConsumeCrystalCoin(self.EquipId, selCnt)
    local itemList = self._Control:GetAwakeConsumeItemCrystalList(self.EquipId, selCnt)
    return itemList, coinCnt
end

-- 尝试选中所有可超频部位，若选择失败，不进行弹窗提示
function XUiGridOverclockingAwareness:TrySelectAllCanOverclockingPos()
    local isSelectSuccess = false
    for pos = 1, self.MAX_AWAKE_COUNT do
        if self:GetIsSelected(pos) then
            goto CONTINUE
        end

        -- 未穿戴装备
        if not self.IsWearEquip then
            goto CONTINUE
        end

        -- 装备非6星，不可超频
        if not self:IsEquipStarCanAwake() then
            goto CONTINUE
        end

        -- 装备未共鸣，不可超频
        if not self:IsEquipResonance(pos) then
            goto CONTINUE
        end

        -- 装备未满级，不可超频
        if not self:IsEquipMaxLevelAndBreakthrough() then
            goto CONTINUE
        end

        -- 已超频，不可选中
        if self:IsEquipAwake(pos) then
            goto CONTINUE
        end

        self:SetSelected(pos, true)
        isSelectSuccess = true
        
        :: CONTINUE ::
    end
    
    return isSelectSuccess
end

return XUiGridOverclockingAwareness