--净化加成插件操作弹窗
local XUiAreaWarJingHuaUp = XLuaUiManager.Register(XLuaUi, "UiAreaWarJingHuaUp")

function XUiAreaWarJingHuaUp:OnAwake()
    self.BtnClose.CallBack = function()
        self:Close()
    end
end

function XUiAreaWarJingHuaUp:OnStart(pluginId, viewType)
    self.PluginId = pluginId
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
    if not isUnlock then
        --已解锁则显示”已生效“
        local unlockLevel = XAreaWarConfigs.GetPfLevelByPluginId(pluginId)
        self.TxtLocked.text = CsXTextManagerGetText("AreaWarAreaUnlockPluginPurificationLevel", unlockLevel)
    end
    self.TxtLocked.gameObject:SetActiveEx(not isUnlock)
    
    self.TxtEquipped.gameObject:SetActiveEx(isUnlock)

    self.BtnTakeOff.gameObject:SetActiveEx(false)
    self.BtnEquip.gameObject:SetActiveEx(false)
end

