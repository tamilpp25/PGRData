local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
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
    ---@type XCommonCharacterFilterAgency
    self.FiltAgecy = XMVCA:GetAgency(ModuleId.XCommonCharacterFilter)

    self:AddBtnListener()
end

function XUiTheatre3RoleRoomDetail:OnStart(slotId, characterId, isLockCharacter)
    self._SlotId = slotId
    self._InitCharacterId = characterId
    self._IsLockCharacter = isLockCharacter
    self:InitSceneRoot()
    self:InitEnergy()
    self:InitFilter()
    self:InitSuitList(slotId)
    
    self:UpdateEnergy()
    self.TxtTitle.text = XUiHelper.GetText("Theatre3RoleRoomTitle")
    self.BtnCharacterDetails.gameObject:SetActiveEx(not self._IsLockCharacter)
    self.BtnJoinTeam.gameObject:SetActiveEx(not self._IsLockCharacter)
end

function XUiTheatre3RoleRoomDetail:OnEnable()
    -- 只有第二次进入enbale才需要同步标签和角色，刷新角色信息。 因为第一次在init时刷新了
    if self.IsEnableFin then
        self.PanelFilter:DoSelectTag("BtnAll", true, self._CurSelectRoleId)
        self:UpdateRoleModel(self._CurSelectRoleId)
    end
    self.IsEnableFin = true
end

function XUiTheatre3RoleRoomDetail:OnDestroy()

end

function XUiTheatre3RoleRoomDetail:OnGetEvents()
    return { XEventId.EVENT_CHARACTER_SYN, XEventId.EVENT_CHARACTER_FIRST_GET }
end

function XUiTheatre3RoleRoomDetail:OnNotify(evt)
    self:RefreshFilter()
end

--region Ui - EnergyPanel
function XUiTheatre3RoleRoomDetail:InitEnergy()
    ---@type XPanelTheatre3Energy
    self._PanelEnergy = XPanelTheatre3Energy.New(self.Energy, self)
end

function XUiTheatre3RoleRoomDetail:UpdateEnergy()
    self._PanelEnergy:Refresh(true)
end
--endregion

--region Ui - Filter
function XUiTheatre3RoleRoomDetail:InitFilter()
    local checkInTeam = function(id)
        return self._Control:GetEntityIdIsInTeam(id)
    end
    local sortOverride = self._Control:GetFilterSortOverrideFunTable(self._SlotId)
    
    self.PanelFilter = self.FiltAgecy:InitFilter(self.PanelCharacterFilter, self)
    self.PanelFilter:InitData(handler(self, self.OnSelectTab), nil, nil, nil, XUiTheatre3RoleRoomCharacterListGrid, checkInTeam, sortOverride)
    self.PanelFilter:ImportList(self:GetCharacterList())
    self.PanelFilter:RefreshList()
    self.PanelFilter:ImportDiyLists(self:GetCharacterList(true))
    
    local slotInfo = self._Control:GetSlotInfo(self._SlotId)
    if slotInfo and not self._IsLockCharacter then
        local defaultCharacterId = slotInfo:GetRoleId()
        if XTool.IsNumberValid(defaultCharacterId) then
            self.PanelFilter:DoSelectCharacter(defaultCharacterId)
        end
    end
    if XTool.IsNumberValid(self._InitCharacterId) and self._IsLockCharacter then
        self.PanelFilter:DoSelectCharacter(self._InitCharacterId)
    end
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

function XUiTheatre3RoleRoomDetail:RefreshFilter()
    -- 刷新时要重新获取源数据，因为角色data可能从碎片变成xCharacter。要重新获取
    local list = self:GetCharacterList()
    self.PanelFilter:ImportList(list)
    self.PanelFilter:RefreshList()
end

