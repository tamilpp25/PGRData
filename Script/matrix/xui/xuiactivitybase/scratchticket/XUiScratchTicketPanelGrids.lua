-- 刮刮卡九宫格面板
local XUiScratchTicketPanelGrids = XClass(nil, "XUiScratchTicketPanelGrids")

function XUiScratchTicketPanelGrids:Ctor(uiGameObject, gameController, rootUi)
    -- 这个面板没有使用UiObject
    self.GameObject = uiGameObject.gameObject
    self.Transform = uiGameObject.transform
    self.RootUi = rootUi
    self.Controller = gameController
    self:InitPanel()
end

function XUiScratchTicketPanelGrids:GetTicket()
    if not self.Ticket then self.Ticket = self.Controller:GetTicket() end
    return self.Ticket
end
--==================
--初始化面板
--==================
function XUiScratchTicketPanelGrids:InitPanel()
    local ticket = self:GetTicket()
    if ticket and ticket:GetPlayStatus() ~= XDataCenter.ScratchTicketManager.PlayStatus.NotStart then
        self:ShowPanel()
    else
        self:HidePanel()
    end
    self:InitGrids()
end
--==================
--初始化九宫格
--==================
function XUiScratchTicketPanelGrids:InitGrids()
    local gridScript = require("XUi/XUiActivityBase/ScratchTicket/XUiScratchTicketGrid")
    local gridIndex = 1
    self.Grids = {}
    while(gridIndex < 100) do
        local gridGameObject = self.GameObject:FindGameObject("Grid" .. gridIndex)
        if not gridGameObject then
            break
        end
        self.Grids[gridIndex] = gridScript.New(gridGameObject, gridIndex, self)
        gridIndex = gridIndex + 1
    end
end
--==================
--刷新九宫格
--==================
function XUiScratchTicketPanelGrids:Refresh()
    self:HideAllMasks()
    for _, grid in pairs(self.Grids) do
        grid:Refresh()
    end
end

function XUiScratchTicketPanelGrids:SetMaskOnChoseSelect(choseIndex)
    local choseCfg = XScratchTicketConfig.GetChoseConfigById(choseIndex, true)
    if choseCfg then
        local selectIndexs = {}
        for _, gridIndex in pairs(choseCfg.GridIndex) do
            selectIndexs[gridIndex] = true
        end
        for index, grid in pairs(self.Grids) do
            if selectIndexs[index] then
                grid:HideMask()
            else
                grid:SetMask()
            end
        end
        self:ShowPanel()
    end
end

function XUiScratchTicketPanelGrids:HideAllMasks()
    for _, grid in pairs(self.Grids) do
        grid:HideMask()
    end
end
--==================
--显示面板
--==================
function XUiScratchTicketPanelGrids:ShowPanel()
    self.GameObject:SetActiveEx(true)
end
--==================
--隐藏面板
--==================
function XUiScratchTicketPanelGrids:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiScratchTicketPanelGrids