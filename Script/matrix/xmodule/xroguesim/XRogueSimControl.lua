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
        RogueSimCommoditySetupProduceRequest = "RogueSimCommoditySetupProduceRequest", -- 请求设置货物生产
        RogueSimCommoditySetupSellRequest = "RogueSimCommoditySetupSellRequest",       -- 请求设置货物出售
        RogueSimTurnSettleRequest = "RogueSimTurnSettleRequest",                       -- 请求回合结算
        RogueSimPickRewardRequest = "RogueSimPickRewardRequest",                       -- 领取奖励请求
        RogueSimMainLevelUpRequest = "RogueSimMainLevelUpRequest",                     -- 请求主城升级
        RogueSimUnlockTechRequest = "RogueSimUnlockTechRequest",                       -- 解锁科技请求
        RogueSimUnlockKeyTechRequest = "RogueSimUnlockKeyTechRequest",                 -- 解锁关键科技请求
        RogueSimStageSettleRequest = "RogueSimStageSettleRequest",                     -- 放弃游戏关卡结算请求
        RogueSimEventSelectOptionRequest = "RogueSimEventSelectOptionRequest",         -- 请求事件选择选项
        RogueSimBuildingBuyRequest = "RogueSimBuildingBuyRequest",                     -- 请求购买建筑
    }
end

function XRogueSimControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    XMVCA.XRogueSim:AddEventListener(XAgencyEventId.EVENT_ROGUE_SIM_CACHE_STAGE_SETTLE_DATA, self.CacheStageSettleData, self)
end

function XRogueSimControl:RemoveAgencyEvent()
    XMVCA.XRogueSim:RemoveEventListener(XAgencyEventId.EVENT_ROGUE_SIM_CACHE_STAGE_SETTLE_DATA, self.CacheStageSettleData, self)
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

function XRogueSimControl:GetActivitySettlePointPerProp()
    local config = self._Model:GetActivityConfig()
    return config and config.SettlePointPerProp or 0
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

function XRogueSimControl:HandleActivityEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipText("ActivityAlreadyOver")
end

--endregion

--region 关卡相关

function XRogueSimControl:GetRogueSimStageType(stageId)
    local config = self._Model:GetRogueSimStageConfig(stageId)
    return config and config.Type or 0
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

function XRogueSimControl:GetRogueSimStageDesc(stageId)
    local config = self._Model:GetRogueSimStageConfig(stageId)
    return config and config.Desc or ""
end

function XRogueSimControl:GetRogueSimStagePreStageId(stageId)
    local config = self._Model:GetRogueSimStageConfig(stageId)
    return config and config.PreStageId or 0
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
    local preStageId = self:GetRogueSimStagePreStageId(stageId)
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
    local preStageId = self:GetRogueSimStagePreStageId(stageId)
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

-- 获取当前行动点数
function XRogueSimControl:GetCurActionPoint()
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    return stageData:GetActionPoint()
end

-- 获取行动点上限
function XRogueSimControl:GetActionPointLimit()
    local actionPointId = XEnumConst.RogueSim.ResourceId.ActionPoint
    local limitPoint = self.ResourceSubControl:GetResourceOwnCount(actionPointId)
    return self.BuffSubControl:GetActionPointMiscAddLimit(limitPoint)
end

