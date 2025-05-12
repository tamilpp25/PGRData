local XUiGoldenMinerItemGrid = require("XUi/XUiGoldenMiner/Grid/XUiGoldenMinerItemGrid")

---@class XUiGoldenMinerItemPanel:XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerItemPanel = XClass(XUiNode, "XUiGoldenMinerItemPanel")

function XUiGoldenMinerItemPanel:OnStart(isGame)
    self.IsGame = isGame
    self.DataDb = self._Control:GetMainDb()
    ---@type XUiGoldenMinerItemGrid[]
    self.GridItemColumns = {}
end

function XUiGoldenMinerItemPanel:UpdateItemColumns()
    if not self.GridSubSkill then
        return
    end

    local itemColumns = self.DataDb:GetItemColumns()
    local maxItemCount = self._Control:GetCurActivityMaxItemColumnCount()
    for i = 1, maxItemCount do
        ---@type XUiGoldenMinerItemGrid
        local itemGrid = self.GridItemColumns[i]
        if not itemGrid then
            local grid = i == 1 and self.GridSubSkill or XUiHelper.Instantiate(self.GridSubSkill, self.Transform)
            itemGrid = XUiGoldenMinerItemGrid.New(grid, self, self.IsGame)
            self.GridItemColumns[i] = itemGrid
        end
        itemGrid:Refresh(itemColumns[i - 1], i)
    end
end

---@return XUiGoldenMinerItemGrid
function XUiGoldenMinerItemPanel:UseItemByIndex(index)
    local maxItemCount = self._Control:GetCurActivityMaxItemColumnCount()
    if index > maxItemCount then
        return
    end
    if not self.GridItemColumns[index] then
        return
    end
    self.GridItemColumns[index]:OnBtnClick()
end

return XUiGoldenMinerItemPanel