local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")

---@class XUiGuildWarCharacterSelectAssistantGrid:XUiBattleRoomRoleGrid
local XUiGuildWarCharacterSelectAssistantGrid = XClass(XUiBattleRoomRoleGrid, "XUiGuildWarCharacterSelectAssistantGrid")

function XUiGuildWarCharacterSelectAssistantGrid:Ctor(ui)
    self.PanelUP = self.PanelUP or XUiHelper.TryGetComponent(self.Transform, "PanelUP", "RectTransform")
    self.RImgUpIcon = self.RImgUpIcon or XUiHelper.TryGetComponent(self.PanelUP.transform, "PanelUP/UpTag/Icon", "RawImage")
    self:SetSelect(false)
end

function XUiGuildWarCharacterSelectAssistantGrid:Refresh(data)
    self.AssistantData = data
    self.Character = self.AssistantData
    self:UpdateCharacter()
end

function XUiGuildWarCharacterSelectAssistantGrid:UpdateCharacter()
    local data = self.AssistantData

    local character = data.FightNpcData.Character
    local characterId = character.Id
    local characterViewModel = XDataCenter.GuildWarManager.GetAssistantCharacterViewModel(characterId, data.PlayerId)
    self:SetCharacterViewModel(characterViewModel)

    if self.TxtPlayerName then
        self.TxtPlayerName.text = data.PlayerName or "???"
    end

    if self.PanelFight then
        local ability = character.Ability
        self.TxtFight.text = math.floor(ability)
        self.PanelFight.gameObject:SetActiveEx(true)
    end

    self:UpdateCdAndInTeam()

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

function XUiGuildWarCharacterSelectAssistantGrid:SetSelect(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end
end

function XUiGuildWarCharacterSelectAssistantGrid:IsIsomerLock()
    local data = self.AssistantData
    local character = data.FightNpcData.Character
    local characterId = character.Id
    return not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Isomer)
            and XMVCA.XCharacter:GetIsIsomer(characterId)
end

function XUiGuildWarCharacterSelectAssistantGrid:UpdateCdAndInTeam()
    local data = self.AssistantData
    local isCd = XDataCenter.GuildWarManager.GetCdUsingAssistantCharacter(data) > 0
    if isCd then
        self.ImgInTeam.gameObject:SetActiveEx(true)
        self.TxtInTeam.text = XUiHelper.GetText("GuildWarCD")
        return
    end

    local character = data.FightNpcData.Character
    local characterId = character.Id
    local isInTeam = XDataCenter.GuildWarManager.GetBattleManager():GetTeam():GetEntityIdIsInTeam(characterId)
    if isInTeam then
        self.ImgInTeam.gameObject:SetActiveEx(true)
        self.TxtInTeam.text = XUiHelper.GetText("CommonInTheTeam")
        return
    end

    self.ImgInTeam.gameObject:SetActiveEx(false)
end

return XUiGuildWarCharacterSelectAssistantGrid
