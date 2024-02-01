---@class XUiFangKuaiMain : XLuaUi 大方块主界面
---@field _Control XFangKuaiControl
local XUiFangKuaiMain = XLuaUiManager.Register(XLuaUi, "UiFangKuaiMain")

function XUiFangKuaiMain:OnAwake()
    ---@type table<boolean,table<number,XUiGridFangKuaiChapter>>
    self._StageGrid = {}
    self:RegisterClickEvent(self.BtnSkip, self.OnClickSkip)
    self:RegisterClickEvent(self.BtnTask, self.OnClickTask)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpId())
end

function XUiFangKuaiMain:OnStart()
    self._IsNormal = true
    self._IsHardOpen, self._hardTimeStr = self._Control:IsOpenHardChapter()
    self.BtnSkip:SetButtonState(self._IsHardOpen and CS.UiButtonState.Normal or CS.UiButtonState.Disable)

    self:InitCompnent()

    self.EndTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        else
            self:CountDown()
            if not self._IsHardOpen then
                local isHardOpen = self._Control:IsOpenHardChapter()
                if isHardOpen then
                    self._IsHardOpen = true
                    self.BtnSkip:SetButtonState(CS.UiButtonState.Normal)
                end
            end
        end
    end, nil, 0)
end

function XUiFangKuaiMain:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateTask()
    self:UpdateChapter()
end

function XUiFangKuaiMain:OnDestroy()
    self:StopCountDown()
    self:StopBubbleTimer()
end

function XUiFangKuaiMain:InitCompnent()
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
end

function XUiFangKuaiMain:UpdateTask()
    if self._Control:IsAllTaskFinish() then
        self.PanelItem.gameObject:SetActiveEx(false)
        self.BtnTask:ShowReddot(false)
        return
    end

    local rewards = self._Control:GetBubbleReward()
    local keepTime = self._Control:GetBubbleKeepTime()
    self.PanelItem.gameObject:SetActiveEx(true)
    XUiHelper.RefreshCustomizedList(self.PanelItem, self.Grid256New, #rewards, function(index, grid)
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self, grid)
        grid:Refresh(rewards[index])
        grid:SetName("")
    end)

    self:StopBubbleTimer()
    self._BubbleTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelItem.gameObject:SetActiveEx(false)
    end, keepTime)

    local isRed = self._Control:CheckTaskRedPoint()
    self.BtnTask:ShowReddot(isRed)
end

function XUiFangKuaiMain:StopBubbleTimer()
    if self._BubbleTimer then
        XScheduleManager.UnSchedule(self._BubbleTimer)
        self._BubbleTimer = nil
    end
end

function XUiFangKuaiMain:UpdateChapter()
    local XUiGridFangKuaiChapter = require("XUi/XUiFangKuai/XUiGrid/XUiGridFangKuaiChapter")
    local stages = self._IsNormal and self._Control:GetNormalStages() or self._Control:GetHardStages()
    local playingStage, isPlayingStageNormal, playingStageIndex
    self.PanelChapterList1.gameObject:SetActiveEx(self._IsNormal)
    self.PanelChapterList2.gameObject:SetActiveEx(not self._IsNormal)
    for i, v in ipairs(stages) do
        if not self._StageGrid[self._IsNormal] then
            self._StageGrid[self._IsNormal] = {}
        end
        local grid = self._StageGrid[self._IsNormal][v.Id]
        if not grid then
            local go = self._IsNormal and self["GridChapterNormal" .. i] or self["GridChapterHard" .. i]
            if go then
                grid = XUiGridFangKuaiChapter.New(go, self)
                self._StageGrid[self._IsNormal][v.Id] = grid
            end
        end
        grid:Open()
        grid:Update(v)
        if self._Control:IsStagePlaying(v.Id) then
            playingStage = v.Id
            isPlayingStageNormal = self._IsNormal
            playingStageIndex = i
        end
    end
    local hideGrids = self._StageGrid[not self._IsNormal]
    if hideGrids then
        for _, grid in pairs(hideGrids) do
            grid:Close()
        end
    end
    local isRed = self._Control:CheckChapterRedPoint(self._IsNormal and XEnumConst.FangKuai.Difficulty.Hard or XEnumConst.FangKuai.Difficulty.Normal)
    self.BtnSkip:ShowReddot(isRed)

    if self._CurStageAnimation then
        self:StopAnimation(self._CurStageAnimation)
        self._CurStageAnimation = nil
    end
    if playingStage then
        if isPlayingStageNormal then
            self._CurStageAnimation = string.format("GridChapterNormal%sLoop", playingStageIndex)
        else
            self._CurStageAnimation = string.format("GridChapterHard%sLoop", playingStageIndex)
        end
        self:PlayAnimation(self._CurStageAnimation, nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end
end

function XUiFangKuaiMain:OnClickSkip()
    if not self._IsHardOpen then
        XUiManager.TipError(XUiHelper.GetText("FangKuaiHardStageLock", self._hardTimeStr))
        return
    end
    self._IsNormal = not self.BtnSkip:GetToggleState()
    self:UpdateChapter()
    self:PlayAnimation("QieHuan")
end

function XUiFangKuaiMain:OnClickTask()
    XLuaUiManager.Open("UiFangKuaiTask")
end

function XUiFangKuaiMain:CountDown()
    local time = self._Control:GetActivityRemainder()
    self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER)
end

function XUiFangKuaiMain:StopCountDown()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

return XUiFangKuaiMain