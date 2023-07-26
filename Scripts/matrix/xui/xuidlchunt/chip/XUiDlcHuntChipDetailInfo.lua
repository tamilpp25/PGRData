local XUiDlcHuntChipGridAttr = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipGridAttr")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")
local XUiDlcHuntGridMagic = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntGridMagic")

---@class XUiDlcHuntChipDetailInfo
local XUiDlcHuntChipDetailInfo = XClass(nil, "XUiDlcHuntChipDetailInfo")

function XUiDlcHuntChipDetailInfo:Ctor(ui, viewModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelDlcHuntChipDetail
    self._ViewModel = viewModel
    self:Init()
    self._UiAttrList = {}
    self._UiMagicList = {}
end

function XUiDlcHuntChipDetailInfo:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnUnlock, self.OnClickUnlock)
    XUiHelper.RegisterClickEvent(self, self.BtnLock, self.OnClickUnlock)
end

function XUiDlcHuntChipDetailInfo:Update()
    local data = self._ViewModel:GetData()
    self.ImgIcon:SetSprite(data.IconBreakthrough)
    self:UpdateUnlock()
    self.TxtEquipName.text = data.ChipName
    local star = data.Star
    for i = 1, XDlcHuntChipConfigs.CHIP_STAR_AMOUNT do
        self["ImgStar" .. i].gameObject:SetActiveEx(i <= star)
    end
    local level = data.ChipLevel
    local maxLevel = data.ChipMaxLevel
    self.TxtLevel.text = XUiHelper.GetText("DlcHuntChipLevel", level, maxLevel)
    self.TextMax.gameObject:SetActiveEx(data.IsMaxLevel)

    -- magic
    if XTool.IsTableEmpty(data.MagicDesc) then
        self.PanelNoSuitSkill.gameObject:SetActiveEx(true)
        self.PanelSuitSkillDes.gameObject:SetActiveEx(false)
    else
        self.PanelNoSuitSkill.gameObject:SetActiveEx(false)
        self.PanelSuitSkillDes.gameObject:SetActiveEx(true)
        XUiDlcHuntUtil.UpdateDynamicItem(self._UiMagicList, data.MagicDesc, self.TxtSkillDes, XUiDlcHuntGridMagic)
    end

    -- Attr
    local attrTable = data.AttrTable
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiAttrList, attrTable, self.PanelAttr1, XUiDlcHuntChipGridAttr)
end

function XUiDlcHuntChipDetailInfo:UpdateUnlock()
    local data = self._ViewModel:GetData()
    if not data.IsShowTabs then
        self.BtnUnlock.gameObject:SetActiveEx(false)
        self.BtnLock.gameObject:SetActiveEx(false)
        return
    end
    local isLock = data.IsChipLock
    self.BtnUnlock.gameObject:SetActiveEx(not isLock)
    self.BtnLock.gameObject:SetActiveEx(isLock)
end

function XUiDlcHuntChipDetailInfo:OnClickUnlock()
    self._ViewModel:SetLockInverse()
    self:UpdateUnlock()
end

return XUiDlcHuntChipDetailInfo