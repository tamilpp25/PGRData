local XUiDlcHuntBagGridChip = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGridChip")
local XUiDlcHuntChipGridAttr = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipGridAttr")
local XUiDlcHuntChipBatchMagic = require("XUi/XUiDlcHunt/ChipMain/XUiDlcHuntChipBatchMagic")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XUiDlcHuntChipReplaceInfo
local XUiDlcHuntChipReplaceInfo = XClass(nil, "XUiDlcHuntChipReplaceInfo")

function XUiDlcHuntChipReplaceInfo:Ctor(ui, viewModel, isLeft, playAnimationEquip)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._PlayAnimationEquip = playAnimationEquip
    ---@type XViewModelDlcHuntChipSetting
    self._ViewModel = viewModel
    self._IsLeft = isLeft
    self._UiAttrList = {}
    self:Init()
end

function XUiDlcHuntChipReplaceInfo:Init()
    ---@type XUiDlcHuntBagGridChip
    self.ChipGrid = XUiDlcHuntBagGridChip.New(self.GridIconChip)
    ---@type XUiDlcHuntChipBatchMagic
    self.Magic1 = XUiDlcHuntChipBatchMagic.New(self.PanelSkillDes1)
    ---@type XUiDlcHuntChipBatchMagic
    self.Magic2 = XUiDlcHuntChipBatchMagic.New(self.PanelSkillDes2)

    if self._IsLeft then
        XUiHelper.RegisterClickEvent(self, self.BtnDlcYellow, self.OnClickStrengthen)
        XUiHelper.RegisterClickEvent(self, self.BtnDlcRed, self.OnClickUndress)
        XUiHelper.RegisterClickEvent(self, self.BtnDlcBlue, self.OnClickDress)
        if self.BtnDlcBlue then
            self.BtnDlcBlue.gameObject:SetActiveEx(false)
        end
    else
        XUiHelper.RegisterClickEvent(self, self.BtnDlcBlueS, self.OnClickStrengthen)
        XUiHelper.RegisterClickEvent(self, self.BtnDlcYellowS, self.OnClickDress)
    end
end

function XUiDlcHuntChipReplaceInfo:GetChip()
    if self._IsLeft then
        local chipEquip = self._ViewModel:GetChipEquip()
        if chipEquip then
            return chipEquip
        end
        return self._ViewModel:GetChipSelected()
    else
        return self._ViewModel:GetChipSelected()
    end
end

function XUiDlcHuntChipReplaceInfo:Update()
    local chip = self:GetChip()
    self:UpdateDetail(chip)
    --self.BtnDlcEquip
    --self.BtnDlcYellow
    --self.BtnDlcRed
end

---@param chip XDlcHuntChip
function XUiDlcHuntChipReplaceInfo:UpdateDetail(chip)
    if chip then
        self.ChipGrid:Update(chip)
        self.TxtLevel.text = XUiHelper.GetText("DlcHuntChipLevel", chip:GetLevel(), chip:GetMaxLevel())
        self.TxtEquipName.text = chip:GetName()
        self.PanelMaxLevel.gameObject:SetActiveEx(chip:IsMaxLevel())
        --self.PanelCommon.gameObject:SetActiveEx(true)
        --self.GreatDetails.gameObject:SetActiveEx(true)

        if self._IsLeft then
            if not self._ViewModel:IsAnyChipEquip() then
                -- 无装备芯片 选择了芯片
                --self:SetPanelBtnVisible(false)
                if self.BtnDlcYellow then
                    self.BtnDlcYellow.gameObject:SetActiveEx(true)
                end
                if self.BtnDlcEquip then
                    self.BtnDlcEquip.gameObject:SetActiveEx(false)
                end
                if self.BtnDlcBlue then
                    self.BtnDlcBlue.gameObject:SetActiveEx(true)
                end
                if self.BtnDlcRed then
                    self.BtnDlcRed.gameObject:SetActiveEx(false)
                end
            else
                if self.BtnDlcYellow then
                    self.BtnDlcYellow.gameObject:SetActiveEx(true)
                end
                if self.BtnDlcEquip then
                    self.BtnDlcEquip.gameObject:SetActiveEx(false)
                end
                if self.BtnDlcBlue then
                    self.BtnDlcBlue.gameObject:SetActiveEx(false)
                end
                if self.BtnDlcRed then
                    self.BtnDlcRed.gameObject:SetActiveEx(true)
                end
            end
        end

        -- Attr
        local attrTable1, attrTable2 = self._ViewModel:GetChipCompare()
        local attrTable
        if self._IsLeft then
            attrTable = attrTable1
            if not self._ViewModel:IsAnyChipEquip() and not attrTable1 then
                attrTable = attrTable2
            end
        else
            attrTable = attrTable2
        end
        XUiDlcHuntUtil.UpdateDynamicItem(self._UiAttrList, attrTable, self.PanelAttr1, XUiDlcHuntChipGridAttr)

        local magicDesc = chip:GetMagicDescIncludePreview()
        local magic = magicDesc[1]
        if magic then
            self.Magic1:Update(magic, magic.IsActive)
            self.Magic1.GameObject:SetActiveEx(true)
        else
            self.Magic1.GameObject:SetActiveEx(false)
        end
        local magic2 = magicDesc[2]
        if magic2 then
            self.Magic2:Update(magic2, magic2.IsActive)
            self.Magic2.GameObject:SetActiveEx(true)
        else
            self.Magic2.GameObject:SetActiveEx(false)
        end

        if self.PanelNo then
            self.PanelNo.gameObject:SetActiveEx(false)
        end
    else
        --self.PanelCommon.gameObject:SetActiveEx(false)
        --self.GreatDetails.gameObject:SetActiveEx(false)
        if self.PanelNo then
            self.PanelNo.gameObject:SetActiveEx(true)
        end
    end
end

function XUiDlcHuntChipReplaceInfo:SetPanelBtnVisible(isVisible)
    --self.PanelBtn.gameObject:SetActiveEx(isVisible)
    if self.BtnDlcYellow then
        self.BtnDlcYellow.gameObject:SetActiveEx(isVisible)
    end
    if self.BtnDlcRed then
        self.BtnDlcRed.gameObject:SetActiveEx(isVisible)
    end
end

function XUiDlcHuntChipReplaceInfo:OnClickStrengthen()
    XLuaUiManager.Open("UiDlcHuntChipDetails", self:GetChip())
end

function XUiDlcHuntChipReplaceInfo:OnClickUndress()
    self._ViewModel:RequestUndress()
end

function XUiDlcHuntChipReplaceInfo:OnClickDress()
    if self._ViewModel:RequestDress() then
        XLuaUiManager.Close("UiDlcHuntChipReplace")
        if self._PlayAnimationEquip then
            self._PlayAnimationEquip()
        end
    end
end

function XUiDlcHuntChipReplaceInfo:RemovePlayAnimationEquip()
    self._PlayAnimationEquip = false
end

return XUiDlcHuntChipReplaceInfo