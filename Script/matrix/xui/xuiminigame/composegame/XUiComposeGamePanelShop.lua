--组合小游戏商店UI控件
local XUiComposeGamePanelShop = XClass(nil, "XUiComposeGamePanelShop")
--================
--构造函数
--================
function XUiComposeGamePanelShop:Ctor(rootUi, game, ui)
    self.RootUi = rootUi
    self.Game = game
    XTool.InitUiObjectByUi(self, ui)
    self:InitDynamicTable()
end
--================
--初始化动态列表
--================
function XUiComposeGamePanelShop:InitDynamicTable()
    local XGrid = require("XUi/XUiMiniGame/ComposeGame/XUiComposeGameShopGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XGrid)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiComposeGamePanelShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ShopList and self.ShopList[index] then
            grid:RefreshData(self.ShopList[index])
        end
    --elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        --grid:OnClick()
    end
end
--================
--刷新列表
--================
function XUiComposeGamePanelShop:UpdateData()
    self.ShopList = self.Game:GetShopGrids()
    self.DynamicTable:SetDataSource(self.ShopList)
    self.DynamicTable:ReloadDataASync(1)
end
return XUiComposeGamePanelShop