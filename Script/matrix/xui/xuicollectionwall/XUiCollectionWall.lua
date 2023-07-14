local XUiCollectionWall = XLuaUiManager.Register(XLuaUi, "UiCollectionWall")

local XUiGridCollectionWall = require("XUi/XUiCollectionWall/XUiCollectionWallGrid/XUiGridCollectionWall")

function XUiCollectionWall:OnStart()
    self:InitComponent()
    self:AddListener()
end

function XUiCollectionWall:OnEnable()
    self:Refresh()
end

function XUiCollectionWall:Refresh()
    self:SetupDynamicTable()
end

function XUiCollectionWall:InitComponent()
    self.AssetPanel = XUiPanelAsset.New(
            self,
            self.PanelAsset,
            XDataCenter.ItemManager.ItemId.FreeGem,
            XDataCenter.ItemManager.ItemId.ActionPoint,
            XDataCenter.ItemManager.ItemId.Coin
    )

    self.PanelNoneTemplate.gameObject:SetActiveEx(false)
    self.GridCollectionWall.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiCollectionWall:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridCollectionWall, self, XCollectionWallConfigs.EnumWallGridOpenType.Overview)
    self.DynamicTable:SetDelegate(self)
end

function XUiCollectionWall:SetupDynamicTable()
    self.PageDatas = XDataCenter.CollectionWallManager.GetWallEntityList()
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(#self.PageDatas)
end

function XUiCollectionWall:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index])
    end
end

function XUiCollectionWall:AddListener()
    self.BtnDisplySetting.CallBack = function()
        self:OnBtnDisplaySettingClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self:BindHelpBtn(self.BtnHelp, "CollectionWall")
end

function XUiCollectionWall:OnBtnDisplaySettingClick()
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_PLAYER_SETTING)
end

function XUiCollectionWall:OnBtnBackClick()
    self:Close()
    XDataCenter.CollectionWallManager.ClearLocalCaptureCache()
end

function XUiCollectionWall:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
    XDataCenter.CollectionWallManager.ClearLocalCaptureCache()
end