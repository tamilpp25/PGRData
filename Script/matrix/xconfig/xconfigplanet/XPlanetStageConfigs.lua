---行星环游记关卡配置
XPlanetStageConfigs = XPlanetStageConfigs or {}
local XPlanetStageConfigs = XPlanetStageConfigs

---@type XConfig
local _ConfigChapter
---@type XConfig
local _ConfigStage
local _StageDirByChapterId = {}
---@type XConfig
local _ConfigCondition
---@type XConfig
local _ConfigEffect
---@type XConfig
local _ConfigEvent
---@type XConfig
local _ConfigItem
---@type XConfig
local _ConfigBuildingRecommend
---@type XConfig
local _ConfigBossGroup
---@type XConfig
local _ConfigBoss
---@type XConfig
local _ConfigAttr
---@type XConfig
local _ConfigWeatherGroup
local _WeatherGroup = {}

XPlanetStageConfigs.ConditionType = {
    BuildCount = 1, -- 累计建造指定建筑
    PerRoundCountPass = 2, -- 每X圈首次经过
    PerRoundCount = 3, -- 每X圈
    InRange = 4, -- 范围内时触发
    InRangeHaveBuilding = 5, -- 范围内存在目标建筑
    MonsterDie = 6, -- 怪物死亡时
}

XPlanetStageConfigs.EffectType = {
    BuildCostIncrease = 1, -- 建造涨价
    AttributeChange = 2, -- 属性修改
    CallMonster = 3, -- 怪物召唤
    AddEvent = 4, -- 添加事件
    WeatherChange = 5, -- 天气修改
    MoneyChange = 6, -- 金币修改
    GetItem = 7, -- 获取指定道具
    GetRandomItem = 8, -- 抽取道具(随机获取道具)
    BuildingCountLimitChange = 9, -- 关卡内建筑建造数量限制
}

XPlanetStageConfigs.EventTriggerType = {

}

XPlanetStageConfigs.ItemRangeType = {
    Global = 0,
    One = 1,
    Three = 2,
    Seven = 3,
}

XPlanetStageConfigs.ItemTargetType = {

}

XPlanetStageConfigs.BossType = {
    Normal = 1,
    Special = 2,
}

local EVENT_INCREASE = {
    INCREASE = 1,
    DECREASE = 2,
}

XPlanetStageConfigs.XPlanetRunningEffectType = {
    BuildingPriceRaise = 1,
    AttrChange = 2,
    MonsterBrush = 3,
    AddEvent = 4,
    WeatherChange = 5,
    CoinChange = 6,
    GainProp = 7,
    DrawProp = 8,
}

-- 属性修改类型
XPlanetStageConfigs.XPlanetRunningAttrChangeType = {
    TenThousandthRatio = 1, --万分比
    Fixed = 2, --固定值
}

function XPlanetStageConfigs.Init()
    --_ConfigChapter = XConfig.New("Share/PlanetRunning/PlanetRunningChapter.tab", XTable.XTablePlanetRunningChapter)
    --_ConfigStage = XConfig.New("Share/PlanetRunning/PlanetRunningStage.tab", XTable.XTablePlanetRunningStage)
    --_ConfigCondition = XConfig.New("Share/PlanetRunning/PlanetRunningCondition.tab", XTable.XTablePlanetRunningCondition)
    --_ConfigEffect = XConfig.New("Share/PlanetRunning/PlanetRunningEffect.tab", XTable.XTablePlanetRunningEffect)
    --_ConfigEvent = XConfig.New("Share/PlanetRunning/PlanetRunningEvent.tab", XTable.XTablePlanetRunningEvent)
    --_ConfigItem = XConfig.New("Share/PlanetRunning/PlanetRunningItem.tab", XTable.XTablePlanetRunningItem)
    --_ConfigBuildingRecommend = XConfig.New("Client/PlanetRunning/PlanetRunningBuildingRecommend.tab", XTable.XTablePlanetRunningBuildingRecommend)
    --_ConfigBossGroup = XConfig.New("Share/PlanetRunning/PlanetRunningBossGroup.tab", XTable.XTablePlanetRunningBossGroup)
    --_ConfigBoss = XConfig.New("Share/PlanetRunning/PlanetRunningMonster.tab", XTable.XTablePlanetRunningMonster)
    --_ConfigWeatherGroup = XConfig.New("Share/PlanetRunning/PlanetRunningWeatherGroup.tab", XTable.XTablePlanetRunningWeatherGroup)
    --_ConfigAttr = XConfig.New("Share/PlanetRunning/PlanetRunningAttribute.tab", XTable.XTablePlanetRunningAttribute)
    --XPlanetStageConfigs.InitStageChapterDir()
    --XPlanetStageConfigs.InitWeatherGroup()
