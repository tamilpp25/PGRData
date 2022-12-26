local XUiRpgMakerGameStages = require("XUi/XUiRpgMakerGame/Main/XUiRpgMakerGameStages")
local XUiRpgMakerGameTabBtn = require("XUi/XUiRpgMakerGame/Main/XUiRpgMakerGameTabBtn")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

--功能主界面
local XUiRpgMakerGameMain = XLuaUiManager.Register(XLuaUi, "UiRpgMakerGameMain")

function XUiRpgMakerGameMain:OnAwake()
    self.NewStageId = 0    --最近解锁的关卡
    self:AutoAddListener()
    self:InitTabGroup()
end

function XUiRpgMakerGameMain:OnStart()
    local defaultButtonGroupIndex = self:GetDefaultButtonGroupIndex()
    self.UiContentButtonGroup:SelectIndex(defaultButtonGroupIndex)
end

function XUiRpgMakerGameMain:OnEnable()
    self:UpdateNewStageId()
    self:Refresh()
    self:StartActivityTimer()
end

function XUiRpgMakerGameMain:OnDisable()
    self:StopActivityTimer()
end

function XUiRpgMakerGameMain:UpdateNewStageId()
    local allStageIdList = XRpgMakerGameConfigs.GetRpgMakerGameAllStageIdList()
    local stageIdTemp
    for _, stageId in ipairs(allStageIdList) do
        if not XDataCenter.RpgMakerGameManager.IsStageClear(stageId) then
            self.NewStageId = stageId
            return
        end
    end
    self.NewStageId = 0
end

function XUiRpgMakerGameMain:StartActivityTimer()
    self:StopActivityTimer()
    if not XDataCenter.RpgMakerGameManager.CheckActivityIsOpen() then
        return
    end

    self:RefreshActivityTime()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function() 
        if not XDataCenter.RpgMakerGameManager.CheckActivityIsOpen() then
            return
        end
        self:RefreshActivityTime()
    end, XScheduleManager.SECOND)
end

function XUiRpgMakerGameMain:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiRpgMakerGameMain:RefreshActivityTime()
    local id = XRpgMakerGameConfigs.GetDefaultActivityId()
    local timeId = XRpgMakerGameConfigs.GetRpgMakerGameActivityTimeId(id)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local now = XTime.GetServerNowTimestamp()
    local offset = endTime - now
    if self.TxtDay then
        self.TxtDay.text = XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.ACTIVITY)
    end

    for _, tabBtn in ipairs(self.TabBtnTemplates) do
        tabBtn:RefreshTimer()
    end
end

function XUiRpgMakerGameMain:InitTabGroup()
    self.TabBtns = {}
    self.TabBtnTemplates = {}
    local chapterIdList = XRpgMakerGameConfigs.GetRpgMakerGameChapterIdList()
    for i, chapterId in ipairs(chapterIdList) do
        self.TabBtns[i] = i == 1 and self.BtnPlotTab or CSUnityEngineObjectInstantiate(self.BtnPlotTab, self.UiContent)
        self.TabBtnTemplates[i] = XUiRpgMakerGameTabBtn.New(self.TabBtns[i], chapterId, i)
    end

    self.UiContentButtonGroup = self.UiContent:GetComponent("XUiButtonGroup")
    self.UiContentButtonGroup:Init(self.TabBtns, function(groupIndex) self:TabGroupSkip(groupIndex) end)
end

function XUiRpgMakerGameMain:GetDefaultButtonGroupIndex()
    local groupIndex = XDataCenter.RpgMakerGameManager.GetCurrClearButtonGroupIndex()
    if groupIndex then
        return groupIndex
    end

    local allStageIdList = XRpgMakerGameConfigs.GetRpgMakerGameAllStageIdList()
    local chapterId
    local defaultGroupIndex = 1
    for _, stageId in ipairs(allStageIdList) do
        if not XDataCenter.RpgMakerGameManager.IsStageUnLock(stageId) then
            chapterId = XRpgMakerGameConfigs.GetRpgMakerGameStageChapterId(stageId)
            groupIndex = self:GetTabBtnIndex(chapterId) or defaultGroupIndex
            return groupIndex
        end
    end

    return defaultGroupIndex
