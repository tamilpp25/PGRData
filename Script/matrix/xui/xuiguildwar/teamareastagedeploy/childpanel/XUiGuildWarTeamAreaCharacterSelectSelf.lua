local XUiGuildWarTeamAreaCharacterSelectSelfGrid = require("XUi/XUiGuildWar/TeamAreaStageDeploy/ChildPanel/XUiGuildWarTeamAreaCharacterSelectSelfGrid")

---@class XUiGuildWarTeamAreaCharacterSelectSelf@refer to XUiPanelStrongholdRoomCharacterSelf
local XUiGuildWarTeamAreaCharacterSelectSelf = XClass(nil, "XUiGuildWarTeamAreaCharacterSelectSelf")

--初始化
--local InitData = {
--    Ui,
--    RootUi,
--    XTeam,
--    MemberPos,
--    SelectCharacterCb,
--    PlayAnimationCB,
--    CloseUiHandler,
--    JoinTeamHandler,
--    QuitTeamHandler,
--}
function XUiGuildWarTeamAreaCharacterSelectSelf:Ctor(initData)
    XTool.InitUiObjectByUi(self, initData.Ui)
    self.RootUi = initData.RootUi
    ---@type XGuildWarAreaBuild
    self._Build = initData.XBuild
    ---@type XGuildWarAreaTeam
    self._Team = initData.XTeam
    self._Pos = initData.MemberPos
    self.SelectCharacterCb = initData.SelectCharacterCb
    self.PlayAnimationCb = initData.PlayAnimationCB
    self.CloseUiHandler = initData.CloseUiHandler
    self.JoinTeamHandler = initData.JoinTeamHandler
    self.QuitTeamHandler = initData.QuitTeamHandler
    
    self._CharacterType = false
    self._Index = false
    self._FilterKey = false
    
    self:Init()
end

function XUiGuildWarTeamAreaCharacterSelectSelf:Init()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGuildWarTeamAreaCharacterSelectSelfGrid)
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

function XUiGuildWarTeamAreaCharacterSelectSelf:Show(characterType, selectedEntityId, filterKey)
    self._FilterKey = filterKey
    self.GameObject:SetActiveEx(true)
    self._CharacterType = characterType
    self._Index = false
    self:UpdateData()

    --region 默认选择
    local index = 1
    if selectedEntityId then
        local dataSource = self.DynamicTable.DataSource
        for i = 1, #dataSource do
            ---@type XCharacter
            local character = dataSource[i]
            if character:GetId() == selectedEntityId then
                index = i
            end
        end
    end
    --endregion 默认选择

    self:SelectCharacter(index)
    if not self:GetCharacterId() then
        self._Index = false
    end
    if self._Index then
        self.DynamicTable:ReloadDataSync(self._Index)
    end
end

function XUiGuildWarTeamAreaCharacterSelectSelf:SelectCharacter(index)
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

function XUiGuildWarTeamAreaCharacterSelectSelf:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildWarTeamAreaCharacterSelectSelf:GetEntities(notFilter)
    local list = XMVCA.XCharacter:GetOwnCharacterList(self._CharacterType)
    --复制黏贴的筛选逻辑
    if not notFilter then
        local filterData = XDataCenter.CommonCharacterFiltManager.GetSelectTagData(self._FilterKey)
        if filterData then
            list = XDataCenter.CommonCharacterFiltManager.DoFilter(list, filterData)
        end
    end
    local TeamIndexSelf = self._Build:GetXTeamIndex(self._Team) or false
    --同级按照战斗力和ID排序
    local SortNormal = function(A1,A2,ID1,ID2)
        if A1 == A2 then
            return ID1 > ID2
        end
        return A1 > A2
    end
    --头牌特攻>特攻>本编队>没编队>其余编队(编队从小到大)>已锁定
    table.sort(list,function(CA, CB)
        local EntityIdA = CA:GetId()
        local AbilityA = CA.Ability
        local TeamIndexA = self._Build:GetMemberTeamIndex(EntityIdA, XPlayer.Id) or false
        local EntityIdB = CB:GetId()
        local AbilityB = CB.Ability
        local TeamIndexB = self._Build:GetMemberTeamIndex(EntityIdB, XPlayer.Id) or false

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
                return SortNormal(AbilityA, AbilityB, EntityIdA , EntityIdB)
            end
        end
        if SpecialA then return true end
        if SpecialB then return false end
        
        --锁定排最后
        local TeamLockA = TeamIndexA and (not (self._Build:GetXTeam(TeamIndexA):GetTeamIsCustom())) or false
        local TeamLockB = TeamIndexB and (not (self._Build:GetXTeam(TeamIndexB):GetTeamIsCustom())) or false
        if TeamLockA and TeamLockB then return SortNormal(AbilityA, AbilityB, EntityIdA , EntityIdB) end
        if TeamLockA then 
            return false 
        end
        if TeamLockB then 
            return true 
        end
        --同编队排最前
        local SameTeamA = TeamIndexA and TeamIndexSelf == TeamIndexA
        local SameTeamB = TeamIndexB and TeamIndexSelf == TeamIndexB
        if SameTeamA and SameTeamB then
            return SortNormal(AbilityA, AbilityB, EntityIdA , EntityIdB)
        end
        if SameTeamA then 
            return true 
        end
        if SameTeamB then 
            return false 
        end
        --不同编队排 倒数第二
        local DiffTeamA = TeamIndexA and not (TeamIndexSelf == TeamIndexA)
        local DiffTeamB = TeamIndexB and not (TeamIndexSelf == TeamIndexB)
        if DiffTeamA and DiffTeamB then
            return SortNormal(AbilityA, AbilityB, EntityIdA , EntityIdB)
        end
        if DiffTeamA then return false end
        if DiffTeamB then return true end
        --剩下的
        return SortNormal(AbilityA, AbilityB, EntityIdA , EntityIdB)
    end)
    return list