end

--region _ConfigChapter
---@return string
function XPlanetStageConfigs.GetChapterIdList()
    local result = {}
    for id, _ in pairs(_ConfigChapter:GetConfigs()) do
        table.insert(result, id)
    end
    return result
end

---@return number
function XPlanetStageConfigs.GetChapterPreStageId(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "PreStageId")
end

---@return number
function XPlanetStageConfigs.GetChapterOpenTimeId(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "OpenTimeId")
end

---@return number
function XPlanetStageConfigs.GetChapterOpenTime(chapterId)
    local timeId = XPlanetStageConfigs.GetChapterOpenTimeId(chapterId)
    return XFunctionManager.GetStartTimeByTimeId(timeId)
end

---@return string
function XPlanetStageConfigs.GetChapterName(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "ChapterName")
end

---@return string
function XPlanetStageConfigs.GetChapterTitleIconUrl(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "TitleIconUrl")
end

---@return string
function XPlanetStageConfigs.GetChapterStageSceneUrl(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "StageSceneUrl")
end

---@return string
function XPlanetStageConfigs.GetChapterPlanetPrefabUrl(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "PlanetPrefabUrl")
end

---@return number
function XPlanetStageConfigs.GetChapterBaseTileFloorId(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "BaseTileFloorId")
end

---@return number
function XPlanetStageConfigs.GetChapterBaseRoadFloorId(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "BaseRoadFloorId")
end
--endregion


--region _ConfigStage
local SortStage = function(stageA, stageB)
    return XPlanetStageConfigs.GetStageOrder(stageA) < XPlanetStageConfigs.GetStageOrder(stageB)
end

function XPlanetStageConfigs.InitStageChapterDir()
    for _, config in pairs(_ConfigStage:GetConfigs()) do
        if XTool.IsTableEmpty(_StageDirByChapterId[config.ChapterId]) then
            _StageDirByChapterId[config.ChapterId] = {}
        end
        table.insert(_StageDirByChapterId[config.ChapterId], config.Id)
        table.sort(_StageDirByChapterId[config.ChapterId], SortStage)
    end
end

function XPlanetStageConfigs.GetStageListByChapterId(chapterId)
    return _StageDirByChapterId[chapterId]
end

function XPlanetStageConfigs.GetStageIdList()
    local result = {}
    for _, config in pairs(_ConfigStage:GetConfigs()) do
        table.insert(result, config.Id)
    end
    return result
end

function XPlanetStageConfigs.GetStageName(stageId)
    return _ConfigStage:GetProperty(stageId, "Name")
end

function XPlanetStageConfigs.GetStageIcon(stageId)
    return _ConfigStage:GetProperty(stageId, "Icon")
end

function XPlanetStageConfigs.GetProgressPerRound(stageId)
    return _ConfigStage:GetProperty(stageId, "LevelUpProgress")
end

---@return number
function XPlanetStageConfigs.GetStageChapterId(stageId)
    return _ConfigStage:GetProperty(stageId, "ChapterId")
end

---@return number
function XPlanetStageConfigs.GetStagePreStageId(stageId)
    return _ConfigStage:GetProperty(stageId, "PreStageId")
end

---@return number
function XPlanetStageConfigs.GetStageOrder(stageId)
    return _ConfigStage:GetProperty(stageId, "Order")
end

---@return number
function XPlanetStageConfigs.GetStagePlanetId(stageId)
    return _ConfigStage:GetProperty(stageId, "PlanetId")
end

function XPlanetStageConfigs.GetStageWeatherGroupId(stageId)
    return _ConfigStage:GetProperty(stageId, "WeatherGroupId")
end

function XPlanetStageConfigs.GetStageBossGroupId(stageId)
    return _ConfigStage:GetProperty(stageId, "BossGroupId")
end

