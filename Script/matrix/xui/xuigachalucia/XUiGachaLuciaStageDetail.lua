local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGachaLuciaStageDetail : XLuaUi
local XUiGachaLuciaStageDetail = XLuaUiManager.Register(XLuaUi, "UiGachaLuciaStageDetail")

function XUiGachaLuciaStageDetail:OnAwake()
    ---@type XUiGridCommon[]
    self._GridList = {}
    XUiHelper.RegisterClickEvent(self, self.BtnMask, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self.OnBtnEnterClick)
end

function XUiGachaLuciaStageDetail:OnStart(stageId)
    self._StageId = stageId
    self._StageCfg = XDataCenter.FubenManager.GetStageCfg(self._StageId)
    self._StageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
end

function XUiGachaLuciaStageDetail:OnEnable()
    local stageCfg = self._StageCfg
    self.TxtStoryName.text = stageCfg.Name
    self.TxtStoryDec.text = stageCfg.Description
    self.RImgStory:SetRawImage(stageCfg.Icon)
    local config = XMVCA.XFuben:GetStageVoiceTip()[self._StageId]
    self.PanelSound.gameObject:SetActiveEx(config)
    self.TextSound.text = config and config.Text
    -- 按钮名字
    local isFight = stageCfg.StageType == XDataCenter.FubenFestivalActivityManager.StageFuben
    local btnName = isFight and CS.XTextManager.GetText("StartFight") or CS.XTextManager.GetText("StartPlay")
    self.BtnEnter:SetNameByGroup(0, btnName)

    -- 奖励
    local rewardId = self._StageCfg.FirstRewardShow
    self.PanelReward.gameObject:SetActiveEx(XTool.IsNumberValid(rewardId))
    -- 首通
    local isPassed = self._StageInfo.Passed

    local rewards = {}
    if rewardId > 0 then
        rewards = XRewardManager.GetRewardList(rewardId)
    end
    if rewards then
        for i, item in ipairs(rewards) do
            local grid = self._GridList[i]
            if not grid then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridRewards, self.GridRewards.parent)
                grid = XUiGridCommon.New(self, ui)
                grid:SetCustomItemTip(function(data, hideSkipBtn, rootUiName, lackNum)
                    XLuaUiManager.Open("UiGachaLuciaTip", data, hideSkipBtn, rootUiName, lackNum)
                end)
                self._GridList[i] = grid
            end
            grid:Refresh(item)
            grid:SetReceived(isPassed)
            grid.GameObject:SetActive(true)
        end
    end
    self.GridRewards.gameObject:SetActive(false)
end

function XUiGachaLuciaStageDetail:PlayStoryId(movieId)
    XDataCenter.MovieManager.PlayMovie(movieId)
end

function XUiGachaLuciaStageDetail:OnBtnEnterClick()
    local stageCfg = self._StageCfg
    local stageType = stageCfg.StageType
    self:Close()
    if stageType == XDataCenter.FubenFestivalActivityManager.StageFuben then
        XLuaUiManager.Open("UiBattleRoleRoom", self._StageId)
    elseif stageType == XDataCenter.FubenFestivalActivityManager.StageStory then
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(self._StageId)
        if not stageInfo then
            return
        end

        local beginStoryId = XMVCA.XFuben:GetBeginStoryId(self._StageId)
        if stageInfo.Passed then
            self:PlayStoryId(beginStoryId, self._StageId)
        else
            XDataCenter.FubenFestivalActivityManager.FinishStoryRequest(self._StageId, function()
                XDataCenter.FubenFestivalActivityManager.RefreshStagePassedBySettleDatas({ StageId = self._StageId })
                self:PlayStoryId(beginStoryId, self._StageId)
            end)
        end
    end
end

return XUiGachaLuciaStageDetail