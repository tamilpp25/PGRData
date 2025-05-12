local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridTwoSideTowerChapter = require("XUi/XUiTwoSideTower/XUiGridTwoSideTowerChapter")

---@class XUiTwoSideTowerMain : XLuaUi
---@field _Control XTwoSideTowerControl
local XUiTwoSideTowerMain = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerMain")

function XUiTwoSideTowerMain:OnAwake()
    self:RegisterUiEvents()
    self.GridChapter.gameObject:SetActiveEx(false)
    self.Grid256New.gameObject:SetActiveEx(false)

    ---@type XUiGridTwoSideTowerChapter[]
    self.GridChapterList = {}
    ---@type XUiGridCommon[]
    self.GridMainTaskReward = {}
end

function XUiTwoSideTowerMain:OnStart(chapterType)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.ChapterType = chapterType
    -- 开启自动关闭检查
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiTwoSideTowerMain:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()
end

function XUiTwoSideTowerMain:OnGetEvents()
    return {
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiTwoSideTowerMain:OnNotify(event, ...)
    if event == XEventId.EVENT_TASK_SYNC then
        self:RefreshTaskRedPoint()
    end
end

function XUiTwoSideTowerMain:OnDisable()
    self.Super.OnDisable(self)
end

function XUiTwoSideTowerMain:Refresh()
    self:RefreshChapterList()
    self:RefreshShowTaskData()
    self:RefreshModel()
    self:RefreshTaskRedPoint()
end

-- 刷新模式
function XUiTwoSideTowerMain:RefreshModel()
    -- 背景
    self.Bg:SetRawImage(self._Control:GetClientConfig("ChapterBgIcon", self.ChapterType))
    -- 标题
    self.ImgTitle:SetRawImage(self._Control:GetClientConfig("ChapterTitleIcon", self.ChapterType))
    -- 跳转按钮
    self.BtnSkip:SetNameByGroup(0, self._Control:GetClientConfig("ChapterBtnSkipName", self.ChapterType))
    self.BtnSkip:SetRawImage(self._Control:GetClientConfig("ChapterBtnSkipIcon", self.ChapterType))
end

function XUiTwoSideTowerMain:RefreshChapterList()
    local chapterIdList = self:GetChapterIdList()
    for index, chapterId in pairs(chapterIdList) do
        local grid = self.GridChapterList[index]
        if not grid then
            local go = index == 1 and self.GridChapter or XUiHelper.Instantiate(self.GridChapter, self.PanelChapterList)
            grid = XUiGridTwoSideTowerChapter.New(go, self)
            self.GridChapterList[index] = grid
        end
        grid:Open()
        grid:Refresh(chapterId)
    end
    for i = #chapterIdList + 1, #self.GridChapterList do
        self.GridChapterList[i]:Close()
    end
end

function XUiTwoSideTowerMain:RefreshShowTaskData()
    local groupIds = { self:GetTaskGroupId() }
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

function XUiTwoSideTowerMain:RefreshTaskRedPoint()
    local groupIds = { self:GetTaskGroupId() }
    local taskRadPoint = self._Control:CheckTaskAchievedRedPoint(groupIds)
    self.BtnRank:ShowReddot(taskRadPoint)
end

function XUiTwoSideTowerMain:GetChapterIdList()
    if self.ChapterType == XEnumConst.TwoSideTower.ChapterType.OutSide then
        return self._Control:GetOutSideChapterIds()
    end
    if self.ChapterType == XEnumConst.TwoSideTower.ChapterType.Inside then
        return self._Control:GetInsideChapterIds()
    end
    return {}
end

function XUiTwoSideTowerMain:GetTaskGroupId()
    if self.ChapterType == XEnumConst.TwoSideTower.ChapterType.OutSide then
        return self._Control:GetOutSideLimitTaskId()
    end
    if self.ChapterType == XEnumConst.TwoSideTower.ChapterType.Inside then
        return self._Control:GetInsideLimitTaskId()
    end
    return 0
end

-- 跳转时获取 需要根据跳转的类型去获取时间Id
function XUiTwoSideTowerMain:GetTimeId(chapterType)
    if chapterType == XEnumConst.TwoSideTower.ChapterType.OutSide then
        return self._Control:GetOutSideTimeId()
    end
    if chapterType == XEnumConst.TwoSideTower.ChapterType.Inside then
        return self._Control:GetInsideTimeId()
    end
    return 0
end

function XUiTwoSideTowerMain:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRank, self.OnBtnRankClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)

    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpKey())
end

function XUiTwoSideTowerMain:OnBtnBackClick()
    self:Close()
end

function XUiTwoSideTowerMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTwoSideTowerMain:OnBtnRankClick()
    local data = {
        {
            GroupId = self:GetTaskGroupId()
        },
    }
    XLuaUiManager.Open("UiTwoSideTowerTaskTwo", data)
end

function XUiTwoSideTowerMain:OnBtnSkipClick()
    local chapterType = XEnumConst.TwoSideTower.ChapterType.OutSide
    if self.ChapterType == XEnumConst.TwoSideTower.ChapterType.OutSide then
        chapterType = XEnumConst.TwoSideTower.ChapterType.Inside
    end
    local timeId = self:GetTimeId(chapterType)
    local isOpen, desc = self._Control:GetActivitySideOpenByTimeId(timeId)
    if not isOpen then
        XUiManager.TipMsg(desc)
        return
    end
    XLuaUiManager.PopThenOpen("UiTwoSideTowerMain", chapterType)
end

return XUiTwoSideTowerMain
