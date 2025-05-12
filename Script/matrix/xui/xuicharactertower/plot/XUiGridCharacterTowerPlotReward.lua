local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridCharacterTowerPlotReward
local XUiGridCharacterTowerPlotReward = XClass(nil, "XUiGridCharacterTowerPlotReward")

function XUiGridCharacterTowerPlotReward:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnFinish, self.OnBtnFinishClick)
end

function XUiGridCharacterTowerPlotReward:Refresh(stageId, chapterId)
    self.StageId = stageId
    self.ChapterId = chapterId
    ---@type XCharacterTowerChapter
    self.ChapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
    
    self:RefreshReward()
    self:RefreshStatus()
end

function XUiGridCharacterTowerPlotReward:RefreshReward()
    -- 描述
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtOrder.text = stageCfg.Name
    -- 奖励
    self.RewardGrid = self.RewardGrid or {}
    local rewardId = stageCfg.FirstRewardShow
    local rewards = XRewardManager.GetRewardList(rewardId)
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.RewardGrid[i]
        if not grid then
            local go = i == 1 and self.PanelReward or XUiHelper.Instantiate(self.PanelReward, self.UiContent)
            grid = XUiGridCommon.New(self.RootUi.RootUi, go)
            self.RewardGrid[i] = grid
        end
        grid:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.RewardGrid do
        self.RewardGrid[i].GameObject:SetActiveEx(false)
    end
end

function XUiGridCharacterTowerPlotReward:RefreshStatus()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local chapterInfo = self.ChapterViewModel:GetChapterInfo()
    if stageInfo.Passed then
        if chapterInfo:CheckStageRewardReceived(self.StageId) then
            -- 领过了
            self:ChangeCollectStatus(false, true, false)
        else
            -- 没有领取
            self:ChangeCollectStatus(true, false, false)
        end
    else
        -- 没有完成
        self:ChangeCollectStatus(false, false, true)
    end
end

function XUiGridCharacterTowerPlotReward:ChangeCollectStatus(finish, alreadyFinish, unfinished)
    self.BtnFinish.gameObject:SetActive(finish)
    self.ImgAlreadyFinish.gameObject:SetActive(alreadyFinish)
    self.ImgUnFinish.gameObject:SetActive(unfinished)
end

function XUiGridCharacterTowerPlotReward:OnBtnFinishClick()
    if not self.StageId or not self.ChapterId then
        return
    end
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local chapterInfo = self.ChapterViewModel:GetChapterInfo()
    if stageInfo.Passed and not chapterInfo:CheckStageRewardReceived(self.StageId) then
        XDataCenter.CharacterTowerManager.CharacterTowerGetStageRewardRequest(self.ChapterId, self.StageId, function(rewards)
            XUiManager.OpenUiObtain(rewards, nil, function()
                self.RootUi:OnRewardTaskFinish()
            end, nil)
        end)
    end
end

return XUiGridCharacterTowerPlotReward