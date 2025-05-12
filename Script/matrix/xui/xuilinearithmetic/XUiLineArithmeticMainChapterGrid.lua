---@class XUiLineArithmeticMainChapterGrid : XUiNode
---@field _Control XLineArithmeticControl
local XUiLineArithmeticMainChapterGrid = XClass(XUiNode, "XUiLineArithmeticMainChapterGrid")

function XUiLineArithmeticMainChapterGrid:OnStart()
    ---@type XLineArithmeticControlChapterData
    self._Data = false
    local buttonComponent = XUiHelper.TryGetComponent(self.Transform, "", "XUiButton")
    XUiHelper.RegisterClickEvent(self, buttonComponent, self.OnClick)
end

---@param data XLineArithmeticControlChapterData
function XUiLineArithmeticMainChapterGrid:Update(data)
    self._Data = data
    --self.TxtTitle.text = data.Name
    --self.PanelOngoing.gameObject:SetActiveEx(data.isRunning)
    self.TxtNew.gameObject:SetActiveEx(data.IsNew)
    --self.PanelLock.gameObject:SetActiveEx(not data.IsOpen)
    --self.TxtStar.text = data.TxtStar
    self.Button:SetNameByGroup(0, data.TxtStar)
    if data.IsOpen then
        self.Button:SetButtonState(CS.UiButtonState.Normal)
    else
        self.Button:SetButtonState(CS.UiButtonState.Disable)
    end
    local uiText = self.Text1 or self.Text2 or self.Text3 or self.Text4
    if uiText then
        uiText.text = data.TxtLock
    end
end

function XUiLineArithmeticMainChapterGrid:OnClick()
    self._Control:OnClickChapter(self._Data)
end

return XUiLineArithmeticMainChapterGrid