local type = type
local pairs = pairs
--[[
public sealed class NotifyFubenShortStoryData
{
    public List<int> TreasureData;
    public List<XShortStoryLastPassStage> LastPassStage;
    public List<XShortStoryEventInfo> ChapterEventInfos;
}
]]

local Default = {
    _PlayerTreasureData = {}, --已领取的奖励Id列表
    _LastPassStage = {},
    _ChapterEventInfos = {},
}

---@class XShortStoryData
---@field _PlayerTreasureData table<number, boolean>
---@field _LastPassStage table<number, number>
---@field _ChapterEventInfos table<number, boolean>
local XShortStoryData = XClass(nil, "XShortStoryData")

function XShortStoryData:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XShortStoryData:UpdateData(data)
    if not data then return end
    if data.TreasureData then
        for _, value in pairs(data.TreasureData) do
            self._PlayerTreasureData[value] = true
        end
    end
    if data.LastPassStage then
        for _, v in pairs(data.LastPassStage) do
            self._LastPassStage[v.ChapterId] = v.StageId
        end
    end
    if data.ChapterEventInfos then
        for _, eventInfo in pairs(data.ChapterEventInfos) do
            local eventIds = eventInfo.EventIds or {}
            for _, id in pairs(eventIds) do
                self._ChapterEventInfos[id] = true
            end
        end
    end
end

function XShortStoryData:IsTreasureGet(treasureId)
    return self._PlayerTreasureData[treasureId]
end

function XShortStoryData:SyncTreasureStage(treasureId)
    self._PlayerTreasureData[treasureId] = true
end

function XShortStoryData:OnSyncStageData(stageId)
    local stageType = XMVCA.XFuben:GetStageType(stageId)
    if stageType ~= XEnumConst.FuBen.StageType.ShortStory then
        return
    end
    local chapterId = XFubenShortStoryChapterConfigs.GetShortStoryChapterIdByStageId(stageId)
    self:SetLastPassStage(chapterId, stageId)
end

function XShortStoryData:SetLastPassStage(chapterId, stageId)
    if XTool.IsNumberValid(chapterId) then
        self._LastPassStage[chapterId] = stageId
    end
end

function XShortStoryData:GetLastPassStage(chapterId)
    return self._LastPassStage[chapterId] or 0
end

function XShortStoryData:AddChapterEventState(chapterEventData)
    local eventIds = chapterEventData and chapterEventData.EventIds or {}
    for _, id in pairs(eventIds) do
        self._ChapterEventInfos[id] = true
    end
end

return XShortStoryData