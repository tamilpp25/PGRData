---@class XUiTheatre3Achievement : XLuaUi
---@field PanelTab XUiButtonGroup
---@field _Control XTheatre3Control
local XUiTheatre3Achievement = XLuaUiManager.Register(XLuaUi, "UiTheatre3Achievement")

function XUiTheatre3Achievement:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3Achievement:OnStart()
    self:InitAchievementData()
    self:InitAchievementTab()
    self:InitTaskPanel()
    self:InitRewardPanel()
end

function XUiTheatre3Achievement:OnEnable()
    self.PanelTab:SelectIndex(1)
    self:AddEventListener()
end

function XUiTheatre3Achievement:OnDisable()
    self:RemoveEventListener()
end

--region Data
---@class XUiTheatre3AchievementTaskIndexShow
---@field StartIndex number
---@field EndIndex number
---@field MaxIndex number
---@field AllPage number

function XUiTheatre3Achievement:InitAchievementData()
    self._TaskPerPageCount = 6
    self._CurSelectAchievementIndex = 0
    self._AchievementIdList = self._Control:GetCfgAchievementIdList()
    ---@type XUiTheatre3AchievementTaskIndexShow[]
    self._TaskIndexShowDir = {}

    self:_UpdateAchievementTaskData()
    for _, id in ipairs(self._AchievementIdList) do
        self._TaskIndexShowDir[id] = {}
        self._TaskIndexShowDir[id].MaxIndex = #self._TaskDataListDir[id]
        self._TaskIndexShowDir[id].AllPage = math.ceil(self._TaskIndexShowDir[id].MaxIndex / self._TaskPerPageCount)
        self._TaskIndexShowDir[id].StartIndex = 1
        self._TaskIndexShowDir[id].EndIndex = math.min(self._TaskIndexShowDir[id].MaxIndex, self._TaskPerPageCount)
    end
end

function XUiTheatre3Achievement:_UpdateAchievementTaskData()
    ---@type table<number, XTaskData[]>
    self._TaskDataListDir = {}
    for _, id in ipairs(self._AchievementIdList) do
        self._TaskDataListDir[id] = self._Control:GetAchievementTaskDataList(id, true)
    end
end

function XUiTheatre3Achievement:_GetAllAchievementProcessCount()
    local allFinishCount = 0
    local allTaskCount = 0
    for _, id in ipairs(self._AchievementIdList) do
        local finishCount, taskCount = self:_GetAchievementProcessCount(id)
        allFinishCount = finishCount + allFinishCount
        allTaskCount = taskCount + allTaskCount
    end
    return allFinishCount, allTaskCount
end

function XUiTheatre3Achievement:_GetAchievementProcessCount(achievementId)
    local finishCount = 0
    for _, data in ipairs(self._TaskDataListDir[achievementId]) do
        if data.State == XDataCenter.TaskManager.TaskState.Finish then
            finishCount = finishCount + 1
        end
    end
    local allTaskCount = self._TaskIndexShowDir[achievementId].MaxIndex
    return finishCount, allTaskCount
end

function XUiTheatre3Achievement:_GetAchievementTagRedPoint(achievementId)
    for _, data in ipairs(self._TaskDataListDir[achievementId]) do
        if data.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    return false
end
--endregion

--region Ui - Achievement
function XUiTheatre3Achievement:InitAchievementTab()
    ---@type XUiComponent.XUiButton[]
    self._AchievementTabList = {
        self.BtnTab01,
        self.BtnTab02,
        self.BtnTab03,
    }
    self.PanelTab:Init(self._AchievementTabList, handler(self, self._SelectAchievementTag))
end

function XUiTheatre3Achievement:_SelectAchievementTag(index)
    if self._CurSelectAchievementIndex == index then
        return
    end
    self._CurSelectAchievementIndex = index
    self:RefreshAchievementTab()
    self:RefreshTaskPanel()
    self:RefreshRewardPanel()
    self:PlayAnimationWithMask("QieHuan")
end

function XUiTheatre3Achievement:RefreshAchievementTab()
    for index, id in pairs(self._AchievementIdList) do
        if self._AchievementTabList[index] then
            local finishCount, allTaskCount = self:_GetAchievementProcessCount(id)
            self._AchievementTabList[index].gameObject:SetActiveEx(true)
            self._AchievementTabList[index]:ShowReddot(self:_GetAchievementTagRedPoint(id))
            self._AchievementTabList[index]:SetNameByGroup(0, self._Control:GetCfgAchievementTag(id))
            self._AchievementTabList[index]:SetNameByGroup(1, XUiHelper.GetText("MainFubenProgress", math.ceil(finishCount / allTaskCount * 100)))
        end
    end
    for i = #self._AchievementIdList + 1, #self._AchievementTabList do
        self._AchievementTabList[i].gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - Reward
function XUiTheatre3Achievement:InitRewardPanel()
    local XUiTheatre3AchvPanelReward = require("XUi/XUiTheatre3/Achievement/XUiTheatre3AchvPanelReward")
    ---@type XUiTheatre3AchvPanelReward
    self._RewardPanel = XUiTheatre3AchvPanelReward.New(self.PanelDetail, self)
end

function XUiTheatre3Achievement:RefreshRewardPanel()
    local allFinishCount, allTaskCount = self:_GetAllAchievementProcessCount()
    self._RewardPanel:Refresh(allFinishCount, allTaskCount)
end
--endregion

