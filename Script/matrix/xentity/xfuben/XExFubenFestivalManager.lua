local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")
local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
local XExFubenFestivalManager = XClass(XExFubenBaseManager, "XExFubenFestivalManager")

-- 检查是否展示红点
function XExFubenFestivalManager:ExCheckIsShowRedPoint(uiType)
    for _, viewModel in ipairs(self:ExGetChapterViewModels(uiType)) do
        if viewModel:CheckHasRedPoint() then
            return true
        end
    end
    return false
end

function XExFubenFestivalManager:ExOpenChapterUi(viewModel)
    local chapterTemplate = XFestivalActivityConfig.GetFestivalById(viewModel:GetId())
    if chapterTemplate.FunctionOpenId and (not XFunctionManager.DetectionFunction(chapterTemplate.FunctionOpenId)) then
        return
    end
    -- 兼容特殊跳转
    if chapterTemplate.UiType == XFestivalActivityConfig.UiType.Activity and not XTool.IsTableEmpty(chapterTemplate.SkipId) then
        XFunctionManager.SkipInterface(chapterTemplate.SkipId[1])
        return
    end
    XLuaUiManager.Open("UiFubenChristmasMainLineChapter", viewModel:GetId())
end

function XExFubenFestivalManager:ExGetFunctionNameType()
    return XFunctionManager.FunctionName.FestivalActivity
end

local function SortModels(models)
    local activityTimeList = {}
    local normalList = {}
    for k, v in pairs(models) do
        if v:CheckHasNewTag() then
            table.insert(activityTimeList, v)
        else
            table.insert(normalList, v)
        end
    end

    table.sort(activityTimeList, function(a, b)
        return a:GetConfig().ChapterCofig.Priority < b:GetConfig().ChapterCofig.Priority
    end)
    table.sort(normalList, function(a, b)
        return a:GetConfig().ChapterCofig.Priority < b:GetConfig().ChapterCofig.Priority
    end)
  
    return appendArray(activityTimeList, normalList)
end

function XExFubenFestivalManager:ExGetCurrentChapterIndex()
    local viewModels = self:ExGetChapterViewModels(1)
    for i, viewModel in ipairs(viewModels) do
        local currPrg, totalPrg = viewModel:GetCurrentAndMaxProgress()
        local isPass = currPrg >= totalPrg

        if viewModel:CheckHasNewTag() and not viewModel:GetIsLocked() and not isPass then
            return i
        end
        
        if not isPass and not viewModel:GetIsLocked() then
            return i
        end
    end
 
    return 1
end

function XExFubenFestivalManager:ExGetChapterViewModels(uiType)
    if uiType == nil then return {} end
    if self.__ChapterViewModelDic == nil then self.__ChapterViewModelDic = {} end
    self.__ChapterViewModelDic[uiType] = {}
    local chapters = XDataCenter.FubenFestivalActivityManager.GetFestivalsByUiType(uiType)
    for _, chapter in ipairs(chapters) do
        local isInTime = chapter:GetIsInTime()
        if not isInTime then
            goto continue
        end

        table.insert(self.__ChapterViewModelDic[uiType], CreateAnonClassInstance({
            GetProgressTips = function(proxy)
                local finishCount, totalCount = XDataCenter.FubenFestivalActivityManager.GetFestivalProgress(proxy:GetId())
                if proxy:GetExtralData() == XFestivalActivityConfig.UiType.Activity then
                    return XUiHelper.GetText("ActivityBossSingleProcess", finishCount, totalCount)                
                elseif proxy:GetExtralData() == XFestivalActivityConfig.UiType.ExtralLine then
                    return string.format("%s%%", math.floor((finishCount / totalCount) * 100))
                end
            end,
            GetCurrentAndMaxProgress = function(proxy)
                local finishCount, totalCount = XDataCenter.FubenFestivalActivityManager.GetFestivalProgress(proxy:GetId())
                return finishCount, totalCount
            end,
            GetTimeTips = function(proxy)
                local _, endTimeSecond = XFestivalActivityConfig.GetFestivalTime(proxy:GetId())
                return string.format("%s%s", XUiHelper.GetText("ActivityBranchFightLeftTime")
                    , XUiHelper.GetTime(endTimeSecond - XTime.GetServerNowTimestamp(), XUiHelper.TimeFormatType.ACTIVITY))
            end,
            GetIsLocked = function(proxy)
                local chapterCofig = XFestivalActivityConfig.GetFestivalById(proxy:GetId())
                if chapterCofig.FunctionOpenId <= 0 then return false end
                return not XFunctionManager.JudgeCanOpen(chapterCofig.FunctionOpenId)
            end,
            GetLockTip = function(proxy)
                local chapterCofig = XFestivalActivityConfig.GetFestivalById(proxy:GetId())
                return XFunctionManager.GetFunctionOpenCondition(chapterCofig.FunctionOpenId)
            end,
            CheckHasRedPoint = function(proxy)
                return XRedPointConditionActivityFestival.Check(proxy:GetId()) and proxy:CheckHasNewTag()
            end,
            CheckIsOpened = function(proxy)
                return chapter:GetIsOpen()
            end,
            CheckIsPassed = function(proxy)
                return chapter:GetChapterIsPassed()
            end,
            CheckHasNewTag = function(proxy)
                local limitTimeId = chapter:GetActivityTimeId()
                return XFunctionManager.CheckInTimeByTimeId(limitTimeId)
            end,
        }, XChapterViewModel
        , {
            Id = chapter:GetChapterId(),
            ExtralName = nil,
            Name = chapter:GetName(),
            Icon = chapter:GetBannerBg(),
            ExtralData = uiType,
            ChapterCofig = XFestivalActivityConfig.GetFestivalById(chapter:GetChapterId())
        }))

        ::continue::
    end
    self.__ChapterViewModelDic[uiType] = SortModels(self.__ChapterViewModelDic[uiType])
    return self.__ChapterViewModelDic[uiType]
end

return XExFubenFestivalManager