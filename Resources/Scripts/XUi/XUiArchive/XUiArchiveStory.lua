local XUiArchiveStory = XLuaUiManager.Register(XLuaUi, "UiArchiveStory")
local Object = CS.UnityEngine.Object

function XUiArchiveStory:OnEnable()
    self:DynamicTableDataSync()
end

function XUiArchiveStory:OnStart()
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:InitTypeButton()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiArchiveStory:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridArchiveStory)
    self.DynamicTable:SetDelegate(self)
    self.GridStoryItem.gameObject:SetActiveEx(false)
end

function XUiArchiveStory:SetupDynamicTable(type)
    self.PageDatas = XDataCenter.ArchiveManager.GetArchiveStoryChapterList(type)
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiArchiveStory:DynamicTableDataSync()
    self.DynamicTable:ReloadDataSync()
end

function XUiArchiveStory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas, self, index)
    end
end

function XUiArchiveStory:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
end

function XUiArchiveStory:InitTypeButton()
    self.GroupList = XDataCenter.ArchiveManager.GetArchiveStoryGroupList()
    self.CurType = 1
    self.StoryGroupBtn = {}
    for _, v in pairs(self.GroupList) do
        local btn = Object.Instantiate(self.BtnTabShortNew)
        btn.gameObject:SetActive(true)
        btn.transform:SetParent(self.TabBtnContent.transform, false)
        local btncs = btn:GetComponent("XUiButton")
        local name = v.Name
        btncs:SetName(name or "Null")

        table.insert(self.StoryGroupBtn, btncs)
    end
    self.TabBtnContent:Init(self.StoryGroupBtn, function(index) self:SelectType(index) end)
    self.BtnTabShortNew.gameObject:SetActiveEx(false)
    self.TabBtnContent:SelectIndex(self.CurType)
end

function XUiArchiveStory:SelectType(index)
    self.CurType = index
    self:SetupDynamicTable(self.GroupList[index].Id)
    self:PlayAnimation("QieHuan")
    self:ShowStoryRateInfo(index)
end

function XUiArchiveStory:OnBtnBackClick()
    self:Close()
end

function XUiArchiveStory:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArchiveStory:ShowStoryRateInfo(index)
    local count = 0
    local maxCount = #self.PageDatas
    for _,data in pairs(self.PageDatas) do
        if not data:GetIsLock() then
            count = count + 1
        end
    end
    self.TxtHaveCollectNum.text = count
    self.TxtMaxCollectNum.text = maxCount
    self.TitleText.text = self.GroupList[index].Name
end

function XUiArchiveStory:OnCheckArchiveRedPoint()

end

function XUiArchiveStory:OnCheckArchiveTag()

end