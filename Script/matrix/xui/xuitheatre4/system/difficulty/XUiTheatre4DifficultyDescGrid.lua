---@class XUiTheatre4DifficultyDescGrid : XUiNode
---@field _Control XTheatre4Control
local XUiTheatre4DifficultyDescGrid = XClass(XUiNode, "XUiTheatre4DifficultyDescGrid")

function XUiTheatre4DifficultyDescGrid:Update(text)
    self.TxtTitle.text = XUiHelper.ReplaceTextNewLine(text)
end

return XUiTheatre4DifficultyDescGrid