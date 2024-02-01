---@class XUiTempleEditorStageGrid:XUiNode
local XUiTempleEditorStageGrid = XClass(XUiNode, "XUiTempleEditorStageGrid")

---@param data XTempleEditorUiDataGrid
function XUiTempleEditorStageGrid:Update(data)
    self.Text1.text = data.Name
    self.Text2.text = data.StageId
    self.Selected.gameObject:SetActiveEx(data.IsSelected)
end

return XUiTempleEditorStageGrid
