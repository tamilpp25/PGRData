local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

---@class XUiRiftPluginBag:XLuaUi
---@field _Control XRiftControl
local XUiRiftPluginBag = XLuaUiManager.Register(XLuaUi, "UiRiftPluginBag")

function XUiRiftPluginBag:OnAwake()
    self.SelectIndex = 1 -- 当前选中的插件下标

    self:InitDynamicTable()
    self:InitToggleList()
    self:SetButtonCallBack()
    self:InitTimes()

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.RiftGold, XDataCenter.ItemManager.ItemId.RiftCoin)
    --self.AssetPanel:HideBtnBuy()
end

function XUiRiftPluginBag:OnEnable()
    self.Super.OnEnable(self)
    XEventManager.AddEventListener(XEventId.EVENT_RIFT_DATA_UPDATE, self.RefreshPluginDetail, self)
    XEventManager.AddEventListener(XEventId.EVENT_RIFT_PLUGIN_AFFIX_UPDATE, self.RefreshPluginDetail, self)
    XEventManager.AddEventListener(XEventId.EVENT_RIFT_BUY, self.RefreshAfterBuyPlugin, self)
    XEventManager.AddEventListener(XEventId.EVENT_RIFT_GUIDE, self.OnGuide, self)
end

function XUiRiftPluginBag:OnDisable()
    self.Super.OnDisable(self)
    self._Control:ClosePluginBagRed()
    XEventManager.RemoveEventListener(XEventId.EVENT_RIFT_DATA_UPDATE, self.RefreshPluginDetail, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RIFT_PLUGIN_AFFIX_UPDATE, self.RefreshPluginDetail, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RIFT_BUY, self.RefreshAfterBuyPlugin, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RIFT_GUIDE, self.OnGuide, self)
end

function XUiRiftPluginBag:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:Close()
    end

    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end

    self:RegisterClickEvent(self.BtnHandbookBuff, self.OnClickHandbookBuff)
end

function XUiRiftPluginBag:OnClickHandbookBuff()
    XLuaUiManager.Open("UiRiftHandbookBuff")
end

function XUiRiftPluginBag:InitToggleList()
    local btns = {}
    self.TabStarMap = {}
    for i = 3, 6 do
        local btn = self["Btn" .. i .. "Star"]
        local cur, all = self._Control:GetPluginCount(i)
        btn:SetNameByGroup(0, XUiHelper.GetText("RiftPluginFilterTagName", i))
        btn:SetNameByGroup(1, string.format("%s/%s", cur, all))
        table.insert(btns, btn)
        table.insert(self.TabStarMap, i)
    end
    self.PanelTabBtn:Init(btns, function(index)
        self:OnTabSelected(index)
    end)
    self.PanelTabBtn:SelectIndex(#btns)
end

function XUiRiftPluginBag:OnTabSelected(index)
    self:RefreshDynamicTable(self.TabStarMap[index])
end

function XUiRiftPluginBag:InitDynamicTable()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiRiftPluginGrid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftPluginBag:RefreshDynamicTable(star)
    self.SelectIndex = 1
    self.SelectStar = star
    self.DataList = self._Control:GetAllPluginList(star)
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(1)
    self:RefreshPluginDetail()

    self.PanelDynamicEmpty.gameObject:SetActiveEx(#self.DataList == 0)
end

function XUiRiftPluginBag:RefreshAfterBuyPlugin()
    ---@type XUiRiftPluginGrid
    local grid = self.DynamicTable:GetGridByIndex(self.SelectIndex)
    if grid then
        grid:Refresh(self.DataList[self.SelectIndex])
    end
    self:RefreshPluginDetail()
    for i = 3, 6 do
        local btn = self["Btn" .. i .. "Star"]
        local cur, all = self._Control:GetPluginCount(i)
        btn:SetNameByGroup(1, string.format("%s/%s", cur, all))
    end
end

---@param grid XUiRiftPluginGrid
function XUiRiftPluginBag:OnDynamicTableEvent(event, index, grid)
    -- item初始化
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(function()
            self:OnPluginClick(grid)
            self:PlayAnimation("GridRiftPluginTipsQieHuan")
        end, true)

    -- item 刷新
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local plugin = self.DataList[index]
        grid:Refresh(plugin)
        grid:ShowSelect(self.SelectIndex == index)
    end
end

function XUiRiftPluginBag:OnPluginClick(selectGrid)
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:ShowSelect(false)
    end
    ---@type XUiRiftPluginGrid
    self.SelectGrid = selectGrid
    self.SelectIndex = selectGrid.Index
    selectGrid:ShowSelect(true)
    self:RefreshPluginDetail()
end

function XUiRiftPluginBag:RefreshPluginDetail()
    if not self.PluginDetail then
        ---@type XUiGridRiftPluginDrop
        self.PluginDetail = require("XUi/XUiRift/Grid/XUiGridRiftPluginDrop").New(self.GridRiftPluginTips, self)
    end

    local plugin = self.DataList[self.SelectIndex]
    if plugin == nil then
        self.PluginDetail:Close()
        self.PanelEmpty.gameObject:SetActiveEx(true)
    else
        self.PluginDetail:Open()
        self.PluginDetail:RefreshByPlugin(plugin)
        self.PluginDetail:ShowAffixDetail()
        self.PanelEmpty.gameObject:SetActiveEx(false)
    end
end

function XUiRiftPluginBag:InitTimes()
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

-- 定位到可购买的插件处
function XUiRiftPluginBag:OnGuide()
    local jumpTo
    for i, v in ipairs(self.DataList) do
        if not self._Control:IsHavePlugin(v.Id) and self._Control:IsPluginBuy(v.Id) then
            jumpTo = i
            break
        end
    end
    if XTool.IsNumberValid(jumpTo) then
        if XTool.IsNumberValid(self.SelectIndex) then
            ---@type XUiRiftPluginGrid
            local grid = self.DynamicTable:GetGridByIndex(self.SelectIndex)
            if grid then
                grid:ShowSelect(false)
            end
        end
        self.SelectIndex = jumpTo
        self.DynamicTable:ScrollToIndex(jumpTo, 0.5, nil, function()
            ---@type XUiRiftPluginGrid
            local grid = self.DynamicTable:GetGridByIndex(self.SelectIndex)
            if grid then
                grid:ShowSelect(true)
                self:RefreshPluginDetail()
            end
        end)
    end
end

return XUiRiftPluginBag