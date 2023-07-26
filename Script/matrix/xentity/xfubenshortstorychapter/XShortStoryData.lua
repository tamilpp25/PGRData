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

local XShortStoryData = XClass(nil,"XShortStoryData")

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
        for k, v in pairs(data.LastPassStage) do
            self._LastPassStage[k] = v
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
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if stageInfo.Type ~= XDataCenter.FubenManager.StageType.ShortStory then return end
    self._LastPassStage[stageInfo.ChapterId] = stageId
end

function XShortStoryData:GetLastPassStage(chapterId)
    return self._LastPassStage[chapterId]
end

function XShortStoryData:AddChapterEventState(chapterEventData)
    local eventIds = chapterEventData and chapterEventData.EventIds or {}
    for _, id in pairs(eventIds) do
        self._ChapterEventInfos[id] = true
    end
end

return XShortStoryData