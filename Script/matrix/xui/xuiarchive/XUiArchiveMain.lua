local XUiArchiveMain = XLuaUiManager.Register(XLuaUi, "UiArchiveMain")

function XUiArchiveMain:OnEnable()
    self.ArchiveDatas = self._Control:GetArchives()
    for index, archive in pairs(self.ArchiveList) do
        archive:UpdateGrid(self.ArchiveDatas[index], self, index)
    end
end

function XUiArchiveMain:OnStart()
    self:SetButtonCallBack()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.ArchiveObj = {[XEnumConst.Archive.SubSystemType.Monster] = self.GridArchive1,
        [XEnumConst.Archive.SubSystemType.Weapon] = self.GridArchive2,
        [XEnumConst.Archive.SubSystemType.Awareness] = self.GridArchive3,
        [XEnumConst.Archive.SubSystemType.Story] = self.GridArchive4,
        [XEnumConst.Archive.SubSystemType.CG] = self.GridArchive5,
        [XEnumConst.Archive.SubSystemType.NPC] = self.GridArchive6,
        [XEnumConst.Archive.SubSystemType.Email] = self.GridArchive7,
        [XEnumConst.Archive.SubSystemType.Partner] = self.GridArchive8,
        [XEnumConst.Archive.SubSystemType.PV] = self.GridArchive9 }

    self:InitArchiveList()
    self._Control:UpdateStoryData()
    self._Control:UpdateStoryNpcData()
    self._Control:UpdateMailAndCommunicationData()
end

function XUiArchiveMain:InitArchiveList()
    self.ArchiveList = {}
    for index, archiveObj in pairs(self.ArchiveObj) do
        self.ArchiveList[index] = XUiGridArchive.New(archiveObj,self,index)
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
