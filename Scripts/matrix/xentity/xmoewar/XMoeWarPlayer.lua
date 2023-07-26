---@class XMoeWarPlayer
local XMoeWarPlayer = XClass(nil, "XMoeWarPlayer")

local tableInsert = table.insert
local tableSort = table.sort
local stringFormat = string.format
local pairs = pairs
local ipairs = ipairs

local Default = {
    -- 选手基本信息
    TodaySupport = 0,
    SupportTotal = 0,
    MyVote = 0,
    IsEliminate = false
}

local DEFAULT_ANIM_INDEX = 1 --动画默认下标

function XMoeWarPlayer:Ctor(Id)
    for key in pairs(Default) do
        self[key] = Default[key]
    end

    self.Data = {}
    self.MatchInfoDic = {}
    self.DailyVoteDic = {}
    self:LoadPlayerCfg(Id)
    self.AnimRandomIndex = {}
end

function XMoeWarPlayer:LoadPlayerCfg(Id)
    self.Id = Id
    self.Cfg = XMoeWarConfig.GetPlayerCfg(Id)
    self.Group = XMoeWarConfig.GetPlayerGroup(Id)
end

--function XMoeWarPlayer:GetGroup()
--    return self.Group
--end
function XMoeWarPlayer:GetGroupName()
    return XDataCenter.MoeWarManager.GetActivityInfo().GroupName[self.Group]
end

function XMoeWarPlayer:GetName()
    return self.Cfg.Name
end

function XMoeWarPlayer:GetDesc()
    return self.Cfg.Description
end

function XMoeWarPlayer:GetModel()
    return self.Cfg.ModelName
end

function XMoeWarPlayer:GetJob()
    return self.Cfg.CareerName
end

function XMoeWarPlayer:GetCareerIcon()
    return self.Cfg.CareerIcon
end

function XMoeWarPlayer:GetCamp()
    return self.Cfg.CampName
end

