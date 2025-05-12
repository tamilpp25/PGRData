local XUiGridCollection = require("XUi/XUiMedal/XUiGridCollection")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiAchvCollectionDTable = XClass(nil, "XUiAchvCollectionDTable")

function XUiAchvCollectionDTable:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.GridCollection.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
    self:InitBtnEnterCollectionWall()
end

function XUiAchvCollectionDTable:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    --local gridProxy = require("XUi/XUiSuperSmashBros/Character/Grids/XUiSSBCharacterGrid")
    self.DynamicTable:SetProxy(XUiGridCollection)
    self.DynamicTable:SetDelegate(self)
end

function XUiAchvCollectionDTable:InitBtnEnterCollectionWall()
    self.BtnEnterCollectionWall.CallBack = function()
        self:OnBtnEnterCollectionWallClick()
    end
end

function XUiAchvCollectionDTable:OnBtnEnterCollectionWallClick()
    XLuaUiManager.Open("UiCollectionWall")
end
--================
--动态列表事件
--================
function XUiAchvCollectionDTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.DataList[index], self, XDataCenter.MedalManager.InType.Normal)
    end
end
--================
--刷新动态列表
--================
function XUiAchvCollectionDTable:Refresh(screenType)
    self.DataList = XDataCenter.MedalManager.GetScoreTitleByScreenType(screenType)
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
    self.PanelNone.gameObject:SetActiveEx(not next(self.DataList))
    self.EmptyText.text = CS.XTextManager.GetText("NotHaveCollection")
end

return XUiAchvCollectionDTable