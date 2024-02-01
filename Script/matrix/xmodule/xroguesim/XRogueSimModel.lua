--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local RogueSimTableKey = {
    RogueSimActivity = { CacheType = XConfigUtil.CacheType.Normal },
    RogueSimIllustrate = {},
    RogueSimStage = { CacheType = XConfigUtil.CacheType.Normal },
    RogueSimResource = {},
    RogueSimCommodity = {},
    RogueSimMainLevel = {},
    RogueSimBuff = {},
    RogueSimBuilding = {},
    RogueSimEvent = {},
    RogueSimEventOption = {},
    RogueSimProp = {},
    RogueSimReward = {},
    RogueSimRewardDrop = {},
    RogueSimTech = {},
    RogueSimTechLevel = {},
    RogueSimTip = {},
    RogueSimCity = {},
    RogueSimTask = {},
    RogueSimToken = {},
    RogueSimVolatility = {},
    RogueSimCondition = {},
    RogueSimEffect = {},
    RogueSimLoadingTips = { DirPath = XConfigUtil.DirectoryType.Client },
    RogueSimCommodityBubble = { DirPath = XConfigUtil.DirectoryType.Client },
    RogueSimCommodityBubbleGroup = { DirPath = XConfigUtil.DirectoryType.Client },
    RogueSimPropRare = { DirPath = XConfigUtil.DirectoryType.Client },
    RogueSimClientConfig =
    {
        CacheType = XConfigUtil.CacheType.Normal,
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Key"
    },
}
local RogueSimMapTableKey = {
    RogueSimArea = {},
    RogueSimLandform = {},
    RogueSimTerrain = {},
}

---@class XRogueSimModel : XModel
---@field ActivityData XRogueSimActivity
local XRogueSimModel = XClass(XModel, "XRogueSimModel")
function XRogueSimModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    self._ConfigUtil:InitConfigByTableKey("RogueSim", RogueSimTableKey)
    self._ConfigUtil:InitConfigByTableKey("RogueSim/RogueSimMap", RogueSimMapTableKey)

    -- 区域格子文件夹内的配置表
    self.RogueSimAreaGridTableKey = {}
    local paths = CS.XTableManager.GetPaths("Share/RogueSim/RogueSimMap/RogueSimAreaGrid")
    XTool.LoopCollection(paths, function(path)
        local key = XTool.GetFileNameWithoutExtension(path)
        self.RogueSimAreaGridTableKey[key] = { TableDefindName = "XTableRogueSimAreaGrid" }
    end)
    self._ConfigUtil:InitConfigByTableKey("RogueSim/RogueSimMap/RogueSimAreaGrid", self.RogueSimAreaGridTableKey)

    -- 是否初始化主城等级
    self.IsInitMainLevel = false
    -- 组对应着主城等级配置Id列表 key是组Id value是Id列表
    self.levelGroupToMainLevelIdList = {}
    -- 组对应着最大等级 key是组Id value是等级
    self.levelGroupToMaxMainLevel = {}
    -- 组和等级对应着主城等级配置Id key1是组Id key2是level value是配置Id
    self.levelGroupAndLevelToMainLevelId = {}

    -- 是否是正在进行回合结束(回合结束时会有事件奖励掉落，该奖励不需要入队奖励弹框的)
    self.IsRoundEnd = false
    -- 弹框数据
    self.PopupData = nil

    -- 回合结算信息
    self.TurnSettleData = nil
    -- 关卡结算信息
    self.StageSettleData = nil
end

function XRogueSimModel:ClearPrivate()
    --这里执行内部数据清理
    self.IsRoundEnd = false
    self:ClearAllPopupData()
    self.TurnSettleData = nil
    self.StageSettleData = nil
end

function XRogueSimModel:ResetAll()
    --这里执行重登数据清理
    self.ActivityData = nil
    self.IsRoundEnd = false
    self:ClearAllPopupData()
    self.TurnSettleData = nil
    self.StageSettleData = nil
end

--region 服务端信息更新和获取

function XRogueSimModel:NotifyRogueSimData(data)
    if not self.ActivityData then
        self.ActivityData = require("XModule/XRogueSim/XEntity/XRogueSimActivity").New()
    end
    self.ActivityData:NotifyRogueSimData(data)