function XUiTheatre3RoleRoomDetail:OnSelectTab(character, index, grid)
    local id = character.Id
    self._CurSelectRoleId = id
    
    local isInTeam, colorId = self._Control:GetEntityIdIsInTeam(id)
    local txtKey = "Theatre3RoleJoin"
    if isInTeam then
        if colorId == self._Control:GetSlotOrder(self._SlotId) then
            txtKey = "Theatre3RoleExit"
            self._PanelEnergy:ShowCanAddEnergy(self._Control:GetCharacterCost(id))
        else
            txtKey = "Replace"
            self._PanelEnergy:ShowCanAddEnergy(0)
        end
    else
        self._PanelEnergy:ShowCanAddEnergy(-self._Control:GetCharacterCost(id))
    end
    self.BtnJoinTeam:SetNameByGroup(0, XUiHelper.GetText(txtKey))
    self.BtnCharacterDetails.gameObject:SetActiveEx(not XRobotManager.CheckIsRobotId(id) and not self._IsLockCharacter)
    self:UpdateRoleModel(id)
end
--endregion

--region Ui - EquipSuit
function XUiTheatre3RoleRoomDetail:InitSuitList(slotId)
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.SViewSetList.gameObject)
    self.DynamicTable:SetProxy(XUiTheatre3EquipmentSuit, self, function(grid)
        self:OnClickSuitGrid(grid)
    end)
    self.DynamicTable:SetDelegate(self)

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
--endregion

--region Scene - Model
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

function XUiTheatre3RoleRoomDetail:UpdateRoleModel(id)
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanren1.gameObject:SetActiveEx(false)
    self.RoleModelPanel:UpdateCharacterModel(id, self.PanelRoleModel, self.Name, function(model)
        self.PanelDrag.Target = model.transform
        self.ImgEffectHuanren.gameObject:SetActiveEx(characterAgency:GetCharacterType(id) == XEnumConst.CHARACTER.CharacterType.Normal)
        self.ImgEffectHuanren1.gameObject:SetActiveEx(characterAgency:GetCharacterType(id) == XEnumConst.CHARACTER.CharacterType.Isomer)
    end)
end
--endregion

--region Ui - BtnListener
function XUiTheatre3RoleRoomDetail:AddBtnListener()
    self:BindExitBtns()
    self.BtnCharacterDetails.CallBack = handler(self, self.OnShowDetail)
    self.BtnJoinTeam.CallBack = handler(self, self.OnJoinOrExitTeam)
end

function XUiTheatre3RoleRoomDetail:OnShowDetail()
    XLuaUiManager.Open("UiCharacterSystemV2P6", self._CurSelectRoleId)
end

function XUiTheatre3RoleRoomDetail:OnJoinOrExitTeam()
    local isInTeam, targetColorId = self._Control:GetEntityIdIsInTeam(self._CurSelectRoleId)

    if not isInTeam then
        local needCost = self._Control:GetCharacterCost(self._CurSelectRoleId)
        local curEnergy, totalEnergy = self._Control:GetCurEnergy()
        if needCost + curEnergy - self._CurCharCost > totalEnergy then
            XUiManager.TipMsg(XUiHelper.GetText("Theatre3EnergyNoEnoughTip"))
            return
        end
        if self._Control:IsCharacterRepeat(self._CurSelectRoleId) then
            XUiManager.TipMsg(XUiHelper.GetText("StrongholdElectricDeploySameCharacter"))
            return
        end
    end

    local curSelectColor = self._Control:GetSlotOrder(self._SlotId)
    if not isInTeam then
        self._Control:UpdateEntityTeamPos(self._CurSelectRoleId, curSelectColor, true)
        self._Control:UpdateEquipPosRoleId(self._CurSelectRoleId, self._SlotId, true)
    else
        if curSelectColor == targetColorId then    -- 同个位置则下阵
            self._Control:UpdateEntityTeamPos(self._CurSelectRoleId, curSelectColor, false)
            self._Control:UpdateEquipPosRoleId(self._CurSelectRoleId, self._SlotId, false)
        else                        -- 不同位置则替换
            local targetSlotId = self._Control:GetSlotIdByColor(targetColorId)
            local characterId = self._Control:GetEntityIdBySlotColor(curSelectColor)
            -- 编队队伍位置交换
            self._Control:SwapEntityTeamPos(targetColorId, curSelectColor)
            -- 装备槽位角色交换
            self._Control:UpdateEquipPosRoleId(characterId, targetSlotId, true)
            self._Control:UpdateEquipPosRoleId(self._CurSelectRoleId, self._SlotId, true)
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE3_SAVE_TEAM)

    self:Close()
end
--endregion

return XUiTheatre3RoleRoomDetail