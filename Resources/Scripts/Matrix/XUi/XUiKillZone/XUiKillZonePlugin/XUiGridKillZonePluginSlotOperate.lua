local XUiGridKillZonePluginSlotOperate = XClass(nil, "XUiGridKillZonePluginSlotOperate")

function XUiGridKillZonePluginSlotOperate:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self:SetSelect(false)
    if self.BtnClick then self.BtnClick.CallBack = function() clickCb(self.Slot) end end
end

function XUiGridKillZonePluginSlotOperate:Refresh(slot)
    self.Slot = slot

    local isLock = not XDataCenter.KillZoneManager.IsPluginSlotUnlock(slot)
    if not isLock then
        local pluginId = XDataCenter.KillZoneManager.GetSlotWearingPluginId(slot)
        if XTool.IsNumberValid(pluginId) then
            local icon = XKillZoneConfigs.GetPluginIcon(pluginId)
            self.RImgIcon:SetRawImage(icon)

            local name = XKillZoneConfigs.GetPluginName(pluginId)
            self.TxtName.text = name

            local level = XDataCenter.KillZoneManager.GetPluginLevel(pluginId)
            
            self.TxtLevel.text = level

            self.ContainerEmpty.gameObject:SetActiveEx(false)
            self.ContainerItem.gameObject:SetActiveEx(true)
            self.ContainerLock.gameObject:SetActiveEx(false)
        else
            self.ContainerEmpty.gameObject:SetActiveEx(true)
            self.ContainerItem.gameObject:SetActiveEx(false)
            self.ContainerLock.gameObject:SetActiveEx(false)
        end
    else
        local conditionDes = XKillZoneConfigs.GetPluginSlotConditionDesc(slot)
        self.TxtUnlockCondition.text = conditionDes

        self.ContainerLock.gameObject:SetActiveEx(true)
        self.ContainerItem.gameObject:SetActiveEx(false)
        self.ContainerEmpty.gameObject:SetActiveEx(false)
    end
end

function XUiGridKillZonePluginSlotOperate:SetSelect(value)
    self.PanelSelect.gameObject:SetActiveEx(value)
end

return XUiGridKillZonePluginSlotOperate