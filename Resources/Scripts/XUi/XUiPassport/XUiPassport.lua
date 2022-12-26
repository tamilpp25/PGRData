local XUiPassportPanel = require("XUi/XUiPassport/XUiPassportPanel")
local XUiPassportPanelTaskActivity = require("XUi/XUiPassport/XUiPassportPanelTaskActivity")
local XUiPassportPanelTaskDaily = require("XUi/XUiPassport/XUiPassportPanelTaskDaily")
local XUiPassportPanelTaskWeekly = require("XUi/XUiPassport/XUiPassportPanelTaskWeekly")

local XUiPassport = XLuaUiManager.Register(XLuaUi, "UiPassport")

local tableInsert = table.insert
local BtnTaskChildMaxCount = 3     --任务页签的子页签最大数量
local BtnGetClickDefaultIndex = 3   --点击跳转至挑战任务页签的下标

--战斗通行证主界面
function XUiPassport:OnAwake()
    self.CurWeeklyGroupId = XPassportConfigs.GetPassportTaskGroupIdByType(XPassportConfigs.TaskType.Weekly)      --记录当前第几周
end

function XUiPassport:OnStart()
    self:InitPanel()
    self:RegisterButtonEvent()
    self:InitUi()
    self:InitTab()
    self:InitRedPoint()
end

function XUiPassport:OnEnable()
    self:CheckOpenAutoGetTaskRewardListView()

    if not XDataCenter.PassportManager.CheckActivityIsOpen() then
        return
    end

    XEventManager.AddEventListener(XEventId.EVENT_BUY_EXP_COMPLEATE, self.UpdatePanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO, self.UpdateLevel, self)
    XEventManager.AddEventListener(XEventId.EVENT_AUTO_GET_TASK_REWARD_LIST, self.CheckOpenAutoGetTaskRewardListView, self)
    self:Refresh()

    self:StartTimer()
end

function XUiPassport:OnDisable()
    self:StopTimer()
    for _, panel in ipairs(self.PanelViews) do
        if not XTool.IsTableEmpty(panel) then
            panel:Hide()
        end
    end
    XEventManager.RemoveEventListener(XEventId.EVENT_BUY_EXP_COMPLEATE, self.UpdatePanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO, self.UpdateLevel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AUTO_GET_TASK_REWARD_LIST, self.CheckOpenAutoGetTaskRewardListView, self)
end

--未按时领取的任务奖励，等打开该界面再弹出提示
function XUiPassport:CheckOpenAutoGetTaskRewardListView()
    local rewardList = XDataCenter.PassportManager.GetCookieAutoGetTaskRewardList()
    if not XTool.IsTableEmpty(rewardList) then
        local title = CS.XTextManager.GetText("PassportAutoGetTipsTitle")
        local desc = CS.XTextManager.GetText("PassportAutoGetTipsDesc")
        XLuaUiManager.Open("UiPassportTips", rewardList, title, desc)

        XDataCenter.PassportManager.ClearCookieAutoGetTaskRewardList()
    end
end

function XUiPassport:InitRedPoint()
    XRedPointManager.AddRedPointEvent(self.Btn01, self.OnCheckRewardRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_PANEL_REWARD_RED })
    XRedPointManager.AddRedPointEvent(self.Btn02, self.OnCheckTaskRedPoint, self,
        { XRedPointConditions.Types.CONDITION_PASSPORT_TASK_DAILY_RED,
            XRedPointConditions.Types.CONDITION_PASSPORT_TASK_WEEKLY_RED,
            XRedPointConditions.Types.CONDITION_PASSPORT_TASK_ACTIVITY_RED })
    XRedPointManager.AddRedPointEvent(self.BtnChild01, self.OnCheckTaskDailyRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_TASK_DAILY_RED })
    XRedPointManager.AddRedPointEvent(self.BtnChild02, self.OnCheckTaskWeeklyRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_TASK_WEEKLY_RED })
    XRedPointManager.AddRedPointEvent(self.BtnChild03, self.OnCheckTaskActivityRedPoint, self, { XRedPointConditions.Types.CONDITION_PASSPORT_TASK_ACTIVITY_RED })
end

