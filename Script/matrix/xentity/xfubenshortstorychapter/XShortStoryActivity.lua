local type = type
local pairs = pairs

--[[
public class NotifyShortStoryActivity
{
    public int ActivityId -- 活动Id
}
]]

local Default = {
    _ActivityId = 0,           -- 活动Id
    _ActivityChapters = {},    --活动抢先体验ChapterId列表
    _EndTime = 0,              --活动抢先体验结束时间
    _HideChapterBeginTime = 0, --活动抢先体验结束时间(隐藏模式)
    _ActivityTimer = nil,      --定时器
    _IsActivity = {},          --活动是否结束
}
---@class XShortStoryActivity
---@field _ActivityId number 活动Id
---@field _ActivityChapters table<number, number> 活动抢先体验ChapterId列表
---@field _EndTime number 活动抢先体验结束时间
---@field _HideChapterBeginTime number 活动抢先体验结束时间(隐藏模式)
---@field _ActivityTimer number 定时器
---@field _IsActivity table<number, boolean> 活动是否结束
local XShortStoryActivity = XClass(nil, "XShortStoryActivity")

function XShortStoryActivity:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
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
        if not XTool.IsTableEmpty(self._ActivityChapters) then
            self:ShortStoryActivityEnd()
        end
        self._ActivityChapters = chapterIds or {}
        self:ShortStoryActivityStart()
    else
        self:ShortStoryActivityEnd()
    end
end

--活动开始
function XShortStoryActivity:ShortStoryActivityStart()
    if not self:IsShortStoryActivityOpen() then
        return
    end
    self:StopActivityTimer()
    local challengeWaitUnlock = true
    self._ActivityTimer = XScheduleManager.ScheduleForeverEx(function()
        local nowTime = XTime.GetServerNowTimestamp()
        if nowTime >= self._HideChapterBeginTime then
            if challengeWaitUnlock then
                self:UnlockActivityChapters()
                challengeWaitUnlock = nil
            end
        end
        if nowTime >= self._EndTime then
            self:ShortStoryActivityEnd()
        end
    end, XScheduleManager.SECOND)
    self:UnlockActivityChapters()
end

--活动关闭
function XShortStoryActivity:ShortStoryActivityEnd()
    self:StopActivityTimer()
    --活动结束处理
    if not XTool.IsTableEmpty(self._ActivityChapters) then
        for _, chapterId in pairs(self._ActivityChapters) do
            if XTool.IsNumberValid(chapterId) then
                self._IsActivity[chapterId] = false
                XDataCenter.ShortStoryChapterManager.CheckStageStatus(chapterId, false)
            end
        end
    end
    XDataCenter.ShortStoryChapterManager.RefreshChapterData()
end

function XShortStoryActivity:UnlockActivityChapters()
    if XTool.IsTableEmpty(self._ActivityChapters) then
        return
    end
    for _, chapterId in pairs(self._ActivityChapters) do
        if XTool.IsNumberValid(chapterId) then
            self:UnlockChapterViaActivity(chapterId)
        end
    end
end

function XShortStoryActivity:UnlockChapterViaActivity(chapterId)
    --开启章节，标识活动状态
    if not XTool.IsNumberValid(chapterId) then
        return
    end
    self._IsActivity[chapterId] = true
    XDataCenter.ShortStoryChapterManager.ChangeChapterUnlock(chapterId)
    XDataCenter.ShortStoryChapterManager.CheckStageStatus(chapterId, true)
end

function XShortStoryActivity:CheckDiffHasActivity(chapterId)
    if XTool.IsTableEmpty(self._ActivityChapters) then
        return false
    end
    for _, id in pairs(self._ActivityChapters) do
        if id == chapterId then
            return true
        end
    end
    return false
end

function XShortStoryActivity:StopActivityTimer()
    if self._ActivityTimer then
        XScheduleManager.UnSchedule(self._ActivityTimer)
        self._ActivityTimer = nil
    end
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