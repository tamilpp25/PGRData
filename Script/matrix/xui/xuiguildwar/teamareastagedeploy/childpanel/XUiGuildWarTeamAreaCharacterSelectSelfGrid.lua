---@class XUiGuildWarTeamAreaCharacterSelectSelfGrid
local XUiGuildWarTeamAreaCharacterSelectSelfGrid = XClass(nil, "XUiGuildWarTeamAreaCharacterSelectSelfGrid")

function XUiGuildWarTeamAreaCharacterSelectSelfGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.ImgInTeam.gameObject:SetActiveEx(false)
    self:SetSelect(false)
end

function XUiGuildWarTeamAreaCharacterSelectSelfGrid:Refresh(characterId)
    self.CharacterId = characterId

    self:UpdateCharacter()
end

function XUiGuildWarTeamAreaCharacterSelectSelfGrid:UpdateCharacter()
    local characterId = self.CharacterId
    local character = XMVCA.XCharacter:GetCharacter(characterId)

    if self.PanelCharElement then
        local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(characterId)
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
    end

    if self.RImgHeadIcon then
        self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
    end

    if self.TxtLevel then
        self.TxtLevel.text = character.Level
    end

    if self.PanelFight then
        self.PanelFight.gameObject:SetActiveEx(true)
        local ability = XMVCA.XCharacter:GetCharacterAbilityById(characterId)
        self.TxtFight.text = math.floor(ability)
    end

    if self.RImgQuality then
        self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))
    end

    -- 特攻角色
    local isSpecialRole = XDataCenter.GuildWarManager.CheckIsSpecialRole(characterId)
    self.PanelUP.gameObject:SetActiveEx(isSpecialRole)

    -- 特攻图标
    if isSpecialRole then
        local icon = XDataCenter.GuildWarManager.GetSpecialRoleIcon(characterId)
        if icon then
            self.RImgUpIcon:SetRawImage(icon)
        end
    end
end

function XUiGuildWarTeamAreaCharacterSelectSelfGrid:SetSelect(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end
end

function XUiGuildWarTeamAreaCharacterSelectSelfGrid:SetInTeamNum(teamIndex, isLock)
    if not teamIndex then 
        self.ImgTeamNum.gameObject:SetActiveEx(false)
        self.ImgLock.gameObject:SetActiveEx(false)
        return 
    end
    if isLock then
        self.ImgTeamNum.gameObject:SetActiveEx(false)
        self.ImgLock.gameObject:SetActiveEx(true)
    end
    self.ImgTeamNum.gameObject:SetActiveEx(true)
    self.ImgLock.gameObject:SetActiveEx(false)
    self.TxtTeamNum.text = CS.XTextManager.GetText("GuildWarTeamNumber" , teamIndex)
end 

return XUiGuildWarTeamAreaCharacterSelectSelfGrid
