---@class XUiTempleEditorGridRound:XUiNode
local XUiTempleEditorGridRound = XClass(XUiNode, "XUiTempleEditorGridRound")

function XUiTempleEditorGridRound:Ctor()
    self._Data = nil
end

function XUiTempleEditorGridRound:OnStart()
    self.Selected.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
end

function XUiTempleEditorGridRound:Update(data)
    self._Data = data
    self.Text1.text = data.Name
end

function XUiTempleEditorGridRound:OnClick()
    if self._Data then
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_EDIT_ROUND, self._Data.Round)
    end
end

function XUiTempleEditorGridRound:UpdateSelected(round)
    if not self._Data then
        self.Selected.gameObject:SetActiveEx(false)
        return
    end
    self.Selected.gameObject:SetActiveEx(round == self._Data.Round)
end

return XUiTempleEditorGridRound