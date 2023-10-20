local XUiArchivePartner = XLuaUiManager.Register(XLuaUi, "UiArchivePartner")
local XUiGridArchivePartner = require("XUi/XUiArchive/XUiGridArchivePartner")
local Object = CS.UnityEngine.Object

function XUiArchivePartner:OnEnable()
    self:DynamicTableDataSync()
end

function XUiArchivePartner:OnStart()
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:InitTypeButton()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiArchivePartner:OnDestroy()
    
end

function XUiArchivePartner:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelArchivePartnerList)
    self.DynamicTable:SetProxy(XUiGridArchivePartner,self)
    self.DynamicTable:SetDelegate(self)
    self.GridArchivePartner.gameObject:SetActiveEx(false)
end

function XUiArchivePartner:SetupDynamicTable(type)
    self.PageDatas = self._Control:GetArchivePartnerList(type)
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync()
end

function XUiArchivePartner:DynamicTableDataSync()
    self.DynamicTable:ReloadDataSync()
end

function XUiArchivePartner:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas, index)
    end
end

function XUiArchivePartner:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
end

function XUiArchivePartner:InitTypeButton()
    self.GroupList = self._Control:GetPartnerGroupList()
    self.CurType = 1
    self.PartnerGroupBtn = {}
    for _, v in pairs(self.GroupList) do
        local btn = Object.Instantiate(self.BtnType)
        btn.gameObject:SetActive(true)
        btn.transform:SetParent(self.BtnContent.transform, false)
        local btncs = btn:GetComponent("XUiButton")
        local name = v.GroupName
        btncs:SetName(name or "")
        table.insert(self.PartnerGroupBtn, btncs)
    end
    self.BtnContent:Init(self.PartnerGroupBtn, function(index) self:SelectType(index) end)
    self.BtnType.gameObject:SetActiveEx(false)
    self.BtnContent:SelectIndex(self.CurType)
end

function XUiArchivePartner:SelectType(index)
    self.CurType = index
    self:SetupDynamicTable(self.GroupList[index].Id)
    self:PlayAnimation("QieHuan")
    self:ShowPartnerRateInfo(index)
end

function XUiArchivePartner:OnBtnBackClick()
    self:Close()
end

function XUiArchivePartner:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArchivePartner:ShowPartnerRateInfo(index)
    self.RateText.text = self.GroupList[index].GroupName
    self.RateNum.text = string.format("%d%s", self._Control:GetPartnerCompletionRate(self.GroupList[index].Id), "%")
end