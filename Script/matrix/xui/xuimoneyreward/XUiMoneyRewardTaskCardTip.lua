local XUiMoneyRewardTaskCardTip = XLuaUiManager.Register(XLuaUi, "UiMoneyRewardTaskCardTip")

function XUiMoneyRewardTaskCardTip:OnAwake()
    self:AutoAddListener()
end

function XUiMoneyRewardTaskCardTip:OnStart(taskCard)
    self.GridList = {}
    self.BountyTask = taskCard
    self:SetupTaskCard()

    self:PlayAnimation("MoneyRewardTaskCardTipBegin")
end

--设置任务卡内容
function XUiMoneyRewardTaskCardTip:SetupTaskCard()
    if not self.BountyTask then
        return
    end

    local taskConfig = XDataCenter.BountyTaskManager.GetBountyTaskConfig(self.BountyTask.Id)
    if not taskConfig then
        local path = XBountyTaskConfigs.GetBountyTaskPath()
        XLog.ErrorTableDataNotFound("XUiPanelTaskCard:SetupTaskCard", "taskConfig", path, "Id", tostring(self.BountyTask.Id))
        return
    end

    self.TxtTitle.text = taskConfig.Name
    self.TxtDesc.text = taskConfig.Desc

    self.RImgRoleIcon:SetRawImage(taskConfig.RoleIcon)
    self:SetUiSprite(self.ImgQuality,taskConfig.DifficultLevelIconX, function()
        self.ImgQuality:SetNativeSize()
    end)

    local randomEventCfg = XDataCenter.BountyTaskManager.GetBountyTaskRandomEventConfig(self.BountyTask.EventId)
    self.TxtBuff.text = randomEventCfg.EventName

    local difficultStageCfg = XDataCenter.BountyTaskManager.GetBountyTaskDifficultStageConfig(self.BountyTask.DifficultStageId)
    self.TxtLevel.text = string.format(taskConfig.TextColor, difficultStageCfg.Name)

    self:SetupReward(self.BountyTask.RewardId)
end

--设置奖励
function XUiMoneyRewardTaskCardTip:SetupReward(rewardId)
    local rewards = XRewardManager.GetRewardList(rewardId)
    if not rewards then
        return
    end

    --显示的奖励
    local start = 0
    if rewards then
        for i, item in ipairs(rewards) do
            start = i
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.PanelReward, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
        end
    end

    for j = start + 1, #self.GridList do
        self.GridList[j].GameObject:SetActive(false)
    end
end

function XUiMoneyRewardTaskCardTip:AutoAddListener()
    self:RegisterClickEvent(self.BtnBg, self.OnBtnBgClick)
end

function XUiMoneyRewardTaskCardTip:OnBtnBgClick()
    self:Close()
end