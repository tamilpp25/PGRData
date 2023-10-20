local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")
local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
local XExFubenMainLineManager = XClass(XExFubenBaseManager, "XExFubenMainLineManager")

function XExFubenMainLineManager:ExOpenChapterUi(viewModel, difficulty)
    if difficulty == nil then difficulty = XDataCenter.FubenManager.DifficultNormal end
    -- 已解锁
    local extralData = viewModel:GetExtralData()
    local chapterMainId = extralData.MainId
    local chapterConfig = XDataCenter.FubenMainLineManager.GetChapterCfgByChapterMain(chapterMainId, difficulty)
    if not viewModel:GetIsLocked() then
        if chapterMainId == XDataCenter.FubenMainLineManager.TRPGChapterId then
            XDataCenter.TRPGManager.PlayStartStory()
        elseif chapterMainId == XDataCenter.FubenMainLineManager.MainLine3DId then
            XLuaUiManager.Open("UiFubenMainLine3D")
        else
            XLuaUiManager.Open("UiFubenMainLineChapter", chapterConfig)
        end
        -- self:ExSetCurrentGroupIndexAndChapterIndex(extralData.GroupId, extralData.Index)
    elseif viewModel:CheckHasTimeLimitTag() then
        local ret, desc = XDataCenter.FubenMainLineManager.CheckActivityCondition(viewModel:GetId())
        if not ret then
            XUiManager.TipError(desc)
        end
    else
        if difficulty == XDataCenter.FubenManager.DifficultNightmare then
            XUiManager.TipMsg(CS.XTextManager.GetText("BfrtChapterUnlockCondition"))
        elseif chapterMainId == XDataCenter.FubenMainLineManager.TRPGChapterId then
            XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MainLineTRPG)
        else
            local isOpen, desc = XDataCenter.FubenMainLineManager.CheckOpenCondition(viewModel:GetId())
            if not isOpen then
                XUiManager.TipMsg(desc)
                return
            end
            local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoByChapterMain(chapterMainId, difficulty)
            local tipMsg = XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage)
            XUiManager.TipMsg(tipMsg)
        end
    end
end

function XExFubenMainLineManager:ExGetChapterViewModels(groupId, difficulty)
    if difficulty == nil then
        local result = {}
        result = appendArray(result, self:ExGetChapterViewModels(groupId, XDataCenter.FubenManager.DifficultNormal))
        result = appendArray(result, self:ExGetChapterViewModels(groupId, XDataCenter.FubenManager.DifficultHard))
        return result
    end
    if self.__ChapterViewModelDic == nil then self.__ChapterViewModelDic = {} end
    if self.__ChapterViewModelDic[groupId] == nil then self.__ChapterViewModelDic[groupId] = {} end
    if self.__ChapterViewModelDic[groupId][difficulty] then return self.__ChapterViewModelDic[groupId][difficulty] end
    self.__ChapterViewModelDic[groupId][difficulty] = {}
    for i, config in ipairs(self:ExGetChapterConfigs(groupId, difficulty)) do
        local subChapterId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(config.Id, difficulty)
        if subChapterId ~= nil and subChapterId > 0 then
            -- 提审服屏蔽第一章以外的
            if XUiManager.IsHideFunc then
                if config.Id == 1001 then -- 第一章id
                    table.insert(self.__ChapterViewModelDic[groupId][difficulty], self:ExGetChapterViewModelById(config.Id, difficulty, i))
                end
            else
                table.insert(self.__ChapterViewModelDic[groupId][difficulty], self:ExGetChapterViewModelById(config.Id, difficulty, i))    
            end
        end
    end
    return self.__ChapterViewModelDic[groupId][difficulty]
end

