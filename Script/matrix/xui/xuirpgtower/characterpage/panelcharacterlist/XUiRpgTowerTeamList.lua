-- 兵法蓝图队伍列表面板
local XUiRpgTowerTeamList = XClass(nil, "XUiRpgTowerTeamList")
local XUiRpgTowerTeamListItem = require("XUi/XUiRpgTower/CharacterPage/PanelCharacterList/XUiRpgTowerTeamListItem")
function XUiRpgTowerTeamList:Ctor(ui, rootUi)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiRpgTowerTeamListItem)
    self.DynamicTable:SetDelegate(self)
end
--动态列表事件
function XUiRpgTowerTeamList:OnDynamicTableEvent(event, index, grid)
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
--刷新列表
--================
function XUiRpgTowerTeamList:UpdateData(index)
    self.TeamList = XDataCenter.RpgTowerManager.GetTeam()
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
    self.CurrentIndex = index or self.CurrentIndex or 1
    self.DynamicTable:SetDataSource(self.TeamList)
    self.DynamicTable:ReloadDataASync(index or 1)
end
--================
--列表项选中事件
--================
function XUiRpgTowerTeamList:SetSelect(grid)
    if self.CurGrid == grid then return end
    if self.CurGrid then
        self.CurGrid:SetSelect(false)
    end
    self.CurGrid = grid
    self.CurrentIndex = grid.GridIndex
    self.RootUi:OnCharaSelect(grid.RChara)
end
--================
--显示面板
--================
function XUiRpgTowerTeamList:ShowPanel(index)
    self.GameObject:SetActiveEx(true)
    self.RootUi:PlayAnimation("SViewCharacterListEnable")
    self:UpdateData(index)
end
--================
--隐藏面板
--================
function XUiRpgTowerTeamList:HidePanel()
    self.GameObject:SetActiveEx(false)
end
return XUiRpgTowerTeamList