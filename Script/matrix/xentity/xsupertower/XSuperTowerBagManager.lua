local XCollectionManager = require("XEntity/XSuperTower/XCollectionManager")
local XSuperTowerPlugin = require("XEntity/XSuperTower/Plugin/XSuperTowerPlugin")
local XSuperTowerBagManager = XClass(XCollectionManager, "XSuperTowerBagManager")

local SortByPriority = function(pluginA, pluginB)
    return pluginA:GetPriority() < pluginB:GetPriority()
end

function XSuperTowerBagManager:Ctor()
    -- 图鉴数据
    self.PokedexPluginDic = {}
    self.PluginSynthesisQueue = XQueue.New()
    self.BagMaxCapacityUpdate = false
    -- self:InitServerApi()
end

-- data : StBagInfo
function XSuperTowerBagManager:InitWithServerData(data)
    -- 更新背包容量
    self:UpdateMaxCapacity(data.Capacity)
    -- 更新背包插件
    -- pluginInfo : StPluginInfo
    for _, pluginInfo in ipairs(data.PluginInfos) do
        self:AddPlugin(pluginInfo)
    end
end

-- data : StPluginInfo
function XSuperTowerBagManager:AddPlugin(data)
    -- 增加图鉴标志
    self.PokedexPluginDic[data.Id] = true
    if data.Count > 0 then
        local plugin = XSuperTowerPlugin.New(data.Id)
        plugin:InitWithServerData(data)
        self:AddData(plugin)
    end
end

function XSuperTowerBagManager:DeletePlugin(id, count)
    local plugin = self:GetPlugin(id)
    plugin:UpdateCount(plugin:GetCount() - count)
    if plugin:GetCount() <= 0 then
        self:DeleteData(id)
    end
end

function XSuperTowerBagManager:GetPlugins(isAscendOrder)
    local pluginsNotSplit = self:GetDatas()
    local result = {}
    local tmpPlugin = nil
    for _, plugin in ipairs(pluginsNotSplit) do
        for i = 1, plugin:GetCount() do
            tmpPlugin = XSuperTowerPlugin.New(plugin:GetId())
            tmpPlugin:UpdateCount(1)
            table.insert(result, tmpPlugin)
        end
    end
    if isAscendOrder ~= nil then
        local ascendWeight = -1
        if isAscendOrder then
            ascendWeight = 1
        end
        table.sort(result, function(pluginA, pluginB)
            local sortWeigthA = ascendWeight * (pluginA:GetId() + pluginA:GetQuality() * 100000000)
            local sortWeigthB = ascendWeight * (pluginB:GetId() + pluginB:GetQuality() * 100000000)
            return sortWeigthA > sortWeigthB
        end)
    end
    return result
end

function XSuperTowerBagManager:GetPluginsByPrior()
    local pluginsNotSplit = self:GetDatas()
    local result = {}
    local tmpPlugin = nil
    for _, plugin in ipairs(pluginsNotSplit) do
        for i = 1, plugin:GetCount() do
            tmpPlugin = XSuperTowerPlugin.New(plugin:GetId())
            tmpPlugin:UpdateCount(1)
            table.insert(result, tmpPlugin)
        end
    end
    table.sort(result, SortByPriority)
    return result
end

function XSuperTowerBagManager:GetPlugin(id)
    return self:GetData(id)
end


-- 根据插件id来更新数量
function XSuperTowerBagManager:UpdatePluginCount(pluginId, count)
    local plugin = self:GetData(pluginId)
    plugin:UpdateCount(count)
    if plugin:GetCount() <= 0 then
        self:DeleteData(plugin:GetId())
    end
end

function XSuperTowerBagManager:UpdatePluginDic(pluginDic)
    for pluginId, count in pairs(pluginDic) do
        self:UpdatePluginCount(pluginId, count)
    end
end

