

local XRegression3rdSign = XClass(XDataEntityBase, "XRegression3rdSign")

local default = {
    _Id = 0, --活动id
    _SignDay = 0,   --签到天数
    _SignIdDict = {},  --已领取奖励Id
}

function XRegression3rdSign:Ctor(id)
    self:Init(default, id)
end 

function XRegression3rdSign:InitData(id)
    self:SetProperty("_Id", id)
end

--- 服务端数据更新
---@param notifyData Server.XRegression3SignInData
---@return nil
--------------------------
function XRegression3rdSign:UpdateData(notifyData)
    if not notifyData then
        return
    end
    local signList = self:GetSignInfos()
    self:SetProperty("_SignDay", math.min(notifyData.SigninTimes, #signList))
    self:ReceiveMultiSign(notifyData.Rewards)
end

function XRegression3rdSign:GetSignInfos()
    return XRegression3rdConfigs.GetSignInList(self._Id)
end

-- 是否有奖励可以领取
function XRegression3rdSign:CheckHasReward()
    local receivedDay = 0
    for _, signId in pairs(self._SignIdDict) do
        if XTool.IsNumberValid(signId) then
            receivedDay = receivedDay + 1
        end
    end
    return self._SignDay > receivedDay
end

-- 检查该天是否签到
function XRegression3rdSign:CheckIsSign(signDay)
    return self._SignDay >= signDay
end

-- 检查该天的签到奖励是否领取
function XRegression3rdSign:CheckIsReceive(signId)
    return self._SignIdDict[signId]
end

-- 领取签到奖励
function XRegression3rdSign:ReceiveSign(signId)
    self._SignIdDict[signId] = true
    self:SetProperty("_SignIdDict", self._SignIdDict)
end

function XRegression3rdSign:ReceiveMultiSign(signIds)
    for _, signId in ipairs(signIds) do
        self._SignIdDict[signId] = true
    end
    self:SetProperty("_SignIdDict", self._SignIdDict)
end

function XRegression3rdSign:SetSignTimes(signTimes)
    local signList = self:GetSignInfos()
    self:SetProperty("_SignDay", math.min(signTimes, #signList))
end

return XRegression3rdSign