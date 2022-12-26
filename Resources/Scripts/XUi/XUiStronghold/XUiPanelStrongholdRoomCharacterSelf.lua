local XUiGridStrongholdCharacter = require("XUi/XUiStronghold/XUiGridStrongholdCharacter")

local handler = handler
local CsXUiHelper = CsXUiHelper
local CsXTextManagerGetText = CsXTextManagerGetText
local IsNumberValid = XTool.IsNumberValid
local IsTableEmpty = XTool.IsTableEmpty
local tableRemove = table.remove
local tableInsert = table.insert

local XUiPanelStrongholdRoomCharacterSelf = XClass(nil, "XUiPanelStrongholdRoomCharacterSelf")

function XUiPanelStrongholdRoomCharacterSelf:Ctor(ui, selectCharacterCb, closeUiFunc, playAnimationCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.SelectCharacterCb = selectCharacterCb
    self.CloseUiFunc = closeUiFunc
    self.PlayAnimationCb = playAnimationCb

    XTool.InitUiObject(self)

    self.IsUpdateTeamPrefab = false     --是否来自预设的更新队伍
    self.DialogTipCount = 0             --打开弹窗的数量，确定时不减少
    self.IsHasOpenDialogTip = false     --是否有打开过弹窗

    self:InitDynamicTable()
    self:AutoAddListener()

    self.GridCharacter.gameObject:SetActiveEx(false)
end

function XUiPanelStrongholdRoomCharacterSelf:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGridStrongholdCharacter)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelStrongholdRoomCharacterSelf:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelStrongholdRoomCharacterSelf:Show(teamList, teamId, memberIndex, groupId, isSelectIsomer)
    self.TeamList = teamList
    self.TeamId = teamId
    self.MemberIndex = memberIndex
    self.GroupId = groupId
    self.IsSelectIsomer = isSelectIsomer


    if self:IsPrefab() then
        self.TxtEchelonName.text = CsXTextManagerGetText("StrongholdTeamTitle", teamId)

        self.PanelTxt.gameObject:SetActiveEx(false)
    else
        local stageIndex = self.TeamId
        self.TxtEchelonName.text = XDataCenter.StrongholdManager.GetGroupStageName(groupId, stageIndex)

        local requireAbility = XDataCenter.StrongholdManager.GetGroupRequireAbility(groupId)
        self.TxtRequireAbility.text = requireAbility

        self.PanelTxt.gameObject:SetActiveEx(true)

        self:RefreshCharacterTypeTips()
    end

    self:UpdateCharacters()

    self.GameObject:SetActiveEx(true)
end

function XUiPanelStrongholdRoomCharacterSelf:RefreshCharacterTypeTips()
    if self:IsPrefab() then return end

    local groupId = self.GroupId
    local stageIndex = self.TeamId
    local stageId = XDataCenter.StrongholdManager.GetGroupStageId(groupId, stageIndex)
    local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(stageId)

    if not XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType) then
        self.PanelRequireCharacter.gameObject:SetActiveEx(false)
        return
    end

    local icon = XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
    self.ImgRequireCharacter:SetSprite(icon)

    local limitBuffId = nil
    local characterType = self:GetSelectCharacterType()
    local text = XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, limitBuffId)
    self.TxtRequireCharacter.text = text

    self.PanelRequireCharacter.gameObject:SetActiveEx(true)
end

function XUiPanelStrongholdRoomCharacterSelf:UpdateCharacters()
    local teamList = self.TeamList
    local groupId = self.GroupId
    local stageIndex = self.TeamId
    local characterType = self:GetSelectCharacterType()
    self.CharacterIds = XDataCenter.StrongholdManager.GetCanUseCharacterOrRobotIds(groupId, stageIndex, characterType, teamList)

    if not self:CheckInCharacterIds(self.CharacterId) then
        self.CharacterId = self.CharacterIds[1]
    end

    --将选中角色提到第一位
    local find = false
    local selectCharacterId = self.CharacterId
    for index, inCharacterId in pairs(self.CharacterIds) do
        if inCharacterId == selectCharacterId then
            tableRemove(self.CharacterIds, index)
            find = true
            break
        end
    end
    if find then
        tableInsert(self.CharacterIds, 1, selectCharacterId)
    end

    local index = self:GetCharacterIndex()
    self.DynamicTable:SetDataSource(self.CharacterIds)
    self.DynamicTable:ReloadDataASync(index)

    local isEmpty = IsTableEmpty(self.CharacterIds)
    self.PanelEmptyList.gameObject:SetActiveEx(isEmpty)

    self.PlayAnimationCb("ShuaXin")
