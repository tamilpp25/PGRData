local XCharacterViewModel = require("XEntity/XCharacter/XCharacterViewModel")

---@class XUiGuildWarTeamAreaCharacterSelectAssistantGrid
local XUiGuildWarTeamAreaCharacterSelectAssistantGrid = XClass(nil, "XUiGuildWarTeamAreaCharacterSelectAssistantGrid")

function XUiGuildWarTeamAreaCharacterSelectAssistantGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.AssistantData = false

    XTool.InitUiObject(self)
    self.ImgInTeam.gameObject:SetActiveEx(false)
    self:SetSelect(false)
end

function XUiGuildWarTeamAreaCharacterSelectAssistantGrid:Refresh(data)
    self.AssistantData = data

    self:UpdateCharacter()
end

function XUiGuildWarTeamAreaCharacterSelectAssistantGrid:UpdateCharacter()
    local data = self.AssistantData

    -- local playerId = data.PlayerId
    local character = data.FightNpcData.Character
    local characterId = character.Id

    if self.TxtPlayerName then
        self.TxtPlayerName.text = data.PlayerName or "???"
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
        local headInfo = character.CharacterHeadInfo or {}
        local head = XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId, true, headInfo.HeadFashionId, headInfo.HeadFashionType)
        self.RImgHeadIcon:SetRawImage(head)
    end

    if self.TxtLevel then
        local level = character.Level
        self.TxtLevel.text = level
    end

    if self.PanelFight then
        local ability = character.Ability
        self.TxtFight.text = math.floor(ability)
        self.PanelFight.gameObject:SetActiveEx(true)
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

    self.PanelLock.gameObject:SetActiveEx(self:IsIsomerLock())
end

function XUiGuildWarTeamAreaCharacterSelectAssistantGrid:SetSelect(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end
end

function XUiGuildWarTeamAreaCharacterSelectAssistantGrid:IsIsomerLock()
    local data = self.AssistantData
    local character = data.FightNpcData.Character
    local characterId = character.Id
    return not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer)
        and XCharacterConfigs.IsIsomer(characterId)
end

function XUiGuildWarTeamAreaCharacterSelectAssistantGrid:UpdateCdAndInTeam(teamIndex, isLock)
    self.ImgTeamNum.gameObject:SetActiveEx(false)
    self.ImgLock.gameObject:SetActiveEx(false)
    local data = self.AssistantData
    local isCd = XDataCenter.GuildWarManager.GetCdUsingAssistantCharacter(data) > 0
    if isCd then
        self.ImgInTeam.gameObject:SetActiveEx(true)
        self.TxtInTeam.text = XUiHelper.GetText("GuildWarCD")
        return
    end
    if not teamIndex then
        return 
    end
    self.ImgInTeam.gameObject:SetActiveEx(false)
    if isLock then
        self.ImgTeamNum.gameObject:SetActiveEx(false)
        self.ImgLock.gameObject:SetActiveEx(true)
    end
    self.ImgTeamNum.gameObject:SetActiveEx(true)
    self.ImgLock.gameObject:SetActiveEx(false)
    self.TxtTeamNum.text = CS.XTextManager.GetText("GuildWarTeamNumber" , teamIndex)
end

return XUiGuildWarTeamAreaCharacterSelectAssistantGrid
