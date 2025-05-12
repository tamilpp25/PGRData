local XUiExpeditionEquipGrid = require("XUi/XUiExpedition/RoleList/XUiExpeditionEquipGrid/XUiExpeditionEquipGrid")
local XUiGridEquipOther = require("XUi/XUiPlayerInfo/XUiGridEquipOther")
local XEquip = require("XEntity/XEquip/XEquip")

local handler = handler
local CsXUiHelper = CsXUiHelper
local CsXTextManagerGetText = CsXTextManagerGetText
local IsNumberValid = XTool.IsNumberValid
local IsTableEmpty = XTool.IsTableEmpty

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.red,
    [false] = XUiHelper.Hexcolor2Color("0E70BDFF"),
}

local XUiPanelStrongholdRoomCharacterOthersV2P6 = XClass(XUiNode, "XUiPanelStrongholdRoomCharacterOthersV2P6")

function XUiPanelStrongholdRoomCharacterOthersV2P6:OnStart(selectCharacterCb, closeUiFunc, playAnimationCb, rootUi)
    self.SelectCharacterCb = selectCharacterCb
    self.CloseUiFunc = closeUiFunc
    self.PlayAnimationCb = playAnimationCb
    self.RootUi = rootUi
    self.WearingAwarenessGrids = {}

    self.PanelEquip = self.GameObject:FindTransform("TeamBtn2")

    self:AutoAddListener()

    self.GridCharacter.gameObject:SetActiveEx(false)
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:Show(teamList, teamId, memberIndex, groupId)
    if self.Parent.PanelFilter:IsCurListEmpty() then
        return
    end

    self.TeamList = teamList
    self.TeamId = teamId
    self.MemberIndex = memberIndex
    self.GroupId = groupId

    self:UpdateUseTimes()
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:UpdateUseTimes()
    local times = XDataCenter.StrongholdManager.GetBorrowCount()
    local maxTimes = XStrongholdConfigs.GetBorrowMaxTimes()

    local isOverTimes = times >= maxTimes
    if not isOverTimes then
        local itemId, count = XStrongholdConfigs.GetBorrowCostItemInfo(times)
        local icon = XItemConfigs.GetItemIconById(itemId)
        self.RImgIcon:SetRawImage(icon)
        self.TxtNumber.text = count
        self.TxtNumber.gameObject:SetActiveEx(true)
    else
        self.TxtNumber.gameObject:SetActiveEx(false)
    end

    self.TxtTimes.text = times .. "/" .. maxTimes
    self.TxtTimes.color = CONDITION_COLOR[isOverTimes]
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:IsLoading()
    return self.DynamicTable and self.DynamicTable:IsAsyncLoading()
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:Refresh()
    if self.Parent.PanelFilter:IsCurListEmpty() then
        return
    end

    local playerId = self.Parent.CharacterId
    self.PlayerId = playerId

    local characterId = XDataCenter.StrongholdManager.GetAssistantPlayerCharacterId(playerId)
    local teamList = self.TeamList
    local oldTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList, playerId)
    local isInCurTeam = oldTeamId == self.TeamId

    local times = XDataCenter.StrongholdManager.GetBorrowCount()
    local maxTimes = XStrongholdConfigs.GetBorrowMaxTimes()
    local isOverTimes = times >= maxTimes
    self.BtnJoinTeam.gameObject:SetActiveEx(not isInCurTeam and not isOverTimes)
    self.BtnJoinDisable.gameObject:SetActiveEx(not isInCurTeam and isOverTimes)
    self.BtnQuitTeam.gameObject:SetActiveEx(isInCurTeam)

    self:UpdateEquips()
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:UpdateEquips()
    if self.Parent.PanelFilter:IsCurListEmpty() then
        self.PanelEquip.gameObject:SetActiveEx(false)
        return
    end
    self.PanelEquip.gameObject:SetActiveEx(true)

    local isCheckEquipPosResonanced = false
    local playerId = self.PlayerId
    local assistantInfo = XDataCenter.StrongholdManager.GetAssistantInfo(playerId)
    local equips = assistantInfo.Equips

    local weapon = {}
    local equipSiteDic = {}
    local weaponResonanceCount = 0
    for _, equip in pairs(equips) do
        if XMVCA.XEquip:IsEquipWeapon(equip.TemplateId) then
            weapon = equip
            weaponResonanceCount = #equip.ResonanceInfo
        else
            local site = XMVCA.XEquip:GetEquipSiteByEquip(equip)
            equipSiteDic[site] = equip
        end
    end

    self.WeaponGrid = self.WeaponGrid or XUiGridEquipOther.New(self.GridWeapon, self)
    local usingWeaponId = weapon.TemplateId
    if usingWeaponId then
        local xEquip = XEquip.New(weapon)
        self.WeaponGrid:Refresh(xEquip)
    end

    for i = 1, 6 do
        self.WearingAwarenessGrids[i] = self.WearingAwarenessGrids[i] or XUiExpeditionEquipGrid.New(CS.UnityEngine.Object.Instantiate(self.GridAwareness), nil, self.Parent)
        self.WearingAwarenessGrids[i].Transform:SetParent(self["PanelAwareness" .. i], false)

        local equip = equipSiteDic[i]
        if not equip then
            self.WearingAwarenessGrids[i].GameObject:SetActiveEx(false)
        else
            local resonanceCount = #equip.ResonanceInfo
            self.WearingAwarenessGrids[i].GameObject:SetActiveEx(true)
            local curCharacterId = XDataCenter.StrongholdManager.GetAssistantPlayerCharacterId(playerId)
            self.WearingAwarenessGrids[i]:Refresh(equip.TemplateId, equip.Breakthrough, i, false, equip.Level, resonanceCount, equip.AwakeSlotList, assistantInfo.AwarenessSetPositions, equip.ResonanceInfo, curCharacterId)
        end
    end
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:AutoAddListener()
    CsXUiHelper.RegisterClickEvent(self.BtnJoinTeam, handler(self, self.OnClickBtnJoinTeam))
    CsXUiHelper.RegisterClickEvent(self.BtnQuitTeam, handler(self, self.OnBtnQuitTeamClick))
    CsXUiHelper.RegisterClickEvent(self.BtnRefresh, handler(self, self.OnClickBtnRefresh))
    CsXUiHelper.RegisterClickEvent(self.BtnJoinDisable, handler(self, self.OnBtnJoinDisableClick))
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:OnClickBtnRefresh()
    local cb = function()
        local groupId = self.GroupId
        local teamList = self.TeamList
        XDataCenter.StrongholdManager.KickOutInvalidMembersInTeamList(teamList, groupId)
        self.Parent:ImportSupportList()
        ---@type XUiPanelCommonCharacterFilterV2P6
        local parentFilter = self.Parent.PanelFilter
        parentFilter:SetForceSeleCbTrigger()
        parentFilter:RefreshList()
    end
    XDataCenter.StrongholdManager.GetStrongholdAssistCharacterListRequest(cb)
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:OnClickBtnJoinTeam()
    local groupId = self.GroupId
    local teamList = self.TeamList
    local teamId = self.TeamId
    local playerId = self.PlayerId
    local characterId = XDataCenter.StrongholdManager.GetAssistantPlayerCharacterId(playerId)
    local team = self:GetTeam()
    local member = self:GetMember()

    if not self:CheckCanJoin(teamList, groupId, characterId, playerId, teamId) then
        return
    end

    local swapFunc = function()
        local oldTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList, playerId)
        if IsNumberValid(oldTeamId) then
            --switch team
            local oldCharacterId = member:GetInTeamCharacterId()
            local oldPlayerId = member:GetPlayerId()
            local oldTeam = teamList[oldTeamId]
            local oldMember = oldTeam:GetInTeamMemberByCharacterId(characterId, playerId)

            local oldCharacterType = self:GetCharacterType(oldCharacterId)
            if oldTeam:ExistDifferentCharacterType(oldCharacterType) then
                oldTeam:Clear()
            end

            oldMember:SetInTeam(oldCharacterId, oldPlayerId)
        end

        local characterType = self:GetCharacterType()
        if team:ExistDifferentCharacterType(characterType) then
            --队伍中已经存在其他类型的角色（构造体/授格者）时，清空队伍
            team:Clear()
        end

        member:SetInTeam(characterId, playerId)

        self.CloseUiFunc()
    end

    local setTeamFunc = function()
        local characterType = self:GetCharacterType()
        if team:ExistDifferentCharacterType(characterType) then
            --队伍中已经存在其他类型的角色（构造体/授格者）
            local content = CSXTextManagerGetText("TeamCharacterTypeNotSame")
            XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, swapFunc)
        else
            swapFunc()
        end
    end

    local callFunc = function()
        local isInTeam = XDataCenter.StrongholdManager.CheckInTeamList(characterId, teamList, playerId)
        if isInTeam then
            --在别的队伍中，可以交换
            local inTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList, playerId)
            local title = CsXTextManagerGetText("StrongholdDeployTipTitle")
            local showCharacterId = XRobotManager.GetCharacterId(characterId)
            local characterName = XMVCA.XCharacter:GetCharacterName(showCharacterId)
            local content = CsXTextManagerGetText("StrongholdDeployTipContent", characterName, inTeamId, teamId)
            XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, setTeamFunc)
        else
            --不在在别的队伍中，直接上阵
            setTeamFunc()
        end
    end
    
    local onJoinTeam = function()
        local times = XDataCenter.StrongholdManager.GetBorrowCount()
        local maxTimes = XStrongholdConfigs.GetBorrowMaxTimes()
        if times >= maxTimes then
            XUiManager.TipText("StrongholdBorrowMaxTimes")
            return
        end

        local itemId, count = XStrongholdConfigs.GetBorrowCostItemInfo(times)
        if not XDataCenter.ItemManager.CheckItemCountById(itemId, count) then
            XUiManager.TipText("StrongholdBorrowCostLack")
            return
        end

        local itemName = XItemConfigs.GetItemNameById(itemId)
        local title = CsXTextManagerGetText("StrongholdDeployAssistantTipTitle")
        local content = CsXTextManagerGetText("StrongholdDeployAssistantTipContent", itemName, count)
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
    end

    XDataCenter.PracticeManager.OnJoinTeam(characterId, function()
        XDataCenter.PracticeManager.OpenUiFubenPractice(characterId, true)
    end, onJoinTeam)
 
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:CheckCanJoin(teamList, groupId, characterId, playerId, teamId)

    --队伍已上阵支援角色
    local overCount = XDataCenter.StrongholdManager.CheckTeamListExistAssitantCharacter(teamList)
    if overCount then
        XUiManager.TipText("StrongholdBorrowCountOver")
        return false
    end

    --在有关卡进度的队伍中
    local isInTeamLock = XDataCenter.StrongholdManager.CheckInTeamListLock(groupId, characterId, teamList, playerId)
    if isInTeamLock then
        XUiManager.TipText("StrongholdElectricDeployInTeamLock")
        return false
    end

    --队伍是否已上阵相同型号角色
    local sameCharacter = XDataCenter.StrongholdManager.CheckTeamListExistSameCharacter(characterId, teamList, playerId, teamId, self.MemberIndex)
    if sameCharacter then
        XUiManager.TipText("StrongholdElectricDeploySameCharacter")
        return false
    end
    
    return true
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:OnBtnJoinDisableClick()
    XUiManager.TipText("StrongholdBorrowMaxTimes")
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:OnBtnQuitTeamClick()
    local teamList = self.TeamList
    local teamId = self.TeamId
    local playerId = self.PlayerId
    local characterId = XDataCenter.StrongholdManager.GetAssistantPlayerCharacterId(playerId)
    local inTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList, playerId)
    if teamId ~= inTeamId then return end

    local team = self:GetTeam()
    local member = team:GetInTeamMemberByCharacterId(characterId, playerId)
    member:KickOutTeam()

    self.CloseUiFunc()
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:GetTeam()
    return self.TeamList[self.TeamId]
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:GetMember()
    local team = self:GetTeam()
    return team:GetMember(self.MemberIndex)
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:GetPlayerCharacterId()
    return XDataCenter.StrongholdManager.GetAssistantPlayerCharacterId(self.PlayerId)
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:GetPlayerIndex()
    local selectPlayerId = self.PlayerId
    if not IsNumberValid(selectPlayerId) then return -1 end

    local playerIds = self.PlayerIds
    if IsTableEmpty(playerIds) then return -1 end

    for index, inPlayerId in ipairs(playerIds) do
        if selectPlayerId == inPlayerId then
            return index
        end
    end

    return -1
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:CheckInPlayerIds(playerId)
    -- if not IsNumberValid(playerId) then return false end

    -- local playerIds = self.PlayerIds
    -- if IsTableEmpty(playerIds) then return false end

    -- for _, inPlayerId in pairs(playerIds) do
    --     if playerId == inPlayerId then
    --         return true
    --     end
    -- end

    -- return false
end

function XUiPanelStrongholdRoomCharacterOthersV2P6:GetCharacterType(characterId)
    characterId = characterId or XDataCenter.StrongholdManager.GetAssistantPlayerCharacterId(self.PlayerId)
    if not IsNumberValid(characterId) then return end

    local showCharacterId = XRobotManager.GetCharacterId(characterId)
    return XMVCA.XCharacter:GetCharacterType(showCharacterId)
end

return XUiPanelStrongholdRoomCharacterOthersV2P6