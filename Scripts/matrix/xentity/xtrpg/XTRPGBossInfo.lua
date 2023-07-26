local type = type

local XTRPGBossInfo = XClass(nil, "XTRPGBossInfo")

local Default = {
    __Id = 0,
    __LoseHp = 0, --丢失血量
    __TotalHp = 0, --总血量
    __ChallengeCount = 0, --已挑战的次数
    __PhasesRewardList = {}, --奖励列表（保存已领取的奖励id）
}

function XTRPGBossInfo:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XTRPGBossInfo:UpdateBaseData(data)
    if not data then return end
    self.__Id = data.Id
    self.__ChallengeCount = data.ChallengeCount
    self:UpdatePhasesRewardList(data.PhasesRewardList)
end

function XTRPGBossInfo:UpdateHpData(data)
    self.__LoseHp = data.LoseHp
    self.__TotalHp = data.TotalHp
end

function XTRPGBossInfo:UpdatePhasesRewardList(phasesRewardList)
    if not phasesRewardList then return end
    for _, id in pairs(phasesRewardList) do
        self.__PhasesRewardList[id] = 1
    end
end

function XTRPGBossInfo:UpdateWorldBossChallengeCount(count)
    self.__ChallengeCount = count
end

function XTRPGBossInfo:GetId()
    return self.__Id
end

function XTRPGBossInfo:GetLoseHp()
    return self.__LoseHp
end

function XTRPGBossInfo:GetTotalHp()
    return self.__TotalHp
end

function XTRPGBossInfo:IsReceiveReward(id)
    return self.__PhasesRewardList[id]
end

function XTRPGBossInfo:GetChallengeCount()
    return self.__ChallengeCount
end

return XTRPGBossInfo