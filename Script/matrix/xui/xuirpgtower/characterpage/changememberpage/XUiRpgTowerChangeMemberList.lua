local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--兵法蓝图养成界面更换成员页面成员动态列表控件
local XUiRpgTowerChangeMemberList = XClass(nil, "XUiRpgTowerChangeMemberList")
local XUiRpgTowerChangeMemberItem = require("XUi/XUiRpgTower/CharacterPage/ChangeMemberPage/XUiRpgTowerChangeMemberItem")

function XUiRpgTowerChangeMemberList:Ctor(ui, page, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.Page = page
    self.RootUi = rootUi
    self.Page.GridCharacterNew.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiRpgTowerChangeMemberItem)
    self.DynamicTable:SetDelegate(self)
end
--动态列表事件
function XUiRpgTowerChangeMemberList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.TeamList and self.TeamList[index] then
            grid:RefreshData(self.TeamList[index], index)
            if self.CurrentIndex == index then
                grid:SetSelect(true)
            end
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
    end
end
--================
--刷新列表数据
--================
function XUiRpgTowerChangeMemberList:UpdateData()
    self.TeamList = XDataCenter.RpgTowerManager.GetTeam()
    local rChara = self.RootUi.RCharacter
    if rChara then
        for index, member in pairs(self.TeamList) do
            if member == rChara then
                self.CurrentIndex = index
                break
            end
        end 
    end
    self.CurrentIndex = self.CurrentIndex or 1
    self.DynamicTable:SetDataSource(self.TeamList)
    self.DynamicTable:ReloadDataASync(1)
end
--================
--列表项选中事件
--================
function XUiRpgTowerChangeMemberList:SetSelect(grid)
    if self.CurGrid == grid then return end
    if self.CurGrid then
        self.CurGrid:SetSelect(false)
    end
    self.CurGrid = grid
    self.CurrentIndex = grid.GridIndex
end
--================
--显示面板
--================
function XUiRpgTowerChangeMemberList:ShowPanel()
    self.GameObject:SetActiveEx(true)
end
--================
--隐藏面板
--================
function XUiRpgTowerChangeMemberList:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiRpgTowerChangeMemberList