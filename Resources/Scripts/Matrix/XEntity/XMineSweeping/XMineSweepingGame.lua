local XMineSweepingGame = XClass(nil, "XMineSweepingGame")
local XMineSweepingChapter = require("XEntity/XMineSweeping/XMineSweepingChapter")

function XMineSweepingGame:Ctor()
    self.ActivityId = self:GetDefaultId()
    self.MineSweepingList = {}
    self.ChapterEntityDic = {}
end

function XMineSweepingGame.GetDefaultId()
    local defaultId = 0
    local spareId = 0
    local nowTime = XTime.GetServerNowTimestamp()
    local activityCfgs = XMineSweepingConfigs.GetMineSweepingActivityCfgs()
    local miniEndTime
    local MaxBeginTime
    for id,cfg in pairs(activityCfgs) do
        local beginTime, endTime = XFunctionManager.GetTimeByTimeId(cfg.TimeId)
        if endTime > nowTime then
            if miniEndTime == nil or miniEndTime == 0 or endTime < miniEndTime then
                defaultId = id
                miniEndTime = endTime
            end
        else
            if endTime == 0 then
                if miniEndTime == nil then
                    defaultId = id
                    miniEndTime = endTime
                end
            end
        end

        if MaxBeginTime == nil or beginTime > MaxBeginTime then
            spareId = id
            MaxBeginTime = beginTime
        end
    end

    defaultId = defaultId == 0 and spareId or defaultId

    return defaultId
end

function XMineSweepingGame:UpdateData(data)
    for key, value in pairs(data or {}) do
        self[key] = value
        if key == "MineSweepingList" then
            self:CreateChapterData()
            self:UpdateChapterData()
        end
    end
end

function XMineSweepingGame:CreateChapterData()
    for _,chapterData in pairs(self.MineSweepingList) do
        local entity = self.ChapterEntityDic[chapterData.ActivityChapterId]
        if not entity then
            entity = XMineSweepingChapter.New(chapterData.ActivityChapterId)
            entity:CreateAllStageData()
            self.ChapterEntityDic[chapterData.ActivityChapterId] = entity
        end
    end
    self:CreatePreStageDic()
end

function XMineSweepingGame:UpdateChapterData()
    for _,chapterData in pairs(self.MineSweepingList) do
        local entity = self.ChapterEntityDic[chapterData.ActivityChapterId]
        if entity then
            entity:UpdateData(chapterData)
        end
    end
end

function XMineSweepingGame:CreatePreStageDic()
    self.PreStageDic = {}
    local exChapterLastStage
    for _,chapterId in pairs(self:GetChapterIds() or {}) do
        local chapterEntity = self.ChapterEntityDic[chapterId]
        local stageIdList = chapterEntity and chapterEntity:GetActivityStageIds()
        for stageIndex,stageId in pairs(stageIdList or {}) do
            local stageEntity = chapterEntity:GetStageEntityById(stageId)
            if stageIndex == 1 then
                if exChapterLastStage then
                    self.PreStageDic[stageId] = exChapterLastStage
                else
                    self.PreStageDic[stageId] = {}
                end
            else
                self.PreStageDic[stageId] = chapterEntity:GetStageEntityById(stageIdList[stageIndex - 1])
            end
            exChapterLastStage = stageEntity
        end
    end
end

function XMineSweepingGame:GetActivityId()
    return (not self.ActivityId or self.ActivityId == 0) and self:GetDefaultId() or self.ActivityId
end

function XMineSweepingGame:GetMineSweepingList()
    return self.MineSweepingList
end

function XMineSweepingGame:GetChapterEntityDic()
    return self.ChapterEntityDic
end

function XMineSweepingGame:GetPreStageDic()
    return self.PreStageDic
end

function XMineSweepingGame:GetNewChapterIndex()
    local tagIndex = 0
    for index, id in pairs(self:GetChapterIds()) do
        local chapterEntity = self.ChapterEntityDic[id]
        if chapterEntity and not chapterEntity:IsLock() then
            tagIndex = index
        end
    end
    return tagIndex
end

function XMineSweepingGame:GetChapterEntityById(id)
    return self.ChapterEntityDic and self.ChapterEntityDic[id]
end

function XMineSweepingGame:GetCfg()
    return XMineSweepingConfigs.GetMineSweepingActivityById(self:GetActivityId())
end

function XMineSweepingGame:GetTimeId()
    return self:GetCfg().TimeId
end

function XMineSweepingGame:GetCoinItemId()
    return self:GetCfg().CoinItemId
end

function XMineSweepingGame:GetChapterIds()
    return self:GetCfg().ChapterIds
end

function XMineSweepingGame:GetChapterIdByIndex(index)
    return self:GetCfg().ChapterIds[index]
end

return XMineSweepingGame