end

-- 获取关卡数据
function XRogueSimModel:GetStageData()
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetStageData()
end

-- 获取关卡记录数据
function XRogueSimModel:GetStageRecord(stageId)
    if not self.ActivityData then
        return nil
    end
    return self.ActivityData:GetStageRecord(stageId)
end

-- 获取地图数据
function XRogueSimModel:GetMapData()
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetMapData()
end

-- 获取单个Buff数据通过自增Id
function XRogueSimModel:GetBuffDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetBuffDataById(id)
end

-- 获取单个奖励数据通过自增Id
function XRogueSimModel:GetRewardDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetRewardDataById(id)
end

-- 获取单个事件数据通过自增Id
function XRogueSimModel:GetEventDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetEventDataById(id)
end

-- 获取单个建筑数据通过自增Id
function XRogueSimModel:GetBuildingDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetBuildingDataById(id)
end

-- 获取单个城邦数据通过自增Id
function XRogueSimModel:GetCityDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetCityDataById(id)
end

-- 获取单个道具数据通过自增Id
function XRogueSimModel:GetPropDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetPropDataById(id)
end

-- 获取单个任务数据通过自增Id
function XRogueSimModel:GetTaskDataById(id)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetTaskDataById(id)
end

-- 获取货物加成信息通过货物Id
function XRogueSimModel:GetCommodityAddsById(commodityId)
    local stageData = self:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetCommodityAdds(commodityId)
end

-- 检查关卡数据是否为空
function XRogueSimModel:CheckStageDataEmpty()
    if not self:GetStageData() then
        return true
    end
    return false
end

-- 检查关卡是否通过
function XRogueSimModel:CheckStageIsPass(stageId)
    if self.ActivityData then
        return self.ActivityData:CheckFinishedStageId(stageId)
    end
    return false
end

--endregion

--region 活动表相关

---@return XTableRogueSimActivity
function XRogueSimModel:GetActivityConfig()
    if not self.ActivityData then
        return nil
    end
    local curActivityId = self.ActivityData:GetActivityId()
    if not XTool.IsNumberValid(curActivityId) then
        return nil
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimActivity, curActivityId)
end

-- 获取活动时间Id
function XRogueSimModel:GetActivityTimeId()
    local config = self:GetActivityConfig()
    return config and config.TimeId or 0
end

-- 获取活动游戏时间Id
function XRogueSimModel:GetActivityGameTimeId()
    local config = self:GetActivityConfig()
    return config and config.GameTimeId or 0
end

-- 获取活动关卡Id列表
function XRogueSimModel:GetActivityStageIds()
    local config = self:GetActivityConfig()
    return config and config.StageIds or {}
end

--endregion

--region 图鉴表相关

---@return XTableRogueSimIllustrate[]
function XRogueSimModel:GetRogueSimIllustrateConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimIllustrate)
end

---@return XTableRogueSimIllustrate
function XRogueSimModel:GetRogueSimIllustrateConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimIllustrate, id)
end

--endregion

--region 关卡表相关

---@return XTableRogueSimStage[]
function XRogueSimModel:GetRogueSimStageConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimStage)
end

---@return XTableRogueSimStage
function XRogueSimModel:GetRogueSimStageConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimStage, id)
end

-- 获取关卡时间Id
function XRogueSimModel:GetRogueSimStageTimeId(stageId)
    local config = self:GetRogueSimStageConfig(stageId)
    return config and config.TimeId or 0
end

-- 获取关卡名称
function XRogueSimModel:GetRogueSimStageName(stageId)
    local config = self:GetRogueSimStageConfig(stageId)
    return config and config.Name or ""
end

-- 获取关卡名称贴图
function XRogueSimModel:GetRogueSimStageNameIcon(stageId)
    local config = self:GetRogueSimStageConfig(stageId)
    return config and config.NameIcon or ""
end

-- 获取关卡最大回合数
function XRogueSimModel:GetRogueSimStageMaxTurnCount(stageId)
    local config = self:GetRogueSimStageConfig(stageId)
    return config and config.MaxTurnCount or 0
end

-- 获取关卡类型
function XRogueSimModel:GetRogueSimStageType(stageId)
    local config = self:GetRogueSimStageConfig(stageId)
    return config and config.Type or 0
