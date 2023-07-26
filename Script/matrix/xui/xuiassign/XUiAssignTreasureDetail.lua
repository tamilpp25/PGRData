local XUiAssignTreasureDetail = XLuaUiManager.Register(XLuaUi, "UiAssignTreasureDetail")

local XUiGridAssignTreasure = require("XUi/XUiAssign/XUiGridAssignTreasure")

function XUiAssignTreasureDetail:OnStart(mainUi)
    self.RootUi = mainUi -- 边界公约主界面
    self:InitButton()
    self:InitDynamicTable()
end

function XUiAssignTreasureDetail:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTreasureGradeList)
    self.DynamicTable:SetProxy(XUiGridAssignTreasure, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiAssignTreasureDetail:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

function XUiAssignTreasureDetail:OnEnable()

    self:Refresh()
end

function XUiAssignTreasureDetail:OnDisable()

end

function XUiAssignTreasureDetail:Refresh()
    local list = XDataCenter.FubenAssignManager.GetChapterIdList()
    self.CurShowList = list
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataASync(1)
end

-- 只刷新格子状态
function XUiAssignTreasureDetail:RefreshGirdState()
    for index, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:Refresh(self.CurShowList[index])
    end
end

function XUiAssignTreasureDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.CurShowList[index])
    end
end

return XUiAssignTreasureDetail