local XUiStageMemoryRewardGrid = require("XUi/XUiStageMemory/XUiStageMemoryRewardGrid")

---@class XUiStageMemoryReward : XUiNode
---@field _Control XStageMemoryControl
local XUiStageMemoryReward = XClass(XUiNode, "XUiStageMemoryReward")

function XUiStageMemoryReward:OnStart()
    ---@type XUiStageMemoryRewardGrid
    self._GridItem1 = XUiStageMemoryRewardGrid.New(self.GridItem1, self)
    ---@type XUiStageMemoryRewardGrid
    self._GridItem2 = XUiStageMemoryRewardGrid.New(self.GridItem2, self)
end

---@param data XStageMemoryControlReward
function XUiStageMemoryReward:Update(data)
    self._Data = data
    self.TxtValue.text = data.StageAmount
    if data.IsEmpty then
        self.Grid.gameObject:SetActiveEx(false)
    else
        self.Grid.gameObject:SetActiveEx(true)
        self._GridItem1:Update(data, 1)
        self._GridItem2:Update(data, 2)
    end
end

return XUiStageMemoryReward