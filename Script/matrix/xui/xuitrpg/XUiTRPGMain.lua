local XUiTRPGPanelPlotTab = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelPlotTab")
local XUiTRPGPanelLevel = require("XUi/XUiTRPG/XUiTRPGPanel/XUiTRPGPanelLevel")

local CSXTextManagerGetText = CS.XTextManager.GetText
local ButtonStateDisable = CS.UiButtonState.Disable

--主界面
local XUiTRPGMain = XLuaUiManager.Register(XLuaUi, "UiTRPGMain")

function XUiTRPGMain:OnAwake()
    self.IsSwitchStatusOpenView = false     --是否从切换模式按钮打开本界面

    self.PanelPlotTab = XUiTRPGPanelPlotTab.New(self.PanelPlotTab, true)
    self.LevelPanel = XUiTRPGPanelLevel.New(self.PanelLevel)
    self:Init()
    self:AutoAddListener()
end

function XUiTRPGMain:OnStart(isSwitchStatusOpenView)
    self.IsSwitchStatusOpenView = isSwitchStatusOpenView
end

function XUiTRPGMain:OnEnable()
    local openAnimaName = self.IsSwitchStatusOpenView and "QieHuan" or "Enable"
    self:PlayAnimation(openAnimaName)
    self.IsSwitchStatusOpenView = false

    XDataCenter.TRPGManager.CheckActivityEnd()
    XDataCenter.TRPGManager.CheckOpenNewMazeTips()
    XEventManager.AddEventListener(XEventId.EVENT_TRPG_FUNCTION_FINISH_SYN, XDataCenter.TRPGManager.CheckOpenNewMazeTips, XDataCenter.TRPGManager)
    self.AreaOpenSchedule = XScheduleManager.ScheduleForever(function() self:UpdateAreaCanOpenTime() end, XScheduleManager.SECOND)
    self:Refresh()
    self:UpdateAreaCanOpenTime()
    self:OnCheckGridPanelChapterRedPoint()
    self:OnCheckSecondMainRedPoint()
    self.PanelPlotTab:Refresh()
end

function XUiTRPGMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRPG_FUNCTION_FINISH_SYN, XDataCenter.TRPGManager.CheckOpenNewMazeTips, XDataCenter.TRPGManager)
    XScheduleManager.UnSchedule(self.AreaOpenSchedule)
end

function XUiTRPGMain:OnDestroy()
    self.LevelPanel:Delete()
    self.PanelPlotTab:OnDestroy()
end

function XUiTRPGMain:Init()
    local areaMaxNum = XTRPGConfigs.GetMainAreaMaxNum()
    for gridPanelChapterIndex = 1, areaMaxNum do
        local name = XTRPGConfigs.GetMainAreaName(gridPanelChapterIndex)
        self["GridPanelChapter" .. gridPanelChapterIndex]:SetNameByGroup(0, name)
        self["TagWending" .. gridPanelChapterIndex] = XUiHelper.TryGetComponent(self["GridPanelChapter" .. gridPanelChapterIndex].transform, "TagWending")
        self["TagZhenya" .. gridPanelChapterIndex] = XUiHelper.TryGetComponent(self["GridPanelChapter" .. gridPanelChapterIndex].transform, "TagZhenya")
        self["TagHundun" .. gridPanelChapterIndex] = XUiHelper.TryGetComponent(self["GridPanelChapter" .. gridPanelChapterIndex].transform, "TagHundun")
        self["TagHundun2" .. gridPanelChapterIndex] = XUiHelper.TryGetComponent(self["GridPanelChapter" .. gridPanelChapterIndex].transform, "TagHundun2")
    end

    local bossHideEntranceTimeStr = XTRPGConfigs.GetBossHideEntranceTimeStr()
    local bossHideEntranceTime = XTime.ParseToTimestamp(bossHideEntranceTimeStr)
    local serverNowTimestamp = XTime.GetServerNowTimestamp()
    self.BtnWorldBoss.gameObject:SetActiveEx(serverNowTimestamp < bossHideEntranceTime)
end

function XUiTRPGMain:Refresh()
    local areaMaxNum = XTRPGConfigs.GetMainAreaMaxNum()
    for gridPanelChapterIndex = 1, areaMaxNum do
        local percent = XDataCenter.TRPGManager.GetAreaRewardPercent(gridPanelChapterIndex)
        self["GridPanelChapter" .. gridPanelChapterIndex]:SetNameByGroup(1, math.floor(percent * 100) .. "%")
    end
end