end

function XUiPanelStrongholdRoomCharacterSelf:IsLoading()
    return self.DynamicTable and self.DynamicTable:IsAsyncLoading()
end

function XUiPanelStrongholdRoomCharacterSelf:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local characterId = self.CharacterIds[index]
        local groupId = self.GroupId
        grid:Refresh(characterId, groupId, self.TeamId, self.TeamList)

        local isSelected = characterId == self.CharacterId
        grid:SetSelect(isSelected)
        if isSelected then
            self.LastSelectGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local characterId = self.CharacterIds[index]

        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelect(false)
        end
        self.LastSelectGrid = grid
        self.LastSelectGrid:SetSelect(true)

        self:SelectCharacter(characterId)
    end
end

function XUiPanelStrongholdRoomCharacterSelf:SelectCharacter(characterId)
    if not self:CheckInCharacterIds(characterId) then
        characterId = self.CharacterIds[1]
    end
    self.CharacterId = characterId

    local teamList = self.TeamList
    local oldTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList)
    local isInCurTeam = oldTeamId == self.TeamId
    self.BtnJoinTeam.gameObject:SetActiveEx(not isInCurTeam)
    self.BtnQuitTeam.gameObject:SetActiveEx(isInCurTeam)

    self.SelectCharacterCb(characterId)
end

function XUiPanelStrongholdRoomCharacterSelf:AutoAddListener()
    CsXUiHelper.RegisterClickEvent(self.BtnPartner, handler(self, self.OnClickBtnPartner))
    CsXUiHelper.RegisterClickEvent(self.BtnFashion, handler(self, self.OnClickBtnFashion))
    CsXUiHelper.RegisterClickEvent(self.BtnConsciousness, handler(self, self.OnBtnConsciousnessClick))
    CsXUiHelper.RegisterClickEvent(self.BtnWeapon, handler(self, self.OnBtnWeaponClick))
    CsXUiHelper.RegisterClickEvent(self.BtnJoinTeam, handler(self, self.OnClickBtnJoinTeam))
    CsXUiHelper.RegisterClickEvent(self.BtnQuitTeam, handler(self, self.OnBtnQuitTeamClick))
    CsXUiHelper.RegisterClickEvent(self.BtnTeamPrefab, handler(self, self.OnBtnTeamPrefabClick))
end

function XUiPanelStrongholdRoomCharacterSelf:OnClickBtnPartner()
    if self:IsRobot() then
        XUiManager.TipText("StrongholdRobotRefusePartner")
        return
    end
    XDataCenter.PartnerManager.GoPartnerCarry(self.CharacterId, false)
end

function XUiPanelStrongholdRoomCharacterSelf:OnBtnConsciousnessClick()
    if self:IsRobot() then
        XUiManager.TipText("StrongholdRobotRefuseAwareness")
        return
    end
    XLuaUiManager.Open("UiEquipAwarenessReplace", self.CharacterId, nil, true)
end

function XUiPanelStrongholdRoomCharacterSelf:OnBtnWeaponClick()
    if self:IsRobot() then
        XUiManager.TipText("StrongholdRobotRefuseWeapon")
        return
    end
    XLuaUiManager.Open("UiEquipReplaceNew", self.CharacterId, nil, true)
end

function XUiPanelStrongholdRoomCharacterSelf:OnClickBtnFashion()
    if self:IsRobot() then
        XUiManager.TipText("StrongholdRobotRefuseFashion")
        return
    end
    XLuaUiManager.Open("UiFashion", self.CharacterId)
end

