local mathFloor = math.floor
local IsNumberValid = XTool.IsNumberValid
local CsXTextManagerGetText = CsXTextManagerGetText

local XUiGridStrongholdCharacter = XClass(nil, "XUiGridStrongholdCharacter")

function XUiGridStrongholdCharacter:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self:SetSelect(false)
end

function XUiGridStrongholdCharacter:Refresh(characterId, groupId, teamId, teamList, playerId)
    self.CharacterId = characterId
    self.GroupId = groupId
    self.TeamId = teamId
    self.TeamList = teamList
    self.PlayerId = playerId

    if XRobotManager.CheckIsRobotId(characterId) then
        self:UpdateRobot()
    elseif IsNumberValid(playerId) then
        self:UpdateAssistant()
    else
        self:UpdateCharacter()
    end
end

function XUiGridStrongholdCharacter:UpdateRobot()
    local teamList = self.TeamList
    local groupId = self.GroupId
    local robotId = self.CharacterId
    local robotTemplate = XRobotManager.GetRobotTemplate(robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)

    if self.PanelCharElement then
        local detailConfig = XCharacterConfigs.GetCharDetailTemplate(characterId)
        local elementList = detailConfig.ObtainElementList
        for i = 1, 3 do
            local rImg = self["RImgCharElement" .. i]
            if elementList[i] then
                rImg.gameObject:SetActiveEx(true)
                local elementConfig = XCharacterConfigs.GetCharElement(elementList[i])
                rImg:SetRawImage(elementConfig.Icon)
            else
                rImg.gameObject:SetActiveEx(false)
            end
        end
    end

    if self.RImgHeadIcon then
        local head = XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId, robotTemplate.LiberateLv, true)
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
        local quality = XCharacterConfigs.GetCharacterQualityIcon(robotTemplate.CharacterQuality)
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

    if self.PanelRecommend then
        local stageId = groupId and XDataCenter.StrongholdManager.GetGroupStageId(groupId, self.TeamId) or nil
        local isStageRecomend = XFubenConfigs.IsStageRecommendCharacterType(stageId, characterId)
        self.PanelRecommend.gameObject:SetActiveEx(isStageRecomend)
    end
end

function XUiGridStrongholdCharacter:UpdateAssistant()
    local teamList = self.TeamList
    local groupId = self.GroupId
    local playerId = self.PlayerId
    local assistantInfo = XDataCenter.StrongholdManager.GetAssistantInfo(playerId)
    local character = assistantInfo.Character
    local characterId = character.Id

    if self.TxtPlayerName then
        self.TxtPlayerName.text = assistantInfo.Name or ""
    end

    if self.PanelCharElement then
        local detailConfig = XCharacterConfigs.GetCharDetailTemplate(characterId)
        local elementList = detailConfig.ObtainElementList
        for i = 1, 3 do
            local rImg = self["RImgCharElement" .. i]
            if elementList[i] then
                rImg.gameObject:SetActiveEx(true)
                local elementConfig = XCharacterConfigs.GetCharElement(elementList[i])
                rImg:SetRawImage(elementConfig.Icon)
            else
                rImg.gameObject:SetActiveEx(false)
            end
        end
    end

    if self.RImgHeadIcon then
        local head = XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId, character.LiberateLv, true)
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
        self.RImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(character.Quality))
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
        self.PanelTry.gameObject:SetActiveEx(true)
    end

    if self.PanelRecommend then
        local stageId = groupId and XDataCenter.StrongholdManager.GetGroupStageId(groupId, self.TeamId) or nil
        local isStageRecomend = XFubenConfigs.IsStageRecommendCharacterType(stageId, characterId)
        self.PanelRecommend.gameObject:SetActiveEx(isStageRecomend)
    end
end

function XUiGridStrongholdCharacter:UpdateCharacter()
    local teamId = self.TeamId
    local teamList = self.TeamList
    local groupId = self.GroupId
    local characterId = self.CharacterId
    local character = XDataCenter.CharacterManager.GetCharacter(characterId)

    if self.PanelCharElement then
        local detailConfig = XCharacterConfigs.GetCharDetailTemplate(characterId)
        local elementList = detailConfig.ObtainElementList
        for i = 1, 3 do
            local rImg = self["RImgCharElement" .. i]
            if elementList[i] then
                rImg.gameObject:SetActiveEx(true)
                local elementConfig = XCharacterConfigs.GetCharElement(elementList[i])
                rImg:SetRawImage(elementConfig.Icon)
            else
                rImg.gameObject:SetActiveEx(false)
            end
        end
    end

    if self.RImgHeadIcon then
        self.RImgHeadIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId))
    end

    if self.TxtLevel then
        self.TxtLevel.text = character.Level
    end

    if self.PanelFight then
        self.PanelFight.gameObject:SetActiveEx(true)
        local ability = XDataCenter.CharacterManager.GetCharacterAbilityById(characterId)
        self.TxtFight.text = mathFloor(ability)
    end

    if self.RImgQuality then
        self.RImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(character.Quality))
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

    if self.PanelRecommend then
        local stageId = groupId and XDataCenter.StrongholdManager.GetGroupStageId(groupId, self.TeamId) or nil
        local isStageRecomend = XFubenConfigs.IsStageRecommendCharacterType(stageId, characterId)
        self.PanelRecommend.gameObject:SetActiveEx(isStageRecomend)
    end
end

function XUiGridStrongholdCharacter:SetSelect(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end
end

return XUiGridStrongholdCharacter