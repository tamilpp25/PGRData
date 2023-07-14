local XUiGuildWarTeamAreaCharacterSelectAssistantGrid = require("XUi/XUiGuildWar/TeamAreaStageDeploy/ChildPanel/XUiGuildWarTeamAreaCharacterSelectAssistantGrid")
local XUiExpeditionEquipGrid = require("XUi/XUiExpedition/RoleList/XUiExpeditionEquipGrid/XUiExpeditionEquipGrid")

local XUiGuildWarTeamAreaCharacterSelectAssistant = XClass(nil, "XUiGuildWarTeamAreaCharacterSelectAssistant")

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
function XUiGuildWarTeamAreaCharacterSelectAssistant:Ctor(initData)
    XTool.InitUiObjectByUi(self, initData.Ui)
    self.RootUi = initData.RootUi
    ---@type XGuildWarAreaBuild
    self._Build = initData.XBuild
    ---@type XGuildWarTeam
    self._Team = initData.XTeam
    self._Pos = initData.MemberPos
    self.SelectCharacterCb = initData.SelectCharacterCb
    self.PlayAnimationCb = initData.PlayAnimationCB
    self.CloseUiHandler = initData.CloseUiHandler
    self.JoinTeamHandler = initData.JoinTeamHandler
    self.QuitTeamHandler = initData.QuitTeamHandler
    
    self._Index = false
    self.WearingAwarenessGrids = {}
    self._Timer = false
    self._FilterKey = false
    
    self:Init()
end
function XUiGuildWarTeamAreaCharacterSelectAssistant:Init()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGuildWarTeamAreaCharacterSelectAssistantGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridCharacter.gameObject:SetActiveEx(false)

    XUiHelper.RegisterClickEvent(self, self.BtnJoinTeam, self.OnBtnJoinTeamClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnQuitTeam, self.OnBtnQuitTeamClick)
end

--父UI调用 展示界面接口
function XUiGuildWarTeamAreaCharacterSelectAssistant:Show(filterKey)
    self._FilterKey = filterKey
    self.GameObject:SetActiveEx(true)
    self._Index = false
    self:UpdateData()
    self:SelectCharacter(1)
    if not self:GetCharacterData() then
        self._Index = false
    end
    if self._Index then
        self.DynamicTable:ReloadDataSync(self._Index)
    end

    --没有支援角色LOGO
    self.ImgEmpty.gameObject:SetActiveEx(#self:GetEntities() == 0)
    --当前选择支援角色无法使用 logo
    self.ImgEmptyShougezhe.gameObject:SetActiveEx(false)
    self:OnEnable()
end
--Enable
function XUiGuildWarTeamAreaCharacterSelectAssistant:OnEnable()
    XDataCenter.GuildWarManager.RequestAssistCharacterList()
    self:StartTimerCd()
end
--Disable
function XUiGuildWarTeamAreaCharacterSelectAssistant:OnDisable()
    self:StopTimerCd()
end
--开始 支援角色CD计时器 
function XUiGuildWarTeamAreaCharacterSelectAssistant:StartTimerCd()
    self:UpdateTime()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
            self:UpdateGridsCd()
        end,1)
    end
end
--关闭刷新界面计时器
function XUiGuildWarTeamAreaCharacterSelectAssistant:StopTimerCd()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end
--更新时间
function XUiGuildWarTeamAreaCharacterSelectAssistant:UpdateTime()
    local cd = self:GetAssistantCd()
    if cd <= 0 then
        self:UpdateBtns()
        self:StopTimerCd()
        return
    end
    self.TextCd.text = XUiHelper.GetText("GuildWarAssistantCD", XUiHelper.GetTime(cd, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND))
end
--选中角色
function XUiGuildWarTeamAreaCharacterSelectAssistant:SelectCharacter(index)
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

function XUiGuildWarTeamAreaCharacterSelectAssistant:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildWarTeamAreaCharacterSelectAssistant:GetEntities(notFilter)
    local list = XDataCenter.GuildWarManager.GetAssistantCharacterList()
    --原来的筛选逻辑
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
    
    local TeamIndexSelf = self._Build:GetXTeamIndex(self._Team) or false
    --同级按照战斗力和ID排序
    local SortNormal = function(A1,A2,ID1,ID2)
        if A1 ~= A2 then
            return A1 > A2
        end
        return ID1 > ID2
    end
    --头牌特攻>特攻>本编队>没编队>其余编队(按照战斗力和ID排序)>已锁定
    table.sort(list,function(CA, CB)
        local EntityIdA = CA.Id
        local AbilityA = CA.FightNpcData.Character.Ability
        local TeamIndexA, XMemberA = self._Build:GetMemberTeamIndex(EntityIdA) or false
        local EntityIdB = CB.Id
        local AbilityB = CB.FightNpcData.Character.Ability
        local TeamIndexB, XMemberB = self._Build:GetMemberTeamIndex(EntityIdB) or false

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
            return SortNormal(AbilityA, AbilityB, EntityIdA , EntityIdB)
        end
        if EntityIdA ~= EntityIdB and SpecialA ~= SpecialB then
            return SpecialA
        end
        
        --锁定排最后
        if XMemberA and XMemberA:IsMyCharacter() then TeamIndexA = false end
        local TeamLockA = TeamIndexA and (not (self._Build:GetXTeam(TeamIndexA):GetTeamIsCustom())) or false
        if XMemberB and XMemberB:IsMyCharacter() then TeamIndexB = false end
        local TeamLockB = TeamIndexB and (not (self._Build:GetXTeam(TeamIndexB):GetTeamIsCustom())) or false
        if TeamLockA and TeamLockB then return SortNormal(AbilityA, AbilityB, EntityIdA , EntityIdB) end
        if EntityIdA ~= EntityIdB and TeamLockA ~= TeamLockB then
            return TeamLockB
        end
        --同编队排最前
        local SameTeamA = TeamIndexA and TeamIndexSelf == TeamIndexA
        local SameTeamB = TeamIndexB and TeamIndexSelf == TeamIndexB
        if SameTeamA and SameTeamB then
            return SortNormal(AbilityA, AbilityB, EntityIdA , EntityIdB)
        end
        if SameTeamA ~= SameTeamB then
            return SameTeamA
        end
        --不同编队排 倒数第二
        local DiffTeamA = TeamIndexA and not (TeamIndexSelf == TeamIndexA)
        local DiffTeamB = TeamIndexB and not (TeamIndexSelf == TeamIndexB)
        if DiffTeamA and DiffTeamB then
            return SortNormal(AbilityA, AbilityB, EntityIdA , EntityIdB)
        end
        if DiffTeamA ~= DiffTeamB then
            return DiffTeamB
        end
        --剩下的
        return SortNormal(AbilityA, AbilityB, EntityIdA , EntityIdB)
    end)
    return list
