---@class XUiRogueSimLoading : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimLoading = XLuaUiManager.Register(XLuaUi, "UiRogueSimLoading")

function XUiRogueSimLoading:OnStart()
    ---@type XTableRogueSimLoadingTips
    local config = self._Control:GetLoadingShowConfig()
    if not config then
        return
    end
    self.TxtTitle.text = config.Title
    self.TxtTips.text = config.Desc
end

return XUiRogueSimLoading
