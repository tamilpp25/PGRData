local XUiGridRiftCharacter = XClass(nil, "XUiGridRiftCharacter")

function XUiGridRiftCharacter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiGridRiftCharacter:Refresh(xRole, isMultiTeam)
    self.XRole = xRole
    local characterId = xRole:GetCharacterId()
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

    if character then
        if self.TxtLevel then
            self.TxtLevel.text = character.Level
        end
    end

    if self.RImgQuality then
        self.RImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(xRole:GetQuality()))
    end

    if self.RImgHeadIcon then
        self.RImgHeadIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId))
    end

    if self.PanelFight then
        self.PanelFight.gameObject:SetActiveEx(true)
        local ability = xRole:GetFinalShowAbility()
        self.TxtFight.text = math.floor(ability)
    end
    
    if isMultiTeam then
        local isInTeam, xTeam = XDataCenter.RiftManager.CheckRoleInTeam(xRole:GetId())
        if isInTeam then
            local desc = CsXTextManagerGetText("StrongholdTeamIndex", xTeam:GetId())
            self.TxtInTeam.text = desc
        end
        self.ImgInTeam.gameObject:SetActiveEx(isInTeam)

        local isMultiEditLock = XDataCenter.RiftManager.CheckRoleInMultiTeamLock(xTeam)
        self.PanelInTeamLock.gameObject:SetActiveEx(isMultiEditLock)
        if isMultiEditLock then
            self.ImgInTeam.gameObject:SetActiveEx(false)
        end
        self.IsMultiEditLock = isMultiEditLock
    else
        local xTeam = XDataCenter.RiftManager.GetSingleTeamData()
        local isIn = xTeam:GetEntityIdIsInTeam(xRole:GetId())
        self.TxtInTeam.text = CsXTextManagerGetText("CommonInTheTeam")
        self.ImgInTeam.gameObject:SetActiveEx(isIn)
    end

    if self.PanelTry then
        self.PanelTry.gameObject:SetActiveEx(xRole:GetIsRobot())
    end

    self.TxtLoad.text = xRole:GetCurrentLoad().."/"..XDataCenter.RiftManager.GetMaxLoad()
end

function XUiGridRiftCharacter:SetSelect(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end

    if value then
        self.RootUi:OnRoleSelected(self.XRole)
    end
end

return XUiGridRiftCharacter