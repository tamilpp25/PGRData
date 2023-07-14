local XUiBuffGrid = require("XUi/XUiGoldenMiner/Grid/XUiBuffGrid")

local XUiBuffPanel = XClass(nil, "XUiBuffPanel")

function XUiBuffPanel:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCallback = clickCb
    XTool.InitUiObject(self)

    self.GridBuffList = {}
    self.GridBuff.gameObject:SetActiveEx(false)
    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    self.GridBuffParent = self.Container or self.Transform
end

function XUiBuffPanel:UpdateBuff()
    local list = XDataCenter.GoldenMinerManager.GetOwnBuffIdList()
    for i, buffId in ipairs(list) do
        local buffGrid = self.GridBuffList[i]
        if not buffGrid then
            local grid = i == 1 and self.GridBuff or XUiHelper.Instantiate(self.GridBuff, self.GridBuffParent)
            buffGrid = XUiBuffGrid.New(grid, self, self.ClickCallback)
            self.GridBuffList[i] = buffGrid
        end
        buffGrid:Refresh(buffId)
    end

    if self.GridBuffNone then
        self.GridBuffNone.gameObject:SetActiveEx(XTool.IsTableEmpty(list))
    end
end

return XUiBuffPanel