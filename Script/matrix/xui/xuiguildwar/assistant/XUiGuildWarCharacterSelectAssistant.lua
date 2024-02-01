local XUiGuildWarCharacterSelectAssistantGrid = require("XUi/XUiGuildWar/Assistant/XUiGuildWarCharacterSelectAssistantGrid")
local XUiExpeditionEquipGrid = require("XUi/XUiExpedition/RoleList/XUiExpeditionEquipGrid/XUiExpeditionEquipGrid")

---@class XUiGuildWarCharacterSelectAssistant@refer to XUiPanelStrongholdRoomCharacterOthers
local XUiGuildWarCharacterSelectAssistant = XClass(nil, "XUiGuildWarCharacterSelectAssistant")

function XUiGuildWarCharacterSelectAssistant:Ctor(ui, selectCharacterCb, closeUiFunc, playAnimationCb, team, pos, rootUi, filter)
    self.RootUi = rootUi
    ---@type XGuildWarTeam
    self._Team = team
    self._Pos = pos
    self._Index = false
    self.WearingAwarenessGrids = {}
    self._Timer = false
    self._FilterKey = false
    self._MemberData = false
    ---@type XUiGuildWarCharacterFilter
    self._Filter = filter

    self.SelectCharacterCb = selectCharacterCb
    self.CloseUiFunc = closeUiFunc
    self.PlayAnimationCb = playAnimationCb

    XTool.InitUiObjectByUi(self, ui)
    self:Init()
end

function XUiGuildWarCharacterSelectAssistant:Init()
    ---@type XDynamicTableNormal
    --self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    --self.DynamicTable:SetProxy(XUiGuildWarCharacterSelectAssistantGrid)
    --self.DynamicTable:SetDelegate(self)
    self.GridCharacter.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnJoinTeam, self.OnBtnJoinTeamClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnQuitTeam, self.OnBtnQuitTeamClick)
    self.PanelEmptyListOthers.gameObject:SetActiveEx(true)
    self.ImgEmptyShougezhe.gameObject:SetActiveEx(false)
    self.SViewCharacterList.gameObject:SetActiveEx(true)
end

function XUiGuildWarCharacterSelectAssistant:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildWarCharacterSelectAssistant:Show(filterKey)
    --self._FilterKey = filterKey
    self.GameObject:SetActiveEx(true)
    --self._Index = false
    --self:UpdateData()
    --self:SelectCharacter(1)
    --if not self:GetCharacterData() then
    --    self._Index = false
    --end
    --if self._Index then
    --    self.DynamicTable:ReloadDataSync(self._Index)
    --end
    --
    --self.ImgEmpty.gameObject:SetActiveEx(false)
    --self.ImgEmptyShougezhe.gameObject:SetActiveEx(false)
    self:UpdateEmpty(true)
    self:OnEnable()
end

function XUiGuildWarCharacterSelectAssistant:OnEnable()
    XDataCenter.GuildWarManager.RequestAssistCharacterList()
    self:StartTimerCd()
end

function XUiGuildWarCharacterSelectAssistant:OnDisable()
    self:StopTimerCd()
end

function XUiGuildWarCharacterSelectAssistant:SelectCharacter(index)
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
    self.SelectCharacterCb(self:GetCharacterData())
end
function XUiGuildWarCharacterSelectAssistant:GetEntities(notFilter)
    local list = XDataCenter.GuildWarManager.GetAssistantCharacterList()
    if not notFilter then
        for i = 1, #list do
            local data = list[i]
            if not data.Id then
                -- 有危险
                data.Id = data.FightNpcData.Character.Id
            end
        end

        local filterData = XDataCenter.CommonCharacterFiltManager.GetSelectTagData(self._FilterKey)
        if filterData then
            list = XDataCenter.CommonCharacterFiltManager.DoFilter(list, filterData)
        end
    end

    --同级按照战斗力和ID排序
    local SortNormal = function(A1, A2, ID1, ID2)
        if A1 ~= A2 then
            return A1 > A2
        end
        return ID1 > ID2
    end
    local team = self._Team
    table.sort(list, function(CA, CB)
        local EntityIdA = CA.Id
        local EntityIdB = CB.Id
        local AbilityA = CA.Ability
        local AbilityB = CB.Ability

        --判断是否特攻角色 特攻优先
        local SpecialA = XDataCenter.GuildWarManager.CheckIsSpecialRole(EntityIdA)
        local SpecialB = XDataCenter.GuildWarManager.CheckIsSpecialRole(EntityIdB)
        if SpecialA and SpecialB and EntityIdA ~= EntityIdB then
            --判断是否头牌特攻角色
            local isCenterSpecialA = XDataCenter.GuildWarManager.CheckIsCenterSpecialRole(EntityIdA)
            local isCenterSpecialB = XDataCenter.GuildWarManager.CheckIsCenterSpecialRole(EntityIdB)
            if isCenterSpecialA ~= isCenterSpecialB then
                return isCenterSpecialA
            end
            return SortNormal(AbilityA, AbilityB, EntityIdA, EntityIdB)
        end
        if EntityIdA ~= EntityIdB and SpecialA ~= SpecialB then
            return SpecialA
        end
        --判断是否在队伍 队伍中的优先
        local PlayerA = CA.PlayerId
        local PlayerB = CB.PlayerId
        local InTeamA = team:CheckHasSameMember({
            EntityId = EntityIdA,
            PlayerId = PlayerA
        })
        local InTeamB = team:CheckHasSameMember({
            EntityId = EntityIdB,
            PlayerId = PlayerB
        })
        if InTeamA ~= InTeamB then
            return InTeamA
        end
        return SortNormal(AbilityA, AbilityB, EntityIdA, EntityIdB)
    end)

    -- 队伍中的优先, 支援角色最多一个
    local flag = 1
    for i = 1, #list do
        local data = list[i]
        if team:CheckHasSameMember({
            EntityId = data.FightNpcData.Character.Id,
            PlayerId = data.PlayerId
        }) then
            list[i] = list[flag]
            list[flag] = data
            flag = flag + 1
        end
    end
    return list
