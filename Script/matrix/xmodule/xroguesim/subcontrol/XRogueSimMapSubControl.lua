-- 地图控制器 包括 建筑、道具、事件、城邦
---@class XRogueSimMapSubControl : XControl
---@field private _Model XRogueSimModel
---@field _MainControl XRogueSimControl
local XRogueSimMapSubControl = XClass(XControl, "XRogueSimMapSubControl")
function XRogueSimMapSubControl:OnInit()
    --初始化内部变量
end

function XRogueSimMapSubControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XRogueSimMapSubControl:RemoveAgencyEvent()

end

function XRogueSimMapSubControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

--region 服务器数据相关
-- 获取地图数据
function XRogueSimMapSubControl:GetAreaIds()
    local mapData = self._Model:GetMapData()
    if not mapData then
        return nil
    end
    return mapData:GetAreaIds()
end

-- 获取格子数据
function XRogueSimMapSubControl:GetGridData(gridId)
    local mapData = self._Model:GetMapData()
    if not mapData then
        return nil
    end
    return mapData:GetGridDataById(gridId)
end

-- 获取已探索格子Id列表
function XRogueSimMapSubControl:GetExploredGridIds()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetExploredGridIds()
end

-- 获取额外开放视野的格子列表
function XRogueSimMapSubControl:GetVisibleGridIds()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetVisibleGridIds()
end

--endregion

--region 配置表相关
-- 获取地形配置表
function XRogueSimMapSubControl:GetRogueSimTerrainConfig(id)
    return self._Model:GetRogueSimTerrainConfig(id)
end

-- 获取地貌配置表
function XRogueSimMapSubControl:GetRogueSimLandformConfig(id)
    return self._Model:GetRogueSimLandformConfig(id)
end

-- 获取地貌名称
function XRogueSimMapSubControl:GetLandformName(id)
    local config = self._Model:GetRogueSimLandformConfig(id)
    return config and config.Name or ""
end

-- 获取地貌类型
function XRogueSimMapSubControl:GetLandformLandType(id)
    local config = self._Model:GetRogueSimLandformConfig(id)
    return config and config.LandType or 0
end

-- 获取地貌图片
function XRogueSimMapSubControl:GetLandformIcon(id)
    local config = self._Model:GetRogueSimLandformConfig(id)
    return config and config.Icon or ""
end

-- 获取地貌描述
function XRogueSimMapSubControl:GetLandformDescription(id)
    local config = self._Model:GetRogueSimLandformConfig(id)
    return config and config.Description or ""
end

-- 获取地貌旁边的图标
function XRogueSimMapSubControl:GetLandformSideIcon(id)
    local config = self._Model:GetRogueSimLandformConfig(id)
    return config and config.ModelSideIcon or nil
end

-- 获取区域配置表
function XRogueSimMapSubControl:GetRogueSimAreaConfig(areaId)
    return self._Model:GetRogueSimAreaConfig(areaId)
end

-- 获取地图配置表
function XRogueSimMapSubControl:GetRogueSimAreaGridConfigs(areaId)
    return self._Model:GetRogueSimAreaGridConfigs(areaId)
end

-- 获取区域聚焦格子Id
function XRogueSimMapSubControl:GetRogueSimAreaFocusGridId(areaId)
    local config = self._Model:GetRogueSimAreaConfig(areaId)
    return config and config.FocusGridId or 0
end

--endregion

--region 道具相关

-- 获取已获取道具Ids
function XRogueSimMapSubControl:GetOwnPropInfo()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    local propInfo = {}
    local propData = stageData:GetPropData()
    for _, data in pairs(propData) do
        table.insert(propInfo, { PropId = data:GetPropId(), Id = data:GetId() })
    end
    -- 排序
    table.sort(propInfo, function(a, b)
        local rareA = self:GetPropRare(a.PropId)
        local rareB = self:GetPropRare(b.PropId)
        if rareA ~= rareB then
            return rareA > rareB
        end
        return a.PropId > b.PropId
    end)
    return propInfo
