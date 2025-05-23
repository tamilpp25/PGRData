local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")
local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
-- 浮点纪实
local XExFubenShortStoryManager = XClass(XExFubenBaseManager, "XExFubenShortStoryManager")

function XExFubenShortStoryManager:ExOpenChapterUi(viewModel)
    if viewModel.OnOpenChapterUi then
        viewModel:OnOpenChapterUi()
        return
    end

    local chapterId = viewModel:GetId()
    local isUnlock = XDataCenter.ShortStoryChapterManager.IsUnlock(chapterId)
    local isActivity = XDataCenter.ShortStoryChapterManager.IsActivity(chapterId)
    local firstStage = XDataCenter.ShortStoryChapterManager.GetFirstStageByChapterId(chapterId)
    local chapterMainId = XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(chapterId)
    local hideDiffTog = XDataCenter.ShortStoryChapterManager.IsHaveHardDifficult(chapterMainId)
    if isUnlock then
        XLuaUiManager.Open("UiFubenMainLineChapterDP", chapterId, nil, not hideDiffTog)
    elseif isActivity then
        local ret, desc = XDataCenter.ShortStoryChapterManager.CheckActivityCondition(chapterId)
        if not ret then
            XUiManager.TipError(desc)
        end
    else
        local ret, desc = XDataCenter.ShortStoryChapterManager.CheckOpenCondition(chapterId)
        if not ret then
            XUiManager.TipError(desc)
            return
        end
        local tipMsg = XMVCA.XFuben:GetFubenOpenTips(firstStage)
        XUiManager.TipMsg(tipMsg)
    end
end

function XExFubenShortStoryManager:ExGetFunctionNameType()
    return XFunctionManager.FunctionName.ShortStory
end

-- 检查是否展示红点
function XExFubenShortStoryManager:ExCheckIsShowRedPoint()
    for _, viewModel in ipairs(self:ExGetChapterViewModels(XMVCA.XFuben.DifficultNormal)) do
        if viewModel:CheckHasRedPoint() then
            return true
        end
    end
    for _, viewModel in ipairs(self:ExGetChapterViewModels(XMVCA.XFuben.DifficultHard)) do
        if viewModel:CheckHasRedPoint() then
            return true
        end
    end
    return false
end

-- 检查是否有限时开放标志
function XExFubenShortStoryManager:ExCheckHasTimeLimitTag()
    for _, viewModel in ipairs(self:ExGetChapterViewModels(XMVCA.XFuben.DifficultNormal)) do
        if viewModel:CheckHasTimeLimitTag() then
            return true
        end
    end
    for _, viewModel in ipairs(self:ExGetChapterViewModels(XMVCA.XFuben.DifficultHard)) do
        if viewModel:CheckHasTimeLimitTag() then
            return true
        end
    end
    return false
end

function XExFubenShortStoryManager:ExGetChapterViewModels(difficulty)
    if difficulty == nil then difficulty = XMVCA.XFuben.DifficultNormal end
    if self.__ChapterViewModelDic == nil then self.__ChapterViewModelDic = {} end
    if self.__ChapterViewModelDic[difficulty] then return self.__ChapterViewModelDic[difficulty] end
    self.__ChapterViewModelDic[difficulty] = {}
    local chapterIds = self:ExGetChapterIds(difficulty)
    for _, id in ipairs(chapterIds) do
        local viewModel = self:ExGetChapterViewModelById(id, difficulty)
        table.insert(self.__ChapterViewModelDic[difficulty], viewModel)
    end

    -- 2.11新浮点纪实章节
    local storyType = XEnumConst.MAINLINE2.STORY_TYPE.SHORT_STORY
    local groupId = XEnumConst.MAINLINE2.SHORT_STORY_GROUP_ID
    local mainLine2Agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    local mainCfgs = mainLine2Agency:GetMainCfgsByStoryTypeGroupId(storyType, groupId)
    if mainCfgs and #mainCfgs > 0 then
        table.sort(mainCfgs, function(a, b) return a.OrderId < b.OrderId end)
        for _, config in ipairs(mainCfgs) do
            local viewModel = mainLine2Agency:GetMain(config.Id)
            table.insert(self.__ChapterViewModelDic[difficulty], viewModel)
        end
    end

    return self.__ChapterViewModelDic[difficulty]
end

function XExFubenShortStoryManager:ExCheckHasOtherDifficulty()
    return true
end

