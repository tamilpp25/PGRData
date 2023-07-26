local XUiGridUnlockIcon = require("XUi/XUiTheatre/UnlockTips/XUiGridUnlockIcon")

--解锁功能
local XUiPanelPrerogative = XClass(nil, "XUiPanelPrerogative")

function XUiPanelPrerogative:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self.Grids = {}
end

-- data = {
--     ShowTipsPanel
--     Datas = {
--         {
--             Name,    --功能名
--             Icon,    --图标路径
--         }
--     }
-- }
function XUiPanelPrerogative:CheckShow(data)
    local isShow = data.ShowTipsPanel == XTheatreConfigs.UplockTipsPanel.Prerogative
    self.GameObject:SetActiveEx(isShow)
    if not isShow then
        return
    end

    local prerogativeDatas = data.Datas
    for i, data in ipairs(prerogativeDatas) do
        local grid = self.Grids[i]
        if not grid then
            local obj = i == 1 and self.GridUnlockIcon or XUiHelper.Instantiate(self.GridUnlockIcon, self.PanelUnlockInfo)
            grid = XUiGridUnlockIcon.New(obj)
            self.Grids[i] = grid
        end
        grid:SetData(data)
    end
end

return XUiPanelPrerogative