end

--endregion

--region 资源表相关

---@return XTableRogueSimResource[]
function XRogueSimModel:GetRogueSimResourceConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimResource)
end

---@return XTableRogueSimResource
function XRogueSimModel:GetRogueSimResourceConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimResource, id)
end

--endregion

--region 货物表相关

---@return XTableRogueSimCommodity[]
function XRogueSimModel:GetRogueSimCommodityConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimCommodity)
end

---@return XTableRogueSimCommodity
function XRogueSimModel:GetRogueSimCommodityConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCommodity, id)
end

--endregion

--region 主城等级表相关

function XRogueSimModel:InitMainLevel()
    if self.IsInitMainLevel then
        return
    end
    local configs = self:GetRogueSimMainLevelConfigs()
    local levelGroup, level
    for id, config in ipairs(configs) do
        levelGroup = config.LevelGroup
        level = config.Level
        if not self.levelGroupToMainLevelIdList[levelGroup] then
            self.levelGroupToMainLevelIdList[levelGroup] = {}
        end
        table.insert(self.levelGroupToMainLevelIdList[levelGroup], id)

        if not self.levelGroupAndLevelToMainLevelId[levelGroup] then
            self.levelGroupAndLevelToMainLevelId[levelGroup] = {}
        end
        self.levelGroupAndLevelToMainLevelId[levelGroup][level] = id

        if not self.levelGroupToMaxMainLevel[levelGroup] or self.levelGroupToMaxMainLevel[levelGroup] < level then
            self.levelGroupToMaxMainLevel[levelGroup] = level
        end
    end
    self.IsInitMainLevel = true
end

-- 获取主城最大等级
function XRogueSimModel:GetMaxMainLevel(levelGroup)
    self:InitMainLevel()
    return self.levelGroupToMaxMainLevel[levelGroup] or 0
end

-- 获取主城等级列表
function XRogueSimModel:GetMainLevelIdList(levelGroup)
    self:InitMainLevel()
    return self.levelGroupToMainLevelIdList[levelGroup] or {}
end

-- 获取主城等级配置Id
function XRogueSimModel:GetMainLevelId(levelGroup, level)
    self:InitMainLevel()
    if not self.levelGroupAndLevelToMainLevelId[levelGroup] then
        XLog.Error("RogueSimMainLevel表中不存在LevelGroup为" .. levelGroup .. "的配置")
        return
    end
    return self.levelGroupAndLevelToMainLevelId[levelGroup][level] or 0
end

---@return XTableRogueSimMainLevel[]
function XRogueSimModel:GetRogueSimMainLevelConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimMainLevel)
end

---@return XTableRogueSimMainLevel
function XRogueSimModel:GetRogueSimMainLevelConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimMainLevel, id)
end

--endregion

--region Buff表相关

---@return XTableRogueSimBuff
function XRogueSimModel:GetRogueSimBuffConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimBuff, id)
end

--endregion

--region 奖励表相关

---@return XTableRogueSimReward
function XRogueSimModel:GetRogueSimRewardConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimReward, id)
end

---@return XTableRogueSimRewardDrop
function XRogueSimModel:GetRogueSimRewardDropConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimRewardDrop, id)
end

--endregion

--region 道具表相关

---@return XTableRogueSimProp[]
function XRogueSimModel:GetRogueSimPropConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimProp)
end

---@return XTableRogueSimProp
function XRogueSimModel:GetRogueSimPropConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimProp, id)
end

---@return XTableRogueSimPropRare
function XRogueSimModel:GetRogueSimPropRareConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimPropRare, id)
end

--endregion

--region 事件表相关

---@return XTableRogueSimEvent
function XRogueSimModel:GetRogueSimEventConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimEvent, id)
end

---@return XTableRogueSimEventOption
function XRogueSimModel:GetRogueSimEventOptionConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimEventOption, id)
end

--endregion

--region 建筑表相关

---@return XTableRogueSimBuilding[]
function XRogueSimModel:GetRogueSimBuildingConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimBuilding)
end

---@return XTableRogueSimBuilding
function XRogueSimModel:GetRogueSimBuildingConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimBuilding, id)
end

--endregion

--region 城邦表相关

