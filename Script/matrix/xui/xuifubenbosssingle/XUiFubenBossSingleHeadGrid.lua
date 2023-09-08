---@class XUiFubenBossSingleHeadGrid : XUiNode
local XUiFubenBossSingleHeadGrid = XClass(XUiNode, "XUiFubenBossSingleHeadGrid")

function XUiFubenBossSingleHeadGrid:OnStart(characterId)
    self._CharacterId = characterId or self._CharacterId
    self:_InitUi()
end

function XUiFubenBossSingleHeadGrid:OnEnable()
    self:_Refresh()
end

function XUiFubenBossSingleHeadGrid:SetCharacterId(characterId)
    self._CharacterId = characterId
end

function XUiFubenBossSingleHeadGrid:_InitUi()
    self.TxtNickName = XUiHelper.TryGetComponent(self.Transform, "TxtNickName", "Text")
    self.TxtEnough = XUiHelper.TryGetComponent(self.Transform, "TxtCountEnough", "Text")
    self.TxtNotEnough = XUiHelper.TryGetComponent(self.Transform, "TxtCountNotEnough", "Text")
    self.ImgHead = XUiHelper.TryGetComponent(self.Transform, "Gouzaoti/RImgHead", "RawImage")
end

function XUiFubenBossSingleHeadGrid:_Refresh()
    if not self._CharacterId then
        return
    end

    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local characterId = self._CharacterId
    local headIcon = characterAgency:GetCharBigRoundnessHeadIcon(characterId)
    local fullName = characterAgency:GetCharacterFullNameStr(characterId)
    local maxStamina = XDataCenter.FubenBossSingleManager.GetMaxStamina()
    local curStamina = maxStamina - XDataCenter.FubenBossSingleManager.GetCharacterChallengeCount(characterId)

    self.ImgHead:SetRawImage(headIcon)
    self.TxtNickName.text = fullName
    self.TxtEnough.text = XUiHelper.GetText("BossSingleAutoFightDesc5", curStamina, maxStamina)
    self.TxtNotEnough.text = XUiHelper.GetText("BossSingleAutoFightDesc6", curStamina, maxStamina)
    self.TxtEnough.gameObject:SetActiveEx(curStamina > 0)
    self.TxtNotEnough.gameObject:SetActiveEx(curStamina <= 0)
end

return XUiFubenBossSingleHeadGrid