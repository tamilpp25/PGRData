local XUiGridCalendar = require("XUi/XUiNewActivityCalendar/XUiGridCalendar")

---@class XUiPanelActivityCalendar : XUiNode
---@field _Control XNewActivityCalendarControl
---@field Parent XUiMainLeftCalendar
---@field PanelScrollRect UnityEngine.UI.ScrollRect
local XUiPanelActivityCalendar = XClass(XUiNode, "XUiPanelActivityCalendar")

function XUiPanelActivityCalendar:OnStart()
    self.GridCalendar.gameObject.SetActiveEx(false)
    ---@type XUiGridCalendar[]
    self.GridTimeLimitActivity = {}
    ---@type XUiGridCalendar[]
    self.GridWeekActivity = {}

    self.IsFinishTimeLimit = false
    self.IsFinishWeek = false

    self.MaxShowWeekCount = 2

    XUiHelper.RegisterClickEvent(self, self.BtnDorm, self.OnBtnDormClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEdit, self.OnBtnEditClick)
end

function XUiPanelActivityCalendar:Refresh(isPlayAnim)
    self.IsPlayAnim = isPlayAnim
    self:RefreshDormQuest()
    self:RefreshWeekActivity()
    self:RefreshTimeLimitActivity()
    self.PanelTip.gameObject:SetActiveEx(self.IsFinishTimeLimit and self.IsFinishWeek)
    -- 开启计时器
    self:StartTimer()
    -- 刷新时从第一个进行显示
    if self.PanelScrollRect then
        self.PanelScrollRect.verticalNormalizedPosition = 1
    end
    -- 播放动画
    if self.IsPlayAnim then
        self:PlayEnableAnim()
    end
end

function XUiPanelActivityCalendar:OnDisable()
    self:StopTimer()
end

function XUiPanelActivityCalendar:RefreshDormQuest()
    local isShow = self._Control:CheckIsShowDormQuest()
    self.BtnDorm.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtWord.text = self._Control:GetDormQuestDesc()
    end
end

function XUiPanelActivityCalendar:RefreshWeekActivity()
    local isShowWeek = self._Control:CheckIsShowWeekEntrance()
    self.PanelWeeklyTitle.gameObject:SetActiveEx(isShowWeek)
    self.PanelWeeklyList.gameObject:SetActiveEx(isShowWeek)
    if not isShowWeek then
        -- 不显示时默认全部完成了
        self.IsFinishWeek = true
        return
    end
    local mainIds = self._Control:GetWeekMainIds(self.MaxShowWeekCount)
    self.IsFinishWeek = XTool.IsTableEmpty(mainIds)
    self.ImgWeekGouYes.gameObject:SetActiveEx(self.IsFinishWeek)
    self.ImgWeekGoNo.gameObject:SetActiveEx(not self.IsFinishWeek)
    for index, id in pairs(mainIds) do
        local grid = self.GridWeekActivity[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridCalendar, self.PanelWeeklyList)
            grid = XUiGridCalendar.New(go, self.Parent)
            self.GridWeekActivity[index] = grid
        end
        grid:Open()
        grid:UpdateTheme(self.Parent.ThemeData)
        grid:SetCanvasAlpha(self.IsPlayAnim and 0 or 1)
        grid:Refresh(id, XEnumConst.NewActivityCalendar.ActivityType.Week)
    end
    for i = #mainIds + 1, #self.GridWeekActivity do
        self.GridWeekActivity[i]:Close()
    end
end

function XUiPanelActivityCalendar:RefreshTimeLimitActivity()
    local activityInfo = self._Control:GetTimeLimitActivityIds()
    self.IsFinishTimeLimit = XTool.IsTableEmpty(activityInfo)
    self.ImgLimitedTimeGouYes.gameObject:SetActiveEx(self.IsFinishTimeLimit)
    self.ImgLimitedTimeGoNo.gameObject:SetActiveEx(not self.IsFinishTimeLimit)
    for index, id in pairs(activityInfo) do
        local grid = self.GridTimeLimitActivity[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridCalendar, self.PanelLimitedTimeList)
            grid = XUiGridCalendar.New(go, self.Parent)
            self.GridTimeLimitActivity[index] = grid
        end
        grid:Open()
        grid:UpdateTheme(self.Parent.ThemeData)
        grid:SetCanvasAlpha(self.IsPlayAnim and 0 or 1)
        grid:Refresh(id, XEnumConst.NewActivityCalendar.ActivityType.TimeLimit)
    end
    for i = #activityInfo + 1, #self.GridTimeLimitActivity do
        self.GridTimeLimitActivity[i]:Close()
    end
end

function XUiPanelActivityCalendar:OnBtnDormClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DormQuest) then
        return
    end
    local dict = {}
    dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnCalendar
    dict["role_level"] = XPlayer.GetLevel()
    dict["ui_second_button"] = XGlobalVar.BtnDorm.BtnUiDormBtnEntrust
    CS.XRecord.Record(dict, "200004", "UiOpen")
    XHomeDormManager.EnterDorm(XPlayer.Id, nil, false, function()
        XLuaUiManager.Open("UiDormTerminalSystem")
    end)
end

function XUiPanelActivityCalendar:OnBtnEditClick()
    self.Parent:OpenEditCalendar()
end

function XUiPanelActivityCalendar:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    self:UpdateTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, XScheduleManager.SECOND)
end

function XUiPanelActivityCalendar:UpdateTimer()
    if XTool.UObjIsNil(self.GameObject) then
        self:StopTimer()
        return
    end
    for _, grid in pairs(self.GridWeekActivity) do
        if grid:IsNodeShow() then
            grid:RefreshTimer()
        end
    end
    for _, grid in pairs(self.GridTimeLimitActivity) do
        if grid:IsNodeShow() then
            grid:RefreshTimer()
        end
    end
end

function XUiPanelActivityCalendar:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

-- 播放动画
function XUiPanelActivityCalendar:PlayEnableAnim()
    RunAsyn(function()
        asynWaitSecond(0.1)
        for _, grid in pairs(self.GridWeekActivity) do
            if not XTool.UObjIsNil(grid.GameObject) and grid:IsNodeShow() and grid.GameObject.activeInHierarchy then
                grid:PlayEnableAnim()
                asynWaitSecond(0.095)
            end
        end
        for _, grid in pairs(self.GridTimeLimitActivity) do
            if not XTool.UObjIsNil(grid.GameObject) and grid:IsNodeShow() and grid.GameObject.activeInHierarchy then
                grid:PlayEnableAnim()
                asynWaitSecond(0.095)
            end
        end
    end)
end

return XUiPanelActivityCalendar
