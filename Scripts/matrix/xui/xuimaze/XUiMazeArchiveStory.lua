local XUiMazeArchiveStoryGrid = require("XUi/XUiMaze/XUiMazeArchiveStoryGrid")
local XViewModelMazeStory = require("XEntity/XMaze/XViewModelMazeStory")

---@class XUiMazeArchiveStory:XLuaUi
local XUiMazeArchiveStory = XLuaUiManager.Register(XLuaUi, "UiMazeArchiveStory")

function XUiMazeArchiveStory:Ctor()
    ---@type XViewModelMazeStory
    self._ViewModel = XViewModelMazeStory.New()
end

function XUiMazeArchiveStory:OnAwake()
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

function XUiMazeArchiveStory:OnStart()
    self:BindExitBtns()
    self:BindHelpBtn(self.HelpBtn, XMazeConfig.GetHelpKey())
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XMazeConfig.GetTicketItemId())
    self.DynamicTable = XDynamicTableNormal.New(self.PanelArchiveStoryList)
    self.DynamicTable:SetProxy(XUiMazeArchiveStoryGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridStoryItem.gameObject:SetActiveEx(false)
end

function XUiMazeArchiveStory:OnEnable()
    self:Update()
end

function XUiMazeArchiveStory:Update()
    local dataSource = self._ViewModel:GetDataSource()
    self.DynamicTable:SetDataSource(dataSource)
    self.DynamicTable:ReloadDataASync(1)
    
    local progress, maxProgress = self._ViewModel:GetProgress(dataSource)
    self.TxtHaveCollectNum.text = progress
    self.TxtMaxCollectNum.text = maxProgress
end

---@param grid XUiMazeArchiveStoryGrid
function XUiMazeArchiveStory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable.DataSource[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end

return XUiMazeArchiveStory