local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiScoreTowerMain : XLuaUi
---@field private _Control XScoreTowerControl
---@field ChapterScrollRect UnityEngine.UI.ScrollRect
local XUiScoreTowerMain = XLuaUiManager.Register(XLuaUi, "UiScoreTowerMain")

function XUiScoreTowerMain:OnAwake()
    self:RegisterUiEvents()
    self.GridChapter.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self.CommonTaskReward.gameObject:SetActiveEx(false)
end

function XUiScoreTowerMain:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.ScoreTowerCoin)
    self.EndTime = XMVCA.XScoreTower:GetActivityEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            XMVCA.XScoreTower:HandleActivityEnd()
        else
            self:RefreshTime()
        end
    end)
    ---@type XUiGridScoreTowerChapter[]
    self.GridChapterList = {}
    ---@type XUiGridCommon[]
    self.GridTaskRewardList = {}
    -- 是否首次打开
    self.IsFirstOpen = true
end

function XUiScoreTowerMain:OnEnable()
    self.Super.OnEnable(self)
    -- 章节入口动画播放间隔
    self.AnimInterval = self._Control:GetClientConfig("ChapterEntranceAnimInterval", self.IsFirstOpen and 1 or 2, true)
    self:RefreshTime()
    self:RefreshChapter(true)
    self:RefreshTaskReward()
    self:RefreshBtn()
    self:RefreshRedPoint()
    self:JumpToChapter()
    self.IsFirstOpen = false
end

function XUiScoreTowerMain:OnDisable()
    self.Super.OnDisable(self)
end

-- 刷新时间
function XUiScoreTowerMain:RefreshTime()
    if XTool.UObjIsNil(self.TxtTime) then
        return
    end
    local leftTime = self.EndTime - XTime.GetServerNowTimestamp()
    if leftTime < 0 then
        leftTime = 0
    end
    self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
end

-- 刷新章节信息
---@type boolean isAnim 是否播放动画
function XUiScoreTowerMain:RefreshChapter(isAnim)
    local chapterIdList = self._Control:GetActivityChapterIds()
    local chapterCount = #chapterIdList
    self.PanelChapter.gameObject:SetActiveEx(chapterCount > 0)
    local enableAnimDelay = self.IsFirstOpen and 550 or 150
    for index = 1, XEnumConst.ScoreTower.MaxChapterCount do
        local grid = self.GridChapterList[index]
        local parent = self[string.format("Chapter%d", index)]
        if index <= chapterCount then
            if not grid then
                local go = XUiHelper.Instantiate(self.GridChapter, parent)
                grid = require("XUi/XUiScoreTower/Chapter/XUiGridScoreTowerChapter").New(go, self)
                self.GridChapterList[index] = grid
            end
            parent.gameObject:SetActiveEx(true)
            grid:Open()
            grid:Refresh(chapterIdList[index])
            if isAnim then
                grid:TryPlayEnableAnim(enableAnimDelay)
                enableAnimDelay = enableAnimDelay + self.AnimInterval
            end
        else
            if grid then
                grid:Close()
            end
            parent.gameObject:SetActiveEx(false)
        end
    end
end

-- 刷新任务奖励
function XUiScoreTowerMain:RefreshTaskReward()
    local rewardId = self._Control:GetClientConfig("TaskShowRewardId", 1, true)
    if not XTool.IsNumberValid(rewardId) then
        self.CommonTaskReward.gameObject:SetActiveEx(false)
        return
    end
    local rewardList = XRewardManager.GetRewardList(rewardId)
    if XTool.IsTableEmpty(rewardList) then
        self.CommonTaskReward.gameObject:SetActiveEx(false)
        return
    end
    self.CommonTaskReward.gameObject:SetActiveEx(true)
    local rewardCount = #rewardList
    for i = 1, rewardCount do
        local grid = self.GridTaskRewardList[i]
        if not grid then
            local go = i == 1 and self.GridReward or XUiHelper.Instantiate(self.GridReward, self.PanelList)
            grid = XUiGridCommon.New(self, go)
            self.GridTaskRewardList[i] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(rewardList[i])
    end
    for i = rewardCount + 1, #self.GridTaskRewardList do
        self.GridTaskRewardList[i].GameObject:SetActiveEx(false)
    end
