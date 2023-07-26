local XUiPanelMultiDimRankList = XClass(nil, "XUiPanelMultiDimRankList")
local XUiGridMultiDimRank = require("XUi/XUiMultiDim/XUiGridMultiDimRank")

function XUiPanelMultiDimRankList:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitDynamicTable()
end

function XUiPanelMultiDimRankList:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiGridMultiDimRank)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiPanelMultiDimRankList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.RankingList and self.RankingList[index] then
            grid:Refresh(self.RankType, self.RankingList[index])
        end
    end
end

function XUiPanelMultiDimRankList:Refresh(rankType, themeId)
    self.RankType = rankType
    self.RankingList = XDataCenter.MultiDimManager.GetRankInfo(rankType, themeId)
    self.RootUi.PanelNoRank.gameObject:SetActiveEx(XTool.IsTableEmpty(self.RankingList))
    self.DynamicTable:SetDataSource(self.RankingList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiPanelMultiDimRankList:SetActivePanel(action)
    self.GameObject:SetActiveEx(action)
end

return XUiPanelMultiDimRankList