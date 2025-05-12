
---@class XUiSkyGardenCafeMain : XBigWorldUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyGardenCafeControl
---@field _PanelHistory XUiPanelSGStageList
---@field _PanelChallenge XUiPanelSGStageList
local XUiSkyGardenCafeMain = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenCafeMain")

local XUiPanelSGStageList = require("XUi/XUiSkyGarden/XCafe/Panel/XUiPanelSGStageList")
local XUiGridSGStageReward = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGStageReward")

local PanelState = {
    None = 0,
    Main = 1,
    History = 2,
    Challenge = 3,
}

function XUiSkyGardenCafeMain:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafeMain:OnStart()
    self:InitView()
end

function XUiSkyGardenCafeMain:OnEnable()
    self:ChangePanel(self._DefaultState)
    if self._DefaultState == PanelState.Main then
        self:PlayAnimationWithMask("PanelMainEnable", self._OnAnimationCb)
    else
        self._OnAnimationCb()
    end
end

function XUiSkyGardenCafeMain:OnDisable()
    self._DefaultState = self._PanelState
    self:ChangePanel(PanelState.None)
end

function XUiSkyGardenCafeMain:InitUi()
    self._Rewards = {}
    self.TxtName.text = XMVCA.XSkyGardenCafe:GetName()
    self._PanelHistory = XUiPanelSGStageList.New(self.PanelHistory, self, false)
    self._PanelChallenge = XUiPanelSGStageList.New(self.PanelChallenge, self, true)

    self.GridReward.gameObject:SetActiveEx(false)
    self.TxtHistoryLockTips.gameObject:SetActiveEx(false)

    self._DefaultState = PanelState.Main

end

function XUiSkyGardenCafeMain:InitCb()
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCloseClick() end
    
    self.BtnStart.CallBack = function() self:OnBtnStartClick() end
    
    self.BtnChallenge.CallBack = function() self:OnBtnChallengeClick() end
    
    self.BtnHistory.CallBack = function() self:OnBtnHistoryClick() end
    
    local function onAnimationCb()
        local isMain = self._PanelState == PanelState.Main
        self.BtnStart.gameObject:SetActiveEx(isMain)
        self.BtnChallenge.gameObject:SetActiveEx(isMain)
        self.BtnHistory.gameObject:SetActiveEx(isMain)
    end
    self._OnAnimationCb = onAnimationCb
end

function XUiSkyGardenCafeMain:InitView()
end

function XUiSkyGardenCafeMain:ChangePanel(state)
    if self._PanelState == state then
        return
    end
    local isMain = state == PanelState.Main
    self.BtnStart.gameObject:SetActiveEx(true)
    self.BtnChallenge.gameObject:SetActiveEx(true)
    self.BtnHistory.gameObject:SetActiveEx(true)
    if isMain then
        self.PanelMain.gameObject:SetActiveEx(true)
        self._PanelHistory:Close()
        self._PanelChallenge:Close()
        self:RefreshMain()
    elseif state == PanelState.History then
        self.PanelMain.gameObject:SetActiveEx(false)
        --避免XUiNode的生命周期异常
        self:RefreshReward(0, nil)
        self._PanelHistory:Open()
        self._PanelChallenge:Close()
    elseif state == PanelState.Challenge then
        self.PanelMain.gameObject:SetActiveEx(false)
        --避免XUiNode的生命周期异常
        self:RefreshReward(0, nil)
        self._PanelHistory:Close()
        self._PanelChallenge:Open()
    else
        self.PanelMain.gameObject:SetActiveEx(false)
        self:RefreshReward(0, nil)
        self._PanelHistory:Close()
        self._PanelChallenge:Close()
    end
    self._PanelState = state
end

