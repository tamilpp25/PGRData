local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--组合小游戏背包面板UI控件
local XUiComposeGamePanelBag = XClass(nil, "XUiComposeGamePanelBag")
--================
--构造函数
--================
function XUiComposeGamePanelBag:Ctor(rootUi, game, ui)
    self.RootUi = rootUi
    self.Game = game
    XTool.InitUiObjectByUi(self, ui)
    self:InitDynamicTable()
end
--================
--初始化动态列表
--================
function XUiComposeGamePanelBag:InitDynamicTable()
    local XGrid = require("XUi/XUiMiniGame/ComposeGame/XUiComposeGameBagGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XGrid)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiComposeGamePanelBag:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.BagList and self.BagList[index] then
            grid:RefreshData(self.BagList[index])
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
    end
end
--================
--刷新控件
--================
function XUiComposeGamePanelBag:UpdateData()
    self.BagList = self.Game:GetBagGrids()
    self.DynamicTable:SetDataSource(self.BagList)
    self.DynamicTable:ReloadDataASync(1)
end

return XUiComposeGamePanelBag