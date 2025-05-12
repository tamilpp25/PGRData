local XRogueSimMapSubControl = require("XModule/XRogueSim/SubControl/XRogueSimMapSubControl")
local XRogueSimBuffSubControl = require("XModule/XRogueSim/SubControl/XRogueSimBuffSubControl")
local XRogueSimResourceSubControl = require("XModule/XRogueSim/SubControl/XRogueSimResourceSubControl")
local XRogueSimConditionSubControl = require("XModule/XRogueSim/SubControl/XRogueSimConditionSubControl")
---@class XRogueSimControl : XControl
---@field private _Model XRogueSimModel
---@field MapSubControl XRogueSimMapSubControl
---@field BuffSubControl XRogueSimBuffSubControl
---@field ResourceSubControl XRogueSimResourceSubControl
---@field ConditionSubControl XRogueSimConditionSubControl
---@field RogueSimScene XRogueSimScene
local XRogueSimControl = XClass(XControl, "XRogueSimControl")
function XRogueSimControl:OnInit()
    --初始化内部变量
    self.MapSubControl = self:AddSubControl(XRogueSimMapSubControl)
    self.BuffSubControl = self:AddSubControl(XRogueSimBuffSubControl)
    self.ResourceSubControl = self:AddSubControl(XRogueSimResourceSubControl)
    self.ConditionSubControl = self:AddSubControl(XRogueSimConditionSubControl)

    self.RequestName = {
        RogueSimStageStartRequest = "RogueSimStageStartRequest",                       -- 请求关卡开始
        RogueSimStageEnterRequest = "RogueSimStageEnterRequest",                       -- 请求关卡进入
        RogueSimExploreGridRequest = "RogueSimExploreGridRequest",                     -- 请求探索格子
        RogueSimCommoditySetupPlansRequest = "RogueSimCommoditySetupPlansRequest",     -- 请求设置商品计划
        RogueSimTurnSettleRequest = "RogueSimTurnSettleRequest",                       -- 请求回合结算
        RogueSimPickRewardRequest = "RogueSimPickRewardRequest",                       -- 领取奖励请求
        RogueSimMainLevelUpRequest = "RogueSimMainLevelUpRequest",                     -- 请求主城升级
        RogueSimCityLevelUpRequest = "RogueSimCityLevelUpRequest",                     -- 请求城邦升级
        RogueSimUnlockTechRequest = "RogueSimUnlockTechRequest",                       -- 解锁科技请求
        RogueSimUnlockKeyTechRequest = "RogueSimUnlockKeyTechRequest",                 -- 解锁关键科技请求
        RogueSimStageSettleRequest = "RogueSimStageSettleRequest",                     -- 放弃游戏关卡结算请求
        RogueSimEventSelectOptionRequest = "RogueSimEventSelectOptionRequest",         -- 请求事件选择选项
        RogueSimEventGambleGetRewardRequest = "RogueSimEventGambleGetRewardRequest",   -- 请求事件投机领取奖励
        RogueSimBuildByBluePrintRequest = "RogueSimBuildByBluePrintRequest",           -- 请求自建建筑
        RogueSimTemporaryBagGetRewardRequest = "RogueSimTemporaryBagGetRewardRequest", -- 请求领取建筑奖励
        RogueSimUnlockAreaRequest = "RogueSimUnlockAreaRequest",                       -- 请求解锁区域
    }
end

function XRogueSimControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    XMVCA.XRogueSim:AddEventListener(XAgencyEventId.EVENT_ROGUE_SIM_CACHE_STAGE_SETTLE_DATA, self.CacheStageSettleData, self)
    XMVCA.XRogueSim:AddEventListener(XEventId.EVENT_ROGUE_SIM_COMMODITY_CHANGE, self.OnCommodityChange, self)
end

function XRogueSimControl:RemoveAgencyEvent()
    XMVCA.XRogueSim:RemoveEventListener(XAgencyEventId.EVENT_ROGUE_SIM_CACHE_STAGE_SETTLE_DATA, self.CacheStageSettleData, self)
    XMVCA.XRogueSim:RemoveEventListener(XEventId.EVENT_ROGUE_SIM_COMMODITY_CHANGE, self.OnCommodityChange, self)
end

function XRogueSimControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
    self.MapSubControl = nil
    self.BuffSubControl = nil
    self.ResourceSubControl = nil
    self.ConditionSubControl = nil
    self.RogueSimScene = nil
end

--region 活动相关

function XRogueSimControl:GetActivityName()
    local config = self._Model:GetActivityConfig()
    return config and config.Name or ""
end

function XRogueSimControl:GetActivityStageIds()
    return self._Model:GetActivityStageIds()
end

function XRogueSimControl:GetActivitySettlePointPerGold()
    local config = self._Model:GetActivityConfig()
    return config and config.SettlePointPerGold or 0
end

function XRogueSimControl:GetActivitySettlePointPerCity()
    local config = self._Model:GetActivityConfig()
    return config and config.SettlePointPerCity or 0
end

function XRogueSimControl:GetActivitySettlePointPerMainLevel()
    local config = self._Model:GetActivityConfig()
    return config and config.SettlePointPerMainLevel or 0
end

function XRogueSimControl:GetActivitySettlePointPerBuilding()
    local config = self._Model:GetActivityConfig()
    return config and config.SettlePointPerBuilding or 0
end

function XRogueSimControl:GetActivitySettlePointPerArea()
    local config = self._Model:GetActivityConfig()
    return config and config.SettlePointPerArea or 0
end

function XRogueSimControl:GetActivitySettlePointPerEvent()
    local config = self._Model:GetActivityConfig()
    return config and config.SettlePointPerEvent or 0
end

function XRogueSimControl:GetActivityEndTime()
    local timeId = self._Model:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XRogueSimControl:GetActivityGameEndTime()
    local timeId = self._Model:GetActivityGameTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XRogueSimControl:HandleActivityEnd(isExitScene)
    if isExitScene then
        self:OnExitScene()
    end
    -- 清除可重复触发的引导记录
    self:ClearGuideRecord()
    XLuaUiManager.RunMain()
    XUiManager.TipText("ActivityAlreadyOver")
end

--endregion

--region 关卡相关

function XRogueSimControl:GetRogueSimStageType(stageId)
    return self._Model:GetRogueSimStageType(stageId)
end

function XRogueSimControl:GetRogueSimStageName(stageId)
    return self._Model:GetRogueSimStageName(stageId)
end

function XRogueSimControl:GetRogueSimStageNameIcon(stageId)
    return self._Model:GetRogueSimStageNameIcon(stageId)
end

function XRogueSimControl:GetRogueSimStageLevelGroup(stageId)
    local config = self._Model:GetRogueSimStageConfig(stageId)
    return config and config.LevelGroup or 0
end

function XRogueSimControl:GetRogueSimStageCityLevelGroup(stageId)
    local config = self._Model:GetRogueSimStageConfig(stageId)
    return config and config.CityLevelGroup or 0
end

function XRogueSimControl:GetRogueSimStageDesc(stageId)
    local config = self._Model:GetRogueSimStageConfig(stageId)
    return config and config.Desc or ""
end

-- 获取关卡最大回合数
function XRogueSimControl:GetRogueSimStageMaxTurnCount(stageId)
    return self._Model:GetRogueSimStageMaxTurnCount(stageId)
end

-- 获取关卡信物Id
function XRogueSimControl:GetRogueSimStageTokenId(stageId)
    local config = self._Model:GetRogueSimStageConfig(stageId)
    return config and config.TokenId or 0
end

-- 获取关卡首通奖励Id
function XRogueSimControl:GetRogueSimStageFirstFinishReward(stageId)
    local config = self._Model:GetRogueSimStageConfig(stageId)
    return config and config.FirstFinishReward or 0
end

-- 获取关卡三星condition列表
function XRogueSimControl:GetRogueSimStageStarConditions(stageId)
    local config = self._Model:GetRogueSimStageConfig(stageId)
    return config and config.StarConditions or {}
end

-- 获取关卡三星奖励Id列表
function XRogueSimControl:GetRogueSimStageStarRewardIds(stageId)
    local config = self._Model:GetRogueSimStageConfig(stageId)
    return config and config.StarRewardIds or {}
end

-- 获取关卡三星描述列表
function XRogueSimControl:GetRogueSimStageStarDescs(stageId)
    local config = self._Model:GetRogueSimStageConfig(stageId)
    return config and config.StarDescs or {}
end

-- 获取关卡开始时间
function XRogueSimControl:GetStageStartTime(stageId)
    local timeId = self._Model:GetRogueSimStageTimeId(stageId)
    return XFunctionManager.GetStartTimeByTimeId(timeId)
end

-- 获取关卡开启倒计时描述
function XRogueSimControl:GetStageOpenCountDownDesc(stageId)
    local time = self:GetStageStartTime(stageId) - XTime.GetServerNowTimestamp()
    if time <= 0 then
        time = 0
    end
    local timeStr = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
    return string.format(self:GetClientConfig("StageNotUnlockDesc", 1), timeStr)
end

-- 获取前置关卡未通过描述
function XRogueSimControl:GetPreStageNotPassDesc(stageId)
    local preStageId = self._Model:GetRogueSimStagePreStageId(stageId)
    local preStageName = self:GetRogueSimStageName(preStageId)
    return string.format(self:GetClientConfig("StageNotUnlockDesc", 2), preStageName)
end

-- 检查是否在开启时间内
function XRogueSimControl:CheckStageIsInOpenTime(stageId)
    local timeId = self._Model:GetRogueSimStageTimeId(stageId)
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

-- 检查前置关卡是否通关
function XRogueSimControl:CheckPreStageIsPass(stageId)
    local preStageId = self._Model:GetRogueSimStagePreStageId(stageId)
    -- 未配置默认为通关
    if not XTool.IsNumberValid(preStageId) then
        return true
    end
    return self:CheckStageIsPass(preStageId)
end

-- 获取当前关卡Id
function XRogueSimControl:GetCurStageId()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetStageId()
end

-- 获取当前回合数
function XRogueSimControl:GetCurTurnNumber()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetTurnNumber()
end

-- 获取当前关卡的等级组
function XRogueSimControl:GetCurStageLevelGroup()
    local stageId = self:GetCurStageId()
    return self:GetRogueSimStageLevelGroup(stageId)
end

-- 获取当前关卡的城邦等级组
function XRogueSimControl:GetCurStageCityLevelGroup()
    local stageId = self:GetCurStageId()
    return self:GetRogueSimStageCityLevelGroup(stageId)
end

-- 检查关卡是否通关
function XRogueSimControl:CheckStageIsPass(stageId)
    return self._Model:CheckStageIsPass(stageId)
end

-- 检查关卡数据是否为空
function XRogueSimControl:CheckStageDataIsEmpty()
    return self._Model:CheckStageDataEmpty()
end

