---@class XUiGridWheelchairManualGuideTag: XUiNode
---@field _Control XWheelchairManualControl
local XUiGridWheelchairManualGuideTag = XClass(XUiNode, 'XUiGridWheelchairManualGuideTag')

function XUiGridWheelchairManualGuideTag:Refresh(kindId)
    self.Id = kindId
    local kindCfg = self._Control:GetWheelchairManualGuideKindCfg(self.Id)

    if kindCfg then
        self.ImgBg.color = XUiHelper.Hexcolor2Color(string.gsub(kindCfg.BgColor, '#', ''))
        self.TxtName.text = kindCfg.Name
    else
        self:Close()
    end
end

return XUiGridWheelchairManualGuideTag