-- 获取当前关卡的等级组
function XRogueSimControl:GetCurStageLevelGroup()
    local stageId = self:GetCurStageId()
    return self:GetRogueSimStageLevelGroup(stageId)
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
function XRogueSimControl:GetMainLevelUnlockAreaIdx(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.UnlockAreaIdx or 0
end

function XRogueSimControl:GetMainLevelRewardResourceIds(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.RewardResourceIds or {}
end

function XRogueSimControl:GetMainLevelRewardResourceCounts(id)
    local config = self._Model:GetRogueSimMainLevelConfig(id)
    return config and config.RewardResourceCounts or {}
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
    return config and config.Desc or ""
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

-- 检查主城升级红点（未满级、金币和繁荣度已满足）
function XRogueSimControl:CheckMainLevelRedPoint()
    local curLevel = self:GetCurMainLevel()
    -- 已满级
    if self:CheckIsMaxLevel(curLevel) then
        return false
    end
    -- 经验不足
    local curExp, upExp = self:GetCurExpAndLevelUpExp(curLevel)
    if curExp < upExp then
        return false
    end
    -- 金币不足
    if not self:CheckLevelUpGoldIsEnough(curLevel) then
        return false
    end
    return true
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
    -- 关闭当前界面后再打开弹框
    XLuaUiManager.CloseWithCallback(uiName, callback)
end

-- 获取有弹框信息的类型
---@return number 弹框类型
function XRogueSimControl:GetHasPopupDataType()
    -- 弹框数据
    local types = {}
    for _, type in pairs(XEnumConst.RogueSim.PopupType) do
        if not self:CheckPopupDataIsEmptyByType(type) then
            table.insert(types, type)
        end
    end
    if not XTool.IsTableEmpty(types) then
        -- 排序
        table.sort(types, function(a, b)
            return a < b
        end)
        return types[1]
    end
    -- 已探索表现
    if self:CheckHasExploreCache() then
        return XEnumConst.RogueSim.PopupType.ExploreGrid
    end
    -- 可见格子
    if self:CheckHasVisibleCache() then
        return XEnumConst.RogueSim.PopupType.VisibleGrid
    end
    return XEnumConst.RogueSim.PopupType.None
end

-- 打开下一个弹框
function XRogueSimControl:ShowNextPopup(uiName, type, ...)
    local arg = { ... }
    self:StartNextStepBefore(uiName, function()
        self:ShowPopup(type, table.unpack(arg))
    end)
end

-- 显示弹框 显示优先级 buff > 道具选择 > 奖励
function XRogueSimControl:ShowPopup(type, ...)
    if type == XEnumConst.RogueSim.PopupType.Buff then
        self:ShowBuffPopup()
    elseif type == XEnumConst.RogueSim.PopupType.PropSelect then
        self:ShowPropSelectPopup(...)
    elseif type == XEnumConst.RogueSim.PopupType.Reward then
        self:ShowRewardPopup(...)
    elseif type == XEnumConst.RogueSim.PopupType.Task then
        self:ShowTaskPopup()
    elseif type == XEnumConst.RogueSim.PopupType.TurnReward then
        self:ShowTurnRewardPopup()
    elseif type == XEnumConst.RogueSim.PopupType.MainLevelUp then
        self:ShowMainLevelUpPopup()
    elseif type == XEnumConst.RogueSim.PopupType.ExploreGrid then
        self:PlayCacheExploreGrids()
    elseif type == XEnumConst.RogueSim.PopupType.VisibleGrid then
        self:PlayCacheVisibleGrids()
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
            or type == XEnumConst.RogueSim.RewardType.Prop then
        XLuaUiManager.Open("UiRogueSimRewardPopup", data.RewardItems)
    elseif type == XEnumConst.RogueSim.RewardType.Building then
        self.MapSubControl:ExploreBuildingGrid(data.RewardItems[1].ObjectId)
    elseif type == XEnumConst.RogueSim.RewardType.Event then
        self.MapSubControl:ExploreEventGrid(data.RewardItems[1].ObjectId)
    else
        XLog.Error("ShowRewardPopup error type" .. type)
    end
    XLog.Warning("ShowRewardPopup Data:", data)
end

-- 显示道具选择弹框
function XRogueSimControl:ShowPropSelectPopup(gridId, source)
    local data = self._Model:DequeuePopupData(XEnumConst.RogueSim.PopupType.PropSelect, gridId, source)
    if not data or not data.Reward then
        return
    end
    self.MapSubControl:ExplorePropGrid(data.Reward.Id)
    XLog.Warning("ShowPropSelectPopup Data:", data)
end

-- 显示Buff弹框
function XRogueSimControl:ShowBuffPopup()
    local data = self._Model:DequeuePopupData(XEnumConst.RogueSim.PopupType.Buff)
    if XTool.IsTableEmpty(data) then
        return
    end
    XLuaUiManager.Open("UiRogueSimRewardPopup", data)
    XLog.Warning("ShowBuffPopup Data:", data)
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
    XLog.Warning("ShowTaskPopup Data:", data)
end

-- 显示回合奖励弹框
function XRogueSimControl:ShowTurnRewardPopup()
    local data = self._Model:DequeuePopupData(XEnumConst.RogueSim.PopupType.TurnReward)
    if XTool.IsTableEmpty(data) then
        return
    end
    XLuaUiManager.Open("UiRogueSimRewardPopup", data)
    XLog.Warning("ShowTurnRewardPopup Data:", data)
end

-- 显示主城等级提升弹框
function XRogueSimControl:ShowMainLevelUpPopup()
    local data = self._Model:DequeuePopupData(XEnumConst.RogueSim.PopupType.MainLevelUp)
    if XTool.IsTableEmpty(data) then
        return
    end
    ---@type XUiRogueSimBattle
    local luaUi = XLuaUiManager.GetTopLuaUi("UiRogueSimBattle")
    if luaUi then
        luaUi:OpenMainLevelUp(data)
    end
    XLog.Warning("ShowMainLevelUpPopup Data:", data)
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

-- 购买建筑之后弹框
function XRogueSimControl:BuyBuildingAfter(buildId)
    -- 购买成功弹框
    local desc = self:GetClientConfig("BuyBuildingSuccess")
    local buildName = self.MapSubControl:GetBuildingName(buildId)
    local content = string.format(desc, buildName)
    XUiManager.TipMsgEnqueue(content)
    -- 发现位置弹框
    if self:CheckHasVisibleCache() then
        local count = self:GetVisibleGridCount()
        local endDesc = self:GetClientConfig("BuildingUnlockShowTips", 2)
        local endContent = string.format(endDesc, count)
        XUiManager.TipMsgEnqueue(self:GetClientConfig("BuildingUnlockShowTips", 1), XUiManager.UiTipType.Tip, function()
            -- 移动镜头
            self:PlayCacheVisibleGrids(function()
                -- 移动结束弹框
                XUiManager.TipMsgEnqueue(endContent)
            end)
        end)
    end
end

-- 去购买建筑
function XRogueSimControl:GoBuyBuilding(name, id)
    self:StartNextStepBefore(name, function()
        self.MapSubControl:ExploreBuildingGrid(id)
    end)
end

-- 通用确认弹框
function XRogueSimControl:ShowCommonTip(title, content, closeCallback, sureCallback, jumpCallBack, data)
    if not title and not content then
        XLog.Error("XRogueSimControl.ShowCommonTip error, title and content is nil")
        return
    end
    CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.Tip_Big)
    XLuaUiManager.Open("UiRogueSimThreeTip", title, content, closeCallback, sureCallback, jumpCallBack, data)
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

-- 是否有已探索的格子
function XRogueSimControl:CheckHasExploreCache(gridId)
    if not self.RogueSimScene then
        return false
    end
    return self.RogueSimScene:CheckHasExploreCache(gridId)
end

-- 播放缓存的已探索格子
function XRogueSimControl:PlayCacheExploreGrids(gridId, cb)
    if not self.RogueSimScene then
        return
    end
    self.RogueSimScene:PlayCacheExploreGrids(gridId, cb)
end

-- 检查是否有可见缓存未处理
function XRogueSimControl:CheckHasVisibleCache()
    if not self.RogueSimScene then
        return false
    end
    return self.RogueSimScene:CheckHasVisibleCache()
end

-- 获取可见格子的数量
function XRogueSimControl:GetVisibleGridCount()
    if not self.RogueSimScene then
        return 0
    end
    return self.RogueSimScene:GetVisibleGridCount()
end

-- 播放缓存的可见格子
function XRogueSimControl:PlayCacheVisibleGrids(cb)
    if not self.RogueSimScene then
        return
    end
    self.RogueSimScene:PlayCacheVisibleGrids(cb)
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
        if data:GetState() == XEnumConst.RogueSim.TaskState.Finished then
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
    return taskData:GetState() == XEnumConst.RogueSim.TaskState.Finished
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
    local totalNum = self:GetTaskNeedCompleteNum(id)
    return XUiHelper.FormatText(desc, totalNum)
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

-- 获取任务需要完成的数量
---@param id number 配置Id
function XRogueSimControl:GetTaskNeedCompleteNum(id)
    local conditionId = self:GetTaskConditionId(id)
    local conditionParams = self:GetTaskConditionParams(id)
    if conditionId > 1 then
        return conditionParams[3] or 0
    else
        return conditionParams[1] or 0
    end
end

-- 获取任务完成值和总值
---@param id number 自增Id
---@param configId number 配置Id
function XRogueSimControl:GetTaskScheduleAndTotalNum(id, configId)
    local schedule = self:GetTaskScheduleById(id)
    local totalNum = self:GetTaskNeedCompleteNum(configId)
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
    return config and config.EffectDesc or ""
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

-- 获取所有的传闻
function XRogueSimControl:GetAllTipList()
    local gridTips = self:GetGridTipList()
    local eventTips = self:GetEventTipList()
    local volatilityTips = self:GetVolatilityTipList()
    return XTool.MergeArray(gridTips, eventTips, volatilityTips)
end

-- 获取格子传闻列表
function XRogueSimControl:GetGridTipList()
    if not self.RogueSimScene then
        return nil
    end
    return self.RogueSimScene:GetGridTipList()
end

-- 获取事件传闻列表
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
        if buildingData and buildingData:CheckIsBuy() then
            local tipId = self.MapSubControl:GetBuildingTipId(buildingData:GetConfigId())
            local msg = self:GetTipContent(tipId)
            table.insert(tips, msg)
        end
    end
    return tips
end

-- 获取波动传闻列表
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
        local XRogueSimScene = require("XModule/XRogueSim/XEntity/Scene/XRogueSimScene")
        self.RogueSimScene = self:AddSubControl(XRogueSimScene)
        self.RogueSimScene:LoadSceneAsync(function()
            -- 加载完毕
            self:AfterEnterScene()
        end)
    end)
