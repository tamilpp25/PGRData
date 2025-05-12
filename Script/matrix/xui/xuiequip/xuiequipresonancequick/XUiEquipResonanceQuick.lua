local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiEquipResonanceQuick: XLuaUi
local XUiEquipResonanceQuick = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceQuick")

function XUiEquipResonanceQuick:OnAwake()
    self.PanelResonance.gameObject:SetActiveEx(true)
    self.TAB_TYPE = {
        RESONANCE_UP = 1,
        RESONANCE_DOWN = 2,
        AWAKE = 3,
    }
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:InitTabGroup()
    self:InitPanelAwareness()
    self:InitPanelCost()
    self:RegisterUiEvents()
end

function XUiEquipResonanceQuick:OnStart(characterid, isAwake)
    self.CharacterId = characterid
    self.TabIndex = isAwake and self.TAB_TYPE.AWAKE or self.TAB_TYPE.RESONANCE_UP
end

function XUiEquipResonanceQuick:OnEnable()
    local tab = self.TabIndex
    self.TabIndex = nil
    self.PanelTabGroup:SelectIndex(tab)
end

function XUiEquipResonanceQuick:OnDisable()
    self:CloseAwarenessList()
end

function XUiEquipResonanceQuick:OnDestroy()

end

function XUiEquipResonanceQuick:OnRelease()
    self.TabBtns = nil
    self.GridAwarenessList = nil
end

function XUiEquipResonanceQuick:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterClickEvent(self.BtnSkill, self.OnBtnSkillClick)
    self:RegisterClickEvent(self.BtnQuickResonance, self.OnBtnQuickResonanceClick)
    self:RegisterClickEvent(self.BtnResonanceSelectAll, self.OnBtnResonanceSelectAllClick)
end

function XUiEquipResonanceQuick:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiEquipResonanceQuick:InitTabGroup()
    self.TabBtns = {self.BtnTabUp, self.BtnTabDown, self.BtnTabOverclocking}
    self.PanelTabGroup:Init(self.TabBtns, function(index)
        self:OnTabClick(index)
    end)
end

function XUiEquipResonanceQuick:OnTabClick(index)
    if self.TabIndex == index then
        return
    end

    self.SkillInfo = nil
    self.TabIndex = index
    self:PlayAnimation("QieHuan")
    self:Refresh()
end

function XUiEquipResonanceQuick:OnBtnSkillClick()
    -- 找出第一个6星意识
    local equipId
    local equipIds = self._Control:GetCharacterAwarenessIds(self.CharacterId)
    for _, eId in pairs(equipIds) do
        local equip = self._Control:GetEquip(eId)
        if equip:GetStar() >= XEnumConst.EQUIP.SIX_STAR then
            equipId = eId
            break
        end
    end

    -- 未穿戴6星意识，无法找到共鸣技能池子
    if not equipId then
        XUiManager.TipText("QuickResonanceNotSixStarEquipTips")
        return
    end

    -- 选择技能界面
    local param = {
        equipId = equipId,
        selectCharacterId = self.CharacterId,
        pos = self.TabIndex,
        rootUi = self, 
        selectSkillInfo = self.SkillInfo,
        isNeedSelectSkill = true,
        isIgnoreResonance = true,
        ClickCb = function (skillInfo)
            self.SkillInfo = skillInfo
            self:UnSelectSameSkill(skillInfo)
            self:RefreshPanelSkill()
            self:RefreshPanelCost()
        end
    }
    XLuaUiManager.Open("UiEquipResonanceSkillPreview", param)
end

function XUiEquipResonanceQuick:OnBtnQuickResonanceClick()
    if not self.SkillInfo then
        return
    end

    local equipIds = {}
    for i, gridAwareness in ipairs(self.GridAwarenessList) do
        if gridAwareness:GetIsSelected() then
            local equipId = self._Control:GetCharacterEquipId(self.CharacterId, i)
            table.insert(equipIds, equipId)
        end
    end
    if #equipIds == 0 then
        return
    end

    -- 6星意识自选共鸣材料不够
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.QuickReasonanceCoin)
    local isEnough = ownCnt >= #equipIds
    if not isEnough then
        XUiManager.TipText("QuickResonanceNotEnoughItemTips")
        return
    end

    -- 请求快速共鸣
    local equipCnt = #equipIds
    local tipsTitle = XUiHelper.GetText("EquipResonancePreciousTipTitle")
    local tipsContent = XUiHelper.GetText("QuickResonanceConfirmTips", equipCnt, equipCnt)
    XUiManager.DialogTip(tipsTitle, tipsContent, XUiManager.DialogType.Normal, nil, function()
        local skillId = self:GetSelectSkillId()
        local resonanceType = self.SkillInfo.EquipResonanceType
        local useItemId = XDataCenter.ItemManager.ItemId.QuickReasonanceCoin
        local agency = XMVCA:GetAgency(ModuleId.XEquip)
        agency:RequestEquipQuickResonance(equipIds, self.CharacterId, useItemId, self.TabIndex, skillId, resonanceType, function()
            self:Refresh()
        end)
    end)
end

