local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiLivWarmRaceStageGroup = require("XUi/XUiLivWarmRace/XUiLivWarmRaceStageGroup")

--二周年预热-赛跑小游戏 关卡界面
local XUiLivWarmRaceFightMain = XLuaUiManager.Register(XLuaUi, "UiLivWarmRaceFightMain")

function XUiLivWarmRaceFightMain:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XLivWarmRaceConfigs.GetActivityConsumeId())
    self:AutoAddListener()
end

function XUiLivWarmRaceFightMain:OnStart(groupId)
    if self.LastData then
        self.GroupId = self.LastData.groupId or groupId
        self.LastData = nil
    else
        self.GroupId = groupId
    end
    self.TxtTitle.text = XLivWarmRaceConfigs.GetGroupName(groupId)
    self:InitStagesMap(groupId)
end

function XUiLivWarmRaceFightMain:OnEnable()
    self:Refresh()
    self:StartTimer()
end

function XUiLivWarmRaceFightMain:OnDisable()
    self:RemoveTimer()
end

function XUiLivWarmRaceFightMain:InitStagesMap(groupId)
    local prefabName = XLivWarmRaceConfigs.GetGroupPrefab(groupId)
    local prefab = self.PanelChapter:LoadPrefab(prefabName)
    if prefab == nil or not prefab:Exist() then
        return
    end
    self.CurStages = XUiLivWarmRaceStageGroup.New(prefab, groupId, function(stageId) self:OpenEnterDialog(stageId) end)
    self.CurStages:SetParent(self.PanelChapter)
end

function XUiLivWarmRaceFightMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "LivWarmRace")
end

function XUiLivWarmRaceFightMain:Refresh()
    self.CurStages:UpdateStagesMap()
end

function XUiLivWarmRaceFightMain:StartTimer()
    self:RemoveTimer()
    self:RefreshActivityTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        if not XDataCenter.LivWarmRaceManager.CheckActivityIsOpen() then
            return
        end
        self:RefreshActivityTime()
    end, XScheduleManager.SECOND)
end

function XUiLivWarmRaceFightMain:RefreshActivityTime()
    local timeId = XLivWarmRaceConfigs.GetActivityTimeId()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local now = XTime.GetServerNowTimestamp()
    local offset = endTime - now
    self.TxtTime.text = XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiLivWarmRaceFightMain:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiLivWarmRaceFightMain:OpenEnterDialog(stageId)
    local closeCb = function()
        self.CurStages:CancalSelectLastGrid()
    end

    XLuaUiManager.Open("UiLivWarmRaceDetail", stageId, closeCb, self.GroupId)
end

function XUiLivWarmRaceFightMain:OnReleaseInst()
    return { GroupId = self.GroupId }
end

function XUiLivWarmRaceFightMain:OnResume(data)
    self.LastData = data
end