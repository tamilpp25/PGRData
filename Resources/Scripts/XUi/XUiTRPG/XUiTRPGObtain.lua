local XUiGridTRPGItem = require("XUi/XUiTRPG/XUiGridTRPGItem")

local XUiTRPGObtain = XLuaUiManager.Register(XLuaUi, "UiTRPGObtain")

function XUiTRPGObtain:OnAwake()
    self:AutoAddListener()
end

function XUiTRPGObtain:OnStart(itemId, itemCount, closeCb)
    self.ItemId = itemId
    self.ItemCount = itemCount
    self.CloseCb = closeCb
end

function XUiTRPGObtain:OnEnable()
    self:UpdateItem()
end

function XUiTRPGObtain:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiTRPGObtain:UpdateItem()
    local itemId = self.ItemId
    local itemCount = self.ItemCount

    local grid = self.ItemGrid
    if not grid then
        grid = XUiGridTRPGItem.New(self.GridItem, self)
        self.ItemGrid = grid
    end
    grid:Refresh(itemId, itemCount)
end

function XUiTRPGObtain:AutoAddListener()
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnHelpCourse, self.OnBtnHelpClick)
end

function XUiTRPGObtain:OnBtnBackClick()
    self:Close()
end

function XUiTRPGObtain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end