-- 获取主线章节配置数据, 服务器数据走XDataCenter.FubenMainLineManager.GetChapterInfoByChapterMain
-- difficulty : XDataCenter.FubenManager.DifficultNormal or XDataCenter.FubenManager.DifficultHard
function XExFubenMainLineManager:ExGetChapterConfigs(groupId, difficulty)
    if difficulty == nil then
        return appendArray(self:ExGetChapterConfigs(groupId, XDataCenter.FubenManager.DifficultNormal)
            , self:ExGetChapterConfigs(groupId, XDataCenter.FubenManager.DifficultHard)) 
    end
    if self.__ChapterConfigDic == nil then self.__ChapterConfigDic = {} end
    if self.__ChapterConfigDic[groupId] == nil then self.__ChapterConfigDic[groupId] = {} end
    local result = self.__ChapterConfigDic[groupId][difficulty]
    if result then return result end
    result = result or {}
    local chapterConfigs = XDataCenter.FubenMainLineManager.GetChapterMainTemplates(difficulty)
    for _, config in ipairs(chapterConfigs) do
        if config.GroupId == groupId then
            table.insert(result, config)
        end
    end
    self.__ChapterConfigDic[groupId][difficulty] = result
    return result
end

-- 获取主线章节分组配置数据
function XExFubenMainLineManager:ExGetChapterGroupConfigs()
    local resultConfigs = XFubenMainLineConfigs.GetAllConfigs(XFubenMainLineConfigs.TableKey.ChapterMainGroup)
    if XUiManager.IsHideFunc then
        local tempConfigs = {}
        table.insert(tempConfigs, resultConfigs[1])
        resultConfigs = tempConfigs
    end
    return resultConfigs
end

-- 检查章节分组是否有红点
function XExFubenMainLineManager:ExCheckChapterGroupHasRedPoint(groupId, difficulty)
    for _, viewModel in ipairs(self:ExGetChapterViewModels(groupId, difficulty)) do
        if viewModel:CheckHasRedPoint() then
            return true
        end
    end
    return false
end

-- 检查章节分组是否有限时tag
function XExFubenMainLineManager:ExCheckChapterGroupHasTimeLimitTag(groupId, difficulty)
    for _, viewModel in ipairs(self:ExGetChapterViewModels(groupId,difficulty)) do
        if viewModel:CheckHasTimeLimitTag() then
            return true
        end
    end
    return false
end

-- 检查是否展示红点
function XExFubenMainLineManager:ExCheckIsShowRedPoint()
    for _, config in ipairs(self:ExGetChapterGroupConfigs()) do
        if self:ExCheckChapterGroupHasRedPoint(config.Id) then
            return true
        end
    end
    return false
end

-- 检查章节是否已经锁住
function XExFubenMainLineManager:ExCheckGroupIsLocked(groupId, difficulty)
    for _, viewModel in ipairs(self:ExGetChapterViewModels(groupId, difficulty)) do
        if not viewModel:GetIsLocked() then
            return false
        end
    end
    return true
end

-- 获取章节是否已解锁和锁定提示
function XExFubenMainLineManager:ExGetChapterIsLockAndLockTip(chapterMainId, difficulty)
    local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoByChapterMain(chapterMainId, difficulty)
    -- 已解锁
    if chapterInfo and chapterInfo.Unlock then return false end
    -- 未解锁
    -- 限时活动特殊处理
    if chapterInfo.IsActivity then
        local chapterId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(chapterMainId, difficulty)
        local _, desc = XDataCenter.FubenMainLineManager.CheckActivityCondition(chapterId)
        return true, desc
    end
    return true, XUiHelper.GetText("CommonLockedTip")
end

