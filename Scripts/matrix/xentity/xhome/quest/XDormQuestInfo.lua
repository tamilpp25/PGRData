local type = type
local pairs = pairs

--[[public class XQuestInfo
{
    // 委托id
    public int QuestId;
    // 获得文件
    public int FileId;
    // 委托面板位置
    public int Index;
    // 是否特殊委托
    public bool IsSpecialQuest;
    // 重置计数
    public int ResetCount;
}]]

local Default = {
    _QuestId = 0, -- 委托id
    _FileId = 0, -- 获得文件
    _Index = 0, -- 委托面板位置
    _IsSpecialQuest = false, -- 是否特殊委托
    _ResetCount = 0, -- 重置计数
}

--委托详情
---@class XDormQuestInfo
local XDormQuestInfo = XClass(nil, "XDormQuestInfo")

function XDormQuestInfo:Ctor(data)
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

function XDormQuestInfo:UpdateData(data)
    self._QuestId = data.QuestId
    self._FileId = data.FileId
    self._Index = data.Index
    self._IsSpecialQuest = data.IsSpecialQuest
    self._ResetCount = data.ResetCount
end

-- 获取委托Id
function XDormQuestInfo:GetQuestId()
    return self._QuestId
end

-- 获取下标
function XDormQuestInfo:GetIndex()
    return self._Index
end

-- 是否是特殊委托
function XDormQuestInfo:GetIsSpecialQuest()
    return self._IsSpecialQuest
end

-- 获取重置次数
function XDormQuestInfo:GetResetCount()
    return self._ResetCount
end

return XDormQuestInfo