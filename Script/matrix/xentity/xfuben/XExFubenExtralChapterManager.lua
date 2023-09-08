local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")
local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
-- 外篇旧闻
local XExFubenExtralChapterManager = XClass(XExFubenBaseManager, "XExFubenExtralChapterManager")

function XExFubenExtralChapterManager:ExOpenChapterUi(viewModel, difficulty)
    if difficulty == nil then difficulty = XDataCenter.FubenManager.DifficultNormal end
    local chapterId = viewModel:GetId()
    local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfo(chapterId)
    local chapterCfg = XDataCenter.ExtraChapterManager.GetChapterDetailsCfgByChapterIdAndDifficult(chapterInfo.ChapterMainId, difficulty)
    if chapterInfo.Unlock then
        XLuaUiManager.Open("UiFubenMainLineChapterFw", chapterCfg, nil, false)
    elseif chapterInfo.IsActivity then
        local ret, desc = XDataCenter.ExtraChapterManager.CheckActivityCondition(chapterId)
        if not ret then
            XUiManager.TipError(desc)
        end
    else
        local ret, desc = XDataCenter.ExtraChapterManager.CheckOpenCondition(chapterId)
        if not ret then
            XUiManager.TipError(desc)
            return
        end
        local tipMsg = XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage)
        XUiManager.TipMsg(tipMsg)
    end
end

function XExFubenExtralChapterManager:ExGetFunctionNameType()
    return XFunctionManager.FunctionName.Extra
end

-- 检查是否展示红点
function XExFubenExtralChapterManager:ExCheckIsShowRedPoint()
    for _, viewModel in ipairs(self:ExGetChapterViewModels(XDataCenter.FubenManager.DifficultNormal)) do
        if viewModel:CheckHasRedPoint() then
            return true
        end
    end
    for _, viewModel in ipairs(self:ExGetChapterViewModels(XDataCenter.FubenManager.DifficultHard)) do
        if viewModel:CheckHasRedPoint() then
            return true
        end
    end
    return false
end

-- Id为该值的Chapter 不进行任何隐藏关的计算（策划说的，这个是以前遗留的留空问题
function XExFubenExtralChapterManager:ExGetSpecialHideChapterId()
    return 2000
end

-- 检查是否有限时开放标志
function XExFubenExtralChapterManager:ExCheckHasTimeLimitTag()
    for _, viewModel in ipairs(self:ExGetChapterViewModels(XDataCenter.FubenManager.DifficultNormal)) do
        if viewModel:CheckHasTimeLimitTag() then
            return true
        end
    end
    for _, viewModel in ipairs(self:ExGetChapterViewModels(XDataCenter.FubenManager.DifficultHard)) do
        if viewModel:CheckHasTimeLimitTag() then
            return true
        end
    end
    return false
end

function XExFubenExtralChapterManager:ExGetChapterViewModels(difficulty)
    if difficulty == nil then difficulty = XDataCenter.FubenManager.DifficultNormal end
    if self.__ChapterViewModelDic == nil then self.__ChapterViewModelDic = {} end
    if self.__ChapterViewModelDic[difficulty] then return self.__ChapterViewModelDic[difficulty] end
    self.__ChapterViewModelDic[difficulty] = {}
    local chapterConfigs = XDataCenter.ExtraChapterManager.GetChapterExtraCfgs(difficulty)
    for _, config in ipairs(chapterConfigs) do
        local id = config.ChapterId[difficulty]
        table.insert(self.__ChapterViewModelDic[difficulty], self:ExGetChapterViewModelById(id, difficulty))
    end
    return self.__ChapterViewModelDic[difficulty]
end

function XExFubenExtralChapterManager:ExGetChapterViewModelById(id, difficulty)
    local chapterMainId = XFubenExtraChapterConfigs.GetChapterMainIdByChapterId(id)
    local config = XDataCenter.ExtraChapterManager.GetChapterCfg(chapterMainId)
    local subChapterId = config.ChapterId[difficulty]
    if self.__ChapterViewModelIdDic == nil then self.__ChapterViewModelIdDic = {} end
    if self.__ChapterViewModelIdDic[subChapterId] then return self.__ChapterViewModelIdDic[subChapterId] end
    local result = nil
    if subChapterId ~= nil and subChapterId > 0 then
        result = CreateAnonClassInstance({
            GetCurrentAndMaxProgress = function(proxy)
                local normalCurStars, normalTotalStars = XDataCenter.ExtraChapterManager.GetChapterStars(proxy:GetId())
                -- 再加上剧情进度计算:1个剧情关算1颗星
                local styPassCount, styTotal = XDataCenter.FubenManagerEx.GetStoryStagePassCount(XDataCenter.ExtraChapterManager.GetStageList(proxy:GetId()))
                normalCurStars = normalCurStars + styPassCount
                normalTotalStars = normalTotalStars + styTotal
                -- 如果有隐藏模式 要把隐藏模式的进度一起算上
                local hideId = config.ChapterId[XDataCenter.FubenManager.DifficultHard]
                if hideId and proxy:GetId() ~= self:ExGetSpecialHideChapterId() then
                    local styPassCount2, styTotal2 = XDataCenter.FubenManagerEx.GetStoryStagePassCount(XDataCenter.ExtraChapterManager.GetStageList(hideId))
                    normalCurStars = normalCurStars + styPassCount2
                    normalTotalStars = normalTotalStars + styTotal2
                    local hideCurStars, hideTotalStars = XDataCenter.ExtraChapterManager.GetCurrentAndMaxProgressByChapterId(hideId)
                    normalCurStars = normalCurStars + hideCurStars
                    normalTotalStars = normalTotalStars + hideTotalStars
                end
                return normalCurStars, normalTotalStars
            end,
            CheckHasRedPoint = function(proxy)
                return XRedPointConditionExtraChapterReward.Check(proxy:GetId())
            end,
            CheckHasNewTag = function(proxy)
                return XDataCenter.ExtraChapterManager.CheckChapterNew(proxy:GetId())
            end,
            CheckHasTimeLimitTag = function(proxy)
                local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfo(proxy:GetId())
                return chapterInfo and chapterInfo.IsActivity
            end,
            GetWeeklyChallengeCount = function(proxy)
                return XDataCenter.FubenZhouMuManager.GetZhouMuNumber(config.ZhouMuId)
            end,
            GetIsLocked = function(proxy)
                local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfo(proxy:GetId())
                if chapterInfo.Unlock then return false end
                if chapterInfo.IsActivity then
                    local isUnLock, _ = XDataCenter.ExtraChapterManager.CheckActivityCondition(proxy:GetId())
                    if isUnLock then
                        XDataCenter.ExtraChapterManager.UnlockChapterViaActivity(proxy:GetId())
                    end
                    return not isUnLock
                else
                    return true
                end
            end,
            GetLockTip = function(proxy)
                local isActivity = proxy:CheckHasTimeLimitTag()
                if isActivity then
                    local ret, desc = XDataCenter.ExtraChapterManager.CheckActivityCondition(proxy:GetId())
                    if not ret then
                        return desc
                    end
                else
                    local ret, desc = XDataCenter.ExtraChapterManager.CheckOpenCondition(proxy:GetId())
                    if not ret then
                        return desc
                    end
                    local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfo(proxy:GetId())
                    local tipMsg = XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage)
                    return tipMsg
                end
            end,
            GetDifficulty = function(proxy)
                return difficulty
            end
        }, XChapterViewModel
        , {
            Id = subChapterId,
            ExtralName = XDataCenter.ExtraChapterManager.GetChapterDetailsStageTitle(subChapterId),
            Name = config.ChapterEn,
            Icon = config.Icon,
            FirstStage = XDataCenter.ExtraChapterManager.GetChapterInfo(subChapterId).FirstStage,
            ActivityCondition = XDataCenter.ExtraChapterManager.GetChapterDetailsCfg(subChapterId).ActivityCondition
        })
    end
    self.__ChapterViewModelIdDic[subChapterId] = result
    return result
end

function XExFubenExtralChapterManager:ExCheckHasOtherDifficulty()
    return true
end

return XExFubenExtralChapterManager