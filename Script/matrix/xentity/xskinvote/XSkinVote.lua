
local Default = {
    _Id = 0, --活动Id
    _RandomNameIds = {},    --随机涂装名Id列表
    _VoteNameMap = {},      --涂装实体数据字典
    _VoteNameId = 0,        --投票涂装名Id
    _PreviewIndex = 1,      --预览图下标，不缓存，每次关闭界面会重置
    _PreviewCount = 0,      --预览图个数
}

---@class XSkinVoteData 单个投票数据实体
---@field Id number nameId
---@field Count number vote count
---@field Percent number vote count percent
---@field Name string skin name
local XSkinVoteData = XClass(nil, "XSkinVoteData")

function XSkinVoteData:Ctor(id)
    self.Id = id
    self.Count = 0
    self.Percent = 0
    self.Name = XSkinVoteConfigs.GetVoteName(id)
end

function XSkinVoteData:UpdateData(count, percent)
    self.Count = count
    self.Percent = percent
end

---@class XSkinVote 涂装投票数据层
local XSkinVote = XClass(XDataEntityBase, "XSkinVote")

function XSkinVote:Ctor(id)
    self:Init(Default, id)
end

function XSkinVote:InitData(id)
    self:SetProperty("_Id", id)
    local nameIds = XSkinVoteConfigs.GetVoteNameIds(id)
    local randomNameIds =  XTool.RandomArray(nameIds, XPlayer.Id)
    self:SetProperty("_RandomNameIds", randomNameIds)

    for _, nameId in ipairs(randomNameIds) do
        local voteData = XSkinVoteData.New(nameId)
        self._VoteNameMap[nameId] = voteData
    end

    local list = self:GetActivityPreviewImgFull()
    self:SetProperty("_PreviewCount", #list)
end

function XSkinVote:UpdateVoteData(voteInfoList)
    local countList = {}
    for i, info in ipairs(voteInfoList or {}) do
        countList[i] = info.VoteCount
    end
    local percents = XTool.CalArrayPercent(countList, 1)

    for i, info in ipairs(voteInfoList or {}) do
        local voteId = info.Id
        local voteData = self:GetVoteNameData(voteId)
        if not XTool.IsTableEmpty(voteData) then
            voteData:UpdateData(info.VoteCount, percents[i])
        end
    end
end

--- 投票数据实体
---@param nameId number 投票Id
---@return XSkinVoteData
--------------------------
function XSkinVote:GetVoteNameData(nameId)
    local voteData = self._VoteNameMap[nameId]
    if not voteData then
        XLog.Warning("XSkinVote:GetVoteNameData: could not find vote data!!! voteId = " .. tostring(nameId))
    end
    return voteData or {}
end

function XSkinVote:Vote(voteId)
    local voteData = self:GetVoteNameData(voteId)
    if not voteData then
        return
    end
    voteData.Count = voteData.Count + 1
    local list = {}
    for _, vote in pairs(self._VoteNameMap or {}) do
        table.insert(list, vote.Count)
    end
    local percents = XTool.CalArrayPercent(list, 1)

    for i, vote in pairs(self._VoteNameMap or {}) do
        if vote then
            vote:UpdateData(vote.Count, percents[i])
        end
    end
end

function XSkinVote:IsOpen()
    if not XTool.IsNumberValid(self._Id) then
        return false
    end
    return XSkinVoteConfigs.CheckActivityInTime(self._Id)
end

function XSkinVote:ResetPreviewIndex()
    self:SetProperty("_PreviewIndex", 1)
end

function XSkinVote:PlayPreviewNext()
    local index = self._PreviewIndex
    index = index + 1
    if index > self._PreviewCount then
        index = 1
    end
    self:SetProperty("_PreviewIndex", index)
end

function XSkinVote:PlayPreviewLast()
    local index = self._PreviewIndex
    index = index - 1
    if index <= 0 then
        index = self._PreviewCount
    end
    self:SetProperty("_PreviewIndex", index)
end

--投票时间过期
function XSkinVote:IsVoteExpired()
    local timeOfNow = XTime.GetServerNowTimestamp()
    local voteTimeOfEnd = XSkinVoteConfigs.GetActivityVoteEndTime(self._Id)
    return timeOfNow > voteTimeOfEnd
end

function XSkinVote:GetVoteTimeStr(timeFormat)
    timeFormat = timeFormat or "MM.dd"
    return string.format("%s-%s",
            XTime.TimestampToLocalDateTimeString(XSkinVoteConfigs.GetActivityVoteStartTime(self._Id), timeFormat),
            XTime.TimestampToLocalDateTimeString(XSkinVoteConfigs.GetActivityVoteEndTime(self._Id), timeFormat))
end

function XSkinVote:GetVoteExpiredTimeStr(timeFormat)
    timeFormat = timeFormat or "MM.dd"
    return string.format("%s-%s",
            XTime.TimestampToLocalDateTimeString(XSkinVoteConfigs.GetActivityVoteEndTime(self._Id), timeFormat),
            XTime.TimestampToLocalDateTimeString(XSkinVoteConfigs.GetActivityEndTime(self._Id), timeFormat))
end

function XSkinVote:GetActivityDesc()
    return XSkinVoteConfigs.GetActivityDesc(self._Id)
end

function XSkinVote:GetActivityVoteTips()
    return XSkinVoteConfigs.GetActivityVoteTips(self._Id)
end

function XSkinVote:GetActivityPreviewImgSmall()
    return XSkinVoteConfigs.GetActivityPreviewImgSmall(self._Id)
end

function XSkinVote:GetActivityPreviewImgFull()
    return XSkinVoteConfigs.GetActivityPreviewImgFull(self._Id)
end

function XSkinVote:GetActivityEndTime()
    return XSkinVoteConfigs.GetActivityEndTime(self._Id)
end

function XSkinVote:GetPrefabPath()
    return XSkinVoteConfigs.GetActivityPrefabPath(self._Id)
end

return XSkinVote