end

function XUiGuildWarCharacterSelectAssistant:UpdateData()
    local dataSource = self:GetEntities()
    self.DynamicTable:SetDataSource(dataSource)
end

function XUiGuildWarCharacterSelectAssistant:GetCharacterData()
    return self._MemberData
end

---@param grid XUiGuildWarCharacterSelectAssistantGrid
function XUiGuildWarCharacterSelectAssistant:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local dataSource = self.DynamicTable.DataSource
        local data = dataSource[index]
        grid:Refresh(data)
        grid:SetSelect(index == self._Index)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:SelectCharacter(index)
    end
end

---@type XGuildWarMember
function XUiGuildWarCharacterSelectAssistant:UpdateCharacterData(member)
    self._MemberData = member
    self:UpdateBtns()
    self:UpdateEquips()
    self:StartTimerCd()
end

function XUiGuildWarCharacterSelectAssistant:UpdateBtns()
    local data = self._MemberData
    if not data then
        self.BtnQuitTeam.gameObject:SetActiveEx(false)
        self.BtnJoinTeam.gameObject:SetActiveEx(false)
        self.BtnJoinDisable.gameObject:SetActiveEx(false)
        self.BtnLock.gameObject:SetActiveEx(false)
        self.PanelCD.gameObject:SetActiveEx(false)
        return
    end
    local character = data.FightNpcData.Character
    local characterId = character.Id

    self.BtnJoinDisable.gameObject:SetActiveEx(false)

    self.PanelCD.gameObject:SetActiveEx(false)

    -- 支援角色冷却中
    local cd = self:GetAssistantCd()
    if cd > 0 then
        self.BtnQuitTeam.gameObject:SetActiveEx(false)
        self.BtnJoinTeam.gameObject:SetActiveEx(false)
        self.BtnJoinDisable.gameObject:SetActiveEx(false)
        self.BtnLock.gameObject:SetActiveEx(true)
        self.PanelCD.gameObject:SetActiveEx(true)
        return
    end

    -- 在队伍中
    if XDataCenter.GuildWarManager.GetBattleManager():GetTeam():GetEntityIdIsInTeam(characterId) then
        self.BtnQuitTeam.gameObject:SetActiveEx(true)
        self.BtnJoinTeam.gameObject:SetActiveEx(false)
        self.BtnJoinDisable.gameObject:SetActiveEx(false)
        self.BtnLock.gameObject:SetActiveEx(false)
        self.PanelCD.gameObject:SetActiveEx(false)
        return
    end

    -- 授格者
    if XMVCA.XCharacter:GetIsIsomer(characterId) and not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer) then
        self.BtnQuitTeam.gameObject:SetActiveEx(false)
        self.BtnJoinTeam.gameObject:SetActiveEx(false)
        self.BtnJoinDisable.gameObject:SetActiveEx(true)
        self.BtnLock.gameObject:SetActiveEx(false)
        self.PanelCD.gameObject:SetActiveEx(false)
        return
    end

    -- 可加入
    self.BtnQuitTeam.gameObject:SetActiveEx(false)
    self.BtnJoinTeam.gameObject:SetActiveEx(true)
    self.BtnJoinDisable.gameObject:SetActiveEx(false)
    self.BtnLock.gameObject:SetActiveEx(false)
    self.PanelCD.gameObject:SetActiveEx(false)
end