function XUiPassport:InitPanel()
    self.PassportPanel = XUiPassportPanel.New(self.PanelPassport, self)
    self.PassportPanelTaskActivity = XUiPassportPanelTaskActivity.New(self.PanelTaskActivity, self)
    self.PassportPanelTaskDaily = XUiPassportPanelTaskDaily.New(self.PanelTaskDaily, self)
    self.PassportPanelTaskWeekly = XUiPassportPanelTaskWeekly.New(self.PanelTaskWeekly, self)
    self:InitSubPanel()
end

function XUiPassport:InitSubPanel()
    self.PanelViews = {}
    tableInsert(self.PanelViews, self.PassportPanel)
    tableInsert(self.PanelViews, {})    --为了和页签数量相同占位用
    tableInsert(self.PanelViews, self.PassportPanelTaskDaily)
    tableInsert(self.PanelViews, self.PassportPanelTaskWeekly)
    tableInsert(self.PanelViews, self.PassportPanelTaskActivity)
end

function XUiPassport:InitTab()
    self.BtnGroupList = {}

    tableInsert(self.BtnGroupList, self.Btn01)     --战略补给
    tableInsert(self.BtnGroupList, self.Btn02)     --任务

    --任务下的子页签
    local tagCount = #self.BtnGroupList
    local btn
    for i = 1, BtnTaskChildMaxCount do
        btn = self["BtnChild0" .. i]
        if btn then
            self["BtnChild0" .. i].SubGroupIndex = tagCount
            tableInsert(self.BtnGroupList, btn)
        end
    end
    
    local defaultTagIndex = XDataCenter.PassportManager.GetCurrMainViewSelectTagIndex()
    self.PanelNoticeTitleBtnGroup:Init(self.BtnGroupList, function(index) self:OnSelectedTag(index) end)
    self.PanelNoticeTitleBtnGroup:SelectIndex(defaultTagIndex)
end

function XUiPassport:OnSelectedTag(index)
    if self.CurrSelectTagIndex == index then
        return
    end

    self.CurrSelectTagIndex = index
    XDataCenter.PassportManager.CatchCurrMainViewSelectTagIndex(index)
    self:UpdatePanel()
end

function XUiPassport:InitUi()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    self.ItemIdList = {XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin}
    for _, itemId in ipairs(self.ItemIdList) do
        XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
            self.AssetActivityPanel:Refresh(self.ItemIdList)
        end, self.AssetActivityPanel)
    end
    self.AssetActivityPanel:Refresh(self.ItemIdList)

    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.PassportExp, function()
        self:UpdateExp()
    end, self)
end

function XUiPassport:Refresh()
    self:UpdateActivityTime()
    self:UpdateLevel()
    self:UpdateExp()
    self:UpdatePanel()
end

function XUiPassport:UpdatePanel()
    local currSelectTagIndex = self:GetCurrSelectTagIndex()
    for i, panel in ipairs(self.PanelViews) do
        if i == currSelectTagIndex then
            panel:Show()
        elseif not XTool.IsTableEmpty(panel) then
            panel:Hide()
        end
    end
end

function XUiPassport:UpdateTaskPanel()
    self.PassportPanelTaskDaily:Refresh()
    self.PassportPanelTaskActivity:Refresh()
    self.PassportPanelTaskWeekly:Refresh()
end

function XUiPassport:UpdateLevel()
    local passportBaseInfo = XDataCenter.PassportManager.GetPassportBaseInfo()
    local level = passportBaseInfo:GetLevel()
    self.TxtLevel.text = level
end

