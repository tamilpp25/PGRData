local type = type

---@class XPassportInfo@玩家通行证信息
local XPassportInfo = XClass(nil, "XPassportInfo")

local Default = {
    _Id = 1, --通行证Id
    _GotRewardDic = {}, --奖励领取记录
}

function XPassportInfo:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XPassportInfo:UpdateData(data)
    if XTool.IsTableEmpty(data) then return end
    self._Id = data.Id
    
    for _, passportRewardId in ipairs(data.GotRewardList) do
        self:SetReceiveReward(passportRewardId)
    end
end

function XPassportInfo:GetId()
    return self._Id
end

function XPassportInfo:SetReceiveReward(passportRewardId)
    self._GotRewardDic[passportRewardId] = true
end

function XPassportInfo:IsReceiveReward(passportRewardId)
    return self._GotRewardDic[passportRewardId]
end

return XPassportInfo