end

function XUiGuildWarTeamAreaCharacterSelectSelf:UpdateData()
    local dataSource = self:GetEntities()
    if #dataSource == 0 and self._CharacterType == XEnumConst.CHARACTER.CharacterType.Isomer then
        self.PanelEmptyList.gameObject:SetActiveEx(true)
    else
        self.PanelEmptyList.gameObject:SetActiveEx(false)
    end
    self.DynamicTable:SetDataSource(dataSource)
end

function XUiGuildWarTeamAreaCharacterSelectSelf:GetCharacterId()
    local data = self.DynamicTable.DataSource[self._Index]
    return data and data.Id or false
end

function XUiGuildWarTeamAreaCharacterSelectSelf:UpdateCharacterData()
    local characterId = self:GetCharacterId()
    if not characterId then
        return
    end
    
    local member = self._Team:GetMember(self._Pos)
    self:SetJoinBtnIsActive(not (member:GetEntityId() == characterId and member:GetPlayerId() == XPlayer.Id))

    -- name
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    -- icon
    local character = XMVCA.XCharacter:GetCharacter(characterId)
    self.RImgTypeIcon:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(character.Type))

    -- level
    self.TxtLv.text = math.floor(character.Ability)

    -- element
    local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(characterId)
    local elementList = detailConfig.ObtainElementList
    XUiHelper.RefreshCustomizedList(self.BtnElementDetail.transform, self.RImgCharElement1, #elementList, function(index, grid)
        local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[index])
        local icon = elementConfig.Icon
        grid:GetComponent("RawImage"):SetRawImage(icon)
    end)
end

function XUiGuildWarTeamAreaCharacterSelectSelf:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self:GetCharacterId(), XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
end

---@param grid XUiGuildWarTeamAreaCharacterSelectSelfGrid
function XUiGuildWarTeamAreaCharacterSelectSelf:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local dataSource = self.DynamicTable.DataSource
        local data = dataSource[index]
        local characterId = data.Id
        grid:Refresh(characterId)
        grid:SetSelect(index == self._Index)
        
        local teamIndex = self._Build:GetMemberTeamIndex(characterId) or false
        local team = teamIndex and self._Build:GetXTeam(teamIndex) or false
        local member = team and team:GetMemberByEntityId(characterId) or false
        if member and member:GetEntityId() == characterId and member:GetPlayerId() == XPlayer.Id then
            local teamLock = teamIndex and (not (team:GetTeamIsCustom())) or false
            grid:SetInTeamNum(teamIndex, teamLock)
        else
            grid:SetInTeamNum(false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:SelectCharacter(index)
    end
end

function XUiGuildWarTeamAreaCharacterSelectSelf:OnBtnPartnerClicked()
    XDataCenter.PartnerManager.GoPartnerCarry(self:GetCharacterId(), false)
end

function XUiGuildWarTeamAreaCharacterSelectSelf:OnBtnFashionClicked()
    XLuaUiManager.Open("UiFashion", self:GetCharacterId())
end

function XUiGuildWarTeamAreaCharacterSelectSelf:OnBtnConsciousnessClicked()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipAwareness(self:GetCharacterId())
end

function XUiGuildWarTeamAreaCharacterSelectSelf:OnBtnWeaponClicked()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipReplace(self:GetCharacterId(), nil, true)
end

function XUiGuildWarTeamAreaCharacterSelectSelf:OnBtnJoinTeamClicked()
    local memberData = {
        EntityId = self:GetCharacterId(),
        PlayerId = XPlayer.Id
    }
    self.JoinTeamHandler(memberData, self._Pos, function(result)
        if result then self.CloseUiHandler(true, memberData) end
    end)
end

function XUiGuildWarTeamAreaCharacterSelectSelf:OnBtnQuitTeamClick()
    if self.QuitTeamHandler(self._Pos) then
        self.CloseUiHandler(true, false)
    else
        XLog.Error("Assistant Character Quit Team Error")
    end
end

function XUiGuildWarTeamAreaCharacterSelectSelf:SetJoinBtnIsActive(value)
    self.BtnJoinTeam.gameObject:SetActiveEx(value)
    self.BtnQuitTeam.gameObject:SetActiveEx(not value)
end

return XUiGuildWarTeamAreaCharacterSelectSelf
