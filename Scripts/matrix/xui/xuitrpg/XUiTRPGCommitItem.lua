local XUiGridTRPGItem = require("XUi/XUiTRPG/XUiGridTRPGItem")

local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiTRPGCommitItem = XLuaUiManager.Register(XLuaUi, "UiTRPGCommitItem")

function XUiTRPGCommitItem:OnAwake()
    self:AutoAddListener()
end

function XUiTRPGCommitItem:OnStart(itemId)
    self.ItemId = itemId
end

function XUiTRPGCommitItem:OnEnable()
    self:UpdateItem()
end

function XUiTRPGCommitItem:UpdateItem()
    local itemId = self.ItemId

    local grid = self.ItemGrid
    if not grid then
        grid = XUiGridTRPGItem.New(self.GridItem, self)
        self.ItemGrid = grid
    end
    grid:Refresh(itemId)

    local itemName = XDataCenter.ItemManager.GetItemName(itemId)
    self.TxtInfo.text = CSXTextManagerGetText("TRPGItemCommited", itemName)
end

function XUiTRPGCommitItem:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnBackClick)
end

function XUiTRPGCommitItem:OnBtnBackClick()
    self:Close()
end