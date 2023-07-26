local type = type
local pairs = pairs

--[[
public class XRelationInfo
{
    // 羁绊组Id
    public int RelationId;
    // 羁绊加成
    public List<int> FightEventIds = new List<int>();
    // 已播放剧情
    public List<string> StoryIds = new List<string>();
    // 已完成解锁条件
    public List<int> FinishConditions = new List<int>();
}
]]

local Default = {
    _RelationId = 0,
    _FightEventIds = {}, -- 羁绊加成
    _StoryIds = {}, -- 已播放剧情
    _FinishConditions = {}, -- 已完成解锁条件
}

---@class XCharacterTowerRelationInfo
local XCharacterTowerRelationInfo = XClass(nil, "XCharacterTowerRelationInfo")

function XCharacterTowerRelationInfo:Ctor(relationId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    
    self._RelationId = relationId
end

function XCharacterTowerRelationInfo:UpdateData(data)
    self._FightEventIds = {}
    self._StoryIds = {}
    self:RecordData(data.FightEventIds, handler(self, self.RecordFightEventId))
    self:RecordData(data.StoryIds, handler(self, self.RecordStoryId))
    self:RecordData(data.FinishConditions, handler(self, self.RecordFinishCondition))
end

function XCharacterTowerRelationInfo:RecordData(data, callBack)
    for _, id in pairs(data or {}) do
        callBack(id)
    end
end

function XCharacterTowerRelationInfo:RecordFightEventId(eventId)
    if not XTool.IsNumberValid(eventId) then
        return
    end
    self._FightEventIds[eventId] = eventId
end

function XCharacterTowerRelationInfo:RecordStoryId(storyId)
    if string.IsNilOrEmpty(storyId) then
        return
    end
    self._StoryIds[storyId] = storyId
end

function XCharacterTowerRelationInfo:RecordFinishCondition(conditionId)
    if not XTool.IsNumberValid(conditionId) then
        return
    end
    self._FinishConditions[conditionId] = conditionId
end

-- 检查羁绊加成是否解锁
function XCharacterTowerRelationInfo:CheckRelationUnlock(eventId)
    return self._FightEventIds[eventId] and true or false
end
-- 检测羁绊剧情是否播放过
function XCharacterTowerRelationInfo:CheckStoryPlayed(storyId)
    return self._StoryIds[storyId] and true or false
end
-- 检测条件是否已完成
function XCharacterTowerRelationInfo:CheckFinishCondition(conditionId)
    return self._FinishConditions[conditionId] and true or false
end

return XCharacterTowerRelationInfo