-- 获取关卡记录最高分数
function XRogueSimControl:GetStageRecordMaxPoint(stageId)
    local record = self._Model:GetStageRecord(stageId)
    if not record then
        return 0
    end
    return record:GetMaxPoint()
end

-- 获取关卡记录星级奖励领取Mask
function XRogueSimControl:GetStageRecordStarMask(stageId)
    local record = self._Model:GetStageRecord(stageId)
    if not record then
        return 0
    end
    return record:GetStarMask()
end

function XRogueSimControl:GetStageStarCount(starsMark)
    local count = (starsMark & 1) + (starsMark & 2 > 0 and 1 or 0) + (starsMark & 4 > 0 and 1 or 0)
    local map = { (starsMark & 1) > 0, (starsMark & 2) > 0, (starsMark & 4) > 0 }
    return count, map
end

-- 将数字转换为按k显示（大于100000（十万），小于1k的直接忽略）
function XRogueSimControl:ConvertNumToK(num)
    if num < 100000 then
        return num
    end
    return string.format("%sk", math.floor(num / 1000))
end

-- 将数字转换为按w显示（小于1w的直接忽略）
function XRogueSimControl:ConvertNumToW(num)
    if num < XEnumConst.RogueSim.Denominator then
        return num
    end
    return string.format("%sw", math.floor(num / XEnumConst.RogueSim.Denominator))
end

-- 检查当前关卡是否是教学关
function XRogueSimControl:CheckCurStageIsTeach()
    local stageId = self:GetCurStageId()
    if not XTool.IsNumberValid(stageId) then
        return false
    end
    return self:GetRogueSimStageType(stageId) == self._Model.StageType.Teach
end

-- 检查当前关卡三星条件是否满足
function XRogueSimControl:CheckCurStageStarConditions()
    local stageId = self:GetCurStageId()
    local conditionIds = self:GetRogueSimStageStarConditions(stageId)
    for _, conditionId in pairs(conditionIds) do
        if not self.ConditionSubControl:CheckCondition(conditionId) then
            return false
        end
    end
    return true
end

--endregion

--region 主城等级相关

-- 获取当前主城等级
function XRogueSimControl:GetCurMainLevel()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetMainLevel()
end

-- 获取主城最大等级
function XRogueSimControl:GetMaxMainLevel()
    local levelGroup = self:GetCurStageLevelGroup()
    return self._Model:GetMaxMainLevel(levelGroup)
end

-- 获取主城等级列表
function XRogueSimControl:GetMainLevelList()
    local levelGroup = self:GetCurStageLevelGroup()
    return self._Model:GetMainLevelIdList(levelGroup)
end

-- 获取主城等级配置Id
function XRogueSimControl:GetMainLevelConfigId(level)
    local levelGroup = self:GetCurStageLevelGroup()
    return self._Model:GetMainLevelId(levelGroup, level)
end

-- 获取当前等级升级需要的经验数
function XRogueSimControl:GetCurLevelUpExpCount(level)
    return self:GetLevelUpResourceCount(level, XEnumConst.RogueSim.ResourceId.Exp)
end

-- 获取当前等级升级需要的金币数
function XRogueSimControl:GetCurLevelUpGoldCount(level)
    return self:GetLevelUpResourceCount(level, XEnumConst.RogueSim.ResourceId.Gold)
end

-- 获取当前主城等级升级需要的金币数（打折后）
function XRogueSimControl:GetCurLevelUpGoldCountWithDiscount(level)
    local count = self:GetCurLevelUpGoldCount(level)
    return self.BuffSubControl:GetMainDiscountPrice(count)
end

-- 获取升级需要的资源数量
function XRogueSimControl:GetLevelUpResourceCount(level, resourceId)
    local id = self:GetMainLevelConfigId(level)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    local resourceIds = config and config.LevelUpResourceIds or {}
    local resourceIdCounts = config and config.LevelUpResourceCounts or {}
    local contain, index = table.contains(resourceIds, resourceId)
    if contain then
        return resourceIdCounts[index] or 0
    end
    return 0
end

