---@class XUiTemple2PopupChapterDetailGrid : XUiNode
---@field _Control XTemple2Control
local XUiTemple2PopupChapterDetailGrid = XClass(XUiNode, "XUiTemple2PopupChapterDetailGrid")

function XUiTemple2PopupChapterDetailGrid:OnStart()
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.BtnHead, self.OnClick)
end

---@param data XUiTemple2PopupChapterDetailGridData
function XUiTemple2PopupChapterDetailGrid:Update(data)
    self._Data = data
    ---@type XUiComponent.XUiButton
    local button = self.BtnHead
    button:SetSprite(data.Head)
    if data.IsUnlock then
        if data.IsSelected then
            button:SetButtonState(CS.UiButtonState.Select)
        else
            button:SetButtonState(CS.UiButtonState.Normal)
        end
    else
        button:SetButtonState(CS.UiButtonState.Disable)
    end
    -- 关卡详情：选人时，点击+滑动，有概率出现多个选中状态
    -- button底层原因
    button.TempState = CS.UiButtonState.Disable
end

function XUiTemple2PopupChapterDetailGrid:OnClick()
    self._Control:GetSystemControl():SetSelectedCharacter(self._Data)
end

return XUiTemple2PopupChapterDetailGrid