end

-- 进入场景后
function XRogueSimControl:AfterEnterScene()
    -- 关闭load界面
    self:CloseLoading()
    -- 打开主界面
    XLuaUiManager.Open("UiRogueSimBattle")
end

-- 退出场景
function XRogueSimControl:OnExitScene()
    self:ClearAllPopupData()
    self:ReleaseScene()
end

-- 释放场景
function XRogueSimControl:ReleaseScene()
    if self.RogueSimScene then
        self.RogueSimScene:SaveLastCameraFollowPointPos()
        self:RemoveSubControl(self.RogueSimScene)
        self.RogueSimScene = nil
    end
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
        self._Model.ActivityData:UpdateActionPoint(res.ActionPoint)
        self.MapSubControl:ExploreGrid(res.Reward, res.CityId)
        if cb then cb() end
    end)
end

-- 请求设置货物生产
---@param commodityId number 货物Id
function XRogueSimControl:RogueSimCommoditySetupProduceRequest(commodityId, cb)
    local req = { CommodityId = commodityId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimCommoditySetupProduceRequest, req, function(res)
        self._Model.ActivityData:UpdateProductCommodityId(commodityId)
        if cb then cb() end
    end)
end

-- 请求设置货物出售
---@param sellPlan table<number,number> key货物Id value出售数量
function XRogueSimControl:RogueSimCommoditySetupSellRequest(sellPlan, cb)
    XMessagePack.MarkAsTable(sellPlan)
    local req = { SellPlan = sellPlan }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimCommoditySetupSellRequest, req, function(res)
        self._Model.ActivityData:UpdateSellPlan(sellPlan)
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
        self._Model.ActivityData:UpdateActionPoint(res.ActionPoint)
        -- 清空货物出售计划
        self._Model.ActivityData:UpdateSellPlan()
        self._Model.ActivityData:UpdateCommodityPriceRates(res.CommodityPriceRates)
        self._Model.ActivityData:AddSellResult(res.CommoditySellResult)
        self:UpdateTurnSettleProduceData(res.CommodityProduceCount, res.CommodityProduceIsCritical,
            res.CommodityProduceIsOverflow)
        self:UpdateStageSettleData(res.StageSettleData, res.CommoditySellResult)
        self._Model:EnqueuePopupData(XEnumConst.RogueSim.PopupType.TurnReward, res.CommodityModifyInfo,
            res.ResourceModifyInfo)
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
        self._Model:EnqueuePopupData(XEnumConst.RogueSim.PopupType.MainLevelUp, res.MainLevel)
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
        self._Model.ActivityData:UpdateGridEventId(id, res.NewEventId)
        if cb then cb(res.NewEventId) end
    end)
