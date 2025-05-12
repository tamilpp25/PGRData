local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
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
        grid:Init(grid.DynamicGrid.gameObject, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local memberData = self.MemberList[index]
        grid:RefreshDatas(memberData)
        if self.CurrentBaseId == memberData:GetBaseId() then
            self.CurCharacterGrid = grid
        end
        grid:SetSelect(self.CurrentBaseId == memberData:GetBaseId())
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:SetSelectCharacter(grid)
    end
end

function XUiExpeditionRoomCharListPanel:UpdateData(baseId)
    self.MemberList = XDataCenter.ExpeditionManager.GetTeam():GetDisplayTeamList()
    if XTool.IsTableEmpty(self.MemberList) then
        return
    end
    
    local index = 1
    self.CurrentBaseId = baseId
    if baseId > 0 then
        index = XDataCenter.ExpeditionManager.GetCharaDisplayIndex(baseId)
        if index < 0 then
            self.CurrentBaseId = self.MemberList[1]:GetBaseId()
            index = 1
        end
    else
        self.CurrentBaseId = self.MemberList[1]:GetBaseId()
    end
    self:UpdateModel()
    self.DynamicTable:SetDataSource(self.MemberList)
    self.DynamicTable:ReloadDataSync(index)
end
--选中
function XUiExpeditionRoomCharListPanel:SetSelectCharacter(grid)
    if self.CurrentBaseId == grid.BaseId then
        return
    end
    
    if self.CurCharacterGrid then
        self.CurCharacterGrid:SetSelect(false)
    end

    grid:SetSelect(true)
    
    self.CurCharacterGrid = grid
    self.CurrentBaseId = grid.BaseId
    self:UpdateModel()
end

function XUiExpeditionRoomCharListPanel:UpdateModel()
    local eChara = XDataCenter.ExpeditionManager.GetCharaByEBaseId(self.CurrentBaseId)
    if eChara then
        self.RootUi:Refresh(eChara:GetCharacterId(), self.CurrentBaseId, eChara:GetRobotId())
    end
end

return XUiExpeditionRoomCharListPanel