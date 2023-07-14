
---@class XRegression3rdPassportInfo 战令基础信息
---@field _Id 战令类型Id
---@field _GotRewardDict 已领取奖励Id
---@field _Unlock 是否解锁
local XRegression3rdPassportInfo = XClass(nil, "XRegression3rdPassportInfo")

function XRegression3rdPassportInfo:Ctor(typeId)
    self._Id = typeId
    self._Unlock = false
    self._GotRewardDict = {}
end

function XRegression3rdPassportInfo:Unlock()
    self._Unlock = true
end

function XRegression3rdPassportInfo:IsReceive(rewardId)
    if not self._Unlock then
        return false
    end
    return self._GotRewardDict[rewardId]
end

function XRegression3rdPassportInfo:IsUnlock()
    return self._Unlock
end

function XRegression3rdPassportInfo:Receive(rewardId)
    if not self._Unlock then
        return
    end
    self._GotRewardDict[rewardId] = true
end

function XRegression3rdPassportInfo:ReceiveList(rewardIds)
    if not self._Unlock then
        return
    end
    for _, rewardId in ipairs(rewardIds) do
        self._GotRewardDict[rewardId] = true
    end
end

function XRegression3rdPassportInfo:GetId()
    return self._Id
end


local XRegression3rdPassport = XClass(XDataEntityBase, "XRegression3rdPassport")

local default = {
    _Id = 0, --战令活动Id
    _Level = 0,                 --战令等级
    _PassportInfoDict = {},     --战令基础信息类
    _Accumulated = 0,           --累积获得数量
    _AutoGetRewards = {},       --自动领取奖励
}

function XRegression3rdPassport:Ctor(bpId)
    self:Init(default, bpId)
end

function XRegression3rdPassport:InitData(id)
    self:SetProperty("_Id", id)
    
    local infos = self:GetPassportTypeInfos()
    for _, info in ipairs(infos) do
        local oInfo = XRegression3rdPassportInfo.New(info.Id)
        if info.IsFree then
            oInfo:Unlock()
        end
        self._PassportInfoDict[info.Id] = oInfo
    end
end

--- 服务端数据更新
---@param notifyData Server.XRegression3PassportData
---@return nil
--------------------------
function XRegression3rdPassport:UpdateData(notifyData)
    if not notifyData then
        return
    end
    self:SetProperty("_Level", notifyData.Level)
    self:SetAccumulated(notifyData.Exp)
    self:SetProperty("_AutoGetRewards", notifyData.AutoGetRewards)
    for _, info in ipairs(notifyData.PassportInfos) do
        self:BuyPassport(info.Id)
    end
    self:ReceiveAvailable(notifyData.PassportInfos)
end

function XRegression3rdPassport:BuyPassport(typeId)
    local oInfo = self:_GetPassportInfo(typeId)
    if not oInfo then
        return
    end
    oInfo:Unlock()
    self:SetProperty("_PassportInfoDict", self._PassportInfoDict)
end

--- 领取单个奖励
---@param rewardId Regression3PassportReward表Id
---@param passportTypeId 战令类型
function XRegression3rdPassport:ReceiveSingleReward(rewardId, passportTypeId)
    local oInfo = self:_GetPassportInfo(passportTypeId)
    if not oInfo then
        return
    end
    oInfo:Receive(rewardId)
    self:SetProperty("_PassportInfoDict", self._PassportInfoDict)
end

--- 领取当前可以领取奖励
---@param passportInfos Server.XRegression3PassportInfo
function XRegression3rdPassport:ReceiveAvailable(passportInfos)
    for _, info in ipairs(passportInfos) do
        local oInfo = self:_GetPassportInfo(info.Id)
        if oInfo then
            oInfo:ReceiveList(info.GotRewardList)
        end
    end
    self:SetProperty("_PassportInfoDict", self._PassportInfoDict)
end

