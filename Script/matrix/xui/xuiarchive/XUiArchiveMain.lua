local XUiArchiveMain = XLuaUiManager.Register(XLuaUi, "UiArchiveMain")

function XUiArchiveMain:OnEnable()
    self.ArchiveDatas = XDataCenter.ArchiveManager.GetArchives()
    for index, archive in pairs(self.ArchiveList) do
        archive:UpdateGrid(self.ArchiveDatas[index], self, index)
    end
end

function XUiArchiveMain:OnStart()
    self:SetButtonCallBack()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.ArchiveObj = {[XArchiveConfigs.SubSystemType.Monster] = self.GridArchive1,
        [XArchiveConfigs.SubSystemType.Weapon] = self.GridArchive2,
        [XArchiveConfigs.SubSystemType.Awareness] = self.GridArchive3,
        [XArchiveConfigs.SubSystemType.Story] = self.GridArchive4,
        [XArchiveConfigs.SubSystemType.CG] = self.GridArchive5,
        [XArchiveConfigs.SubSystemType.NPC] = self.GridArchive6,
        [XArchiveConfigs.SubSystemType.Email] = self.GridArchive7,
        [XArchiveConfigs.SubSystemType.Partner] = self.GridArchive8,
        [XArchiveConfigs.SubSystemType.PV] = self.GridArchive9 }

    self:InitArchiveList()
    XDataCenter.ArchiveManager.UpdateStoryData()
    XDataCenter.ArchiveManager.UpdateStoryNpcData()
    XDataCenter.ArchiveManager.UpdateMailAndCommunicationData()
end

function XUiArchiveMain:InitArchiveList()
    self.ArchiveList = {}
    for index, archiveObj in pairs(self.ArchiveObj) do
        self.ArchiveList[index] = XUiGridArchive.New(archiveObj)
        self.ArchiveList[index]:AddRedPointEvent(index)
    end
end

function XUiArchiveMain:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
end

function XUiArchiveMain:OnBtnBackClick()
    self:Close()
end

function XUiArchiveMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
