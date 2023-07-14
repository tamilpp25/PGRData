---@class XUiDlcHuntChipDetailBreakthroughCostGrid
local XUiDlcHuntChipDetailBreakthroughCostGrid = XClass(nil, "XUiDlcHuntChipDetailBreakthroughCostGrid")

function XUiDlcHuntChipDetailBreakthroughCostGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelDlcHuntChipDetail
    self._ViewModel = false
    self._Chip = false
    self._Index = 0
    self:Init()
    self.EffectRefresh.gameObject:SetActiveEx(false)
end

function XUiDlcHuntChipDetailBreakthroughCostGrid:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
end

function XUiDlcHuntChipDetailBreakthroughCostGrid:Update(data)
    local oldChip = self._Chip
    ---@type XDlcHuntChip
    local chip = data.Chip
    self._Index = data.Index
    self._Chip = chip
    if not chip then
        self.ImgTianjia.gameObject:SetActiveEx(true)
        self.RImgIcon.gameObject:SetActiveEx(false)
        self.ImgQuality.gameObject:SetActiveEx(false)
        self.ImgBreak.gameObject:SetActiveEx(false)
        self.TxtLevel.gameObject:SetActiveEx(false)
        self.ImgSelected.gameObject:SetActiveEx(false)
        self.EffectRefresh.gameObject:SetActiveEx(false)
        return
    end
    if not oldChip or not oldChip:Equals(chip) then
        self.EffectRefresh.gameObject:SetActiveEx(false)
        self.EffectRefresh.gameObject:SetActiveEx(true)
    end
    self.ImgTianjia.gameObject:SetActiveEx(false)
    self.RImgIcon.gameObject:SetActiveEx(true)
    self.ImgQuality.gameObject:SetActiveEx(true)
    self.ImgBreak.gameObject:SetActiveEx(true)
    self.TxtLevel.gameObject:SetActiveEx(true)
    --self.ImgSelected.gameObject:SetActiveEx(true)

    self.RImgIcon:SetRawImage(chip:GetIcon())
    local iconBreak = self.ImgIconBreak or self.ImgBreak
    iconBreak:SetSprite(chip:GetIconBreakthrough())
    local txtLevel = self.TxtNum or self.TxtLevel
    txtLevel.text = chip:GetLevel()

    local star = chip:GetStarAmount()
    for i = 1, XDlcHuntChipConfigs.CHIP_STAR_AMOUNT do
        local uiStar = self["ImgGirdStar" .. i]
        if uiStar then
            uiStar.gameObject:SetActiveEx(i <= star)
        end
    end
end

function XUiDlcHuntChipDetailBreakthroughCostGrid:SetViewModel(viewModel)
    self._ViewModel = viewModel
end

function XUiDlcHuntChipDetailBreakthroughCostGrid:OnClick()
    self._ViewModel:SelectBreakthroughCost(self._Index)
end

return XUiDlcHuntChipDetailBreakthroughCostGrid