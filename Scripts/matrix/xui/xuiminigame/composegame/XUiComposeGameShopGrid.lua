--组合小游戏商店动态列表内容组件
local XUiComposeGameShopGrid = XClass(nil, "XUiComposeGameShopGrid")
--================
--构造函数(动态列表组件初始化不在这里做)
--================
function XUiComposeGameShopGrid:Ctor()
    
end
--================
--初始化
--================
function XUiComposeGameShopGrid:Init(ui)
    XTool.InitUiObjectByUi(self, ui)
    self:InitPanelStar()
    self.BtnItem.CallBack = function() self:OnClick() end
end

function XUiComposeGameShopGrid:InitPanelStar()
    local PanelStar = require("XUi/XUiMiniGame/ComposeGame/XUiComposeGameStarPanelLevel")
    self.Star = PanelStar.New(self.PanelLevel)
end

function XUiComposeGameShopGrid:RefreshData(gridInfo)
    if not gridInfo then
        return
    end
    self.Grid = gridInfo
    self.Item = self.Grid:GetItem()
    local gameId = self.Item:GetGameId()
    self.Game = XDataCenter.ComposeGameManager.GetGameById(gameId)
    self:SetIsSell()
    self:SetDisplayItem()
    self:SetIsLevelUp()
end

function XUiComposeGameShopGrid:SetIsSell()
    local isSell = self.Grid:CheckIsSell()
    if isSell then
        self.BtnItem:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnItem:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiComposeGameShopGrid:SetDisplayItem()
    if not self.Item or (self.Item:CheckIsEmpty()) then return end
    self.TxtName.text = self.Item:GetName()
    self.BtnItem:SetName(self.Item:GetCostCoinNum())
    self.RImgShopItemIcon:SetRawImage(self.Item:GetBigIcon())
    self.RImgCostItemIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.Game:GetCoinId()))
    self.Star:ShowStar(self.Item:GetStar())
end

function XUiComposeGameShopGrid:SetIsLevelUp()
    self.ImgLevel.gameObject:SetActiveEx(self.Item:CheckIsLevelUp())
end

function XUiComposeGameShopGrid:OnClick()
    if not self.Grid then return end
    if self.Grid:CheckIsSell() then
        XUiManager.TipMsg(CS.XTextManager.GetText("ComposeGameShopItemIsSelled"))
        return
    end
    XDataCenter.ComposeGameManager.BuyItem(self.Grid)
end

return XUiComposeGameShopGrid