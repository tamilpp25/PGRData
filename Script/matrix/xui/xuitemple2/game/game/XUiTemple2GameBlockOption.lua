---@class XUiTemple2GameBlockOption : XUiNode
---@field _Control XTemple2Control
local XUiTemple2GameBlockOption = XClass(XUiNode, "XUiTemple2GameBlockOption")

function XUiTemple2GameBlockOption:OnStart()
    local button = self.Transform:GetComponent("XUiButton")
    if button then
        XUiHelper.RegisterClickEvent(self, button, self.OnClick)
    end
    self._Data = false
end

---@param data XUiTemple2GameBlockOptionData
function XUiTemple2GameBlockOption:Update(data)
    self.TxtName.text = data.Name
    self._Data = data
end

function XUiTemple2GameBlockOption:OnClick()
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_CLICK_BLOCK_OPTION, self._Data)
end

return XUiTemple2GameBlockOption