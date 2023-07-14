--虚像地平线战斗准备换人界面：角色列表
local XUiExpeditionRoomCharListPanel = XClass(nil, "XUiExpeditionRoomCharListPanel")
local XUiExpeditionRoomCharListGrid = require("XUi/XUiExpedition/Battle/ChangeMember/XUiExpeditionRoomCharListGrid")
function XUiExpeditionRoomCharListPanel:Ctor(ui, rootUi)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiExpeditionRoomCharListGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiExpeditionRoomCharListPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self.RootUi, index)
        if self.CurrentSelect == index then
            self:SetSelectCharacter(grid)
        end
        local memberData = self.MemberList[index]
        grid:SetInTeam(XDataCenter.ExpeditionManager.GetCharacterIsInTeam(memberData:GetBaseId()))
        grid:RefreshDatas(memberData)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetSelect(false)
        grid:SetInTeam(false)
        if self.CurrentSelect == index then
            self:SetSelectCharacter(grid)
        end
        local memberData = self.MemberList[index]
        grid:SetInTeam(XDataCenter.ExpeditionManager.GetCharacterIsInTeam(memberData:GetBaseId()))
        grid:RefreshDatas(memberData)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurrentSelect = index
        self:SetSelectCharacter(grid)
    end
end

function XUiExpeditionRoomCharListPanel:UpdateData(index)
    self.MemberList = XDataCenter.ExpeditionManager.GetTeam():GetDisplayTeamList()
    self.CurrentSelect = index
    self.DynamicTable:SetDataSource(self.MemberList)
    if #self.MemberList > 0 then
        self.DynamicTable:ReloadDataSync(index)
    end
end
--选中
function XUiExpeditionRoomCharListPanel:SetSelectCharacter(grid)
    if self.CurCharacterGrid then
        self.CurCharacterGrid:SetSelect(false)
    end
    self.CurCharacterGrid = grid
    self.CurCharacterGrid:SetSelect(true)
    self.RootUi.CurrentSelect = self.CurrentSelect
end
return XUiExpeditionRoomCharListPanel