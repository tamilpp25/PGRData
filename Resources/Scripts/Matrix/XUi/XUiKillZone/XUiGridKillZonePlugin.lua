local XUiGridKillZonePlugin = XClass(nil, "XUiGridKillZonePlugin")

function XUiGridKillZonePlugin:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    if self.BtnClick then self.BtnClick.CallBack = clickCb end

    self.Effect.gameObject:SetActiveEx(false)
end

function XUiGridKillZonePlugin:Refresh(plugin, isAllPluginEmpty, doNotShowEffect)
    self.Plugin = plugin

    self.PanelEmpty.gameObject:SetActiveEx(isAllPluginEmpty)
    self.PanelPlugin.gameObject:SetActiveEx(not isAllPluginEmpty)

    local icon = plugin:GetIcon()
    self.RImgIcon:SetRawImage(icon)

    local count = plugin:GetCount()
    self.TxtNum.text = "x" .. count

    if not doNotShowEffect and not isAllPluginEmpty then
        self.Effect.gameObject:SetActiveEx(false)
        self.Effect.gameObject:SetActiveEx(true)
    end
end

return XUiGridKillZonePlugin