end

-- 请求购买建筑
---@param id number 自增Id
function XRogueSimControl:RogueSimBuildingBuyRequest(id, cb)
    local req = { Id = id }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.RogueSimBuildingBuyRequest, req, function(res)
        -- 更新当前格子建筑为已购买
        self._Model.ActivityData:UpdateBuildingIsBuy(id)
        if cb then cb() end
    end)
end

--endregion

--region 结算信息处理

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

-- 获取最近几次的销售记录和货物最大总价格
---@param turnNumber number 回合数
---@param count number 记录数
function XRogueSimControl:GetRecentSellResults(turnNumber, count)
    local recentSellResults = {}
    local num = 0
    local maxTotalPrice = 0
    for i = turnNumber, 1, -1 do
        local sellResult = self:GetSellResultByTurnNumber(i)
        if sellResult then
            local turnNum = sellResult:GetTurnNumber()
            local totalPrice = sellResult:GetTotalPrice()
            if totalPrice > maxTotalPrice then
                maxTotalPrice = totalPrice
            end
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
    -- 清理数据
    self._Model.TurnSettleData = {}
    -- 记录生产的货物Id
    self._Model.TurnSettleData.CommodityProduceId = self.ResourceSubControl:GetProductCommodityId()
end

-- 更新回合结算货物产出数据
function XRogueSimControl:UpdateTurnSettleProduceData(count, isCritical, isOverflow)
    self._Model.TurnSettleData.CommodityProduceCount = count or 0
    self._Model.TurnSettleData.CommodityProduceIsCritical = isCritical or false
    self._Model.TurnSettleData.CommodityProduceIsOverflow = isOverflow or false
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
    self._Model.StageSettleData = {}
    -- 关卡Id
    self._Model.StageSettleData.StageId = self:GetCurStageId()
    -- 回合数
    self._Model.StageSettleData.TurnNumber = self:GetCurTurnNumber()
    -- 销售记录(克隆数据)
    self._Model.StageSettleData.SellResults = XTool.Clone(self:GetSellResults())
    -- 记录当前关卡三星完成状态
    local starConditions = self:GetRogueSimStageStarConditions(self._Model.StageSettleData.StageId)
    local starFinish = {}
    for _, conditionId in ipairs(starConditions) do
        starFinish[conditionId] = self.ConditionSubControl:CheckCondition(conditionId)
    end
    self._Model.StageSettleData.StarConditionFinished = starFinish