function XExFubenMainLineManager:ExGetChapterViewModelById(chapterMainId, difficulty, index)
    local subChapterId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(chapterMainId, difficulty)
    if self.__ChapterViewModelIdDic == nil then self.__ChapterViewModelIdDic = {} end
    if self.__ChapterViewModelIdDic[subChapterId] then return self.__ChapterViewModelIdDic[subChapterId] end
    local result = nil
    local config = XDataCenter.FubenMainLineManager.GetChapterMainTemplate(chapterMainId)
    if subChapterId ~= nil and subChapterId > 0 then
        result = CreateAnonClassInstance({
            CheckHasRedPoint = function(proxy)
                return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MAINLINE_CHAPTER_REWARD, proxy:GetId())
            end,
            CheckHasNewTag = function(proxy)
                local hideId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(chapterMainId, XDataCenter.FubenMainLineManager.DifficultHard)
                if XTool.IsNumberValid(hideId) then
                    local hideNew = XDataCenter.FubenMainLineManager.CheckChapterNew(hideId)
                    local normalNew = XDataCenter.FubenMainLineManager.CheckChapterNew(proxy:GetId())
                    return hideNew or normalNew
                end

                return XDataCenter.FubenMainLineManager.CheckChapterNew(proxy:GetId())
            end,
            CheckIsPassed = function(proxy)
                local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(proxy:GetId())
                return chapterInfo.Unlock and chapterInfo.Passed
            end,
            CheckHasTimeLimitTag = function(proxy)
                local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoByChapterMain(proxy:GetExtralData().MainId
                    , proxy:GetExtralData().Difficulty)
                return chapterInfo.IsActivity or false
            end,
            GetWeeklyChallengeCount = function(proxy)
                local chapterConfig = XDataCenter.FubenMainLineManager.GetChapterMainTemplate(proxy:GetExtralData().MainId)
                return XDataCenter.FubenZhouMuManager.GetZhouMuNumber(chapterConfig.ZhouMuId)
            end,
            GetIsLocked = function(proxy)
                return self:ExGetChapterIsLockAndLockTip(proxy:GetExtralData().MainId, proxy:GetExtralData().Difficulty)
            end,
            GetLockTip = function(proxy)
                if proxy:CheckHasTimeLimitTag() then
                    local ret, desc = XDataCenter.FubenMainLineManager.CheckActivityCondition(proxy:GetId())
                    if not ret then
                        return desc
                    end
                else
                    if difficulty == XDataCenter.FubenManager.DifficultNightmare then
                        return CS.XTextManager.GetText("BfrtChapterUnlockCondition")
                    elseif chapterMainId == XDataCenter.FubenMainLineManager.TRPGChapterId then
                        return XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.MainLineTRPG)
                    else
                        local isOpen, desc = XDataCenter.FubenMainLineManager.CheckOpenCondition(proxy:GetId())
                        if not isOpen then
                            return desc
                        end
                        local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoByChapterMain(chapterMainId, difficulty)
                        local tipMsg = XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage)
                        return tipMsg
                    end
                end

            end,
            GetDifficulty = function(proxy)
                return difficulty
            end,
            GetCurrentAndMaxProgress = function(proxy)
                -- return XDataCenter.FubenMainLineManager.GetCurrentAndMaxProgress(proxy:GetId())
                local normalCurStars, normalTotalStars = XDataCenter.FubenMainLineManager.GetChapterStars(proxy:GetId())
                -- 再加上剧情进度计算:1个剧情关算1颗星
                local styPassCount, styTotal = XDataCenter.FubenManagerEx.GetStoryStagePassCount(XDataCenter.FubenMainLineManager.GetStageList(proxy:GetId()))
                normalCurStars = normalCurStars + styPassCount
                normalTotalStars = normalTotalStars + styTotal
                -- 如果有隐藏模式 要把隐藏模式的进度一起算上
                local hideId = XDataCenter.FubenMainLineManager.GetChapterIdByChapterMain(chapterMainId, XDataCenter.FubenMainLineManager.DifficultHard)
                if hideId and hideId > 0 then -- 如果该viewmodel本来就是隐藏关，这里也会重复计算，但是也不需要检测该viewmodel是否是隐藏关, 因为只是拿进度和红点
                    local styPassCount2, styTotal2 = XDataCenter.FubenManagerEx.GetStoryStagePassCount(XDataCenter.FubenMainLineManager.GetStageList(hideId))
                    normalCurStars = normalCurStars + styPassCount2
                    normalTotalStars = normalTotalStars + styTotal2
                    local hideCurStars, hideTotalStars = XDataCenter.FubenMainLineManager.GetChapterStars(hideId)
                    normalCurStars = normalCurStars + hideCurStars
                    normalTotalStars = normalTotalStars + hideTotalStars
                end
                return normalCurStars, normalTotalStars 
            end,
        }, XChapterViewModel
        , {
            Id = subChapterId,
            ExtralName = string.format("%02d", config.OrderId),
            Name = config.ChapterEn,
            Icon = config.Icon,
            ExtralData = {
                GroupId = config.GroupId,
                Difficulty = difficulty,
                MainId = config.Id,
                OrderId = config.OrderId,
                Index = index,
            },
            FirstStage = XDataCenter.FubenMainLineManager.GetChapterInfoByChapterMain(chapterMainId, difficulty).FirstStage,
            ActivityCondition = XDataCenter.FubenMainLineManager.GetChapterCfg(subChapterId).ActivityCondition
        })
        self.__ChapterViewModelIdDic[subChapterId] = result
    end 
    return result
