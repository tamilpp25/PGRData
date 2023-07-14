local XUiGridCharacterNew = require("XUi/XUiSpecialTrainBreakthrough/XUiSpecialTrainBreakthroughExchangeGrid")

---@class XUiSpecialTrainBreakthroughExchange:XLuaUi
local XUiSpecialTrainBreakthroughExchange = XLuaUiManager.Register(XLuaUi, "UiSpecialTrainBreakthroughExchange")

function XUiSpecialTrainBreakthroughExchange:Ctor()
    self._RobotIdList = false
    self._SelectedIndex = false
    self.DynamicTable = false
end

function XUiSpecialTrainBreakthroughExchange:OnAwake()
    self._RobotIdList = XDataCenter.FubenSpecialTrainManager.BreakthroughGetRobotList()
    self:AutoAddListener()
    self.GridCharacterNew.gameObject:SetActiveEx(false)
    local robotId = XDataCenter.FubenSpecialTrainManager.BreakthroughGetRobotId()
    self._SelectedIndex = self:FindIndex(robotId) or 1
end

function XUiSpecialTrainBreakthroughExchange:OnStart()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelScrollView)
    self.DynamicTable:SetProxy(XUiGridCharacterNew)
    self.DynamicTable:SetDelegate(self)
end

function XUiSpecialTrainBreakthroughExchange:OnEnable()
    self:SetupDynamicTable()
end

function XUiSpecialTrainBreakthroughExchange:SetupDynamicTable()
    self.DynamicTable:SetDataSource(self._RobotIdList)
    self.DynamicTable:ReloadDataASync(self._SelectedIndex)
end

---@param grid XUiSpecialTrainBreakthroughExchangeGrid
function XUiSpecialTrainBreakthroughExchange:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        self:UpdateGrid(index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if index == self._SelectedIndex then
            return
        end
        self:SetSelected(index)
    end
end

function XUiSpecialTrainBreakthroughExchange:SetSelected(index)
    local lastSelectedIndex = self._SelectedIndex
    self._SelectedIndex = index
    self:UpdateGrid(index)
    self:UpdateGrid(lastSelectedIndex)
    XDataCenter.FubenSpecialTrainManager.RequestBreakthroughSetRobotId(self._RobotIdList[index])
end

function XUiSpecialTrainBreakthroughExchange:UpdateGrid(index)
    local grid = self.DynamicTable:GetGridByIndex(index)
    local robotId = self._RobotIdList[index]
    if robotId then
        grid:UpdateGrid(robotId)
        local isSelected = self._SelectedIndex == index
        grid:SetSelected(isSelected)
        grid:SetCurrentSign(isSelected)
    end
end

function XUiSpecialTrainBreakthroughExchange:AutoAddListener()
    self:RegisterClickEvent(self.BtnCancel, self.Close)
end

function XUiSpecialTrainBreakthroughExchange:Close(...)
    XUiSpecialTrainBreakthroughExchange.Super.Close(self, ...)
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SPECIAL_TRAIN_BREAKTHROUGH_ON_EXCHANGE_CLOSE)
end

function XUiSpecialTrainBreakthroughExchange:FindIndex(robotId)
    for i = 1, #self._RobotIdList do
        if self._RobotIdList[i] == robotId then
            return i
        end
    end
    return false
end

return XUiSpecialTrainBreakthroughExchange
