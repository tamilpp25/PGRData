local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiMazeTask:XLuaUi
local XUiMazeTask = XLuaUiManager.Register(XLuaUi, "UiMazeTask")

function XUiMazeTask:OnAwake()
    local uiNearRootObj = self.UiModel.UiNearRoot
    local cameraNearChoose = XUiHelper.TryGetComponent(uiNearRootObj, "UiMazeRoleRoomChoose", "Transform")
    local cameraNearRoom = XUiHelper.TryGetComponent(uiNearRootObj, "UiMazeRoleRoom", "Transform")
    cameraNearChoose.gameObject:SetActiveEx(false)
    cameraNearRoom.gameObject:SetActiveEx(false)

    local uiFarRootObj = self.UiModel.UiFarRoot
    local cameraFarChoose = XUiHelper.TryGetComponent(uiFarRootObj, "UiMazeRoleRoomChoose", "Transform")
    local cameraFarRoom = XUiHelper.TryGetComponent(uiFarRootObj, "UiMazeRoleRoom", "Transform")
    local cameraFarStory = XUiHelper.TryGetComponent(uiFarRootObj, "UiMazeArchiveStory", "Transform")
    cameraFarChoose.gameObject:SetActiveEx(false)
    cameraFarRoom.gameObject:SetActiveEx(false)
    cameraFarStory.gameObject:SetActiveEx(true)
end

function XUiMazeTask:OnStart()
    self:BindExitBtns()
    self:BindHelpBtn(self.BtnHelp, XMazeConfig.GetHelpKey())
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XMazeConfig.GetTicketItemId())

    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XDynamicGridTask, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiMazeTask:OnEnable()
    self:Update()
end

function XUiMazeTask:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC
    }
end

function XUiMazeTask:OnNotify(event, ...)
    if event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self:Update()
    end
end

function XUiMazeTask:Update()
    local taskList = XDataCenter.MazeManager.GetTaskList()
    self.DynamicTable:SetDataSource(taskList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiMazeTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DynamicTable.DataSource[index])
    end
end

return XUiMazeTask