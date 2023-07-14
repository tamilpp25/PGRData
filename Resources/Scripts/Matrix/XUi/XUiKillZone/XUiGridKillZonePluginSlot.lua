local XUiGridKillZonePluginSlot = XClass(nil, "XUiGridKillZonePluginSlot")

function XUiGridKillZonePluginSlot:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    if self.BtnClick then self.BtnClick.CallBack = function() clickCb(self.Slot) end end

    self:SetSelect(false)
end

function XUiGridKillZonePluginSlot:Refresh(slot)
    self.Slot = slot

    local isLock = not XDataCenter.KillZoneManager.IsPluginSlotUnlock(slot)
    self.BtnClick:SetDisable(isLock)

    if not isLock then
        local pluginId = XDataCenter.KillZoneManager.GetSlotWearingPluginId(slot)
        if XTool.IsNumberValid(pluginId) then
            local icon = XKillZoneConfigs.GetPluginIcon(pluginId)
            self.RImgBuffIcon:SetRawImage(icon)

            self.RImgBuffIcon.gameObject:SetActiveEx(true)
        else
            self.RImgBuffIcon.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridKillZonePluginSlot:SetSelect(value)
    self.BuffSelect.gameObject:SetActiveEx(value)
end

return XUiGridKillZonePluginSlot