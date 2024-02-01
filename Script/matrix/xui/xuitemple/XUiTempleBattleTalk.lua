---@class XUiTempleBattleTalk : XUiNode
---@field _Control XTempleControl
local XUiTempleBattleTalk = XClass(XUiNode, "UiTempleBattleTalk")

function XUiTempleBattleTalk:Update(data)
    self.TxtSpeak.text = data.Text
    self.RImgCharacter:SetRawImage(data.ImageCharacter)
    --self.RImgFace:SetRawImage(data.ImageFace)
    --self.RImgHair:SetRawImage(data.ImageHair)
end

return XUiTempleBattleTalk