---@return XTableRogueSimCity
function XRogueSimModel:GetRogueSimCityConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCity, id)
end

--endregion

--region 任务表相关

---@return XTableRogueSimTask
function XRogueSimModel:GetRogueSimTaskConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimTask, id)
end

--endregion

--region 信物表相关

---@return XTableRogueSimToken
function XRogueSimModel:GetRogueSimTokenConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimToken, id)
end

--endregion

--region 波动表相关

---@return XTableRogueSimVolatility
function XRogueSimModel:GetRogueSimVolatilityConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimVolatility, id)
end

--endregion

--region 条件表相关

---@return XTableRogueSimCondition
function XRogueSimModel:GetRogueSimConditionConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCondition, id)
end

-- 比较两个数值
function XRogueSimModel:CompareInt(num1, num2, op)
    if op == XEnumConst.RogueSim.ConditionOperateType.Greater then
        return num1 > num2
    elseif op == XEnumConst.RogueSim.ConditionOperateType.GreaterEqual then
        return num1 >= num2
    elseif op == XEnumConst.RogueSim.ConditionOperateType.Equal then
        return num1 == num2
    elseif op == XEnumConst.RogueSim.ConditionOperateType.LessEqual then
        return num1 <= num2
    elseif op == XEnumConst.RogueSim.ConditionOperateType.Less then
        return num1 < num2
    end
    return false
end

-- 位运算
function XRogueSimModel:CountBit(num)
    local count = 0
    while num > 0 do
        if (num & 1) == 1 then
            count = count + 1
        end
        num = num >> 1
    end
    return count
end

--endregion

--region 效果表相关

---@return XTableRogueSimEffect
function XRogueSimModel:GetRogueSimEffectConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimEffect, id)
end

--endregion

--region 科技表相关

---@return XTableRogueSimTech[]
function XRogueSimModel:GetRogueSimTechConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimTech)
end

---@return XTableRogueSimTech
function XRogueSimModel:GetRogueSimTechConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimTech, id)
end

---@return XTableRogueSimTechLevel[]
function XRogueSimModel:GetRogueSimTechLevelConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimTechLevel)
end

---@return XTableRogueSimTechLevel
function XRogueSimModel:GetRogueSimTechLevelConfig(lv)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimTechLevel, lv)
end

--endregion

--region 客户端配置表相关

function XRogueSimModel:GetClientConfig(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimClientConfig, key)
    if not config then
        return nil
    end
    return config.Params and config.Params[index] or ""
end

function XRogueSimModel:GetClientConfigParams(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimClientConfig, key)
    if not config then
        return nil
    end
    return config.Params
end

--endregion

--region loading表相关

-- 获取所有loading表
---@return XTableRogueSimLoadingTips[]
function XRogueSimModel:GetLoadingTipsConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimTableKey.RogueSimLoadingTips)
end

--endregion

--region 货物气泡表相关

---@return XTableRogueSimCommodityBubble
function XRogueSimModel:GetCommodityBubbleConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCommodityBubble, id)
end

---@return XTableRogueSimCommodityBubbleGroup
function XRogueSimModel:GetCommodityBubbleGroupConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimCommodityBubbleGroup, id)
end

--endregion

--region 传闻相关

-- 获取传闻表
---@return XTableRogueSimTip
function XRogueSimModel:GetRogueSimTipConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimTableKey.RogueSimTip, id)
end

--endregion

--region 地图表相关

---@return XTableRogueSimArea[]
function XRogueSimModel:GetRogueSimAreaConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimMapTableKey.RogueSimArea)
end

---@return XTableRogueSimArea
function XRogueSimModel:GetRogueSimAreaConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimMapTableKey.RogueSimArea, id)
end

---@return XTableRogueSimLandform[]
function XRogueSimModel:GetRogueSimLandformConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimMapTableKey.RogueSimLandform)
end

---@return XTableRogueSimLandform
function XRogueSimModel:GetRogueSimLandformConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimMapTableKey.RogueSimLandform, id)
end

---@return XTableRogueSimTerrain[]
function XRogueSimModel:GetRogueSimTerrainConfigs()
    return self._ConfigUtil:GetByTableKey(RogueSimMapTableKey.RogueSimTerrain)
end

