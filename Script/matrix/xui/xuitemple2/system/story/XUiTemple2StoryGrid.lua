---@class XUiTemple2StoryGrid : XUiNode
---@field _Control XTemple2Control
local XUiTemple2StoryGrid = XClass(XUiNode, "XUiTemple2StoryGrid")

function XUiTemple2StoryGrid:OnStart()
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
end

---@param data XUiTemple2StoryGridData
function XUiTemple2StoryGrid:Update(data)
    self._Data = data
    if data.IsUnlock then
        self.Button:SetButtonState(CS.UiButtonState.Normal)
    else
        self.Button:SetButtonState(CS.UiButtonState.Disable)
    end
    self.Button:SetNameByGroup(0, data.Desc)
    self.Button:SetRawImage(data.Icon)
end

function XUiTemple2StoryGrid:OnClick()
    if self._Data.IsUnlock then
        XLuaUiManager.Open("UiTemple2PopupStory", self._Data)
    else
        XUiManager.TipText("NotUnlock")
    end
end

return XUiTemple2StoryGrid