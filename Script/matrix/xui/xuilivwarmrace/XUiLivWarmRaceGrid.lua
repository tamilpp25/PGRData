local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local CSXTextManagerGetText = CS.XTextManager.GetText

--挑战目标弹窗的格子
local XUiLivWarmRaceGrid = XClass(nil, "XUiLivWarmRaceGrid")

function XUiLivWarmRaceGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self:AutoAddListener()
    self.GridList = {}
end

function XUiLivWarmRaceGrid:Init(rootUi)
    self.RootUi = rootUi
end

function XUiLivWarmRaceGrid:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnFinish, self.OnBtnFinishClick)
end

function XUiLivWarmRaceGrid:Refresh(targetId, curStarCount)
    self.targetId = targetId
    self.CurStarCount = curStarCount

    local targetCount = XLivWarmRaceConfigs.GetChallegneTarget(targetId)
    curStarCount = math.min(curStarCount, targetCount)
    self.TxtTaskNumStar.text = CSXTextManagerGetText("AlreadyobtainedCount", curStarCount, targetCount)

    local rewardId = XLivWarmRaceConfigs.GetChallegneTargetRewardId(targetId)
    local rewards = XRewardManager.GetRewardList(rewardId)
    for i, item in ipairs(rewards) do
        local grid = self.GridList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            grid = XUiGridCommon.New(self.RootUi, ui)
            grid.Transform:SetParent(self.Content, false)
            self.GridList[i] = grid
        end
        grid:Refresh(item)
        grid.GameObject:SetActive(true)
    end

    for j = #rewards + 1, #self.GridList do
        self.GridList[j].GameObject:SetActive(false)
    end
    
    self:UpdateBtnFinish()
end

function XUiLivWarmRaceGrid:UpdateBtnFinish()
    local targetId = self.targetId
    local curStarCount = self.CurStarCount
    local targetCount = XLivWarmRaceConfigs.GetChallegneTarget(targetId)
    local isOverReward = XDataCenter.LivWarmRaceManager.IsHadTokenChallengeTarget(targetId)
    local isCanReward = curStarCount >= targetCount
    self.BtnFinish:SetDisable(not isCanReward, isCanReward)
    self.BtnFinish.gameObject:SetActiveEx(not isOverReward)
    self.BtnReceiveHave.gameObject:SetActiveEx(isOverReward)
end

function XUiLivWarmRaceGrid:OnBtnFinishClick()
    local targetId = self.targetId
    XDataCenter.LivWarmRaceManager.RequestRunGameGetChallengeTargetReward(targetId, handler(self, self.UpdateBtnFinish))
end

return XUiLivWarmRaceGrid