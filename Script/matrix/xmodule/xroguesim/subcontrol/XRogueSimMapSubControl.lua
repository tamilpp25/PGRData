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

-- 获取地图相关数据
---@return XRogueSimMap
function XRogueSimMapSubControl:GetMapData()
    return self._Model:GetMapData()
end

-- 获取已探索格子Id列表
function XRogueSimMapSubControl:GetExploredGridIds()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetExploredGridIds()
end

-- 获取指定类型已探索格子列表
function XRogueSimMapSubControl:GetSpExploredGridIds()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetSpExploredGridIds()
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

-- 获取区域解锁UI放置的格子Id
function XRogueSimMapSubControl:GetRogueSimAreaUnlockUiGridId(areaId)
    local config = self._Model:GetRogueSimAreaConfig(areaId)
    return config and config.UnlockUiGridId or 0
end

-- 获取区域解锁UI的位置偏移
function XRogueSimMapSubControl:GetRogueSimAreaUnlockUiPos(areaId)
    local config = self._Model:GetRogueSimAreaConfig(areaId)
    return config and config.UnlockUiPos or 0
end

-- 获取区域解锁消耗的金币数
function XRogueSimMapSubControl:GetRogueSimAreaUnlockCost(areaId)
    local config = self._Model:GetRogueSimAreaConfig(areaId)
    return config and config.UnlockCost or 0
end

-- 获取区域解锁奖励的经验
function XRogueSimMapSubControl:GetRogueSimAreaUnlockExpReward(areaId)
    local config = self._Model:GetRogueSimAreaConfig(areaId)
    return config and config.UnlockExpReward or 0
end

-- 获取区域的名称
function XRogueSimMapSubControl:GetRogueSimAreaName(areaId)
    local name = ""
    local config = self._Model:GetRogueSimAreaConfig(areaId)
    if config and config.Texts and #config.Texts > 0 then
        for _, text in ipairs(config.Texts) do
            name = name .. text
        end
    end
    return name
end

-- 获取区域的名称Texts数组
function XRogueSimMapSubControl:GetRogueSimAreaTexts(areaId)
    local config = self._Model:GetRogueSimAreaConfig(areaId)
    return config and config.Texts or {}
end

-- 获取区域的名称对应格子Id数组
function XRogueSimMapSubControl:GetRogueSimAreaTextGridIds(areaId)
    local config = self._Model:GetRogueSimAreaConfig(areaId)
    return config and config.TextGridIds or {}
end

--endregion

--region 区域相关

-- 获取可购买区域的格子Ids
function XRogueSimMapSubControl:GetCanBuyAreaGridIds()
    -- 已解锁未获得的区域Ids
    local unlockNotObtainAreaIds = self:GetUnlockNotObtainAreaIds()
    local gridIds = {}
    for _, areaId in pairs(unlockNotObtainAreaIds) do
        if self:CheckAreaBuyGoldIsEnough(areaId) then
            local gridId = self:GetRogueSimAreaFocusGridId(areaId)
            if XTool.IsNumberValid(gridId) then
                table.insert(gridIds, gridId)
            end
        end
    end
    table.sort(gridIds, function(a, b)
        return a < b
    end)
    return gridIds
end

-- 获取区域购买需要的金币数量
---@param areaId number 区域Id
function XRogueSimMapSubControl:GetBuyAreaCostGoldCount(areaId)
    -- 配置的价格
    local costGoldCount = self:GetRogueSimAreaUnlockCost(areaId)
    -- 打折后的价格
    return self._MainControl.BuffSubControl:GetAreaDiscountPrice(areaId, costGoldCount)
end

-- 获取已解锁未获得的区域Id列表
function XRogueSimMapSubControl:GetUnlockNotObtainAreaIds()
    local mapData = self:GetMapData()
    if not mapData then
        return {}
    end
    return mapData:GetUnlockNotObtainAreaIds()
end

-- 获取已获得区域的数量
function XRogueSimMapSubControl:GetObtainAreaCount()
    local mapData = self:GetMapData()
    if not mapData then
        return 0
    end
    return mapData:GetObtainAreaCount()
end

-- 获取已获得区域的Id列表
function XRogueSimMapSubControl:GetObtainAreaIds()
    local mapData = self:GetMapData()
    if not mapData then
        return {}
    end
    -- 已获得的区域Ids
    local areaIds = mapData:GetObtainAreaIds()
    -- 排序 1.可升级的城邦 2.城邦自增Id 3.区域Id
    table.sort(areaIds, function(a, b)
        local cityDataA = self:GetCityDataByAreaId(a)
        local cityDataB = self:GetCityDataByAreaId(b)
        if cityDataA and cityDataB then
            local isCanUpgradeA = self:CheckCityCanLevelUp(cityDataA:GetId())
            local isCanUpgradeB = self:CheckCityCanLevelUp(cityDataB:GetId())
            if isCanUpgradeA ~= isCanUpgradeB then
                return isCanUpgradeA
            end
            return cityDataA:GetId() < cityDataB:GetId()
        end
        local isCityDataA = cityDataA and 1 or 0
        local isCityDataB = cityDataB and 1 or 0
        if isCityDataA ~= isCityDataB then
            return isCityDataA > isCityDataB
        end
        return a < b
    end)
    return areaIds