end

-- 获取关卡结算数据
function XRogueSimControl:GetStageSettleData()
    if XTool.IsTableEmpty(self._Model.StageSettleData) then
        return nil
    end
    return self._Model.StageSettleData.SettleData or nil
end

-- 检测是否是关卡完成结算
function XRogueSimControl:CheckIsStageFinishedSettle()
    if XTool.IsTableEmpty(self._Model.StageSettleData) then
        return false
    end
    if XTool.IsTableEmpty(self._Model.StageSettleData.SettleData) then
        return false
    end
    return self._Model.StageSettleData.SettleData.IsStageFinished or false
end

-- 获取结算关卡Id
function XRogueSimControl:GetStageSettleStageId()
    if XTool.IsTableEmpty(self._Model.StageSettleData) then
        return 0
    end
    return self._Model.StageSettleData.StageId or 0
end

-- 获取结算回合数
function XRogueSimControl:GetStageSettleTurnNumber()
    if XTool.IsTableEmpty(self._Model.StageSettleData) then
        return 0
    end
    return self._Model.StageSettleData.TurnNumber or 0
end

-- 获取结算单个销售记录通过回合数
function XRogueSimControl:GetStageSettleSellResultByTurnNumber(turnNumber)
    if XTool.IsTableEmpty(self._Model.StageSettleData) then
        return nil
    end
    if not self._Model.StageSettleData.SellResults then
        return nil
    end
    return self._Model.StageSettleData.SellResults[turnNumber] or nil
