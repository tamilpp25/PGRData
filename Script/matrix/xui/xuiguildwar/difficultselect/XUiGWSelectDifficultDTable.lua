--选择难度动态列表
local XUiGWSelectDifficultDTable = XClass(nil, "XUiGWSelectDifficultDTable")

function XUiGWSelectDifficultDTable:Ctor(panel)
    XTool.InitUiObjectByUi(self, panel)
    if self.GridDifficultyLevel then
        self.GridDifficultyLevel.gameObject:SetActiveEx(false)
    end
    self:InitDynamicTable()
    self:RefreshList()
end

function XUiGWSelectDifficultDTable:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    local gridProxy = require("XUi/XUiGuildWar/DifficultSelect/XUiGWSelectDifficultGrid")
    self.DynamicTable:SetProxy(gridProxy)
    self.DynamicTable:SetDelegate(self)
end
--================
--动态列表事件
--================
function XUiGWSelectDifficultDTable:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataList and self.DataList[index] then
            grid:Refresh(self.DataList[index])
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
    end
end

function XUiGWSelectDifficultDTable:RefreshList()
    self.DataList = XDataCenter.GuildWarManager.GetDifficultyDataList()
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync(1)
end

return XUiGWSelectDifficultDTable