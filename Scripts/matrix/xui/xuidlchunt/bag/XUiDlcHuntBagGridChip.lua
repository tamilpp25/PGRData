---@class XUiDlcHuntBagGridChip
local XUiDlcHuntBagGridChip = XClass(nil, "XUiDlcHuntBagGridChip")

function XUiDlcHuntBagGridChip:Ctor(ui, params)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XDlcHuntChip
    self._Chip = false
    ---@type XViewModelDlcHuntBag
    self._ViewModel = false
    self._IsClick = true
    self._IsMine = false
    self._Params = params or {}
    self:Init()
end

function XUiDlcHuntBagGridChip:SetClickDisable()
    self._IsClick = false
end

function XUiDlcHuntBagGridChip:Init()
    if self._Params.ClickFunc and self._Params.ClickTable then
        XUiHelper.RegisterClickEvent(self._Params.ClickTable, self.BtnClick, self._Params.ClickFunc)
    else
        XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
    end
end

---@param chip XDlcHuntChip
function XUiDlcHuntBagGridChip:Update(chip)
    self._Chip = chip
    self.RImgIcon:SetRawImage(chip:GetIcon())
    local iconBreak = self.ImgIconBreak or self.ImgBreak
    iconBreak:SetSprite(chip:GetIconBreakthrough())
    local txtLevel = self.TxtNum or self.TxtLevel
    if txtLevel then
        txtLevel.text = chip:GetLevel()
    end
    if self.ImgQuality then
        self.ImgQuality.color = chip:GetColor()
    end
    local star = chip:GetStarAmount()
    for i = 1, XDlcHuntChipConfigs.CHIP_STAR_AMOUNT do
        local uiStar = self["ImgGirdStar" .. i]
        if uiStar then
            uiStar.gameObject:SetActiveEx(i <= star)
        end
    end
    if self.TxtName then
        self.TxtName.text = chip:GetName()
    end
    self:UpdateSelected()
end

function XUiDlcHuntBagGridChip:SetViewModel(viewModel)
    self._ViewModel = viewModel
end

function XUiDlcHuntBagGridChip:UpdateSelected()
    if not self._ViewModel or not self._Chip then
        return
    end
    if self.ImgSelected then
        local isSelected = self._ViewModel:IsChipSelected(self._Chip)
        self.ImgSelected.gameObject:SetActiveEx(isSelected)
    end
end

function XUiDlcHuntBagGridChip:OnClick()
    if not self._IsClick then
        return
    end
    if not self._Chip then
        if self._IsMine then
            XLuaUiManager.Open("UiDlcHuntChipMain")
        end
        return
    end
    --if not self._Chip:IsValid() then
    --    XLog.Error("[XUiDlcHuntBagGridChip] invalid chip")
    --    return
    --end

    if self._ViewModel and self._ViewModel:IsCanSelectGrid() then
        self._ViewModel:SetChipSelectedInverse(self._Chip)
        self:UpdateSelected()
        return
    end

    -- 背包界面
    if self._ViewModel and self._ViewModel.__cname == "XViewModelDlcHuntBag" then
        XLuaUiManager.Open("UiDlcHuntChipDetails", self._Chip)
        return
    end
end

function XUiDlcHuntBagGridChip:SetIsMine(isMine)
    self._IsMine = isMine
end

function XUiDlcHuntBagGridChip:GetChip()
    return self._Chip
end

return XUiDlcHuntBagGridChip