---@return XTableRogueSimTerrain
function XRogueSimModel:GetRogueSimTerrainConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(RogueSimMapTableKey.RogueSimTerrain, id)
end

--endregion

--region 地图格子表相关
---@return XTableRogueSimAreaGrid[]
function XRogueSimModel:GetRogueSimAreaGridConfigs(id)
    local key = self.RogueSimAreaGridTableKey["RogueSimAreaGrid" .. id]
    local config = self._ConfigUtil:GetByTableKey(key)
    if not config then
        XLog.ErrorTableDataNotFound("XRogueSimModel.GetRogueSimAreaGridConfigs", "areaId",
            "Share/RogueSim/RogueSimMap/RogueSimAreaGrid/", "areaId", tostring(id))
        return
    end

    return config
end

--endregion

--region 弹框相关

-- 根据弹框类型入队弹框数据
function XRogueSimModel:EnqueuePopupData(popupType, ...)
    if not self.PopupData then
        self.PopupData = {}
    end
    if not self.PopupData[popupType] then
        self.PopupData[popupType] = {}
    end
    if popupType == XEnumConst.RogueSim.PopupType.Reward then
        self:AddRewardData(popupType, ...)
    end
    if popupType == XEnumConst.RogueSim.PopupType.PropSelect then
        self:AddPropSelectData(popupType, ...)
    end
    if popupType == XEnumConst.RogueSim.PopupType.Buff then
        self:AddBuffData(popupType, ...)
    end
    if popupType == XEnumConst.RogueSim.PopupType.Task then
        self:AddCityTaskData(popupType, ...)
    end
    if popupType == XEnumConst.RogueSim.PopupType.TurnReward then
        self:AddTurnRewardData(popupType, ...)
    end
    if popupType == XEnumConst.RogueSim.PopupType.MainLevelUp then
        self:AddMainLevelUpData(popupType, ...)
    end
end

-- 添加奖励数据
function XRogueSimModel:AddRewardData(popupType, rewardId, rewardItems)
    if not XTool.IsNumberValid(rewardId) or XTool.IsTableEmpty(rewardItems) or self.IsRoundEnd then
        return
    end
    -- 建筑掉落的事件不弹框
    if self:CheckIsBuildingEvent(rewardItems) then
        return
    end
    local data = {}
    data.RewardId = rewardId
    data.RewardItems = rewardItems
    table.insert(self.PopupData[popupType], data)
end

-- 检查是否是建筑掉落的事件
function XRogueSimModel:CheckIsBuildingEvent(rewardItems)
    if XTool.IsTableEmpty(rewardItems) then
        return false
    end
    local stageData = self:GetStageData()
    if not stageData then
        return false
    end
    -- 默认取第一个物品进行判断
    if rewardItems[1].Type == XEnumConst.RogueSim.RewardType.Event then
        local eventData = stageData:GetEventDataById(rewardItems[1].ObjectId)
        if eventData then
            local buildingData = stageData:GetBuildingDataByGridId(eventData:GetGridId())
            if buildingData then
                return true
            end
        end
    end
    return false
end

-- 添加道具选择数据
function XRogueSimModel:AddPropSelectData(popupType, reward)
    if not reward or not XTool.IsNumberValid(reward.GridId) or not XTool.IsNumberValid(reward.Source) or self.IsRoundEnd then
        return
    end
    local data = {}
    data.Reward = reward
    table.insert(self.PopupData[popupType], data)
end

-- 添加Buff数据
function XRogueSimModel:AddBuffData(popupType, buffData)
    if not buffData then
        return
    end
    -- 只收集事件和全局波动的Buff
    if buffData.Source ~= XEnumConst.RogueSim.SourceType.Event and buffData.Source ~= XEnumConst.RogueSim.SourceType.Volatility then
        return
    end
    local data = {}
    data.ItemId = buffData.BuffId
    data.Type = XEnumConst.RogueSim.RewardType.Buff
    data.Num = buffData.RemainingTurn -- 剩余回合数
    table.insert(self.PopupData[popupType], data)
end

