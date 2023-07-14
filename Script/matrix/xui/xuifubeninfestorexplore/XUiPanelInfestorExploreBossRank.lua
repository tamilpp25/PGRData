local XUiGridInfestorExploreRank = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreRank")
local XUiGridInfestorExploreRegionTitle = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreRegionTitle")

local tableInsert = table.insert
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiPanelInfestorExploreBossRank = XClass(nil, "XUiPanelInfestorExploreBossRank")

function XUiPanelInfestorExploreBossRank:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RankGrids = {}
    XTool.InitUiObject(self)
    self.GridRegionTitle.gameObject:SetActiveEx(false)
    self.GridArenaTeamRank.gameObject:SetActiveEx(false)
end

function XUiPanelInfestorExploreBossRank:Refresh(rewardId, chapterId, nodeId)
    local upList = {}
    local keepList = {}
    local downList = {}

    local upNum = XDataCenter.FubenInfestorExploreManager.GetDiffUpNum()
    local keepNum = XDataCenter.FubenInfestorExploreManager.GetDiffKeepNum()
    local downNum = XDataCenter.FubenInfestorExploreManager.GetDiffDownNum()
    local upIndex = upNum
    local keepIndex = upNum + keepNum
    local rankIndexList = XDataCenter.FubenInfestorExploreManager.GetPlayerRankIndexList()
    for _, index in ipairs(rankIndexList) do
        local player = XDataCenter.FubenInfestorExploreManager.GetPlayerRankData(index)
        if player:GetScore() == 0 then
            if downNum > 0 then
                tableInsert(downList, index)
            else
                tableInsert(keepList, index)
            end
        else
            if index <= upIndex then
                tableInsert(upList, index)
            elseif index <= keepIndex then
                tableInsert(keepList, index)
            else
                tableInsert(downList, index)
            end
        end
    end

    local gridIndex = 0

    --晋级区
    local region = XFubenInfestorExploreConfigs.Region.UpRegion
    self.UpGrid = self.UpGrid or XUiGridInfestorExploreRegionTitle.New(CSUnityEngineObjectInstantiate(self.GridRegionTitle, self.PanelContent))
    if upNum == 0 then
        self.UpGrid.GameObject:SetActiveEx(false)
    else
        local rewardId = XDataCenter.FubenInfestorExploreManager.GetCurGroupRankRegionRewardList(_, region)
        self.UpGrid:Refresh(region, rewardId)
        self.UpGrid.GameObject:SetActiveEx(true)
        self.UpGrid.Transform:SetAsLastSibling()
        for _, rankIndex in ipairs(upList) do
            gridIndex = gridIndex + 1
            local rankGrid = self.RankGrids[gridIndex]
            if not rankGrid then
                rankGrid = XUiGridInfestorExploreRank.New(CSUnityEngineObjectInstantiate(self.GridArenaTeamRank, self.PanelContent))
                self.RankGrids[gridIndex] = rankGrid
            end
            rankGrid:Refresh(rankIndex)
            rankGrid.GameObject:SetActiveEx(true)
            rankGrid.Transform:SetAsLastSibling()
        end
    end

    --保级区
    local region = XFubenInfestorExploreConfigs.Region.KeepRegion
    local rewardId = XDataCenter.FubenInfestorExploreManager.GetCurGroupRankRegionRewardList(_, region)
    self.KeepGrid = self.KeepGrid or XUiGridInfestorExploreRegionTitle.New(CSUnityEngineObjectInstantiate(self.GridRegionTitle, self.PanelContent))
    self.KeepGrid:Refresh(region, rewardId)
    self.KeepGrid.GameObject:SetActiveEx(true)
    self.KeepGrid.Transform:SetAsLastSibling()
    for _, rankIndex in ipairs(keepList) do
        gridIndex = gridIndex + 1
        local rankGrid = self.RankGrids[gridIndex]
        if not rankGrid then
            rankGrid = XUiGridInfestorExploreRank.New(CSUnityEngineObjectInstantiate(self.GridArenaTeamRank, self.PanelContent))
            self.RankGrids[gridIndex] = rankGrid
        end
        rankGrid:Refresh(rankIndex)
        rankGrid.GameObject:SetActiveEx(true)
        rankGrid.Transform:SetAsLastSibling()
    end

    --降级区
    local region = XFubenInfestorExploreConfigs.Region.DownRegion
    self.DownGrid = self.DownGrid or XUiGridInfestorExploreRegionTitle.New(CSUnityEngineObjectInstantiate(self.GridRegionTitle, self.PanelContent))
    if downNum == 0 then
        self.DownGrid.GameObject:SetActiveEx(false)
    else
        local rewardId = XDataCenter.FubenInfestorExploreManager.GetCurGroupRankRegionRewardList(_, region)
        self.DownGrid.GameObject:SetActiveEx(true)
        self.DownGrid:Refresh(region, rewardId)
        self.DownGrid.Transform:SetAsLastSibling()
        for _, rankIndex in ipairs(downList) do
            gridIndex = gridIndex + 1
            local rankGrid = self.RankGrids[gridIndex]
            if not rankGrid then
                rankGrid = XUiGridInfestorExploreRank.New(CSUnityEngineObjectInstantiate(self.GridArenaTeamRank, self.PanelContent))
                self.RankGrids[gridIndex] = rankGrid
            end
            rankGrid:Refresh(rankIndex)
            rankGrid.GameObject:SetActiveEx(true)
            rankGrid.Transform:SetAsLastSibling()
        end
    end

    for index = gridIndex + 1, #self.RankGrids do
        self.RankGrids.GameObject:SetActiveEx(false)
    end
end

return XUiPanelInfestorExploreBossRank