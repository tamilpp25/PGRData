---@class XUiBlackRockChessChapter : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessChapter = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessChapter")

local StyleCount = 4

function XUiBlackRockChessChapter:OnAwake()
    self._ChapterTimerIds = {}
    self:BindHelpBtn(self.BtnHelp, "UiBlackRockChessChapter")
    self:BindExitBtns()
    self:InitLocate()
end

function XUiBlackRockChessChapter:OnStart()
    ---@type XUiGridChapterStage[]
    self._Grids = {}

    self:SetAutoCloseInfo(self._Control:GetActivityStopTime(), function(isClose)
        if isClose then
            self._Control:OnActivityEnd()
            return
        end
    end, nil, 0)

    self:InitChapterData()
    self:InitChapter()

    XUiHelper.NewPanelActivityAssetSafe(self._Control:GetCurrencyIds(), self.PanelSpecialTool, self)
end

function XUiBlackRockChessChapter:OnEnable()
    
end

function XUiBlackRockChessChapter:OnDestroy()
    self:RemoveTweenTimer()
end

function XUiBlackRockChessChapter:InitChapterData()
    -- value[1]=普通关stageId value[2]=困难关stageId value[3]=chapterId
    self._Datas = {}
    local map = self._Control:GetChapterDifficultyMap()
    for _, v in pairs(map) do
        local normal = v[XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL]
        local hard = v[XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.HARD]
        for i, stageId in ipairs(normal.StageIds) do
            local data = {}
            table.insert(data, stageId)
            if hard and XTool.IsNumberValid(hard.StageIds[i]) then
                table.insert(data, hard.StageIds[i])
            else
                table.insert(data, 0)
            end
            table.insert(data, normal.ChapterId)
            table.insert(self._Datas, data)
        end
    end
    table.sort(self._Datas, function(a, b)
        return a[1] < b[1]
    end)
end

function XUiBlackRockChessChapter:InitChapter()
    for i, data in ipairs(self._Datas) do
        local idx = i % StyleCount == 0 and StyleCount or i % StyleCount
        local node = self["Node" .. idx]
        node = XUiHelper.Instantiate(node, node.parent)
        local parent = node:Find("Content")
        local go = i == 1 and self.GridChapter or XUiHelper.Instantiate(self.GridChapter, self.GridChapter.parent)
        ---@type XUiGridChapterStage
        local grid = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridChapterStage").New(go, self, data[1], data[2], data[3])
        grid.Transform:SetParent(parent, false)
        grid:Open()
        table.insert(self._Grids, grid)
        self:PlayGridTween(i, grid)
    end
    for i = 1, StyleCount do
        local node = self["Node" .. i]
        node.gameObject:SetActiveEx(false)
    end
end

function XUiBlackRockChessChapter:UpdateChaptersView()
    for _, grid in pairs(self._Grids) do
        grid:UpdateView()
    end
end


function XUiBlackRockChessChapter:PlayGridTween(index, grid)
    self:RemoveGridTween(grid)
    local timerId = XScheduleManager.ScheduleOnce(function()
        grid:PlayAnimationWithMask("GridChapterEnable")
    end, (index - 1) * 50)
    self._ChapterTimerIds[grid] = timerId
end

function XUiBlackRockChessChapter:RemoveGridTween(grid)
    if self._ChapterTimerIds[grid] then
        XScheduleManager.UnSchedule(self._ChapterTimerIds[grid])
        self._ChapterTimerIds[grid] = nil
    end
end

function XUiBlackRockChessChapter:RemoveTweenTimer()
    for _, timerId in pairs(self._ChapterTimerIds) do
        XScheduleManager.UnSchedule(timerId)
    end
    self._ChapterTimerIds = {}
end

function XUiBlackRockChessChapter:InitLocate()
    self.ScrollRect = self.ScrollRect or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelChapter", "ScrollRect")
    self.Content = self.Content or XUiHelper.TryGetComponent(self.ScrollRect.transform, "Viewport/Content")
    self.LocateOffsetX = self.ScrollRect.viewport.rect.width * 0.5
end

-- 定位到入口
function XUiBlackRockChessChapter:LocateToStage(stageGo)
    local nodeGo = stageGo.transform.parent.parent
    local beginX = self.Content.anchoredPosition.x
    local endX = -nodeGo.transform.anchoredPosition.x + self.LocateOffsetX
    if endX > 0 then endX = 0 end -- 最左边边关卡不用滑动到最中间

    local TWEEN_TIME = 0.3
    XLuaUiManager.SetMask(true)
    XUiHelper.Tween(TWEEN_TIME, function(time)
        local curX = beginX + time * (endX - beginX)
        self.Content.anchoredPosition = CS.UnityEngine.Vector2(curX, self.Content.anchoredPosition.y)
    end, function()
        self.Content.anchoredPosition = CS.UnityEngine.Vector2(endX, self.Content.anchoredPosition.y)
        XLuaUiManager.SetMask(false)
    end, function(f)
        return XUiHelper.Evaluate(XUiHelper.EaseType.Sin, f)
    end)
end

return XUiBlackRockChessChapter