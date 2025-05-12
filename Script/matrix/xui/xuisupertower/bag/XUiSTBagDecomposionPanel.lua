local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local ChildPanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--===========================
--超级爬塔容量条形图面板
--===========================
local XUiSTBagDecomposionPanel = XClass(ChildPanel, "XUiSTBagDecomposionPanel")
local QUALITY_START_NUM = 2
function XUiSTBagDecomposionPanel:InitPanel()
    self:InitToggleButtons()
    self:InitDynamicTable()
    self:InitButtons()
end

function XUiSTBagDecomposionPanel:InitToggleButtons()
    self.ToggleButtons = {}
    local index = 1
    local btn = self["BtnTog" .. index]
    local toggleScript = require("XUi/XUiSuperTower/Bag/XUiSTBagToggleButton")
    while btn ~= nil do
        self.ToggleButtons[index] = toggleScript.New(btn, self, (index - 1) + QUALITY_START_NUM)
        index = index + 1
        btn = self["BtnTog" .. index]
    end
end

function XUiSTBagDecomposionPanel:InitDynamicTable()
    local GridProxy = require("XUi/XUiSuperTower/Bag/XUiSTBagDecomposionGrid")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(GridProxy)
    self.DynamicTable:SetDelegate(self)
end

function XUiSTBagDecomposionPanel:InitButtons()
    XUiHelper.RegisterClickEvent(self, self.BtnCha, function() self:Close() end)
    XUiHelper.RegisterClickEvent(self, self.BtnDecomposion, function() self:Decomposion() end)
end
--=============
--动态列表事件
--=============
function XUiSTBagDecomposionPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, function() grid:OnGridClick() end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DecomposionDataList and self.DecomposionDataList[index] then
            grid:RefreshData(self.DecomposionDataList[index])
        end
        --elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        --grid:OnClick()
    end
end

function XUiSTBagDecomposionPanel:OnShowPanel()
    self:ResetPanel()
end

function XUiSTBagDecomposionPanel:ResetPanel()
    self:ResetToggles()
    self:OnDecomposeListRefresh({})
    self.TxtSelectNum.text = 0
end

function XUiSTBagDecomposionPanel:ResetToggles()
    for _, toggle in pairs(self.ToggleButtons) do
        toggle:Reset()
    end
end

function XUiSTBagDecomposionPanel:Decomposion()
    if self.DecomposionData and next(self.DecomposionData) then
        self.RootUi.BagManager:RequestResolvePlugin(self.DecomposionData)
        self:Close()
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("STBagDecomposionDataIsNull"))
    end
end
--=============
--星数Toggle单选时
--=============
function XUiSTBagDecomposionPanel:OnTogSelect(index)
    self.RootUi:PluginsSelectStar(index)
end
--=============
--星数Toggle反选时
--=============
function XUiSTBagDecomposionPanel:OnTogUnSelect(index)
    self.RootUi:PluginsUnSelectStar(index)
end

function XUiSTBagDecomposionPanel:OnDecomposeListRefresh(decomposionList)  
    local decomposionData = {}
    self.DecomposionData = {}
    local selectNum = 0
    for _, plugin in pairs(decomposionList) do
        -- 存储分解后道具信息用于展示预览 key = itemId value = 分解数量
        if not decomposionData[plugin:GetResolveId()] then
            decomposionData[plugin:GetResolveId()] = plugin:GetResolveCount()
        else
            decomposionData[plugin:GetResolveId()] = decomposionData[plugin:GetResolveId()] + plugin:GetResolveCount()
        end
        -- 存储分解插件信息用于请求 key = 插件Id value = 插件数
        if not self.DecomposionData[plugin:GetId()] then
            self.DecomposionData[plugin:GetId()] = 0
        end
        self.DecomposionData[plugin:GetId()] = self.DecomposionData[plugin:GetId()] + 1
        
        -- 统计选中个数
        selectNum = selectNum + 1
    end
    self.TxtSelectNum.text = selectNum
    self.DecomposionDataList = {}
    for itemId, count in pairs(decomposionData) do       
        local data = { ItemId = itemId, Count = count}
        table.insert(self.DecomposionDataList, data)
    end
    self.DynamicTable:SetDataSource(self.DecomposionDataList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiSTBagDecomposionPanel:Close()
    self.RootUi:ShowPageBag()
end

function XUiSTBagDecomposionPanel:OnPluginRefresh()
    self:ResetPanel()
end

function XUiSTBagDecomposionPanel:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_ST_PLUGIN_REFRESH, self.OnPluginRefresh, self)
end

function XUiSTBagDecomposionPanel:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_ST_PLUGIN_REFRESH, self.OnPluginRefresh, self)
end

return XUiSTBagDecomposionPanel