local XUiDlcHuntBagGridChip = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGridChip")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")
local XUiDlcHuntChipDetailAttrCompare = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipDetailAttrCompare")
local XUiDlcHuntChipDetailBreakthroughMagic = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipDetailBreakthroughMagic")
local XUiDlcHuntChipDetailBreakthroughCostGrid = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipDetailBreakthroughCostGrid")

---@class XUiDlcHuntChipDetailBreakthrough
local XUiDlcHuntChipDetailBreakthrough = XClass(nil, "XUiDlcHuntChipDetailBreakthrough")

function XUiDlcHuntChipDetailBreakthrough:Ctor(ui, viewModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelDlcHuntChipDetail
    self._ViewModel = viewModel
    self._UiAttr = {}
    self._UiMagic = {}
    self._UiCost = {}
    self:Init()
end

function XUiDlcHuntChipDetailBreakthrough:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnDlcYellow, self.OnClickBreakthrough)
    XUiHelper.RegisterClickEvent(self, self.BtnDlcBlue, self.OnClickAutoSelect)
end

function XUiDlcHuntChipDetailBreakthrough:Update()
    local data = self._ViewModel:GetData()
    self.Text.text = data.TextBreakthroughConsumeDesc
    self.TxtCurAttr.text = data.TextBreakthroughBefore
    self.TxtSelectAttr.text = data.TextBreakthroughAfter
    self.Icon01:SetSprite(data.IconBeforeBreakthrough)
    self.Icon02:SetSprite(data.IconAfterBreakthrough)

    XUiDlcHuntUtil.UpdateDynamicItem(self._UiAttr, data.DataCompareBreakthrough, self.PanelAttr1, XUiDlcHuntChipDetailAttrCompare)
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiMagic, data.DataCompareMagic, self.PanelAffix1, XUiDlcHuntChipDetailBreakthroughMagic)

    self:UpdateCost()
end

function XUiDlcHuntChipDetailBreakthrough:OnClickBreakthrough()
    self._ViewModel:RequestBreakthrough()
end

function XUiDlcHuntChipDetailBreakthrough:OnClickAutoSelect()
    self._ViewModel:AutoSelectChips4Breakthrough()
    self:UpdateCost()
end

function XUiDlcHuntChipDetailBreakthrough:UpdateCost()
    local cost = self._ViewModel:GetCostBreakthrough()
    local amount = self._ViewModel:GetBreakthroughCostItemAmount()
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiCost, cost, self.GridIconChip, XUiDlcHuntChipDetailBreakthroughCostGrid, amount)
    for i = 1, #self._UiCost do
        self._UiCost[i]:SetViewModel(self._ViewModel)
    end
end

return XUiDlcHuntChipDetailBreakthrough