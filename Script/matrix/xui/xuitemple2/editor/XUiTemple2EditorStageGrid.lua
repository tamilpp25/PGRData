---@class XUiTemple2EditorStageGrid:XUiNode
local XUiTemple2EditorStageGrid = XClass(XUiNode, "XUiTemple2EditorStageGrid")

---@param data XTempleEditorUiDataGrid
function XUiTemple2EditorStageGrid:Update(data)
    self.Text1.text = data.Name
    self.Text2.text = data.StageId
    self.Selected.gameObject:SetActiveEx(data.IsSelected)
end

return XUiTemple2EditorStageGrid