end

-- 获取已获得道具的数量通过道具Id
function XRogueSimMapSubControl:GetOwnPropCountByPropId(propId)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    local propData = stageData:GetPropData()
    local count = 0
    for _, data in pairs(propData) do
        if data:GetPropId() == propId then
            count = count + 1
        end
    end
    return count
end

-- 获取已获得道具的数量通过标签
function XRogueSimMapSubControl:GetOwnPropCountByTag(tag)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    local propData = stageData:GetPropData()
    local count = 0
    for _, data in pairs(propData) do
        if self:GetPropTag(data:GetPropId()) == tag then
            count = count + 1
        end
    end
    return count
end

-- 获取所有道具配置表
function XRogueSimMapSubControl:GetPropConfigs()
    return self._Model:GetRogueSimPropConfigs()
end

-- 获取道具标签
function XRogueSimMapSubControl:GetPropTag(id)
    local config = self._Model:GetRogueSimPropConfig(id)
    return config and config.Tag or ""
end

-- 获取道具名称
function XRogueSimMapSubControl:GetPropName(id)
    local config = self._Model:GetRogueSimPropConfig(id)
    return config and config.Name or ""
end

-- 获取道具描述
function XRogueSimMapSubControl:GetPropDesc(id)
    local config = self._Model:GetRogueSimPropConfig(id)
    return config and config.Desc or ""
end

-- 获取道具效果描述
function XRogueSimMapSubControl:GetPropEffectDesc(id)
    local config = self._Model:GetRogueSimPropConfig(id)
    local desc = config and config.EffectDesc or ""
    return XUiHelper.ReplaceTextNewLine(desc)
end

-- 获取道具图片
function XRogueSimMapSubControl:GetPropIcon(id)
    local config = self._Model:GetRogueSimPropConfig(id)
    return config and config.Icon or ""
end

-- 获取道具持续时间
function XRogueSimMapSubControl:GetPropDuration(id)
    local config = self._Model:GetRogueSimPropConfig(id)
    return config and config.Duration or 0
end

-- 获取道具稀有度
function XRogueSimMapSubControl:GetPropRare(id)
    local config = self._Model:GetRogueSimPropConfig(id)
    return config and config.Rare or 0
end

-- 获取道具BuffIds
function XRogueSimMapSubControl:GetPropBuffIds(id)
    local config = self._Model:GetRogueSimPropConfig(id)
    return config and config.BuffIds or {}
end

-- 获取道具稀有图片
function XRogueSimMapSubControl:GetPropRareIcon(rareId)
    local config = self._Model:GetRogueSimPropRareConfig(rareId)
    return config and config.Path or ""
end

--endregion

--region 事件相关

-- 获取挂起事件自增Ids
function XRogueSimMapSubControl:GetPendingEventIds()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    local eventIds = {}
    local eventData = stageData:GetEventData()
    for _, data in pairs(eventData) do
        table.insert(eventIds, data:GetId())
    end
    return eventIds
end

-- 获取事件信息通过格子Id
function XRogueSimMapSubControl:GetEventDataByGridId(gridId)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetEventDataByGridId(gridId)
end

-- 获取事件配置Id通过自增Id
function XRogueSimMapSubControl:GetEventConfigIdById(id)
    local eventData = self._Model:GetEventDataById(id)
    if not eventData then
        return 0
    end
    return eventData:GetConfigId()
end

-- 获取事件格子Id通过自增Id
function XRogueSimMapSubControl:GetEventGridIdById(id)
    local eventData = self._Model:GetEventDataById(id)
    if not eventData then
        return 0
    end
    return eventData:GetGridId()
end

-- 获取事件名称
function XRogueSimMapSubControl:GetEventName(id)
    local config = self._Model:GetRogueSimEventConfig(id)
    return config and config.Name or ""
