local XUiGoldenMinerBuffGrid = require("XUi/XUiGoldenMiner/Grid/XUiGoldenMinerBuffGrid")

---@class XUiGoldenMinerBuffPanel:XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerBuffPanel = XClass(XUiNode, "XUiGoldenMinerBuffPanel")

function XUiGoldenMinerBuffPanel:OnStart()
    ---@type XUiGoldenMinerBuffGrid[]
    self.GridBuffList = {}
    self.GridBuff.gameObject:SetActiveEx(false)
    self.DataDb = self._Control:GetMainDb()
    self.GridBuffParent = self.Container or self.Transform
end

---@param buffIdList number[]
function XUiGoldenMinerBuffPanel:UpdateBuff(buffIdList)
    local buffCount = #buffIdList
    for i = 1, buffCount do
        ---@type XUiGoldenMinerBuffGrid
        local buffGrid = self.GridBuffList[i]
        if not buffGrid then
            local grid = i == 1 and self.GridBuff or XUiHelper.Instantiate(self.GridBuff, self.GridBuffParent)
            buffGrid = XUiGoldenMinerBuffGrid.New(grid, self)
            self.GridBuffList[i] = buffGrid
        end
        buffGrid:Refresh(buffIdList[i])
        buffGrid:Open()
    end
    for i = buffCount + 1, #self.GridBuffList do
        self.GridBuffList[i]:Close()
    end

    if self.GridBuffNone then
        self.GridBuffNone.gameObject:SetActiveEx(XTool.IsTableEmpty(buffIdList))
    end
end

return XUiGoldenMinerBuffPanel