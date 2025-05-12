---@class XUiGridGame2048Target:XUiNode
---@field _Control XGame2048Control
local XUiGridGame2048Target = XClass(XUiNode, 'XUiGridGame2048Target')


function XUiGridGame2048Target:Refresh(desc, isAchieve)
    self.TargetOff.gameObject:SetActiveEx(not isAchieve)
    self.TargetOn.gameObject:SetActiveEx(isAchieve)

    if isAchieve then
        self.TxtTargetOn.text = desc
    else
        self.TxtTargetOff.text = desc
    end
end

return XUiGridGame2048Target