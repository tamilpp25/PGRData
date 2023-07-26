local type = type
local pairs = pairs
local next = next
local ipairs = ipairs

--[[
public class NotifyShortStoryActivity
{
    public int ActivityId -- 活动Id
}
]]

local Default = {
    _ActivityId = 0, -- 活动Id
    _ActivityChapters = {}, --活动抢先体验ChapterId列表
    _EndTime = 0, --活动抢先体验结束时间
    _HideChapterBeginTime = 0, --活动抢先体验结束时间(隐藏模式)
    _ActivityTimer = nil, --定时器
    _IsActivity = {}, --活动是否结束
}
local XShortStoryActivity = XClass(nil,"XShortStoryActivity")

function XShortStoryActivity:Ctor(activityCb)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self.ActivityCallback = activityCb
end

function XShortStoryActivity:UpdateData(data)
    self._ActivityId = data.ActivityId or self._ActivityId
    if not XTool.IsNumberValid(self._ActivityId) then
        self._EndTime = 0
        self._HideChapterBeginTime = 0
        self:ShortStoryActivityEnd()
        return
    end
    
    local shortStoryActivityCfg = XFubenShortStoryChapterConfigs.GetShortStoryActivity(self._ActivityId)
    local chapterIds = shortStoryActivityCfg.ChapterId
    local chapterTimeId = shortStoryActivityCfg.ChapterTimeId
    local hideChapterTimeId = shortStoryActivityCfg.HideChapterTimeId
    
    local now = XTime.GetServerNowTimestamp()
    self._EndTime = XFunctionManager.GetEndTimeByTimeId(chapterTimeId) or self._EndTime
    self._HideChapterBeginTime = XFunctionManager.GetStartTimeByTimeId(hideChapterTimeId) or self._HideChapterBeginTime

    if now < self._EndTime then
        --清理上次活动状态
        if next(self._ActivityChapters) then
            self:ShortStoryActivityEnd()
        end
        self._ActivityChapters = { Chapters = chapterIds } or self._ActivityChapters
        self:ShortStoryActivityStart()
    else
        self:ShortStoryActivityEnd()
    end
end

--活动开始
function XShortStoryActivity:ShortStoryActivityStart()
    if not self:IsShortStoryActivityOpen() then return end
    --定时器
    if self._ActivityTimer then
        XScheduleManager.UnSchedule(self._ActivityTimer)
        self._ActivityTimer = nil
    end
    local time = XTime.GetServerNowTimestamp()
    local challengeWaitUnlock = true
    self._ActivityTimer = XScheduleManager.ScheduleForever(function()
        time = time + 1
        if time >= self._HideChapterBeginTime then
            if challengeWaitUnlock then
                self:UnlockActivityChapters()
                challengeWaitUnlock = nil
            end
        end
        if time >= self._EndTime then
            self:ShortStoryActivityEnd()
        end
    end, XScheduleManager.SECOND, 0)
    self:UnlockActivityChapters()
end

--活动关闭
function XShortStoryActivity:ShortStoryActivityEnd()
    if self._ActivityTimer then
        XScheduleManager.UnSchedule(self._ActivityTimer)
        self._ActivityTimer = nil
    end
    --活动结束处理
    local chapterIds = self._ActivityChapters.Chapters
    if chapterIds then
        for _, chapterId in pairs(chapterIds) do
            if XTool.IsNumberValid(chapterId) then
                self._IsActivity[chapterId] = false
                self:CheckStageStatus(chapterId, false)
            end
        end
    end
    
    self.ActivityCallback.UpdateStageInfo(true)
    --self:ShortStoryActivityStart()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_SHORT_STORY_CHAPTER_STATE_CHANGE)
    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA)
end

function XShortStoryActivity:UnlockActivityChapters()
    if not next(self._ActivityChapters) then return end
    for _, chapterId in pairs(self._ActivityChapters.Chapters) do
        if XTool.IsNumberValid(chapterId) then
            self:UnlockChapterViaActivity(chapterId)
        end
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_SHORT_STORY_CHAPTER_STATE_CHANGE)
end

function XShortStoryActivity:UnlockChapterViaActivity(chapterId)
    --开启章节，标识活动状态
    if not chapterId then return end
    self._IsActivity[chapterId] = true
    
    self.ActivityCallback.UpdateChapterData(chapterId)

    self:CheckStageStatus(chapterId, true)
end

function XShortStoryActivity:CheckStageStatus(chapterId, isFirstSpecial)
    local stageIds = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)

    for index, stageId in ipairs(stageIds) do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        stageInfo.Unlock = true
        stageInfo.IsOpen = true

        local isSpecial = true
        if isFirstSpecial then
            isSpecial = index ~= 1 -- 章节第一关无视前置条件
        end
        
        if isSpecial then
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
            for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                if preStageId > 0 then
                    local stageData = XDataCenter.FubenManager.GetStageData(preStageId)
                    if not stageData or not stageData.Passed then
                        stageInfo.Unlock = false
                        stageInfo.IsOpen = false
                        break
                    end
                end
            end
        end
    end
end

function XShortStoryActivity:CheckDiffHasActivity(chapterId)
    if not next(self._ActivityChapters) then return false end
    for _, Id in pairs(self._ActivityChapters.Chapters) do
        if Id == chapterId then
            return true
        end
    end
    return false
end

function XShortStoryActivity:IsShortStoryActivityOpen()
    return self._EndTime and self._EndTime > XTime.GetServerNowTimestamp()
end

function XShortStoryActivity:IsShortStoryActivityChallengeBegin()
    return self._HideChapterBeginTime and XTime.GetServerNowTimestamp() >= self._HideChapterBeginTime
end

function XShortStoryActivity:GetActivityEndTime()
    return self._EndTime
end

function XShortStoryActivity:GetActivityHideChapterBeginTime()
    return self._HideChapterBeginTime
end

function XShortStoryActivity:IsActivity(chapterId)
    return self._IsActivity[chapterId]
end

return XShortStoryActivity