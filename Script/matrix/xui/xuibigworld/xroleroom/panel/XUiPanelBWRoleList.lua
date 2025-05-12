local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiGridBWRoleVTeam : XUiNode
---@field Parent XUiBigWorldRoleRoom
---@field
local XUiGridBWRoleVTeam = XClass(XUiNode, "XUiGridBWRoleVTeam")

function XUiGridBWRoleVTeam:OnStart(root)
    self._Root = root
end

function XUiGridBWRoleVTeam:Refresh(id, selectId, pos)
    self._Id = id

    self:SetSelect(id == selectId)

    local agency = XMVCA.XBigWorldCharacter
    self.RImgHeadIcon:SetRawImage(agency:GetSquareHeadIcon(id))
    local isInTeam = pos > 0
    self.PanelOrder.gameObject:SetActiveEx(isInTeam)
    self.PanelInTeam.gameObject:SetActiveEx(isInTeam)
    if isInTeam then
        self.TxtOrder.text = string.format("%02d", pos)
    end
    self.UiBigWorldPanelStory.gameObject:SetActiveEx(agency:CheckCharacterTrial(id))
end

function XUiGridBWRoleVTeam:GetId()
    return self._Id
end

function XUiGridBWRoleVTeam:SetSelect(select)
    self.PanelSelected.gameObject:SetActiveEx(select)
    self.PanelKuang.gameObject:SetActiveEx(not select)
end


---@class XUiPanelBWRoleList : XUiNode 角色竖向列表
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldRoleRoom
---@field _Control
local XUiPanelBWRoleList = XClass(XUiNode, "XUiPanelBWRoleList")

function XUiPanelBWRoleList:OnStart(isContainCommandant)
    self._IsContainCommandant = isContainCommandant
    self._IsDisabled = false
    self:InitCb()
    self:InitView()
end

function XUiPanelBWRoleList:OnEnable()
    self:SetupDynamicTable()
end

function XUiPanelBWRoleList:OnDestroy()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_ROLE_TEAM_STATUS_REFRESH, self.SetupDynamicTable, self)
end

function XUiPanelBWRoleList:Close()
    self._DataList = false
    XUiNode.Close(self)
end

function XUiPanelBWRoleList:InitCb()
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_ROLE_TEAM_STATUS_REFRESH, self.SetupDynamicTable, self)
end

function XUiPanelBWRoleList:InitView()
    local url = XMVCA.XBigWorldResource:GetAssetUrl("PanelVListGrid")
    local panelList = self.PanelList.transform:LoadPrefab(url)
    local grid = panelList.transform:Find("Viewport/PanelRoleGouzaoContent/GridCharacterV2P6")
    if grid then
        grid.gameObject:SetActiveEx(false)
    end
    self._DynamicTable = XDynamicTableNormal.New(panelList)
    self._DynamicTable:SetProxy(XUiGridBWRoleVTeam, self.Parent, self)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTableComplete = false
end

function XUiPanelBWRoleList:RefreshView(teamId, entityId, pos)
    self:Open()
    self._TeamId = teamId
    self._Pos = pos
    local dataList = XMVCA.XBigWorldCharacter:SortTeamList(teamId, self._IsContainCommandant)
    local isEmpty = XTool.IsTableEmpty(dataList)
    self.PanelEmptyList.gameObject:SetActiveEx(isEmpty)
    local team = XMVCA.XBigWorldCharacter:GetDlcTeam(self._TeamId)
    self._Team = team

    if isEmpty then
        return
    end
    local first = math.min(team:GetCount() + 1, #dataList)
    self._SelectEntityId = (entityId and entityId > 0) and entityId or dataList[first]
    self._DataList = dataList
    self:SetupDynamicTable()
end

function XUiPanelBWRoleList:SetupDynamicTable()
    if XTool.IsTableEmpty(self._DataList) then
        return
    end
    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync()
end

function XUiPanelBWRoleList:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local entityId = self._DataList[index]
        local pos = self._Team:GetEntityPos(entityId)
        grid:Refresh(entityId, self._SelectEntityId, pos)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local pos = 1
        for i, entityId in pairs(self._DataList) do
            if entityId == self._SelectEntityId then
                pos = i
                break
            end
        end
        local grid = self._DynamicTable:GetGridByIndex(pos)
        self._Last = grid
        self:DoLoadModel(self._SelectEntityId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnSelect(index, grid)
    end
end

function XUiPanelBWRoleList:OnSelect(index, grid)
    local targetId = self._DataList[index]
    if self._SelectEntityId == targetId then
        return
    end
    if self._Last then
        self._Last:SetSelect(false)
    end
    self._SelectEntityId = targetId
    grid:SetSelect(true)
    self._Last = grid
    self:DoLoadModel(targetId)
end

function XUiPanelBWRoleList:DoLoadModel(entityId)
    self.Parent:OnSelectSingle(self._Pos, entityId)
end

return XUiPanelBWRoleList