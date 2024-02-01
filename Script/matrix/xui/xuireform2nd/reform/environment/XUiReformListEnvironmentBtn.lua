---@field _Control XReformControl
---@class XUiReformListEnvironmentBtn:XUiNode
local XUiReformListEnvironmentBtn = XClass(XUiNode, "XUiReformListEnvironmentBtn")

---@param data XViewModelReformEnvironment
function XUiReformListEnvironmentBtn:Update(data)
    if data then
        self.TextNone.gameObject:SetActiveEx(false)
        self.RImg:SetRawImage(data.Icon)
        self.RImg.gameObject:SetActiveEx(true)
        self.TextEnvironment.text = data.Name
    else
        self.TextNone.gameObject:SetActiveEx(true)
        self.RImg.gameObject:SetActiveEx(false)
        self.TextEnvironment.text = ""
    end
end

return XUiReformListEnvironmentBtn