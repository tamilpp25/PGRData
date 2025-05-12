---@class XUiGridSGStageTarget : XUiNode
---@field _Control XSkyGardenCafeControl
local XUiGridSGStageTarget = XClass(XUiNode, "XUiGridSGStageTarget")

function XUiGridSGStageTarget:Refresh(score, curScore)
    local isFinish = curScore >= score
    self.TargetOff.gameObject:SetActiveEx(not isFinish)
    self.TargetOn.gameObject:SetActiveEx(isFinish)
    local value = string.format(self._Control:GetTargetText(), score)
    if isFinish then
        self.TxtTargetOn.text = value
    else
        self.TxtTargetOff.text = value
    end
end


---@class XUiSkyGardenCafePopupSettlement : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyGardenCafeControl
local XUiSkyGardenCafePopupSettlement = XLuaUiManager.Register(XLuaUi, "UiSkyGardenCafePopupSettlement")

local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

function XUiSkyGardenCafePopupSettlement:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafePopupSettlement:OnStart(stageId, isSettlement)
    self._StageId = stageId
    self._IsSettlement = isSettlement
    self:InitView()
end

function XUiSkyGardenCafePopupSettlement:InitUi()
    self._GridTargets = {}
    self._GridRewards = {}
end

function XUiSkyGardenCafePopupSettlement:InitCb()
    self.BtnTanchuangCloseBig.CallBack = function() 
        self:Close()
        XLuaUiManager.SafeClose("UiSkyGardenCafeGame")
        XLuaUiManager.SafeClose("UiSkyGardenCafeHandBook")
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EXIT_FIGHT, self._StageId)
    end
    self.BtnAgain.CallBack = function()
        self:OnBtnAgainClick()
    end
    self.BtnRechallenge.CallBack = function()
        self:OnBtnRechallengeClick()
    end
    self.BtnContinue.CallBack = function()
        self:OnBtnContinueClick()
    end
end

function XUiSkyGardenCafePopupSettlement:InitView()
    self.BtnAgain.gameObject:SetActiveEx(not self._IsSettlement)
    self.BtnRechallenge.gameObject:SetActiveEx(self._IsSettlement)
    self.BtnContinue.gameObject:SetActiveEx(self._IsSettlement)

    local isTagNew = false
    if self._IsSettlement then
        local battleInfo = self._Control:GetBattle():GetBattleInfo()
        local score = battleInfo:GetScore()
        self:RefreshTarget(score, battleInfo:GetRound(), battleInfo:GetRewardIds())
        self._NextStageId = self._Control:GetFirstNotPassStageId()
        if self._NextStageId == self._StageId then
            self._NextStageId = nil
        end
        local stageInfo = self._Control:GetStageInfo(self._StageId)
        local oldScore = stageInfo and stageInfo:GetLastScore() or 0
        isTagNew = score > oldScore
    else
        local stageInfo = self._Control:GetStageInfo(self._StageId)
        local round = self._Control:GetStageRounds(self._StageId)
        self:RefreshTarget(stageInfo:GetScore(), round, self._Control:GetStageRewardIdsByStar(self._StageId))
    end
    self.TagNew.gameObject:SetActiveEx(isTagNew)
    self.BtnContinue:SetNameByGroup(0, self._Control:GetBtnSettleContinueText(self._NextStageId == nil))
end

function XUiSkyGardenCafePopupSettlement:RefreshTarget(curScore, curRound, rewardIds)
    local stageId = self._StageId
    local targets = self._Control:GetStageTarget(stageId)
    self.PanelTarget.gameObject:SetActiveEx(true)
    self.PanelRecord.gameObject:SetActiveEx(true)
    self.PanelReward.gameObject:SetActiveEx(true)
    self.TxtTitle.text = self._Control:GetStageName(stageId)
    for i, target in pairs(targets) do
        local grid = self._GridTargets[i]
        if not grid then
            local ui = i == 1 and self.GridTarget or XUiHelper.Instantiate(self.GridTarget, self.PanelTarget)
            grid = XUiGridSGStageTarget.New(ui, self)
            self._GridTargets[i] = grid
        end
        grid:Refresh(target, curScore)
    end

    self.TxtScoreNum.text = curScore
    self.TxtStepsNum.text = curRound

    self:RefreshReward(rewardIds)
end

function XUiSkyGardenCafePopupSettlement:RefreshReward(rewardIds)
    local rewards = {}
    if not XTool.IsTableEmpty(rewardIds) then
        for _, rewardId in pairs(rewardIds) do
            local list = XRewardManager.GetRewardList(rewardId)
            if list then
                --只显示第一个
                rewards[#rewards + 1] = list[1]
            end
        end
    end

    XTool.UpdateDynamicItem(self._GridRewards, rewards, self.UiBigWorldItemGrid, XUiGridBWItem, self)
end

function XUiSkyGardenCafePopupSettlement:OnBtnAgainClick()
    self:Close()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ENTER_FIGHT, self._StageId)
end

function XUiSkyGardenCafePopupSettlement:OnBtnRechallengeClick()
    local stageId = self._StageId
    local isStoryStage = self._Control:IsStoryStage(stageId)
    self:Close()
    XLuaUiManager.Close("UiSkyGardenCafeGame")
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EXIT_FIGHT, stageId)
    if isStoryStage then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ENTER_FIGHT, stageId, 0)
    end
end

function XUiSkyGardenCafePopupSettlement:OnBtnContinueClick()
    local stageId = self._StageId
    if self._NextStageId and not self._Control:IsStoryStage(stageId) then
        self._Control:SetStageIdCache(self._NextStageId)
    end
    self:Close()
    XLuaUiManager.Close("UiSkyGardenCafeGame")
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EXIT_FIGHT, stageId)
    
end