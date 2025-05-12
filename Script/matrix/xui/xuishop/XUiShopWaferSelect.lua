local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--[[
    v1.29 商店优化
    优化当前分解商店-意识商店的筛选功能					
        （1）去掉当前【位置】筛选按钮，以及下拉选择位置的下拉条					
        （2）将原【位置】按钮替换成【切换套装】按钮。					
        （3）进入分解-意识商店时，默认选中套装为排序第一意识套装（康德丽娜）					
        （4）点击【切换套装】按钮，弹出二级界面，显示所有可选择的意识套装图标、名称、属性简介。					
        （5）选中某一意识套装后，点击【确认】按钮后，关闭二级界面，商店刷新为对应意识，显示顺序按照意识位置从一到六依次显示。					
        （6）5星和4星意识商店中有材料道具，【切换套装】按钮变成【筛选】按钮，同时在筛选界面新增分类：【其他类】。					
        （7）选中【其他类】，商店刷新对应的除意识外的道具。					
        （8）【2】—【5】步骤的操作逻辑参考【战斗——资源——作战补给——资源商店——切换套装】的操作逻辑，可直接复用，需要特殊处理不属于意识类的道具					
--]]
local XUiShopWaferSelect = XLuaUiManager.Register(XLuaUi, "UiShopWaferSelect")

function XUiShopWaferSelect:OnAwake()
    self:InitComponent()
    self:InitDynamicTable()
end

function XUiShopWaferSelect:OnStart(SelectData, dataProvider, selectCallBack)
    self.DataProvider = dataProvider
    self.SelectCallBack = selectCallBack
    self.CurData = SelectData
    self:UpdateGridList()
end

function XUiShopWaferSelect:InitComponent()
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnCancel.CallBack = function() self:OnBtnCloseClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCloseClick() end
    self.GridSuitSimple.gameObject:SetActiveEx(false)
end

function XUiShopWaferSelect:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList.gameObject)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require("XUi/XUiShop/XUiShopWaferSelectGrid"))
end

function XUiShopWaferSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DataProvider[index]
        self:UpdateGrid(grid, data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local data = self.DataProvider[index]
        self:OnGridClick(data)
    end
end

function XUiShopWaferSelect:OnGridClick(data)
    if self.CurData == data then
        self.CurData = nil
    else
        self.CurData = data
    end
    
    for k, v in ipairs(self.DataProvider) do
        local grid = self.DynamicTable:GetGridByIndex(k)
        if grid then
            self:UpdateGrid(grid, v)
        end
    end
end

function XUiShopWaferSelect:UpdateGrid(grid, data)
    if data then
        local isSelected = self.CurData == data
        grid:Refresh(data, isSelected)
    end
end

function XUiShopWaferSelect:UpdateGridList()
    self.ImgEmpty.gameObject:SetActiveEx(not self.DataProvider or #self.DataProvider == 0)
    self.DynamicTable:SetDataSource(self.DataProvider)
    self.DynamicTable:ReloadDataASync()
end

function XUiShopWaferSelect:OnBtnConfirmClick()
    if self.SelectCallBack then
        self.SelectCallBack(self.CurData)
    end

    self:Close()
end

function XUiShopWaferSelect:OnBtnCloseClick()
    self:Close()
end

return XUiShopWaferSelect