end

-- 检查章节是否有指定难度开启
function XExFubenMainLineManager:ExCheckChapterHasDifficulty(difficulty, orderId)
    local hardOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty)
    local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfoForOrderId(difficulty, orderId)
    hardOpen = hardOpen and chapterInfo and chapterInfo.IsOpen
    return hardOpen
end

function XExFubenMainLineManager:ExGetCurrentGroupIndexAndChapterIndex(groupId)
    -- if checkHistory == nil then checkHistory = true end
    -- checkHistory = false
    -- if checkHistory then
    --     return XSaveTool.GetData("XExFubenMainLineManager.CurrentGroupIndex" .. XPlayer.Id) or 1
    --         , XSaveTool.GetData("XExFubenMainLineManager.CurrentChapterIndex" .. XPlayer.Id) or 1
    -- end
    local groupConfigs
    if groupId == nil then
        groupConfigs = self:ExGetChapterGroupConfigs()
    else
        groupConfigs = { XFubenMainLineConfigs.GetCfgByIdKey(XFubenMainLineConfigs.TableKey.ChapterMainGroup, groupId) }
    end
    local extralData, hardViewModel
    local lockAll = true
    local timeLimitResult = nil
    local normalResult = nil
    local lastModelInfo = nil -- 记录上一个
    local playerCurrModelInfo = nil -- 记录玩家当前通关到的关卡
    for i, config in ipairs(groupConfigs) do
        local viewModels = self:ExGetChapterViewModels(config.Id, XDataCenter.FubenManager.DifficultNormal)
        for i, viewModel in ipairs(viewModels) do
            if not viewModel:GetIsLocked() then
                lockAll = false
            end
            extralData = viewModel:GetExtralData()
            -- 检查正常难度
            if viewModel:CheckHasNewTag() then
                if viewModel:CheckHasTimeLimitTag() then
                    return extralData.GroupId, i
                end
                if normalResult == nil then
                    normalResult = { extralData.GroupId, i }
                end  
            end
            -- 检查困难难度
            hardViewModel = self:ExGetChapterViewModelById(extralData.MainId, XDataCenter.FubenManager.DifficultHard, i)
            if hardViewModel and hardViewModel:CheckHasNewTag() then
                if hardViewModel:CheckHasTimeLimitTag() then
                    return extralData.GroupId, i
                end
                if normalResult == nil then
                    normalResult = { extralData.GroupId, i }
                end
            end
            -- 记录当前玩家打到的关卡
            if viewModel:GetIsLocked() and lastModelInfo and lastModelInfo.ViewModel and not lastModelInfo.ViewModel:GetIsLocked() then
                playerCurrModelInfo = {ViewModel = lastModelInfo.ViewModel, Index = lastModelInfo.Index}
            end

            lastModelInfo = {ViewModel = viewModel, Index = i}
        end
    end
    -- 最后如果没有限时章节，再返回当前打到的关卡
    if playerCurrModelInfo then
        return playerCurrModelInfo.ViewModel:GetExtralData().GroupId, playerCurrModelInfo.Index
    end
    if lockAll then
        return 1, 1
    end
    if normalResult then
        return normalResult[1], normalResult[2]
    end
    return #groupConfigs, #self:ExGetChapterViewModels(groupConfigs[#groupConfigs].Id, XDataCenter.FubenManager.DifficultNormal)

end

-- function XExFubenMainLineManager:ExSetCurrentGroupIndexAndChapterIndex(groupId, index)
--     XSaveTool.SaveData("XExFubenMainLineManager.CurrentGroupIndex" .. XPlayer.Id, groupId)
--     XSaveTool.SaveData("XExFubenMainLineManager.CurrentChapterIndex" .. XPlayer.Id, index)
-- end

return XExFubenMainLineManager