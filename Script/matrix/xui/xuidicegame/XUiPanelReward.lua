local XUiGridReward = require("XUi/XUiDiceGame/XUiGridReward")
local XUiPanelReward = XClass(nil, "XUiPanelReward")

local TWEEN_TIME_SCORE = 0.5
local FULL_PROGRESS = 0.9 --缩小实际显示进度,让进度条在最后一个奖励后有一定余长.

function XUiPanelReward:Ctor(ui, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform ---@type UnityEngine.Transform
    self.Root = root
    XTool.InitUiObject(self)

    self.ImgProgressBgRect = self.ImgProgressBg:GetComponent("RectTransform") ---@type UnityEngine.RectTransform
    self.ImgProgressFilledRect = self.ImgProgressFilled:GetComponent("RectTransform") ---@type UnityEngine.RectTransform
    self.GridReward = self.GridReward.gameObject
    self.GridReward:SetActiveEx(false)
    self.GridRewardOriPos = self.GridReward.transform.localPosition
    self.Transform:Find("SViewCourse"):GetComponent("ScrollRect").enabled = false

    self.Progress = 0
    self.RewardGrids = {}

    self:UpdatePanel(true)
    self:UpdateGridPosition()
end

function XUiPanelReward:UpdatePanel(isInit)
    local manager = XDataCenter.DiceGameManager
    local lastScore = manager.GetLastScore()
    local curScore = manager.GetScore()
    local maxScore = manager.GetMaxScore()

    local deltaScore = curScore - lastScore
    XUiHelper.Tween(TWEEN_TIME_SCORE, function(t)
        if self.TxtScore:Exist() then
            self.TxtScore.text = tostring(math.floor(lastScore + deltaScore* t))
        end
    end)

    if isInit then
        self.ImgProgressFilled.fillAmount = 0
        for i = 1, XDiceGameConfigs.GetRewardCount() do
            local gridGo = CSObjectInstantiate(self.GridReward, self.GridRewardContainer.transform) ---@type UnityEngine.GameObject
            local grid = XUiGridReward.New(gridGo, self.Root, i)
            gridGo:SetActiveEx(true)
            self.RewardGrids[i] = grid
        end
    end

    self.Progress = curScore / maxScore * FULL_PROGRESS
    self.Progress = self.Progress >= FULL_PROGRESS and 1.0 or self.Progress
    self.ImgProgressFilled:DOFillAmount(self.Progress, TWEEN_TIME_SCORE)

    for i = 1, #self.RewardGrids do
        self.RewardGrids[i]:UpdateView(curScore)
    end
end

function XUiPanelReward:UpdateGridPosition()
    local maxScore = XDataCenter.DiceGameManager.GetMaxScore()
    local width = self.ImgProgressBgRect.rect.size.x
    for i = 1, #self.RewardGrids do
        self.RewardGrids[i]:UpdatePosition(maxScore, width * FULL_PROGRESS, self.GridRewardOriPos)
    end
end

return XUiPanelReward