-- 用于扩展的副本管理基类
---@class XExFubenBaseManager
local XExFubenBaseManager = XClass(nil, "XExFubenBaseManager")

--[[
    chapterType : XFubenConfigs.ChapterType
    config : {
        FunctionNameId : 功能开启id
        Icon : 显示图标
        Name : 显示名称
        TimeId : 运行时间
        SkipId : 跳转入口Id
        RedPointConditions : 红点条件
    }
]]
function XExFubenBaseManager:Ctor(chapterType, config)
    self.ExChapterType = chapterType or -1
    self.ExCustomName = nil
    self:ExSetConfig(config)
    XDataCenter.FubenManagerEx.RegisterManager(self)
end

function XExFubenBaseManager:ExSetConfig(value)
    self.ExConfig = value or {}
end

function XExFubenBaseManager:ExSetCustomName(value)
    self.ExCustomName = value
end

function XExFubenBaseManager:ExGetConfig()
    return self.ExConfig
end

function XExFubenBaseManager:ExGetChapterType()
    return self.ExChapterType
end

-- return : XFunctionManager.FunctionName
function XExFubenBaseManager:ExGetFunctionNameType()
    return self.ExConfig.FunctionNameId
end

-- 获取是否已锁住
function XExFubenBaseManager:ExGetIsLocked()
    local functionNameType = self:ExGetFunctionNameType()
    if functionNameType == nil then return false end
    return not XFunctionManager.JudgeCanOpen(functionNameType)
end

-- 获取锁提示
function XExFubenBaseManager:ExGetLockTip()
    local functionNameType = self:ExGetFunctionNameType()
    if functionNameType == nil then return XUiHelper.GetText("CommonLockedTip") end
    return XFunctionManager.GetFunctionOpenCondition(functionNameType)
end

-- 获取活动常用图标
function XExFubenBaseManager:ExGetIcon()
    return self.ExConfig.Icon
end

-- 获取活动对外显示名称
function XExFubenBaseManager:ExGetName()
    return self.ExCustomName or self.ExConfig.Name
end

-- 获取运行时间提示
function XExFubenBaseManager:ExGetRunningTimeStr()
    local startTime = XFunctionManager.GetStartTimeByTimeId(self.ExConfig.TimeId) or 0
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.ExConfig.TimeId) or 0
    local nowTime = XTime.GetServerNowTimestamp()
    if startTime and endTime and nowTime >= startTime and nowTime <= endTime then
        return string.format("%s%s", XUiHelper.GetText("ActivityBranchFightLeftTime")
        , XUiHelper.GetTime(endTime - XTime.GetServerNowTimestamp(), XUiHelper.TimeFormatType.ACTIVITY))
    end
    return ""
end

--检测是否在活动开放时间内
function XExFubenBaseManager:ExCheckInTime()
    local timeId = self.ExConfig.TimeId or 0
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

-- 获取进度提示
function XExFubenBaseManager:ExGetProgressTip()
end

-- 打开玩法主界面
function XExFubenBaseManager:ExOpenMainUi(...)
    XFunctionManager.SkipInterface(self.ExConfig.SkipId)
end

-- 打开玩法指定章节界面，非必须
function XExFubenBaseManager:ExOpenChapterUi(...)
end

-- 检查是否展示红点
function XExFubenBaseManager:ExCheckIsShowRedPoint(...)
    if self.ExConfig.RedPointConditions 
        and XRedPointManager.CheckConditions(self.ExConfig.RedPointConditions) then
        return true
    end
    for _, viewModel in ipairs(self:ExGetChapterViewModels(...) or {}) do
        if viewModel:CheckHasRedPoint() then
            return true
        end
    end
    return false
end

-- 检查是否有限时开放标志
function XExFubenBaseManager:ExCheckHasTimeLimitTag(...)
    for _, viewModel in ipairs(self:ExGetChapterViewModels(...)) do
        if viewModel:CheckHasTimeLimitTag() then
            return true
        end
    end
    return false
end

-- 获取玩法章节数据 return : XChapterViewModel
function XExFubenBaseManager:ExGetChapterViewModels(...)
    return {}
end

-- 获取玩法是否有多难度挑战
function XExFubenBaseManager:ExCheckHasOtherDifficulty()
    return false
end

-- 获取玩法当前章节下标
function XExFubenBaseManager:ExGetCurrentChapterIndex()
    local viewModels = self:ExGetChapterViewModels()

    local unlockAndPassList = {} -- 已通关且解锁列表
    for i, viewModel in ipairs(viewModels) do
        local currPrg, totalPrg = viewModel:GetCurrentAndMaxProgress()
        local isPass = currPrg >= totalPrg

        if not viewModel:GetIsLocked() and isPass then
            table.insert(unlockAndPassList, {viewModel = viewModel, index = i})
        end

        if viewModel:CheckHasTimeLimitTag() and not viewModel:GetIsLocked() and not isPass then
            return i
        end
        
        if not isPass and not viewModel:GetIsLocked() then
            return i
        end
    end
    
    if not unlockAndPassList or not next(unlockAndPassList) then
        return 1
    end

    return unlockAndPassList[#unlockAndPassList].index
end

-- 标记检查玩法是否已完成
function XExFubenBaseManager:ExCheckIsFinished()
    self.IsClear = false
    return false
end

-- 获取检查玩法是否已完成
function XExFubenBaseManager:ExCheckIsClear()
    return self.IsClear or false
end

-- 根据chapterId获得viewModel
function XExFubenBaseManager:ExGetChapterViewModelBySubChapterId(chapterId)
    if self.__ChapterViewModelIdDic then
        return self.__ChapterViewModelIdDic[chapterId]
    end
end

return XExFubenBaseManager