end

-- 获取事件描述
function XRogueSimMapSubControl:GetEventText(id)
    local config = self._Model:GetRogueSimEventConfig(id)
    local desc = config and config.Text or ""
    return XUiHelper.ReplaceTextNewLine(desc)
end

-- 获取事件挂起描述
function XRogueSimMapSubControl:GetEventSuspendDesc(id)
    local config = self._Model:GetRogueSimEventConfig(id)
    local desc = config and config.SuspendDesc or ""
    return XUiHelper.ReplaceTextNewLine(desc)
end

-- 获取事件存在回合数
-- 为0表示不会过期
-- 不为0时表示事件可以延后N个回合进行处理
function XRogueSimMapSubControl:GetEventDuration(id)
    local config = self._Model:GetRogueSimEventConfig(id)
    return config and config.Duration or 0
end

-- 获取事件选项Id列表
function XRogueSimMapSubControl:GetEventOptionIds(id)
    local config = self._Model:GetRogueSimEventConfig(id)
    return config and config.OptionIds or {}
end

-- 获取事件选项名称
function XRogueSimMapSubControl:GetEventOptionName(id)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.Name or ""
end

-- 获取事件选项描述
function XRogueSimMapSubControl:GetEventOptionDesc(id)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.Desc or ""
end

-- 获取事件选项条件id
function XRogueSimMapSubControl:GetEventOptionCondition(id)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.Condition or 0
end

-- 获取事件选项消耗资源Id列表
function XRogueSimMapSubControl:GetEventOptionCostResourceIds(id)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.CostResourceIds or {}
end

-- 获取事件选项消耗资源数量列表
function XRogueSimMapSubControl:GetEventOptionCostResourceCounts(id)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.CostResourceCounts or {}
end

-- 获取事件选项消耗货物Id列表
function XRogueSimMapSubControl:GetEventOptionCostCommodityIds(id)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.CostCommodityIds or {}
end

-- 获取事件选项消耗货物数量列表
function XRogueSimMapSubControl:GetEventOptionCostCommodityCounts(id)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.CostCommodityCounts or {}
end

-- 获取事件选项效果Id列表
function XRogueSimMapSubControl:GetEventOptionEffectIds(id)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.EffectIds or {}
end

-- 获取事件选项下个事件id
function XRogueSimMapSubControl:GetEventOptionNextEventId(id)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.NextEventId or 0
end

-- 获取剩余回合数
---@param id number 事件自增Id
function XRogueSimMapSubControl:GetEventRemainingDuration(id)
    local eventData = self._Model:GetEventDataById(id)
    if not eventData then
        return 0
    end
    local duration = self:GetEventDuration(eventData:GetConfigId())
    local curTurn = self._MainControl:GetCurTurnNumber()
    local createTurn = eventData:GetCreateTurnNumber()
    return duration - (curTurn - createTurn)
end

-- 获取事件选项资源消耗数据
function XRogueSimMapSubControl:GetEventOptionCostResourceInfos(optionId)
    local infos = {}
    local costResourceIds = self:GetEventOptionCostResourceIds(optionId)
    if XTool.IsTableEmpty(costResourceIds) then
        return infos
    end
    local costResourceCounts = self:GetEventOptionCostResourceCounts(optionId)
    for index, id in ipairs(costResourceIds) do
        table.insert(infos, {
            Id = id,
            Count = costResourceCounts[index] or 0,
        })
    end
    return infos
end

-- 获取事件选项货物消耗数据
function XRogueSimMapSubControl:GetEventOptionCostCommodityInfos(optionId)
    local infos = {}
    local costCommodityIds = self:GetEventOptionCostCommodityIds(optionId)
    if XTool.IsTableEmpty(costCommodityIds) then
        return infos
    end
    local costCommodityCounts = self:GetEventOptionCostCommodityCounts(optionId)
    for index, id in ipairs(costCommodityIds) do
        table.insert(infos, {
            Id = id,
            Count = costCommodityCounts[index] or 0,
        })
    end
    return infos
