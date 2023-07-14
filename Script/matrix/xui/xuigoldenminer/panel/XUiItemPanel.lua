local XUiItemGrid = require("XUi/XUiGoldenMiner/Grid/XUiItemGrid")

local XUiItemPanel = XClass(nil, "XUiItemPanel")

function XUiItemPanel:Ctor(ui, useItemCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UseItemCb = useItemCb
    XTool.InitUiObject(self)

    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    self.GridItemColumns = {}
    if self.GridSubSkill then
        self.GridSubSkill.gameObject:SetActiveEx(false)
    end
end

function XUiItemPanel:UpdateItemColumns()
    if not self.GridSubSkill then
        return
    end

    local itemColumns = self.DataDb:GetItemColumns()
    local maxItemCount = XGoldenMinerConfigs.GetActivityMaxItemColumnCount()
    for i = 1, maxItemCount do
        local itemGrid = self.GridItemColumns[i]
        if not itemGrid then
            local grid = i == 1 and self.GridSubSkill or XUiHelper.Instantiate(self.GridSubSkill, self.Transform)
            itemGrid = XUiItemGrid.New(grid, self.UseItemCb)
            self.GridItemColumns[i] = itemGrid
        end
        itemGrid:Refresh(itemColumns[i - 1])
    end
end

return XUiItemPanel