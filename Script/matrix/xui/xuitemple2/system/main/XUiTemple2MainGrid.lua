---@class XUiTemple2MainGrid : XUiNode
---@field _Control XTemple2Control
local XUiTemple2MainGrid = XClass(XUiNode, "XUiTemple2MainGrid")

function XUiTemple2MainGrid:OnStart()
    self._Data = false
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
end

---@param data XUiTemple2MainGridData
function XUiTemple2MainGrid:Update(data)
    self._Data = data
    --self.Button
    --self.ImgBg
    if self.TxtTitle then
        self.TxtTitle.text = data.Name
    end
    self.PanelLock.gameObject:SetActiveEx(not data.IsUnlock)
    self.TxtLock.text = data.LockReason
end

function XUiTemple2MainGrid:OnClick()
    if self._Data.IsUnlock then
        self._Control:GetSystemControl():SetCurrentChapter(self._Data)
        XLuaUiManager.Open("UiTemple2Chapter")
    else
        if self._Data.LockReason then
            XUiManager.TipMsg(self._Data.LockReason)
        end
    end
end

return XUiTemple2MainGrid