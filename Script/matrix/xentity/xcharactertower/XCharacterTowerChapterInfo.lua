local type = type
local pairs = pairs

--[[
public class XChapterInfo
{
    // 章节Id
    public int ChapterId;
    // 已领取章节奖励
    public List<int> ChapterRewardData = new List<int>();
    // 已领取挑战星级奖励
    public List<int> TreasureData = new List<int>();
    // 已领取通关关卡奖励
    public List<int> StageRewardData = new List<int>();
    // 已播放录像
    public List<int> VideoedIds = new List<int>();
    // 已解锁羁绊
    public List<XRelationInfo> RelationInfos = new List<XRelationInfo>();
    // 已触发条件（客户端触发保存）
    public List<int> TriggerConditions = new List<int>();
}
]]

local Default = {
    _ChapterId = 0,
    _ChapterRewardData = {}, -- 已领取章节奖励
    _TreasureData = {}, --已领取挑战星级奖励
    _StageRewardData = {}, -- 已领取通关关卡奖励
    _VideoedIds = {}, -- 剧情关已播放动画的关卡Id
    _TriggerConditions = {}, -- 保存已触发的条件
}

---@class XCharacterTowerChapterInfo
local XCharacterTowerChapterInfo = XClass(nil, "XCharacterTowerChapterInfo")

function XCharacterTowerChapterInfo:Ctor(chapterId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    
    self._ChapterId = chapterId
end

function XCharacterTowerChapterInfo:UpdateData(data)
    self._ChapterRewardData = {}
    self._TreasureData = {}
    self._StageRewardData = {}
    self._VideoedIds = {}
    self._TriggerConditions = {}
    self:RecordData(data.ChapterRewardData, handler(self, self.RecordChapterRewardData))
    self:RecordData(data.TreasureData, handler(self, self.RecordTreasureData))
    self:RecordData(data.StageRewardData, handler(self, self.RecordStageRewardData))
    self:RecordData(data.VideoedIds, handler(self, self.RecordVideoedId))
    self:RecordData(data.TriggerConditions, handler(self, self.RecordTriggerCondition))
end

function XCharacterTowerChapterInfo:RecordData(data, callBack)
    for _, id in pairs(data or {}) do
        callBack(id)
    end
end

function XCharacterTowerChapterInfo:RecordChapterRewardData(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return
    end
    self._ChapterRewardData[chapterId] = chapterId
end

function XCharacterTowerChapterInfo:RecordTreasureData(treasureId)
    if not XTool.IsNumberValid(treasureId) then
        return
    end
    self._TreasureData[treasureId] = treasureId
end

function XCharacterTowerChapterInfo:RecordStageRewardData(stageId)
    if not XTool.IsNumberValid(stageId) then
        return
    end
    self._StageRewardData[stageId] = stageId
end

function XCharacterTowerChapterInfo:RecordVideoedId(stageId)
    if not XTool.IsNumberValid(stageId) then
        return
    end
    self._VideoedIds[stageId] = stageId
end

function XCharacterTowerChapterInfo:RecordTriggerCondition(conditionId)
    if not XTool.IsNumberValid(conditionId) then
        return
    end
    self._TriggerConditions[conditionId] = conditionId
end

-- 检测剧情最终奖励是否领取
function XCharacterTowerChapterInfo:CheckChapterRewardReceived(chapterId)
    return self._ChapterRewardData[chapterId] and true or false
end
-- 检测挑战星级奖励是否领取
function XCharacterTowerChapterInfo:CheckTreasureRewardReceived(treasureId)
    return self._TreasureData[treasureId] and true or false
end
-- 检测关卡奖励是否领取
function XCharacterTowerChapterInfo:CheckStageRewardReceived(stageId)
    return self._StageRewardData[stageId] and true or false
end
-- 检测剧情关卡动画是否播放过
function XCharacterTowerChapterInfo:CheckVideoPlayed(stageId)
    return self._VideoedIds[stageId] and true or false
end
-- 检测条件是否触发过
function XCharacterTowerChapterInfo:CheckTriggerCondition(conditionId)
    return self._TriggerConditions[conditionId] and true or false
end

return XCharacterTowerChapterInfo