-- 添加城邦任务数据
function XRogueSimModel:AddCityTaskData(popupType, cityTaskData)
    if not cityTaskData then
        return
    end
    for _, taskData in pairs(cityTaskData) do
        -- 只收集已完成的任务
        if taskData.State == XEnumConst.RogueSim.TaskState.Finished then
            local data = {}
            data.TaskData = taskData
            table.insert(self.PopupData[popupType], data)
        end
    end
end

-- 添加回合奖励数据
function XRogueSimModel:AddTurnRewardData(popupType, commodityInfo, resourceInfo)
    if commodityInfo then
        for id, num in pairs(commodityInfo) do
            local data = {}
            data.ItemId = id
            data.Num = num
            data.Type = XEnumConst.RogueSim.RewardType.Commodity
            table.insert(self.PopupData[popupType], data)
        end
    end
    if resourceInfo then
        for id, num in pairs(resourceInfo) do
            local data = {}
            data.ItemId = id
            data.Num = num
            data.Type = XEnumConst.RogueSim.RewardType.Resource
            table.insert(self.PopupData[popupType], data)
        end
    end
end

-- 添加主城等级提升数据
function XRogueSimModel:AddMainLevelUpData(popupType, level)
    local data = {}
    data.Level = level
    table.insert(self.PopupData[popupType], data)
end

-- 根据弹框类型出队弹框数据
function XRogueSimModel:DequeuePopupData(popupType, ...)
    if not self.PopupData or not self.PopupData[popupType] then
        return nil
    end
    if popupType == XEnumConst.RogueSim.PopupType.Reward then
        return self:GetRewardData(popupType, ...)
    end
    if popupType == XEnumConst.RogueSim.PopupType.PropSelect then
        return self:GetPropSelectData(popupType, ...)
    end
    if popupType == XEnumConst.RogueSim.PopupType.Buff
        or popupType == XEnumConst.RogueSim.PopupType.TurnReward
        or popupType == XEnumConst.RogueSim.PopupType.MainLevelUp then
        -- 返回所有值
        local data = self.PopupData[popupType]
        self.PopupData[popupType] = nil
        return data
    end
    if popupType == XEnumConst.RogueSim.PopupType.Task then
        -- 默认取第一个
        return table.remove(self.PopupData[popupType], 1)
    end
    return nil
end

-- 获取奖励数据
function XRogueSimModel:GetRewardData(popupType, rewardId)
    -- 根据奖励Id取数据里的值
    if XTool.IsNumberValid(rewardId) then
        local index = 0
        for i, data in ipairs(self.PopupData[popupType]) do
            if data.RewardId == rewardId then
                index = i
                break
            end
        end
        if index > 0 then
            return table.remove(self.PopupData[popupType], index)
        end
    end
    -- 取数据里的第一个值
    return table.remove(self.PopupData[popupType], 1)
end

-- 获取道具选择数据
function XRogueSimModel:GetPropSelectData(popupType, gridId, source)
    -- 根据格子id和来源id取数据里的值
    if XTool.IsNumberValid(gridId) and XTool.IsNumberValid(source) then
        local index = 0
        for i, data in ipairs(self.PopupData[popupType]) do
            if data.Reward.GridId == gridId and data.Reward.Source == source then
                index = i
                break
            end
        end
        if index > 0 then
            return table.remove(self.PopupData[popupType], index)
        end
    end
    -- 取数据里的第一个值
    return table.remove(self.PopupData[popupType], 1)
end

-- 检查弹框数据是否为空
function XRogueSimModel:CheckPopupDataEmpty(popupType)
    if not self.PopupData or not self.PopupData[popupType] then
        return true
    end
    if XTool.IsTableEmpty(self.PopupData[popupType]) then
        return true
    end
    return false
end

-- 根据类型清空弹框数据
function XRogueSimModel:ClearPopupDataByType(popupType)
    if not self.PopupData or not self.PopupData[popupType] then
        return
    end
    self.PopupData[popupType] = nil
end

-- 清空弹框数据
function XRogueSimModel:ClearAllPopupData()
    self.PopupData = nil
end

--endregion

--region 本地信息相关

-- 获取引导记录key
function XRogueSimModel:GetGuideRecordKey()
    local activityId = self.ActivityData and self.ActivityData:GetActivityId() or 0
    return string.format("XRogueSimModel_GetGuideRecordKey_%s_%s", XPlayer.Id, activityId)
end

--endregion

return XRogueSimModel
