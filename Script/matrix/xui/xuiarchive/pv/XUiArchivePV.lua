local XUiArchivePVGrid = require("XUi/XUiArchive/PV/XUiArchivePVGrid")

local XUiArchivePV = XLuaUiManager.Register(XLuaUi, "UiArchivePV")

function XUiArchivePV:OnEnable()
    self:DynamicTableDataSync()
end

function XUiArchivePV:OnStart()
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:InitTypeButton()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiArchivePV:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiArchivePVGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridPVItem.gameObject:SetActiveEx(false)
end

function XUiArchivePV:SetupDynamicTable(groupId)
    self.DetailIdList = XArchiveConfigs.GetPVDetailIdList(groupId)
    self.DynamicTable:SetDataSource(self.DetailIdList)
    self.DynamicTable:ReloadDataSync()
end

function XUiArchivePV:DynamicTableDataSync()
    self.DynamicTable:ReloadDataSync()
end

function XUiArchivePV:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.DetailIdList[index])
    end
end

function XUiArchivePV:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
end

function XUiArchivePV:InitTypeButton()
    self.GroupList = XArchiveConfigs.GetPVGroups()
    self.CurType = 1
    self.PVGroupBtn = {}
    for _, v in pairs(self.GroupList) do
        local btn = XUiHelper.Instantiate(self.BtnTabShortNew, self.TabBtnContent.transform)
        btn.gameObject:SetActive(true)
        local btncs = btn:GetComponent("XUiButton")
        btncs:SetName(v.Name or "")
        btn:ShowReddot(false)

        table.insert(self.PVGroupBtn, btncs)
    end
    self.TabBtnContent:Init(self.PVGroupBtn, function(index) self:SelectType(index) end)
    self.BtnTabShortNew.gameObject:SetActiveEx(false)
    self.TabBtnContent:SelectIndex(self.CurType)
end

function XUiArchivePV:SelectType(index)
    self.CurType = index
    self:SetupDynamicTable(self.GroupList[index].Id)
    self:PlayAnimation("QieHuan")
    self:ShowPVRateInfo(index)
end

function XUiArchivePV:OnBtnBackClick()
    self:Close()
end

function XUiArchivePV:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArchivePV:ShowPVRateInfo(index)
    self.RateNum.text = string.format("%d%s", XDataCenter.ArchiveManager.GetPVCompletionRate(self.GroupList[index].Id), "%")
end