function XPlanetStageConfigs.GetStageTargetGroupId(stageId)
    return _ConfigStage:GetProperty(stageId, "TargetGroupId")
end

---关卡初始金币数
---@return number
function XPlanetStageConfigs.GetStageInitCoin(stageId)
    return _ConfigStage:GetProperty(stageId, "InitCoin")
end

---关卡可携带道具数
---@return number
function XPlanetStageConfigs.GetStageCarryItemCount(stageId)
    return _ConfigStage:GetProperty(stageId, "CarryItemCount")
end

---关卡可携带道具数
---@return number
function XPlanetStageConfigs.GetStageCarryBuildingCount(stageId)
    return _ConfigStage:GetProperty(stageId, "CarryBuildingCount")
end

---关卡每圈(回合)提升等级数
---@return number
function XPlanetStageConfigs.GetStageLevelUpProgress(stageId)
    return _ConfigStage:GetProperty(stageId, "LevelUpProgress")
end

---关卡首通奖励
---@return number
function XPlanetStageConfigs.GetStageRewardId(stageId)
    return _ConfigStage:GetProperty(stageId, "RewardId")
end

---关卡携带的事件
---@return number[]
function XPlanetStageConfigs.GetStageEnvironmentEvents(stageId)
    return _ConfigStage:GetProperty(stageId, "EnvironmentEvents")
end

---关卡默认建筑
---@return number[]
function XPlanetStageConfigs.GetStageDefaultBuilding(stageId)
    return _ConfigStage:GetProperty(stageId, "DefaultBuilding")
end

---关卡禁用建筑
---@return number[]
function XPlanetStageConfigs.GetStageDisableBuilding(stageId)
    return _ConfigStage:GetProperty(stageId, "DisableBuilding")
end

---关卡强制使用建筑
---@return number[]
function XPlanetStageConfigs.GetStageCompelUsedBuilding(stageId)
    return _ConfigStage:GetProperty(stageId, "CompelUsedBuilding")
end

---关卡禁止使用建筑
---@return number[]
function XPlanetStageConfigs.GetStageDisableBuilding(stageId)
    return _ConfigStage:GetProperty(stageId, "DisableBuilding")
end

function XPlanetStageConfigs.GetStageItemGroupId(stageId)
    return _ConfigStage:GetProperty(stageId, "ItemGroupId")
end

function XPlanetStageConfigs.IsStageShowProp(stageId)
    local id = XPlanetStageConfigs.GetStageItemGroupId(stageId)
    return id and id ~= 0
end

function XPlanetStageConfigs.GetStageFullName(stageId)
    local stageName = XPlanetStageConfigs.GetStageName(stageId)
    local chapterName = XPlanetStageConfigs.GetChapterName(XPlanetStageConfigs.GetStageChapterId(stageId))
    if string.IsNilOrEmpty(stageName) then
        return chapterName
    end
    if string.IsNilOrEmpty(chapterName) then
        return stageName
    end
    return XUiHelper.GetText("PlanetRunningStageFullName", chapterName, stageName)
end
--endregion


--region _ConfigCondition
---@return string
function XPlanetStageConfigs.GetConditionDesc(conditionId)
    return _ConfigCondition:GetProperty(conditionId, "Desc")
end

---@return number XPlanetStageConfigs.ConditionType
function XPlanetStageConfigs.GetConditionType(conditionId)
    return _ConfigCondition:GetProperty(conditionId, "Type")
end

---@return number[]
function XPlanetStageConfigs.GetConditionParams(conditionId)
    return _ConfigCondition:GetProperty(conditionId, "Params")
end
--endregion


--region _ConfigEffect
---@return string
function XPlanetStageConfigs.GetEffectDesc(effectId)
    return _ConfigEffect:GetProperty(effectId, "Desc")
end

---@return number XPlanetStageConfigs.EffectType
function XPlanetStageConfigs.GetEffectType(effectId)
    return _ConfigEffect:GetProperty(effectId, "Type")
end

---效果可否叠加
function XPlanetStageConfigs.GetEffectOverlying(effectId)
    return XTool.IsNumberValid(_ConfigEffect:GetProperty(effectId, "Overlying"))
end

---@return number[]
function XPlanetStageConfigs.GetEffectParams(effectId)
    return _ConfigEffect:GetProperty(effectId, "Params")
end

