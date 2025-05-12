local mathFloor = math.floor
local IsNumberValid = XTool.IsNumberValid
local CsXTextManagerGetText = CsXTextManagerGetText

local XUiGridStrongholdCharacter = XClass(nil, "XUiGridStrongholdCharacter")

function XUiGridStrongholdCharacter:Ctor(ui)
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self:SetSelect(false)
end

function XUiGridStrongholdCharacter:Refresh(characterId, groupId, teamPropId, teamList, playerId)
    self.CharacterId = characterId
    self.GroupId = groupId
    self.TeamPropId = teamPropId
    self.TeamList = teamList
    self.PlayerId = playerId
    self.TeamIndex = XTool.IsNumberValid(groupId) and XDataCenter.StrongholdManager.GetTeamIndexByProp(groupId, teamPropId) or self.TeamPropId

    self:UpdateBaseInfo()
    if XRobotManager.CheckIsRobotId(characterId) then
        self:UpdateRobot()
    elseif IsNumberValid(playerId) then
        self:UpdateAssistant()
    else
        self:UpdateCharacter()
    end
end

function XUiGridStrongholdCharacter:UpdateBaseInfo()
    -- 独域
    self.PanelUniframe.gameObject:SetActiveEx(self.CharacterAgency:GetIsIsomer(self.CharacterId))

    -- 初始品质
    self.PanelInitQuality.gameObject:SetActiveEx(true)
    local initQuality = self.CharacterAgency:GetCharacterInitialQuality(self.CharacterId)
    local icon = self.CharacterAgency:GetModelCharacterQualityIcon(initQuality).IconCharacterInit
    self.ImgInitQuality:SetSprite(icon)

    -- 相同构造体
    if self.PanelSameRole then
        local curTeam = self.TeamList[self.TeamPropId]
        local pos = curTeam:GetSameCharacterPos(self.CharacterId)
        local inTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(self.CharacterId, self.TeamList)
        local isShowSame = inTeamId ~= self.TeamIndex and XTool.IsNumberValid(pos)
        self.PanelSameRole.gameObject:SetActiveEx(isShowSame)
    end
end

function XUiGridStrongholdCharacter:UpdateRobot()
    local teamList = self.TeamList
    local groupId = self.GroupId
    local robotId = self.CharacterId
    local robotTemplate = XRobotManager.GetRobotTemplate(robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)

    local npcType = self.CharacterAgency:GetCharacterCareer(characterId)
    self.RImgCharElement1:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(npcType))


    if self.RImgHeadIcon then
        local head = self.CharacterAgency:GetCharSmallHeadIcon(characterId, true)
        self.RImgHeadIcon:SetRawImage(head)
    end

    if self.TxtLevel then
        local level = robotTemplate.CharacterLevel
        self.TxtLevel.text = level
    end

    if self.PanelFight then
        local ability = XRobotManager.GetRobotAbility(robotId)
        self.TxtFight.text = mathFloor(ability)
        self.PanelFight.gameObject:SetActiveEx(true)
    end

    if self.RImgQuality then
        local quality = XMVCA.XCharacter:GetCharacterQualityIcon(robotTemplate.CharacterQuality)
        self.RImgQuality:SetRawImage(quality)
    end

    local isInTeam = XDataCenter.StrongholdManager.CheckInTeamList(robotId, teamList)
    local isInTeamLock = XDataCenter.StrongholdManager.CheckInTeamListLock(groupId, robotId, teamList)
    if self.ImgInTeam then
        local showInTeam = not isInTeamLock and isInTeam
        if showInTeam then
            local oldTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(robotId, teamList)
            self.TxtInTeam.text = CsXTextManagerGetText("StrongholdTeamIndex", oldTeamId)
            self.ImgInTeam.gameObject:SetActiveEx(true)
        else
            self.ImgInTeam.gameObject:SetActiveEx(false)
        end
    end
    if self.PanelInTeamLock then
        self.PanelInTeamLock.gameObject:SetActiveEx(isInTeamLock)
    end

    if self.PanelTeamSupport then
        self.PanelTeamSupport.gameObject:SetActiveEx(false)
    end

    if self.PanelTry then
        self.PanelTry.gameObject:SetActiveEx(true)
    end
end

