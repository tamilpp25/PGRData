local type = type
local pairs = pairs

--[[public class XQuestAccept
{
    // 委托id
    public int QuestId;
    // 接取时间
    public long AcceptTime;
    // 派遣成员
    public List<int> TeamCharacter = new List<int>();
    // 获得文件
    public int FileId;
    // 是否特殊委托
    public bool IsSpecialQuest;
    // 委托面板位置
    public int Index;
    // 是否符合推荐属性
    public bool IsSatisfyRecommend;
    // 重置计数
    public int ResetCount;
    // 是否领奖
    public bool IsAward = false;
}]]

local Default = {
    _QuestId = 0, -- 委托id
    _AcceptTime = 0, -- 接取时间
    _TeamCharacter = {}, -- 派遣成员
    _FileId = 0, -- 获得文件
    _IsSpecialQuest = false, -- 是否特殊委托
    _Index = 0, -- 委托面板位置
    _IsSatisfyRecommend = false, -- 是否符合推荐属性
    _ResetCount = 0, -- 重置计数
    _IsAward = false, -- 是否领奖
}

-- 已接取委托
---@class XDormQuestAcceptInfo
local XDormQuestAcceptInfo = XClass(nil, "XDormQuestAcceptInfo")

function XDormQuestAcceptInfo:Ctor(data)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    if data then
        self:UpdateData(data)
    end
end

function XDormQuestAcceptInfo:UpdateData(data)
    self._QuestId = data.QuestId
    self._AcceptTime = data.AcceptTime
    self._FileId = data.FileId
    self._IsSpecialQuest = data.IsSpecialQuest
    self._TeamCharacter = data.TeamCharacter
    self._Index = data.Index
    self._IsSatisfyRecommend = data.IsSatisfyRecommend
    self._ResetCount = data.ResetCount
    self._IsAward = data.IsAward
end

-- 获取委托Id
function XDormQuestAcceptInfo:GetQuestId()
    return self._QuestId
end

-- 获取下标
function XDormQuestAcceptInfo:GetIndex()
    return self._Index
end

-- 获取接取时间
function XDormQuestAcceptInfo:GetAcceptTime()
    return self._AcceptTime
end

-- 获取派遣成员信息
function XDormQuestAcceptInfo:GetTeamCharacter()
    return self._TeamCharacter
end

-- 获取重置次数
function XDormQuestAcceptInfo:GetResetCount()
    return self._ResetCount
end

-- 是否领奖
function XDormQuestAcceptInfo:IsAward()
    return self._IsAward
end

return XDormQuestAcceptInfo