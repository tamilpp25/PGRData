local XNieRChapter = XClass(nil, "XNieRChapter")

function XNieRChapter:Ctor(id, index)
    self.Id = id
    self.Index = index
    self.ChapterCfg = XNieRConfigs.GetChapterConfigById(id)
end

function XNieRChapter:SetLastBossAtk(lastBossAtk)
    self.LastBossAtk = lastBossAtk
end

function XNieRChapter:GetLastBossAtk()
    return self.LastBossAtk
end

function XNieRChapter:CheckNieRChapterUnLock()
    local chapterStartTime = self:GetNierChapterStartTime()
    local chapterEndTime = self:GetNierChapterEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    local isUnLock, desc = true, ""
    if self.ChapterCfg.Condition ~= 0 then
        isUnLock, desc = XConditionManager.CheckCondition(self.ChapterCfg.Condition)
    end
    if isUnLock then
        if chapterStartTime ~= 0 then
            if nowTime >= chapterStartTime and nowTime <= chapterEndTime then   
                desc = CS.XTextManager.GetText("NieRActivityChapterLock", os.date("%Y/%m/%d", chapterStartTime))

            elseif nowTime < chapterStartTime then
                isUnLock = false
                desc = CS.XTextManager.GetText("NieRActivityChapterLock", os.date("%Y/%m/%d", chapterStartTime))
            elseif nowTime > chapterEndTime then
                isUnLock = false
                desc = CS.XTextManager.GetText("NieRActivityChapterEnd")
            end
        end
    end
    return isUnLock, desc
end

function XNieRChapter:GetChapterId()
    return self.Id
end

function XNieRChapter:GetIndex()
    return self.Index
end

function XNieRChapter:GetNierChapterCfg()
    return self.ChapterCfg
end

function XNieRChapter:GetNierChapterStageIds()
    return self.ChapterCfg.StageIds
end

function XNieRChapter:GetNieRBossStageId()
    return self.ChapterCfg.BossStageId
end

function XNieRChapter:GetNierChapterRobotIds()
    return self.ChapterCfg.RobotIds
end

function XNieRChapter:GetNierChapterStartTime()
    if not self.ChapterCfg then return 0 end
    return self.ChapterCfg.TimeId ~= 0 and XFunctionManager.GetStartTimeByTimeId(self.ChapterCfg.TimeId) or 0
end

function XNieRChapter:GetNierChapterEndTime()
    if not self.ChapterCfg then return 0 end
    return self.ChapterCfg.TimeId ~= 0 and XFunctionManager.GetEndTimeByTimeId(self.ChapterCfg.TimeId) or 0
end

function XNieRChapter:GetNieRChapterName()
    return self.ChapterCfg.Title
end

function XNieRChapter:GetNieRChapterIcon()
    return self.ChapterCfg.Icon
end

function XNieRChapter:GetNieRChapterTaskSkipId()
    return self.ChapterCfg.TaskSkipId
end

function XNieRChapter:GetNieRRepeatPoStagePos()
    return self.ChapterCfg.RepeatPoStagePos
end

function XNieRChapter:GetNieRRepeatPoStageId()
    local pos = self.ChapterCfg.RepeatPoStagePos
    local stageIds = self.ChapterCfg.StageIds
    return stageIds[pos]
end


function XNieRChapter:GetNieRRepeatPoStageLabel()
    return self.ChapterCfg.RepeatPoStageLabel
end


function XNieRChapter:GetNieRChapterPhaseStr()
    if XDataCenter.FubenManager.CheckStageIsUnlock(self:GetNieRBossStageId()) then
        return CS.XTextManager.GetText("NieRChapterPhaseStr", 2)
    else
        return CS.XTextManager.GetText("NieRChapterPhaseStr", 1)
    end
end

return XNieRChapter