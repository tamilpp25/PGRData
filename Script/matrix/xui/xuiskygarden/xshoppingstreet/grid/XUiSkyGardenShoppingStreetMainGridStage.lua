local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiSkyGardenShoppingStreetMainGridStage : XUiNode
---@field TxtTitle UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetMainGridStage = XClass(XUiNode, "XUiSkyGardenShoppingStreetMainGridStage")

function XUiSkyGardenShoppingStreetMainGridStage:Ctor()
    self.GridStage.CallBack = function() self:OnGridStageClick() end
end

function XUiSkyGardenShoppingStreetMainGridStage:OnGridStageClick()
    XMVCA.XSkyGardenShoppingStreet:StartStage(self._data.Id)
end

function XUiSkyGardenShoppingStreetMainGridStage:ResetData(stageId, i)
    self._data = self._Control:GetStageConfigsByStageId(stageId)
    self.TxtTitle.text = self._data.Name
end

return XUiSkyGardenShoppingStreetMainGridStage