function XUiGridStrongholdCharacter:UpdateAssistant()
    local teamList = self.TeamList
    local groupId = self.GroupId
    local playerId = self.PlayerId
    local assistantInfo = XDataCenter.StrongholdManager.GetAssistantInfo(playerId)
    local character = assistantInfo.Character
    local characterId = character.Id

    local npcType = self.CharacterAgency:GetCharacterCareer(characterId)
    self.RImgCharElement1:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(npcType))

    if self.RImgHeadIcon then
        local headInfo = character.CharacterHeadInfo or {}
        local head = self.CharacterAgency:GetCharSmallHeadIcon(characterId, true, headInfo.HeadFashionId, headInfo.HeadFashionType)
        self.RImgHeadIcon:SetRawImage(head)
    end

    if self.TxtLevel then
        local level = character.Level
        self.TxtLevel.text = level
    end

    if self.PanelFight then
        local ability = character.Ability
        self.TxtFight.text = mathFloor(ability)
        self.PanelFight.gameObject:SetActiveEx(true)
    end

    if self.RImgQuality then
        self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))
    end

    local isInTeam = XDataCenter.StrongholdManager.CheckInTeamList(characterId, teamList, playerId)
    local isInTeamLock = XDataCenter.StrongholdManager.CheckInTeamListLock(groupId, characterId, teamList, playerId)
    if self.ImgInTeam then
        local showInTeam = not isInTeamLock and isInTeam
        if showInTeam then
            local oldTeamId = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList, playerId)
            self.TxtInTeam.text = CsXTextManagerGetText("StrongholdTeamIndex", oldTeamId)
            self.ImgInTeam.gameObject:SetActiveEx(true)
        else
            self.ImgInTeam.gameObject:SetActiveEx(false)
        end
    end
    if self.PanelInTeamLock then
        self.PanelInTeamLock.gameObject:SetActiveEx(isInTeamLock)
    end

    if self.PanelTeamSupport then
        self.PanelTeamSupport.gameObject:SetActiveEx(false)
    end

    if self.PanelTry then
        self.PanelTry.gameObject:SetActiveEx(false)
    end
end

function XUiGridStrongholdCharacter:UpdateCharacter()
    local teamId = self.TeamIndex
    local teamList = self.TeamList
    local groupId = self.GroupId
    local characterId = self.CharacterId
    local character = self.CharacterAgency:GetCharacter(characterId)

    self.RImgCharElement1:SetRawImage(XMVCA.XCharacter:GetNpcTypeIcon(character.Type))

    if self.RImgHeadIcon then
        self.RImgHeadIcon:SetRawImage(self.CharacterAgency:GetCharSmallHeadIcon(characterId))
    end

    if self.TxtLevel then
        self.TxtLevel.text = character.Level
    end

    if self.PanelFight then
        self.PanelFight.gameObject:SetActiveEx(true)
        local ability = self.CharacterAgency:GetCharacterAbilityById(characterId)
        self.TxtFight.text = mathFloor(ability)
    end

    if self.RImgQuality then
        self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))
    end

    local isInTeam = XDataCenter.StrongholdManager.CheckInTeamList(characterId, teamList)
    local isInTeamLock = XDataCenter.StrongholdManager.CheckInTeamListLock(groupId, characterId, teamList)
    if self.ImgInTeam then
        local showInTeam = not isInTeamLock and isInTeam
        if showInTeam then
            local oldTeamId, oldTeamPos = XDataCenter.StrongholdManager.GetCharacterInTeamId(characterId, teamList)
            local desc = CsXTextManagerGetText("StrongholdTeamIndex", oldTeamId)
            if IsNumberValid(groupId) then
                local requireTeamMemberDic = XDataCenter.StrongholdManager.GetGroupRequireTeamMemberDic(groupId)
                local memberNum = requireTeamMemberDic[teamId]
                if memberNum < oldTeamPos and oldTeamId == teamId then
                    desc = CsXTextManagerGetText("StrongholdGridInPrefab")
                end
            end
            self.TxtInTeam.text = desc
            self.ImgInTeam.gameObject:SetActiveEx(true)
        else
            self.ImgInTeam.gameObject:SetActiveEx(false)
        end
    end
    if self.PanelInTeamLock then
        self.PanelInTeamLock.gameObject:SetActiveEx(isInTeamLock)
    end

    if self.PanelTeamSupport then
        local IsElectric = XDataCenter.StrongholdManager.CheckInElectricTeam(characterId)
        self.PanelTeamSupport.gameObject:SetActiveEx(IsElectric)
    end

    if self.PanelTry then
        self.PanelTry.gameObject:SetActiveEx(false)
    end
end

function XUiGridStrongholdCharacter:SetSelect(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end
end

return XUiGridStrongholdCharacter