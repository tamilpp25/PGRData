local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiGridBWRoleTeam : XUiNode
---@field Parent XUiPanelBWRoleSheet
local XUiGridBWRoleTeam = XClass(XUiNode, "XUiGridBWRoleTeam")

local FullTeamEntityCount = XMVCA.XBigWorldCharacter:GetFullTeamEntityCount()

function XUiGridBWRoleTeam:OnStart()
    self.BtnCharacter.CallBack = function()
        self:OnClickBtnRole()
    end
end

function XUiGridBWRoleTeam:Refresh(characterId, pos)
    self._Id = characterId
    self._Pos = pos
    local agency = XMVCA.XBigWorldCharacter
    self.RImgHeadIcon:SetRawImage(agency:GetSquareHeadIcon(characterId))
    self.TxtName.text = agency:GetCharacterName(characterId)
    local showPos = pos > 0
    self.PanelOrder.gameObject:SetActiveEx(showPos)
    if showPos then
        self.TxtOrder.text = pos
    end
    self._IsSelect = showPos
    self.PanelInTeam.gameObject:SetActiveEx(showPos)
    if self.UiBigWorldPanelStory then
        local isTrial = XMVCA.XBigWorldCharacter:CheckCharacterTrial(characterId)

        self.UiBigWorldPanelStory.gameObject:SetActiveEx(isTrial)
    end
end

function XUiGridBWRoleTeam:OnClickBtnRole()
    local team = self.Parent:GetDlcTeam()
    if not team then
        return
    end
    self._IsSelect = not self._IsSelect
    local pos = 0
    -- 操作：选中
    if self._IsSelect then
        pos = team:GetFirstEmptyPos()
        --正常编队-还未满员
        if pos > FullTeamEntityCount then
            XMVCA.XBigWorldService:TipText("TeamFullText")
            return
        end
        team:AddLast(self._Id, true)
    else
        -- 操作：取消选中
        pos = team:UpdateTeamByPos(self._Pos, 0)
    end
    self.Parent:SetupDynamicTable()
end

---@class XUiPanelBWRoleSheet : XUiNode 快捷编队
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldRoleRoom
---@field _Control
local XUiPanelBWRoleSheet = XClass(XUiNode, "XUiPanelBWRoleSheet")

function XUiPanelBWRoleSheet:OnStart()
    self:InitCb()
    self:InitView()
end

function XUiPanelBWRoleSheet:InitCb()
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
end

function XUiPanelBWRoleSheet:InitView()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelCharacterList)
    self._DynamicTable:SetProxy(XUiGridBWRoleTeam, self)
    self._DynamicTable:SetDelegate(self)

    self.PlayerInfoCharacterGrid.gameObject:SetActiveEx(false)
end

function XUiPanelBWRoleSheet:RefreshView(teamId)
    self._TeamId = teamId
    self._Team = XMVCA.XBigWorldCharacter:GetDlcTeam(teamId)
    self._DataList = XMVCA.XBigWorldCharacter:SortTeamList(teamId, true)
    self:SetupDynamicTable()
end

function XUiPanelBWRoleSheet:SetupDynamicTable()
    local isEmpty = XTool.IsTableEmpty(self._DataList)
    self.PanelCharacterNone.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        return
    end

    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync()
end

function XUiPanelBWRoleSheet:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local entityId = self._DataList[index]
        local pos = self._Team:GetEntityPos(entityId)
        grid:Refresh(entityId, pos)
    end
end

---@return XBWTeam
function XUiPanelBWRoleSheet:GetDlcTeam()
    if not self._Team then
        self._Team = XMVCA.XBigWorldCharacter:GetDlcTeam(self._TeamId)
    end
    return self._Team
end

function XUiPanelBWRoleSheet:OnBtnConfirmClick()
    XMVCA.XBigWorldCharacter:RequestUpdateTeam(self._TeamId, function()
        self:SetupDynamicTable()
        self.Parent:UpdateView()
        self.Parent:OnBtnDetailClicked()
    end)
end

return XUiPanelBWRoleSheet