local XUiGridStrongholdCharacter = require("XUi/XUiStronghold/XUiGridStrongholdCharacter")

local handler = handler
local CsXUiHelper = CsXUiHelper
local CsXTextManagerGetText = CsXTextManagerGetText
local IsNumberValid = XTool.IsNumberValid
local IsTableEmpty = XTool.IsTableEmpty

local XUiPanelStrongholdRoomCharacterSelfV2P6 = XClass(XUiNode, "XUiPanelStrongholdRoomCharacterSelfV2P6")

function XUiPanelStrongholdRoomCharacterSelfV2P6:OnStart(selectCharacterCb, closeUiFunc, playAnimationCb)
    self.SelectCharacterCb = selectCharacterCb
    self.CloseUiFunc = closeUiFunc
    self.PlayAnimationCb = playAnimationCb

    self.IsUpdateTeamPrefab = false --是否来自预设的更新队伍
    self.DialogTipCount = 0 --打开弹窗的数量，确定时不减少
    self.IsHasOpenDialogTip = false --是否有打开过弹窗

    ---@type XCharacterAgency
    self.CharacterAgency = XMVCA:GetAgency(ModuleId.XCharacter)

    self:AutoAddListener()

    self.GridCharacter.gameObject:SetActiveEx(false)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:Show(teamList, teamId, memberIndex, groupId, isSelectIsomer, pos)
    self.TeamList = teamList
    self.TeamId = teamId
    self.MemberIndex = memberIndex
    self.GroupId = groupId
    self.IsSelectIsomer = isSelectIsomer
    self.Pos = pos

    self.PlayAnimationCb("ShuaXin")
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:RefreshRoleDetail()
    local characterId = self.Parent.CharacterId
    ---@type XCharacterViewModel
    local viewModel = self:GetCharacterViewModelByEntityId(characterId)
    self.PanelContent.gameObject:SetActiveEx(viewModel ~= nil)
    if viewModel == nil then return end
    local viewModelId = viewModel:GetSourceEntityId()

    -- 机体名
    self.TxtName.text = viewModel:GetName()
    self.TxtNameOther.text = viewModel:GetTradeName()

    self.TxtAbility.text = self:GetRoleAbility(characterId)

    -- 职业
    self.BtnType:SetRawImage(viewModel:GetProfessionIcon())

    -- 初始品质
    local initQuality = self.CharacterAgency:GetCharacterInitialQuality(viewModelId)
    local initColor = self.CharacterAgency:GetModelCharacterQualityIcon(initQuality).InitColor
    self.QualityRail.color = XUiHelper.Hexcolor2Color(initColor)

    -- 元素
    local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(XRobotManager.GetCharacterId(self.Parent.CharacterId))
    local elementList = detailConfig.ObtainElementList
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
    local generalSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(XRobotManager.GetCharacterId(self.Parent.CharacterId))
    for i = 1, self.ListGeneralSkillDetail.childCount, 1 do
        local id = generalSkillIds[i]
        self["BtnGeneralSkill"..i].gameObject:SetActiveEx(id)
        if id then
            local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
            self["BtnGeneralSkill"..i]:SetRawImage(generalSkillConfig.Icon)
        end
    end
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:GetCharacterViewModelByEntityId(id)
    if id > 0 then
        local entity = nil
        if XEntityHelper.GetIsRobot(id) then
            entity = XRobotManager.GetRobotById(id)
        else
            entity = XMVCA.XCharacter:GetCharacter(id)
        end
        if entity == nil then
            XLog.Error(string.format("找不到id%s的角色", id))
            return
        end
        return entity:GetCharacterViewModel()
    end
    return nil
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:GetRoleAbility(entityId)
    local viewModel = self:GetCharacterViewModelByEntityId(entityId)
    if not viewModel then
        ---@type XCharacterAgency
        local ag = XMVCA:GetAgency(ModuleId.XCharacter)
        return ag:GetCharacterHaveRobotAbilityById(entityId)
    end
    return viewModel:GetAbility()
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:GetTeamDynamicCharacterTypes()
    local result = {}
    local team = self:GetTeam()
    local members = team:GetAllMembers()

    for pos, member in pairs(members) do
        if not member then goto Continue end
        local charId = member:GetCharacterId() > 0 and member:GetCharacterId() or member:GetRobotId()
        if charId <= 0 then
            goto Continue
        end
        if pos ~= self.Pos and self.Parent.CharacterId ~= charId then
            local type = member:GetCharacterType()
            if type then
                table.insert(result, type)
            end
        end
        ::Continue::
    end
    local oldTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(self.Parent.CharacterId, self.TeamList)
    local isInCurTeam = oldTeamId == self.TeamId

    if not isInCurTeam then
        local type = self:GetSelectCharacterType()
        if self.Parent.CharacterId then
            local template = XMVCA.XCharacter:GetCharacterTemplate(self.Parent.CharacterId)
            type = template.Type
        end
        table.insert(result, type)
    else
        local member = team:GetMember(self.Pos)
        local charId = member:GetCharacterId() > 0 and member:GetCharacterId() or member:GetRobotId()
        local isInTeam = XDataCenter.StrongholdManager.GetCharacterInTeamId(charId, self.TeamList) == self.TeamId
        if charId > 0 and isInTeam and charId ~= self.Parent.CharacterId then
            table.insert(result, member:GetCharacterType())
        end
    end

    return result
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:IsLoading()
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:Refresh()
    self:RefreshOperationBtns()
    self:RefreshRoleDetail()
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:RefreshOperationBtns()
    local characterId = self.Parent.CharacterId
    local teamList = self.TeamList
    local oldTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList)
    local isInCurTeam = oldTeamId == self.TeamId
    self.BtnJoinTeam.gameObject:SetActiveEx(not isInCurTeam)
    self.BtnQuitTeam.gameObject:SetActiveEx(isInCurTeam)
    
    local isRobot = XRobotManager.CheckIsRobotId(characterId)
    local useFashion = true
    if isRobot then
        useFashion = XRobotManager.CheckUseFashion(characterId)
    end
    self.BtnPartner:SetDisable(isRobot, not isRobot)
    self.BtnFashion:SetDisable(not useFashion, useFashion)
    self.BtnConsciousness:SetDisable(isRobot, not isRobot)
    self.BtnWeapon:SetDisable(isRobot, not isRobot)
    local isSomer = self.CharacterAgency:GetIsIsomer(characterId)
    self.BtnUniframeTip.gameObject:SetActiveEx(isSomer)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:AutoAddListener()
    CsXUiHelper.RegisterClickEvent(self.BtnJoinTeam, handler(self, self.OnClickBtnJoinTeam))
    CsXUiHelper.RegisterClickEvent(self.BtnQuitTeam, handler(self, self.OnBtnQuitTeamClick))
    self.BtnPartner.CallBack = function() self:OnClickBtnPartner() end
    self.BtnFashion.CallBack = function() self:OnClickBtnFashion() end
    self.BtnConsciousness.CallBack = function() self:OnBtnConsciousnessClick() end
    self.BtnWeapon.CallBack = function() self:OnBtnWeaponClick() end
    XUiHelper.RegisterClickEvent(self, self.BtnType, self.OnBtnCareerTipsClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUniframeTip, self.OnBtnUniframeTipClick)
    XUiHelper.RegisterClickEvent(self, self.BtnElementDetail, self.OnBtnElementDetailClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill1, function ()
        self:OnBtnGeneralSkillClick(1)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill2, function ()
        self:OnBtnGeneralSkillClick(2)
    end)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.Parent.CharacterId)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:OnBtnElementDetailClicked()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.Parent.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:OnBtnGeneralSkillClick(index)
    local generalSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(self.Parent.CharacterId)
    local curId = generalSkillIds[index]
    if not curId then
        return
    end

    XLuaUiManager.Open("UiCharacterAttributeDetail", self.Parent.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill, index)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:OnBtnUniframeTipClick()
    XLuaUiManager.Open("UiCharacterUniframeBubbleV2P6")
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:OnClickBtnPartner()
    if self:IsRobot() then
        XUiManager.TipText("StrongholdRobotRefusePartner")
        return
    end
    XDataCenter.PartnerManager.GoPartnerCarry(self.Parent.CharacterId, false)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:OnBtnConsciousnessClick()
    if self:IsRobot() then
        XUiManager.TipText("StrongholdRobotRefuseAwareness")
        return
    end
    XMVCA.XEquip:OpenUiEquipAwareness(self.Parent.CharacterId)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:OnBtnWeaponClick()
    if self:IsRobot() then
        XUiManager.TipText("StrongholdRobotRefuseWeapon")
        return
    end
    XMVCA.XEquip:OpenUiEquipReplace(self.Parent.CharacterId, nil, true)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:OnClickBtnFashion()
    if self:IsRobot() then
        local characterId = XRobotManager.GetCharacterId(self.Parent.CharacterId)
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(characterId)
        if not isOwn then
            XUiManager.TipText("CharacterLock")
            return
        else
            XLuaUiManager.Open("UiFashion", characterId, nil, nil, XUiConfigs.OpenUiType.RobotFashion)
        end
    else
        XLuaUiManager.Open("UiFashion", self.Parent.CharacterId)
    end
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:OnClickBtnJoinTeam(btnSelfObj, prefabCharId, prefabMemberIndex)
    local groupId = self.GroupId
    local teamList = self.TeamList
    local teamId = self.TeamId

    local characterId = prefabCharId or self.Parent.CharacterId
    local team = self:GetTeam()
    local member = self:GetMember(prefabMemberIndex)
    local playerId = XPlayer.Id

    if not self:CheckCanJoin(characterId, teamList, groupId, prefabMemberIndex) then
        return
    end

    local swapFunc = function()
        local oldCharacterId = member:GetInTeamCharacterId()
        local oldPlayerId = member:GetPlayerId()
        local oldTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList)
        if IsNumberValid(oldTeamId) then
            --swap team
            local oldTeam = teamList[oldTeamId]
            local oldMember = oldTeam:GetInTeamMemberByCharacterId(characterId)
            local oldCharacterType = self:GetCharacterType(oldCharacterId)
            if oldTeam:ExistDifferentCharacterType(oldCharacterType) then
                oldTeam:Clear()
            end

            oldMember:SetInTeam(oldCharacterId, oldPlayerId)
        end

        local characterType = self:GetCharacterType(characterId)
        if team:ExistDifferentCharacterType(characterType) then
            --队伍中已经存在其他类型的角色（构造体/授格者）时，清空队伍
            team:Clear()
        end

        member:SetInTeam(characterId, playerId)

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

            XUiManager.DialogTip(
                nil,
                content,
                XUiManager.DialogType.Normal,
                handler(self, self.DialogCloseCallback),
                swapFunc
            )
        else
            swapFunc()
        end
    end
    
    local onJoinTeam = function()
        local isInTeam = XDataCenter.StrongholdManager.CheckInTeamList(characterId, teamList, nil, teamId)
        if isInTeam then
            --在别的队伍中，可以交换
            local inTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList)
            local title = CsXTextManagerGetText("StrongholdDeployTipTitle")
            local showCharacterId = XRobotManager.GetCharacterId(characterId)
            local characterName = XMVCA.XCharacter:GetCharacterName(showCharacterId)
            local content = CsXTextManagerGetText("StrongholdDeployTipContent", characterName, inTeamId, teamId)
            self:AddDialogTipCount()

            XUiManager.DialogTip(
                    title,
                    content,
                    XUiManager.DialogType.Normal,
                    handler(self, self.DialogCloseCallback),
                    setTeamFunc
            )
        else
            --不在在别的队伍中，直接上阵
            setTeamFunc()
        end
        
    end
    
    XDataCenter.PracticeManager.OnJoinTeam(characterId, function()
        XDataCenter.PracticeManager.OpenUiFubenPractice(characterId, true)
    end, onJoinTeam)
