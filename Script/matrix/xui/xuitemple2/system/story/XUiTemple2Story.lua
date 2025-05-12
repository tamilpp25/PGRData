local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTemple2StoryGrid = require("XUi/XUiTemple2/System/Story/XUiTemple2StoryGrid")

---@class XUiTemple2Story : XLuaUi
---@field _Control XTemple2Control
local XUiTemple2Story = XLuaUiManager.Register(XLuaUi, "UiTemple2Story")

function XUiTemple2Story:Ctor()
    ---@type XUiTemple2StoryGrid
    self._Grids = {}
end

function XUiTemple2Story:OnAwake()
    self:BindExitBtns()
    self.DynamicTable = XDynamicTableNormal.New(self.ListStory)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiTemple2StoryGrid, self)
end

function XUiTemple2Story:OnStart()

end

function XUiTemple2Story:OnEnable()
    self:Update()
end

function XUiTemple2Story:OnDisable()
end

function XUiTemple2Story:Update()
    local storyData = self._Control:GetSystemControl():GetDataStory()
    --XTool.UpdateDynamicItem(self._Grids, storyData, self.GridStory, XUiTemple2StoryGrid, self)
    self.DynamicTable:SetDataSource(storyData)
    self.DynamicTable:ReloadDataSync(1)

    self.TxtNum.text = storyData.Progress
end

---@param grid XUiTemple2StoryGrid
function XUiTemple2Story:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        self:PlayGridAnimation(grid, index)
    end
end

-- 播放动画
function XUiTemple2Story:PlayGridAnimation(grid, index)
    ---@type UnityEngine.CanvasGroup
    local canvasGroup = XUiHelper.TryGetComponent(grid.Transform, "", "CanvasGroup")
    if canvasGroup then
        canvasGroup.alpha = 0
    end
    local timerId
    timerId = XScheduleManager.ScheduleOnce(function()
        grid:PlayAnimation("GridStoryEnable")
        self:_RemoveTimerIdAndDoCallback(timerId)
    end, 200 + 80 * index)
    self:_AddTimerId(timerId)
end

return XUiTemple2Story