-- 注意：这是旧的接口，2.11后新做的不适用，请使用ExGetChapterViewModelById
function XExFubenShortStoryManager:GetChapterViewModel(id, difficulty)
    local chapterMainId = XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(id)
    local subChapterId = XFubenShortStoryChapterConfigs.GetChapterIdByIdAndDifficult(chapterMainId, difficulty)
    if self.__ChapterViewModelIdDic == nil then self.__ChapterViewModelIdDic = {} end
    if self.__ChapterViewModelIdDic[subChapterId] then return self.__ChapterViewModelIdDic[subChapterId] end
    local result = nil
    if subChapterId ~= nil and subChapterId > 0 then
        result = CreateAnonClassInstance({
            GetCurrentAndMaxProgress = function(proxy)
                local normalCurStars, normalTotalStars = XDataCenter.ShortStoryChapterManager.GetChapterStars(proxy:GetId())
                -- 再加上剧情进度计算:1个剧情关算1颗星
                local styPassCount, styTotal = XDataCenter.FubenManagerEx.GetStoryStagePassCount(XFubenShortStoryChapterConfigs.GetStageIdByChapterId(proxy:GetId()))
                normalCurStars = normalCurStars + styPassCount
                normalTotalStars = normalTotalStars + styTotal
                -- 如果有隐藏模式 要把隐藏模式的进度一起算上
                local hideId = XFubenShortStoryChapterConfigs.GetChapterIdByIdAndDifficult(chapterMainId, XMVCA.XFuben.DifficultHard)
                if hideId then
                    local styPassCount2, styTotal2 = XDataCenter.FubenManagerEx.GetStoryStagePassCount(XFubenShortStoryChapterConfigs.GetStageIdByChapterId(hideId))
                    normalCurStars = normalCurStars + styPassCount2
                    normalTotalStars = normalTotalStars + styTotal2
                    local hideCurStars, hideTotalStars = XDataCenter.ShortStoryChapterManager.GetChapterStars(hideId)
                    normalCurStars = normalCurStars + hideCurStars
                    normalTotalStars = normalTotalStars + hideTotalStars
                end
                return normalCurStars, normalTotalStars
            end,
            CheckHasRedPoint = function(proxy)
                return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_SHORT_STORY_CHAPTER_REWARD, proxy:GetId())
            end,
            CheckHasNewTag = function(proxy)
                return XDataCenter.ShortStoryChapterManager.CheckChapterNew(proxy:GetId())
            end,
            CheckHasTimeLimitTag = function(proxy)
                return XDataCenter.ShortStoryChapterManager.IsActivity(proxy:GetId()) or false
            end,
            GetWeeklyChallengeCount = function(proxy)
                local zhouMuId = XFubenShortStoryChapterConfigs.GetZhouMuId(chapterMainId)
                return XDataCenter.FubenZhouMuManager.GetZhouMuNumber(zhouMuId)
            end,
            GetIsLocked = function(proxy)
                local result = not XDataCenter.ShortStoryChapterManager.IsUnlock(proxy:GetId())    
                local isActivity = proxy:CheckHasTimeLimitTag()
                -- 如果锁定并且是活动，判断下一层
                if result and isActivity then
                    return not XDataCenter.ShortStoryChapterManager.CheckActivityCondition(proxy:GetId())
                end
                return result
            end,
            GetLockTip = function(proxy)
                local isActivity = proxy:CheckHasTimeLimitTag()
                if not isActivity then 
                    local ret, desc = XDataCenter.ShortStoryChapterManager.CheckOpenCondition(proxy:GetId())
                    if not ret then
                        return desc
                    end
                    local firstStage = XDataCenter.ShortStoryChapterManager.GetFirstStageByChapterId(proxy:GetId())
                    local tipMsg = XMVCA.XFuben:GetFubenOpenTips(firstStage)
                    return tipMsg
                end
                local _, desc = XDataCenter.ShortStoryChapterManager.CheckActivityCondition(proxy:GetId())
                return desc
            end,
            CheckIsPassed = function(proxy)
                return XDataCenter.ShortStoryChapterManager.CheckChapterIsPassed(proxy:GetId())
            end,
            GetDifficulty = function(proxy)
                return difficulty
            end,
            GetNormalChapterNextStageOrderId = function(proxy)
                local chapterInfo = XDataCenter.ExtraChapterManager.GetChapterInfo(proxy:GetId())
                local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(chapterInfo.ActiveStage)
                return stageCfg.OrderId
            end,
        }, XChapterViewModel
        , {
            Id = subChapterId,
            ExtralName = XFubenShortStoryChapterConfigs.GetStageTitleByChapterId(subChapterId),
            Name = XFubenShortStoryChapterConfigs.GetChapterEnById(chapterMainId),
            Icon = XFubenShortStoryChapterConfigs.GetIconById(chapterMainId),
            FirstStage = XDataCenter.ShortStoryChapterManager.GetFirstStageByChapterId(subChapterId),
            ActivityCondition = XFubenShortStoryChapterConfigs.GetActivityConditionByChapterId(subChapterId)
        })
        self.__ChapterViewModelIdDic[subChapterId] = result
    end
    return result
end

-- ##################################### 私有方法 ########################################

-- 获取章节Id配置
-- difficulty : XDataCenter.FubenManager.DifficultNormal or XDataCenter.FubenManager.DifficultHard
function XExFubenShortStoryManager:ExGetChapterIds(difficulty)
    if difficulty == nil then 
        return appendArray(self:ExGetChapterIds(XMVCA.XFuben.DifficultNormal)
            , self:ExGetChapterIds(XMVCA.XFuben.DifficultHard))
    end
    local result = {}
    local chapterSimpleConfigs = XDataCenter.ShortStoryChapterManager.GetShortStoryChapterCfg(difficulty)
    for _, config in ipairs(chapterSimpleConfigs) do
        table.insert(result, config.ChapterId)
    end
    return result
end

-- 获取章节的ViewModel
function XExFubenShortStoryManager:ExGetChapterViewModelById(chapterId, difficulty)
    -- v2.11新主线
    if XMVCA:GetAgency(ModuleId.XMainLine2):IsMainExit(chapterId) then
        return
    end

    local chapterMainId = XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(chapterId)
    return self:GetChapterViewModel(chapterId, difficulty)
end

return XExFubenShortStoryManager