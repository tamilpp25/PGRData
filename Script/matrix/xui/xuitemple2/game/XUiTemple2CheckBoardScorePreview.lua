local XUiTemple2Util = require("XUi/XUiTemple2/XUiTemple2Util")

---@class XUiTemple2CheckBoardScorePreview : XUiNode
---@field _Control XTemple2Control
local XUiTemple2CheckBoardScorePreview = XClass(XUiNode, "XUiTemple2CheckBoardScorePreview")

---@param data XUiTemple2CheckBoardScorePreviewData
function XUiTemple2CheckBoardScorePreview:Update(data)
    self.TxtName.text = data.Name
    self.TxtNum.text = data.Score
    XUiTemple2Util.ActiveIcon(self, data)
end

return XUiTemple2CheckBoardScorePreview