function XUiPassport:UpdateExp()
    local passportBaseInfo = XDataCenter.PassportManager.GetPassportBaseInfo()
    local itemId = XDataCenter.ItemManager.ItemId.PassportExp
    local curExp = XDataCenter.ItemManager.GetCount(itemId)
    local level = passportBaseInfo:GetLevel()
    local maxLevel = XPassportConfigs.GetPassportMaxLevel()

    local curLevelId = XTool.IsNumberValid(level) and XPassportConfigs.GetPassportLevelId(level)
    local curLevelExp = curLevelId and XPassportConfigs.GetPassportLevelTotalExp(curLevelId) or 0

    local upperLevel = level - 1

    local nextLevel = math.min(maxLevel, level + 1)
    local nextLevelId = XPassportConfigs.GetPassportLevelId(nextLevel)
    local nextLevelTotalExp = nextLevelId and XPassportConfigs.GetPassportLevelTotalExp(nextLevelId)

    curExp = upperLevel > 0 and curExp - curLevelExp or curExp
    nextLevelTotalExp = (upperLevel > 0 and XTool.IsNumberValid(nextLevelTotalExp)) and nextLevelTotalExp - curLevelExp or nextLevelTotalExp    --初始等级1服务端下发的经验是0
    local progress = XTool.IsNumberValid(nextLevelTotalExp) and curExp / nextLevelTotalExp or 0
    
    self.TxtPointNum.text = string.format("%s/%s", curExp, nextLevelTotalExp)   --（玩家总经验-之前等级升级需要经验之和）/ 升至下一等级需要的经验
    self.ImgProgress.fillAmount = math.min(1, progress)
end

function XUiPassport:UpdateActivityTime()
    local timeId = XPassportConfigs.GetPassportActivityTimeId()
    local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
    local startTimeStr = os.date("%m/%d",startTime)
    local endTimeStr = os.date("%m/%d",endTime)
    local totleWeekly, currWeekly = XPassportConfigs.GetPassportWeeklyTaskGroupCountAndCurrWeekly()
    self.TxtTime01.text = CS.XTextManager.GetText("PassportActivityTime", startTimeStr, endTimeStr, totleWeekly)
    self.TxtTime02.text = CS.XTextManager.GetText("PassportActivityCurrWeekly", currWeekly) 
end

function XUiPassport:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:RegisterClickEvent(self.BtnGet, self.OnBtnGetClick)
    self:RegisterClickEvent(self.BtnBuy, self.OnBtnBuyClick)
    self:BindHelpBtn(self.BtnHelp, "Passport")
end

--跳转至挑战任务页签
function XUiPassport:OnBtnGetClick()
    self.PanelNoticeTitleBtnGroup:SelectIndex(BtnGetClickDefaultIndex)
end

--购买等级
function XUiPassport:OnBtnBuyClick()
    local passportBaseInfo = XDataCenter.PassportManager.GetPassportBaseInfo()
    local level = passportBaseInfo:GetLevel()
    local maxLevel = XPassportConfigs.GetPassportMaxLevel()
    if level >= maxLevel then
        XUiManager.TipText("PassportBuyLevelMaxDesc")
        return
    end
    XLuaUiManager.Open("UiPassportUpLevel", handler(self, self.Refresh))
end

function XUiPassport:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiPassport:OnNotify(event)
    if event == XEventId.EVENT_FINISH_TASK
        or event == XEventId.EVENT_TASK_SYNC then
        self:UpdateTaskPanel()
    end
end

function XUiPassport:GetCurrSelectTagIndex()
    return self.CurrSelectTagIndex
end

function XUiPassport:OnCheckRewardRedPoint(count)
    self.Btn01:ShowReddot(count >= 0)
end

function XUiPassport:OnCheckTaskRedPoint(count)
    self.Btn02:ShowReddot(count >= 0)
end

function XUiPassport:OnCheckTaskDailyRedPoint(count)
    self.BtnChild01:ShowReddot(count >= 0)
end

function XUiPassport:OnCheckTaskWeeklyRedPoint(count)
    self.BtnChild02:ShowReddot(count >= 0)
end

function XUiPassport:OnCheckTaskActivityRedPoint(count)
    self.BtnChild03:ShowReddot(count >= 0)
end

function XUiPassport:StartTimer()
    self:StopTimer()
    local curWeeklyGroupId
    self.Timer = XScheduleManager.ScheduleForever(function()
        if not XDataCenter.PassportManager.CheckActivityIsOpen() then
            return
        end

        curWeeklyGroupId = XPassportConfigs.GetPassportTaskGroupIdByType(XPassportConfigs.TaskType.Weekly)
        if curWeeklyGroupId ~= self.CurWeeklyGroupId then
            self.CurWeeklyGroupId = curWeeklyGroupId
            self:Refresh()
            return
        end

        self.PassportPanelTaskWeekly:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiPassport:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end