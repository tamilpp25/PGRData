local type = type
local pairs = pairs
local next = next
local ipairs = ipairs

--[[
public class NotifyShortStoryActivity
{
    public List<int> Chapters = new List<int>();
    public long EndTime;
    public long HideChapterBeginTime;
}
]]

local Default = {
    _ActivityChapters = {}, --活动抢先体验ChapterId列表
    _EndTime = 0, --活动抢先体验结束时间
    _HideChapterBeginTime = 0, --活动抢先体验结束时间(隐藏模式)
    _ActivityTimer = nil, --定时器
}
local IsActivity = {} --活动是否结束
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
    local now = XTime.GetServerNowTimestamp()
    self._EndTime = data.EndTime or self._EndTime
    self._HideChapterBeginTime = data.HideChapterBeginTime or self._HideChapterBeginTime

    if now < self._EndTime then
        --清理上次活动状态
        if next(self._ActivityChapters) then
            self:ShortStoryActivityEnd()
        end
        self._ActivityChapters = { Chapters = data.Chapters } or self._ActivityChapters
        self:ShortStoryActivityStart()
    end
    self:ShortStoryActivityEnd()
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
                IsActivity[chapterId] = false
            end
        end
    end
    
    self.ActivityCallback.UpdateStageInfo(true)
    self:ShortStoryActivityStart()
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
    IsActivity[chapterId] = true
    
    self.ActivityCallback.UpdateChapterData(chapterId)

    local stageIds = XFubenShortStoryChapterConfigs.GetStageIdByChapterId(chapterId)
    for index, stageId in ipairs(stageIds) do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        stageInfo.Unlock = true
        stageInfo.IsOpen = true
        --章节第一关无视前置条件
        if index ~= 1 then
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
            --其余关卡只检测前置条件组
            for _, prestageId in pairs(stageCfg.PreStageId or {}) do
                if prestageId > 0 then
                    local stageData = XDataCenter.FubenManager.GetStageData(prestageId)
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
    return IsActivity[chapterId]
end

return XShortStoryActivity