function XUiPanelStrongholdRoomCharacterSelf:OnClickBtnJoinTeam(btnSelfObj, prefabCharId, prefabMemberIndex)
    local groupId = self.GroupId
    local teamList = self.TeamList
    local teamId = self.TeamId

    local characterId = prefabCharId or self.CharacterId
    local team = self:GetTeam()
    local member = self:GetMember(prefabMemberIndex)

    --电能支援
    local isElectric = XDataCenter.StrongholdManager.CheckInElectricTeam(characterId)
    if isElectric then
        XUiManager.TipText("StrongholdElectricDeployInElectricTeam")
        return
    end

    --队伍是否已上阵相同型号角色
    local sameCharacter = XDataCenter.StrongholdManager.CheckTeamListExistSameCharacter(characterId, teamList)
    if sameCharacter then
        local key = prefabMemberIndex and "StrongholdElectricDeployUsePrefabSameCharacter" or "StrongholdElectricDeploySameCharacter"
        XUiManager.TipText(key)
        return
    end

    --在有关卡进度的队伍中
    local isInTeamLock = XDataCenter.StrongholdManager.CheckInTeamListLock(groupId, characterId, teamList)
    if isInTeamLock then
        XUiManager.TipText("StrongholdElectricDeployInTeamLock")
        return
    end

    local swapFunc = function()
        local oldCharacterId = member:GetInTeamCharacterId()
        local oldTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList)
        if IsNumberValid(oldTeamId) then
            --switch team
            local oldTeam = teamList[oldTeamId]
            local oldMember = oldTeam:GetInTeamMemberByCharacterId(characterId)

            local oldCharacterType = self:GetCharacterType(oldCharacterId)
            if oldTeam:ExistDifferentCharacterType(oldCharacterType) then
                oldTeam:Clear()
            end

            oldMember:SetInTeam(oldCharacterId)
        end

        local characterType = self:GetCharacterType(characterId)
        if team:ExistDifferentCharacterType(characterType) then
            --队伍中已经存在其他类型的角色（构造体/授格者）时，清空队伍
            team:Clear()
        end

        member:SetInTeam(characterId)
        
        if self.IsUpdateTeamPrefab then
            self:CheckIsCloseView()
        else
            self.CloseUiFunc()
        end
    end

    local setTeamFunc = function()
        local characterType = self:GetCharacterType(characterId)
        if team:ExistDifferentCharacterType(characterType) then
            --队伍中已经存在其他类型的角色（构造体/授格者）
            local content = CSXTextManagerGetText("TeamCharacterTypeNotSame")
            self:AddDialogTipCount()

            XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, handler(self, self.DialogCloseCallback), swapFunc)
        else
            swapFunc()
        end
    end

    local isInTeam = XDataCenter.StrongholdManager.CheckInTeamList(characterId, teamList, nil, teamId)
    if isInTeam then
        --在别的队伍中，可以交换
        local inTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList)
        local title = CsXTextManagerGetText("StrongholdDeployTipTitle")
        local showCharacterId = XRobotManager.GetCharacterId(characterId)
        local characterName = XCharacterConfigs.GetCharacterName(showCharacterId)
        local content = CsXTextManagerGetText("StrongholdDeployTipContent", characterName, inTeamId, teamId)
        self:AddDialogTipCount()

        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, handler(self, self.DialogCloseCallback), setTeamFunc)
    else
        --不在在别的队伍中，直接上阵
        setTeamFunc()
    end
end

function XUiPanelStrongholdRoomCharacterSelf:OnBtnQuitTeamClick()
    local teamList = self.TeamList
    local teamId = self.TeamId
    local characterId = self.CharacterId
    local inTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList)
    if teamId ~= inTeamId then return end

    local team = self:GetTeam()
    local member = team:GetInTeamMemberByCharacterId(characterId)
    member:KickOutTeam()

    self.CloseUiFunc()
end

function XUiPanelStrongholdRoomCharacterSelf:OnBtnTeamPrefabClick()
    local groupId = self.GroupId
    local stageIndex = self.TeamId
    local stageId = not self:IsPrefab() and XDataCenter.StrongholdManager.GetGroupStageId(groupId, stageIndex)
    local characterLimitType = IsNumberValid(stageId) and XFubenConfigs.GetStageCharacterLimitType(stageId)
    local limitBuffId = IsNumberValid(stageId) and XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
    local stageType = IsNumberValid(stageId) and XFubenConfigs.GetStageType(stageId)
    local closeCb = function()
        if self.IsUpdateTeamPrefab and (XTool.IsNumberValid(self.DialogTipCount) or not self.IsHasOpenDialogTips) then
            self.CloseUiFunc()
        end
        self.IsUpdateTeamPrefab = false
        self.DialogTipCount = 0
    end
    XLuaUiManager.Open("UiRoomTeamPrefab", nil, nil, characterLimitType, limitBuffId, stageType, nil, closeCb)
end

