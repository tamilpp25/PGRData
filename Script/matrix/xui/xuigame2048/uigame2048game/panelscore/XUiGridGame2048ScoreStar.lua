---@class XUiGridGame2048ScoreStar: XUiNode
local XUiGridGame2048ScoreStar = XClass(XUiNode, 'XUiGridGame2048ScoreStar')

function XUiGridGame2048ScoreStar:SetIsAchieve(achieve)
    self.ImgOn.gameObject:SetActiveEx(achieve)
    self.ImgOff.gameObject:SetActiveEx(not achieve)
end

return XUiGridGame2048ScoreStar