function XMoeWarPlayer:GetAnim(actionType)
    math.randomseed(os.time())
    if actionType == XMoeWarConfig.ActionType.Intro then
        --左闭右闭
        local index = math.random(1, #self.Cfg.IntroAnim)
        self.AnimRandomIndex[XMoeWarConfig.ActionType.Intro] = index
        return self.Cfg.IntroAnim[index]
    elseif actionType == XMoeWarConfig.ActionType.Thank then
        --左闭右闭
        local index = math.random(1, #self.Cfg.ThankAnim)
        self.AnimRandomIndex[XMoeWarConfig.ActionType.Thank] = index
        return self.Cfg.ThankAnim[index]
    end
end

function XMoeWarPlayer:GetCv(actionType)
    if actionType == XMoeWarConfig.ActionType.Intro then
        return self.Cfg.IntroCv
    elseif actionType == XMoeWarConfig.ActionType.Thank then
        return self.Cfg.ThankCv
    end
end

function XMoeWarPlayer:GetLength(actionType)
    if actionType == XMoeWarConfig.ActionType.Intro then
        local index = self.AnimRandomIndex[XMoeWarConfig.ActionType.Intro] or DEFAULT_ANIM_INDEX
        return self.Cfg.IntroLength[index]
    elseif actionType == XMoeWarConfig.ActionType.Thank then
        local index = self.AnimRandomIndex[XMoeWarConfig.ActionType.Thank] or DEFAULT_ANIM_INDEX
        return self.Cfg.ThankLength[index]
    end
end

function XMoeWarPlayer:GetAnimRandomIndex(actionType)
    if not XTool.IsNumberValid(actionType) then
        return DEFAULT_ANIM_INDEX
    end
    return self.AnimRandomIndex[actionType] or DEFAULT_ANIM_INDEX
end

function XMoeWarPlayer:GetActionBg()
    return self.Cfg.ActionBg
end

function XMoeWarPlayer:GetSquareHead()
    return self.Cfg.SquareHead
end

function XMoeWarPlayer:GetCircleHead()
    return self.Cfg.CircleHead
end

function XMoeWarPlayer:GetBigCharacterImage()
    return self.Cfg.BigCharacterImage
end

function XMoeWarPlayer:GetSupportCount(matchId)
    if matchId then
        local matchInfo = self.MatchInfoDic[matchId]
        if matchInfo then
            return matchInfo.VoteCount
        else
            return 0
        end
    else
        return self.SupportTotal
    end
end

function XMoeWarPlayer:GetMySupportCount(sId)
    local match = XDataCenter.MoeWarManager.GetVoteMatch(sId)
    if match then
        local matchInfo = self.MatchInfoDic[match.Id]
        if matchInfo and matchInfo.MyVote then
            return matchInfo.MyVote
        else
            return 0
        end
    else
        return self.MyVote
    end
end

function XMoeWarPlayer:GetIsEliminate()
    return self.IsEliminate
end

function XMoeWarPlayer:GetShareImage()
    return self.Cfg.ShareImg
end

function XMoeWarPlayer:GetWinAnimGroupId(sessionId)
    return self.Cfg.WinAnimGroupId[sessionId]
end

function XMoeWarPlayer:GetLoseAnimGroupId(sessionId)
    return self.Cfg.LoseAnimGroupId[sessionId]
end

local SECOND_SESSIONID = 5--仅决赛时出现第二名（三人比赛），固定配置列5
function XMoeWarPlayer:GetSecondAnimGroupId()
    return self.Cfg.LoseAnimGroupId[SECOND_SESSIONID]
end

function XMoeWarPlayer:UpdateDailyVote(itemId, voteCount)
    self.DailyVoteDic[itemId] = voteCount
end

function XMoeWarPlayer:GetDailyVoteByItemId(itemId)
    return self.DailyVoteDic[itemId] or 0
end

function XMoeWarPlayer:UpdateMatchVote(match, voteCount, pairInfo)
    local info = self.MatchInfoDic[match.Id] or {}
    info.IsWin = pairInfo.WinnerId == self.Id
    info.IsSecond = pairInfo.SecondId == self.Id
    info.MyVote = info.MyVote or 0
    info.VoteCount = voteCount
    self.SupportTotal = self.SupportTotal + voteCount
    info.MatchEntity = match
    -- 已结束
    if pairInfo.WinnerId ~= 0 then
        info.IsOver = true
        if not info.IsWin then
            self.IsEliminate = true
        end
    end
    self.MatchInfoDic[match.Id] = info
end

function XMoeWarPlayer:UpdateMatchMyVote(data)
    local matchInfo = self.MatchInfoDic[data.MatchId]
    matchInfo.MyVote = data.MyVote or 0
    self.MyVote = self.MyVote + matchInfo.MyVote

    -- if matchInfo.IsOver then
    --     self.MatchInfoDic[data.MatchId] = XReadOnlyTable.Create(matchInfo)
    -- end
end

--萌战投票请求
function XMoeWarPlayer:RequestVote(itemNo, count, cb)
    local req = { PlayerId = self.Id,
    ItemId = XMoeWarConfig.GetVoteItemById(itemNo).ItemId,
    Count = count }
    XNetwork.Call("MoeWarVoteRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if self.DailyVoteDic[req.ItemId] then
            self.DailyVoteDic[req.ItemId] = self.DailyVoteDic[req.ItemId] + count
        else
            self.DailyVoteDic[req.ItemId] = count
        end
        XDataCenter.MoeWarManager.UpdateDailyVoteCount(res.Vote)
        local matchInfo = self.MatchInfoDic[XDataCenter.MoeWarManager.GetCurMatchId()]
        matchInfo.MyVote = matchInfo.MyVote + res.Vote
        self.MyVote = self.MyVote + res.Vote
        if cb then
            cb(count)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_MOE_WAR_VOTE_SUCC)
    end)
end

return XMoeWarPlayer