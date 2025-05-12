local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
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
    XUiHelper.RegisterClickEvent(self, self.BtnType, self.OnBtnCareerTipsClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill1, function ()
        self:OnBtnGeneralSkillClick(1)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill2, function ()
        self:OnBtnGeneralSkillClick(2)
    end)
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
    local list = XMVCA.XCharacter:GetOwnCharacterList(self._CharacterType)

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
    self:UpdateCharacter()
end

function XUiGuildWarCharacterSelectSelf:UpdateCharacter()
    local character = self._Character
    if not character then
        return
    end
    local characterId = character:GetId()
    if not characterId then
        return
    end
    self:SetJoinBtnIsActive(not self._Team:CheckHasSameMember({
        EntityId = characterId,
        PlayerId = XPlayer.Id
    }))
        
    -- 机体名
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    -- 职业
    local career = XMVCA.XCharacter:GetCharacterCareer(characterId)
    local careerIcon = XMVCA.XCharacter:GetNpcTypeIcon(career)
    self.BtnType:SetRawImage(careerIcon)

    local showUniframe = XMVCA.XCharacter:GetIsIsomer(characterId)
    self.BtnUniframeTip.gameObject:SetActiveEx(showUniframe)

    -- 元素
    local elementList = XMVCA.XCharacter:GetCharacterAllElement(characterId, true)
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActiveEx(true)
            local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end

    -- 机制
    local generalSkillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(characterId)
    for i = 1, self.ListGeneralSkillDetail.childCount, 1 do
        local id = generalSkillIds[i]
        self["BtnGeneralSkill"..i].gameObject:SetActiveEx(id)
        if id then
            local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
            self["BtnGeneralSkill"..i]:SetRawImage(generalSkillConfig.Icon)
        end
    end

    self.TxtFight.text = XMVCA.XCharacter:GetCharacterHaveRobotAbilityById(characterId)
end

function XUiGuildWarCharacterSelectSelf:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self:GetCharacterId(), XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
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

function XUiGuildWarCharacterSelectSelf:OnBtnCareerTipsClick()
    local charId = self:GetCurCharacterId()
    if not charId then
        return
    end
    XLuaUiManager.Open("UiCharacterAttributeDetail", charId)
end

function XUiGuildWarCharacterSelectSelf:GetCurCharacterId()
    local character = self._Character
    if not character then
        return
    end
    local characterId = character:GetId()
    return characterId
end

function XUiGuildWarCharacterSelectSelf:OnBtnGeneralSkillClick(index)
    local charId = self:GetCurCharacterId()
    if not charId then
        return
    end

    local activeGeneralSkillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(charId)
    local curId = activeGeneralSkillIds[index]
    local realIndex = XMVCA.XCharacter:GetIndexInCharacterGeneralSkillIdsById(charId, curId)

    XLuaUiManager.Open("UiCharacterAttributeDetail", charId, XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill, realIndex)
end

function XUiGuildWarCharacterSelectSelf:SetJoinBtnIsActive(value)
    self.BtnJoinTeam.gameObject:SetActiveEx(value)
    self.BtnQuitTeam.gameObject:SetActiveEx(not value)
end

return XUiGuildWarCharacterSelectSelf
