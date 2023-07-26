--动态列表的格子
local XUiDeployDynamicGrid = XClass(nil, "XUiDeployDynamicGrid")

local State2Color = {
    Enough    = CS.UnityEngine.Color.white,
    NotEnough = XUiHelper.Hexcolor2Color("FC8686"),
}

function XUiDeployDynamicGrid:Ctor(ui, openDetailCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.OpenDetailCb = openDetailCb

    self:InitCb()

    self.BaseInfo = XDataCenter.DoubleTowersManager.GetBaseInfo()
    self.TeamDb = self.BaseInfo:GetTeamDb()
    self.Loaded = XUiHelper.TryGetComponent(self.Transform, "loaded", "Transform")
end

function XUiDeployDynamicGrid:InitCb()

    self.BtnLock.CallBack = function ()
        if not XTool.IsNumberValid(self.PluginId) then
            return
        end
        --XLuaUiManager.Open("UiDoubleTowersSkillDetails", self.PluginId, handler(self, self.Refresh))
        if self.OpenDetailCb then
            self.OpenDetailCb(self)
        end
    end
end

function XUiDeployDynamicGrid:Refresh(pluginId)
    self.PluginId = pluginId
    local pluginLevelId = self.BaseInfo:GetPluginLevelId(pluginId)
    local defaultPluginLevelId
    local unlocked = XTool.IsNumberValid(pluginLevelId)
    --未解锁
    if not unlocked then
        defaultPluginLevelId = self.BaseInfo:GetPluginLevelDefaultId(pluginId)
        --一级消耗
        local spendCost = XDoubleTowersConfigs.GetPluginLevelUpgradeSpend(defaultPluginLevelId)
        --无消耗，则直接解锁
        local showLock = XTool.IsNumberValid(spendCost)
        self.BtnLock.gameObject:SetActiveEx(showLock)
        if showLock then
            local itemId = XDoubleTowersConfigs.GetActivityRewardItemId()
            self.LockIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
            self.LockDesc.text = spendCost
            local hasCoin = XDataCenter.ItemManager.GetCount(itemId)
            self.LockDesc.color = hasCoin >= spendCost and State2Color.Enough or State2Color.NotEnough
        end
    else
        self.BtnLock.gameObject:SetActiveEx(false)
    end
    pluginLevelId = unlocked and pluginLevelId or defaultPluginLevelId
    local isEquip, _  = self.TeamDb:IsEquipPlugin(self.PluginId)
    self.Loaded.gameObject:SetActiveEx(isEquip)
    --图标
    local icon = XDoubleTowersConfigs.GetPluginIcon(pluginId)
    self.PartnerIcon:SetRawImage(icon)
    --名字
    self.Name.text = XDoubleTowersConfigs.GetPluginLevelName(pluginLevelId)
    --等级
    self.TxtSubSkillLevel.text = XDoubleTowersConfigs.GetPluginLevel(pluginLevelId)
    --描述
    self.Desc.text = XDoubleTowersConfigs.GetPluginDesc(pluginId)
end

function XUiDeployDynamicGrid:GetPluginId()
    return self.PluginId
end

function XUiDeployDynamicGrid:SetSelect(isSelect)
    self.Selected.gameObject:SetActiveEx(isSelect)
end

return XUiDeployDynamicGrid