end

-- 获取指定类型已探索格子数量
---@param areaId number 区域Id 0表示所有区域
function XRogueSimMapSubControl:GetSpExploredGridCount(areaId)
    local spExploredGridIds = self:GetSpExploredGridIds()
    if not spExploredGridIds then
        return 0
    end
    if areaId == 0 then
        return table.nums(spExploredGridIds)
    end
    local count = 0
    for _, gridId in pairs(spExploredGridIds) do
        if self._MainControl:GetAreaIdByGridId(gridId) == areaId then
            count = count + 1
        end
    end
    return count
end

-- 检查区域是否已解锁
---@param areaId number 区域Id
function XRogueSimMapSubControl:CheckAreaIsUnlock(areaId)
    local mapData = self:GetMapData()
    if not mapData then
        return false
    end
    local areaData = mapData:GetAreaData(areaId)
    return areaData and areaData:GetIsUnlock() or false
end

-- 检查区域购买金币是否充足
---@param areaId number 区域Id
---@param isShowTip boolean 是否显示提示
function XRogueSimMapSubControl:CheckAreaBuyGoldIsEnough(areaId, isShowTip)
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    local costGoldCount = self:GetBuyAreaCostGoldCount(areaId)
    return self._MainControl.ResourceSubControl:CheckResourceIsEnough(goldId, costGoldCount, isShowTip)
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
    return config and config.Tag or 0
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

-- 获取道具显示标签列表
function XRogueSimMapSubControl:GetPropShowLabels(id)
    local config = self._Model:GetRogueSimPropConfig(id)
    return config and config.ShowLabels or {}
end

-- 获取道具显示的分数
---@param id number 道具Id
---@param commodityId number 货物Id
function XRogueSimMapSubControl:GetPropShowScore(id, commodityId)
    local config = self._Model:GetRogueSimPropConfig(id)
    local scores = config and config.ShowScores or {}
    return scores[commodityId] or 0
end

-- 获取道具实际的分数
---@param id number 道具Id
---@param commodityId number 货物Id
function XRogueSimMapSubControl:GetPropActualScore(id, commodityId)
    local config = self._Model:GetRogueSimPropConfig(id)
    local scores = config and config.ActualScores or {}
    return scores[commodityId] or 0
end

-- 获取道具稀有图片
function XRogueSimMapSubControl:GetPropRareIcon(rareId)
    local config = self._Model:GetRogueSimPropRareConfig(rareId)
    return config and config.Path or ""
end

-- 获取道具显示标签背景颜色
function XRogueSimMapSubControl:GetPropShowLabelColor(tagId)
    local config = self._Model:GetRogueSimPropShowLabelConfig(tagId)
    return config and config.BgColor or ""
end

-- 获取道具显示标签描述
function XRogueSimMapSubControl:GetPropShowLabelDesc(tagId)
    local config = self._Model:GetRogueSimPropShowLabelConfig(tagId)
    return config and config.Desc or ""
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
    -- 排序
    table.sort(eventIds, function(a, b)
        local isDurEventA = self:CheckIsEventDurationById(a) and 1 or 0
        local isDurEventB = self:CheckIsEventDurationById(a) and 1 or 0
        if isDurEventA ~= isDurEventB then
            return isDurEventA > isDurEventB
        end
        return a < b
    end)
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

-- 获取事件奖励Id通过自增Id
function XRogueSimMapSubControl:GetEventRewardIdById(id)
    local eventData = self._Model:GetEventDataById(id)
    if not eventData then
        return 0
    end
    return eventData:GetRewardId()
end

-- 获取事件类型
function XRogueSimMapSubControl:GetEventType(id)
    local config = self._Model:GetRogueSimEventConfig(id)
    return config and config.EventType or 0
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

-- 获取事件选项消耗资源比例列表
function XRogueSimMapSubControl:GetEventOptionCostResourceRates(id)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.CostResourceRates or {}
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

-- 获取事件选项消耗货物比例列表
function XRogueSimMapSubControl:GetEventOptionCostCommodityRates(id)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.CostCommodityRates or {}
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

-- 获取事件选项投机奖励率
function XRogueSimMapSubControl:GetEventOptionGambleRewardRates(id, index)
    local config = self._Model:GetRogueSimEventOptionConfig(id)
    return config and config.GambleRewardRates[index] or 0
end

-- 获取剩余回合数
---@param id number 事件自增Id
function XRogueSimMapSubControl:GetEventRemainingDuration(id)
    local eventData = self._Model:GetEventDataById(id)
    if not eventData then
        return 0
    end
    local curTurn = self._MainControl:GetCurTurnNumber()
    local curDeadlineTurnNumber = eventData:GetCurDeadlineTurnNumber()
    return curDeadlineTurnNumber - curTurn