end

-- 刷新按钮
function XUiScoreTowerMain:RefreshBtn()
    -- 天赋按钮
    local isUnlock, _ = self._Control:IsStrengthenUnlock()
    self.BtnTalent:SetDisable(not isUnlock)
    -- 排行榜按钮
    local isOpen, _ = self._Control:IsActivityRankOpen()
    self.BtnRank:SetDisable(not isOpen)
end

-- 刷新按钮红点
function XUiScoreTowerMain:RefreshRedPoint()
    -- 天赋按钮红点
    local isShowTalentRedPoint = self._Control:IsShowStrengthenRedPoint()
    self.BtnTalent:ShowReddot(isShowTalentRedPoint)
    -- 任务按钮红点
    local isShowTaskRedPoint = self._Control:IsShowTaskRedPoint()
    self.BtnTask:ShowReddot(isShowTaskRedPoint)
    -- 排行榜按钮红点
    local isShowRankRedPoint = self._Control:IsShowRankRedPoint()
    self.BtnRank:ShowReddot(isShowRankRedPoint)
end

-- 跳转到章节
function XUiScoreTowerMain:JumpToChapter()
    local index = self:GetUnPassedChapterIndex()
    ---@type UnityEngine.RectTransform
    local chapterNode = self[string.format("Chapter%d", index)]
    if XTool.UObjIsNil(chapterNode) then
        return
    end
    local posX = chapterNode.localPosition.x - self.PanelChapter.rect.width / 2
    self.ChapterScrollRect.horizontalNormalizedPosition = 0
    self.ChapterScrollRect.horizontalNormalizedPosition = posX / (self.ChapterScrollRect.content.rect.width - self.PanelChapter.rect.width)
end

-- 获取未通关章节索引 如果有正在进行的章节则返回正在进行的章节索引
function XUiScoreTowerMain:GetUnPassedChapterIndex()
    local chapterIdList = self._Control:GetActivityChapterIds()
    -- 正在进行中的章节Id
    local curChapterId = self._Control:GetCurrentChapterId()
    for index, chapterId in ipairs(chapterIdList) do
        if XTool.IsNumberValid(curChapterId) then
            if curChapterId == chapterId then
                return index
            end
        else
            if not self._Control:IsChapterPass(chapterId) then
                return index
            end
        end
    end
    return #chapterIdList
end

-- 提前结算
function XUiScoreTowerMain:AdvanceSettleRequest(towerId)
    local title = self._Control:GetClientConfig("ChapterProgressTitle")
    local content = self._Control:GetClientConfig("ChapterProgressContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        self._Control:AdvanceSettleRequest(towerId, function()
            self:RefreshChapter()
            self:RefreshRedPoint()
        end)
    end)
end

function XUiScoreTowerMain:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnTalent, self.OnBtnTalentClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:RegisterClickEvent(self.BtnRank, self.OnBtnRankClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiScoreTowerMain:OnBtnBackClick()
    self:Close()
end

function XUiScoreTowerMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 天赋按钮
function XUiScoreTowerMain:OnBtnTalentClick()
    local isUnlock, unlockTips = self._Control:IsStrengthenUnlock()
    if not isUnlock then
        XUiManager.TipMsg(unlockTips)
        return
    end
    XLuaUiManager.Open("UiScoreTowerTalent")
end

-- 任务按钮
function XUiScoreTowerMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiScoreTowerTask")
end

-- 排行榜按钮
function XUiScoreTowerMain:OnBtnRankClick()
    local isOpen, openTips = self._Control:IsActivityRankOpen()
    if not isOpen then
        XUiManager.TipMsg(openTips)
        return
    end
    self._Control:QueryRankRequest(function()
        XLuaUiManager.Open("UiScoreTowerRank")
    end)
end

return XUiScoreTowerMain