function XPlanetStageConfigs.GetBuffBubbleControllerId(eventId)
    return _ConfigEffect:GetProperty(eventId, "BubbleControllerId")
end

function XPlanetStageConfigs.GetBuffEffect2Model(eventId)
    return _ConfigEffect:GetProperty(eventId, "PlayEffect")
end
--endregion


--region _ConfigEvent
function XPlanetStageConfigs.GetEventType(eventId)
    return _ConfigEvent:GetProperty(eventId, "Name")
end

function XPlanetStageConfigs.GetEventName(eventId)
    return _ConfigEvent:GetProperty(eventId, "Name")
end

function XPlanetStageConfigs.GetEventDesc(eventId)
    return _ConfigEvent:GetProperty(eventId, "Desc")
end

---事件触发时机类型
---@return number XPlanetStageConfigs.EventTriggerType
function XPlanetStageConfigs.GetEventTriggerType(eventId)
    return _ConfigEvent:GetProperty(eventId, "TriggerType")
end

---事件第X圈后激活效果
---@return number
function XPlanetStageConfigs.GetEventActivateCount(eventId)
    return _ConfigEvent:GetProperty(eventId, "ActivateCount")
end

---事件是否在单位面板上显示
function XPlanetStageConfigs.GetEventIsShow(eventId)
    return XTool.IsNumberValid(_ConfigEvent:GetProperty(eventId, "Show"))
end

---事件是否在单位面板上显示
function XPlanetStageConfigs.GetEventIsIncrease(eventId)
    return _ConfigEvent:GetProperty(eventId, "IsIncrease") == EVENT_INCREASE.INCREASE
end

function XPlanetStageConfigs.GetEventIcon(eventId)
    return _ConfigEvent:GetProperty(eventId, "Icon")
end

---事件效果
---@return number[]
function XPlanetStageConfigs.GetEventEffects(eventId)
    return _ConfigEvent:GetProperty(eventId, "Effects")
end

---事件效果生效条件(并逻辑)
---@return number[]
function XPlanetStageConfigs.GetEventConditions(eventId)
    return _ConfigEvent:GetProperty(eventId, "Conditions")
end

--endregion


--region _ConfigItem
---@return number
function XPlanetStageConfigs.GetItemName(stageId)
    return _ConfigItem:GetProperty(stageId, "Name")
end

function XPlanetStageConfigs.GetItemIcon(itemId)
    return _ConfigItem:GetProperty(itemId, "Icon")
end

function XPlanetStageConfigs.GetItemDesc(itemId)
    return _ConfigItem:GetProperty(itemId, "Desc")
end

function XPlanetStageConfigs.GetItemEvents(itemId)
    return _ConfigItem:GetProperty(itemId, "Events")
end

---道具可释放的目标类型
---@return number XPlanetStageConfigs.ItemTargetType
function XPlanetStageConfigs.GetItemTargetType(stageId)
    return _ConfigItem:GetProperty(stageId, "TargetType")
end

---道具可释放的目标类型用参数
---@return number[]
function XPlanetStageConfigs.GetItemTargetTypeParam(stageId)
    return _ConfigItem:GetProperty(stageId, "TargetTypeParam")
end

---道具效果范围
---@return number
function XPlanetStageConfigs.GetItemRange(stageId)
    return _ConfigItem:GetProperty(stageId, "Range")
end

---道具效果指定目标数
---@return number
function XPlanetStageConfigs.GetItemTargetCount(stageId)
    return _ConfigItem:GetProperty(stageId, "TargetCount")
end

---道具超过持有上限时单个该道具转化的金币数
---@return number
function XPlanetStageConfigs.GetItemOverflowReturnCoin(stageId)
    return _ConfigItem:GetProperty(stageId, "OverflowReturnCoin")
end

---道具事件效果
---@return number[]
function XPlanetStageConfigs.GetItemEvents(stageId)
    return _ConfigItem:GetProperty(stageId, "Events")
end
--endregion

