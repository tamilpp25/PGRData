XUiPanelMedalListView = XClass(nil, "XUiPanelMedalListView")
local XUiGridNameplate = require("XUi/XUiNameplate/XUiGridNameplate")
function XUiPanelMedalListView:Ctor(ui, type, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Type = type
    self.Base = base
    XTool.InitUiObject(self)

    self:AddListener()
    self:InitDynamicTable()
end

function XUiPanelMedalListView:Refresh(screenType)
    self:SetupDynamicTable(screenType)
end


function XUiPanelMedalListView:AddListener()
    if self.Type == XMedalConfigs.ViewType.Collection then
        self.BtnEnterCollectionWall.CallBack = function()
            self:OnBtnEnterCollectionWallClick()
        end
    end
end

function XUiPanelMedalListView:OnBtnEnterCollectionWallClick()
    XLuaUiManager.Open("UiCollectionWall")
end


function XUiPanelMedalListView:InitDynamicTable()
    if self.Type == XMedalConfigs.ViewType.Medal then
        self.DynamicTable = XDynamicTableNormal.New(self.PanelMedalScroll)
        self.DynamicTable:SetProxy(XUiGridMedal)
        self.GridMedal.gameObject:SetActiveEx(false)
    elseif self.Type == XMedalConfigs.ViewType.Collection then
        self.DynamicTable = XDynamicTableNormal.New(self.PanelCollectionScroll)
        self.DynamicTable:SetProxy(XUiGridCollection)
        self.GridCollection.gameObject:SetActiveEx(false)
    elseif self.Type == XMedalConfigs.ViewType.Nameplate then
        self.DynamicTable = XDynamicTableNormal.New(self.PanelNameplateScroll)
        self.DynamicTable:SetProxy(XUiGridNameplate)
        self.GridNameplate.gameObject:SetActiveEx(false)
    end

    self.DynamicTable:SetDelegate(self)
end

function XUiPanelMedalListView:SetupDynamicTable(screenType)
    if self.Type == XMedalConfigs.ViewType.Medal then
        self.PageDatas = XDataCenter.MedalManager.GetMedals()
        self.Base.EmptyText.text = CS.XTextManager.GetText("NotHaveMedal")
    elseif self.Type == XMedalConfigs.ViewType.Collection then
        self.PageDatas = XDataCenter.MedalManager.GetScoreTitleByScreenType(screenType)
        self.Base.EmptyText.text = CS.XTextManager.GetText("NotHaveCollection")
    elseif self.Type == XMedalConfigs.ViewType.Nameplate then
        self.PageDatas = XDataCenter.MedalManager.GetNameplateGroupList()
        self.Base.EmptyText.text = CS.XTextManager.GetText("NotHaveNameplate")
    else
        return
    end

    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
    self.Base.PanelNone.gameObject:SetActiveEx(not next(self.PageDatas))
end

function XUiPanelMedalListView:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.Type == XMedalConfigs.ViewType.Medal then
            grid:UpdateGrid(self.PageDatas[index], self)
        elseif self.Type == XMedalConfigs.ViewType.Collection then
            grid:UpdateGrid(self.PageDatas[index], self, XDataCenter.MedalManager.InType.Normal)
        elseif self.Type == XMedalConfigs.ViewType.Nameplate then
            grid:UpdateData(self.PageDatas[index], true, true)
        end
    end
end