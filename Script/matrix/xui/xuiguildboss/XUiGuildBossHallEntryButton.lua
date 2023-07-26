

local XUiGuildBossHallEntryButton = XClass(nil, "XUiGuildBossHallEntryButton")

--最大显示奖励数
local MaxRewardShow = 2

function XUiGuildBossHallEntryButton:Ctor(ui, clickCb)
    XTool.InitUiObjectByUi(self, ui)
    self.ClickCb = clickCb
    self.Btn = self.Transform:GetComponent("XUiButton")
    self.RewardGrids = {}
    
    self:InitCb()
end

function XUiGuildBossHallEntryButton:InitCb()
    self.Btn.CallBack = function() 
        self:OnClick()
    end
end

function XUiGuildBossHallEntryButton:OnEnable()
    self.Btn:ShowReddot(XDataCenter.GuildBossManager.IsReward())
    local timeLeft = XDataCenter.GuildManager.GuildBossEndTime() - XTime.GetServerNowTimestamp()
    if timeLeft < 0 then
        timeLeft = 0
    end
    local timeStr = XUiHelper.GetTime(timeLeft, XUiHelper.TimeFormatType.MAINBATTERY)
    self.Btn:SetNameByGroup(1, CS.XTextManager.GetText("GuildBossCountDown", timeStr))
    
    self:RefreshReward()
end

function XUiGuildBossHallEntryButton:RefreshReward()
    if not self.GameObject.activeInHierarchy then
        return
    end

    local rewardId = XGuildBossConfig.GetZeroHpRewardId()
    local rewards = XRewardManager.GetRewardListNotCount(rewardId)
    for i, reward in pairs(rewards or {}) do
        if i > MaxRewardShow then
            break
        end
        local grid = self.RewardGrids[i]
        if not grid then
            local ui = i == 1 and self.GridReward or XUiHelper.Instantiate(self.GridReward, self.RewardList)
            grid = XUiGridCommon.New(ui)
            self.RewardGrids[i] = grid
        end
        grid:Refresh(reward)
        grid.GameObject:SetActiveEx(true)
    end

    for i, grid in pairs(self.RewardGrids or {}) do
        grid.GameObject:SetActiveEx(i <= MaxRewardShow)
    end
    
    self.PanelReward.gameObject:SetActiveEx(not XTool.IsTableEmpty(rewards))
end

function XUiGuildBossHallEntryButton:OnClick()
    if self.ClickCb then
        self.ClickCb()
    end
end

return XUiGuildBossHallEntryButton