function XSuperTowerBagManager:UpdateMaxCapacity(value)
    if self.MaxCapacity > 0 then
        if not self.LastMaxCapacity then
            self.LastMaxCapacity = self.MaxCapacity
        end
        self.BagMaxCapacityUpdate = true
    end
    self.MaxCapacity = value
end

function XSuperTowerBagManager:CheckMaxCapacityUpdate()
    if self.BagMaxCapacityUpdate then
        self.BagMaxCapacityUpdate = false
        local last = self.LastMaxCapacity
        self.LastMaxCapacity = nil
        return true, last, self:GetMaxCapacity()
    end
    return false
end

function XSuperTowerBagManager:GetCurrentCapacity()
    local allPlugins = self:GetPlugins()
    local result = 0
    for _, plugin in pairs(allPlugins) do
        result = result + plugin:GetCapacity()
    end
    return result
end

function XSuperTowerBagManager:PluginSynEnqueue(oldList, newList)
    local data = {
            Old = oldList,
            New = newList,
        } 
    self.PluginSynthesisQueue:Enqueue(data)
end

function XSuperTowerBagManager:GetPluginSyn()
    if self.PluginSynthesisQueue:IsEmpty() then
        return nil
    end
    local data = self.PluginSynthesisQueue:Dequeue()
    return data and data.Old or nil, data and data.New or nil
end

-- starGroup : { [star] = true, ... }
function XSuperTowerBagManager:GetPluginsWithStarFilter(starGroup, isAscendOrder)
    local plugins = self:GetPlugins(isAscendOrder)
    local result = {}
    for _, plugin in ipairs(plugins) do
        if starGroup[plugin:GetStar()] then
            table.insert(result, plugin)
        end
    end
    return result
end

function XSuperTowerBagManager:CheckHasPluginWithStarFilter(star)
    local plugins = self:GetPlugins()
    for _, plugin in ipairs(plugins) do
        if plugin:GetStar() <= star then
            return true
        end
    end
    return false
end

function XSuperTowerBagManager:GetCapacityPercentsByStar(star)
    local plugins = self:GetDatas()
    local starTotalCapacity = 0
    -- local totalCapacity = 0
    for _, plugin in ipairs(plugins) do
        -- totalCapacity = totalCapacity + plugin:GetCapacity()
        if plugin:GetStar() == star then
            starTotalCapacity = starTotalCapacity + plugin:GetCapacity()
        end
    end
    -- if totalCapacity == 0 then return totalCapacity end
    return getRoundingValue(starTotalCapacity / self:GetMaxCapacity(), 3)
end

-- 获取图鉴插件数组
-- return 1 : 已获得的图鉴插件
-- return 2 : 未获得的图鉴插件
function XSuperTowerBagManager:GetIllusPluginList(filter)
    --[[local pluginConfigs = XSuperTowerConfigs.GetAllPluginCfgs()
    local result1 = {} -- 已获得的图鉴插件
    local result2 = {} -- 未获得的图鉴插件
    local plugin
    for _, config in pairs(pluginConfigs) do
        plugin = XSuperTowerPlugin.New(config.Id)
        if self.PokedexPluginDic[plugin:GetId()] then
            table.insert(result1, plugin)
        else
            table.insert(result2, plugin)
        end
    end
    return result1, result2]]  --注释掉需要区分历史有无获得过的条件
    local pluginConfigs = XSuperTowerConfigs.GetAllPluginCfgs()
    local result = {}
    local noFilter = true
    if filter and next(filter) then noFilter = false end
    for _, config in pairs(pluginConfigs) do
        if config.IsShowInLibrary and config.IsShowInLibrary > 0 then
            if not noFilter and filter[config.Quality] then
                local plugin = XSuperTowerPlugin.New(config.Id)
                table.insert(result, plugin)
            elseif noFilter then
                local plugin = XSuperTowerPlugin.New(config.Id)
                table.insert(result, plugin)
            end
        end
    end
    table.sort(result, SortByPriority)
    return result
end