function XUiEquipResonanceQuick:OnBtnResonanceSelectAllClick()
    if not XTool.IsTableEmpty(self.GridAwarenessList) then
        local isAnyAwarenessSelectSuccess = false
        for i, grid in pairs(self.GridAwarenessList) do
            if grid:TrySelectAwareness(true) then
                isAnyAwarenessSelectSuccess = true
            end
        end

        if isAnyAwarenessSelectSuccess then
            self:OnSelectAwarenessChange()
        end
    end
end

function XUiEquipResonanceQuick:OnSelectAwarenessChange()
    self:RefreshPanelCost()
end

-- 刷新界面
function XUiEquipResonanceQuick:Refresh()
    local isResonance = self.TabIndex == self.TAB_TYPE.RESONANCE_UP or self.TabIndex == self.TAB_TYPE.RESONANCE_DOWN
    self.PanelResonance.gameObject:SetActiveEx(isResonance)
    if isResonance then
        self:RefreshPanelAwareness()
        self:RefreshPanelSkill()
        self:RefreshPanelCost()
    end
    
    -- 快速共鸣页签
    local isAwake = self.TabIndex == self.TAB_TYPE.AWAKE
    if isAwake then
        if not self.UiPanelOverclockingQuick then
            local XUiPanelOverclockingQuick = require("XUi/XUiEquip/XUiEquipResonanceQuick/XUiPanelOverclockingQuick")
            self.UiPanelOverclockingQuick = XUiPanelOverclockingQuick.New(self.PanelOverclocking, self)
        end
        self.UiPanelOverclockingQuick:Open()
        self.UiPanelOverclockingQuick:Refresh(self.CharacterId)
    else
        if self.UiPanelOverclockingQuick then
            self.UiPanelOverclockingQuick:Close()
        else
            self.PanelOverclocking.gameObject:SetActiveEx(false)
        end
    end
end

function XUiEquipResonanceQuick:InitPanelAwareness()
    self.GridAwarenessList = {}
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local XUiGridAwareness = require("XUi/XUiEquip/XUiEquipResonanceQuick/XUiGridAwareness")
    for i = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local go
        if i == 1 then
            go = self.GridAwareness
        else
            go = CSInstantiate(self.GridAwareness.gameObject, self.AwarenessList)
        end
        local grid = XUiGridAwareness.New(go, self)
        table.insert(self.GridAwarenessList, grid)
    end
end

-- 关闭界面时关闭XUiGridAwareness对象
function XUiEquipResonanceQuick:CloseAwarenessList()
    if not self.GridAwarenessList then return end
    for _, grid in ipairs(self.GridAwarenessList) do
        grid:Close()
    end
end

-- 刷新意识面板
function XUiEquipResonanceQuick:RefreshPanelAwareness()
    for i = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local grid = self.GridAwarenessList[i]
        grid:Open()
        grid:Refresh(self.CharacterId, i, self.TabIndex)
    end
end

-- 刷新技能面板
function XUiEquipResonanceQuick:RefreshPanelSkill()
    local isSelect = self.SkillInfo ~= nil
    self.ResonanceSkill.gameObject:SetActiveEx(isSelect)
    self.PanelEmptySkill.gameObject:SetActiveEx(not isSelect)
    if not isSelect then
        return
    end

    local uiObj = self.ResonanceSkill
    uiObj:GetObject("TxtSkillName").text = self.SkillInfo.Name
    uiObj:GetObject("TxtSkillDes").text = self.SkillInfo.Description
    uiObj:GetObject("RImgResonanceSkill"):SetRawImage(self.SkillInfo.Icon)
end

function XUiEquipResonanceQuick:InitPanelCost()
    local iconPath = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.QuickReasonanceCoin)
    self.RImgCostIcon:SetRawImage(iconPath)
end

-- 刷新消耗面板
function XUiEquipResonanceQuick:RefreshPanelCost()
    local selectCnt = 0
    for _, gridAwareness in ipairs(self.GridAwarenessList) do
        if gridAwareness:GetIsSelected() then
            selectCnt = selectCnt + 1
        end
    end

    -- 消耗文本
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.QuickReasonanceCoin)
    local isEnough = ownCnt >= selectCnt
    local strKey = isEnough and "QuickResonanceCost" or "QuickResonanceCostNoEnough"
    self.TxtCost.text = XUiHelper.GetText(strKey, ownCnt, selectCnt)

    -- 按钮状态
    local isDisable = self.SkillInfo == nil or selectCnt == 0
    self.BtnQuickResonance:SetDisable(isDisable)
end

-- 取消选中相同技能
function XUiEquipResonanceQuick:UnSelectSameSkill()
    local skillId = self:GetSelectSkillId()
    for _, awareness in ipairs(self.GridAwarenessList) do
        if skillId == awareness:GetResonanceSkillId() and self.CharacterId == awareness:GetResonanceCharacterId() then
            awareness:SetSelected(false)
        end
    end
end

function XUiEquipResonanceQuick:GetSelectSkillId()
    return self.SkillInfo and self.SkillInfo:GetSkillIdToServer() or nil
end

return XUiEquipResonanceQuick