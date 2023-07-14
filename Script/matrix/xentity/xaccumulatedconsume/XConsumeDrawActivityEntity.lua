---@class ConsumeDrawActivityEntity
local XConsumeDrawActivityEntity = XClass(nil, "XConsumeDrawActivityEntity")

function XConsumeDrawActivityEntity:Ctor(activityId)
    self.Config = XAccumulatedConsumeConfig.GetDrawActivity(activityId)
    self.DetailConfig = XAccumulatedConsumeConfig.GetDrawActivityDetail(activityId)
    self.RewardConfig = XAccumulatedConsumeConfig.GetDrawReward(activityId)
end

---@desc 单次抽消费的代币个数
function XConsumeDrawActivityEntity:GetCoinCost()
    return self.Config.CoinCost
end
---@desc 获取福袋代币Id(抽卡)
function XConsumeDrawActivityEntity:GetDrawCardCoinItemId()
    return self.Config.CoinItemId
end
---@desc 单次最大抽奖次数
function XConsumeDrawActivityEntity:GetSingleMaxDraw()
    return self.Config.SingleMaxDraw
end

function XConsumeDrawActivityEntity:GetDropId()
    return self.Config.DropId
end

function XConsumeDrawActivityEntity:GetAssetItemId()
    return self.Config.AssetItemId
end
-- 福袋抽卡 开始时间
function XConsumeDrawActivityEntity:GetLuckyStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self.Config.TimeId)
end
-- 福袋抽卡 结束时间
function XConsumeDrawActivityEntity:GetLuckyEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self.Config.TimeId)
end
-- 累消活动 开始时间
function XConsumeDrawActivityEntity:GetActivityStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self.DetailConfig.ActivityTimeId)
end
-- 累消活动 结束时间
function XConsumeDrawActivityEntity:GetActivityEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self.DetailConfig.ActivityTimeId)
end
function XConsumeDrawActivityEntity:GetShopId()
    return self.DetailConfig.ShopId
end
---@desc 获取累消代币Id(商城)
function XConsumeDrawActivityEntity:GetShopCoinItemId()
    return self.DetailConfig.ShopCoinId
end
---@desc 活动涂装的TaskId
function XConsumeDrawActivityEntity:GetCoatTaskId()
    return self.DetailConfig.CoatTaskId
end
---@desc 获取任务列表信息
function XConsumeDrawActivityEntity:GetActivityTaskData(index)
    return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(self.DetailConfig.TaskGroupId[index])
end

function XConsumeDrawActivityEntity:GetTaskGroupId()
    return self.DetailConfig.TaskGroupId
end

function XConsumeDrawActivityEntity:GetTaskGroupName()
    return self.DetailConfig.TaskGroupName
end
function XConsumeDrawActivityEntity:GetDrawId()
    return self.DetailConfig.DrawId
end
---@desc 获取3D模型ModelId
function XConsumeDrawActivityEntity:GetModelId()
    return self.DetailConfig.ModelId
end
---@desc 获取涂装背景
function XConsumeDrawActivityEntity:GetCoatBg()
    return self.DetailConfig.CoatBg
end
---@desc 获取涂装名字
function XConsumeDrawActivityEntity:GetCoatName()
    return self.DetailConfig.CoatName
end
---@desc 获取奖励描述
function XConsumeDrawActivityEntity:GetRewardDescription()
    return self.DetailConfig.RewardDescription
end
---@desc “MM-dd HH:mm ~ MM-dd HH:mm” 
function XConsumeDrawActivityEntity:GetActivityTime()
    local startTime = self:GetLuckyStartTime()
    local endTime = self:GetLuckyEndTime()
    local startTimeStr = XTime.TimestampToGameDateTimeString(startTime, "MM-dd HH:mm")
    local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, "MM-dd HH:mm")
    return CSXTextManagerGetText("ConsumeActivityLuckyTime", startTimeStr, endTimeStr)
end
---@return 最大抽取的次数
function XConsumeDrawActivityEntity:GetMaxDrawCount()
    -- 当前玩家拥有代币数量
    local itemId = self:GetDrawCardCoinItemId()
    local coinCost = XDataCenter.ItemManager.GetCount(itemId)
    if not XTool.IsNumberValid(coinCost) then
        return 1  -- 默认为一次
    end
    -- 单次开启需要消耗代币的个数
    local singleCost = self:GetCoinCost()
    local drawCount = math.floor(coinCost / singleCost)
    if drawCount <= 1 then
        return 1
    end
    local singleMaxDrawCount = self:GetSingleMaxDraw()
    return math.min(drawCount, singleMaxDrawCount)
end
--region 进度相关
function XConsumeDrawActivityEntity:GetRewardProgressId()
    return self.RewardConfig.ProgressId
end

function XConsumeDrawActivityEntity:GetRewardProgressRequired()
    return self.RewardConfig.ProgressRequired
end

function XConsumeDrawActivityEntity:GetRewardRewardId()
    return self.RewardConfig.RewardId
end

function XConsumeDrawActivityEntity:GetProgressRequiredByProgressId(progressId)
    local progressIds = self:GetRewardProgressId()
    local progressRequired = self:GetRewardProgressRequired()
    for key, value in pairs(progressIds) do
        if progressId == value then
            return progressRequired[key]
        end
    end
    return progressRequired[1]
end

function XConsumeDrawActivityEntity:GetProgressRewardIdByProgressId(progressId)
    local progressIds = self:GetRewardProgressId()
    local progressRewardId = self:GetRewardRewardId()
    for key, value in pairs(progressIds) do
        if progressId == value then
            return progressRewardId[key]
        end
    end
    return progressRewardId[1]
end

--endregion

---@desc 检查福袋抽卡过期
function XConsumeDrawActivityEntity:CheckLuckyTimeout(isShowTip)
    local timeId = self.Config.TimeId
    return self:CheckTimeout(timeId, isShowTip)
end
---@desc 检查累消活动过期
function XConsumeDrawActivityEntity:CheckActivityTimeout(isShowTip)
    local timeId = self.DetailConfig.ActivityTimeId
    return self:CheckTimeout(timeId, isShowTip)
end
---@desc 检查过期
function XConsumeDrawActivityEntity:CheckTimeout(timeId, isShowTip)
    local curTime = XTime.GetServerNowTimestamp()

    local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
    if curTime < startTime then
        if isShowTip then
            XUiManager.TipMsg(CS.XTextManager.GetText("ConsumeActivityNotOpen"))
        end
        return true
    end

    if curTime > endTime then
        if isShowTip then
            XUiManager.TipMsg(CS.XTextManager.GetText("ConsumeActivityOver"))
        end
        return true
    end

    return false
end

return XConsumeDrawActivityEntity