local XUiTheatre3RoleRoomCharacterListGrid = require("XUi/XUiTheatre3/RoleRoom/XUiTheatre3RoleRoomCharacterListGrid")
local XUiTheatre3EquipmentSuit = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentSuit")
local XPanelTheatre3Energy = require("XUi/XUiTheatre3/Adventure/Main/XPanelTheatre3Energy")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local tableInsert = table.insert

---@class XUiTheatre3RoleRoomDetail : XLuaUi
---@field _Control XTheatre3Control 编队成员详细信息
local XUiTheatre3RoleRoomDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre3RoleRoomDetail")

function XUiTheatre3RoleRoomDetail:OnAwake()
    ---@type XCharacterAgency
    self.CharacterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    ---@type XCommonCharacterFiltAgency
    self.FiltAgecy = XMVCA:GetAgency(ModuleId.XCommonCharacterFilt)

    self.BtnCharacterDetails.CallBack = handler(self, self.OnShowDetail)
    self.BtnJoinTeam.CallBack = handler(self, self.OnJoinOrExitTeam)
end

function XUiTheatre3RoleRoomDetail:OnStart(slotId)
    self._SlotId = slotId
    self:InitComponent()
    self:InitSceneRoot()
    self:InitSuitList(slotId)
    self:UpdateEnergy()
end

function XUiTheatre3RoleRoomDetail:OnDestroy()

end

function XUiTheatre3RoleRoomDetail:OnGetEvents()
    return { XEventId.EVENT_CHARACTER_SYN, XEventId.EVENT_CHARACTER_FIRST_GET }
end

function XUiTheatre3RoleRoomDetail:OnNotify(evt)
    self:RefreshFilter()
end

function XUiTheatre3RoleRoomDetail:InitComponent()
    local checkInTeam = function(id)
        return self._Control:GetEntityIdIsInTeam(id)
    end

    local sortOverride = self._Control:GetFilterSortOverrideFunTable(self._SlotId)
    self:BindExitBtns()
    self.PanelFilter = self.FiltAgecy:InitFilter(self.PanelCharacterFilter, self)
    self.PanelFilter:InitData(handler(self, self.OnSelectTab), nil, nil, nil, XUiTheatre3RoleRoomCharacterListGrid, checkInTeam, sortOverride)
    self.PanelFilter:ImportList(self:GetCharacterList())
    self.PanelFilter:ImportDiyLists(self:GetCharacterList(true))

    ---@type XPanelTheatre3Energy
    self._PanelEnergy = XPanelTheatre3Energy.New(self.Energy, self)
    local slotInfo = self._Control:GetSlotInfo(self._SlotId)
    if slotInfo then
        local defaultCharacterId = slotInfo:GetRoleId()
        if XTool.IsNumberValid(defaultCharacterId) then
            self.PanelFilter:DoSelectCharacter(defaultCharacterId)
        end
    end

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.SViewSetList.gameObject)
    self.DynamicTable:SetProxy(XUiTheatre3EquipmentSuit, self, function(grid)
        self:OnClickSuitGrid(grid)
    end)
    self.DynamicTable:SetDelegate(self)
    self.TxtTitle.text = XUiHelper.GetText("Theatre3RoleRoomTitle")
end

function XUiTheatre3RoleRoomDetail:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    ---@type XUiPanelRoleModel
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiTheatre3RoleRoomDetail:InitSuitList(slotId)
    local suitIds = self._Control:GetSlotSuits(slotId)
    if #suitIds == 0 then
        self.TxtEmpty.gameObject:SetActiveEx(true)
        self.SViewSetList.gameObject:SetActiveEx(false)
    else
        self.TxtEmpty.gameObject:SetActiveEx(false)
        self.SViewSetList.gameObject:SetActiveEx(true)

        self.DynamicTable:SetDataSource(suitIds)
        self.DynamicTable:ReloadDataSync()
    end

    local charId = self._Control:GetSlotCharacter(slotId)
    if XTool.IsNumberValid(charId) then
        self._CurCharCost = self._Control:GetCharacterCost(charId)
    else
        self._CurCharCost = 0
    end
