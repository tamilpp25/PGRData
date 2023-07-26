--==============
--超限乱斗 支援角色选人页面
--==============
local XUiSuperSmashBrosRoleSelectionGrid = require("XUi/XUiSuperSmashBros/Pick/AssistanceRoleSelection/XUiSuperSmashBrosRoleSelectionGrid")

---@class UiSuperSmashBrosPick:XLuaUi
local XUiSuperSmashBrosRoleSelection = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosRoleSelection")

function XUiSuperSmashBrosRoleSelection:Ctor()
    self._RoleSelected = false
    self._RoleId = false
    self._Callback = false
end

function XUiSuperSmashBrosRoleSelection:OnStart(roleId, callback)
    self._RoleId = roleId
    self._Callback = callback
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnTcanchaungBlack, self.Close)
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.DTableCharaList)
    self.DynamicTable:SetProxy(XUiSuperSmashBrosRoleSelectionGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridCharacterNew.gameObject:SetActiveEx(false)
    self:InitCharacterInfo()
end

function XUiSuperSmashBrosRoleSelection:OnEnable()
    local dataProvider = XDataCenter.SuperSmashBrosManager.GetAssistantRoleList()
    self.DynamicTable:SetDataSource(dataProvider)
    local index = false
    if self._RoleId and self._RoleId > 0 then
        for i = 1, #dataProvider do
            ---@type XSmashBCharacter
            local role = dataProvider[i]
            if role:GetId() == self._RoleId then
                index = i
            end
        end
    end
    if index then
        self.DynamicTable:ReloadDataASync(index)
        self:SetSelected(index)
    else
        self.DynamicTable:ReloadDataASync(1)
        self:UpdateRole(dataProvider[1])
    end
end

function XUiSuperSmashBrosRoleSelection:OnDisable()
    if self._Callback then
        self._Callback(self._RoleSelected)
    end
end

function XUiSuperSmashBrosRoleSelection:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local role = self.DynamicTable:GetData(index)
        grid:Refresh(role)
        grid:UpdateSelected(self._RoleSelected)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self:SetSelected(index) then
            self:PlayAnimationQieHuan()
        end
        self:UpdateSelected()
    end
end

function XUiSuperSmashBrosRoleSelection:SetSelected(index)
    local role = self.DynamicTable:GetData(index)
    if role == self._RoleSelected then
        self._RoleSelected = false
        return false
    end
    self._RoleSelected = role
    self:UpdateRole(role)
    return true
end

---@param role XSmashBCharacter
function XUiSuperSmashBrosRoleSelection:UpdateRole(role)
    if not role then
        self:Close()
        XLog.Error("[XUiSuperSmashBrosRoleSelection] 没有支援角色")
        return
    end
    self.PanelRen:SetRawImage(role:GetAssistanceCharacterImg())
    self.CharacterInfo:Refresh(role)
end

function XUiSuperSmashBrosRoleSelection:InitCharacterInfo()
    local script = require("XUi/XUiSuperSmashBros/Character/Panels/XUiSSBCharacterInfoPanel")
    self.CharacterInfo = script.New(self.PanelCharaInfo)
end

function XUiSuperSmashBrosRoleSelection:OnNotify(evt, ...)
    if evt == XEventId.EVENT_SSB_CORE_REFRESH then
        self.CharacterInfo:Refresh(self._RoleSelected)
    end
end

function XUiSuperSmashBrosRoleSelection:OnGetEvents()
    return { XEventId.EVENT_SSB_CORE_REFRESH }
end

function XUiSuperSmashBrosRoleSelection:UpdateSelected()
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateSelected(self._RoleSelected)
    end
end

function XUiSuperSmashBrosRoleSelection:PlayAnimationQieHuan()
    self:PlayAnimation("QieHuan")
end

return XUiSuperSmashBrosRoleSelection