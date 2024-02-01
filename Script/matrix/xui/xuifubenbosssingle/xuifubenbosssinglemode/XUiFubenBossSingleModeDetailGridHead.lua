---@class XUiFubenBossSingleModeDetailGridHead : XUiNode
---@field RImgHead UnityEngine.UI.RawImage
---@field ImgClash UnityEngine.UI.Image
---@field PanelEmpty UnityEngine.UI.RectTransform
local XUiFubenBossSingleModeDetailGridHead = XClass(XUiNode, "XUiFubenBossSingleModeDetailGridHead")

function XUiFubenBossSingleModeDetailGridHead:Refresh(characterId, isClash, isSelf)
    if characterId ~= nil then
        self.RImgHead.gameObject:SetActiveEx(true)
        self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharBigHeadIcon(characterId))
        self.ImgClash.gameObject:SetActiveEx(isClash or false)
        self.PanelEmpty.gameObject:SetActiveEx(false)

        self:_RefreshClashEffect(isClash or false, isSelf)
    else
        self.RImgHead.gameObject:SetActiveEx(false)
        self.ImgClash.gameObject:SetActiveEx(false)
        self.PanelEmpty.gameObject:SetActiveEx(true)

        self:_RefreshClashEffect(false, false)
    end
end

function XUiFubenBossSingleModeDetailGridHead:_RefreshClashEffect(isShow, isSelf)
    if self.ImgEffecBlue then
        self.ImgEffecBlue.gameObject:SetActiveEx(isShow and isSelf)
    end
    if self.ImgEffectRed then
        self.ImgEffectRed.gameObject:SetActiveEx(isShow and not isSelf)
    end
end

return XUiFubenBossSingleModeDetailGridHead