end

---@param grid XUiTheatre3EquipmentSuit
function XUiTheatre3RoleRoomDetail:OnDynamicTableEvent(event, index, grid)
    if not grid then
        return
    end
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local suitId = self.DynamicTable:GetData(index)
        grid:SetSuitId(suitId, self._SlotId, true, false)
        grid:ShowHideBtnOpen(false)
    end
end

---@param grid XUiTheatre3EquipmentSuit
function XUiTheatre3RoleRoomDetail:OnClickSuitGrid(grid)
    self._Control:OpenShowEquipPanel(grid.SlotId)
end

function XUiTheatre3RoleRoomDetail:UpdateEnergy()
    self._PanelEnergy:Refresh()
end

function XUiTheatre3RoleRoomDetail:RefreshFilter()
    -- 刷新时要重新获取源数据，因为角色data可能从碎片变成xCharacter。要重新获取
    local list = self:GetCharacterList()
    self.PanelFilter:ImportList(list)
end

function XUiTheatre3RoleRoomDetail:GetCharacterList(isOnlyRobot)
    local characterList = {}
    local datas = self._Control:GetCharacterList(isOnlyRobot)
    for _, v in pairs(datas) do
        if XRobotManager.CheckIsRobotId(v) then
            local robot = XRobotManager.GetRobotById(v)
            tableInsert(characterList, robot)
        else
            local character = self.CharacterAgency:GetCharacter(v)
            if character then
                tableInsert(characterList, character)
            end
        end
    end
    return characterList
end

function XUiTheatre3RoleRoomDetail:OnSelectTab(character, index, grid)
    self:UpdateRoleInfo(character.Id)
end

function XUiTheatre3RoleRoomDetail:UpdateRoleInfo(id)
    self._CurSelect = id
    self:UpdateRoleModel(id)
    self.BtnJoinTeam:SetNameByGroup(0, XUiHelper.GetText(self._Control:GetEntityIdIsInTeam(id) and "Theatre3RoleExit" or "Theatre3RoleJoin"))
end

function XUiTheatre3RoleRoomDetail:UpdateRoleModel(id)
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.RoleModelPanel:UpdateCharacterModel(id, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiCharacter, function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(characterAgency:GetCharacterType(id) == XCharacterConfigs.CharacterType.Normal)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(characterAgency:GetCharacterType(id) == XCharacterConfigs.CharacterType.Isomer)
    end)
    
end

function XUiTheatre3RoleRoomDetail:OnShowDetail()
    XLuaUiManager.Open("UiCharacterSystemV2P6", self._CurSelect)
end

function XUiTheatre3RoleRoomDetail:OnJoinOrExitTeam()
    local isInTeam = self._Control:GetEntityIdIsInTeam(self._CurSelect)

    if not isInTeam then
        local needCost = self._Control:GetCharacterCost(self._CurSelect)
        local curEnergy, totalEnergy = self._Control:GetCurEnergy()
        if needCost + curEnergy - self._CurCharCost > totalEnergy then
            XUiManager.TipMsg(XUiHelper.GetText("Theatre3EnergyNoEnoughTip"))
            return
        end
        if self._Control:IsCharacterRepeat(self._CurSelect) then
            XUiManager.TipMsg(XUiHelper.GetText("StrongholdElectricDeploySameCharacter"))
            return
        end
    end

    local index = self._Control:GetSlotOrder(self._SlotId)
    if not isInTeam then
        self._Control:UpdateEntityTeamPos(self._CurSelect, index, true)
        self._Control:UpdateEquipPosRoleId(self._CurSelect, self._SlotId, true)
    else
        self._Control:UpdateEntityTeamPos(self._CurSelect, index, false)
        self._Control:UpdateEquipPosRoleId(self._CurSelect, self._SlotId, false)
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_THEATRE3_SAVE_TEAM)
    
    self:Close()
end

return XUiTheatre3RoleRoomDetail