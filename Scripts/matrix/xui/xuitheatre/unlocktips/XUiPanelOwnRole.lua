--解锁可使用自身角色
local XUiPanelOwnRole = XClass(nil, "XUiPanelOwnRole")

function XUiPanelOwnRole:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)
end

function XUiPanelOwnRole:CheckShow(data)
    local isShow = data.ShowTipsPanel == XTheatreConfigs.UplockTipsPanel.OwnRole
    self.GameObject:SetActiveEx(isShow)
    if not isShow then
        return
    end

    local configs = XTheatreConfigs.GetUnlockOwnRole()

    local title = configs[1]
    self.TextTitle.text = title

    if self.Icon then
        local icon = configs[2]
        self.Icon:SetRawImage(icon)
    end

    local useOwnCharacterFa = XTheatreConfigs.GetTheatreConfig("UseOwnCharacterFa").Value
    self.TxtDesc.text = XUiHelper.GetText("TheatreUnlockOwnRoleTipsDesc", useOwnCharacterFa)
end

return XUiPanelOwnRole