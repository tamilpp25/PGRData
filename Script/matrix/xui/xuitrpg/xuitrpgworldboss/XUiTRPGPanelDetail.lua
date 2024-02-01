local XUiTRPGPanelDetail = XClass(nil, "XUiTRPGPanelDetail")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiTRPGPanelDetail:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)

    self:SetButtonCallBack()
    self:SetActivityInfo()
end

function XUiTRPGPanelDetail:SetButtonCallBack()
    self.BtnBoss.CallBack = function()
        self:OnBtnBossClick()
    end
end

function XUiTRPGPanelDetail:UpdateActivityInfo()
    local challengeCount = XDataCenter.TRPGManager.GetWorldBossChallengeCount()
    local maxChallengeCount = XTRPGConfigs.GetBossChallengeCount()
    self.ChallengeText.text = CSTextManagerGetText("WorldBossBossChallengeText")
    self.ChallengeCount.text = string.format("%d/%d", maxChallengeCount - challengeCount, maxChallengeCount)
end

function XUiTRPGPanelDetail:SetActivityInfo()
    local desc = XTRPGConfigs.GetBossDesc()
    self.TxtDesc.text = desc

    self.GridRewardList = {}
    self.GridCommon.gameObject:SetActiveEx(false)
    self:UpdateRewardList()
end

function XUiTRPGPanelDetail:UpdateRewardList()
    local stageId = XTRPGConfigs.GetBossStageId()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local rewardId = stageCfg.FinishRewardShow
    local rewards = XRewardManager.GetRewardList(rewardId)

    for _, grid in pairs(self.GridRewardList) do
        grid.GameObject:SetActiveEx(false)
    end

    if rewards then
        for index, item in pairs(rewards) do
            if not self.GridRewardList[index] then
                local obj = CS.UnityEngine.Object.Instantiate(self.GridCommon, self.PanelDropContent)
                local grid = XUiGridCommon.New(self.Base, obj)
                grid:Refresh(item)
                grid.GameObject:SetActive(true)
                self.GridRewardList[index] = grid
            else
                self.GridRewardList[index]:Refresh(item)
                self.GridRewardList[index].GameObject:SetActive(true)
            end
        end
    end
end

function XUiTRPGPanelDetail:OnBtnBossClick()
    local challengeCount = XDataCenter.TRPGManager.GetWorldBossChallengeCount()
    local maxChallengeCount = XTRPGConfigs.GetBossChallengeCount()
    if maxChallengeCount - challengeCount == 0 then
        XUiManager.TipText("WorldBossNoChallengeCount")
        return
    end

    local stageId = XTRPGConfigs.GetBossStageId()
    XLuaUiManager.Open("UiBattleRoleRoom", stageId)
end

function XUiTRPGPanelDetail:SetShow(IsShow)
    self.GameObject:SetActiveEx(IsShow)
end

return XUiTRPGPanelDetail