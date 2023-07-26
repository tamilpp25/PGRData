local XUiLoadingSet = XLuaUiManager.Register(XLuaUi, "UiLoadingSet")
local XUiGridCG = require("XUi/UiLoading/ChildItem/XUiGridCG")

function XUiLoadingSet:OnEnable()
    if XDataCenter.LoadingManager.GetCustomLoadingChanged() then
        XDataCenter.LoadingManager.SetCustomLoadingChanged()
        self:Refresh()
    end
end

function XUiLoadingSet:OnStart()
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:Refresh()
end

function XUiLoadingSet:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridCG)
    self.DynamicTable:SetDelegate(self)
    self.GridCGItem.gameObject:SetActiveEx(false)
end

function XUiLoadingSet:Refresh()
    self.LoadingList = XDataCenter.LoadingManager.GetCustomLoadingList()
    self.EntityList = {}

    self.SelectionDic = {}
    self.SelectCount = 0

    for _, v in ipairs(self.LoadingList) do
        table.insert(self.EntityList, XDataCenter.ArchiveManager.GetArchiveCgEntity(v))
        self.SelectionDic[v] = false
    end

    self:ShowSelectInfo()
    table.insert(self.EntityList, false)

    self:RefreshBtnState()
    self.DynamicTable:SetDataSource(self.EntityList)
    self.DynamicTable:ReloadDataSync()
end

function XUiLoadingSet:OnDynamicTableEvent(event, index, grid)
    local id = self.LoadingList[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateCg(self.EntityList[index])
        grid:SetSelect(self.SelectionDic[id])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if index > #self.LoadingList then
            XLuaUiManager.Open("UiLoadingOption")
        else
            self.LastSelectIndex = index
            self.SelectionDic[id] = not self.SelectionDic[id]
            self.SelectCount = self.SelectCount + (self.SelectionDic[id] and 1 or (-1))
            grid:SetSelect(self.SelectionDic[id])
            self:RefreshBtnState()
        end
    end
end

function XUiLoadingSet:RefreshBtnState()
    self.BtnPreview.gameObject:SetActiveEx(self.SelectCount == 1)
    self.BtnRemove.gameObject:SetActiveEx(self.SelectCount >= 1)
end

function XUiLoadingSet:SetButtonCallBack()
    self.BtnBack.CallBack = handler(self, self.OnBtnBackClick)
    self.BtnMainUi.CallBack = handler(self, self.OnBtnMainUiClick)

    self.BtnPreview.CallBack = handler(self, self.OnBtnPreviewClick)
    self.BtnRemove.CallBack = handler(self, self.OnBtnRemoveClick)
end

function XUiLoadingSet:OnBtnBackClick()
    self:Close()
end

function XUiLoadingSet:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiLoadingSet:OnBtnPreviewClick()
    XLuaUiManager.Open("UiArchiveCGDetail", self.EntityList, self.LastSelectIndex, XLoadingConfig.GetCustomUseSpine())
end

function XUiLoadingSet:OnBtnRemoveClick()
    XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("CustomLoadingRemoveTip"),
            XUiManager.DialogType.Normal, nil, handler(self, self.RemoveSelection))
end

function XUiLoadingSet:RemoveSelection()
    for i = #self.LoadingList, 1, -1 do
        if self.SelectionDic[self.LoadingList[i]] then
            table.remove(self.LoadingList, i)
        end
    end
    XDataCenter.LoadingManager.SaveCustomLoading(self.LoadingList)
    self:Refresh()
end

function XUiLoadingSet:ShowSelectInfo()
    self.SelectNum.text = string.format("%d/%d", #self.EntityList, XLoadingConfig.GetCustomMaxSize())
end