end

function XUiGuildWarTeamAreaCharacterSelectAssistant:UpdateData()
    local dataSource = self:GetEntities()
    self.DynamicTable:SetDataSource(dataSource)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiGuildWarTeamAreaCharacterSelectAssistant:GetCharacterData()
    return self.DynamicTable.DataSource[self._Index]
end

--- grid XUiGuildWarTeamAreaCharacterSelectAssistantGrid(同目录下的)
function XUiGuildWarTeamAreaCharacterSelectAssistant:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local dataSource = self.DynamicTable.DataSource
        local data = dataSource[index]
        grid:Refresh(data)
        grid:SetSelect(index == self._Index)
        self:UpdateGridCd(grid)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:SelectCharacter(index)
    end
end

function XUiGuildWarTeamAreaCharacterSelectAssistant:UpdateCharacterData()
    self:UpdateBtns()
    self:UpdateEquips()
    self:StartTimerCd()
end

function XUiGuildWarTeamAreaCharacterSelectAssistant:UpdateBtns()
    local dataSource = self.DynamicTable.DataSource
    local data = dataSource[self._Index]
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
    
    -- 在队伍对应的位置中
    if characterId == self._Team:GetEntityIdByTeamPos(self._Pos) then
        self.BtnQuitTeam.gameObject:SetActiveEx(true)
        self.BtnJoinTeam.gameObject:SetActiveEx(false)
        self.BtnJoinDisable.gameObject:SetActiveEx(false)
        self.BtnLock.gameObject:SetActiveEx(false)
        self.PanelCD.gameObject:SetActiveEx(false)
        return
    end

    -- 授格者
    if XCharacterConfigs.IsIsomer(characterId) and not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer) then
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

function XUiGuildWarTeamAreaCharacterSelectAssistant:GetAssistantCd()
    local data = self:GetCharacterData()
    return XDataCenter.GuildWarManager.GetCdUsingAssistantCharacter(data)
end

function XUiGuildWarTeamAreaCharacterSelectAssistant:IsEmpty()
    local dataSource = self.DynamicTable.DataSource
    return #dataSource == 0
end

function XUiGuildWarTeamAreaCharacterSelectAssistant:UpdateEquips()
    if self:IsEmpty() then
        self.PanelEquipment.gameObject:SetActiveEx(false)
        return
    end
    self.PanelEquipment.gameObject:SetActiveEx(true)

    local dataSource = self.DynamicTable.DataSource
    local data = dataSource[self._Index]
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



function XUiGuildWarTeamAreaCharacterSelectAssistant:OnBtnJoinTeamClicked()
    local data = self:GetCharacterData()
    local character = data.FightNpcData.Character
    local characterId = character.Id
    local memberData = {
        EntityId = characterId,
        PlayerId = data.PlayerId
    }
    self.JoinTeamHandler(memberData, self._Pos, function(result)
        if result then self.CloseUiHandler(true, memberData) end
    end)
end

function XUiGuildWarTeamAreaCharacterSelectAssistant:OnBtnQuitTeamClick()
    if self.QuitTeamHandler(self._Pos) then
        self.CloseUiHandler(true, false)
    else
        XLog.Error("Assistant Character Quit Team Error")
    end
end

function XUiGuildWarTeamAreaCharacterSelectAssistant:UpdateGridsCd()
    local grids = self.DynamicTable:GetGrids()
    --赶时间暴力遍历 
    for i, grid in pairs(grids) do
        self:UpdateGridCd(grid)
    end
end

function XUiGuildWarTeamAreaCharacterSelectAssistant:UpdateGridCd(grid)
    local characterId = grid.AssistantData.FightNpcData.Character.Id
    local teamIndex = self._Build:GetMemberTeamIndex(characterId) or false
    local team = teamIndex and self._Build:GetXTeam(teamIndex) or false
    local member = team and team:GetMemberByEntityId(characterId) or false
    if member and member:GetEntityId() == characterId and not (member:GetPlayerId() == XPlayer.Id) then
        local teamLock = teamIndex and (not (team:GetTeamIsCustom())) or false
        grid:UpdateCdAndInTeam(teamIndex, teamLock)
    else
        grid:UpdateCdAndInTeam(false)
    end
end

return XUiGuildWarTeamAreaCharacterSelectAssistant
