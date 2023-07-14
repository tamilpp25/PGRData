local XUiGridActivityLink = require("XUi/XUiActivityBase/XUiGridActivityLink")
local XUiActivityBaseLink = XLuaUiManager.Register(XLuaUi, "UiActivityBaseLink")

function XUiActivityBaseLink:OnStart()
    self:InitDynamicTable()
    self:UpdateList()
    --local bg = self.BtnFirst.transform:Find("RImgBg"):GetComponent("RawImage")
    --bg:SetRawImage(CS.XGame.ClientConfig:GetString("ActivityLinkButtonBg"))
    self.BtnFirst:SetName(CS.XGame.ClientConfig:GetString("ActivityLinkButtonName"))
end

function XUiActivityBaseLink:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewLinkList)
    self.DynamicTable:SetProxy(XUiGridActivityLink)
    self.DynamicTable:SetDelegate(self)
end

function XUiActivityBaseLink:UpdateList()
    self.LinkDataList = XActivityConfigs.GetActivityLinkTemplate()
    self.DynamicTable:SetDataSource(self.LinkDataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiActivityBaseLink:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.LinkDataList[index])
    end
end
