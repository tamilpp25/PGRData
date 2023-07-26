local XSuperTowerPlugin = require("XEntity/XSuperTower/Plugin/XSuperTowerPlugin")
local XSuperTowerPluginSlotManager = XClass(nil, "XSuperTowerPluginSlotManager")

function XSuperTowerPluginSlotManager:Ctor()
    self.PluginSlots = {}
    self.MaxCapacity = XSuperTowerConfigs.GetBaseConfigByKey("MaxTeamPluginCount")
    self.CurrentCapacity = 0
    self.StageId = nil
end

function XSuperTowerPluginSlotManager:SetStageId(value)
    self.StageId = value
end

function XSuperTowerPluginSlotManager:SetMaxCapacity(value)
    self.MaxCapacity = value
end

function XSuperTowerPluginSlotManager:GetStageId()
    return self.StageId
end
--===========================
--把另一个Slot的内容添加入此Slot
--===========================
function XSuperTowerPluginSlotManager:AddSlot(pluginSlot)
    local addPluginList = pluginSlot:GetPluginsNotSplit()
    if addPluginList and #addPluginList == 0 then return end
    local originPluginList = self:GetPluginsNotSplit()
    local originDic = {}
    for _, originPlugin in pairs(originPluginList) do
        originDic[originPlugin:GetId()] = originPlugin
    end
    self:Clear()
    for _, plugin in pairs(addPluginList) do
        local originPlugin = originDic[plugin:GetId()]
        if originPlugin then
            originPlugin:UpdateCount(originPlugin:GetCount() + plugin:GetCount())
        else
            originDic[plugin:GetId()] = plugin
        end
    end
    for _, newPlugin in pairs(originDic) do
        self:AddPluginById(newPlugin:GetId(), newPlugin:GetCount())
    end
end

function XSuperTowerPluginSlotManager:AddPluginById(pluginId, count)
    if not pluginId then return end
    for i = 1, count do
        local plugin = XSuperTowerPlugin.New(pluginId)
        plugin:UpdateCount(1)
        self:AddPlugin(plugin)
    end
end

-- plugin : XSuperTowerPlugin
function XSuperTowerPluginSlotManager:AddPlugin(plugin, slot)
    if not plugin then return end
    if slot ~= nil then
        if self.PluginSlots[slot] == 0 or self.PluginSlots[slot] == nil then
            self.CurrentCapacity = self.CurrentCapacity + 1
        end
        self.PluginSlots[slot] = plugin
    else
        for i = 1, self.MaxCapacity do
            if self.PluginSlots[i] == 0 or self.PluginSlots[i] == nil then
                self.PluginSlots[i] = plugin
                self.CurrentCapacity = self.CurrentCapacity + 1
                return i
            end
        end
    end
    return slot
end

function XSuperTowerPluginSlotManager:DeletePlugin(slot)
    if slot == nil then return end
    local plugin = self.PluginSlots[slot]
    if plugin then
        self.CurrentCapacity = self.CurrentCapacity - 1
    end
    self.PluginSlots[slot] = 0
end

-- return : { plugin, plugin, 0, plugin }
-- PS: 0是数组的占位符，通过0判断该槽位为nil，直接设置为nil的话到导致数组遍历连续
function XSuperTowerPluginSlotManager:GetPlugins(isCheckBag)
    if isCheckBag then
        local result = XTool.Clone(self.PluginSlots)
        local bagManager = XDataCenter.SuperTowerManager.GetBagManager()
        for i, plugin in ipairs(self.PluginSlots) do
            if type(plugin) == "table" and not bagManager:GetIsHaveData(plugin:GetId()) then
                result[i] = 0
            end
        end
        return result
    end
    return self.PluginSlots
end

function XSuperTowerPluginSlotManager:GetPluginsSplit()
    local result = {}
    for _, plugin in pairs(self.PluginSlots) do
        if type(plugin) == "table" then
            table.insert(result, plugin)
        end
    end
    return result
end

function XSuperTowerPluginSlotManager:GetPluginsNotSplit()
    local result = {}
    local pluginCountDic = {}
    local pluginId
    for _, plugin in pairs(self.PluginSlots) do
        if type(plugin) == "table" then
            pluginId = plugin:GetId()
            pluginCountDic[pluginId] = pluginCountDic[pluginId] or 0
            pluginCountDic[pluginId] = pluginCountDic[pluginId] + plugin:GetCount()
        end
    end
    local plugin
    for pluginId, count in pairs(pluginCountDic) do
        if count > 0 then
            plugin = XSuperTowerPlugin.New(pluginId)
            plugin:UpdateCount(count)
            table.insert(result, plugin)
        end
    end
    return result
end

function XSuperTowerPluginSlotManager:Clear()
    self.PluginSlots = {}
    self.StageId = nil
    self.CurrentCapacity = 0
end

function XSuperTowerPluginSlotManager:GetIsEmpty()
    return self.CurrentCapacity <= 0
    -- if #self.PluginSlots <= 0 then return true end
    -- for _, plugin in ipairs(self.PluginSlots) do
    --     if type(plugin) == "table" then
    --         return false
    --     end
    -- end
    -- return true
end

function XSuperTowerPluginSlotManager:GetCurrentCapacity()
    return self.CurrentCapacity
end

function XSuperTowerPluginSlotManager:GetMaxCapacity()
    return self.MaxCapacity
end

return XSuperTowerPluginSlotManager