function XUiTRPGMain:UpdateAreaCanOpenTime()
    local isAllOpen = true

    local areaMaxNum = XTRPGConfigs.GetMainAreaMaxNum()
    for gridPanelChapterIndex = 1, areaMaxNum do
        local state = XDataCenter.TRPGManager.GetAreaState(gridPanelChapterIndex)
        local isNotOpen = state == XTRPGConfigs.AreaStateType.NotOpen
        self["GridPanelChapter" .. gridPanelChapterIndex]:SetDisable(isNotOpen, not isNotOpen)

        local percent = XDataCenter.TRPGManager.GetAreaRewardPercent(gridPanelChapterIndex)
        self["TagWending" .. gridPanelChapterIndex].gameObject:SetActiveEx((state == XTRPGConfigs.AreaStateType.Open or state == XTRPGConfigs.AreaStateType.Over) and percent == 1)
        self["TagZhenya" .. gridPanelChapterIndex].gameObject:SetActiveEx(state == XTRPGConfigs.AreaStateType.Open and percent > 0 and percent < 1)
        self["TagHundun" .. gridPanelChapterIndex].gameObject:SetActiveEx(state == XTRPGConfigs.AreaStateType.NotOpen)
        self["TagHundun2" .. gridPanelChapterIndex].gameObject:SetActiveEx(state == XTRPGConfigs.AreaStateType.Open and percent == 0)

        if isNotOpen then
            isAllOpen = false
            local timeStamp = XTRPGConfigs.GetAreaOpenLastTimeStamp(gridPanelChapterIndex)
            local timeStr = XUiHelper.GetTime(timeStamp, XUiHelper.TimeFormatType.ACTIVITY)
            local str = CSXTextManagerGetText("TRPGMainAreaCanOpenTime", timeStr)
            self["GridPanelChapter" .. gridPanelChapterIndex]:SetNameByGroup(2, str)
        end
    end

    local openState, time = XDataCenter.TRPGManager.GetWorldBossOpenState()
    local timeStr = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
    local str
    if openState == XTRPGConfigs.AreaStateType.NotOpen then
        str = CSXTextManagerGetText("TRPGBossOpenTime", timeStr)
        self.BtnWorldBoss:SetNameByGroup(1, str)
        if self.BtnWorldBoss.ButtonState ~= ButtonStateDisable then     --防止定时器频繁设置按钮状态影响特效播放
            self.BtnWorldBoss:SetDisable(true)
        end
        self.BtnWorldBoss:ShowTag(false)
        isAllOpen = false
    elseif openState == XTRPGConfigs.AreaStateType.Open then
        str = CSXTextManagerGetText("TRPGBossCloseTime", timeStr)
        self.BtnWorldBoss:SetNameByGroup(1, str)
        if self.BtnWorldBoss.ButtonState == ButtonStateDisable then
            self.BtnWorldBoss:SetDisable(false)
        end
        self.BtnWorldBoss:ShowTag(false)
        isAllOpen = false
    else
        self.BtnWorldBoss:SetNameByGroup(1, "")
        if self.BtnWorldBoss.ButtonState ~= ButtonStateDisable then
            self.BtnWorldBoss:SetDisable(true)
        end
        self.BtnWorldBoss:ShowTag(true)
    end

    if isAllOpen then
        XScheduleManager.UnSchedule(self.AreaOpenSchedule)
    end
end

function XUiTRPGMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelpCourse, "TRPGMainLine")
    self.BtnWorldBoss.CallBack = function() self:OnBtnWorldBossClick() end
    self:RegisterClickEvent(self.PanelCut, self.OnPanelCutClick)

    local areaMaxNum = XTRPGConfigs.GetMainAreaMaxNum()
    for i = 1, areaMaxNum do
        self["GridPanelChapter" .. i].CallBack = function() self:OnGridPanelChapterClick(i) end
    end
end

--切换模式
function XUiTRPGMain:OnPanelCutClick()
    XDataCenter.TRPGManager.RequestTRPGChangePageStatus(true)
    XLuaUiManager.PopThenOpen("UiTRPGSecondMain", true)
end

function XUiTRPGMain:OnBtnWorldBossClick()
    local openState = XDataCenter.TRPGManager.GetWorldBossOpenState()
    if openState ~= XTRPGConfigs.AreaStateType.Open then
        XUiManager.TipText("TPRGWorldBossNotInActivityTime")
        return
    end
    XLuaUiManager.Open("UiTRPGWorldBossBossArea")
end

function XUiTRPGMain:OnGridPanelChapterClick(index)
    local condition = XTRPGConfigs.GetMainAreaCondition(index)
    local ret, desc = XConditionManager.CheckCondition(condition)
    if not ret then
        XUiManager.TipError(desc)
        return
    end
    XLuaUiManager.Open("UiTRPGExploreRegion", index)
end

function XUiTRPGMain:OnBtnBackClick()
    self:Close()
end

function XUiTRPGMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTRPGMain:OnCheckGridPanelChapterRedPoint()
    local areaMaxNum = XTRPGConfigs.GetMainAreaMaxNum()
    local isShow
    for areaId = 1, areaMaxNum do
        if self["GridPanelChapter" .. areaId] then
            isShow = XDataCenter.TRPGManager.CheckAreaRewardByAreaId(areaId)
            self["GridPanelChapter" .. areaId]:ShowReddot(isShow)
        end
    end
    isShow = XDataCenter.TRPGManager.CheckWorldBossReward()
    self.BtnWorldBoss:ShowReddot(isShow)
end

function XUiTRPGMain:OnCheckSecondMainRedPoint()
    local isShowRedPoint = XDataCenter.TRPGManager.IsSecondMainReward()
    self.PanelCut:ShowReddot(isShowRedPoint)
end

function XUiTRPGMain:OnGetEvents()
    return {XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE}
end

function XUiTRPGMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE then
        XDataCenter.TRPGManager.OnActivityMainLineStateChange(...)
    end
end