function XSuperTowerBagManager:RequestResolvePlugin(resolveDic)
    local requestData = {
        ResolveDic = resolveDic,
    }
    XMessagePack.MarkAsTable(requestData.ResolveDic)
    -- res : StResolvePluginResponse(RewardGoodsList)
    XNetwork.Call("StResolvePluginRequest", requestData, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        XUiManager.OpenUiObtain(res.RewardGoodsList)
    end)
end

--######################## 私有方法 ########################

-- function XSuperTowerBagManager:InitServerApi()
--     -- 背包最大容量
--     XRpc.NotifyStBagCapacity = function(data)
--         self:UpdateMaxCapacity(data.Capacity)
--     end
--     -- 背包插件更新
--     XRpc.NotifyStBagPluginChange = function(data)
--         self:OnBagPluginChange(data)
--     end
--     -- 通知背包插件合成数据
--     -- data : List<StPluginSynthesisInfo>
--     XRpc.NotifyStBagPluginSynthesisData = function(pluginSynthesisInfos)
--         self:OnBagPluginSynthesisData(pluginSynthesisInfos)
--     end
-- end

function XSuperTowerBagManager:OnBagPluginChange(data)
    -- List<StPluginInfo> Id && Count
    local changePluginInfos = data.ChangePluginInfos
    local plugin
    for _, pluginInfo in ipairs(changePluginInfos) do
        -- 删除变化
        if pluginInfo.Count <= 0 then
            self:DeleteData(pluginInfo.Id)
        else
            plugin = self:GetData(pluginInfo.Id)
            -- 更新变化
            if plugin then
                plugin:UpdateWithServerData(pluginInfo)
            else -- 增加变化
                self:AddPlugin(pluginInfo)
            end
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_ST_PLUGIN_REFRESH)
end

function XSuperTowerBagManager:OnBagPluginSynthesisData(pluginSynthesisInfos)
    local result1 = {} -- 旧的插件数据
    local result2 = {} -- 新的插件数据
    --对比旧列表和新列表中重复的ID数量插件，去掉（此为多次合成的中途插件，最终不显示）
    local oldPluginDic = {}
    for _, pluginSynthesisInfo in pairs(pluginSynthesisInfos.SynthesisInfos) do
        if pluginSynthesisInfo.Id and pluginSynthesisInfo.Id > 0 and not oldPluginDic[pluginSynthesisInfo.Id] then
            oldPluginDic[pluginSynthesisInfo.Id] = pluginSynthesisInfo
        end
    end
    for _, pluginSynthesisInfo in pairs(pluginSynthesisInfos.SynthesisInfos) do
        if pluginSynthesisInfo.NewId and pluginSynthesisInfo.NewId > 0 and oldPluginDic[pluginSynthesisInfo.NewId] then
            for i = 1, pluginSynthesisInfo.NewCount do
                oldPluginDic[pluginSynthesisInfo.NewId].Count = oldPluginDic[pluginSynthesisInfo.NewId].Count - 1
            end
            pluginSynthesisInfo.NewCount = 0
        end
    end
    --记录处理后的新旧合成列表
    local tmpPlugin
    for _, pluginSynthesisInfo in ipairs(pluginSynthesisInfos.SynthesisInfos) do
        -- 旧插件数据
        for i = 1, pluginSynthesisInfo.Count do
            tmpPlugin = XSuperTowerPlugin.New(pluginSynthesisInfo.Id)
            tmpPlugin:UpdateCount(1)
            table.insert(result1, tmpPlugin)
        end
        -- 新插件数据
        for i = 1, pluginSynthesisInfo.NewCount do
            tmpPlugin = XSuperTowerPlugin.New(pluginSynthesisInfo.NewId)
            tmpPlugin:UpdateCount(1)
            table.insert(result2, tmpPlugin)
        end
    end

    XDataCenter.SuperTowerManager.GetBagManager():PluginSynEnqueue(result1, result2)
end

return XSuperTowerBagManager