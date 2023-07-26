local XUiItemGrid = require("XUi/XUiGoldenMiner/Grid/XUiItemGrid")

---@class XUiGoldenMinerItemPanel
local XUiItemPanel = XClass(nil, "XUiItemPanel")

function XUiItemPanel:Ctor(ui, isGame)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsGame = isGame
    XTool.InitUiObject(self)

    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    ---@type XUiGoldenMinerItemGrid[]
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
        ---@type XUiGoldenMinerItemGrid
        local itemGrid = self.GridItemColumns[i]
        if not itemGrid then
            local grid = i == 1 and self.GridSubSkill or XUiHelper.Instantiate(self.GridSubSkill, self.Transform)
            itemGrid = XUiItemGrid.New(grid, self.IsGame)
            self.GridItemColumns[i] = itemGrid
        end
        itemGrid:Refresh(itemColumns[i - 1], i)
    end
end

---@return XUiGoldenMinerItemGrid
function XUiItemPanel:UseItemByIndex(index)
    local maxItemCount = XGoldenMinerConfigs.GetActivityMaxItemColumnCount()
    if index > maxItemCount then
        return
    end
    if not self.GridItemColumns[index] then
        --XGoldenMinerConfigs.DebugLog("道具栏"..index.."为空")
        return
    end
    self.GridItemColumns[index]:OnBtnClick()
end

return XUiItemPanel