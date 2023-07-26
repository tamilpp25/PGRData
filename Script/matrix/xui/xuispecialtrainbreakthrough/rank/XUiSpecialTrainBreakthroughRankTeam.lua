local XUiSpecialTrainBreakthroughRankTeamGrid = require("XUi/XUiSpecialTrainBreakthrough/Rank/XUiSpecialTrainBreakthroughRankTeamGrid")

---@class XUiSpecialTrainBreakthroughRankTeam
local XUiSpecialTrainBreakthroughRankTeam = XClass(nil, "XUiSpecialTrainBreakthroughRankTeam")

function XUiSpecialTrainBreakthroughRankTeam:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    XTool.InitUiObject(self)
    self.GridRank.gameObject:SetActiveEx(false)

    ---@type XUiSpecialTrainBreakthroughRankTeamGrid
    self.UiPanelMine = XUiSpecialTrainBreakthroughRankTeamGrid.New(self.PanelMyRank)
    self:InitDynamicTable()
    self._IsRequestUpdate = false
end

function XUiSpecialTrainBreakthroughRankTeam:Update()
    if not self._IsRequestUpdate then
        self._IsRequestUpdate = true
        XDataCenter.FubenSpecialTrainManager.BreakthroughRequestRankTeam()
    end
    local rankData = XDataCenter.FubenSpecialTrainManager.BreakthroughGetTeamRankData() or {}
    local rankInfos = rankData and rankData.SpecialTrainCubeTeamRank and rankData.SpecialTrainCubeTeamRank.RankTeamInfos or {}
    self.DynamicTable:SetDataSource(rankInfos)
    self.DynamicTable:ReloadDataASync()
    self.UiPanelMine:Update(self:GetMyData())
    self.PanelNoRank.gameObject:SetActiveEx(#rankInfos <= 0)
end

function XUiSpecialTrainBreakthroughRankTeam:GetMyData()
    local rankData = XDataCenter.FubenSpecialTrainManager.BreakthroughGetTeamRankData() or {}
    local rankInfos = rankData and rankData.SpecialTrainCubeTeamRank and rankData.SpecialTrainCubeTeamRank.RankTeamInfos or {}
    local myRankData
    for i = 1, #rankInfos do
        local info = rankInfos[i]
        local memberInfos = info.MemberInfo
        for j = 1, #memberInfos do
            local memberInfo = memberInfos[j]
            if memberInfo.Id == XPlayer.Id then
                myRankData = info
                break
            end
        end
        if myRankData then
            break
        end
    end
    if not myRankData then
        ---@class SpecialTrainBreakthroughRankTeamData
        myRankData = {
            Ranking = 0,
            Round = 0,
            Score = 0,
            MemberInfo = {
                {
                    Id = XPlayer.Id,
                    HeadPortraitId = XPlayer.CurrHeadPortraitId,
                    HeadFrameId = XPlayer.CurrHeadFrameId,
                    Name = XPlayer.Name,
                }
            },
        }
    end
    return myRankData
end

function XUiSpecialTrainBreakthroughRankTeam:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelRankingList)
    self.DynamicTable:SetProxy(XUiSpecialTrainBreakthroughRankTeamGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiSpecialTrainBreakthroughRankTeam:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    end
end

return XUiSpecialTrainBreakthroughRankTeam