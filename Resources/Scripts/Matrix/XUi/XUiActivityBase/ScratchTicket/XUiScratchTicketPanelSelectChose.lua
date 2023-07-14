---@class XUiScratchTicketPanelSelectChose
local XUiScratchTicketPanelSelectChose = XClass(nil, "XUiScratchTicketPanelSelectChose")

function XUiScratchTicketPanelSelectChose:Ctor(uiGameObject, gameController, rootUi)
    self.GameObject = uiGameObject.gameObject
    self.Controller = gameController
    self.RootUi = rootUi
    self:InitPanel()
end

function XUiScratchTicketPanelSelectChose:InitPanel()
    local gridIndex = 1
    self.Grids = {}
    while(gridIndex < 100) do
        local gridGameObject = self.GameObject:FindGameObject("Grid" .. gridIndex)
        if not gridGameObject then
            break
        end
        self.Grids[gridIndex] = gridGameObject
        gridIndex = gridIndex + 1
    end
    self:HidePanel()
end

function XUiScratchTicketPanelSelectChose:Reset()
    for index, grid in pairs(self.Grids) do
        grid.gameObject:SetActiveEx(false)
    end
end

function XUiScratchTicketPanelSelectChose:SelectChose(index)
    local choseCfg = XScratchTicketConfig.GetChoseConfigById(index, true)
    if choseCfg then
        local selectIndexs = {}
        for _, gridIndex in pairs(choseCfg.GridIndex) do
            selectIndexs[gridIndex] = true
        end
        for index, grid in pairs(self.Grids) do
            grid.gameObject:SetActiveEx(selectIndexs[index])
        end
        self:ShowPanel()
    else
        self:HidePanel()
    end
end

function XUiScratchTicketPanelSelectChose:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiScratchTicketPanelSelectChose:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiScratchTicketPanelSelectChose