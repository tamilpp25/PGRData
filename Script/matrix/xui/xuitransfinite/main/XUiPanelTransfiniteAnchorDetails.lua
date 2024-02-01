---@class XUiPanelTransfiniteAnchorDetails : XUiNode
local XUiPanelTransfiniteAnchorDetails = XClass(XUiNode, "XUiPanelTransfiniteAnchorDetails")

function XUiPanelTransfiniteAnchorDetails:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.GridAnchor.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridAnchorList = {}
end

function XUiPanelTransfiniteAnchorDetails:Refresh()
    local stageGroup = XDataCenter.TransfiniteManager.GetStageGroup()
    local nextStartProgress = stageGroup:GetNextStartProgress()
    local configs = XTransfiniteConfigs.GetAllStartStageProgress()
    for index, config in ipairs(configs) do
        local grid = self.GridAnchorList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridAnchor, self.PanelAnchor)
            self.GridAnchorList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtOnNum1").text = config.LastProgress
        grid:GetObject("TxtOnNum2").text = config.StartProgress
        grid:GetObject("TxtOffNum1").text = config.LastProgress
        grid:GetObject("TxtOffNum2").text = config.StartProgress
        grid:GetObject("PanelOff").gameObject:SetActiveEx(config.StartProgress > nextStartProgress)
        grid:GetObject("PanelOn").gameObject:SetActiveEx(config.StartProgress <= nextStartProgress)
    end
    for i = #configs + 1, #self.GridAnchorList do
        self.GridAnchorList[i].gameObject:SetActiveEx(false)
    end
end

function XUiPanelTransfiniteAnchorDetails:OnBtnCloseClick()
    self:Close()
end

return XUiPanelTransfiniteAnchorDetails
