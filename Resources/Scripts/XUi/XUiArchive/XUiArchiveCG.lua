local XUiArchiveCG = XLuaUiManager.Register(XLuaUi, "UiArchiveCG")
local Object = CS.UnityEngine.Object

function XUiArchiveCG:OnEnable()
    self:DynamicTableDataSync()
end

function XUiArchiveCG:OnStart()
    self.CGIndex = {}
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:InitTypeButton()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiArchiveCG:OnDestroy()
    XDataCenter.ArchiveManager.ClearCGRedPointByGroup()
end

function XUiArchiveCG:InitRedPoint(btn,type)
    XRedPointManager.AddRedPointEvent(btn,
        function (_,count)
            btn:ShowReddot(count >= 0)
        end, self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_CG_TYPE_RED },
        type)
end

function XUiArchiveCG:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridArchiveCG)
    self.DynamicTable:SetDelegate(self)
    self.GridCGItem.gameObject:SetActiveEx(false)
end

function XUiArchiveCG:SetupDynamicTable(type)
    self.PageDatas = XDataCenter.ArchiveManager.GetArchiveCGDetailList(type)
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
end

function XUiArchiveCG:DynamicTableDataSync()
    self.DynamicTable:ReloadDataSync()
end

function XUiArchiveCG:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas, self, index)
    end
end

function XUiArchiveCG:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
end

function XUiArchiveCG:InitTypeButton()
    self.GroupList = XDataCenter.ArchiveManager.GetArchiveCGGroupList()
    self.CurType = 1
    self.CGGroupBtn = {}
    for _, v in pairs(self.GroupList) do
        local btn = Object.Instantiate(self.BtnTabShortNew)
        btn.gameObject:SetActive(true)
        btn.transform:SetParent(self.TabBtnContent.transform, false)
        local btncs = btn:GetComponent("XUiButton")
        local name = v.Name
        btncs:SetName(name or "")

        table.insert(self.CGGroupBtn, btncs)
        self:InitRedPoint(btncs,v.Id)
    end
    self.TabBtnContent:Init(self.CGGroupBtn, function(index) self:SelectType(index) end)
    self.BtnTabShortNew.gameObject:SetActiveEx(false)
    self.TabBtnContent:SelectIndex(self.CurType)
end

function XUiArchiveCG:SelectType(index)
    self.CurType = index
    self:SetupDynamicTable(self.GroupList[index].Id)
    self:PlayAnimation("QieHuan")
    self:ShowCGRateInfo(index)

    if self.OldType then
        XDataCenter.ArchiveManager.ClearCGRedPointByGroup(self.GroupList[self.OldType].Id)
    end

    self.OldType = index
end

function XUiArchiveCG:OnBtnBackClick()
    self:Close()
end

function XUiArchiveCG:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArchiveCG:ShowCGRateInfo(index)
    self.TxtCollectionDesc.text = self.GroupList[index].Name
    self.RateNum.text = string.format("%d%s", XDataCenter.ArchiveManager.GetCGCompletionRate(self.GroupList[index].Id), "%")
end