function XUiGuildWarCharacterSelectAssistant:GetAssistantCd()
    local data = self:GetCharacterData()
    return XDataCenter.GuildWarManager.GetCdUsingAssistantCharacter(data)
end

function XUiGuildWarCharacterSelectAssistant:IsEmpty()
    --local dataSource = self.DynamicTable.DataSource
    --return #dataSource == 0
    return not self._MemberData
end

function XUiGuildWarCharacterSelectAssistant:UpdateEmpty(visible)
    if visible then
        self.PanelEquipment.gameObject:SetActiveEx(true)
        self.ImgEmpty.gameObject:SetActiveEx(false)
        return
    end
    self.PanelEquipment.gameObject:SetActiveEx(false)
    self.ImgEmpty.gameObject:SetActiveEx(true)
end

function XUiGuildWarCharacterSelectAssistant:UpdateEquips()
    if self:IsEmpty() then
        self.PanelEquipment.gameObject:SetActiveEx(false)
        return
    end
    self.PanelEquipment.gameObject:SetActiveEx(true)

    local data = self._MemberData
    local equips = data and data.FightNpcData.Equips or {}

    local weapon = {}
    local equipSiteDic = {}
    local weaponResonanceCount = 0
    for _, equip in pairs(equips) do
        if XDataCenter.EquipManager.IsWeaponByTemplateId(equip.TemplateId) then
            weapon = equip
            weaponResonanceCount = #equip.ResonanceInfo
        else
            local site = XDataCenter.EquipManager.GetEquipSiteByEquipData(equip)
            equipSiteDic[site] = equip
        end
    end

    self.WeaponGrid = self.WeaponGrid or XUiExpeditionEquipGrid.New(self.GridWeapon, nil, self.RootUi)
    local usingWeaponId = weapon.TemplateId
    if usingWeaponId then
        self.WeaponGrid:Refresh(usingWeaponId, weapon.Breakthrough, 0, true, weapon.Level, weaponResonanceCount)
    end

    for i = 1, 6 do
        self.WearingAwarenessGrids[i] = self.WearingAwarenessGrids[i] or XUiExpeditionEquipGrid.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), nil, self.RootUi)
        self.WearingAwarenessGrids[i].Transform:SetParent(self["PanelAwareness" .. i], false)

        local equip = equipSiteDic[i]
        if not equip then
            self.WearingAwarenessGrids[i].GameObject:SetActiveEx(false)
        else
            local resonanceCount = #equip.ResonanceInfo
            self.WearingAwarenessGrids[i].GameObject:SetActiveEx(true)
            self.WearingAwarenessGrids[i]:Refresh(equip.TemplateId, equip.Breakthrough, i, false, equip.Level, resonanceCount)
        end
    end

    -- partner
    local partnerId = data and data.FightNpcData.Partner and data.FightNpcData.Partner.TemplateId
    if partnerId then
        local icon = XPartnerConfigs.GetPartnerTemplateIcon(partnerId)
        self.PartnerIcon:SetRawImage(icon)
        self.PartnerIcon.gameObject:SetActiveEx(true)
    else
        self.PartnerIcon.gameObject:SetActiveEx(false)
    end
end

function XUiGuildWarCharacterSelectAssistant:StartTimerCd()
    self:UpdateTime()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
            self:UpdateGridCd()
        end, 1)
    end
end

function XUiGuildWarCharacterSelectAssistant:StopTimerCd()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiGuildWarCharacterSelectAssistant:UpdateTime()
    local cd = self:GetAssistantCd()
    if cd <= 0 then
        self:UpdateBtns()
        self:StopTimerCd()
        return
    end
    self.TextCd.text = XUiHelper.GetText("GuildWarAssistantCD", XUiHelper.GetTime(cd, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND))
end

function XUiGuildWarCharacterSelectAssistant:OnBtnJoinTeamClicked()
    local data = self:GetCharacterData()
    local character = data.FightNpcData.Character
    local characterId = character.Id
    local memberData = {
        EntityId = characterId,
        PlayerId = data.PlayerId
    }
    self._Team:UpdateEntityTeamPos(memberData, self._Pos, true)
    self.CloseUiFunc(true, memberData)
end

function XUiGuildWarCharacterSelectAssistant:OnBtnQuitTeamClick()
    local data = self:GetCharacterData()
    local character = data.FightNpcData.Character
    local characterId = character.Id
    self._Team:KickOut(characterId)
    self.CloseUiFunc(true, false)
end

function XUiGuildWarCharacterSelectAssistant:UpdateGridCd()
    ---@type XUiGuildWarCharacterSelectAssistantGrid[]
    local grids = self._Filter.DynamicTableSupport:GetGrids()
    for i, grid in pairs(grids) do
        grid:UpdateCdAndInTeam()
    end
end

return XUiGuildWarCharacterSelectAssistant