function XUiSkyGardenCafeMain:RefreshMain()
    local curStageId = self._Control:GetFirstNotPassStoryStage()
    local stageName
    if XTool.IsNumberValid(curStageId) then
        self.BtnStart:ShowTag(false)
        local rewardIds = self._Control:GetStageReward(curStageId)
        self:RefreshReward(curStageId, rewardIds)
        stageName = self._Control:GetStageName(curStageId)
    else
        self.BtnStart:ShowTag(true)
        stageName = ""
    end
    self.BtnStart:SetNameByGroup(0, stageName)
    local openChallenge = self._Control:IsChallengeOpen()
    self.BtnChallenge:ShowTag(not openChallenge)
    self.PanelChallengeStar.gameObject:SetActiveEx(openChallenge)
    if openChallenge then
        local cur, total = self._Control:GetChallengeProgress()
        self.BtnChallenge:SetNameByGroup(0, string.format("%d/%d", cur, total))
    end

    local openHistory = self._Control:IsHistoryOpen()
    self.BtnHistory:ShowTag(not openHistory)
    self.PanelHistoryStar.gameObject:SetActiveEx(openHistory)
    if openHistory then
        local cur, total = self._Control:GetHistoryProgress()
        self.BtnHistory:SetNameByGroup(0, string.format("%d/%d", cur, total))
    --else
    --    self.TxtHistoryLockTips.text = self._Control:GetHistoryLockText()
    end
end

function XUiSkyGardenCafeMain:RefreshReward(stateId, rewardIds)
    local rewards = {}
    if not XTool.IsTableEmpty(rewardIds) then
        local targets = self._Control:GetStageTarget(stateId)
        for index, rewardId in pairs(rewardIds) do
            local list = XRewardManager.GetRewardList(rewardId)
            local reward, target = nil, 0
            if list then
                --只显示第一个
                reward = list[1]
            end
            if targets then
                target = targets[index]
            end
            rewards[#rewards + 1] = {
                Reward = reward,
                Target = target,
            }
        end
    end
    
    XTool.UpdateDynamicItem(self._Rewards, rewards, self.GridReward, XUiGridSGStageReward, self)
end
 
function XUiSkyGardenCafeMain:OnBtnStartClick()
    local curStageId = self._Control:GetFirstNotPassStoryStage()
    if not curStageId or curStageId <= 0 then
        XUiManager.TipMsg(self._Control:GetAllStoryStagePassedTip())
        return
    end
    --self._Control:EnterFight(curStageId)
    self._Control:SetFightData(curStageId, 0)
    XMVCA.XSkyGardenCafe:EnterGameLevel()
end

function XUiSkyGardenCafeMain:OnBtnChallengeClick()
    if not self._Control:IsChallengeOpen() then
        return
    end
    self:PlayAnimationWithMask("PanelChallengeEnable", self._OnAnimationCb)
    self:ChangePanel(PanelState.Challenge)
end

function XUiSkyGardenCafeMain:OnBtnHistoryClick()
    if not self._Control:IsHistoryOpen() then
        XUiManager.TipMsg(self._Control:GetHistoryLockText())
        return
    end
    self:PlayAnimationWithMask("PanelHistoryEnable", self._OnAnimationCb)
    self:ChangePanel(PanelState.History)
end

function XUiSkyGardenCafeMain:OnBtnCloseClick()
    if self._PanelState == PanelState.Challenge then
        self:PlayAnimationWithMask("PanelChallengeDisable", function()
            self:ChangePanel(PanelState.Main)
        end, function()
            self.BtnStart.gameObject:SetActiveEx(true)
            self.BtnChallenge.gameObject:SetActiveEx(true)
            self.BtnHistory.gameObject:SetActiveEx(true)
        end)
        return
    elseif self._PanelState == PanelState.History then
        self:PlayAnimationWithMask("PanelHistoryDisable", function()
            self:ChangePanel(PanelState.Main)
        end, function()
            self.BtnStart.gameObject:SetActiveEx(true)
            self.BtnChallenge.gameObject:SetActiveEx(true)
            self.BtnHistory.gameObject:SetActiveEx(true)
        end)
        return
    end

    if not XMVCA.XSkyGardenCafe:IsEnterLevel() then
        XMVCA.XSkyGardenCafe:DoLevelLevel()
        return
    end
    
    local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

    confirmData:InitInfo(self._Control:GetTipTitle(), self._Control:GetQuitText())
    confirmData:InitToggleActive(false):InitSureClick(nil, handler(XMVCA.XSkyGardenCafe, XMVCA.XSkyGardenCafe.ExitGameLevel))

    XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
end