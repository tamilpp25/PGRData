local XUiGridUnlockIcon = require("XUi/XUiTheatre/UnlockTips/XUiGridUnlockIcon")

--新装修项解锁
local XUiPanelNewTalent = XClass(nil, "XUiPanelNewTalent")

function XUiPanelNewTalent:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
    self:Init()
end

function XUiPanelNewTalent:Init()
    local configs = XTheatreConfigs.GetUnlockNewDecoration()
    local title = configs[1]
    local desc = configs[2]
    self.TextTitle.text = title
    self.TextDesc.text = desc

    self.Grids = {}
end

function XUiPanelNewTalent:CheckShow(data)
    local isShow = data.ShowTipsPanel == XTheatreConfigs.UplockTipsPanel.NewTalent
    self.GameObject:SetActiveEx(isShow)
    if not isShow then
        return
    end

    local theatreDecorationIdList = data.TheatreDecorationIdList
    for i, id in ipairs(theatreDecorationIdList) do
        local grid = self.Grids[i]
        if not grid then
            local obj = i == 1 and self.GridUnlockIcon or XUiHelper.Instantiate(self.GridUnlockIcon, self.PanelUnlockInfo)
            grid = XUiGridUnlockIcon.New(obj)
            self.Grids[i] = grid
        end
        grid:SetData({Name = XTheatreConfigs.GetDecorationName(id), Icon = XTheatreConfigs.GetDecorationIcon(id)})
    end
end

return XUiPanelNewTalent