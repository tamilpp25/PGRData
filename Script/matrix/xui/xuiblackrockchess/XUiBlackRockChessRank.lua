---@class XUiBlackRockChessRank : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessRank = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessRank")

local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

function XUiBlackRockChessRank:OnAwake()
    self._RankTimerIds = {}
    self:BindExitBtns()
    XUiHelper.NewPanelActivityAssetSafe(self._Control:GetCurrencyIds(), self.PanelSpecialTool, self)

    local RankGrid = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridRank")
    ---@type XDynamicTableNormal
    self._DynamicTable = XDynamicTableNormal.New(self.RankList)
    self._DynamicTable:SetProxy(RankGrid, self)
    self._DynamicTable:SetDelegate(self)
    ---@type XUiGridRank
    self._MyRank = RankGrid.New(self.GridMyRank, self)
    self.GridRank.gameObject:SetActiveEx(false)
end

function XUiBlackRockChessRank:OnStart()
    self._ChapterIds = {}
    ---@type XTableBlackRockChessChapter[]
    local chapterConfigs = {}
    for _, chapterId in pairs(self._Control:GetChapterIds()) do
        local config = self._Control:GetChapterConfig(chapterId, XEnumConst.BLACK_ROCK_CHESS.DIFFICULTY.NORMAL)
        if config.IsRank then
            table.insert(self._ChapterIds, chapterId)
            table.insert(chapterConfigs, config)
        end
    end

    local btns = {}
    XUiHelper.RefreshCustomizedList(self.BtnRank.parent, self.BtnRank, #chapterConfigs, function(index, go)
        local uiObject = {}
        local chapter = chapterConfigs[index]
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.BtnRank:SetNameByGroup(0, chapter.Name)
        table.insert(btns, uiObject.BtnRank)
    end)
    self.BtnTabGroup:Init(btns, handler(self, self.OnTabSelect))

    self:SetAutoCloseInfo(self._Control:GetActivityStopTime(), function(isClose)
        if isClose then
            self._Control:OnActivityEnd()
            return
        end
    end, nil, 0)
end

function XUiBlackRockChessRank:OnEnable()
    self.BtnTabGroup:SelectIndex(1)
end

function XUiBlackRockChessRank:OnDestroy()
    self._Control:ClearRankData()
    self:RemoveTweenTimer()
end

function XUiBlackRockChessRank:OnTabSelect(i)
    --if XTool.IsNumberValid(self._CurIndex) then
    --    self:PlayAnimationWithMask("QieHuan")
    --end

    self._CurChapterId = self._ChapterIds[i]
    local data = self._Control:GetRankData(self._CurChapterId)
    
    if data then
        self:RemoveTweenTimer()
        self:UpdateView()
    else
        self._Control:RequestBlackRockChessQueryRank(self._CurChapterId, function()
            self:RemoveTweenTimer()
            self:UpdateView()
        end)
    end
end

function XUiBlackRockChessRank:UpdateView()
    local rankData = self._Control:GetRankData(self._CurChapterId)
    local rankPlayerInfos = rankData.RankPlayerInfos

    self._CurRankTotalCount = rankData.TotalCount
    self.PanelNoRank.gameObject:SetActiveEx((not next(rankPlayerInfos)))
    self._DynamicTable:SetDataSource(rankPlayerInfos)
    self._DynamicTable:ReloadDataASync(1)
    self._MyRank:Refresh(self._Control:GetMyRankData(self._CurChapterId))
end

---@param grid XUiGridRank
function XUiBlackRockChessRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rankInfo = self._DynamicTable:GetData(index)
        rankInfo.Rank = index
        grid:Refresh(rankInfo)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        self:PlayGridTween(index, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        self:RemoveGridTween(grid)
    end
end

function XUiBlackRockChessRank:GetRankTotalCount()
    return self._CurRankTotalCount
end

function XUiBlackRockChessRank:PlayGridTween(index, grid)
    self:RemoveGridTween(grid)
    local timerId = XScheduleManager.ScheduleOnce(function()
        grid:PlayAnimationWithMask("PlayerRankEnable")
    end, (index - 1) * 50)
    grid.Transform:GetComponent("CanvasGroup").alpha = 0
    self._RankTimerIds[grid] = timerId
end

function XUiBlackRockChessRank:RemoveGridTween(grid)
    if self._RankTimerIds[grid] then
        XScheduleManager.UnSchedule(self._RankTimerIds[grid])
        self._RankTimerIds[grid] = nil
    end
end

function XUiBlackRockChessRank:RemoveTweenTimer()
    for _, timerId in pairs(self._RankTimerIds) do
        XScheduleManager.UnSchedule(timerId)
    end
    self._RankTimerIds = {}
end

return XUiBlackRockChessRank