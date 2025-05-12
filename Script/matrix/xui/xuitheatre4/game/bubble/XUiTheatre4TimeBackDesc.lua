---@class XUiTheatre4TimeBackDesc : XUiNode
---@field _Control XTheatre4Control
local XUiTheatre4TimeBackDesc = XClass(XUiNode, "XUiTheatre4TimeBackDesc")

function XUiTheatre4TimeBackDesc:OnStart()
end

function XUiTheatre4TimeBackDesc:Update(data)
    local params = data.Params
    local icon = params[2]
    if not string.IsNilOrEmpty(icon) then
        self.RImgBuild:SetRawImage(icon)
    end

    local text = params[1]
    if not string.IsNilOrEmpty(text) then
        self.TxtDetail.text = string.format(text, data.Value)
    end
end

return XUiTheatre4TimeBackDesc