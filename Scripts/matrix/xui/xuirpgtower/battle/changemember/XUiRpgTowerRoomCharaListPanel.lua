-- 兵法蓝图出战换人界面角色列表面板
local XUiRpgTowerRoomCharaListPanel = XClass(nil, "XUiRpgTowerRoomCharaListPanel")
local CharaItem = require("XUi/XUiRpgTower/Battle/ChangeMember/XUiRpgTowerRoomCharaListItem")
function XUiRpgTowerRoomCharaListPanel:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(CharaItem)
    self.DynamicTable:SetDelegate(self)
end
--动态列表事件
function XUiRpgTowerRoomCharaListPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.TeamList and self.TeamList[index] then
            grid:RefreshData(self.TeamList[index], index)
            if self.CurrentIndex == index then
                grid:SetSelect(true)
            else
                grid:SetSelect(false)
            end
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
    end
end
--================
--刷新列表
--================
local SortFun = function (list)
    local inTeamList = {}
    local notInTeamList = {}
    for i, rChar in ipairs(list) do
        if rChar:GetIsInTeam() then
            table.insert(inTeamList, rChar)
        else
            table.insert(notInTeamList, rChar)
        end
    end

    return appendArray(inTeamList, notInTeamList)
end

function XUiRpgTowerRoomCharaListPanel:UpdateData()
    local list = XDataCenter.RpgTowerManager.GetTeam()
    self.TeamList = SortFun(list)
    -- 获取当前选中角色在列表中的序号，若没有选中角色则默认列表第一个角色
    local rChara = self.RootUi.RCharacter
    if rChara then
        for index, member in pairs(self.TeamList) do
            if member == rChara then
                self.CurrentIndex = index
                break
            end
        end
    end
    -- 排序
    self.CurrentIndex = self.CurrentIndex or 1
    self.DynamicTable:SetDataSource(self.TeamList)
    self.DynamicTable:ReloadDataASync(self.CurrentIndex)
end
--================
--列表项选中事件
--================
function XUiRpgTowerRoomCharaListPanel:SetSelect(grid)
    if self.CurGrid and self.CurGrid ~= grid then
        self.CurGrid:SetSelect(false)
    end
    self.CurGrid = grid
    self.CurrentIndex = grid.GridIndex
    self.RootUi:OnCharaSelect(grid.RChara)
end
return XUiRpgTowerRoomCharaListPanel