end

--能否编入队伍
function XUiPanelStrongholdRoomCharacterSelfV2P6:CheckCanJoin(characterId, teamList, groupId, prefabMemberIndex)
    --电能支援
    local isElectric = XDataCenter.StrongholdManager.CheckInElectricTeam(characterId)
    if isElectric then
        XUiManager.TipText("StrongholdElectricDeployInElectricTeam")
        return false
    end

    --队伍是否已上阵相同型号角色
    local sameCharacter = XDataCenter.StrongholdManager.CheckTeamListExistSameCharacter(characterId, teamList)
    if sameCharacter then
        local key =
        prefabMemberIndex and "StrongholdElectricDeployUsePrefabSameCharacter" or
                "StrongholdElectricDeploySameCharacter"
        XUiManager.TipText(key)
        return false
    end

    --在有关卡进度的队伍中
    local isInTeamLock = XDataCenter.StrongholdManager.CheckInTeamListLock(groupId, characterId, teamList)
    if isInTeamLock then
        XUiManager.TipText("StrongholdElectricDeployInTeamLock")
        return false
    end
    return true
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:OnBtnQuitTeamClick()
    local teamList = self.TeamList
    local teamId = self.TeamId
    local characterId = self.Parent.CharacterId
    local inTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList)
    if teamId ~= inTeamId then
        return
    end

    local team = self:GetTeam()
    local member = team:GetInTeamMemberByCharacterId(characterId)
    member:KickOutTeam()

    self.CloseUiFunc()
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:GetTeam()
    return self.TeamList[self.TeamId]
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:GetMember(prefabMemberIndex)
    local team = self:GetTeam()
    local memberIndex = prefabMemberIndex or self.MemberIndex
    return team:GetMember(memberIndex)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:GetSelectCharacterType()
    return self.IsSelectIsomer and XEnumConst.CHARACTER.CharacterType.Isomer or XEnumConst.CHARACTER.CharacterType.Normal
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:GetCharacterType(characterId)
    characterId = characterId or self.Parent.CharacterId
    if not IsNumberValid(characterId) then
        return
    end

    local showCharacterId = XRobotManager.GetCharacterId(characterId)
    return XMVCA.XCharacter:GetCharacterType(showCharacterId)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:IsPrefab()
    return not IsNumberValid(self.GroupId)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:IsRobot()
    return XRobotManager.CheckIsRobotId(self.Parent.CharacterId)
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:GetCharacterIndex()
    local selectCharacterId = self.Parent.CharacterId
    if not IsNumberValid(selectCharacterId) then
        return -1
    end

    local characterIds = self.CharacterIds
    if IsTableEmpty(characterIds) then
        return -1
    end

    for index, characterId in ipairs(characterIds) do
        if selectCharacterId == characterId then
            return index
        end
    end

    return -1
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:CheckInCharacterIds(characterId)
    if not IsNumberValid(characterId) then
        return false
    end

    local characterIds = self.CharacterIds
    if IsTableEmpty(characterIds) then
        return false
    end

    for _, inCharacterId in pairs(characterIds) do
        if characterId == inCharacterId then
            return true
        end
    end

    return false
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:UpdateTeamPrefab(team)
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

                XUiManager.DialogTip(
                    nil,
                    content,
                    XUiManager.DialogType.Normal,
                    handler(self, self.DialogCloseCallback),
                    sureCallback
                )
                return
            end
            updateTeam(teamData, firstFightPos, captainPos)
            return
        end
    end
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:AddDialogTipCount()
    self.IsHasOpenDialogTips = true
    self.DialogTipCount = self.DialogTipCount + 1
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:DeleteDialogTipCount()
    self.DialogTipCount = self.DialogTipCount - 1
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:CheckIsCloseView()
    if not self.IsUpdateTeamPrefab then
        return
    end

    if not XLuaUiManager.IsUiShow("UiDialog") and XTool.IsNumberValid(self.DialogTipCount) and self.IsHasOpenDialogTips then
        if XLuaUiManager.IsUiShow("UiRoomTeamPrefab") then
            XLuaUiManager.Close("UiRoomTeamPrefab")
        end
    end
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:DialogCloseCallback()
    self:DeleteDialogTipCount()
    self:CheckIsCloseView()
end

function XUiPanelStrongholdRoomCharacterSelfV2P6:IsEmpty()
    return IsTableEmpty(self.CharacterIds)
end

return XUiPanelStrongholdRoomCharacterSelfV2P6