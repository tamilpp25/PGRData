local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiEpicFashionGachaStageDetail = XLuaUiManager.Register(XLuaUi, "UiEpicFashionGachaStageDetail")

function XUiEpicFashionGachaStageDetail:OnAwake()
    self.GridList = {}
    self:InitButton()
end

function XUiEpicFashionGachaStageDetail:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnMask, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self.OnBtnEnterClick)
end

function XUiEpicFashionGachaStageDetail:OnStart(stageId)
    self.StageId = stageId
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.StageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
end

function XUiEpicFashionGachaStageDetail:OnEnable()
    local stageCfg = self.StageCfg
    self.TxtStoryName.text = stageCfg.Name
    self.TxtStoryDec.text = stageCfg.Description
    self.RImgStory:SetRawImage(stageCfg.StoryIcon)
    local config = XMVCA.XFuben:GetStageVoiceTip()[self.StageId]
    self.PanelSound.gameObject:SetActiveEx(config)
    self.TextSound.text = config and config.Text
    -- 按钮名字
    local isFight = stageCfg.StageType == XDataCenter.FubenFestivalActivityManager.StageFuben
    local btnName = isFight and CS.XTextManager.GetText("StartFight") or CS.XTextManager.GetText("StartPlay")
    self.BtnEnter:SetNameByGroup(0, btnName)

    -- 奖励
    local rewardId = self.StageCfg.FirstRewardShow
    self.PanelReward.gameObject:SetActiveEx(XTool.IsNumberValid(rewardId))
    -- 首通
    local isPassed = self.StageInfo.Passed

    local rewards = {}
    if rewardId > 0 then
        rewards = XRewardManager.GetRewardList(rewardId)
    end
    if rewards then
        for i, item in ipairs(rewards) do
            local grid = self.GridList[i]
            if not grid then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridRewards, self.GridRewards.parent)
                grid = XUiGridCommon.New(self, ui)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid:SetReceived(isPassed)
            grid.GameObject:SetActive(true)
        end
    end
    self.GridRewards.gameObject:SetActive(false)
end

function XUiEpicFashionGachaStageDetail:PlayStoryId(movieId)
    XDataCenter.MovieManager.PlayMovie(movieId)
end

function XUiEpicFashionGachaStageDetail:OnBtnEnterClick()
    local stageCfg = self.StageCfg
    local stageType = stageCfg.StageType
    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(self.StageId)
    self:Close()
    if stageType == XDataCenter.FubenFestivalActivityManager.StageFuben then
        XLuaUiManager.Open("UiBattleRoleRoom", self.StageId)
    elseif stageType == XDataCenter.FubenFestivalActivityManager.StageStory then
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
        if not stageInfo then return end
        if stageInfo.Passed then
            self:PlayStoryId(beginStoryId, self.StageId)
        else
            XDataCenter.FubenFestivalActivityManager.FinishStoryRequest(self.StageId, function()
                XDataCenter.FubenFestivalActivityManager.RefreshStagePassedBySettleDatas({ StageId = self.StageId })
                self:PlayStoryId(beginStoryId, self.StageId)
            end)
        end
    end

end