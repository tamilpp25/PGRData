local XGachaGroup = require("XEntity/XNewRegression/Gacha/XGachaGroup")
local XINewRegressionChildManager = require("XEntity/XNewRegression/XINewRegressionChildManager")
local XGachaManager = XClass(XINewRegressionChildManager, "XGachaManager")

function XGachaManager:Ctor(id)
    self.Config = XNewRegressionConfigs.GetGachaConfig(id)
    -- XGachaGroup
    self.GachaGroupDic = {}
    -- 活动开始时间
    self.BeginTime = nil
end

-- data : XRegression2GachaData
function XGachaManager:InitWithServerData(data)
    for _, groupData in ipairs(data.GroupDatas or {}) do
        self:GetGachaGroup(groupData.Id):InitWithServerData(groupData)
    end
end

-- data : NotifyRegression2InvitePoint
function XGachaManager:UpdateWithServerData(data)
    for _, groupData in ipairs(data.GroupDatas or {}) do
        self:GetGachaGroup(groupData.Id):UpdateWithServerData(groupData)
    end
end

function XGachaManager:SetBeginTime(value)
    self.BeginTime = value
end

function XGachaManager:GetGachaGroup(id)
    if self.GachaGroupDic[id] == nil then
        self.GachaGroupDic[id] = XGachaGroup.New(id)
    end
    return self.GachaGroupDic[id]
end

function XGachaManager:GetGachaGroups()
    local result = {}
    for _, id in ipairs(XNewRegressionConfigs.GetGachaGroupIds(self.Config.Id)) do
        table.insert(result, self:GetGachaGroup(id))
    end
    return result
end

function XGachaManager:GetCurrentGachaGroupIndex()
    local gachaGroups = self:GetGachaGroups()
    for i, gachaGroup in ipairs(gachaGroups) do
        if gachaGroup:GetState() == XNewRegressionConfigs.GachaGroupState.Begin then
            return i
        end
    end
    return #gachaGroups
end

function XGachaManager:GetCurrentGachaGroup()
    return self:GetGachaGroups()[self:GetCurrentGachaGroupIndex()]
end

-- 检查抽奖组是否已经开启
function XGachaManager:CheckGachaGroupIsOpen(groupId)
    local gachaGroups = self:GetGachaGroups()
    local targetIndex = 1
    for i, gachaGroup in ipairs(gachaGroups) do
        if gachaGroup:GetId() == groupId then
            targetIndex = i
            break
        end
    end
    if targetIndex <= 1 then return true end
    return gachaGroups[targetIndex - 1]:GetIsFinishedCoreReward() 
end

function XGachaManager:GetConsumeId()
    return self.Config.ConsumeId
end

function XGachaManager:GetConsumeIcon()
    return XDataCenter.ItemManager.GetItemIcon(self.Config.ConsumeId)
end

function XGachaManager:GetConsumeCount()
    return self.Config.ConsumeCount
end

-- 检查是否能够抽奖
function XGachaManager:CheckCanPlayGacha()
    local currentGroup = self:GetCurrentGachaGroup()
    return currentGroup:GetRewardRemainingCount() > 0
        and XEntityHelper.CheckItemCountIsEnough(self:GetConsumeId(), 10, false)
end

function XGachaManager:RequestGetReward(gachaGroupId, times, callback)
    -- 检查抽奖组是否已经开启
    if not self:CheckGachaGroupIsOpen(gachaGroupId) then
        XUiManager.TipErrorWithKey("NewRegressionGachaRewardTip1")
        return 
    end
    -- 检查奖励组是否已经抽取完毕
    if self:GetGachaGroup(gachaGroupId):GetIsDone() then
        XUiManager.TipErrorWithKey("NewRegressionGachaRewardTip2")
        return 
    end
    -- 检查次数是否满足
    local needCount = times * self:GetConsumeCount()
    if not XEntityHelper.CheckItemCountIsEnough(self.Config.ConsumeId, needCount) then
        return
    end
    local requestBody = { 
        GachaId = self.Config.Id,
        GachaGroupId = gachaGroupId,
        Times = times,
    }
    XNetwork.CallWithAutoHandleErrorCode("Regression2GachaDoGachaRequest", requestBody, function(res)
        local gachaGroup = self:GetGachaGroup(gachaGroupId)
        gachaGroup:UpdateRewardTimesDic(res.GridInfoList)
        RunAsyn(function()
            XLuaUiManager.Open("UiRewardPreviewEffect")
            local signalCode = XLuaUiManager.AwaitSignal("UiRewardPreviewEffect", "_", self)
            if signalCode ~= XSignalCode.RELEASE then return end
            XLuaUiManager.Open("UiGachaOrganizeDrawResult", res.RewardGoods)
        end)
        if callback then callback() end
    end)
end

--######################## XINewRegressionChildManager接口 ########################

-- 入口按钮排序权重，越小越前，可以重写自己的权重
function XGachaManager:GetButtonWeight()
    return tonumber(XNewRegressionConfigs.GetChildActivityConfig("GachaButtonWeight"))
end

-- 入口按钮显示名称
function XGachaManager:GetButtonName()
    return XNewRegressionConfigs.GetChildActivityConfig("GachaButtonName" .. self.Config.Type)
end

-- 获取面板控制数据
function XGachaManager:GetPanelContrlData()
    return {
        assetPath = XNewRegressionConfigs.GetChildActivityConfig("GachaPrefabAssetPath"),
        proxy = require("XUi/XUiNewRegression/XUiGachaPanel"),
    }
end

function XGachaManager:GetIsShowRedPoint()
    return self:CheckCanPlayGacha()
end

-- 获取该子活动管理器是否开启
function XGachaManager:GetIsOpen()
    if self.Config.TimeId > 0 then
        return XFunctionManager.CheckInTimeByTimeId(self.Config.TimeId)
    end
    local endTime = self.BeginTime + self.Config.ContinueDays * 24 * 3600
    endTime = XTime.GetTimeDayFreshTime(endTime)
    return XTime.GetServerNowTimestamp() < endTime
end

return XGachaManager