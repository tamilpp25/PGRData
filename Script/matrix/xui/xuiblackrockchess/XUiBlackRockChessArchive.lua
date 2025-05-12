local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridArchive = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridArchive")

---@class XUiBlackRockChessArchive : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessArchive = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessArchive")

local SelectIndex = 1

function XUiBlackRockChessArchive:OnAwake()
    self._StoryTimerIds = {}
end

function XUiBlackRockChessArchive:OnStart()
    self:InitCompnent()
end

function XUiBlackRockChessArchive:OnEnable()
    self.TabBtnContent:SelectIndex(SelectIndex)
end

function XUiBlackRockChessArchive:OnDisable()
    self.TabIndex = nil
end

function XUiBlackRockChessArchive:OnDestroy()
    self:RemoveTweenTimer()
end

function XUiBlackRockChessArchive:InitCompnent()
    local tabs = {}
    local infos = self._Control:GetArchiveData()
    self._ArchiveList = {}
    for i, v in ipairs(infos) do
        local button = i == 1 and self.BtnTabShortNew or XUiHelper.Instantiate(self.BtnTabShortNew, self.TabBtnContent.transform)
        button:SetNameByGroup(0, v.Name)
        table.insert(tabs, button)
        self._ArchiveList[i] = v.archives
    end

    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridArchive, self)
    self.DynamicTable:SetDelegate(self)

    self.TopController = XUiHelper.NewPanelTopControl(self, self.TopControl)
    self.TabBtnContent:Init(tabs, function(index)
        self:OnSelectTab(index)
    end)

    local endTime = self._Control:GetActivityStopTime()
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
end

function XUiBlackRockChessArchive:OnSelectTab(index)
    if self.TabIndex == index then
        return
    end
    self:RemoveTweenTimer()
    self:PlayAnimation("QieHuan")
    self.TabIndex = index
    SelectIndex = index
    local data = self._ArchiveList[index]
    self:RefreshCount()
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataSync()
end

---动态列表事件
function XUiBlackRockChessArchive:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        self:PlayGridTween(index, grid)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        grid:UpdateGrid(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        self:RemoveGridTween(grid)
    end
end

function XUiBlackRockChessArchive:PlayGridTween(index, grid)
    self:RemoveGridTween(grid)
    local timerId = XScheduleManager.ScheduleOnce(function()
        grid:PlayAnimationWithMask("GridStoryItemEnable")
    end, (index - 1) * 50)
    grid.Transform:FindTransform("GridStory"):GetComponent("CanvasGroup").alpha = 0
    self._StoryTimerIds[grid] = timerId
end

function XUiBlackRockChessArchive:RemoveGridTween(grid)
    if self._StoryTimerIds[grid] then
        XScheduleManager.UnSchedule(self._StoryTimerIds[grid])
        self._StoryTimerIds[grid] = nil
    end
end

function XUiBlackRockChessArchive:RemoveTweenTimer()
    for _, timerId in pairs(self._StoryTimerIds) do
        XScheduleManager.UnSchedule(timerId)
    end
    self._StoryTimerIds = {}
end

function XUiBlackRockChessArchive:OnCheckActivity(isClose)
    if isClose then
        self._Control:OnActivityEnd()
        return
    end
end

function XUiBlackRockChessArchive:RefreshCount()
    local data = self._ArchiveList[self.TabIndex]
    local max = #data
    local count = 0
    for _, v in pairs(data) do
        if XConditionManager.CheckCondition(v.Condition) then
            count = count + 1
        end
    end
    self.TxtMaxCollectNum.text = max
    self.TxtHaveCollectNum.text = count
end

return XUiBlackRockChessArchive