end

-- 获取事件选项资源消耗数据
function XRogueSimMapSubControl:GetEventOptionCostResourceInfos(optionId)
    local infos = {}
    local costResourceIds = self:GetEventOptionCostResourceIds(optionId)
    if XTool.IsTableEmpty(costResourceIds) then
        return infos
    end
    local costResourceCounts = self:GetEventOptionCostResourceCounts(optionId)
    local costResourceRates = self:GetEventOptionCostResourceRates(optionId)
    for index, id in ipairs(costResourceIds) do
        table.insert(infos, {
            Id = id,
            Count = costResourceCounts[index] or 0,
            Rate = costResourceRates[index] or 0,
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
    local costCommodityRates = self:GetEventOptionCostCommodityRates(optionId)
    for index, id in ipairs(costCommodityIds) do
        table.insert(infos, {
            Id = id,
            Count = costCommodityCounts[index] or 0,
            Rate = costCommodityRates[index] or 0,
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

-- 检查事件id是否是当前回合必须处理(限时事件、剩余回合数小于等于1)
---@param id number 事件自增Id
function XRogueSimMapSubControl:CheckEventIsMustHandle(id)
    if not self:CheckIsEventDurationById(id) then
        return false
    end
    local remainingDuration = self:GetEventRemainingDuration(id)
    return remainingDuration <= 1
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

-- 获取事件选项的effectId类型为1、15、16的数据
function XRogueSimMapSubControl:GetEventOptionEffectInfos(optionId)
    local infos = {}
    local effectIds = self:GetEventOptionEffectIds(optionId)
    if XTool.IsTableEmpty(effectIds) then
        return infos
    end
    for _, id in ipairs(effectIds) do
        local effectType = self._MainControl.BuffSubControl:GetEffectType(id)
        if effectType == self._Model.EffectType.Type1 or effectType == self._Model.EffectType.Type15 or effectType == self._Model.EffectType.Type16 then
            local params = self._MainControl.BuffSubControl:GetEffectParams(id)
            local data = {}
            data.ItemId = params[1]
            data.Num = params[2]
            -- 货物
            if effectType == self._Model.EffectType.Type1 then
                data.Type = XEnumConst.RogueSim.RewardType.Commodity
            end
            -- 资源
            if effectType == self._Model.EffectType.Type15 then
                data.Type = XEnumConst.RogueSim.RewardType.Resource
            end
            -- 建筑蓝图
            if effectType == self._Model.EffectType.Type16 then
                data.Type = XEnumConst.RogueSim.RewardType.BuildBluePrint
            end
            table.insert(infos, data)
        end
    end
    return infos
end

--endregion

--region 事件投机相关

-- 获取可领取的事件投机的自增Ids
function XRogueSimMapSubControl:GetCanGetEventGambleIds()
    local eventGambleData = self:GetEventGambleData()
    if not eventGambleData then
        return {}
    end
    local curTurnNumber = self._MainControl:GetCurTurnNumber()
    local eventGambleIds = {}
    for _, data in pairs(eventGambleData) do
        if curTurnNumber >= data:GetRewardTurnNumber() then
            table.insert(eventGambleIds, data:GetId())
        end
    end
    table.sort(eventGambleIds, function(a, b)
        return a < b
    end)
    return eventGambleIds
end

-- 获取事件投机数据
function XRogueSimMapSubControl:GetEventGambleData()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetEventGambleData()
end

-- 获取事件投机数据通过格子Id
function XRogueSimMapSubControl:GetEventGambleDataByGridId(gridId)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetEventGambleDataByGridId(gridId)
end

-- 获取事件投机数据通过自增Id
function XRogueSimMapSubControl:GetEventGambleDataById(id)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetEventGambleDataById(id)
end

-- 获取事件投机格子ID通过自增Id
---@param id number 事件投机自增Id
function XRogueSimMapSubControl:GetEventGambleGridIdById(id)
    local eventGambleData = self:GetEventGambleDataById(id)
    if not eventGambleData then
        return 0
    end
    return eventGambleData:GetGridId()
end

-- 获取事件选择Id和奖励比例索引通过自增Id
---@param id number 事件投机自增Id
function XRogueSimMapSubControl:GetEventGambleOptionIdAndRewardRateIndexById(id)
    local eventGambleData = self:GetEventGambleDataById(id)
    if not eventGambleData then
        return 0, -1
    end
    return eventGambleData:GetEventOptionId(), eventGambleData:GetRewardRateIndex()
end

-- 获取事件可领奖励回合数通过自增Id
---@param id number 事件投机自增Id
function XRogueSimMapSubControl:GetEventGambleRewardTurnNumberById(id)
    local eventGambleData = self:GetEventGambleDataById(id)
    if not eventGambleData then
        return 0
    end
    return eventGambleData:GetRewardTurnNumber()
end

-- 获取返还的资源数据通过自增Id
---@param id number 事件投机自增Id
function XRogueSimMapSubControl:GetReturnResourceInfosById(id)
    local infos = {}
    local eventOptionId, rewardRateIndex = self:GetEventGambleOptionIdAndRewardRateIndexById(id)
    if eventOptionId <= 0 or rewardRateIndex <= 0 then
        return infos
    end
    local eventGambleData = self:GetEventGambleDataById(id)
    if not eventGambleData then
        return infos
    end
    local costResourceIds = eventGambleData:GetCostResourceIds()
    if XTool.IsTableEmpty(costResourceIds) then
        return infos
    end
    -- 返还奖励比例
    local rewardRate = self:GetEventOptionGambleRewardRates(eventOptionId, rewardRateIndex)
    local costResourceCounts = eventGambleData:GetCostResourceCounts()
    for index, resourceId in pairs(costResourceIds) do
        local costCount = costResourceCounts[index] or 0
        local returnCount = math.ceil(costCount * rewardRate / XEnumConst.RogueSim.Denominator)
        if returnCount > 0 then
            table.insert(infos, { Id = resourceId, Count = returnCount })
        end
    end
    return infos
end

-- 获取返还的货物数据通过自增Id
---@param id number 事件投机自增Id
function XRogueSimMapSubControl:GetReturnCommodityInfosById(id)
    local infos = {}
    local eventOptionId, rewardRateIndex = self:GetEventGambleOptionIdAndRewardRateIndexById(id)
    if eventOptionId <= 0 or rewardRateIndex <= 0 then
        return infos
    end
    local eventGambleData = self:GetEventGambleDataById(id)
    if not eventGambleData then
        return infos
    end
    local costCommodityIds = eventGambleData:GetCostCommodityIds()
    if XTool.IsTableEmpty(costCommodityIds) then
        return infos
    end
    -- 返还奖励比例
    local rewardRate = self:GetEventOptionGambleRewardRates(eventOptionId, rewardRateIndex)
    local costCommodityCounts = eventGambleData:GetCostCommodityCounts()
    for index, commodityId in pairs(costCommodityIds) do
        local costCount = costCommodityCounts[index] or 0
        local returnCount = math.ceil(costCount * rewardRate / XEnumConst.RogueSim.Denominator)
        if returnCount > 0 then
            table.insert(infos, { Id = commodityId, Count = returnCount })
        end
    end
    return infos
end

-- 获取可领取的事件投机数据通过格子Id
function XRogueSimMapSubControl:GetCanGetEventGambleDataByGridId(gridId)
    local eventGambleData = self:GetEventGambleDataByGridId(gridId)
    if not eventGambleData then
        return nil
    end
    local curTurnNumber = self._MainControl:GetCurTurnNumber()
    if curTurnNumber < eventGambleData:GetRewardTurnNumber() then
        return nil
    end
    return eventGambleData
end

-- 检查是否有事件投机奖励可领取
function XRogueSimMapSubControl:CheckHasEventGambleReward()
    local eventGambleData = self:GetEventGambleData()
    if not eventGambleData then
        return false
    end
    local curTurnNumber = self._MainControl:GetCurTurnNumber()
    for _, data in pairs(eventGambleData) do
        if curTurnNumber >= data:GetRewardTurnNumber() then
            return true
        end
    end
    return false
end

--endregion

--region 建筑相关

-- 获取建筑数据
function XRogueSimMapSubControl:GetBuildingData()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    return stageData:GetBuildingData()
end

-- 获取已获得建筑自增Ids
function XRogueSimMapSubControl:GetOwnBuildingIds()
    local buildingIds = {}
    local buildingData = self:GetBuildingData()
    for _, data in pairs(buildingData) do
        table.insert(buildingIds, data:GetId())
    end
    table.sort(buildingIds, function(a, b)
        return a < b
    end)
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

-- 获取建筑数量
---@param areaType number 区域类型
---@param areaId number 区域Id
---@param buildId number 建筑Id
function XRogueSimMapSubControl:GetBuildingsCountByAreaId(areaType, areaId, buildId)
    local buildingData = self:GetBuildingData()
    local count = 0
    for _, data in pairs(buildingData) do
        local gridId = data:GetGridId()
        local matchesArea = (areaType == self._Model.ObtainBuildingAreaType.AllArea) or (self._MainControl:GetAreaIdByGridId(gridId) == areaId)
        local matchesBuild = ((buildId == 0) or (data:GetConfigId() == buildId)) and data:GetIsBuildByBluePrint()
        if matchesArea and matchesBuild then
            count = count + 1
        end
    end
    return count
end

-- 检查是否有建筑数据
function XRogueSimMapSubControl:CheckHasBuildingData()
    local buildingData = self:GetBuildingData()
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
    local descParam = self:GetBuildingDescParam(id)
    if descParam > 0 then
        local addParam = self._MainControl.BuffSubControl:GetBuildingOutputCount(id, descParam)
        desc = XUiHelper.FormatText(desc, addParam)
    end
    return XUiHelper.ReplaceTextNewLine(desc)
end

-- 获取建筑描述参数
function XRogueSimMapSubControl:GetBuildingDescParam(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.DescParam or 0
end

-- 获取建筑描述图标
function XRogueSimMapSubControl:GetBuildingDescIcon(id, index)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.DescIcon[index] or ""
end

-- 获取建筑图片
function XRogueSimMapSubControl:GetBuildingIcon(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.Icon or ""
end

-- 获取建筑类型
function XRogueSimMapSubControl:GetBuildingType(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.Type or 0
end

-- 获取建筑品质
function XRogueSimMapSubControl:GetBuildingQuality(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.Quality or 1
end

-- 获取建筑品质图标
function XRogueSimMapSubControl:GetBuildingQualityIcon(id)
    local quality = self:GetBuildingQuality(id)
    return self._MainControl:GetClientConfig("BuildingQualityIcon", quality)
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

-- 获取建筑奖励组Id
function XRogueSimMapSubControl:GetBuildingRefreshRewardGroupId(id)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    return config and config.RefreshRewardGroupId or 0
end

-- 获取建筑显示的分数
---@param id number 建筑Id
---@param commodityId number 货物Id
function XRogueSimMapSubControl:GetBuildingShowScore(id, commodityId)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    local scores = config and config.ShowScores or {}
    return scores[commodityId] or 0
end

-- 获取建筑实际的分数
---@param id number 建筑Id
---@param commodityId number 货物Id
function XRogueSimMapSubControl:GetBuildingActualScore(id, commodityId)
    local config = self._Model:GetRogueSimBuildingConfig(id)
    local scores = config and config.ActualScores or {}
    return scores[commodityId] or 0
end

--endregion

--region 自建建筑相关

-- 获取自建建筑蓝图数据
---@return XRogueSimBuildingBluePrint[]
function XRogueSimMapSubControl:GetBuildingBluePrintData()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    return stageData:GetBuildingBluePrintData()
end

-- 获取自建建筑蓝图数量
---@param id number 自建建筑蓝图Id
function XRogueSimMapSubControl:GetBuildingBluePrintCount(id)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetBuildingBluePrintCount(id)
end

-- 获取自建建筑蓝图Ids
function XRogueSimMapSubControl:GetBuildingBluePrintIds()
    local ids = {}
    local buildingBluePrintData = self:GetBuildingBluePrintData()
    for _, data in pairs(buildingBluePrintData) do
        if data:GetCount() > 0 then
            table.insert(ids, data:GetId())
        end
    end
    table.sort(ids, function(a, b)
        return a < b
    end)
    return ids
end

-- 获取自建建筑建造消耗金币数量
---@param id number 自建建筑蓝图Id
function XRogueSimMapSubControl:GetBuildingBluePrintCostGoldCount(id)
    -- 免费建造次数
    local freeBuildCount = self._MainControl.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.FreeBuildCount)
    if freeBuildCount > 0 then
        return 0
    end
    -- 建筑Id
    local buildingId = self:GetBuildingIdByBluePrintId(id)
    -- 配置的金币数量
    local costGoldCount = self:GetCostGoldCountByBluePrintId(id)
    -- 折扣后的金币数量
    return self._MainControl.BuffSubControl:GetBuildingDiscountPrice(buildingId, costGoldCount)
end

-- 检查自建建筑建造金币是否充足
---@param id number 自建建筑蓝图Id
------@param isShowTips boolean 是否显示提示
function XRogueSimMapSubControl:CheckBuildingBluePrintGoldIsEnough(id, isShowTips)
    local goldId = XEnumConst.RogueSim.ResourceId.Gold
    local costGold = self:GetBuildingBluePrintCostGoldCount(id)
    return self._MainControl.ResourceSubControl:CheckResourceIsEnough(goldId, costGold, isShowTips)
end

-- 获取自建建筑有新增的蓝图Id列表
function XRogueSimMapSubControl:GetBuildingBluePrintNewIdList()
    local isSave = false
    local newList = {}
    local buildingBluePrintData = self:GetBuildingBluePrintData()
    local buildingBluePrintRecord = self._MainControl:GetBuildingBluePrintRecord()
    for _, data in pairs(buildingBluePrintData) do
        local id = data:GetId()
        local count = data:GetCount()
        local recordCount = buildingBluePrintRecord[id] or 0
        if count ~= recordCount then
            isSave = true
        end
        if count > recordCount then
            newList[id] = true
        end
    end
    if isSave then
        self._MainControl:SaveBuildingBluePrintRecord()
    end
    return newList
end

-- 获取可建造建筑的地图格子Id列表
function XRogueSimMapSubControl:GetBuildableGridIds()
    -- 背包有未建造的建筑蓝图
    local buildingBluePrintIds = self:GetBuildingBluePrintIds()
    if XTool.IsTableEmpty(buildingBluePrintIds) then
        return nil
    end
    -- 建筑蓝图消耗的金币是否满足
    local isGoldEnough = false
    for _, id in ipairs(buildingBluePrintIds) do
        if self:CheckBuildingBluePrintGoldIsEnough(id) then
            isGoldEnough = true
            break
        end
    end
    if not isGoldEnough then
        return nil
    end
    -- 地图上有空的可建造格子
    local girdIds = self._MainControl.RogueSimScene:GetGridIdsByLandformType(XEnumConst.RogueSim.LandformType.BuildingField)
    table.sort(girdIds, function(a, b)
        return a < b
    end)
    return girdIds
end

-- 获取自建建筑Id通过蓝图Id
---@param id number 自建建筑蓝图Id
function XRogueSimMapSubControl:GetBuildingIdByBluePrintId(id)
    local config = self._Model:GetRogueSimBuildingBluePrintConfig(id)
    return config and config.BuildingId or 0
end

-- 获取建造消耗金币数量(配置的金币数量)
---@param id number 自建建筑蓝图Id
function XRogueSimMapSubControl:GetCostGoldCountByBluePrintId(id)
    local config = self._Model:GetRogueSimBuildingBluePrintConfig(id)
    return config and config.CostGoldCount or 0
end

-- 获取建筑蓝图图标
---@param id number 自建建筑蓝图Id
function XRogueSimMapSubControl:GetBuildingBluePrintIcon(id)
    local config = self._Model:GetRogueSimBuildingBluePrintConfig(id)
    return config and config.Icon or ""
end

--endregion

--region 城邦等级相关

-- 获取所有城邦数据
function XRogueSimMapSubControl:GetCityData()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    return stageData:GetCityData()
end

-- 获取已获得城邦自增Id
function XRogueSimMapSubControl:GetOwnCityIds()
    local cityData = self:GetCityData()
    local cityIds = {}
    for _, data in pairs(cityData) do
        if data:GetIsExplored() then
            table.insert(cityIds, data:GetId())
        end
    end
    -- 排序 1.可升级 2.未满级 3 自增Id
    table.sort(cityIds, function(a, b)
        local isCanLevelUpA = self:CheckCityCanLevelUp(a)
        local isCanLevelUpB = self:CheckCityCanLevelUp(b)
        if isCanLevelUpA ~= isCanLevelUpB then
            return isCanLevelUpA
        end
        local isMaxLevelA = self:CheckCityIsMaxLevel(a)
        local isMaxLevelB = self:CheckCityIsMaxLevel(b)
        if isMaxLevelA ~= isMaxLevelB then
            return isMaxLevelB
        end
        return a < b
    end)
    return cityIds
end

-- 获取已探索城邦数量
function XRogueSimMapSubControl:GetOwnCityCount()
    local cityData = self:GetCityData()
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
    local cityData = self:GetCityData()
    local cityIds = {}
    for _, data in pairs(cityData) do
        if data:GetIsExplored() then
            table.insert(cityIds, data:GetConfigCityId())
        end
    end
    return cityIds
end

-- 获取城邦数据
---@param id number 城邦自增Id
function XRogueSimMapSubControl:GetCityDataById(id)
    return self._Model:GetCityDataById(id)
end

-- 获取城邦数据通过格子Id
---@param gridId number 格子Id
function XRogueSimMapSubControl:GetCityDataByGridId(gridId)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetCityDataByGridId(gridId)
end

-- 获取城邦数据通过区域Id
---@param areaId number 区域Id
function XRogueSimMapSubControl:GetCityDataByAreaId(areaId)
    if not self._MainControl.RogueSimScene then
        return nil
    end
    local cityData = self:GetCityData()
    for _, data in pairs(cityData) do
        local gird = self._MainControl.RogueSimScene:GetGrid(data:GetGridId())
        if gird and gird.AreaId == areaId then
            return data
        end
    end
    return nil
end

-- 获取城邦配置Id通过自增Id
---@param id number 城邦自增Id
function XRogueSimMapSubControl:GetCityConfigIdById(id)
    local cityData = self._Model:GetCityDataById(id)
    if not cityData then
        return 0
    end
    return cityData:GetConfigCityId()
end

-- 获取城邦任务自增Ids通过自增Id
---@param id number 城邦自增Id
---@return number[] 任务自增Ids
function XRogueSimMapSubControl:GetCityTaskIdsById(id)
    local cityData = self._Model:GetCityDataById(id)
    if not cityData then
        return {}
    end
    return cityData:GetTaskIds()
end

-- 获取城邦等级通过自增Id
---@param id number 城邦自增Id
function XRogueSimMapSubControl:GetCityLevelById(id)
    local cityData = self:GetCityDataById(id)
    if not cityData then
        return 0
    end
    return cityData:GetLevel()
end

-- 获取城邦格子Id通过自增Id
---@param id number 城邦自增Id
function XRogueSimMapSubControl:GetCityGridIdById(id)
    local cityData = self:GetCityDataById(id)
    if not cityData then
        return 0
    end
    return cityData:GetGridId()
end

-- 获取城邦是否已探索通过自增Id
---@param id number 城邦自增Id
function XRogueSimMapSubControl:GetCityIsExploredById(id)
    local cityData = self:GetCityDataById(id)
    if not cityData then
        return false
    end
    return cityData:GetIsExplored()
end

-- 获取城邦等级通过配置Id
---@param configId number 城邦配置Id
function XRogueSimMapSubControl:GetCityLevelByConfigId(configId)
    local cityData = self:GetCityData()
    for _, data in pairs(cityData) do
        if data:GetConfigCityId() == configId then
            return data:GetLevel()
        end
    end
    return 0
end

-- 获取所有城邦总等级
function XRogueSimMapSubControl:GetAllCityTotalLevel()
    local cityData = self:GetCityData()
    local totalLevel = 0
    for _, data in pairs(cityData) do
        if data:GetIsExplored() then
            totalLevel = totalLevel + data:GetLevel()
        end
    end
    return totalLevel
end

-- 获取城邦最大等级通过自增Id
---@param id number 城邦自增Id
function XRogueSimMapSubControl:GetCityMaxLevelById(id)
    local configCityId = self:GetCityConfigIdById(id)
    local cityLevelGroup = self._MainControl:GetCurStageCityLevelGroup()
    return self._Model:GetMaxCityLevel(cityLevelGroup, configCityId)
end

-- 获取城邦等级列表通过自增Id
---@param id number 城邦自增Id
function XRogueSimMapSubControl:GetCityLevelIdListById(id)
    local configCityId = self:GetCityConfigIdById(id)
    local cityLevelGroup = self._MainControl:GetCurStageCityLevelGroup()
    return self._Model:GetCityLevelIdList(cityLevelGroup, configCityId)
end

-- 获取城邦等级配置Id通过自增Id
---@param id number 城邦自增Id
function XRogueSimMapSubControl:GetCityLevelConfigIdById(id, level)
    local configCityId = self:GetCityConfigIdById(id)
    local cityLevelGroup = self._MainControl:GetCurStageCityLevelGroup()
    return self._Model:GetCityLevelConfigId(cityLevelGroup, configCityId, level)
end

-- 获取城邦未完成的任务自增Id列表
---@param id number 城邦自增Id
function XRogueSimMapSubControl:GetCityUnfinishedTaskIds(id)
    local taskIds = self:GetCityTaskIdsById(id)
    local unfinishedTaskIds = {}
    for _, taskId in pairs(taskIds) do
        if not self._MainControl:CheckTaskIsFinished(taskId) then
            table.insert(unfinishedTaskIds, taskId)
        end
    end
    table.sort(unfinishedTaskIds, function(a, b)
        return a < b
    end)
    return unfinishedTaskIds
end

-- 获取任务未完成的城邦自增Id列表
function XRogueSimMapSubControl:GetTaskUnfinishedCityIds()
    local cityData = self:GetCityData()
    local cityIds = {}
    for _, data in pairs(cityData) do
        if data:GetIsExplored() then
            local taskIds = data:GetTaskIds()
            local isFinished = true
            for _, taskId in pairs(taskIds) do
                if not self._MainControl:CheckTaskIsFinished(taskId) then
                    isFinished = false
                    break
                end
            end
            if not isFinished then
                table.insert(cityIds, data:GetId())
            end
        end
    end
    table.sort(cityIds, function(a, b)
        return a < b
    end)
    return cityIds
end

-- 获取可升级的城邦自增Id列表
function XRogueSimMapSubControl:GetCityCanLevelUpIds()
    local cityData = self:GetCityData()
    local cityIds = {}
    for _, data in pairs(cityData) do
        if data:GetIsExplored() and self:CheckCityCanLevelUp(data:GetId()) then
            table.insert(cityIds, data:GetId())
        end
    end
    table.sort(cityIds, function(a, b)
        return a < b
    end)
    return cityIds
end

-- 获取城邦任务未完成或者可升级的城邦自增Id列表
function XRogueSimMapSubControl:GetCityTaskUnfinishedOrCanLevelUpIds()
    local taskUnfinishedCityIds = self:GetTaskUnfinishedCityIds()
    local canLevelUpIds = self:GetCityCanLevelUpIds()
    -- 合并数据
    local cityIds = XTool.MergeArray(canLevelUpIds, taskUnfinishedCityIds)
    -- 去重
    return table.unique(cityIds, true)
end

-- 检查城邦是否已满级
---@param id number 城邦自增Id
function XRogueSimMapSubControl:CheckCityIsMaxLevel(id)
    local cityLevel = self:GetCityLevelById(id)
    local maxLevel = self:GetCityMaxLevelById(id)
    return cityLevel >= maxLevel
end

-- 检查城邦是否可升级
---@param id number 城邦自增Id
function XRogueSimMapSubControl:CheckCityCanLevelUp(id)
    -- 检测城邦是否已购买
    if not self:GetCityIsExploredById(id) then
        return false, self._MainControl:GetClientConfig("CityLevelCanLevelUpTips", 1)
    end
    -- 已满级
    if self:CheckCityIsMaxLevel(id) then
        return false, self._MainControl:GetClientConfig("CityLevelCanLevelUpTips", 2)
    end
    -- 任务未完成
    local taskIds = self:GetCityTaskIdsById(id)
    for _, taskId in pairs(taskIds) do
        if not self._MainControl:CheckTaskIsFinished(taskId) then
            return false, self._MainControl:GetClientConfig("CityLevelCanLevelUpTips", 3)
        end
    end
    return true, ""
end

-- 获取城邦等级表的配置等级
---@param id number 城邦等级表Id
function XRogueSimMapSubControl:GetCityLevelConfigLevel(id)
    local config = self._Model:GetRogueSimCityLevelConfig(id)
    return config and config.Level or 0
end

function XRogueSimMapSubControl:GetCityLevelName(id)
    local config = self._Model:GetRogueSimCityLevelConfig(id)
    return config and config.Name or ""
end

function XRogueSimMapSubControl:GetCityLevelDesc(id)
    local config = self._Model:GetRogueSimCityLevelConfig(id)
    local desc = config and config.Desc or ""
    return XUiHelper.ReplaceTextNewLine(desc)
end

function XRogueSimMapSubControl:GetCityLevelIcon(id)
    local config = self._Model:GetRogueSimCityLevelConfig(id)
    return config and config.Icon or ""
end

function XRogueSimMapSubControl:GetCityLevelBriefDesc(id)
    local config = self._Model:GetRogueSimCityLevelConfig(id)
    return config and config.BriefDesc or ""
end

function XRogueSimMapSubControl:GetCityLevelFlagIcon(id)
    local config = self._Model:GetRogueSimCityLevelConfig(id)
    return config and config.FlagIcon or ""
end

function XRogueSimMapSubControl:GetCityLevelBuffDesc(id)
    local config = self._Model:GetRogueSimCityLevelConfig(id)
    local desc = config and config.BuffDesc or ""
    return XUiHelper.ReplaceTextNewLine(desc)
end

function XRogueSimMapSubControl:GetCityLevelUnlockExpReward(id)
    local config = self._Model:GetRogueSimCityLevelConfig(id)
    return config and config.UnlockExpReward or 0
end

function XRogueSimMapSubControl:GetCityLevelLandformId(id)
    local config = self._Model:GetRogueSimCityLevelConfig(id)
    return config and config.LandformId or 0
end

-- 获取城邦显示的分数
---@param id number 城邦等级表Id
---@param commodityId number 货物Id
function XRogueSimMapSubControl:GetCityLevelShowScore(id, commodityId)
    local config = self._Model:GetRogueSimCityLevelConfig(id)
    local scores = config and config.ShowScores or {}
    return scores[commodityId] or 0
end

-- 获取城邦实际的分数
---@param id number 城邦等级表Id
---@param commodityId number 货物Id
function XRogueSimMapSubControl:GetCityLevelActualScore(id, commodityId)
    local config = self._Model:GetRogueSimCityLevelConfig(id)
    local scores = config and config.ActualScores or {}
    return scores[commodityId] or 0
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
            self._MainControl.RogueSimScene:PlayCacheExploreGrids()
            return
        end
        if rewardData.Pick then
            self._MainControl:ShowRewardPopup(rewardData.Rewards[1])
        else
            self._MainControl:ShowPropSelectPopup(rewardData.GridId, rewardData.Source)
        end
    elseif XTool.IsNumberValid(cityId) then
        XLog.Error(string.format("ExploreGrid cityId:%s", cityId))
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
    -- 临时背包和作弊获得的道具没有格子Id
    if rewardData:GetSource() == XEnumConst.RogueSim.SourceType.TemporaryReward or rewardData:GetSource() == XEnumConst.RogueSim.SourceType.Cheat then
        XLuaUiManager.Open("UiRogueSimChoose", id)
        return
    end
    local gridId = rewardData:GetGridId()
    self._MainControl:CameraFocusGrid(gridId, function()
        XLuaUiManager.Open("UiRogueSimChoose", id)
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

-- 事件投机点位点击
---@param id number 事件投机自增Id
function XRogueSimMapSubControl:EventGambleGridClick(id)
    if not XTool.IsNumberValid(id) then
        return
    end
    local gridId = self:GetEventGambleGridIdById(id)
    if not XTool.IsNumberValid(gridId) then
        return
    end
    self._MainControl:CameraFocusGrid(gridId, function()
        XLuaUiManager.Open("UiRogueSimPopupCommonHorizontal", { EventGambleId = id })
    end)
end

--endregion

--region 缓存记录相关

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

--endregion

return XRogueSimMapSubControl