end

-- 获取记录的三星完成状态
function XRogueSimControl:GetStageSettleStarConditionFinished(conditionId)
    if XTool.IsTableEmpty(self._Model.StageSettleData) then
        return false
    end
    if not self._Model.StageSettleData.StarConditionFinished then
        return false
    end
    return self._Model.StageSettleData.StarConditionFinished[conditionId] or false
end

-- 更新关卡结算数据
function XRogueSimControl:UpdateStageSettleData(stageSettleData, commoditySellResult)
    if not stageSettleData then
        return
    end
    if not self._Model.StageSettleData then
        self._Model.StageSettleData = {}
    end
    -- 关卡结算数据, 为空表示未触发结算
    self._Model.StageSettleData.SettleData = stageSettleData
    -- 结算信息不为空时单独处理最后一回合的销售记录
    if stageSettleData and commoditySellResult then
        if not self._Model.StageSettleData.SellResults then
            self._Model.StageSettleData.SellResults = {}
        end
        local sellResult = self._Model.StageSettleData.SellResults[commoditySellResult.TurnNumber]
        if not sellResult then
            sellResult = require("XModule/XRogueSim/XEntity/XRogueSimCommoditySellResult").New()
            self._Model.StageSettleData.SellResults[commoditySellResult.TurnNumber] = sellResult
        end
        sellResult:UpdateSellResultData(commoditySellResult)
    end
end

-- 检查关卡数据是否为空（不包含缓存信息）
function XRogueSimControl:CheckStageSettleDataIsEmpty()
    if XTool.IsTableEmpty(self._Model.StageSettleData) then
        return true
    end
    return XTool.IsTableEmpty(self._Model.StageSettleData.SettleData)
end

-- 清空关卡结算数据
function XRogueSimControl:ClearStageSettleData()
    self._Model.StageSettleData = nil
end

--endregion

--region 统计数据相关

-- 获取统计数据
function XRogueSimControl:GetStatisticsValue(type, key)
    local stageData = self._Model:GetStageData()
    if not stageData then
        return 0
    end
    if type == XEnumConst.RogueSim.StatisticsType.CommoditySale then
        return stageData:GetSellStatisticsCountById(key)
    elseif type == XEnumConst.RogueSim.StatisticsType.CommodityProduce then
        return stageData:GetProductionStatisticsCountById(key)
    elseif type == XEnumConst.RogueSim.StatisticsType.EventTrigger then
        return stageData:GetEventStatisticsCountById(key)
    elseif type == XEnumConst.RogueSim.StatisticsType.GoldAdd then
        return stageData:GetGoldStatisticsCount()
    end
    return 0
end

--endregion

--region 手动触发引导

-- 手动触发引导
function XRogueSimControl:TriggerGuide()
    -- 教学关才会触发引导
    local stageId = self:GetCurStageId()
    if not XTool.IsNumberValid(stageId) then
        return
    end
    if self:GetRogueSimStageType(stageId) == XEnumConst.RogueSim.StageType.Teach then
        XDataCenter.GuideManager.CheckGuideOpen()
    end
end

--endregion

return XRogueSimControl