--奖励是否解锁
function XRegression3rdPassport:CheckUnlock(level, passportTypeId)
    local oInfo = self:_GetPassportInfo(passportTypeId)
    if not oInfo then
        return false
    end
    if level <= 0 then
        return false
    end
    return self._Level >= level and oInfo:IsUnlock()
end

--奖励是否领取
function XRegression3rdPassport:CheckReceive(rewardId, passportTypeId)
    local oInfo = self:_GetPassportInfo(passportTypeId)
    if not oInfo then
        return false
    end
    return oInfo:IsReceive(rewardId)
end

--奖励是否可以领取
function XRegression3rdPassport:CheckAvailable(level, rewardId, passportTypeId)
    return self:CheckUnlock(level, passportTypeId) and not self:CheckReceive(rewardId, passportTypeId)
end

--拥有可领取的奖励
function XRegression3rdPassport:IsRewardsAvailable()
    local rewardDict = XRegression3rdConfigs.GetPassportRewardInfos(self._Id)
    for passportTypeId, info in pairs(rewardDict or {}) do
        for level, rewardId in pairs(info) do
            if self:CheckAvailable(level, rewardId, passportTypeId) then
                return true
            end
        end
    end
    return false
end

function XRegression3rdPassport:IsPassportBuy(typeInfoId)
    local oInfo = self:_GetPassportInfo(typeInfoId)
    if not oInfo then
        return false
    end
    return oInfo:IsUnlock()
end

function XRegression3rdPassport:GetPassportTypeInfos()
    return XRegression3rdConfigs.GetPassportTypeInfos(self._Id)
end

--获取可支付的类型
function XRegression3rdPassport:GetPayPassportTypeInfo()
    for _, oInfo in pairs(self._PassportInfoDict) do
        if oInfo and not oInfo:IsUnlock() then
            return XRegression3rdConfigs.GetPassportTypeInfoTemplate(oInfo:GetId())
        end
    end
end

function XRegression3rdPassport:GetPassportLevelInfos()
    return XRegression3rdConfigs.GetPassportLevelInfos(self._Id)
end

function XRegression3rdPassport:GetLevelInfo(level)
    local infos = self:GetPassportLevelInfos()
    for _, info in ipairs(infos) do
        if info.Level == level then
            return info
        end
    end
    return {}
end

--获取可领取奖励的最小下标
function XRegression3rdPassport:GetAvailableRewardIndex()
    local infos = self:GetPassportLevelInfos()
    local types = self:GetPassportTypeInfos()
    local tmp = {}
    for _, type in ipairs(types) do
        for idx, info in ipairs(infos) do
            if info.Level > self._Level then
                break
            end
            local rewardId = self:GetPassportRewardInfo(type.Id, info.Level).Id
            if self:CheckAvailable(info.Level, rewardId, type.Id) then
                table.insert(tmp, idx)
                break
            end
        end
    end
    
    if not XTool.IsTableEmpty(tmp) then
        table.sort(tmp, function(a, b) 
            return a < b
        end)
        return tmp[1]
    end
end

function XRegression3rdPassport:ClearAutoGetRewards()
    self._AutoGetRewards = {}
end

function XRegression3rdPassport:GetPassportRewardInfo(typeInfoId, level)
    return XRegression3rdConfigs.GetPassportRewardInfo(self._Id, typeInfoId, level)
end

function XRegression3rdPassport:GetBuyPassPortEarlyEndTime()
    return XRegression3rdConfigs.GetBuyPassportEndTime(self._Id)
end

function XRegression3rdPassport:_GetPassportInfo(typeId)
    local oInfo = self._PassportInfoDict[typeId]
    if not oInfo then
        XLog.Warning("XRegression3rdPassport:BuyPassport: get info object error, typeId = " .. typeId)
        return
    end
    return oInfo
end

function XRegression3rdPassport:SetAccumulated(exp)
    self:SetProperty("_Accumulated", exp)
    XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION3_PASSPORT_STATUS_CHANGE)
end

return XRegression3rdPassport