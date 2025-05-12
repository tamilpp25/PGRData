local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")

---@class XNewCharStoryViewModel
---@field Config XTableTeachingTrustStoryChapter
local XNewCharStoryViewModel = XClass(XChapterViewModel, 'XNewCharStoryViewModel')


-- 获取进度
---@overload
function XNewCharStoryViewModel:GetProgress()
    local passCount, totalCount = self:GetCurrentAndMaxProgress()
    
    return XTool.IsNumberValid(totalCount) and passCount / totalCount or 0
end

-- 获取当前和最大进度值
---@overload
function XNewCharStoryViewModel:GetCurrentAndMaxProgress()
    local plotDatas = XMVCA.XFavorability:GetCharacterStoryById(self.Config.CharacterId)
    local totalCount = XTool.GetTableCount(plotDatas)
    local passCount = 0

    if not XTool.IsTableEmpty(plotDatas) then
        for i, v in ipairs(plotDatas) do
            if XTool.IsNumberValid(v.StoryId) then
                if XMVCA.XFavorability:CheckStoryIsSatisfyUnlockCondition(self.Config.CharacterId, v.Id) then
                    passCount = passCount + 1
                end
            elseif XTool.IsNumberValid(v.StageId) then
                if XMVCA.XFuben:CheckStageIsPass(v.StageId) then
                    passCount = passCount + 1
                end
            end
        end
    end

    return passCount, totalCount
end

-- 获取进度提示
---@overload
function XNewCharStoryViewModel:GetProgressTips()
    local passCount, totalCount = self:GetCurrentAndMaxProgress()
    
    return XUiHelper.GetText('PrequelCompletion', passCount, totalCount)
end

-- 检查是否有红点提示
---@overload
function XNewCharStoryViewModel:CheckHasRedPoint()
    local plotDatas = XMVCA.XFavorability:GetCharacterStoryById(self.Config.CharacterId)

    if not XTool.IsTableEmpty(plotDatas) then
        for i, v in pairs(plotDatas) do
            if XTool.IsNumberValid(v.TaskId) then
                if XDataCenter.TaskManager.CheckTaskAchieved(v.TaskId) then
                    return true
                end
            end
        end
    end
    
    return false
end

return XNewCharStoryViewModel