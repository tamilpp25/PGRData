local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

local XUiRiftPluginBag = XLuaUiManager.Register(XLuaUi, "UiRiftPluginBag")

function XUiRiftPluginBag:OnAwake()
    self.SelectIndex = 1 -- 当前选中的插件下标

    self:InitDynamicTable()
    self:InitToggleList()
    self:SetButtonCallBack()
    self:InitTimes()

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.RiftGold, XDataCenter.ItemManager.ItemId.RiftCoin)
    self.AssetPanel:HideBtnBuy()
end

function XUiRiftPluginBag:OnEnable()
    self.Super.OnEnable(self)
    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.PluginShop)
    self.BtnPluginShop:SetDisable(not isUnlock)
end

function XUiRiftPluginBag:OnDisable()
    self.Super.OnDisable(self)
    XDataCenter.RiftManager.ClosePluginBagRed()
end

function XUiRiftPluginBag:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:Close()
    end

    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end

    self.BtnPluginShop.CallBack = function()
        self:OnBtnPluginShopClick()
    end
    self:RegisterClickEvent(self.BtnHandbookBuff, self.OnClickHandbookBuff)
end

function XUiRiftPluginBag:OnClickHandbookBuff()
    XLuaUiManager.Open("UiRiftHandbookBuff")
end

function XUiRiftPluginBag:OnBtnPluginShopClick()
    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.PluginShop)
    if isUnlock then
        XLuaUiManager.Open("UiRiftPluginShop")
    else
        local funcUnlockCfg = XRiftConfig.GetCfgByIdKey(XRiftConfig.TableKey.RiftFuncUnlock, XRiftConfig.FuncUnlockId.PluginShop)
        XUiManager.TipError(funcUnlockCfg.Desc)
    end
end

function XUiRiftPluginBag:InitToggleList()
    local btns = {}
    self.TabStarMap = {}
    for i = 3, 6 do
        local btn = self["Btn" .. i .. "Star"]
        local cur, all = XDataCenter.RiftManager.GetPluginCount(i)
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
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiRiftPluginGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftPluginBag:RefreshDynamicTable(star)
    self.SelectIndex = 1
    self.DataList = XDataCenter.RiftManager.GetAllPluginList(star)
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(1)
    self:RefreshPluginDetail()

    self.PanelDynamicEmpty.gameObject:SetActiveEx(#self.DataList == 0)
end

function XUiRiftPluginBag:OnDynamicTableEvent(event, index, grid)
    -- item初始化
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local clickCB = function(grid)
            self:OnPluginClick(grid)
        end
        grid:Init(clickCB, true)

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
        self.PanelEmpty.gameObject:SetActiveEx(false)
    end
end

function XUiRiftPluginBag:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.RiftManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end