--region _ConfigBuildingRecommend
function XPlanetStageConfigs.GetBuildingRecommend(stageId)
    local recommendId = _ConfigStage:GetProperty(stageId, "BuildingRecommend")
    local configs = _ConfigBuildingRecommend:GetConfigs()
    local result = {}
    for _, config in pairs(configs) do
        if config.GroupId == recommendId and config.IsRecommend then
            result[#result + 1] = config
        end
    end
    return result
end

function XPlanetStageConfigs.GetBuildingRecommendDefault(stageId)
    local recommendId = _ConfigStage:GetProperty(stageId, "BuildingRecommend")
    local configs = _ConfigBuildingRecommend:GetConfigs()
    local result = {}
    for _, config in pairs(configs) do
        if config.GroupId == recommendId then
            result[#result + 1] = config.Building
        end
    end
    return result
end
--endregion _ConfigBuildingRecommend

--region _ConfigBossGroup
function XPlanetStageConfigs.GetBossByGroup(groupId)
    local configs = _ConfigBossGroup:GetConfigs()
    local result = {}
    for _, config in pairs(configs) do
        if config.GroupId == groupId then
            result[#result + 1] = config
        end
    end
    return result
end

local function GetBossGroupConfig(groupId, bossId)
    for _, config in pairs(_ConfigBossGroup:GetConfigs()) do
        if config.GroupId == groupId and config.BossId == bossId then
            return config
        end
    end
    return false
end

function XPlanetStageConfigs.GetBossProgress2Born(groupId, bossId)
    local config = GetBossGroupConfig(groupId, bossId)
    return config and config.SummonValue or 0
end

function XPlanetStageConfigs.GetBossFightingPower(groupId, bossId)
    local config = GetBossGroupConfig(groupId, bossId)
    return config and config.BossFightValue or 0
end

function XPlanetStageConfigs.GetBossFightingPowerRecommend(groupId, bossId)
    local config = GetBossGroupConfig(groupId, bossId)
    return config and config.CommendFightValue or 0
end
--endregion _ConfigBossGroup

--region _ConfigBoss
function XPlanetStageConfigs.GetBossIcon(bossId)
    return _ConfigBoss:GetProperty(bossId, "Icon")
end

function XPlanetStageConfigs.GetBossName(bossId)
    return _ConfigBoss:GetProperty(bossId, "Name")
end

function XPlanetStageConfigs.GetBossType(bossId)
    return _ConfigBoss:GetProperty(bossId, "MonsterType")
end

function XPlanetStageConfigs.IsSpecialBoss(bossId)
    return XPlanetStageConfigs.GetBossType(bossId) == XPlanetStageConfigs.BossType.Special
end

function XPlanetStageConfigs.IsBossCanSkipFight(bossId)
    return not XPlanetStageConfigs.IsSpecialBoss(bossId)
end

function XPlanetStageConfigs.GetBossAttrId(bossId)
    return _ConfigBoss:GetProperty(bossId, "NpcAttributeId")
end

function XPlanetStageConfigs.GetBossModel(bossId)
    return _ConfigBoss:GetProperty(bossId, "Model")
end

function XPlanetStageConfigs.GetBossEvents(bossId)
    return _ConfigBoss:GetProperty(bossId, "Events")
end

function XPlanetStageConfigs.GetAttr(attrId)
    return _ConfigAttr:GetConfig(attrId)
end
--endregion _ConfigBoss


--region _ConfigWeatherGroup
function XPlanetStageConfigs.InitWeatherGroup()
    for _, config in pairs(_ConfigWeatherGroup:GetConfigs()) do
        if XTool.IsTableEmpty(_WeatherGroup[config.GroupId]) then
            _WeatherGroup[config.GroupId] = {}
        end
        table.insert(_WeatherGroup[config.GroupId], config.Id)
        table.sort(_WeatherGroup[config.GroupId], function(idA, idB)
            local orderA = XPlanetStageConfigs.GetWeatherGroupOrder(idA)
            local orderB = XPlanetStageConfigs.GetWeatherGroupOrder(idB)
            return orderA < orderB
        end)
    end
end

function XPlanetStageConfigs.GetWeatherGroup(groupId)
    return _WeatherGroup[groupId]
end

function XPlanetStageConfigs.GetWeatherGroupWeatherId(id)
    return _ConfigWeatherGroup:GetProperty(id, "WeatherId")
end

function XPlanetStageConfigs.GetWeatherGroupOrder(id)
    return _ConfigWeatherGroup:GetProperty(id, "Order")
end

function XPlanetStageConfigs.GetWeatherGroupDuration(id)
    return _ConfigWeatherGroup:GetProperty(id, "Duration")
end
--endregion