-- 获取解锁科技等级
function XRogueSimControl:GetMainLevelUnlockTechLevel(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.UnlockTechLevel or 0
end

-- 获取解锁区域索引
function XRogueSimControl:GetMainLevelUnlockAreaIdxs(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.UnlockAreaIdxs or {}
end

function XRogueSimControl:GetMainLevelRewardResourceIds(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.RewardResourceIds or {}
end

function XRogueSimControl:GetMainLevelRewardResourceCounts(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.RewardResourceCounts or {}
end

function XRogueSimControl:GetMainLevelUnlockBuildCount(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.UnlockBuildCount or 0
end

function XRogueSimControl:GetMainLevelRewardBluePrintIds(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.RewardBluePrintIds or {}
end

function XRogueSimControl:GetMainLevelRewardBluePrintCounts(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.RewardBluePrintCounts or {}
end

-- 获取主城配置等级
function XRogueSimControl:GetMainLevelConfigLevel(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.Level or 0
end

-- 获取主城名称
function XRogueSimControl:GetMainLevelName(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.Name or ""
end

-- 获取主城简略描述
function XRogueSimControl:GetMainLevelBriefDesc(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.BriefDesc or ""
end

-- 获取主城描述
function XRogueSimControl:GetMainLevelDesc(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    local desc = config and config.Desc or ""
    return XUiHelper.ReplaceTextNewLine(desc)
end

-- 获取主城地貌Id
function XRogueSimControl:GetMainLevelLandformId(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.LandformId or 0
end

-- 获取主城图片
function XRogueSimControl:GetMainLevelIcon(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.Icon or ""
end

-- 获取主城小图片
function XRogueSimControl:GetMainLevelSmallIcon(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.SmallIcon or ""
end

-- 获取当前经验和升级经验
function XRogueSimControl:GetCurExpAndLevelUpExp(level)
    -- 当前经验
    local curExp = self.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Exp)
    -- 升级经验
    local levelUpExp = self:GetCurLevelUpExpCount(level)
    return curExp, levelUpExp
end

-- 检查是否是最大等级
function XRogueSimControl:CheckIsMaxLevel(level)
    local maxLevel = self:GetMaxMainLevel()
    return level >= maxLevel
end

-- 检查主城升级金币是否充足
function XRogueSimControl:CheckLevelUpGoldIsEnough(level)
    local curGold = self.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Gold)
    local levelUpGold = self:GetCurLevelUpGoldCountWithDiscount(level)
    return curGold >= levelUpGold
end

-- 检查主城是否可升级
function XRogueSimControl:CheckMainLevelCanLevelUp()
    -- 关卡数据为空
    if self:CheckStageDataIsEmpty() then
        return false, ""
    end
    local curLevel = self:GetCurMainLevel()
    -- 已满级
    if self:CheckIsMaxLevel(curLevel) then
        return false, self:GetClientConfig("MainLevelCanLevelUpTips", 1)
    end
    -- 经验不足
    local curExp, upExp = self:GetCurExpAndLevelUpExp(curLevel)
    if curExp < upExp then
        return false, self:GetClientConfig("MainLevelCanLevelUpTips", 2)
    end
    -- 金币不足
    if not self:CheckLevelUpGoldIsEnough(curLevel) then
        return false, self:GetClientConfig("MainLevelCanLevelUpTips", 3)
    end
    return true, ""
end

--endregion

--region 奖励相关

-- 获取所有奖励
function XRogueSimControl:GetRewardData()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return {}
    end
    return stageData:GetRewardData()
end

-- 获取奖励数据通过格子Id
function XRogueSimControl:GetRewardDataByGridId(gridId)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetRewardDataByGridId(gridId)
end

-- 获取奖励数据通过来源和格子Id
function XRogueSimControl:GetRewardDataBySourceAndGridId(source, gridId)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetRewardDataBySourceAndGridId(source, gridId)
end

-- 获取多选道具奖励列表信息
function XRogueSimControl:GetMultiSelectPropRewardListById(id)
    local rewardData = self._Model:GetRewardDataById(id)
    if not rewardData then
        return {}
    end
    local rewardIds = rewardData:GetRewards()
    local rewardList = {}
    for _, rewardId in ipairs(rewardIds) do
        local itemIds = self:GetRewardItemIds(rewardId)
        local itemNums = self:GetRewardItemNums(rewardId)
        local types = self:GetRewardTypes(rewardId)
        -- 默认取第一个
        table.insert(rewardList, { ItemId = itemIds[1], Num = itemNums[1], Type = types[1] })
    end
    return rewardList
end

-- 获取奖励列表信息
---@param configId number 奖励配置Id
---@return { ItemId:number, Num:number,Type:number }[] 奖励列表
function XRogueSimControl:GetRewardListByConfigId(configId)
    local itemIds = self:GetRewardItemIds(configId)
    local itemNums = self:GetRewardItemNums(configId)
    local types = self:GetRewardTypes(configId)
    local rewardList = {}
    for i, itemId in ipairs(itemIds) do
        table.insert(rewardList, { ItemId = itemId, Num = itemNums[i], Type = types[i] })
    end
    return rewardList
end

-- 获取奖励类型
function XRogueSimControl:GetRewardTypes(id)
    local config = self._Model:GetRogueSimRewardConfig(id)
    return config and config.Types or 0
end

-- 获取奖励物品Ids
function XRogueSimControl:GetRewardItemIds(id)
    local config = self._Model:GetRogueSimRewardConfig(id)
    return config and config.ItemIds or {}
end

-- 获取奖励物品数量
function XRogueSimControl:GetRewardItemNums(id)
    local config = self._Model:GetRogueSimRewardConfig(id)
    return config and config.Nums or {}
end

-- 获取奖励掉落的类型
function XRogueSimControl:GetRewardDropType(id)
    local config = self._Model:GetRogueSimRewardDropConfig(id)
    return config and config.Type or 0
end

-- 获取奖励图标
---@param type number 奖励类型 XEnumConst.RogueSim.RewardType
---@param configId number 配置Id
function XRogueSimControl:GetRewardIcon(type, configId)
    if type == XEnumConst.RogueSim.RewardType.Resource then
        return self.ResourceSubControl:GetResourceIcon(configId)
    elseif type == XEnumConst.RogueSim.RewardType.Commodity then
        return self.ResourceSubControl:GetCommodityIcon(configId)
    elseif type == XEnumConst.RogueSim.RewardType.Prop then
        return self.MapSubControl:GetPropIcon(configId)
    elseif type == XEnumConst.RogueSim.RewardType.Building then
        return self.MapSubControl:GetBuildingIcon(configId)
    elseif type == XEnumConst.RogueSim.RewardType.Event then
        XLog.Warning("XRogueSimControl:GetRewardIcon Error: RewardType is Event")
    elseif type == XEnumConst.RogueSim.RewardType.City then
        return self.MapSubControl:GetCityLevelIcon(configId)
    elseif type == XEnumConst.RogueSim.RewardType.BuildBluePrint then
        return self.MapSubControl:GetBuildingBluePrintIcon(configId)
    end
    return nil
end

-- 获取奖励名称
---@param type number 奖励类型 XEnumConst.RogueSim.RewardType
---@param configId number 配置Id
function XRogueSimControl:GetRewardName(type, configId)
    if type == XEnumConst.RogueSim.RewardType.Resource then
        return self.ResourceSubControl:GetResourceName(configId)
    elseif type == XEnumConst.RogueSim.RewardType.Commodity then
        return self.ResourceSubControl:GetCommodityName(configId)
    elseif type == XEnumConst.RogueSim.RewardType.Prop then
        return self.MapSubControl:GetPropName(configId)
    elseif type == XEnumConst.RogueSim.RewardType.Building then
        return self.MapSubControl:GetBuildingName(configId)
    elseif type == XEnumConst.RogueSim.RewardType.Event then
        return self.MapSubControl:GetEventName(configId)
    elseif type == XEnumConst.RogueSim.RewardType.City then
        return self.MapSubControl:GetCityLevelName(configId)
    elseif type == XEnumConst.RogueSim.RewardType.BuildBluePrint then
        -- 使用建筑的名称
        local buildId = self.MapSubControl:GetBuildingIdByBluePrintId(configId)
        return self.MapSubControl:GetBuildingName(buildId)
    end
    return ""
end

-- 获取奖励描述
---@param type number 奖励类型 XEnumConst.RogueSim.RewardType
---@param configId number 配置Id
function XRogueSimControl:GetRewardDesc(type, configId)
    if type == XEnumConst.RogueSim.RewardType.Resource then
        return self.ResourceSubControl:GetResourceDesc(configId)
    elseif type == XEnumConst.RogueSim.RewardType.Commodity then
        XLog.Warning("XRogueSimControl:GetRewardDesc Error: RewardType is Commodity")
    elseif type == XEnumConst.RogueSim.RewardType.Prop then
        return self.MapSubControl:GetPropEffectDesc(configId)
    elseif type == XEnumConst.RogueSim.RewardType.Building then
        return self.MapSubControl:GetBuildingDesc(configId)
    elseif type == XEnumConst.RogueSim.RewardType.Event then
        return self.MapSubControl:GetEventText(configId)
    elseif type == XEnumConst.RogueSim.RewardType.City then
        return self.MapSubControl:GetCityLevelDesc(configId)
    elseif type == XEnumConst.RogueSim.RewardType.BuildBluePrint then
        -- 使用建筑的描述
        local buildId = self.MapSubControl:GetBuildingIdByBluePrintId(configId)
        return self.MapSubControl:GetBuildingDesc(buildId)
    end
    return ""
end

--endregion

--region 弹框相关

-- 开始下一步之前
function XRogueSimControl:StartNextStepBefore(uiName, callback)
    if string.IsNilOrEmpty(uiName) then
        if callback then
            callback()
        end
        return
    end
    XLuaUiManager.CloseWithCallback(uiName, callback)
end

-- 获取具有弹框数据的弹框类型列表
---@return number[] 弹框类型列表
function XRogueSimControl:GetHasDataPopupTypeList()
    local types = {}
    for _, type in pairs(XEnumConst.RogueSim.PopupType) do
        if type ~= XEnumConst.RogueSim.PopupType.None and not self:CheckPopupDataIsEmptyByType(type) then
            table.insert(types, type)
        end
    end

    -- 场景表现弹框类型
    for _, type in pairs(self:GetScenePopupTypes()) do
        table.insert(types, type)
    end

    -- 去重
    types = table.unique(types, true)
    if #types > 1 then
        table.sort(types, function(a, b)
            return a < b
        end)
    end
    return types
end

-- 获取场景表现弹框类型列表
---@return number[] 弹框类型列表
function XRogueSimControl:GetScenePopupTypes()
    local types = {}
    if not self.RogueSimScene then
        return types
    end

    local sceneChecks = {
        { check = self.RogueSimScene.CheckHasAreaCanUnlock, type = XEnumConst.RogueSim.PopupType.AreaCanUnlock },
        { check = self.RogueSimScene.CheckHasAreaUnlock,    type = XEnumConst.RogueSim.PopupType.AreaUnlock },
        { check = self.RogueSimScene.CheckHasGridLevelUp,   type = XEnumConst.RogueSim.PopupType.GridLevelUp },
        { check = self.RogueSimScene.CheckHasExploreCache,  type = XEnumConst.RogueSim.PopupType.ExploreGrid },
        { check = self.RogueSimScene.CheckHasVisibleCache,  type = XEnumConst.RogueSim.PopupType.VisibleGrid },
        { check = self.RogueSimScene.CheckCacheChangeGrid,  type = XEnumConst.RogueSim.PopupType.ChangeGrid },
    }

    for _, sceneCheck in ipairs(sceneChecks) do
        if sceneCheck.check(self.RogueSimScene) then
            table.insert(types, sceneCheck.type)
        end
    end

    return types
end

-- 设置下一个目标弹框类型
---@param nextTargetType number 下一个目标弹框类型
function XRogueSimControl:SetNextTargetPopupType(nextTargetType)
    self._Model.NextTargetPopupType = nextTargetType
end

-- 清理下一个目标弹框类型
function XRogueSimControl:ClearNextTargetPopupType()
    self._Model.NextTargetPopupType = XEnumConst.RogueSim.PopupType.None
end

-- 获取下一个需要弹的弹框类型
---@param nextType number 下一个弹框类型 指定下一个弹框类型 有就弹，没有就弹其它的弹框
---@return number 弹框类型
function XRogueSimControl:GetNextPopupType(nextType)
    local types = self:GetHasDataPopupTypeList()
    if XTool.IsTableEmpty(types) then
        return XEnumConst.RogueSim.PopupType.None
    end

    self._Model.NextTargetPopupType = self._Model.NextTargetPopupType or XEnumConst.RogueSim.PopupType.None
    if self._Model.NextTargetPopupType ~= XEnumConst.RogueSim.PopupType.None then
        for _, type in ipairs(types) do
            if type == self._Model.NextTargetPopupType then
                return type
            end
        end
        return XEnumConst.RogueSim.PopupType.None
    end

    nextType = nextType or XEnumConst.RogueSim.PopupType.None
    if nextType ~= XEnumConst.RogueSim.PopupType.None then
        for _, type in ipairs(types) do
            if type == nextType then
                return type
            end
        end
    end

    return types[1]
end

-- 检查是否需要打开下一个弹框
---@param uiName string 界面名
---@param isNeedClose boolean 是否需要关闭当前弹框
---@param typeData { NextType:number, ArgType:number } 弹框类型数据 NextType:下一个弹框类型 ArgType:参数类型
function XRogueSimControl:CheckNeedShowNextPopup(uiName, isNeedClose, typeData, ...)
    typeData = typeData or {}
    local nextPopupType = self:GetNextPopupType(typeData.NextType)
    if nextPopupType == XEnumConst.RogueSim.PopupType.None then
        if isNeedClose then
            XLuaUiManager.Close(uiName)
        end
        return
    end

    local arg = (typeData.ArgType ~= nil and typeData.ArgType == nextPopupType) and { ... } or nil
    local showPopup = function()
        self:ShowPopup(nextPopupType, table.unpack(arg or {}))
    end

    if isNeedClose then
        self:StartNextStepBefore(uiName, showPopup)
    else
        showPopup()
    end
end

-- 显示弹框
function XRogueSimControl:ShowPopup(type, ...)
    local popupHandlers = {
        [XEnumConst.RogueSim.PopupType.PropSelect] = self.ShowPropSelectPopup,
        [XEnumConst.RogueSim.PopupType.Reward] = self.ShowRewardPopup,
        [XEnumConst.RogueSim.PopupType.Task] = self.ShowTaskPopup,
        [XEnumConst.RogueSim.PopupType.TurnReward] = self.ShowTurnRewardPopup,
        [XEnumConst.RogueSim.PopupType.MainLevelUp] = self.ShowMainLevelUpPopup,
        [XEnumConst.RogueSim.PopupType.CityLevelUp] = self.ShowCityLevelUpPopup,
        [XEnumConst.RogueSim.PopupType.NewTips] = self.ShowNewTipsPopup,
        [XEnumConst.RogueSim.PopupType.AreaCanUnlock] = function() self.RogueSimScene:PlayAreaCanUnlock() end,
        [XEnumConst.RogueSim.PopupType.AreaUnlock] = function() self.RogueSimScene:PlayAreaUnlock() end,
        [XEnumConst.RogueSim.PopupType.GridLevelUp] = function() self.RogueSimScene:PlaGridLevelUp() end,
        [XEnumConst.RogueSim.PopupType.ExploreGrid] = function() self.RogueSimScene:PlayCacheExploreGrids() end,
        [XEnumConst.RogueSim.PopupType.VisibleGrid] = function() self.RogueSimScene:PlayCacheVisibleGrids() end,
        [XEnumConst.RogueSim.PopupType.ChangeGrid] = function() self.RogueSimScene:PlayCacheChangeGrid() end,
    }
    local handler = popupHandlers[type]
    if handler then
        handler(self, ...)
    else
        XLog.Error("ShowPopup error type" .. type)
    end
end

-- 显示奖励弹框
function XRogueSimControl:ShowRewardPopup(rewardId)
    local data = self._Model:DequeuePopupData(XEnumConst.RogueSim.PopupType.Reward, rewardId)
    if not data then
        return
    end
    -- 奖励类型 默认取第一个物品进行判断
    local type = data.RewardItems[1].Type
    if type == XEnumConst.RogueSim.RewardType.Resource
        or type == XEnumConst.RogueSim.RewardType.Commodity
        or type == XEnumConst.RogueSim.RewardType.Prop
        or type == XEnumConst.RogueSim.RewardType.BuildBluePrint
        or type == XEnumConst.RogueSim.RewardType.Building then
        XLuaUiManager.Open("UiRogueSimRewardPopup", data.RewardItems)
    elseif type == XEnumConst.RogueSim.RewardType.Event then
        self.MapSubControl:ExploreEventGrid(data.RewardItems[1].ObjectId)
    else
        XLog.Error("ShowRewardPopup error type" .. type)
    end
end

-- 显示道具选择弹框
function XRogueSimControl:ShowPropSelectPopup(gridId, source)
    local data = self._Model:DequeuePopupData(XEnumConst.RogueSim.PopupType.PropSelect, gridId, source)
    if not data or not data.Reward then
        return
    end
    self.MapSubControl:ExplorePropGrid(data.Reward.Id)
end

-- 显示任务弹框
function XRogueSimControl:ShowTaskPopup()
    local data = self._Model:DequeuePopupData(XEnumConst.RogueSim.PopupType.Task)
    if not data or not data.TaskData then
        return
    end
    ---@type XUiRogueSimBattle
    local luaUi = XLuaUiManager.GetTopLuaUi("UiRogueSimBattle")
    if luaUi then
        luaUi:OpenTaskSuccess(data.TaskData.Id)
    end
end

-- 显示回合奖励弹框
function XRogueSimControl:ShowTurnRewardPopup()
    local data = self._Model:DequeuePopupData(XEnumConst.RogueSim.PopupType.TurnReward)
    if XTool.IsTableEmpty(data) then
        return
    end
    XLuaUiManager.Open("UiRogueSimRewardPopup", data)
end

-- 显示主城等级提升弹框
function XRogueSimControl:ShowMainLevelUpPopup()
    local data = self._Model:DequeuePopupData(XEnumConst.RogueSim.PopupType.MainLevelUp)
    if XTool.IsTableEmpty(data) then
        return
    end
    XLuaUiManager.Open("UiRogueSimPopupCommonHorizontal", data)
end

-- 显示城邦等级提升弹窗
function XRogueSimControl:ShowCityLevelUpPopup()
    local data = self._Model:DequeuePopupData(XEnumConst.RogueSim.PopupType.CityLevelUp)
    if XTool.IsTableEmpty(data) then
        return
    end
    XLuaUiManager.Open("UiRogueSimPopupCommonHorizontal", data)
end

-- 显示新提示弹框
function XRogueSimControl:ShowNewTipsPopup()
    local data = self._Model:DequeuePopupData(XEnumConst.RogueSim.PopupType.NewTips)
    if XTool.IsTableEmpty(data) then
        return
    end
    local curTurnNumber = self:GetCurTurnNumber()
    local tipIds = data[curTurnNumber] or {}
    ---@type XUiRogueSimBattle
    local luaUi = XLuaUiManager.GetTopLuaUi("UiRogueSimBattle")
    if luaUi then
        luaUi:RefreshTips(tipIds)
    end
end

-- 检查弹框数据是否为空通过弹框类型
function XRogueSimControl:CheckPopupDataIsEmptyByType(type)
    return self._Model:CheckPopupDataEmpty(type)
end

-- 清空弹框数据通过弹框类型
function XRogueSimControl:ClearPopupDataByType(type)
    self._Model:ClearPopupDataByType(type)
end

-- 清空所有弹框数据
function XRogueSimControl:ClearAllPopupData()
    self._Model:ClearAllPopupData()
end

-- 通用确认弹框
function XRogueSimControl:ShowCommonTip(title, content, closeCallback, sureCallback, jumpCallBack, skipCallBack, data)
    if not title and not content then
        XLog.Error("XRogueSimControl.ShowCommonTip error, title and content is nil")
        return
    end
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_Big)
    XLuaUiManager.Open("UiRogueSimThreeTip", title, content, closeCallback, sureCallback, jumpCallBack, skipCallBack, data)
end

-- 显示事件效果弹框
function XRogueSimControl:ShowEventEffectPopup(name, data)
    self:StartNextStepBefore(name, function()
        XLuaUiManager.Open("UiRogueSimRewardPopup", data)
    end)
end

--endregion

--region 场景方法相关

-- 摄像机聚焦到格子
function XRogueSimControl:CameraFocusGrid(gridId, cb)
    if not self.RogueSimScene then
        return
    end
    self.RogueSimScene:CameraFocusGrid(gridId, cb)
end

-- 摄像机聚焦到主城
function XRogueSimControl:CameraFocusMainGrid(cb)
    if not self.RogueSimScene then
        return
    end
    self.RogueSimScene:CameraFocusMainGrid(cb)
end

-- 获取主城格子Id
function XRogueSimControl:GetMainGridId()
    if not self.RogueSimScene then
        return 0
    end
    return self.RogueSimScene.MainGridId
end

-- 模拟格子点击
function XRogueSimControl:SimulateGridClick(gridId)
    if not self.RogueSimScene then
        return
    end
    local grid = self.RogueSimScene:GetGrid(gridId)
    self.RogueSimScene:OnGridClick(grid, true)
end

-- 模拟格子点击前处理
function XRogueSimControl:SimulateGridClickBefore(name, gridId)
    self:StartNextStepBefore(name, function()
        self:SimulateGridClick(gridId)
    end)
end

-- 跳转到格子前处理
function XRogueSimControl:JumpToGridBefore(name, gridId)
    self:StartNextStepBefore(name, function()
        self:CameraFocusGrid(gridId)
    end)
end

-- 打开事件弹框之前处理
function XRogueSimControl:OpenEventPopupBefore(name, eventId, eventGambleId)
    self:StartNextStepBefore(name, function()
        if XTool.IsNumberValid(eventGambleId) then
            self.MapSubControl:EventGambleGridClick(eventGambleId)
        else
            self.MapSubControl:ExploreEventGrid(eventId)
        end
    end)
end

-- 获取区域Id通过格子Id
---@param gridId number 格子Id
function XRogueSimControl:GetAreaIdByGridId(gridId)
    if not self.RogueSimScene then
        return 0
    end
    local grid = self.RogueSimScene:GetGrid(gridId)
    return grid and grid.AreaId or 0
end

-- 获取可探索格子Id列表
function XRogueSimControl:GetCanExploreGridIds()
    if not self.RogueSimScene then
        return {}
    end
    return self.RogueSimScene:GetCanExploreGridIds()
end

-- 清除格子选中特效
function XRogueSimControl:ClearGridSelectEffect()
    if not self.RogueSimScene then
        return
    end
    return self.RogueSimScene:ClearGridSelectEffect()
end

-- 获取格子对象
function XRogueSimControl:GetGrid(gridId)
    if not self.RogueSimScene then
        return
    end
    return self.RogueSimScene:GetGrid(gridId)
end

-- 点击主城格子
function XRogueSimControl:OnMainGridClick()
    if not self.RogueSimScene then
        return
    end
    return self.RogueSimScene:OnMainGridClick()
end

-- 设置摄像机高度
function XRogueSimControl:SetCameraDistance(distance)
    if not self.RogueSimScene then
        return
    end
    return self.RogueSimScene:SetCameraDistance(distance)
end

-- 是否正在播放区域动画
function XRogueSimControl:IsPlayAreaAnim()
    if not self.RogueSimScene then
        return
    end
    return self.RogueSimScene.IsPlayAreaAnim
end

--endregion

--region 任务相关

-- 获取完成任务的数量
function XRogueSimControl:GetFinishedTaskCount()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    local taskData = stageData:GetTaskData()
    local count = 0
    for _, data in pairs(taskData) do
        if data:GetState() == self._Model.TaskState.Finished then
            count = count + 1
        end
    end
    return count
end

-- 获取任务配置Id
---@param id number 自增Id
function XRogueSimControl:GetTaskConfigIdById(id)
    local taskData = self._Model:GetTaskDataById(id)
    if not taskData then
        return 0
    end
    return taskData:GetConfigId()
end

-- 获取任务进度
---@param id number 自增Id
function XRogueSimControl:GetTaskScheduleById(id)
    local taskData = self._Model:GetTaskDataById(id)
    if not taskData then
        return 0
    end
    return taskData:GetSchedule()
end

-- 检查任务是否已完成
---@param id number 自增Id
function XRogueSimControl:CheckTaskIsFinished(id)
    local taskData = self._Model:GetTaskDataById(id)
    if not taskData then
        return false
    end
    return taskData:GetState() == self._Model.TaskState.Finished
end

-- 获取任务名称
function XRogueSimControl:GetTaskName(id)
    local config = self._Model:GetRogueSimTaskConfig(id)
    return config and config.TaskName or ""
end

-- 获取任务描述
function XRogueSimControl:GetTaskDesc(id)
    local config = self._Model:GetRogueSimTaskConfig(id)
    local desc = config and config.TaskDesc or ""
    local conditionParams = config and config.ConditionParams or {}
    local totalNum = 0
    if #conditionParams == 4 and conditionParams[4] == 1 then
        totalNum = conditionParams[3] or 0
    else
        totalNum = config and config.Schedule or 0
    end
    local totalNumStr = self:ConvertNumToW(totalNum)
    return XUiHelper.FormatText(desc, totalNumStr)
end

-- 获取任务条件Id
function XRogueSimControl:GetTaskConditionId(id)
    local config = self._Model:GetRogueSimTaskConfig(id)
    return config and config.ConditionId or 0
end

-- 获取任务条件参数
function XRogueSimControl:GetTaskConditionParams(id)
    local config = self._Model:GetRogueSimTaskConfig(id)
    return config and config.ConditionParams or {}
end

-- 获取任务BuffIds
function XRogueSimControl:GetTaskBuffIds(id)
    local config = self._Model:GetRogueSimTaskConfig(id)
    return config and config.BuffIds or {}
end

-- 获取任务目标数量
function XRogueSimControl:GetTaskTargetNumber(id)
    local config = self._Model:GetRogueSimTaskConfig(id)
    return config and config.Schedule or 0
end

-- 获取任务完成值和总值
---@param id number 自增Id
---@param configId number 配置Id
function XRogueSimControl:GetTaskScheduleAndTotalNum(id, configId)
    local schedule = self:GetTaskScheduleById(id)
    local totalNum = self:GetTaskTargetNumber(configId)
    schedule = schedule > totalNum and totalNum or schedule
    return schedule, totalNum
end

--endregion

--region 信物相关

-- 获取当前信物Id
function XRogueSimControl:GetCurTokenId()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetTokenId()
end

-- 获取信息名称
function XRogueSimControl:GetTokenName(id)
    local config = self._Model:GetRogueSimTokenConfig(id)
    return config and config.Name or ""
end

-- 获取信物描述
function XRogueSimControl:GetTokenDesc(id)
    local config = self._Model:GetRogueSimTokenConfig(id)
    return config and config.Desc or ""
end

-- 获取信物效果描述
function XRogueSimControl:GetTokenEffectDesc(id)
    local config = self._Model:GetRogueSimTokenConfig(id)
    return config and XUiHelper.ConvertLineBreakSymbol(config.EffectDesc) or ""
end

-- 获取信物Icon
function XRogueSimControl:GetTokenIcon(id)
    local config = self._Model:GetRogueSimTokenConfig(id)
    return config and config.Icon or ""
end

-- 获取信物稀有值
function XRogueSimControl:GetTokenRare(id)
    local config = self._Model:GetRogueSimTokenConfig(id)
    return config and config.Rare or 0
end

-- 获取信物BuffIds
function XRogueSimControl:GetTokenBuffIds(id)
    local config = self._Model:GetRogueSimTokenConfig(id)
    return config and config.BuffIds or {}
end

-- 获取信物是否显示城邦视野
function XRogueSimControl:GetTokenIsShowCity(id)
    local config = self._Model:GetRogueSimTokenConfig(id)
    return config and config.IsShowCity or false
end

--endregion

--region 波动相关

-- 获取当前波动数据
function XRogueSimControl:GetCurVolatilityData()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetVolatilityData()
end

-- 获取波动Tag
function XRogueSimControl:GetVolatilityTag(id)
    local config = self._Model:GetRogueSimVolatilityConfig(id)
    return config and config.Tag or 0
end

-- 获取波动BuffId
function XRogueSimControl:GetVolatilityBuffId(id)
    local config = self._Model:GetRogueSimVolatilityConfig(id)
    return config and config.BuffId or 0
end

-- 获取波动延迟
function XRogueSimControl:GetVolatilityDelay(id)
    local config = self._Model:GetRogueSimVolatilityConfig(id)
    return config and config.Delay or 0
end

-- 获取波动持续时间
function XRogueSimControl:GetVolatilityDuration(id)
    local config = self._Model:GetRogueSimVolatilityConfig(id)
    return config and config.Duration or 0
end

-- 获取波动传闻Id
function XRogueSimControl:GetVolatilityTipId(id)
    local config = self._Model:GetRogueSimVolatilityConfig(id)
    return config and config.TipId or 0
end

--endregion

--region 传闻相关

-- 获取传闻描述
function XRogueSimControl:GetTipContent(id)
    local config = self._Model:GetRogueSimTipConfig(id)
    return config and config.Content or ""
end

-- 获取传闻图标
function XRogueSimControl:GetTipIcon(id)
    local config = self._Model:GetRogueSimTipConfig(id)
    return config and config.Icon or ""
end

-- 获取所有传闻记录
function XRogueSimControl:GetTipRecordList()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetTipRecordList()
end

-- 获取单个传闻记录通过回合数
function XRogueSimControl:GetTipRecordByTurnNumber(turnNumber)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetTipRecordByTurnNumber(turnNumber)
end

-- 获取当前回合数的传闻Ids
function XRogueSimControl:GetCurTurnTipIds()
    local curTurn = self:GetCurTurnNumber()
    local tipRecord = self:GetTipRecordByTurnNumber(curTurn)
    if not tipRecord then
        return {}
    end
    return tipRecord:GetTipIds()
end

-- 获取所有的传闻  -- TODO 待删除
function XRogueSimControl:GetAllTipList()
    local gridTips = self:GetGridTipList()
    local eventTips = self:GetEventTipList()
    local volatilityTips = self:GetVolatilityTipList()
    return XTool.MergeArray(gridTips, eventTips, volatilityTips)
end

-- 获取格子传闻列表 -- TODO 待删除
function XRogueSimControl:GetGridTipList()
    if not self.RogueSimScene then
        return nil
    end
    return self.RogueSimScene:GetGridTipList()
end

-- 获取事件传闻列表 -- TODO 待删除
function XRogueSimControl:GetEventTipList()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    local eventData = stageData:GetEventData()
    if not eventData then
        return nil
    end
    local curTurn = self:GetCurTurnNumber()
    local gridIds = {}
    for _, event in pairs(eventData) do
        -- 初次触发：获取事件的回合数 == 当前回合数
        if event:GetCreateTurnNumber() == curTurn then
            table.insert(gridIds, event:GetGridId())
        end
    end
    if #gridIds == 0 then
        return nil
    end
    local tips = {}
    for _, gridId in ipairs(gridIds) do
        local buildingData = self.MapSubControl:GetBuildingDataByGridId(gridId)
        if buildingData then
            local tipId = self.MapSubControl:GetBuildingTipId(buildingData:GetConfigId())
            local msg = self:GetTipContent(tipId)
            table.insert(tips, msg)
        end
    end
    return tips
end

-- 获取波动传闻列表  -- TODO 待删除
function XRogueSimControl:GetVolatilityTipList()
    local volatilityData = self:GetCurVolatilityData()
    if not volatilityData then
        return nil
    end
    local volatilityId = volatilityData:GetId()
    if not XTool.IsNumberValid(volatilityId) then
        return nil
    end
    local volatilityTurn = volatilityData:GetTurn()
    local curTurn = self:GetCurTurnNumber()
    -- 波动延迟回合数
    local delay = self:GetVolatilityDelay(volatilityId)
    -- 当前回合数 <= VolatilityId生效的回合数 + 延迟的回合数
    if curTurn <= volatilityTurn + delay then
        local tipId = self:GetVolatilityTipId(volatilityId)
        local msg = self:GetTipContent(tipId)
        return { msg }
    end
    return nil
end

--endregion

--region 科技树相关

-- 根据当前主城等级，计算当前科技树等级
function XRogueSimControl:GetCurTechLv()
    local mainLv = self:GetCurMainLevel()
    while (mainLv > 0) do
        local id = self:GetMainLevelConfigId(mainLv)
        local techLv = self:GetMainLevelUnlockTechLevel(id)
        if techLv ~= 0 then
            return techLv
        end
        mainLv = mainLv - 1
    end
    return 0
end

function XRogueSimControl:GetTechData()
    if self._Model.ActivityData then
        return self._Model.ActivityData:GetTechData()
    end
    return nil
end

-- 获取科技折扣后的价格
function XRogueSimControl:GetTechDiscountPrice(count)
    return self.BuffSubControl:GetTechDiscountPrice(count)
end

-- 获取科技树配置列表
function XRogueSimControl:GetRogueSimTechConfigs()
    return self._Model:GetRogueSimTechConfigs()
end

-- 获取科技树配置
function XRogueSimControl:GetRogueSimTechConfig(id)
    return self._Model:GetRogueSimTechConfig(id)
end

-- 获取关键科技树列表
function XRogueSimControl:GetRogueSimTechLevelConfigs()
    return self._Model:GetRogueSimTechLevelConfigs()
end

-- 获取关键科技树配置
function XRogueSimControl:GetRogueSimTechLevelConfig(lv)
    return self._Model:GetRogueSimTechLevelConfig(lv)
end

-- 检测是否有科技解锁红点
function XRogueSimControl:CheckHasTechUnlockRedPoint()
    local techLv = self:GetCurTechLv()
    local localTechLv = self:GetSaveTechUnlockLevel()
    if techLv == 0 and localTechLv ~= 0 then
        self:SaveTechUnlockLevel(techLv)
        return false
    end
    return techLv > localTechLv
end

--endregion

--region 图鉴相关

-- 获取已解锁的图鉴列表
function XRogueSimControl:GetIllustrates()
    if self._Model.ActivityData then
        return self._Model.ActivityData:GetIllustrates()
    end
    return {}
end

-- 获取图鉴配置列表
function XRogueSimControl:GetRogueSimIllustrateConfigs()
    return self._Model:GetRogueSimIllustrateConfigs()
end

-- 获取图鉴配置
function XRogueSimControl:GetRogueSimIllustrateConfig(id)
    return self._Model:GetRogueSimIllustrateConfig(id)
end

-- 获取显示红点的图鉴id列表
function XRogueSimControl:GetShowRedIllustrates()
    local saveKey = self:GetIllustrateRedKey()
    local removeIdDic = XSaveTool.GetData(saveKey) or {}

    local illustrates = self:GetIllustrates()
    local redIds = {}
    for _, id in ipairs(illustrates) do
        if not removeIdDic[id] then
            table.insert(redIds, id)
        end
    end
    return redIds
end

-- 移除图鉴列表的红点
function XRogueSimControl:RemoveIllustratesRed(ids)
    if #ids == 0 then
        return
    end

    local saveKey = self:GetIllustrateRedKey()
    local removeIdDic = XSaveTool.GetData(saveKey) or {}
    for _, id in ipairs(ids) do
        if not removeIdDic[id] then
            removeIdDic[id] = true
        end
    end
    XSaveTool.SaveData(saveKey, removeIdDic)
end

function XRogueSimControl:GetIllustrateRedKey()
    local activityId = self._Model.ActivityData:GetActivityId()
    return string.format("XRogueSimControl_GetIllustrateRedKey_XPlayer.Id:%s_ActivityId:%s", XPlayer.Id, activityId)
end

--endregion

--region 客户端配置表相关

function XRogueSimControl:GetClientConfig(key, index)
    if not index then
        index = 1
    end
    return self._Model:GetClientConfig(key, index)
end

function XRogueSimControl:GetClientConfigParams(key)
    return self._Model:GetClientConfigParams(key)
end

--endregion

--region 进入场景相关

-- 从关卡界面进入场景
function XRogueSimControl:EnterSceneFromStage(stageId)
    -- 清理本地缓存
    self:ClearLocalCache()
    -- 打开loading界面
    self:OpenLoading()
    -- 关闭关卡和关卡详情界面
    XLuaUiManager.Remove("UiRogueSimChapterDetail")
    XLuaUiManager.Remove("UiRogueSimChapter")
    self:RogueSimStageStartRequest(stageId, function()
        -- 清除缓存摄像机位置
        self.MapSubControl:ClearLastCameraFollowPointPos()
        -- 进入场景
        self:EnterScene()
    end)
end

-- 从主界面进入场景
function XRogueSimControl:EnterSceneFromMain()
    -- 打开loading界面
    self:OpenLoading()
    -- 进入场景
    self:EnterScene()
end

-- 进入场景
function XRogueSimControl:EnterScene()
    -- 释放场景
    self:ReleaseScene()
    -- 请求关卡进入
    self:RogueSimStageEnterRequest(function()
        -- 等待场景的加载
        XLuaUiManager.SetMask(true)
        local XRogueSimScene = require("XModule/XRogueSim/XEntity/Scene/XRogueSimScene")
        self.RogueSimScene = self:AddSubControl(XRogueSimScene)
        self.RogueSimScene:LoadSceneAsync(function()
            -- 加载完毕
            self:AfterEnterScene()
            XLuaUiManager.SetMask(false)
        end)
    end)
end

-- 进入场景后
function XRogueSimControl:AfterEnterScene()
    -- 关闭load界面
    self:CloseLoading()

    -- 打开主界面
    -- 场景是异步加载，中途退出时，不需要再打开UiRogueSimBattle
    if self.RogueSimScene then
        XLuaUiManager.Open("UiRogueSimBattle")
    end
end

-- 退出场景
function XRogueSimControl:OnExitScene()
    self:ClearAllPopupData()
    self:ReleaseScene()
    self:RemoveStagePopup()
end

-- 释放场景
function XRogueSimControl:ReleaseScene()
    if self.RogueSimScene then
        self.RogueSimScene:SaveLastCameraFollowPointPos()
        self:RemoveSubControl(self.RogueSimScene)
        self.RogueSimScene = nil
    end
end

-- 移除关卡内的弹框界面
function XRogueSimControl:RemoveStagePopup()
    XLuaUiManager.Remove("UiRogueSimPopupRoundEnd")
    XLuaUiManager.Remove("UiRogueSimThreeTip")
end

-- 清理本地缓存数据
function XRogueSimControl:ClearLocalCache()
    -- 清除可重复触发的引导记录
    self:ClearGuideRecord()
    -- 清理建筑蓝图数据记录
    self:ClearBuildingBluePrintRecord()
    -- 清理临时生产和出售计划
    self:ClearTempProduceAndSellPlan()
end

-- 打开loading界面
function XRogueSimControl:OpenLoading()
    XLuaUiManager.Open("UiRogueSimLoading")
end

-- 关闭loading界面
function XRogueSimControl:CloseLoading()
    XLuaUiManager.Close("UiRogueSimLoading")
end

-- 获取loading显示配置
function XRogueSimControl:GetLoadingShowConfig()
    local configs = self._Model:GetLoadingTipsConfigs()
    if not configs then
        return nil
    end
    return XTool.WeightRandomSelect(configs)
end

-- 请求进入关卡失败处理
function XRogueSimControl:EnterStageFail()
    -- 关闭loading界面
    self:CloseLoading()
    -- 显示最上层的ui
    XLuaUiManager.ShowTopUi()
end

--endregion

--region 服务端信息请求

-- 请求关卡开始
---@param stageId number 关卡Id
function XRogueSimControl:RogueSimStageStartRequest(stageId, cb)
    local req = { StageId = stageId }
    XNetwork.Call(self.RequestName.RogueSimStageStartRequest, req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            self:EnterStageFail()
            return
        end
        self._Model.ActivityData:UpdateStageData(res.StageData)
        if cb then cb() end
    end)
end

-- 请求关卡进入
function XRogueSimControl:RogueSimStageEnterRequest(cb)
    XNetwork.Call(self.RequestName.RogueSimStageEnterRequest, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            self:EnterStageFail()
            return
        end
        if cb then cb() end
    end)
end

-- 请求探索格子
---@param gridId number 格子Id
function XRogueSimControl:RogueSimExploreGridRequest(gridId, cb)
    local req = { GridId = gridId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimExploreGridRequest, req, function(res)
        self.MapSubControl:ExploreGrid(res.Reward, res.CityId)
        if cb then cb() end
    end)
end

-- 请求设置商品计划
---@param producePlan table<number,number> key货物Id value生产力
---@param sellPlan table<number,number> key货物Id value出售数量
---@param sellPlanPreset table<number,number> key货物Id value出售比例
---@param producePlanScore table<number,number> key货物Id value生产评分
function XRogueSimControl:RogueSimCommoditySetupPlansRequest(producePlan, sellPlan, sellPlanPreset, producePlanScore, cb)
    XMessagePack.MarkAsTable(producePlan)
    XMessagePack.MarkAsTable(sellPlan)
    XMessagePack.MarkAsTable(sellPlanPreset)
    XMessagePack.MarkAsTable(producePlanScore)
    local req = { ProducePlan = producePlan, SellPlan = sellPlan, SellPlanPreset = sellPlanPreset, ProducePlanScore = producePlanScore }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimCommoditySetupPlansRequest, req, function(res)
        -- 更新生产和出售计划
        self._Model.ActivityData:UpdateProducePlan(producePlan)
        self._Model.ActivityData:UpdateSellPlan(sellPlan)
        self._Model.ActivityData:UpdateSellPlanPreset(sellPlanPreset)
        self._Model.ActivityData:UpdateProducePlanScore(producePlanScore)
        if cb then cb() end
    end)
end

-- 请求回合结算
function XRogueSimControl:RogueSimTurnSettleRequest(cb)
    self:ClearAllPopupData()
    self:RecordTurnSettleBeforeData()
    self._Model.IsRoundEnd = true
    XNetwork.Call(self.RequestName.RogueSimTurnSettleRequest, nil, function(res)
        self._Model.IsRoundEnd = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model.ActivityData:UpdateTurnNumber(res.TurnNumber)
        -- 清理临时生产和出售计划
        self:ClearTempProduceAndSellPlan()
        -- 清空货物出售计划
        self._Model.ActivityData:UpdateSellPlan()
        self._Model.ActivityData:UpdateCommodityPriceRates(res.CommodityPriceRates)
        self._Model.ActivityData:UpdateCommodityPriceRateIds(res.CommodityPriceRateIds)
        self._Model.ActivityData:AddSellResult(res.CommoditySellResult)
        self._Model.ActivityData:AddProduceResult(res.CommodityProduceResult)
        self:UpdateStageSettleData(res.StageSettleData, res.CommoditySellResult, res.CommodityProduceResult)
        self._Model:EnqueuePopupData(XEnumConst.RogueSim.PopupType.TurnReward, res.CommodityModifyInfo, res.ResourceModifyInfo)
        if cb then cb() end
    end)
end

-- 领取奖励请求
---@param id number 自增Id
---@param selects number[] 选中的下标列表
function XRogueSimControl:RogueSimPickRewardRequest(id, selects, cb)
    local req = { Id = id, Selects = selects }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimPickRewardRequest, req, function(res)
        if cb then cb(res.RewardIds) end
    end)
end

-- 请求主城升级
function XRogueSimControl:RogueSimMainLevelUpRequest(cb)
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimMainLevelUpRequest, nil, function(res)
        self._Model.ActivityData:UpdateMainLevel(res.MainLevel)
        self._Model:EnqueuePopupData(XEnumConst.RogueSim.PopupType.MainLevelUp, { IsMainCity = true })
        self.RogueSimScene:CacheLevelUpGridId(self.RogueSimScene.MainGridId)
        if cb then cb() end
    end)
end

-- 请求城邦升级
function XRogueSimControl:RogueSimCityLevelUpRequest(id, gridId, cb)
    local req = { Id = id }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimCityLevelUpRequest, req, function(res)
        self._Model:EnqueuePopupData(XEnumConst.RogueSim.PopupType.CityLevelUp, { CityId = id })
        self.RogueSimScene:CacheLevelUpGridId(gridId)
        if cb then cb() end
    end)
end

-- 解锁科技请求
function XRogueSimControl:RogueSimUnlockTechRequest(techId, cb)
    local req = { TechId = techId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimUnlockTechRequest, req, function(res)
        self._Model.ActivityData:UpdateTechData(res.TechData)
        if cb then cb() end
    end)
end

-- 解锁关键科技请求
function XRogueSimControl:RogueSimUnlockKeyTechRequest(techIds, cb)
    local req = { TechIds = techIds }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimUnlockKeyTechRequest, req, function(res)
        self._Model.ActivityData:UpdateTechData(res.TechData)
        if cb then cb() end
    end)
end

-- 放弃游戏 结算关卡请求
function XRogueSimControl:RogueSimStageSettleRequest(cb)
    -- 请求前先检查是否有关卡数据 避免重复请求
    if self:CheckStageDataIsEmpty() then
        if cb then cb() end
        return
    end
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimStageSettleRequest, nil, function(res)
        self:UpdateStageSettleData(res.StageSettleData)
        if cb then cb() end
    end)
end

-- 请求事件选择选项
---@param id number 自增Id
---@param optionId number 选项Id
function XRogueSimControl:RogueSimEventSelectOptionRequest(id, optionId, cb)
    local req = { Id = id, OptionId = optionId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimEventSelectOptionRequest, req, function(res)
        -- 更新当前格子的事件Id
        self._Model.ActivityData:UpdateGridEventId(id, res.NewEventId, res.NewRewardId, res.DeadlineTurnNumber)
        if cb then cb(res.NewEventId) end
    end)
end

-- 请求事件投机领取奖励
---@param id number 自增Id
function XRogueSimControl:RogueSimEventGambleGetRewardRequest(id, cb)
    local req = { Id = id }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimEventGambleGetRewardRequest, req, function(res)
        if cb then cb() end
    end)
end

-- 请求自建建筑
---@param gridId number 格子Id
---@param bluePrintId number 蓝图Id
function XRogueSimControl:RogueSimBuildByBluePrintRequest(gridId, bluePrintId, cb)
    local req = { GridId = gridId, BluePrintId = bluePrintId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimBuildByBluePrintRequest, req, function(res)
        self.RogueSimScene:PlayBuildSuccessEffect(gridId)
        if cb then cb() end
    end)
end

-- 请求建筑刷新奖励
function XRogueSimControl:RogueSimTemporaryBagGetRewardRequest(type, cb)
    if type == XEnumConst.RogueSim.BagGetRewardType.Commodity then
        self._Model.IsTempBagReward = true
    end
    local req = { Type = type }
    XNetwork.Call(self.RequestName.RogueSimTemporaryBagGetRewardRequest, req, function(res)
        self._Model.IsTempBagReward = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

-- 请求解锁区域
---@param areaId number 区域Id
function XRogueSimControl:RogueSimUnlockAreaRequest(areaId, cb)
    local req = { AreaId = areaId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimUnlockAreaRequest, req, function(res)
        -- 更新区域为已解锁
        self._Model.ActivityData:SetAreaIsUnlock(areaId)
        self._Model.ActivityData:SetAreaIsObtain(areaId)
        self._Model:GetStageData():AddExploredGridIds(res.ExploredGridIds)
        -- res.ExploreRewards 在通用的奖励下发协议中处理
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_EXPLORE_GRID, res.ExploredGridIds)
        if cb then cb() end
    end)
end

--endregion

--region 生产记录和销售记录

-- 获取所有生产记录
function XRogueSimControl:GetProduceResults()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetProduceResults()
end

-- 获取单个生产记录通过回合数
function XRogueSimControl:GetProduceResultByTurnNumber(turnNumber)
    local stageData = self._Model:GetStageData()
    if not stageData then
        -- 最后一回合使用结算时缓存的数据
        return self:GetStageSettleProduceResultByTurnNumber(turnNumber)
    end
    return stageData:GetProduceResultByTurnNumber(turnNumber)
end

-- 获取生产记录通过固定回合数
---@param roundCount number 固定回合数
---@return XRogueSimCommodityProduceResult[] 生产记录列表
function XRogueSimControl:GetProduceRecordsByRoundCount(roundCount)
    local produceResults = self:GetProduceResults()
    if not produceResults then
        return nil
    end
    local curTurnNumber = self:GetCurTurnNumber()
    local record = {}
    for _, result in pairs(produceResults) do
        local turnNumber = result:GetTurnNumber()
        if turnNumber < curTurnNumber and turnNumber >= curTurnNumber - roundCount then
            table.insert(record, result)
        end
    end
    return record
end

-- 获取货物生产百分比
---@param roundCount number 固定回合数
function XRogueSimControl:GetCommodityProducePercent(roundCount)
    local produceRecords = self:GetProduceRecordsByRoundCount(roundCount)
    if not produceRecords then
        return {}
    end
    local commodityProduceCount = {}
    local totalProduceCount = 0
    for _, result in pairs(produceRecords) do
        totalProduceCount = totalProduceCount + result:GetTotalProduceCount()
        for commodityId, count in pairs(result:GetProduceCountDic()) do
            commodityProduceCount[commodityId] = (commodityProduceCount[commodityId] or 0) + count
        end
    end
    local commodityProducePercent = {}
    for commodityId, produceCount in pairs(commodityProduceCount) do
        commodityProducePercent[commodityId] = produceCount / totalProduceCount
    end
    return commodityProducePercent
end

-- 获取货物生产数量
---@param commodityId number 货物Id 0表示计算所有货物
---@param roundCount number 任意回合数
function XRogueSimControl:GetCommodityProduceCount(commodityId, roundCount)
    local produceResults = self:GetProduceResults()
    if not produceResults then
        return 0
    end
    local list = {}
    for _, result in pairs(produceResults) do
        local count = (commodityId == 0) and result:GetTotalProduceCount() or result:GetProduceCountById(commodityId)
        table.insert(list, count)
    end
    table.sort(list, function(a, b) return a > b end)
    local total = 0
    for i = 1, math.min(roundCount, #list) do
        total = total + list[i]
    end
    return total
end

-- 获取所有销售记录
function XRogueSimControl:GetSellResults()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return nil
    end
    return stageData:GetSellResults()
end

-- 获取单个销售记录通过回合数
function XRogueSimControl:GetSellResultByTurnNumber(turnNumber)
    local stageData = self._Model:GetStageData()
    if not stageData then
        -- 最后一回合使用结算时缓存的数据
        return self:GetStageSettleSellResultByTurnNumber(turnNumber)
    end
    return stageData:GetSellResultByTurnNumber(turnNumber)
end

-- 获取货物出售暴击次数
---@param commodityId number 货物Id 0表示计算所有货物
function XRogueSimControl:GetCommoditySellCriticalTimes(commodityId)
    local sellResults = self:GetSellResults()
    if not sellResults then
        return 0
    end
    local count = 0
    for _, sellResult in pairs(sellResults) do
        count = count + sellResult:GetSellCriticalCount(commodityId)
    end
    return count
end

-- 获取出售记录通过固定回合数
---@param roundCount number 固定回合数
---@return XRogueSimCommoditySellResult[] 出售记录列表
function XRogueSimControl:GetSellRecordsByRoundCount(roundCount)
    local sellResults = self:GetSellResults()
    if not sellResults then
        return nil
    end
    local curTurnNumber = self:GetCurTurnNumber()
    local record = {}
    for _, result in pairs(sellResults) do
        local turnNumber = result:GetTurnNumber()
        if turnNumber < curTurnNumber and turnNumber >= curTurnNumber - roundCount then
            table.insert(record, result)
        end
    end
    return record
end

-- 获取货物出售百分比
---@param roundCount number 固定回合数
function XRogueSimControl:GetCommoditySellPercent(roundCount)
    local sellResults = self:GetSellRecordsByRoundCount(roundCount)
    if not sellResults then
        return {}
    end
    local commoditySellCount = {}
    local totalSellCount = 0
    for _, result in pairs(sellResults) do
        totalSellCount = totalSellCount + result:GetTotalSellAwardCount()
        for commodityId, count in pairs(result:GetSellAwardCountDic()) do
            commoditySellCount[commodityId] = (commoditySellCount[commodityId] or 0) + count
        end
    end
    local commoditySellPercent = {}
    for commodityId, sellCount in pairs(commoditySellCount) do
        commoditySellPercent[commodityId] = sellCount / totalSellCount
    end
    return commoditySellPercent
end

-- 获取货物出售价格
---@param commodityId number 货物Id 0表示计算所有货物
---@param roundCount number 任意回合数
function XRogueSimControl:GetCommoditySellAmount(commodityId, roundCount)
    local sellResults = self:GetSellResults()
    if not sellResults then
        return 0
    end
    local list = {}
    for _, result in pairs(sellResults) do
        local count = (commodityId == 0) and result:GetTotalSellAwardCount() or result:GetSellAwardCountById(commodityId)
        table.insert(list, count)
    end
    table.sort(list, function(a, b) return a > b end)
    local total = 0
    for i = 1, math.min(roundCount, #list) do
        total = total + list[i]
    end
    return total
end

-- 固定回合内的指定商品的累计贸易金额是否为最高
---@param commodityId number 货物Id
---@param roundCount number 固定回合数
function XRogueSimControl:CheckCommodityIdSellPercentIsMaxLastRound(commodityId, roundCount)
    local commoditySellPercent = self:GetCommoditySellPercent(roundCount)
    local curSellPercent = commoditySellPercent[commodityId] or 0
    if curSellPercent == 0 then
        return false
    end
    for id, percent in pairs(commoditySellPercent) do
        if id ~= commodityId and percent > curSellPercent then
            return false
        end
    end
    return true
end

--endregion

--region 结算信息处理

-- 获取最近几次的销售价格和货物最大总价格
---@param turnNumber number 回合数
---@param count number 记录数
---@return { TurnNum:number, TotalPrice:number }[], number 销售价格列表, 货物最大总价格
function XRogueSimControl:GetRecentSellResults(turnNumber, count)
    local recentSellResults = {}
    local num = 0
    local maxTotalPrice = 0
    for i = turnNumber, 1, -1 do
        local sellResult = self:GetSellResultByTurnNumber(i)
        if sellResult then
            local turnNum = sellResult:GetTurnNumber()
            local totalPrice = sellResult:GetTotalSellAwardCount()
            maxTotalPrice = math.max(maxTotalPrice, totalPrice)
            table.insert(recentSellResults, { TurnNum = turnNum, TotalPrice = totalPrice })
            num = num + 1
            if num >= count then
                break
            end
        end
    end
    table.reverse(recentSellResults)
    return recentSellResults, maxTotalPrice
end

-- 获取回合结算数据
function XRogueSimControl:GetTurnSettleData()
    return self._Model.TurnSettleData
end

-- 记录当前回合结算前数据
function XRogueSimControl:RecordTurnSettleBeforeData()
    if not self._Model.TurnSettleData then
        self._Model.TurnSettleData = require("XModule/XRogueSim/XEntity/Settle/XRogueSimTurnSettleData").New()
    end
    -- 记录当前回合数
    self._Model.TurnSettleData:SetTurnNumber(self:GetCurTurnNumber())
end

-- 检查回合结束数据是否为空
function XRogueSimControl:CheckTurnSettleDataIsEmpty()
    return XTool.IsTableEmpty(self._Model.TurnSettleData)
end

-- 清空回合结算数据
function XRogueSimControl:ClearTurnSettleData()
    self._Model.TurnSettleData = nil
end

-- 缓存部分关卡数据结算使用
function XRogueSimControl:CacheStageSettleData()
    if not self._Model.StageSettleData then
        self._Model.StageSettleData = require("XModule/XRogueSim/XEntity/Settle/XRogueSimStageSettleData").New()
    end
    -- 关卡Id
    self._Model.StageSettleData:SetStageId(self:GetCurStageId())
    -- 回合数
    self._Model.StageSettleData:SetTurnNumber(self:GetCurTurnNumber())
    -- 销售记录
    self._Model.StageSettleData:UpdateSellResults(self:GetSellResults())
    -- 生产记录
    self._Model.StageSettleData:UpdateProduceResults(self:GetProduceResults())
    -- 记录当前关卡三星完成状态
    local starConditions = self:GetRogueSimStageStarConditions(self:GetStageSettleStageId())
    local starFinish = {}
    for _, conditionId in ipairs(starConditions) do
        starFinish[conditionId] = self.ConditionSubControl:CheckCondition(conditionId)
    end
    self._Model.StageSettleData:UpdateStarConditionFinished(starFinish)
end

-- 获取关卡结算数据
function XRogueSimControl:GetStageSettleData()
    return self._Model.StageSettleData
end

-- 检测是否是关卡完成结算
function XRogueSimControl:CheckIsStageFinishedSettle()
    if not self._Model.StageSettleData then
        return false
    end
    return self._Model.StageSettleData:GetIsStageFinished()
end

-- 获取结算关卡Id
function XRogueSimControl:GetStageSettleStageId()
    if not self._Model.StageSettleData then
        return 0
    end
    return self._Model.StageSettleData:GetStageId() or 0
end

-- 获取结算回合数
function XRogueSimControl:GetStageSettleTurnNumber()
    if not self._Model.StageSettleData then
        return 0
    end
    return self._Model.StageSettleData:GetTurnNumber() or 0
end

-- 获取结算单个销售记录通过回合数
function XRogueSimControl:GetStageSettleSellResultByTurnNumber(turnNumber)
    if not self._Model.StageSettleData then
        return nil
    end
    return self._Model.StageSettleData:GetSellResultByTurnNumber(turnNumber)
end

-- 获取结算单个生产记录通过回合数
function XRogueSimControl:GetStageSettleProduceResultByTurnNumber(turnNumber)
    if not self._Model.StageSettleData then
        return nil
    end
    return self._Model.StageSettleData:GetProduceResultByTurnNumber(turnNumber)
end

-- 获取记录的三星完成状态
function XRogueSimControl:GetStageSettleStarConditionFinished(conditionId)
    if not self._Model.StageSettleData then
        return false
    end
    return self._Model.StageSettleData:GetStarConditionFinished(conditionId)
end

-- 更新关卡结算数据
function XRogueSimControl:UpdateStageSettleData(stageSettleData, commoditySellResult, commodityProduceResult)
    if not stageSettleData then
        return
    end
    if not self._Model.StageSettleData then
        self._Model.StageSettleData = require("XModule/XRogueSim/XEntity/Settle/XRogueSimStageSettleData").New()
    end
    -- 关卡结算数据, 为空表示未触发结算
    self._Model.StageSettleData:UpdateStageSettleData(stageSettleData)
    -- 单独处理最后一回合的销售记录
    self._Model.StageSettleData:AddSellResult(commoditySellResult)
    -- 单独处理最后一回合的生产记录
    self._Model.StageSettleData:AddProduceResult(commodityProduceResult)
end

-- 检查关卡数据是否为空（不包含缓存信息）
function XRogueSimControl:CheckStageSettleDataIsEmpty()
    if not self._Model.StageSettleData then
        return true
    end
    return not self._Model.StageSettleData:GetIsStageSettle()
end

-- 清空关卡结算数据
function XRogueSimControl:ClearStageSettleData()
    self._Model.StageSettleData = nil
end

-- 获取分数称号配置通过当前分数
---@param score number 当前分数
function XRogueSimControl:GetScoreTitleConfigByScore(score)
    local configs = self._Model:GetRogueSimScoreTitleConfigs()
    if not configs then
        return nil
    end
    -- 上限配置-1表示无上限 大于等于LowerLimit 小于UpperLimit
    for _, config in pairs(configs) do
        if score >= config.LowerLimit and (config.UpperLimit == -1 or score < config.UpperLimit) then
            return config
        end
    end
    return nil
end

--endregion

--region 统计数据相关

-- 获取统计数据
function XRogueSimControl:GetStatisticsValue(type, key)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    if type == self._Model.StatisticsType.CommoditySale then
        return stageData:GetSellStatisticsCountById(key)
    elseif type == self._Model.StatisticsType.CommodityProduce then
        return stageData:GetProductionStatisticsCountById(key)
    elseif type == self._Model.StatisticsType.EventTrigger then
        return stageData:GetEventStatisticsCountById(key)
    elseif type == self._Model.StatisticsType.GoldAdd then
        return stageData:GetGoldStatisticsCount()
    end
    return 0
end

--endregion

--region 手动触发引导

-- 手动触发引导
function XRogueSimControl:TriggerGuide()
    -- 教学关才会触发引导
    if self:CheckCurStageIsTeach() then
        XDataCenter.GuideManager.CheckGuideOpen()
    end
end

--endregion

--region 本地信息相关

-- 获取科技解锁蓝点key
function XRogueSimControl:GetTechUnlockRedPointKey()
    local activityId = self._Model.ActivityData:GetActivityId()
    local stageId = self:GetCurStageId()
    return string.format("XRogueSimControl_GetTechUnlockRedPointKey_%s_%s_%s", XPlayer.Id, activityId, stageId)
end

-- 获取保存的科技等级
function XRogueSimControl:GetSaveTechUnlockLevel()
    local key = self:GetTechUnlockRedPointKey()
    return XSaveTool.GetData(key) or 0
end

-- 保存科技等级
function XRogueSimControl:SaveTechUnlockLevel(techLv)
    local key = self:GetTechUnlockRedPointKey()
    XSaveTool.SaveData(key, techLv)
end

-- 保存引导已触发通过引导Id
function XRogueSimControl:SaveGuideIsTriggerById(guideId)
    local key = self._Model:GetGuideRecordKey()
    local guideRecord = XSaveTool.GetData(key) or {}
    guideRecord[guideId] = true
    XSaveTool.SaveData(key, guideRecord)
end

-- 清理引导记录
function XRogueSimControl:ClearGuideRecord()
    local key = self._Model:GetGuideRecordKey()
    XSaveTool.SaveData(key, {})
end

-- 获取建筑蓝图数据记录key
function XRogueSimControl:GetBuildingBluePrintRecordKey()
    local activityId = self._Model.ActivityData:GetActivityId()
    return string.format("XRogueSimControl_GetBuildingBluePrintRecordKey_%s_%s", XPlayer.Id, activityId)
end

-- 获取建筑蓝图数据记录
function XRogueSimControl:GetBuildingBluePrintRecord()
    local key = self:GetBuildingBluePrintRecordKey()
    return XSaveTool.GetData(key) or {}
end

-- 保存建筑蓝图数据记录
function XRogueSimControl:SaveBuildingBluePrintRecord()
    local key = self:GetBuildingBluePrintRecordKey()
    local record = {}
    local buildingBluePrintData = self.MapSubControl:GetBuildingBluePrintData()
    for _, data in pairs(buildingBluePrintData) do
        record[data:GetId()] = data:GetCount()
    end
    XSaveTool.SaveData(key, record)
end

-- 清理建筑蓝图数据记录
function XRogueSimControl:ClearBuildingBluePrintRecord()
    local key = self:GetBuildingBluePrintRecordKey()
    XSaveTool.SaveData(key, {})
end

-- 设置跳过货物已满确认提示
function XRogueSimControl:SetSkipCommodityFullTips(isSkip)
    self._Model.IsSkipCommodityFullConfirmTips = isSkip
end

-- 是否跳过货物已满确认提示
function XRogueSimControl:IsSkipCommodityFullTips()
    return self._Model.IsSkipCommodityFullConfirmTips
end

-- 设置跳过有可购买区域确认提示
function XRogueSimControl:SetSkipBuyAreaTips(isSkip)
    self._Model.IsSkipBuyAreaConfirmTips = isSkip
end

-- 是否跳过有可购买区域确认提示
function XRogueSimControl:IsSkipBuyAreaTips()
    return self._Model.IsSkipBuyAreaConfirmTips
end

-- 设置跳过有可探索格子确认提示
function XRogueSimControl:SetSkipExploreGridTips(isSkip)
    self._Model.IsSkipExploreGridConfirmTips = isSkip
end

-- 是否跳过有可探索格子确认提示
function XRogueSimControl:IsSkipExploreGridTips()
    return self._Model.IsSkipExploreGridConfirmTips
end

--endregion

--region 临时生产和出售计划

-- 初始化临时生产和出售计划
function XRogueSimControl:InitTempProduceAndSellPlan()
    self._Model.TempProduceAndSellData = require("XModule/XRogueSim/XEntity/Temp/XRogueSimTempProduceAndSellData").New()
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        local produceCount = self.ResourceSubControl:GetProducePlanCount(id)
        local sellCount = self.ResourceSubControl:GetSellPlanCount(id)
        local sellPresetCount = self.ResourceSubControl:GetSellPlanPresetCount(id)
        local ownCount = self.ResourceSubControl:GetCommodityOwnCount(id)
        if sellPresetCount > 0 then
            -- 向上取整
            sellCount = math.ceil(ownCount * sellPresetCount / XEnumConst.RogueSim.Denominator)
        end
        sellCount = math.min(sellCount, ownCount)
        self._Model.TempProduceAndSellData:UpdateTempProducePlanById(id, produceCount)
        self._Model.TempProduceAndSellData:UpdateTempSellPlanById(id, sellCount)
        self._Model.TempProduceAndSellData:UpdateTempSellPlanPresetById(id, sellPresetCount)
    end
end

-- 获取临时生产和出售计划
---@return XRogueSimTempProduceAndSellData
function XRogueSimControl:GetTempProduceAndSellPlan()
    if not self._Model.TempProduceAndSellData then
        self:InitTempProduceAndSellPlan()
    end
    return self._Model.TempProduceAndSellData
end

-- 清理临时生产和出售计划
function XRogueSimControl:ClearTempProduceAndSellPlan()
    self._Model.TempProduceAndSellData = nil
end

-- 更新临时生产计划
function XRogueSimControl:UpdateTempProducePlan(id, count)
    self:GetTempProduceAndSellPlan():UpdateTempProducePlanById(id, count)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_PRODUCE)
end

-- 更新临时出售计划
function XRogueSimControl:UpdateTempSellPlan(id, count)
    self:GetTempProduceAndSellPlan():UpdateTempSellPlanById(id, count)
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_SELL)
end

-- 更新临时出售预设计划
function XRogueSimControl:UpdateTempSellPresetPlan(id, count)
    self:GetTempProduceAndSellPlan():UpdateTempSellPlanPresetById(id, count)
end

-- 获取实际货物分配的生产力
---@param id number 货物Id
function XRogueSimControl:GetActualCommodityPopulationCount(id)
    return self:GetTempProduceAndSellPlan():GetTempProducePlanCountById(id)
end

-- 获取实际货物生产力计划
function XRogueSimControl:GetActualCommodityPopulationPlan()
    local populationPlan = {}
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        local count = self:GetActualCommodityPopulationCount(id)
        if count > 0 then
            populationPlan[id] = count
        end
    end
    return populationPlan
end

-- 获取实际剩余生产力(容许为负数)
function XRogueSimControl:GetActualRemainingPopulation()
    -- 总的生产力
    local totalPopulation = self.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Population)
    -- 剩余生产力
    local remainingPopulation = totalPopulation
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        remainingPopulation = remainingPopulation - self:GetActualCommodityPopulationCount(id)
    end
    return remainingPopulation
end

-- 获取货物分配了生产力的数量
function XRogueSimControl:GetCommodityPopulationCount()
    local count = 0
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        if self:GetActualCommodityPopulationCount(id) > 0 then
            count = count + 1
        end
    end
    return count
end

-- 获取实际货物出售数量
---@param id number 货物Id
function XRogueSimControl:GetActualCommoditySellCount(id)
    return self:GetTempProduceAndSellPlan():GetTempSellPlanCountById(id)
end

-- 获取实际货物出售计划
function XRogueSimControl:GetActualCommoditySellPlan()
    local sellPlan = {}
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        local ownCount = self.ResourceSubControl:GetCommodityOwnCount(id)
        local sellCount = self:GetActualCommoditySellCount(id)
        sellCount = math.min(sellCount, ownCount)
        if sellCount > 0 then
            sellPlan[id] = sellCount
        end
    end
    return sellPlan
end

-- 获取实际货物出售预设比例
---@param id number 货物Id
function XRogueSimControl:GetActualCommoditySellPresetCount(id)
    return self:GetTempProduceAndSellPlan():GetTempSellPlanPresetCountById(id)
end

-- 获取实际货物出售计划预设
function XRogueSimControl:GetActualCommoditySellPlanPreset()
    local sellPresetPlan = {}
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        local count = self:GetActualCommoditySellPresetCount(id)
        if count > 0 then
            sellPresetPlan[id] = count
        end
    end
    return sellPresetPlan
end

-- 重置临时生产计划数量
function XRogueSimControl:ResetTempProducePlanCount()
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        self:UpdateTempProducePlan(id, 0)
    end
end

-- 检测货物是否自动出售
function XRogueSimControl:CheckCommodityIsAutoSell()
    for _, id in pairs(XEnumConst.RogueSim.CommodityIds) do
        local sellPlanPreset = self:GetActualCommoditySellPresetCount(id)
        if sellPlanPreset > 0 then
            return true
        end
    end
    return false
end

-- 检查上一回合是否生产了某个货物
---@param id number 货物Id
function XRogueSimControl:CheckLastRoundIsProduceCommodity(id)
    local lastTurnNumber = self:GetCurTurnNumber() - 1
    if lastTurnNumber <= 0 then
        return false
    end
    local produceResult = self:GetProduceResultByTurnNumber(lastTurnNumber)
    if not produceResult then
        return false
    end
    local produceDic = produceResult:GetProduceCountDic()
    return produceDic[id] and produceDic[id] > 0
end

-- 检查是否触发循环生产/销售效果
---@param id number 货物Id
function XRogueSimControl:CheckIsLoopSellOrProduceEffect(id)
    -- 上一回合没有生产该货物并且当前回合生产了该货物
    if self:CheckLastRoundIsProduceCommodity(id) then
        return false
    end
    local curPopulation = self:GetActualCommodityPopulationCount(id)
    return curPopulation > 0
end

-- 检查并更新临时出售计划
function XRogueSimControl:CheckAndUpdateTempSellPlan()
    if not self._Model.TempProduceAndSellData then
        return
    end
    for _, id in ipairs(XEnumConst.RogueSim.CommodityIds) do
        local sellCount = self:GetActualCommoditySellCount(id)
        local sellPlanPreset = self:GetActualCommoditySellPresetCount(id)
        local ownCount = self.ResourceSubControl:GetCommodityOwnCount(id)
        if sellPlanPreset > 0 then
            local count = math.ceil(ownCount * sellPlanPreset / XEnumConst.RogueSim.Denominator)
            if count ~= sellCount then
                self:UpdateTempSellPlan(id, math.min(count, ownCount))
            end
        elseif sellCount > ownCount then
            self:UpdateTempSellPlan(id, ownCount)
        end
    end
end

-- 货物变更时判断出售数量和货物拥有的数量
function XRogueSimControl:OnCommodityChange()
    -- 回合结算时不处理
    if self._Model.IsRoundEnd then
        return
    end
    self:CheckAndUpdateTempSellPlan()
end

--endregion

return XRogueSimControl
