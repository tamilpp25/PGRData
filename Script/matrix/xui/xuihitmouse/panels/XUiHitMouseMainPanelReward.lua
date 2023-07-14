
local XUiHitMouseMainPanelReward = {}

local function RefreshProgress(panel, maxScore)
    local totalScore = maxScore
    if not maxScore then
        local scores = XDataCenter.HitMouseManager.GetRewardScores()
        totalScore = scores[#scores]
    end
    local currentScore = XDataCenter.HitMouseManager.GetCurrentScores()
    panel.ImgProgressFilled.fillAmount = currentScore / (totalScore > 0 and totalScore or 1)
end

local function InitRewards(panel)
    local scores = XDataCenter.HitMouseManager.GetRewardScores()
    local rewardIds = XDataCenter.HitMouseManager.GetRewardIds()
    local XGrid = require("XUi/XUiHitMouse/Entities/XUiHitMousePanelRewardGrid")
    local maxScore = 0
    for _, score in pairs(scores) do
        maxScore = score
    end
    panel.GridCourse.gameObject:SetActiveEx(false)
    panel.Grids = {}
    local addScore = 0
    for index, score in pairs(scores) do
        local go = XUiHelper.Instantiate(panel.GridCourse, panel.ImgProgressBg.transform)
        if go then
            local newGrid = XGrid.New(go)
            newGrid:SetData(index, rewardIds[index], score, maxScore, panel.ImgProgressBg.rect.width)
            newGrid:Show()
            panel.Grids[index] = newGrid
        end
    end
    RefreshProgress(panel, maxScore)
end

function XUiHitMouseMainPanelReward.Init(ui)
    ui.RewardPanel = {}
    XTool.InitUiObjectByUi(ui.RewardPanel, ui.PanelReward)
    InitRewards(ui.RewardPanel)
end

function XUiHitMouseMainPanelReward.OnRewardRefresh(ui)
    for _, grid in pairs(ui.RewardPanel.Grids or {}) do
        grid:RefreshIcon()
    end
    RefreshProgress(ui.RewardPanel)
end

return XUiHitMouseMainPanelReward