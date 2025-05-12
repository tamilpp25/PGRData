local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiStageFightControl = require("XUi/XUiCommon/XUiStageFightControl")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiAssignStageDetail = XLuaUiManager.Register(XLuaUi, "UiAssignStageDetail")

local MAX_STAR = 3
function XUiAssignStageDetail:OnAwake()
    self:InitComponent()
end

function XUiAssignStageDetail:InitComponent()
    self.GridCommon.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:RegisterClickEvent(self.BtnAddNum, self.OnBtnAddNumClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)


    self.PanelNums.gameObject:SetActiveEx(false)
    self.PanelNoLimitCount.gameObject:SetActiveEx(true)
    self.BtnAddNum.gameObject:SetActiveEx(false)
    self.TxtAllNums.text = ""
    self.TxtLeftNums.text = ""
    self.PanelNums.gameObject:SetActiveEx(false)
end

function XUiAssignStageDetail:OnStart()
    self.GridList = {}
end

function XUiAssignStageDetail:OnEnable()
    self.ChapterId = XDataCenter.FubenAssignManager.SelectChapterId
    self.GroupId = XDataCenter.FubenAssignManager.SelectGroupId

    self:Refresh()

    -- 动画
    self.IsPlaying = true
    XUiHelper.StopAnimation()

    -- self:PlayAnimation(ANIMATION_OPEN, handler(self, function()
    self.IsPlaying = false
    -- end))
    self.IsOpen = true
end

function XUiAssignStageDetail:OnDisable()
    self.IsOpen = false
end

function XUiAssignStageDetail:Refresh()
    local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(self.GroupId)

    self.BaseStageId = groupData:GetBaseStageId()
    self.Stage = XDataCenter.FubenManager.GetStageCfg(self.BaseStageId)
    self.StageInfo = XDataCenter.FubenManager.GetStageInfo(self.BaseStageId)
    self.IsPassed = XDataCenter.FubenManager.CheckStageIsPass(self.BaseStageId)
    self:UpdatePanelTargetList()
    self:UpdateRewards()
    self:UpdateDetailText()
    self:UpdateDifficulty()
    self:UpdateStageFightControl()
end

function XUiAssignStageDetail:OnBtnAddNumClick()
    local challengeData = XDataCenter.FubenMainLineManager.GetStageBuyChallengeData(self.BaseStageId)
    local func = function()
        self:UpdateDetailText()
    end
    XLuaUiManager.Open("UiBuyAsset", 1, func, challengeData)
end

function XUiAssignStageDetail:OnBtnEnterClick()
    if self.IsPlaying then
        return
    end

    if self.BaseStageId == nil then
        XLog.Error("OnBtnEnterClick: Can not find baseStageId!")
        return
    end

    -- 检查体力 前置等
    if not XDataCenter.FubenManager.CheckPreFight(self.Stage) then
        return
    end

    self:Hide()
    XLuaUiManager.Open("UiAssignDeploy")
end

function XUiAssignStageDetail:OnBtnCloseClick()
    self:Hide()
end

function XUiAssignStageDetail:UpdatePanelTargetList()
    for i = 1, MAX_STAR do
        self["TxtStarActive" .. i].text = self.Stage.StarDesc[i]
    end
end

function XUiAssignStageDetail:UpdateRewards()
    local rewardId
    local IsFirst = (not self.IsPassed)
    local cfg = self.Stage
    if IsFirst then
        rewardId = cfg.FirstRewardShow
    else
        rewardId = cfg.FinishRewardShow
    end

    if not rewardId or rewardId == 0 then
        for j = 1, #self.GridList do
            self.GridList[j].GameObject:SetActiveEx(false)
        end
        return
    end

    local rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.PanelDropContent, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.GridList do
        if j > rewardsCount then
            self.GridList[j].GameObject:SetActiveEx(false)
        end
    end
end

function XUiAssignStageDetail:UpdateDetailText()
    self.TxtTitle.text = self.Stage.Name
    self.TxtLevelVal.text = self.Stage.RecommandLevel
    self.TxtDesc.text = self.Stage.Description
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(self.Stage.StageId)

    -- local groupData = XDataCenter.FubenAssignManager.GetGroupDataById(self.GroupId)
    -- local chanllengeNum = groupData:GetFightCount()
    -- local maxChallengeNum = groupData:GetMaxFightCount()
    -- local buyChallengeCount = XDataCenter.FubenManager.GetStageBuyChallengeCount(self.BaseStageId)
    -- self.PanelNums.gameObject:SetActiveEx(maxChallengeNum > 0)
    -- self.PanelNoLimitCount.gameObject:SetActiveEx(maxChallengeNum <= 0)
    -- self.BtnAddNum.gameObject:SetActiveEx(buyChallengeCount > 0)
    -- if maxChallengeNum > 0 then
    --     self.TxtAllNums.text = "/" .. maxChallengeNum
    --     self.TxtLeftNums.text = maxChallengeNum - chanllengeNum
    -- end
    self.TxtFirstDrop.gameObject:SetActiveEx(not self.IsPassed)
    self.TxtDrop.gameObject:SetActiveEx(self.IsPassed)
end

function XUiAssignStageDetail:UpdateDifficulty()
    local nanDuIcon = XDataCenter.FubenManager.GetDifficultIcon(self.BaseStageId)
    self.RImgNandu:SetRawImage(nanDuIcon)
end

function XUiAssignStageDetail:UpdateStageFightControl()
    --暂时屏蔽，后面可能要加回来
    if true then
        self.PanelStageFightControl.gameObject:SetActiveEx(false)
        return
    end

    -- local stageInfo = self.StageInfo
    -- self.StageFightControl = self.StageFightControl or XUiStageFightControl.New(self.PanelStageFightControl, self.Stage.FightControlId)

    -- if not self.IsPassed and stageInfo.Unlock then
    --     self.StageFightControl.GameObject:SetActiveEx(true)
    --     self.StageFightControl:UpdateInfo(self.Stage.FightControlId)
    -- else
    --     self.StageFightControl.GameObject:SetActiveEx(false)
    -- end
end

function XUiAssignStageDetail:Hide()
    if self.IsPlaying or not self.IsOpen then
        return
    end

    self.IsPlaying = true
    XUiHelper.StopAnimation()

    -- self:PlayAnimation(ANIMATION_END, handler(self, function()
    --     if XTool.UObjIsNil(self.GameObject) then
    --         return
    --     end
    self.IsPlaying = false
    self:Close()
    -- end))
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_ASSIGN_STAGE_DETAIL_CLOSE)
end