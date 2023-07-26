local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

local XUiRiftPluginBag = XLuaUiManager.Register(XLuaUi, "UiRiftPluginBag")

function XUiRiftPluginBag:OnAwake()
    self.SelectIndex = 1 -- 当前选中的插件下标
    self.TipsPluginGrid = nil -- 提示面板的插件

    self:InitToggleList()
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:InitTimes()

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.RiftGold, XDataCenter.ItemManager.ItemId.RiftCoin)
    self.AssetPanel:HideBtnBuy()

    self.TipsPluginGrid = XUiRiftPluginGrid.New(self.GridRiftPlugin)
    self.TipsPluginGrid:Init(nil, true)
end

function XUiRiftPluginBag:OnEnable()
    self.Super.OnEnable(self)
    local haveCnt, allCnt = XDataCenter.RiftManager.GetPluginHaveAndAllCnt()
    local collectPercent = string.format("%.1f", (haveCnt / allCnt) * 100)
    local t1, t2 = math.modf(collectPercent)
    if t2 == 0 then collectPercent = t1 end
    self.TxtCollectNum.text = collectPercent .. "%"

    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.PluginShop)
    self.BtnPluginShop:SetDisable(not isUnlock)
    self:RefreshDynamicTable()
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

    self:RegisterClickEvent(self.TogStar3, self.OnTogStar3Click)
    self:RegisterClickEvent(self.TogStar4, self.OnTogStar4Click)
    self:RegisterClickEvent(self.TogStar5, self.OnTogStar5Click)
    self:RegisterClickEvent(self.TogStar6, self.OnTogStar6Click)
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

function XUiRiftPluginBag:OnTogStar3Click()
    local isOn = self.TogStar3:GetToggleState()
    self.StarSelectList[1] = isOn
    self.StarSelectList[2] = isOn
    self.StarSelectList[3] = isOn
    self:RefreshDynamicTable()
end

function XUiRiftPluginBag:OnTogStar4Click()
    local isOn = self.TogStar4:GetToggleState()
    self.StarSelectList[4] = isOn
    self:RefreshDynamicTable()
end

function XUiRiftPluginBag:OnTogStar5Click()
    local isOn = self.TogStar5:GetToggleState()
    self.StarSelectList[5] = isOn
    self:RefreshDynamicTable()
end

function XUiRiftPluginBag:OnTogStar6Click()
    local isOn = self.TogStar6:GetToggleState()
    self.StarSelectList[6] = isOn
    self:RefreshDynamicTable()
end

function XUiRiftPluginBag:InitToggleList()
    self.StarSelectList = {true, true, true, true, true, true}
    for index, isSelect in ipairs(self.StarSelectList) do
        local tog = self["TogStar" .. index]
        if tog then
            local state = isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal
            tog:SetButtonState(state)
        end
    end
end

function XUiRiftPluginBag:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiRiftPluginGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftPluginBag:RefreshDynamicTable()
    self.SelectIndex = 1
    self.DataList = XDataCenter.RiftManager.GetAllPluginList(self.StarSelectList)
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
    local plugin = self.DataList[self.SelectIndex]
    self.PanelRiftPluginTips.gameObject:SetActiveEx(plugin ~= nil)
    if plugin == nil then
        return
    end

    self.TipsPluginGrid:Refresh(plugin)
    local isHave = plugin:GetHave()
    self.TxtPluginName.text = isHave and plugin:GetName() or XUiHelper.GetText("RiftUnlockPluginName") 
    self.PanelAdditionList.gameObject:SetActiveEx(isHave)
    self.TxtCoreExplain.gameObject:SetActiveEx(isHave)
    self.PanelEmpty.gameObject:SetActiveEx(not isHave)
    if isHave then
        self.TxtCoreExplain.text = plugin:GetDesc()

        -- 补正类型
        local fixTypeList = plugin:GetAttrFixTypeList()
        for i = 1, XRiftConfig.PluginMaxFixCnt do
            local isShow = #fixTypeList >= i
            self["PanelAddition" .. i].gameObject:SetActiveEx(isShow)
            if isShow then
                self["TxtAddition" .. i].text = fixTypeList[i]
            end
        end

        -- 补正效果
        local attrFixList = plugin:GetEffectStringList()
        for i = 1, XRiftConfig.PluginMaxFixCnt do
            local isShow = #attrFixList >= i
            self["PanelEntry" .. i].gameObject:SetActiveEx(isShow)
            if isShow then
                local attrFix = attrFixList[i]
                self["TxtEntry" .. i].text = attrFix.Name
                self["TxtEntryNum" .. i].text = attrFix.ValueString
            end
        end
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