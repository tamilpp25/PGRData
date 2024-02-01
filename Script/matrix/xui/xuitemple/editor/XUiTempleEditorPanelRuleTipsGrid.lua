---@field _Control XTempleControl
---@class XUiTempleEditorPanelRuleTipsGrid:XUiNode
local XUiTempleEditorPanelRuleTipsGrid = XClass(XUiNode, "XUiTempleEditorPanelRuleTipsGrid")

function XUiTempleEditorPanelRuleTipsGrid:Ctor()
    self._Data = false
    ---@type XTempleGameEditorControl
    self._GameControl = self._Control:GetGameControl()
end

function XUiTempleEditorPanelRuleTipsGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.Button, self._OnClick)
end

function XUiTempleEditorPanelRuleTipsGrid:Update(data)
    self._Data = data
    self.Text1.text = data.Text
    self:UpdateSelected()
end

function XUiTempleEditorPanelRuleTipsGrid:_OnClick()
    self._GameControl:SetTipsEditingRule(self._Data)
end

function XUiTempleEditorPanelRuleTipsGrid:UpdateSelected()
    if self._GameControl:IsTipsEditingRule(self._Data) then
        self.Selected.gameObject:SetActiveEx(true)
    else
        self.Selected.gameObject:SetActiveEx(false)
    end
end

return XUiTempleEditorPanelRuleTipsGrid
