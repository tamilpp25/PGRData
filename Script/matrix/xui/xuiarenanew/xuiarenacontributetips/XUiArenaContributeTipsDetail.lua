local XUiArenaContributeTipsContributeGrid = require(
    "XUi/XUiArenaNew/XUiArenaContributeTips/XUiArenaContributeTipsContributeGrid")
local XUiArenaContributeTipsTitleGrid =
    require("XUi/XUiArenaNew/XUiArenaContributeTips/XUiArenaContributeTipsTitleGrid")

---@class XUiArenaContributeTipsDetail : XUiNode
---@field PanelTitle UnityEngine.RectTransform
---@field ListContribute UnityEngine.RectTransform
---@field GridContribute UnityEngine.RectTransform
---@field ListTitle UnityEngine.RectTransform
---@field _Control XArenaControl
local XUiArenaContributeTipsDetail = XClass(XUiNode, "XUiArenaContributeTipsDetail")

-- region 生命周期

function XUiArenaContributeTipsDetail:OnStart(challengeId)
    ---@type XUiArenaContributeTipsContributeGrid[]
    self._GridList = {}
    ---@type XUiArenaContributeTipsTitleGrid[]
    self._TitleGridList = {}
    self._CurrentChallengeId = challengeId

    self:_InitUi()
end

function XUiArenaContributeTipsDetail:OnEnable()
    self:_RefreshTips()
    self:_RefreshContribute()
end

-- endregion

function XUiArenaContributeTipsDetail:Refresh(challengeId)
    if XTool.IsNumberValid(challengeId) then
        self._CurrentChallengeId = challengeId
        self:_RefreshContribute()
    end
end

-- region 私有方法

function XUiArenaContributeTipsDetail:_RefreshTips()
    if XTool.IsTableEmpty(self._TitleGridList) then
        local panelTitle = XUiHelper.Instantiate(self.PanelTitle, self.ListTitle)

        self._TitleGridList[1] = XUiArenaContributeTipsTitleGrid.New(self.PanelTitle, self)
        self._TitleGridList[2] = XUiArenaContributeTipsTitleGrid.New(panelTitle, self)
    end

    local challengeId = self._CurrentChallengeId
    local upRank = self._Control:GetChallengeDanUpRankByChallengeId(challengeId)
    local contributeScore = self._Control:GetChallengeDanUpRankCostContributeScoreById(challengeId)

    self._TitleGridList[1]:Refresh(XUiHelper.GetText("ArenaMeritPoints"),
        XUiHelper.ReadTextWithNewLine("ContributeScoreDesc"))
    self._TitleGridList[2]:Refresh(XUiHelper.GetText("ArenaReputationPoints"), XUiHelper.GetText(
        "ArenaActivityUpRegionContributeScoreDes", upRank, contributeScore))
end

function XUiArenaContributeTipsDetail:_RefreshContribute()
    local contributeScores = self._Control:GetChallengeContributeScoreById(self._CurrentChallengeId)

    for i, contributeScore in pairs(contributeScores) do
        local grid = self._GridList[i]

        if not grid then
            local gridObject = XUiHelper.Instantiate(self.GridContribute, self.ListContribute)

            grid = XUiArenaContributeTipsContributeGrid.New(gridObject, self)
            self._GridList[i] = grid
        end

        grid:Open()
        grid:Refresh(i, contributeScore)
    end
    for i = #contributeScores + 1, #self._GridList do
        self._GridList[i]:Close()
    end
end

function XUiArenaContributeTipsDetail:_InitUi()
    self.GridContribute.gameObject:SetActiveEx(false)
end

-- endregion

return XUiArenaContributeTipsDetail