end

function XUiRpgMakerGameMain:GetTabBtnIndex(chapterId)
    local tabBtnTemplates = self:GetTabBtnTemplates()
    for _, v in ipairs(tabBtnTemplates) do
        if v:GetChapterId() == chapterId then
            return v:GetTabBtnIndex()
        end
    end
end

function XUiRpgMakerGameMain:TabGroupSkip(groupIndex)
    if self.TabGroupIndex == groupIndex then
        return
    end

    local chapterId = XRpgMakerGameConfigs.GetRpgMakerGameChapterId(groupIndex)
    local isUnLock = XDataCenter.RpgMakerGameManager.IsChapterUnLock(chapterId)
    if not isUnLock then
        local timeId = XRpgMakerGameConfigs.GetRpgMakerGameChapterOpenTimeId(chapterId)
        local time = XFunctionManager.GetStartTimeByTimeId(timeId)
        local serverTimestamp = XTime.GetServerNowTimestamp()
        local str = CS.XTextManager.GetText("ScheOpenCountdown", XUiHelper.GetTime(time - serverTimestamp, XUiHelper.TimeFormatType.RPG_MAKER_GAME))
        XUiManager.TipMsg(str)

        if self.TabGroupIndex then
            self.UiContentButtonGroup:SelectIndex(self.TabGroupIndex)
        end
        return
    end

    self:PlayAnimation("QieHuan")
    self.TabGroupIndex = groupIndex
    XDataCenter.RpgMakerGameManager.SetCurrTabGroupIndexByUiMainTemp(groupIndex)
    self:Refresh()
end

function XUiRpgMakerGameMain:AutoAddListener()
    self:RegisterClickEvent(self.SceneBtnBack, self.Close)
    self:RegisterClickEvent(self.SceneBtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnActDesc, "RpgMakerGame")
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
end

function XUiRpgMakerGameMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiRpgMakerGameMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiRpgMakerGamePlayTask")
end

function XUiRpgMakerGameMain:Refresh()
    self:UpdateStagesMap()
    self:UpdateTabBtnTemplates()
    self:UpdateTaskRedPoint()
end

function XUiRpgMakerGameMain:UpdateTaskRedPoint()
    local isShowRedPoint = XDataCenter.RpgMakerGameManager.CheckRedPoint()
    self.BtnTask:ShowReddot(isShowRedPoint)
end

function XUiRpgMakerGameMain:UpdateStagesMap()
    if not self.TabGroupIndex then
        return
    end

    local chapterId = XRpgMakerGameConfigs.GetRpgMakerGameChapterId(self.TabGroupIndex)
    if chapterId ~= self.ChapterId then
        local prefabName = XRpgMakerGameConfigs.GetRpgMakerGameChapterPrefab(chapterId)
        local prefab = self.PanelChapter:LoadPrefab(prefabName)
        if prefab == nil or not prefab:Exist() then
            return
        end
        self.ChapterId = chapterId
        self.CurStages = XUiRpgMakerGameStages.New(prefab, chapterId, function(stageId) self:OpenEnterDialog(stageId) end)
    end

    local newStageId = self:GetNewStageId()
    self.CurStages:Refresh(newStageId)
end

function XUiRpgMakerGameMain:UpdateTabBtnTemplates()
    for _, tabBtn in ipairs(self.TabBtnTemplates) do
        tabBtn:Refresh()
    end
end

function XUiRpgMakerGameMain:GetTabBtnTemplates()
    return self.TabBtnTemplates
end

function XUiRpgMakerGameMain:GetNewStageId()
    return self.NewStageId
end