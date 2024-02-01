--选择角色页面中角色列表Gird组件
local XUiSelectCharacterGrid = XClass(nil, "XUiSelectCharacterGrid")

UiCharacterGridType = {
    Normal = 1, --我拥有的角色
    Try = 2, --试玩角色(robot)
}

function XUiSelectCharacterGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiSelectCharacterGrid:UpdateInfo(data, teamData, editPos, rootUi)
    self:Reset()
    self.Data = data
    self.TeamData = teamData
    self.EditPos = editPos
    self.RootUi = rootUi
    if self.Data.Type == UiCharacterGridType.Normal then
        self:UpdateNormalInfo()
    elseif self.Data.Type == UiCharacterGridType.Try then
        self:UpdateTryInfo()
    end
end

function XUiSelectCharacterGrid:Reset()
    self.PanelTry.gameObject:SetActiveEx(false)
    self.PanelSelected.gameObject:SetActiveEx(false)
    self.RImgTonngDiao.gameObject:SetActiveEx(false)
    self.PanelRogueLikeTheme.gameObject:SetActiveEx(false)
    self.PanelStaminaBar.gameObject:SetActiveEx(false)
    self.PanelTeamSupport.gameObject:SetActiveEx(false)
    self.PanelInTeam.gameObject:SetActiveEx(false)
    self.PanelSame.gameObject:SetActiveEx(false)

    self.PanelFight.gameObject:SetActiveEx(true)
end

function XUiSelectCharacterGrid:UpdateNormalInfo()
    local characterData = XMVCA.XCharacter:GetCharacter(self.Data.Id)
    self.Data.CharacterData = characterData
    self.TxtLevel.text = characterData.Level
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(characterData.Quality))
    self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterData.Id))
    self.TxtFight.text = characterData.Ability

    local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(characterData.Id)
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

    --是否在队里,是否是同类角色
    for i = 1, #self.TeamData do
        if self.TeamData[i] == self.Data.Id then
            self.PanelInTeam.gameObject:SetActiveEx(true)
            break
        else
            if self.TeamData[i] < 1000000 and self.TeamData[i] > 0 then
                local robotTemplate = XRobotManager.GetRobotTemplate(self.TeamData[i])
                if robotTemplate.CharacterId == self.Data.Id then
                    self.PanelSame.gameObject:SetActiveEx(true)
                end
            end
        end
    end
end

--试玩角色Data.Id ->robotId
function XUiSelectCharacterGrid:UpdateTryInfo()
    self.PanelTry.gameObject:SetActiveEx(true)
    local robotTemplate = XRobotManager.GetRobotTemplate(self.Data.Id)
    self.Data.RobotData = robotTemplate
    self.TxtLevel.text = robotTemplate.CharacterLevel
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(robotTemplate.CharacterQuality))
    self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(robotTemplate.CharacterId, true))

    local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(robotTemplate.CharacterId)
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

    --是否在队里,是否是同类角色
    for i = 1, #self.TeamData do
        if self.TeamData[i] == robotTemplate.Id then
            self.PanelInTeam.gameObject:SetActiveEx(true)
            break
        else
            if self.TeamData[i] == robotTemplate.CharacterId then
                self.PanelSame.gameObject:SetActiveEx(true)
            end
        end
    end

    if self.Data.NieRCharacterId and self.Data.NieRCharacterId ~= 0 then
        self.TxtFight.text = XDataCenter.NieRManager.GetNieRCharacterByCharacterId(self.Data.NieRCharacterId):GetAbilityNum()
    else
        if self.RootUi and self.RootUi.Type and self.RootUi.Type == UiSelectCharacterType.NieROnlyRobot then
            self.TxtFight.text = XRobotManager.GetRobotAbility(self.Data.Id)
        else
            local ability = XRobotManager.GetRobotAbility(self.Data.Id)
            self.TxtFight.text = ability
        end
    end
end

function XUiSelectCharacterGrid:SetSelectMark(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

return XUiSelectCharacterGrid