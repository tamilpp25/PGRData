--净化加成插件操作弹窗
local XUiAreaWarJingHuaUp = XLuaUiManager.Register(XLuaUi, "UiAreaWarJingHuaUp")

function XUiAreaWarJingHuaUp:OnAwake()
    self.BtnClose.CallBack = function()
        self:Close()
    end
    self.BtnTakeOff.CallBack = function()
        self:OnClickBtnTakeOff()
    end
    self.BtnEquip.CallBack = function()
        self:OnClickBtnEquip()
    end
end

function XUiAreaWarJingHuaUp:OnStart(pluginId, slot, viewType)
    self.PluginId = pluginId
    self.Slot = slot
    self.ViewType = viewType or 1
    self:InitView()
    self:Refresh()
end

function XUiAreaWarJingHuaUp:InitView()
    local parent = self["PanelParent" .. self.ViewType]
    self.PanelContent.transform:SetParent(parent.transform)
    self.PanelContent.transform.localPosition = CS.UnityEngine.Vector3.zero
end

function XUiAreaWarJingHuaUp:Refresh()
    local pluginId = self.PluginId

    local buffId = pluginId
    self.RImgBuffIcon:SetRawImage(XAreaWarConfigs.GetBuffIcon(buffId))
    self.TxtName.text = XAreaWarConfigs.GetBuffName(buffId)
    self.TxtDesc.text = XAreaWarConfigs.GetBuffDesc(buffId)

    --已解锁
    local isUnlock = XDataCenter.AreaWarManager.IsPluginUnlock(pluginId)
    if isUnlock then
        local unlockLevel = XAreaWarConfigs.GetPfLevelByPluginId(pluginId)
        self.TxtLocked.text = CsXTextManagerGetText("AreaWarAreaUnlockPluginPurificationLevel", unlockLevel)
    end
    self.TxtLocked.gameObject:SetActiveEx(not isUnlock)

    --使用中
    local isUsing = XDataCenter.AreaWarManager.IsPluginUsing(pluginId)
    self.TxtEquipped.gameObject:SetActiveEx(isUsing)
    self.TxtUnlocked.gameObject:SetActiveEx(isUnlock and not isUsing)

    self.BtnTakeOff.gameObject:SetActiveEx(isUnlock and isUsing)
    self.BtnEquip.gameObject:SetActiveEx(isUnlock and not isUsing)
end

function XUiAreaWarJingHuaUp:OnClickBtnEquip()
    if XDataCenter.AreaWarManager.IsPluginSlotFull() then
        XUiManager.TipText("AreaWarAreaSlotFull")
        return 
    end

    local pluginId = self.PluginId
    local slot = self.Slot
    XDataCenter.AreaWarManager.RequestUsePluginInSlot(
        pluginId,
        slot,
        function()
            self:Close()
        end
    )
end

function XUiAreaWarJingHuaUp:OnClickBtnTakeOff()
    local pluginId = self.PluginId
    local slot = XDataCenter.AreaWarManager.GetPluginUsingSlot(pluginId)
    XDataCenter.AreaWarManager.RequestClearPluginSlot(
        slot,
        function()
            self:Close()
        end
    )
end
