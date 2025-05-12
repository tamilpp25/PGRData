local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiGuildWarAssistantSelectGrid = require("XUi/XUiGuildWar/Assistant/XUiGuildWarAssistantSelectGrid")

---@class UiGuildWarAssistantSelect:XLuaUi@ 没有新增ui, 用的是UiBattleRoomRoleDetail
local XUiGuildWarAssistantSelect = XLuaUiManager.Register(XLuaUi, "UiGuildWarAssistantSelect")

function XUiGuildWarAssistantSelect:Ctor()
    self._Team = false
    self._Pos = false
    self._CurrentCharacterId = false
    self._CurrentCharacterType = XEnumConst.CHARACTER.CharacterType.Normal
end

function XUiGuildWarAssistantSelect:OnStart()
    self:Init()
end

function XUiGuildWarAssistantSelect:Init()
    -- model
    local panelModel = self.UiModelGo.transform:FindTransform("PanelRoleModel")
    self.UiPanelRoleModel = XUiPanelRoleModel.New(panelModel, self.Name, nil, true)
    
    -- main and back
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)

    -- PanelAsset
    local ItemId = XDataCenter.ItemManager.ItemId
    XUiPanelAsset.New(self, self.PanelAsset,
        ItemId.FreeGem,
        ItemId.ActionPoint,
        ItemId.Coin)

    -- button click
    self:RegisterClickEvent(self.BtnPartner, self.OnBtnPartnerClicked)
    self:RegisterClickEvent(self.BtnFashion, self.OnBtnFashionClicked)
    self:RegisterClickEvent(self.BtnConsciousness, self.OnBtnConsciousnessClicked)
    self:RegisterClickEvent(self.BtnWeapon, self.OnBtnWeaponClicked)

    -- 独域机体
    if self:IsIsomerLock() then
        self.BtnTabShougezhe:SetDisable(true)
    end

    -- 角色列表
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGuildWarAssistantSelectGrid)
    self.DynamicTable:SetDelegate(self)
    
    -- button join
    self:RegisterClickEvent(self.BtnJoinTeam, self.OnBtnJoinTeamClicked)
    local textBtnJoinTeam = XUiHelper.TryGetComponent(self.BtnJoinTeam.transform, "Text1", "Text")
    textBtnJoinTeam.text = XUiHelper.GetText("GuildWarAssistantSet")

    -- hide useless ui
    self.PanelCharacterLimit.gameObject:SetActiveEx(false)
    self.BtnTeaching.gameObject:SetActiveEx(false)
    self.BtnFilter.gameObject:SetActiveEx(false)

    -- 角色类型按钮组
    self.BtnGroupCharacterType:Init(
        {
            [XEnumConst.CHARACTER.CharacterType.Normal] = self.BtnTabGouzaoti,
            [XEnumConst.CHARACTER.CharacterType.Isomer] = self.BtnTabShougezhe,
        },
        function(tabIndex)
            self:OnBtnGroupCharacterTypeClicked(tabIndex)
        end
    )
end

function XUiGuildWarAssistantSelect:OnEnable()
    self:UpdateDataSource()
    self.BtnGroupCharacterType:SelectIndex(self._CurrentCharacterType)
end

function XUiGuildWarAssistantSelect:UpdateDataSource()
    local dataSource = self:GetEntities()
    self.DynamicTable:SetDataSource(dataSource)

    -- select default character
    if #dataSource > 0 then
        local characterId = XDataCenter.GuildWarManager.GetAssistantCharacterId()
        if not characterId then
            characterId = dataSource[1]:GetId()
        end
        
        local index
        for i = 1,#dataSource do
            if characterId == dataSource[i]:GetId() then
                index = i
                break
            end
        end

        if not index then
            index = 1
            characterId = dataSource[1]:GetId()
        end

        self._CurrentCharacterId = characterId
        self.DynamicTable:ReloadDataSync(index)
        self:UpdateCharacter()
    end
end

function XUiGuildWarAssistantSelect:IsIsomerLock()
    return not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer)
end

function XUiGuildWarAssistantSelect:OnBtnPartnerClicked()
    XDataCenter.PartnerManager.GoPartnerCarry(self._CurrentCharacterId, false)
end

function XUiGuildWarAssistantSelect:OnBtnFashionClicked()
    XLuaUiManager.Open("UiFashion", self._CurrentCharacterId)
end

function XUiGuildWarAssistantSelect:OnBtnConsciousnessClicked()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self._CurrentCharacterId)
end

function XUiGuildWarAssistantSelect:OnBtnWeaponClicked()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self._CurrentCharacterId, nil, true)
end

function XUiGuildWarAssistantSelect:OnBtnJoinTeamClicked()
    XDataCenter.GuildWarManager.SendAssistant(self._CurrentCharacterId)
    self:Close()
end

function XUiGuildWarAssistantSelect:GetEntities()
    return XMVCA.XCharacter:GetOwnCharacterList(self._CurrentCharacterType)
end

---@param grid XUiGuildWarAssistantSelectGrid
function XUiGuildWarAssistantSelect:OnDynamicTableEvent(event, index, grid)
    local character = self.DynamicTable.DataSource[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(character)
        grid:SetSelectStatus(self._CurrentCharacterId == character:GetId())
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        for _, tmpGrid in pairs(self.DynamicTable:GetGrids()) do
            tmpGrid:SetSelectStatus(false)
        end
        grid:SetSelectStatus(true)
        self:SetCharacterSelected(character:GetId())
    end
end

function XUiGuildWarAssistantSelect:SetCharacterSelected(characterId)
    self._CurrentCharacterId = characterId
    self:UpdateCharacter()
end

function XUiGuildWarAssistantSelect:UpdateCharacter()
    -- model
    self.UiPanelRoleModel:UpdateCharacterModel(self._CurrentCharacterId)
end

function XUiGuildWarAssistantSelect:OnBtnGroupCharacterTypeClicked(characterType)
    -- 检查功能是否开启
    if characterType == XEnumConst.CHARACTER.CharacterType.Isomer and 
    not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Isomer)
    then
        return
    end
    self._CurrentCharacterType = characterType
    self:UpdateDataSource()
end

return XUiGuildWarAssistantSelect
