local XINewRegressionChildManager = require("XEntity/XNewRegression/XINewRegressionChildManager")
local XSignInManager = XClass(XINewRegressionChildManager, "XSignInManager")

local DAY_2_SECOND = 24 * 60 * 60

function XSignInManager:Ctor(activityId)
    self.Config = XNewRegressionConfigs.GetSignInConfigByActivityId(activityId)
    -- 当前签到的天数
    self.SigninTimes = nil
    -- 已领奖励
    self.RewardStatusDic = {}
    -- 签到持续时间（天）
    self.ContinueDay = 0
    -- 玩家自身活动开启玩家
    self.BeginTime = 0
end

-- data : XRegression2SignInData
function XSignInManager:InitWithServerData(data)
    self.SigninTimes = data.SigninTimes
    for _, rewardId in ipairs(data.Rewards) do
        self.RewardStatusDic[rewardId] = true
    end
end

-- data : NotifyRegression2SignInData
function XSignInManager:UpdateWithServerData(data)
    self.SigninTimes = data.SigninTimes
    for _, rewardId in ipairs(data.Rewards) do
        self.RewardStatusDic[rewardId] = true
    end
end

function XSignInManager:SetContinueDay(value)
    self.ContinueDay = value or 0
end

function XSignInManager:SetBeginTime(value)
    self.BeginTime = value
end

function XSignInManager:GetBeginTime()
    return self.BeginTime
end

function XSignInManager:GetContinueDay()
    return self.ContinueDay
end

function XSignInManager:GetEndTime(day)
    if day == nil then day = self.ContinueDay end
    return self.BeginTime + day * DAY_2_SECOND
end

function XSignInManager:GetLeaveTimeStr(day, formatType, endTime)
    if endTime == nil then endTime = self:GetEndTime(day) end
    if formatType == nil then formatType = XUiHelper.TimeFormatType.NEW_REGRESSION end
    return XUiHelper.GetTime(endTime - XTime.GetServerNowTimestamp(), formatType)
end

function XSignInManager:GetSignInDatas()
    if self._SignInDatas == nil then
        self._SignInDatas = self.Config
    end
    table.sort(self._SignInDatas, function(dataA, dataB)
        local weightA = self:GetIsFinishReward(dataA.Id) and 100000 or 0
        local weightB = self:GetIsFinishReward(dataB.Id) and 100000 or 0
        weightA = weightA + dataA.Id
        weightB = weightB + dataB.Id
        return weightA < weightB
    end)
    return self._SignInDatas
end

function XSignInManager:CheckCanGetReward(id)
    for _, config in ipairs(self.Config) do
        if id == nil or id == config.Id then
            if self.SigninTimes >= config.Days 
                and not self.RewardStatusDic[config.Id] then
                return true
            end
        end
    end
    return false
end

function XSignInManager:GetIsFinishReward(id)
    return self.RewardStatusDic[id] or false
end

function XSignInManager:RequestGetReward(signInId, callback)
    -- 检查是否已领取
    if self:GetIsFinishReward(signInId) then
        XUiManager.TipErrorWithKey("NewRegressionSignInRewardTip1")
        return
    end
    -- 是否是否满足领取条件
    if not self:CheckCanGetReward(signInId) then
        XUiManager.TipErrorWithKey("NewRegressionSignInRewardTip2")
        return
    end
    XNetwork.CallWithAutoHandleErrorCode("Regression2SignInGetRewardRequest", { SignInId = signInId }, function(res)
        -- 自己更新下数据
        self.RewardStatusDic[signInId] = true
        XUiManager.OpenUiObtain(res.RewardGoods)
        if callback then callback() end
    end)
end

--######################## XINewRegressionChildManager接口 ########################

-- 入口按钮排序权重，越小越前，可以重写自己的权重
function XSignInManager:GetButtonWeight()
    return tonumber(XNewRegressionConfigs.GetChildActivityConfig("SignInButtonWeight"))
end

-- 入口按钮显示名称
function XSignInManager:GetButtonName()
    return XNewRegressionConfigs.GetChildActivityConfig("SignInButtonName")
end

-- 获取面板控制数据
function XSignInManager:GetPanelContrlData()
    return {
        assetPath = XNewRegressionConfigs.GetChildActivityConfig("SignInPrefabAssetPath"),
        proxy = require("XUi/XUiNewRegression/XUiSignInPanel"),
    }
end

-- 用来显示页签和统一入口的小红点
function XSignInManager:GetIsShowRedPoint(...)
    return self:CheckCanGetReward()
end

return XSignInManager