--region Ui - TaskPanel
function XUiTheatre3Achievement:InitTaskPanel()
    local XUiTheatre3AchvGridTask = require("XUi/XUiTheatre3/Achievement/XUiTheatre3AchvGridTask")
    ---@type XUiTheatre3AchvGridTask[]
    self._TaskGridList = { }
    for i = 1, self._TaskPerPageCount do
        local item = self["Item" .. i]
        item.gameObject:SetActiveEx(true)
        self._TaskGridList[i] = XUiTheatre3AchvGridTask.New(XUiHelper.Instantiate(self.PanelBagItem, item), self)
    end
    self.Content.gameObject:SetActiveEx(false)
end

function XUiTheatre3Achievement:RefreshTaskPanel()
    local id = self._AchievementIdList[self._CurSelectAchievementIndex]
    self:_RefreshTaskProcess(id)
    self:_RefreshTaskPage(id)
    if not XTool.IsNumberValid(id) then
        return
    end
    for i, v in ipairs(self._TaskGridList) do
        if self._TaskGridList[i] then
            self._TaskGridList[i]:Open()
        end
    end
    
    for i = self._TaskIndexShowDir[id].StartIndex, self._TaskIndexShowDir[id].EndIndex do
        local index = i % ((i == self._TaskPerPageCount) and (self._TaskPerPageCount + 1) or (self._TaskPerPageCount))
        local taskData = self._TaskDataListDir[id][i]
        if self._TaskGridList[index] then
            self._TaskGridList[index]:Refresh(taskData)
        end
    end
    local endIndex
    if self._TaskIndexShowDir[id].EndIndex == self._TaskPerPageCount then
        endIndex = self._TaskIndexShowDir[id].EndIndex % (self._TaskPerPageCount + 1)
    else
        endIndex = self._TaskIndexShowDir[id].EndIndex % (self._TaskPerPageCount)
    end
    for i = endIndex + 1, self._TaskPerPageCount do
        if self._TaskGridList[i] then
            self._TaskGridList[i]:Close()
        end
    end
end

function XUiTheatre3Achievement:_RefreshTaskPage(achievementId)
    local indexShow = self._TaskIndexShowDir[achievementId]
    local curPage = math.ceil(indexShow.EndIndex / self._TaskPerPageCount)
    self.TxtTurnPages.text = curPage .. " / " .. indexShow.AllPage
end

function XUiTheatre3Achievement:_RefreshTaskProcess(achievementId)
    local finishCount, allTaskCount = self:_GetAchievementProcessCount(achievementId)
    self.TxtQuantity.text = XUiHelper.GetText("Theatre3AchievementProcess", finishCount, allTaskCount)
end
--endregion

--region Ui - BtnListener
function XUiTheatre3Achievement:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnLeftArrow, self.OnClickLeftArrow)
    XUiHelper.RegisterClickEvent(self, self.BtnRightArrow, self.OnClickRightArrow)
    XUiHelper.RegisterClickEvent(self, self.BtnExclamatory, self.OnOpenAllReward)
end

function XUiTheatre3Achievement:OnBtnBackClick()
    self:Close()
end

function XUiTheatre3Achievement:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTheatre3Achievement:OnClickLeftArrow()
    local id = self._AchievementIdList[self._CurSelectAchievementIndex]
    if not XTool.IsNumberValid(id) then
        return
    end
    local indexShow = self._TaskIndexShowDir[id]
    local newStartIndex = indexShow.StartIndex - self._TaskPerPageCount
    local newEndIndex = indexShow.EndIndex - self._TaskPerPageCount
    if newStartIndex < 1 then
        indexShow.StartIndex = 1
        indexShow.EndIndex = math.min(indexShow.MaxIndex, self._TaskPerPageCount)
    else
        indexShow.StartIndex = newStartIndex
        indexShow.EndIndex = math.max(newEndIndex, self._TaskPerPageCount)
    end
    
    self:RefreshTaskPanel()
    self:PlayAnimationWithMask("QieHuan")
end

function XUiTheatre3Achievement:OnClickRightArrow()
    local id = self._AchievementIdList[self._CurSelectAchievementIndex]
    if not XTool.IsNumberValid(id) then
        return
    end
    local indexShow = self._TaskIndexShowDir[id]
    local newStartIndex = indexShow.StartIndex + self._TaskPerPageCount
    local newEndIndex = indexShow.EndIndex + self._TaskPerPageCount
    if newStartIndex > indexShow.MaxIndex then
        return
    else
        indexShow.StartIndex = newStartIndex
        indexShow.EndIndex = math.min(newEndIndex, indexShow.MaxIndex)
    end

    self:RefreshTaskPanel()
    self:PlayAnimationWithMask("QieHuan")
end

function XUiTheatre3Achievement:OnOpenAllReward()
    XLuaUiManager.Open("UiTheatre3PreviewTips")
end
--endregion

--region Event
function XUiTheatre3Achievement:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_ACHIEVEMENT_RECV_TASK, self._OnTaskFinish, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_ACHIEVEMENT_RECV_REWARD, self._OnTaskFinish, self)
end

function XUiTheatre3Achievement:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_ACHIEVEMENT_RECV_TASK, self._OnTaskFinish, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_ACHIEVEMENT_RECV_REWARD, self._OnTaskFinish, self)
end

function XUiTheatre3Achievement:_OnTaskFinish()
    self:_UpdateAchievementTaskData()
    self:RefreshAchievementTab()
    self:RefreshTaskPanel()
    self:RefreshRewardPanel()
    self:PlayAnimationWithMask("QieHuan")
end
--endregion

return XUiTheatre3Achievement