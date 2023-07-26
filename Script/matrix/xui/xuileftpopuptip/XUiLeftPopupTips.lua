---@class XUiLeftPopupTips : XLuaUi
local XUiLeftPopupTips = XLuaUiManager.Register(XLuaUi, "UiLeftPopupTips")

---@deprecated delayTime 显示时间 单位秒
function XUiLeftPopupTips:OnStart(data, delayTime)
    self.Data = data
    self.GridDic = {}
    self:InitView()

    XScheduleManager.ScheduleOnce(function()
        self:Close()
    end, XScheduleManager.SECOND * delayTime)
end

function XUiLeftPopupTips:InitView()
    if XTool.IsTableEmpty(self.Data) then
        return
    end
    for index, data in pairs(self.Data) do
        local grid = self.GridDic[index]
        if not grid then
            local go = index == 1 and self.PanelAssistDistanceTip or XUiHelper.Instantiate(self.PanelAssistDistanceTip, self.PanelContentTip)
            grid = {}
            XTool.InitUiObjectByUi(grid, go)
            self.GridDic[index] = grid
        end
        grid.TxtTitle.text = data.Title
        grid.TxtContent.text = data.Content
    end
end

return XUiLeftPopupTips