function XUiPanelStrongholdRoomCharacterSelf:GetTeam()
    return self.TeamList[self.TeamId]
end

function XUiPanelStrongholdRoomCharacterSelf:GetMember(prefabMemberIndex)
    local team = self:GetTeam()
    local memberIndex = prefabMemberIndex or self.MemberIndex
    return team:GetMember(memberIndex)
end

function XUiPanelStrongholdRoomCharacterSelf:GetSelectCharacterType()
    return self.IsSelectIsomer and XCharacterConfigs.CharacterType.Isomer or XCharacterConfigs.CharacterType.Normal
end

function XUiPanelStrongholdRoomCharacterSelf:GetCharacterType(characterId)
    characterId = characterId or self.CharacterId
    if not IsNumberValid(characterId) then return end

    local showCharacterId = XRobotManager.GetCharacterId(characterId)
    return XCharacterConfigs.GetCharacterType(showCharacterId)
end

function XUiPanelStrongholdRoomCharacterSelf:IsPrefab()
    return not IsNumberValid(self.GroupId)
end

function XUiPanelStrongholdRoomCharacterSelf:IsRobot()
    return XRobotManager.CheckIsRobotId(self.CharacterId)
end

function XUiPanelStrongholdRoomCharacterSelf:GetCharacterIndex()
    local selectCharacterId = self.CharacterId
    if not IsNumberValid(selectCharacterId) then return -1 end

    local characterIds = self.CharacterIds
    if IsTableEmpty(characterIds) then return -1 end

    for index, characterId in ipairs(characterIds) do
        if selectCharacterId == characterId then
            return index
        end
    end

    return -1
end

function XUiPanelStrongholdRoomCharacterSelf:CheckInCharacterIds(characterId)
    if not IsNumberValid(characterId) then return false end

    local characterIds = self.CharacterIds
    if IsTableEmpty(characterIds) then return false end

    for _, inCharacterId in pairs(characterIds) do
        if characterId == inCharacterId then
            return true
        end
    end

    return false
end

function XUiPanelStrongholdRoomCharacterSelf:UpdateTeamPrefab(team)
    self.IsUpdateTeamPrefab = true
    self.IsCloseRoomTeamPrefab = true

    local teamData = team and team.TeamData
    local firstFightPos = team and team.FirstFightPos
    local captainPos = team and team.CaptainPos

    local updateTeam = function(teamData, firstFightPos, captainPos)
        for index, characterId in ipairs(teamData or {}) do
            self:OnClickBtnJoinTeam(nil, characterId, index)
        end

        local team = self:GetTeam()
        team:SetCaptainPos(captainPos)
        team:SetFirstPos(firstFightPos)
    end

    for _, characterId in ipairs(teamData or {}) do
        if characterId > 0 then
            local characterType = self:GetCharacterType(characterId)
            local team = self:GetTeam()
            if team:ExistDifferentCharacterType(characterType) then
                local content = CSXTextManagerGetText("TeamCharacterTypeNotSame")
                local sureCallback = function()
                    team:Clear()
                    updateTeam(teamData, firstFightPos, captainPos)
                end
                self:AddDialogTipCount()

                XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, handler(self, self.DialogCloseCallback), sureCallback)
                return
            end
            updateTeam(teamData, firstFightPos, captainPos)
            return
        end
    end
end

function XUiPanelStrongholdRoomCharacterSelf:AddDialogTipCount()
    self.IsHasOpenDialogTips = true
    self.DialogTipCount = self.DialogTipCount + 1
end

function XUiPanelStrongholdRoomCharacterSelf:DeleteDialogTipCount()
    self.DialogTipCount = self.DialogTipCount - 1
end

function XUiPanelStrongholdRoomCharacterSelf:CheckIsCloseView()
    if not self.IsUpdateTeamPrefab then
        return
    end
    
    if not XLuaUiManager.IsUiShow("UiDialog") and XTool.IsNumberValid(self.DialogTipCount) and self.IsHasOpenDialogTips then
        if XLuaUiManager.IsUiShow("UiRoomTeamPrefab") then
            XLuaUiManager.Close("UiRoomTeamPrefab")
        end
    end
end

function XUiPanelStrongholdRoomCharacterSelf:DialogCloseCallback()
    self:DeleteDialogTipCount()
    self:CheckIsCloseView()
end

return XUiPanelStrongholdRoomCharacterSelf