local XUiDlcHuntChipGridAttr = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipGridAttr")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XUiDlcHuntCharacterInfo
local XUiDlcHuntCharacterInfo = XClass(nil, "XUiDlcHuntCharacterInfo")

function XUiDlcHuntCharacterInfo:Ctor(ui, viewModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelDlcHuntCharacter
    self._ViewModel = viewModel
    self._UiAttr = {}
    self:Init()
end

function XUiDlcHuntCharacterInfo:Init()
    XUiHelper.RegisterClickEvent(self, self.PanelChip, self.OnClickChipGroup)
    XUiHelper.RegisterClickEvent(self, self.BtnExclamatoryMark, self.OnClickAttr)
end

function XUiDlcHuntCharacterInfo:Update()
    self.RImgTypeIcon:SetRawImage(self._ViewModel:GetCharacterIcon())
    self.TxtName.text = self._ViewModel:GetCharacterName()
    --self.BtnCareerTips
    self.ImageEnergy:SetSprite(self._ViewModel:GetElementIcon())
    self.TxtEnergy.text = self._ViewModel:GetElementName()
    self.ImageWeapon:SetSprite(self._ViewModel:GetWeaponIcon())
    self.TxtWeapon.text = self._ViewModel:GetWeaponName()

    local attrTable = self._ViewModel:GetAttrTable4Display()
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiAttr, attrTable, self.Gridformation1, XUiDlcHuntChipGridAttr)

    self.PanelChip:SetNameByGroup(0, XUiHelper.GetText("DlcHuntChipGroupAmount", self._ViewModel:GetChipGroupAmount()))
    self.PanelChip:SetNameByGroup(1, self._ViewModel:GetChipGroupName())

    self.PanelChip:ShowReddot(self._ViewModel:GetCharacter():IsCanEquipMoreChip())
    local chipGroup = self._ViewModel:GetChipGroup()
    if chipGroup then
        local mainChipIcon = chipGroup:GetMainChipIcon()
        self.PanelChip:SetRawImage(mainChipIcon)
    else
        self.PanelChip:SetRawImage(XDlcHuntConfigs.GetIconChipGroupEmpty())
    end
end

function XUiDlcHuntCharacterInfo:OnClickChipGroup()
    local chipGroup = self._ViewModel:GetChipGroup()
    local character = self._ViewModel:GetCharacter()
    XDataCenter.DlcHuntChipManager.OpenUiChipMain(chipGroup, character)
end

function XUiDlcHuntCharacterInfo:OnClickAttr()
    XLuaUiManager.Open("UiDlcHuntAttrDialog", { Character = self._ViewModel:GetCharacter() })
end

return XUiDlcHuntCharacterInfo