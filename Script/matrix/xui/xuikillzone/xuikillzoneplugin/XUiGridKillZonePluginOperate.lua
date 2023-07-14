local XUiGridKillZonePluginOperate = XClass(nil, "XUiGridKillZonePluginOperate")

function XUiGridKillZonePluginOperate:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self:SetSelect(false)
    if self.BtnClick then self.BtnClick.CallBack = function() clickCb(self.PluginId, self.Transform) end end
end

function XUiGridKillZonePluginOperate:Refresh(pluginId)
    self.PluginId = pluginId

    local icon = XKillZoneConfigs.GetPluginIcon(pluginId)
    self.RImgIcon:SetRawImage(icon)

    local name = XKillZoneConfigs.GetPluginName(pluginId)
    self.TxtName.text = name

    local levelStr = XDataCenter.KillZoneManager.GetPluginShowLevelStr(pluginId)
    self.TxtLevel.text = levelStr

    self.PanelUnAcitve.gameObject:SetActiveEx(false)
    self.PanelLock.gameObject:SetActiveEx(false)
    self.PanelNormal.gameObject:SetActiveEx(false)

    local isLock = XDataCenter.KillZoneManager.IsPluginLock(pluginId)
    local isUnActive = XDataCenter.KillZoneManager.IsPluginUnActive(pluginId)
    if isLock then
        self:UpdateLock()
    elseif isUnActive then
        self:UpdateUnActive()
    else
        self:UpdateNormal()
    end
end

function XUiGridKillZonePluginOperate:UpdateNormal()
    local pluginId = self.PluginId

    local canLevelUp = XDataCenter.KillZoneManager.IsPluginCanLevelUp(pluginId)
    self.IconUp.gameObject:SetActiveEx(canLevelUp)

    --此处的数目标记是该插件升到下1记得【B货币】消耗的数目，若已升到满级，则显示玩家在此插件消耗的总数目
    if XDataCenter.KillZoneManager.IsPluginMaxLevel(pluginId) then
        local itemId, itemCount = XKillZoneConfigs.GetPluginLevelUpCostTotal(pluginId)
        local icon = XItemConfigs.GetItemIconById(itemId)
        self.RImgCost:SetRawImage(icon)
        self.TxtCost.text = itemCount
    else
        local itemId, itemCount = XDataCenter.KillZoneManager.GetPluginLevelUpCost(pluginId)
        local icon = XItemConfigs.GetItemIconById(itemId)
        self.RImgCost:SetRawImage(icon)
        self.TxtCost.text = itemCount
    end

    local isWearing = XDataCenter.KillZoneManager.IsPluginWearing(pluginId)
    self.PanelWearing.gameObject:SetActiveEx(isWearing)

    self.PanelNormal.gameObject:SetActiveEx(true)
end

function XUiGridKillZonePluginOperate:UpdateLock()
    local pluginId = self.PluginId

    local name = XKillZoneConfigs.GetPluginName(pluginId)
    self.TxtNameLock.text = name

    local itemId, itemCount = XKillZoneConfigs.GetPluginUnlockCost(pluginId)
    local icon = XItemConfigs.GetItemIconById(itemId)
    self.RImgCostLock:SetRawImage(icon)
    self.TxtCostLock.text = itemCount

    self.TxtLevel.gameObject:SetActiveEx(false)
    self.PanelLock.gameObject:SetActiveEx(true)
end

function XUiGridKillZonePluginOperate:UpdateUnActive()
    self.TxtLevel.gameObject:SetActiveEx(true)
    self.PanelUnAcitve.gameObject:SetActiveEx(true)
end

function XUiGridKillZonePluginOperate:SetSelect(value)
    self.TxtLevel.gameObject:SetActiveEx(true)
    self.PanelSelect.gameObject:SetActiveEx(value)
end

return XUiGridKillZonePluginOperate