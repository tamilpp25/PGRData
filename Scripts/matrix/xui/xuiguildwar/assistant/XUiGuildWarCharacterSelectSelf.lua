local XUiGuildWarCharacterSelectSelfGrid = require("XUi/XUiGuildWar/Assistant/XUiGuildWarCharacterSelectSelfGrid")

---@class XUiGuildWarCharacterSelectSelf@refer to XUiPanelStrongholdRoomCharacterSelf
local XUiGuildWarCharacterSelectSelf = XClass(nil, "XUiGuildWarCharacterSelectSelf")

function XUiGuildWarCharacterSelectSelf:Ctor(ui, selectCharacterCb, closeUiFunc, playAnimationCb, team, pos)
    self._CharacterType = false
    self._Index = false
    self._FilterKey = false

    self._Character = false

    ---@type XGuildWarTeam
    self._Team = team
    self._Pos = pos
    self.SelectCharacterCb = selectCharacterCb
    self.CloseUiFunc = closeUiFunc
    self.PlayAnimationCb = playAnimationCb

    XTool.InitUiObjectByUi(self, ui)
    self:Init()
end

function XUiGuildWarCharacterSelectSelf:Init()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGuildWarCharacterSelectSelfGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridCharacter.gameObject:SetActiveEx(false)

    -- button click
    XUiHelper.RegisterClickEvent(self, self.BtnElementDetail, self.OnBtnElementDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPartner, self.OnBtnPartnerClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnFashion, self.OnBtnFashionClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnConsciousness, self.OnBtnConsciousnessClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnWeapon, self.OnBtnWeaponClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnJoinTeam, self.OnBtnJoinTeamClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnQuitTeam, self.OnBtnQuitTeamClick)
end

function XUiGuildWarCharacterSelectSelf:Show(characterType, selectedEntityId, filterKey)
    --self._FilterKey = filterKey
    self.GameObject:SetActiveEx(true)
    --self._CharacterType = characterType
    --self._Index = false
    --self:UpdateData()
    --
    ----region 默认选择
    --local index = 1
    --if selectedEntityId then
    --    local dataSource = self.DynamicTable.DataSource
    --    for i = 1, #dataSource do
    --        ---@type XCharacter
    --        local character = dataSource[i]
    --        if character:GetId() == selectedEntityId then
    --            index = i
    --        end
    --    end
    --end
    ----endregion 默认选择
    --
    --self:SelectCharacter(index)
    --if not self:GetCharacterId() then
    --    self._Index = false
    --end
    --if self._Index then
    --    self.DynamicTable:ReloadDataSync(self._Index)
    --end
end

function XUiGuildWarCharacterSelectSelf:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildWarCharacterSelectSelf:SelectCharacter(index)
    if self._Index == index then
        return
    end
    self._Index = index
    for _, tempGrid in pairs(self.DynamicTable:GetGrids()) do
        tempGrid:SetSelect(false)
    end
    local grid = self.DynamicTable:GetGridByIndex(self._Index)
    if grid then
        grid:SetSelect(true)
    end

    self:UpdateCharacterData()
    -- model
    self.SelectCharacterCb(self:GetCharacterId(), XPlayer.Id)
end

function XUiGuildWarCharacterSelectSelf:GetEntities(notFilter)
    local list = XDataCenter.CharacterManager.GetOwnCharacterList(self._CharacterType)

    if not notFilter then
        local filterData = XDataCenter.CommonCharacterFiltManager.GetSelectTagData(self._FilterKey)
        if filterData then
            list = XDataCenter.CommonCharacterFiltManager.DoFilter(list, filterData)
        end
    end

    --同级按照战斗力和ID排序
    local SortNormal = function(A1, A2, ID1, ID2)
        if A1 == A2 then
            return ID1 > ID2
        end
        return A1 > A2
    end
    local team = XDataCenter.GuildWarManager.GetBattleManager():GetTeam()
    table.sort(list, function(CA, CB)
        local EntityIdA = CA:GetId()
        local EntityIdB = CB:GetId()
        local AbilityA = CA.Ability
        local AbilityB = CB.Ability
        --判断是否特攻角色 特攻优先
        local SpecialA = XDataCenter.GuildWarManager.CheckIsSpecialRole(EntityIdA)
        local SpecialB = XDataCenter.GuildWarManager.CheckIsSpecialRole(EntityIdB)
        if SpecialA and SpecialB then
            --判断是否头牌特攻角色
            if XDataCenter.GuildWarManager.CheckIsCenterSpecialRole(EntityIdA) then
                return true
            elseif XDataCenter.GuildWarManager.CheckIsCenterSpecialRole(EntityIdB) then
                return false
            else
                return SortNormal(AbilityA, AbilityB, EntityIdA, EntityIdB)
            end
        end
        if SpecialA then
            return true
        end
        if SpecialB then
            return false
        end
        --判断是否在队伍 队伍中的优先
        local InTeamA = team:GetEntityIdIsInTeam(EntityIdA)
        local InTeamB = team:GetEntityIdIsInTeam(EntityIdB)
        if InTeamA and not InTeamB then
            return true
        elseif not InTeamA and InTeamB then
            return false
        end
        return SortNormal(AbilityA, AbilityB, EntityIdA, EntityIdB)
    end)
    return list