end

-- 检查是否是限时事件（duration > 0）
---@param configId number 事件配置Id
function XRogueSimMapSubControl:CheckIsEventDuration(configId)
    local duration = self:GetEventDuration(configId)
    return duration > 0
end

-- 检查是否是限时事件（duration > 0）通过自增Id
---@param id number 事件自增Id
function XRogueSimMapSubControl:CheckIsEventDurationById(id)
    local configId = self:GetEventConfigIdById(id)
    return self:CheckIsEventDuration(configId)
end

-- 检查事件id是否是当前回合必须处理(限时事件、剩余回合数等于1)
---@param id number 事件自增Id
function XRogueSimMapSubControl:CheckEventIsMustHandle(id)
    if not self:CheckIsEventDurationById(id) then
        return false
    end
    local remainingDuration = self:GetEventRemainingDuration(id)
    return remainingDuration == 1
end

-- 检查是否有挂起事件必须处理
function XRogueSimMapSubControl:CheckHasPendingEvent()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return false
    end
    local eventData = stageData:GetEventData()
    for _, data in pairs(eventData) do
        if self:CheckEventIsMustHandle(data:GetId()) then
            return true
        end
    end
    return false
end

-- 检查事件选项条件是否满足
function XRogueSimMapSubControl:CheckEventOptionCondition(optionId)
    local conditionId = self:GetEventOptionCondition(optionId)
    -- 无条件默认满足
    if not XTool.IsNumberValid(conditionId) then
        return true, ""
    end
    return self._MainControl.ConditionSubControl:CheckCondition(conditionId)
end

-- 获取事件选项的effectId类型为1和15的数据
function XRogueSimMapSubControl:GetEventOptionEffectInfos(optionId)
    local infos = {}
    local effectIds = self:GetEventOptionEffectIds(optionId)
    if XTool.IsTableEmpty(effectIds) then
        return infos
    end
    for _, id in ipairs(effectIds) do
        local effectType = self._MainControl.BuffSubControl:GetEffectType(id)
        if effectType == XEnumConst.RogueSim.EffectType.Commodity or effectType == XEnumConst.RogueSim.EffectType.Resource then
            local params = self._MainControl.BuffSubControl:GetEffectParams(id)
            local data = {}
            data.ItemId = params[1]
            data.Num = params[2]
            -- 货物
            if effectType == XEnumConst.RogueSim.EffectType.Commodity then
                data.Type = XEnumConst.RogueSim.RewardType.Commodity
            end
            -- 资源
            if effectType == XEnumConst.RogueSim.EffectType.Resource then
                data.Type = XEnumConst.RogueSim.RewardType.Resource
            end
            table.insert(infos, data)
        end
    end
    return infos
end

--endregion

--region 建筑相关

-- 获取已获得建筑自增Ids
function XRogueSimMapSubControl:GetOwnBuildingIds()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    local buildingIds = {}
    local buildingData = stageData:GetBuildingData()
    for _, data in pairs(buildingData) do
        table.insert(buildingIds, data:GetId())
    end
    return buildingIds
end

-- 获取未购买建筑自增Ids
function XRogueSimMapSubControl:GetUnBuyBuildingIds()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    local buildingIds = {}
    local buildingData = stageData:GetBuildingData()
    for _, data in pairs(buildingData) do
        if not data:CheckIsBuy() then
            table.insert(buildingIds, data:GetId())
        end
    end
    return buildingIds
end

-- 获取建筑数据通过格子Id
function XRogueSimMapSubControl:GetBuildingDataByGridId(gridId)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetBuildingDataByGridId(gridId)
end

-- 获取建筑数据通过自增Id
function XRogueSimMapSubControl:GetBuildingDataById(id)
    return self._Model:GetBuildingDataById(id)
