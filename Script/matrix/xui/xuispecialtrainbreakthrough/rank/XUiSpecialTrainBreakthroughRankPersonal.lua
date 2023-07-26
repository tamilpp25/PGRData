local XUiSpecialTrainBreakthroughRankPersonalGrid = require("XUi/XUiSpecialTrainBreakthrough/Rank/XUiSpecialTrainBreakthroughRankPersonalGrid")

---@class XUiSpecialTrainBreakthroughRankPersonal
local XUiSpecialTrainBreakthroughRankPersonal = XClass(nil, "XUiSpecialTrainBreakthroughRankPersonal")

function XUiSpecialTrainBreakthroughRankPersonal:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
    self.GridRank.gameObject:SetActiveEx(false)

    ---@type XUiSpecialTrainBreakthroughRankPersonalGrid
    self.UiPanelMine = XUiSpecialTrainBreakthroughRankPersonalGrid.New(self.PanelMyRank)
    self:InitDynamicTable()
    self._IsRequestUpdate = false
end

function XUiSpecialTrainBreakthroughRankPersonal:Update()
    if not self._IsRequestUpdate then
        self._IsRequestUpdate = true
        XDataCenter.FubenSpecialTrainManager.BreakthroughRequestRankPersonal()
    end
    local rankData = XDataCenter.FubenSpecialTrainManager.BreakthroughGetPersonalRankData()
    local rankInfos = rankData and rankData.SpecialTrainCubePersonRank and rankData.SpecialTrainCubePersonRank.RankInfos or {}
    self.DynamicTable:SetDataSource(rankInfos)
    self.DynamicTable:ReloadDataASync()
    self.UiPanelMine:Update(self:GetMyData())
    self.PanelNoRank.gameObject:SetActiveEx(#rankInfos <= 0)
end

function XUiSpecialTrainBreakthroughRankPersonal:GetMyData()
    local rankData = XDataCenter.FubenSpecialTrainManager.BreakthroughGetPersonalRankData() or {}
    local ranking = 0
    local score = 0
    local pointScore = 0
    if rankData then
        ranking = rankData.Ranking or 0
        score = rankData.Score or 0
        pointScore = rankData.PointScore or 0
    end
    
    ---@class SpecialTrainBreakthroughRankPersonalData
    local data = {
        Ranking = ranking,
        Name = XPlayer.Name,
        PointScore = pointScore,
        Score = score,
        HeadPortraitId = XPlayer.CurrHeadPortraitId, 
        HeadFrameId = XPlayer.CurrHeadFrameId,
    }
    return data
end

function XUiSpecialTrainBreakthroughRankPersonal:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRankingList)
    self.DynamicTable:SetProxy(XUiSpecialTrainBreakthroughRankPersonalGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiSpecialTrainBreakthroughRankPersonal:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    end
end

return XUiSpecialTrainBreakthroughRankPersonal