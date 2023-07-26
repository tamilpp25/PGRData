local XUiBuffGrid = require("XUi/XUiGoldenMiner/Grid/XUiBuffGrid")

---@class XUiGoldenMinerBuffPanel
---@field GridBuffList XUiGoldenMinerBuffGrid[]
local XUiBuffPanel = XClass(nil, "XUiBuffPanel")

function XUiBuffPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.GridBuffList = {}
    self.GridBuff.gameObject:SetActiveEx(false)
    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    self.GridBuffParent = self.Container or self.Transform
end

---@param buffIdList number[]
function XUiBuffPanel:UpdateBuff(buffIdList)
    local buffCount = #buffIdList
    for i = 1, buffCount do
        ---@type XUiGoldenMinerBuffGrid
        local buffGrid = self.GridBuffList[i]
        if not buffGrid then
            local grid = i == 1 and self.GridBuff or XUiHelper.Instantiate(self.GridBuff, self.GridBuffParent)
            buffGrid = XUiBuffGrid.New(grid, self)
            self.GridBuffList[i] = buffGrid
        end
        buffGrid:Refresh(buffIdList[i])
    end
    for i = buffCount + 1, #self.GridBuffList do
        self.GridBuffList[i]:SetActive(false)
    end

    if self.GridBuffNone then
        self.GridBuffNone.gameObject:SetActiveEx(XTool.IsTableEmpty(buffIdList))
    end
end

return XUiBuffPanel