end

function XUiGuildWarCharacterSelectSelf:UpdateEmpty(value)
    self.PanelEmptyList.gameObject:SetActiveEx(value)
end

function XUiGuildWarCharacterSelectSelf:GetCharacterId()
    return self._Character:GetId()
end

---@param character XCharacter
function XUiGuildWarCharacterSelectSelf:UpdateCharacterData(character)
    self._Character = character
    local characterId = character:GetId()
    if not characterId then
        return
    end
    self:SetJoinBtnIsActive(not self._Team:CheckHasSameMember({
        EntityId = characterId,
        PlayerId = XPlayer.Id
    }))

    -- name
    local charConfig = XCharacterConfigs.GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    -- icon
    self.RImgTypeIcon:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(character.Type))

    -- level
    self.TxtLv.text = math.floor(character.Ability)

    -- element
    local detailConfig = XCharacterConfigs.GetCharDetailTemplate(characterId)
    local elementList = detailConfig.ObtainElementList
    XUiHelper.RefreshCustomizedList(self.BtnElementDetail.transform, self.RImgCharElement1, #elementList, function(index, grid)
        local elementConfig = XCharacterConfigs.GetCharElement(elementList[index])
        local icon = elementConfig.Icon
        grid:GetComponent("RawImage"):SetRawImage(icon)
    end)
end

function XUiGuildWarCharacterSelectSelf:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterElementDetail", self:GetCharacterId())
end

---@param grid XUiGuildWarCharacterSelectSelfGrid
function XUiGuildWarCharacterSelectSelf:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local dataSource = self.DynamicTable.DataSource
        local data = dataSource[index]
        local characterId = data.Id
        grid:Refresh(characterId)
        grid:SetSelect(index == self._Index)
        grid:SetInTeam(self._Team:GetEntityIdIsInTeam(characterId, XPlayer.Id))

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:SelectCharacter(index)
    end
end

function XUiGuildWarCharacterSelectSelf:OnBtnPartnerClicked()
    XDataCenter.PartnerManager.GoPartnerCarry(self:GetCharacterId(), false)
end

function XUiGuildWarCharacterSelectSelf:OnBtnFashionClicked()
    XLuaUiManager.Open("UiFashion", self:GetCharacterId())
end

function XUiGuildWarCharacterSelectSelf:OnBtnConsciousnessClicked()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self:GetCharacterId())
end

function XUiGuildWarCharacterSelectSelf:OnBtnWeaponClicked()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self:GetCharacterId(), nil, true)
end

function XUiGuildWarCharacterSelectSelf:OnBtnJoinTeamClicked()
    local memberData = {
        EntityId = self:GetCharacterId(),
        PlayerId = XPlayer.Id
    }
    self._Team:UpdateEntityTeamPos(memberData, self._Pos, true)
    self.CloseUiFunc(true, memberData)
end

function XUiGuildWarCharacterSelectSelf:OnBtnQuitTeamClick()
    self._Team:KickOut(self:GetCharacterId())
    self.CloseUiFunc(true, false)
end

function XUiGuildWarCharacterSelectSelf:SetJoinBtnIsActive(value)
    self.BtnJoinTeam.gameObject:SetActiveEx(value)
    self.BtnQuitTeam.gameObject:SetActiveEx(not value)
end

return XUiGuildWarCharacterSelectSelf