end

-- 获取建筑Id通过自增Id
function XRogueSimMapSubControl:GetBuildingConfigIdById(id)
    local buildingData = self._Model:GetBuildingDataById(id)
    if not buildingData then
        return 0
    end
    return buildingData:GetConfigId()
end

-- 检查建筑是否购买通过自增Id
function XRogueSimMapSubControl:CheckBuildingIsBuyById(id)
    local buildingData = self._Model:GetBuildingDataById(id)
    if not buildingData then
        return false
    end
    return buildingData:CheckIsBuy()
end

-- 检查是否有建筑数据
function XRogueSimMapSubControl:CheckHasBuildingData()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return false
    end
    local buildingData = stageData:GetBuildingData()
    return not XTool.IsTableEmpty(buildingData)
end

-- 获取所有建筑配置表
function XRogueSimMapSubControl:GetBuildingConfigs()
    return self._Model:GetRogueSimBuildingConfigs()
end

-- 获取建筑名称
function XRogueSimMapSubControl:GetBuildingName(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.Name or ""
end

-- 获取建筑描述
function XRogueSimMapSubControl:GetBuildingDesc(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    local desc = config and config.Desc or ""
    return XUiHelper.ReplaceTextNewLine(desc)
end

-- 获取建筑地貌Id
function XRogueSimMapSubControl:GetBuildingLandformId(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.LandformId or 0
end

-- 获取建筑图片
function XRogueSimMapSubControl:GetBuildingIcon(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.Icon or ""
end

-- 获取建筑地貌
function XRogueSimMapSubControl:GetBuildingLandformId(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.LandformId or 0
end

-- 获取建筑标志
function XRogueSimMapSubControl:GetBuildingTag(id)
    local landformId = self:GetBuildingLandformId(id)
    return self:GetLandformSideIcon(landformId)
end

-- 获取建筑传闻Id
function XRogueSimMapSubControl:GetBuildingTipId(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.TipId or 0
end

-- 获取建筑购买消耗资源Id列表
function XRogueSimMapSubControl:GetBuildingCostResourceIds(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.CostResourceIds or {}
end

-- 获取建筑购买消耗资源数量列表
function XRogueSimMapSubControl:GetBuildingCostResourceCounts(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.CostResourceCounts or {}
end

-- 获取建筑购买消耗金币数量
---@param id number 建筑配置Id
function XRogueSimMapSubControl:GetBuyBuildingCostGoldCount(id)
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    local costResourceIds = self:GetBuildingCostResourceIds(id)
    local costResourceCounts = self:GetBuildingCostResourceCounts(id)
    local contain, index = table.contains(costResourceIds, goldId)
    if contain then
        local costResourceCount = costResourceCounts[index] or 0
        return self._MainControl.BuffSubControl:GetBuildingDiscountPrice(costResourceCount)
    end
    return 0
end

-- 检查购买建筑金币是否充足
---@param id number 建筑配置Id
function XRogueSimMapSubControl:CheckBuyBuildingGoldIsEnough(id)
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    local curGold = self._MainControl.ResourceSubControl:GetResourceOwnCount(goldId)
    local costGold = self:GetBuyBuildingCostGoldCount(id)
    return curGold >= costGold
end

-- 检查未购买建筑红点
function XRogueSimMapSubControl:CheckUnBuyBuildingsRedPoint()
    local ids = self:GetUnBuyBuildingIds()
    if XTool.IsTableEmpty(ids) then
        return false
    end
    for _, id in ipairs(ids) do
        if self:CheckBuildingRedPoint(id) then
            return true
        end
    end
    return false
end

-- 检查建筑红点（未购买和金币充足）
---@param id number 建筑自增Id
function XRogueSimMapSubControl:CheckBuildingRedPoint(id)
    local isBuy = self:CheckBuildingIsBuyById(id)
    if isBuy then
        return false
    end
    local configId = self:GetBuildingConfigIdById(id)
    return self:CheckBuyBuildingGoldIsEnough(configId)
end

--endregion

--region 城邦相关

-- 获取已获得城邦Id
function XRogueSimMapSubControl:GetOwnCityIds()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    local cityIds = {}
    local cityData = stageData:GetCityData()
    for _, data in pairs(cityData) do
        if data:GetIsExplored() then
            table.insert(cityIds, data:GetId())
        end
    end
    -- 未完成额外任务 > 建立联系的先后顺序
    table.sort(cityIds, function(a, b)
        local taskIdA = self:GetCityTaskIdById(a)
        local taskIdB = self:GetCityTaskIdById(b)
        local isFinishA = self._MainControl:CheckTaskIsFinished(taskIdA)
        local isFinishB = self._MainControl:CheckTaskIsFinished(taskIdB)
        if isFinishA ~= isFinishB then
            return isFinishB
        end
        return a < b
    end)
    return cityIds
end

-- 获取已探索城邦数量
function XRogueSimMapSubControl:GetOwnCityCount()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    local cityData = stageData:GetCityData()
    local count = 0
    for _, data in pairs(cityData) do
        if data:GetIsExplored() then
            count = count + 1
        end
    end
    return count
end

-- 获取已探索城邦配置Id
function XRogueSimMapSubControl:GetOwnCityConfigIds()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    local cityIds = {}
    local cityData = stageData:GetCityData()
    for _, data in pairs(cityData) do
        if data:GetIsExplored() then
            table.insert(cityIds, data:GetConfigId())
        end
    end
    return cityIds
end

-- 获取城邦数据通过格子Id
function XRogueSimMapSubControl:GetCityDataByGridId(gridId)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetCityDataByGridId(gridId)
end

-- 获取城邦配置Id通过自增Id
function XRogueSimMapSubControl:GetCityConfigIdById(id)
    local cityData = self._Model:GetCityDataById(id)
    if not cityData then
        return 0
    end
    return cityData:GetConfigId()
end

-- 获取城邦任务自增Id通过自增Id
---@return number 任务自增Id
function XRogueSimMapSubControl:GetCityTaskIdById(id)
    local cityData = self._Model:GetCityDataById(id)
    if not cityData then
        return 0
    end
    return cityData:GetTaskId()
end

-- 获取城邦名称
function XRogueSimMapSubControl:GetCityName(id)
    local config = self._Model:GetRogueSimCityConfig(id)
    return config and config.Name or ""
end

-- 获取城邦简略描述
function XRogueSimMapSubControl:GetCityBriefDesc(id)
    local config = self._Model:GetRogueSimCityConfig(id)
    return config and config.BriefDesc or ""
end

-- 获取城邦描述
function XRogueSimMapSubControl:GetCityDesc(id)
    local config = self._Model:GetRogueSimCityConfig(id)
    local desc = config and config.Desc or ""
    return XUiHelper.ReplaceTextNewLine(desc)
end

-- 获取城邦图片
function XRogueSimMapSubControl:GetCityIcon(id)
    local config = self._Model:GetRogueSimCityConfig(id)
    return config and config.Icon or ""
end

-- 获取城邦BuffIds
function XRogueSimMapSubControl:GetCityBuffIds(id)
    local config = self._Model:GetRogueSimCityConfig(id)
    return config and config.BuffIds or {}
end

-- 获取城邦地貌
function XRogueSimMapSubControl:GetCityLandformId(id)
    local config = self._Model:GetRogueSimCityConfig(id)
    return config and config.LandformId or 0
end

-- 获取城邦标志
function XRogueSimMapSubControl:GetCityTag(id)
    local landformId = self:GetCityLandformId(id)
    return self:GetLandformSideIcon(landformId)
end

--endregion

--region 点位探索相关

-- 点位探索
---@param rewardData XRogueSimReward
---@param cityId number 城邦自增Id
function XRogueSimMapSubControl:ExploreGrid(rewardData, cityId)
    if rewardData then
        if XTool.IsTableEmpty(rewardData.Rewards) then
            local tips = self._MainControl:GetClientConfig("ExploreFail")
            XUiManager.TipError(tips)
            self._MainControl:PlayCacheExploreGrids()
            return
        end
        if rewardData.Pick then
            self._MainControl:ShowRewardPopup(rewardData.Rewards[1])
        else
            self._MainControl:ShowPropSelectPopup(rewardData.GridId, rewardData.Source)
        end
    elseif XTool.IsNumberValid(cityId) then
        self:ExploreCityGrid(cityId)
    else
        XLog.Error("XRogueSimMapSubControl:ExploreGrid rewardData and cityId is empty!")
    end
end

-- 道具点位探索
---@param id number 奖励自增Id
function XRogueSimMapSubControl:ExplorePropGrid(id)
    if not XTool.IsNumberValid(id) then
        return
    end
    -- 检查是否有道具选择数据避免选择界面信息为空
    local rewardData = self._Model:GetRewardDataById(id)
    if not rewardData then
        return
    end
    -- 作弊获得的道具没有格子Id
    if rewardData:GetSource() == XEnumConst.RogueSim.SourceType.Cheat then
        XLuaUiManager.Open("UiRogueSimChoose", id, true)
        return
    end
    local gridId = rewardData:GetGridId()
    self._MainControl:CameraFocusGrid(gridId, function()
        XLuaUiManager.Open("UiRogueSimChoose", id, true)
    end)
end

-- 事件点位探索
---@param id number 事件自增Id
function XRogueSimMapSubControl:ExploreEventGrid(id)
    if not XTool.IsNumberValid(id) then
        return
    end
    local gridId = self:GetEventGridIdById(id)
    if not XTool.IsNumberValid(gridId) then
        return
    end
    self._MainControl:CameraFocusGrid(gridId, function()
        XLuaUiManager.Open("UiRogueSimOutpost", id)
    end)
end

-- 建筑点位探索
---@param id number 建筑自增Id
function XRogueSimMapSubControl:ExploreBuildingGrid(id)
    if not XTool.IsNumberValid(id) then
        return
    end
    local buildingData = self:GetBuildingDataById(id)
    if not buildingData then
        return
    end

    local gridId = buildingData:GetGridId()
    local inCache = self._MainControl:CheckHasExploreCache(gridId)
    if inCache then
        self._MainControl:PlayCacheExploreGrids(gridId, function()
            XLuaUiManager.Open("UiRogueSimChoose", id, false)
        end)
    else
        self._MainControl:CameraFocusGrid(gridId, function()
            XLuaUiManager.Open("UiRogueSimChoose", id, false)
        end)
    end
end

-- 城邦点位探索
---@param id number 城邦自增Id
function XRogueSimMapSubControl:ExploreCityGrid(id)
    if not XTool.IsNumberValid(id) then
        return
    end
    ---@type XUiRogueSimBattle
    local luaUi = XLuaUiManager.GetTopLuaUi("UiRogueSimBattle")
    if luaUi then
        luaUi:OpenFindCity(id)
    end
end

--endregion


--退出界面后记录相机上次滑动到的位置（本次登录有效）
local _LastCameraFollowPointPos

-- 获取相机跟随点最后位置
function XRogueSimMapSubControl:GetLastCameraFollowPointPos()
    return _LastCameraFollowPointPos
end

-- 记录相机跟随点最后位置
function XRogueSimMapSubControl:SaveLastCameraFollowPointPos(pos)
    _LastCameraFollowPointPos = pos
end

function XRogueSimMapSubControl:ClearLastCameraFollowPointPos()
    _LastCameraFollowPointPos = nil
end

return XRogueSimMapSubControl
