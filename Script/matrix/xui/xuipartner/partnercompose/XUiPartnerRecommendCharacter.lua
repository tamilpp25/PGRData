---@class XUiPartnerRecommendCharacter:XUiNode
local XUiPartnerRecommendCharacter = XClass(XUiNode, "XUiPartnerRecommendCharacter")

function XUiPartnerRecommendCharacter:Update(characterId)
    local characterIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)
    local characterName = XMVCA.XCharacter:GetCharacterLogName(characterId)
    self.RImgRole:SetRawImage(characterIcon)
    self.RoleName.text = characterName
end

return XUiPartnerRecommendCharacter
