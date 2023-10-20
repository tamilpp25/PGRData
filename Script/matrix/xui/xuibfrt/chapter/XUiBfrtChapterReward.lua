---@class XUiBfrtChapterReward : XLuaUi
---@field _Control
local XUiBfrtChapterReward = XLuaUiManager.Register(XLuaUi, "UiBfrtChapterReward")

function XUiBfrtChapterReward:OnAwake()
    self:AddBtnListener()
end

function XUiBfrtChapterReward:OnStart(chapterId)
    self._ChapterId = chapterId
    self:InitRewardDynamicTable()
end

function XUiBfrtChapterReward:OnEnable()
    self:RefreshReward()
    self:AddEventListener()
end

function XUiBfrtChapterReward:OnDisable()
    self:RemoveEventListener()
end

function XUiBfrtChapterReward:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiBfrtChapterReward:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FINISH_TASK or evt == XEventId.EVENT_TASK_SYNC then
        self:RefreshReward()
    end
end

--region Ui - RewardList
function XUiBfrtChapterReward:InitRewardDynamicTable()
    local script = require("XUi/XUiBfrt/Chapter/XUiBfrtGridChapterReward")
    self._RewardDynamicTable = XDynamicTableNormal.New(self.PanelTreasureGradeList)
    self._RewardDynamicTable:SetProxy(script, self)
    self._RewardDynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiBfrtChapterReward:RefreshReward()
    if not XTool.IsNumberValid(self._ChapterId) then
        return
    end
    ---@type XBfrtTaskData[]
    self._ChapterTaskList = XDataCenter.BfrtManager.GetChapterTaskDataList(self._ChapterId, true)
    self._RewardDynamicTable:SetDataSource(self._ChapterTaskList)
    self._RewardDynamicTable:ReloadDataASync(1)
end

---@param grid XUiBfrtGridChapterReward
function XUiBfrtChapterReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._ChapterTaskList[index])
    end
end
--endregion

--region Ui - BtnListener
function XUiBfrtChapterReward:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBg, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end
--endregion

--region Event
function XUiBfrtChapterReward:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_BFRT_CHAPTER_REWARD_RECV, self.RefreshReward, self)
end

function XUiBfrtChapterReward:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_BFRT_CHAPTER_REWARD_RECV, self.RefreshReward, self)
end
--endregion

return XUiBfrtChapterReward