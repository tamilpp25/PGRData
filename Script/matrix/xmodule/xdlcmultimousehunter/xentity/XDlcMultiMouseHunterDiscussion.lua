---@class XDlcMultiMouseHunterDiscussion
local XDlcMultiMouseHunterDiscussion = XClass(nil, "XDlcMultiMouseHunterDiscussion")

function XDlcMultiMouseHunterDiscussion:Ctor()
    self._Id = nil                     --话题Id
    self._VoteEndTimestamp = nil       --投票截止时间
    self._DiscussionEndTimestamp = nil --话题截止时间
    self._DiscussionTimestampId = nil  --当前时间戳的话题id
    self._Status = nil                 --话题状态
    self._Ratio = nil                  --话题阵营1的比例

    self._PlayerId = nil               --玩家的话题Id
    self._PlayerCamp = nil             --玩家选择的阵营
    self._PlayerIsReward = nil         --玩家是否有奖励
end

function XDlcMultiMouseHunterDiscussion:SetData(data)
    if not data then
        return
    end

    if data.Id ~= nil then
        self._Id = data.Id
    end

    if data.Status ~= nil then
        self._Status = data.Status
    end

    if data.Ratio ~= nil then
        self._Ratio = data.Ratio
    end
end

function XDlcMultiMouseHunterDiscussion:SetInfo(info)
    if not info then
        return
    end

    if info.Id ~= nil then
        self._PlayerId = info.Id
    end

    if info.Camp ~= nil then
        self._PlayerCamp = info.Camp
    end

    if info.IsReward ~= nil then
        self._PlayerIsReward = info.IsReward
    end
end

function XDlcMultiMouseHunterDiscussion:GetId()
    return self._Id
end

function XDlcMultiMouseHunterDiscussion:GetTable()
    if not self:HasDiscussionData() then
        return nil
    end
    return XMVCA.XDlcMultiMouseHunter:GetDlcMultiplayerDiscussionConfigById(self._Id)
end

function XDlcMultiMouseHunterDiscussion:GetVoteEndTimestamp()
    self:_InitDiscussionTimestamp()
    return self._VoteEndTimestamp
end

function XDlcMultiMouseHunterDiscussion:GetDiscussionEndTimestamp()
    self:_InitDiscussionTimestamp()
    return self._DiscussionEndTimestamp
end

function XDlcMultiMouseHunterDiscussion:_InitDiscussionTimestamp()
    if self._DiscussionTimestampId ~= self._Id then
        local config = self:GetTable()
        self._VoteEndTimestamp = XTime.ParseToTimestamp(config.VoteEndTime)
        self._DiscussionEndTimestamp = XTime.ParseToTimestamp(config.DiscussionEndTime)
        self._DiscussionTimestampId = self._Id
    end
end

function XDlcMultiMouseHunterDiscussion:GetStatus()
    return self._Status
end

function XDlcMultiMouseHunterDiscussion:GetRatio()
    return self._Ratio
end

function XDlcMultiMouseHunterDiscussion:GetPlayerId()
    return self._PlayerId
end

function XDlcMultiMouseHunterDiscussion:GetPlayerTable()
    if not self:HasPlayerData() then
        return nil
    end
    return XMVCA.XDlcMultiMouseHunter:GetDlcMultiplayerDiscussionConfigById(self._PlayerId)
end

function XDlcMultiMouseHunterDiscussion:GetPlayerCamp()
    return self._PlayerCamp
end

function XDlcMultiMouseHunterDiscussion:GetPlayerIsReward()
    return self._PlayerIsReward
end

function XDlcMultiMouseHunterDiscussion:HasDiscussionData()
    return XTool.IsNumberValid(self._Id)
end

function XDlcMultiMouseHunterDiscussion:HasPlayerData()
    return XTool.IsNumberValid(self._PlayerId)
end

function XDlcMultiMouseHunterDiscussion:GetDiscussionTotalRatio()
    return 1000
end

function XDlcMultiMouseHunterDiscussion:GetCamp1Ratio()
    return self._Ratio or 0
end

function XDlcMultiMouseHunterDiscussion:GetCamp2Ratio()
    return self:GetDiscussionTotalRatio() - self:GetCamp1Ratio()
end

function XDlcMultiMouseHunterDiscussion:GetCamp1RatioStr()
    return string.format("%.1f%%", self:GetCamp1Ratio() / 10)
end

function XDlcMultiMouseHunterDiscussion:GetCamp2RatioStr()
    return string.format("%.1f%%", self:GetCamp2Ratio() / 10)
end

function XDlcMultiMouseHunterDiscussion:IsSameDiscussion()
    return self._PlayerId == self._Id
end

function XDlcMultiMouseHunterDiscussion:GetPlayerCamp1Ratio()
    if self:IsSameDiscussion() then
        return self:GetCamp1Ratio()
    else
        local config = self:GetPlayerTable()
        if config then
            return config.Camp1Ratio[#config.Camp1Ratio]
        else
            return 0
        end
    end
end

function XDlcMultiMouseHunterDiscussion:GetPlayerCamp2Ratio()
    return self:GetDiscussionTotalRatio() - self:GetPlayerCamp1Ratio()
end

function XDlcMultiMouseHunterDiscussion:GetPlayerCamp1RatioStr()
    return string.format("%.1f%%", self:GetPlayerCamp1Ratio() / 10)
end

function XDlcMultiMouseHunterDiscussion:GetPlayerCamp2RatioStr()
    return string.format("%.1f%%", self:GetPlayerCamp2Ratio() / 10)
end

function XDlcMultiMouseHunterDiscussion:IsStatistics()
    return self._Ratio == nil or self._Ratio == 0
end

function XDlcMultiMouseHunterDiscussion:IsPlayerCamp1Vectory()
    return self:GetPlayerCamp1Ratio() > self:GetDiscussionTotalRatio() / 2
end

function XDlcMultiMouseHunterDiscussion:IsPlayerCamp2Vectory()
    return self:GetPlayerCamp2Ratio() > self:GetDiscussionTotalRatio() / 2
end

function XDlcMultiMouseHunterDiscussion:IsPlayerVectory()
    local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionCamp
    return (self:IsPlayerCamp1Vectory() and self:GetPlayerCamp() == CampEnum.Camp1) or (self:IsPlayerCamp2Vectory() and self:GetPlayerCamp() == CampEnum.Camp2)
end

function XDlcMultiMouseHunterDiscussion:CanGetReward()
    if not self:HasDiscussionData() and not self:HasPlayerData() then
        return false
    end

    local StatusEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionStatus
    local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionCamp
    if self:GetPlayerCamp() ~= CampEnum.None then
        if self:IsSameDiscussion() then
            return self:GetPlayerIsReward() and self:GetStatus() == StatusEnum.Show
        else
            return self:GetPlayerIsReward()
        end
    else
        return false
    end
end

return XDlcMultiMouseHunterDiscussion
