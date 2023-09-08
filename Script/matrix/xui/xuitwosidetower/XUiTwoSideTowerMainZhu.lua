---@class XUiTwoSideTowerMainZhu : XLuaUi
---@field _Control XTwoSideTowerControl
---@field PanelMoel1 XUiComponent.XUiButton
local XUiTwoSideTowerMainZhu = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerMainZhu")

function XUiTwoSideTowerMainZhu:OnAwake()
    self:RegisterUiEvents()
    self.Grid256New.gameObject:SetActiveEx(false)
    ---@type XUiGridCommon[]
    self.GridMainTaskReward = {}
end

function XUiTwoSideTowerMainZhu:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    -- 开启自动关闭检查
    self.EndTime = self._Control:GetActivityEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        else
            self:UpdateTime()
        end
    end)
end

function XUiTwoSideTowerMainZhu:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()
    self:UpdateTime()
    -- 播放动画
    self:PlayAnimationWithMask("Enable", function()
        self:PlayAnimation("UiLoop",nil,nil,CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
end

function XUiTwoSideTowerMainZhu:OnGetEvents()
    return {
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiTwoSideTowerMainZhu:OnNotify(event, ...)
    if event == XEventId.EVENT_TASK_SYNC then
        self:RefreshTaskRedPoint()
    end
end

function XUiTwoSideTowerMainZhu:OnDisable()
    self.Super.OnDisable(self)
end

function XUiTwoSideTowerMainZhu:Refresh()
    self:RefreshOutSideModel()
    self:RefreshInSideModel()
    self:RefreshMainTask()
    self:RefreshTaskRedPoint()
end

function XUiTwoSideTowerMainZhu:RefreshOutSideModel()
    local outSideBg = self._Control:GetOutSideBannerBg()
    self.PanelMoel1:SetRawImage(outSideBg)

    local outSideTimeId = self._Control:GetOutSideTimeId()
    local isOpen, desc = self._Control:GetActivitySideOpenByTimeId(outSideTimeId)
    if not isOpen then
        self.PanelMoel1:SetNameByGroup(0, desc)
    end
    self.PanelMoel1:SetDisable(not isOpen)
    --刷新红点
    if not isOpen then
        self.PanelMoel1:ShowReddot(false)
        return
    end
    local outSideChapterIds = self._Control:GetOutSideChapterIds()
    local isShowRedPoint = self._Control:CheckNewChapterOpenRedPoint(outSideChapterIds)
    self.PanelMoel1:ShowReddot(isShowRedPoint)
end

function XUiTwoSideTowerMainZhu:RefreshInSideModel()
    local insideBg = self._Control:GetInsideBannerBg()
    self.PanelMoel2:SetRawImage(insideBg)

    local insideTimeId = self._Control:GetInsideTimeId()
    local isOpen, desc = self._Control:GetActivitySideOpenByTimeId(insideTimeId)
    if not isOpen then
        self.PanelMoel2:SetNameByGroup(0, desc)
    end
    self.PanelMoel2:SetDisable(not isOpen)
    -- 刷新红点
    if not isOpen then
        self.PanelMoel2:ShowReddot(false)
        return
    end
    local insideChapterIds = self._Control:GetInsideChapterIds()
    local isShowRedPoint = self._Control:CheckNewChapterOpenRedPoint(insideChapterIds)
    self.PanelMoel2:ShowReddot(isShowRedPoint)
end

function XUiTwoSideTowerMainZhu:RefreshMainTask()
    local groupIds = {
        self._Control:GetOutSideLimitTaskId(),
        self._Control:GetInsideLimitTaskId()
    }
    local taskId, isAllFinish = self._Control:GetShowTaskId(groupIds)
    if not XTool.IsNumberValid(taskId) then
        self.PanelTips.gameObject:SetActiveEx(false)
        return
    end
    self.PanelTips.gameObject:SetActiveEx(true)
    local config = XDataCenter.TaskManager.GetTaskTemplate(taskId)
    self.GridMainTaskReward = self.GridMainTaskReward or {}
    local rewardId = config.RewardId
    local rewards = XRewardManager.GetRewardList(rewardId)
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.GridMainTaskReward[i]
        if not grid then
            local go = i == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelItem)
            grid = XUiGridCommon.New(self, go)
            self.GridMainTaskReward[i] = grid
        end
        grid:Refresh(rewards[i])
        grid:SetReceived(isAllFinish)
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.GridMainTaskReward do
        self.GridMainTaskReward[i].GameObject:SetActiveEx(false)
    end
end

function XUiTwoSideTowerMainZhu:UpdateTime()
    if XTool.UObjIsNil(self.TxtTime) then
        return
    end
    local time = self.EndTime - XTime.GetServerNowTimestamp()
    if time <= 0 then
        self.TxtTime.text = ""
        return
    end
    self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
end

-- 任务红点
function XUiTwoSideTowerMainZhu:RefreshTaskRedPoint()
    local groupIds = {
        self._Control:GetOutSideLimitTaskId(),
        self._Control:GetInsideLimitTaskId()
    }
    local taskRadPoint = self._Control:CheckTaskAchievedRedPoint(groupIds)
    self.BtnRank:ShowReddot(taskRadPoint)
end

function XUiTwoSideTowerMainZhu:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRank, self.OnBtnRankClick)
    XUiHelper.RegisterClickEvent(self, self.PanelMoel1, self.OnPanelModel1Click)
    XUiHelper.RegisterClickEvent(self, self.PanelMoel2, self.OnPanelModel2Click)

    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpKey())
end

function XUiTwoSideTowerMainZhu:OnBtnBackClick()
    self:Close()
end

function XUiTwoSideTowerMainZhu:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTwoSideTowerMainZhu:OnBtnRankClick()
    local data = {
        {
            Name = self._Control:GetClientConfig("OutSideLimitTaskName"),
            GroupId = self._Control:GetOutSideLimitTaskId(),
        },
        {
            Name = self._Control:GetClientConfig("InSideLimitTaskName"),
            GroupId = self._Control:GetInsideLimitTaskId(),
        },
    }
    XLuaUiManager.Open("UiTwoSideTowerTaskTwo", data)
end

function XUiTwoSideTowerMainZhu:OnPanelModel1Click()
    local outSideTimeId = self._Control:GetOutSideTimeId()
    local isOpen, desc = self._Control:GetActivitySideOpenByTimeId(outSideTimeId)
    if not isOpen then
        XUiManager.TipMsg(desc)
        return
    end
    XLuaUiManager.Open("UiTwoSideTowerMain", XEnumConst.TwoSideTower.ChapterType.OutSide)
end

function XUiTwoSideTowerMainZhu:OnPanelModel2Click()
    local insideTimeId = self._Control:GetInsideTimeId()
    local isOpen, desc = self._Control:GetActivitySideOpenByTimeId(insideTimeId)
    if not isOpen then
        XUiManager.TipMsg(desc)
        return
    end
    XLuaUiManager.Open("UiTwoSideTowerMain", XEnumConst.TwoSideTower.ChapterType.Inside)
end

return XUiTwoSideTowerMainZhu
