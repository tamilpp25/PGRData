local XRedPointConditionReformBaseStageOpen = {}

local Pairs = pairs

function XRedPointConditionReformBaseStageOpen.GetEvents()
    if XRedPointConditionReformBaseStageOpen.Events == nil then
        XRedPointConditionReformBaseStageOpen.Events = {}
    end
    return XRedPointConditionReformBaseStageOpen.Events
end

---@param stage XReform2ndStage
--local function CheckStage(stage)
--    local star = stage:GetStarHistory()
--    local fullStar = stage:GetFullPoint()
--    local timeId = stage:GetOpenTime()
--    local isTimeOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
--
--    if isTimeOpen then
--        local preStageId = stage:GetUnlockStageId()
--
--        if preStageId == nil or preStageId == 0 then
--            if star < fullStar then
--                return true
--            end
--        else
--            ---@type XReform2ndStage
--            local preStage = XDataCenter.Reform2ndManager.GetStage(preStageId)
--
--            if preStage:GetIsPassed() and star < fullStar then
--                return true
--            end
--        end
--    end
--    
--    return false
--end

---@param chapter XReform2ndChapter
---@param preChapter XReform2ndChapter
--local function CheckChapter(chapter, preChapter)
--    local timeId = chapter:GetOpenTime()
--    local isTimeOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
--    local preIsPassed = false
--
--    if preChapter == nil then
--        preIsPassed = true
--    else
--        preIsPassed = preChapter:IsPassed()
--    end
--
--    return isTimeOpen and preIsPassed
--end

--function XRedPointConditionReformBaseStageOpen.Check(chapterData)
--    --if chapterData == nil then
--    --    local chapterConfig = XDataCenter.Reform2ndManager.GetChapterConfigs()
--    --
--    --    for id, config in Pairs(chapterConfig) do
--    --        local chapter = XDataCenter.Reform2ndManager.GetChapter(id)
--    --        local preChapterId = config.Order
--    --        local preChapter = nil
--    --
--    --        if preChapterId ~= 0 and preChapterId ~= nil then
--    --            preChapter = XDataCenter.Reform2ndManager.GetChapter(preChapterId)
--    --        end
--    --        
--    --        if not chapter:IsFinished() and CheckChapter(chapter, preChapter) then
--    --            local stageIds = chapter:GetStageIdList()
--    --            
--    --            for i = 1, #stageIds do
--    --                local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[i])
--    --
--    --                if CheckStage(stage) and XDataCenter.Reform2ndManager.GetChapterRedPointFromLocal(id) then
--    --                    return true
--    --                end
--    --            end
--    --        end
--    --    end
--    --    
--    --    return false
--    --end
--    --
--    -----@type XReform2ndChapter
--    --local chapter = chapterData.Chapter
--    --local stageIds = chapter:GetStageIdList()
--    --local preChapter = chapterData.PreChapter
--    --
--    --if chapter:IsFinished() then
--    --    return false
--    --end
--    --
--    --if not CheckChapter(chapter, preChapter) then
--    --    return false
--    --end
--    --
--    --for i = 1, #stageIds do
--    --    local stage = XDataCenter.Reform2ndManager.GetStage(stageIds[i])
--    --
--    --    if CheckStage(stage) then
--    --        return XDataCenter.Reform2ndManager.GetChapterRedPointFromLocal(chapter:GetId())
--    --    end
--    --end
--    --
--    return false
--end

function XRedPointConditionReformBaseStageOpen.Check(chapter)
    return XMVCA.XReform:CheckChapterRed(chapter)
end

return XRedPointConditionReformBaseStageOpen