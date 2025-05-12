local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiFangKuaiChapter : XLuaUi 大方块关卡界面
---@field _Control XFangKuaiControl
local XUiFangKuaiChapter = XLuaUiManager.Register(XLuaUi, "UiFangKuaiChapter")

function XUiFangKuaiChapter:OnAwake()
    ---@type XUiGridFangKuaiStageGroup[]
    self._Grids = {}
    self._Timer = {}
    self:RegisterClickEvent(self.BtnTask, self.OnClickTask)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpId())
end

function XUiFangKuaiChapter:OnStart(chapterId)
    self._Chapter = self._Control:GetChapterConfig(chapterId)
    self:InitCompnent()

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiFangKuaiChapter:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateTask()
    self:UpdateChapter()
end

function XUiFangKuaiChapter:OnDestroy()
    self:StopBubbleTimer()
    self:RemoveAnimTimer()
end

function XUiFangKuaiChapter:InitCompnent()
    self.ImgTitle:SetRawImage(self._Chapter.Icon)
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
end

function XUiFangKuaiChapter:RemoveAnimTimer()
    for _, timeId in pairs(self._Timer) do
        XScheduleManager.UnSchedule(timeId)
    end
end

function XUiFangKuaiChapter:UpdateChapter()
    self:RemoveAnimTimer()
    XUiHelper.RefreshCustomizedList(self.GridChapter.parent, self.GridChapter, #self._Chapter.StageGroupIds, function(index, go)
        local id = self._Chapter.StageGroupIds[index]
        local grid = require("XUi/XUiFangKuai/XUiGrid/XUiGridFangKuaiStageGroup").New(go, self, id, self._Chapter.Id)
        grid:Update()
        grid.Canvas.alpha = 0
        self._Timer[index] = XScheduleManager.ScheduleOnce(function()
            grid:PlayChapterAnim()
        end, 200 * index)
    end)
end

function XUiFangKuaiChapter:UpdateTask()
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

function XUiFangKuaiChapter:StopBubbleTimer()
    if self._BubbleTimer then
        XScheduleManager.UnSchedule(self._BubbleTimer)
        self._BubbleTimer = nil
    end
end

function XUiFangKuaiChapter:OnClickTask()
    XLuaUiManager.Open("UiFangKuaiTask")
end

return XUiFangKuaiChapter