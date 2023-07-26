---@class XDlcHuntChapter
local XDlcHuntChapter = XClass(nil, "XDlcHuntChapter")

function XDlcHuntChapter:Ctor(chapterId)
    self._ChapterId = chapterId
end

function XDlcHuntChapter:GetChapterId()
    return self._ChapterId
end

function XDlcHuntChapter:GetName()
    return XDlcHuntWorldConfig.GetChapterName(self:GetChapterId())
end

function XDlcHuntChapter:GetIndex()
    return XDlcHuntWorldConfig.GetChapterIndex(self:GetChapterId())
end

function XDlcHuntChapter:GetModel()
    return XDlcHuntWorldConfig.GetChapterModel(self:GetChapterId())
end

function XDlcHuntChapter:GetModel2()
    return XDlcHuntWorldConfig.GetChapterModel2(self:GetChapterId())
end

function XDlcHuntChapter:GetDesc()
    return XDlcHuntWorldConfig.GetChapterDesc(self:GetChapterId())
end

function XDlcHuntChapter:GetWorldIdList()
    return XDlcHuntWorldConfig.GetChapterWorlds(self:GetChapterId())
end

function XDlcHuntChapter:IsRank()
    local worldList = self:GetWorldList()
    for i = 1, #worldList do
        local world = worldList[i]
        if world:IsRank() then
            return true
        end
    end
    return false
end

---@return XDlcHuntWorld[]
function XDlcHuntChapter:GetWorldList()
    local worldIdList = self:GetWorldIdList()
    local result = {}
    for i = 1, #worldIdList do
        local worldId = worldIdList[i]
        local world = XDataCenter.DlcHuntManager.GetWorld(worldId)
        result[#result + 1] = world
    end
    return result
end

function XDlcHuntChapter:GetProgress()
    local progress = 0
    local worlds = self:GetWorldIdList()
    local maxProgress = #worlds
    for i = 1, maxProgress do
        local worldId = worlds[i]
        if XDataCenter.DlcHuntManager.IsPassed(worldId) then
            progress = progress + 1
        end
    end
    return progress, maxProgress
end

function XDlcHuntChapter:GetMaxProgress()
    local worlds = XDlcHuntWorldConfig.GetChapterWorlds(self:GetChapterId())
    return #worlds
end

function XDlcHuntChapter:GetIcon()
    return XDlcHuntWorldConfig.GetChapterIcon(self:GetChapterId())
end

function XDlcHuntChapter:GetChapterTimerId()
    return XDlcHuntWorldConfig.GetChapterTimerId(self:GetChapterId())
end

function XDlcHuntChapter:GetChapterUnlockTime()
    local timerId = self:GetChapterTimerId()
    local beginTime = XFunctionManager.GetStartTimeByTimeId(timerId)
    return beginTime
end

function XDlcHuntChapter:GetChapterPreWorldId()
    return XDlcHuntWorldConfig.GetChapterPreWorldId(self:GetChapterId())
end

function XDlcHuntChapter:IsUnlock()
    local timerId = self:GetChapterTimerId()
    local isOpen = XFunctionManager.CheckInTimeByTimeId(timerId)
    if not isOpen then
        return false, XDlcHuntWorldConfig.CHAPTER_LOCK_STATE.LOCK_FOR_TIME
    end

    local preWorldId = XDlcHuntWorldConfig.GetChapterPreWorldId(self:GetChapterId())
    if preWorldId and preWorldId > 0 then
        local world = self:GetWorld(preWorldId)
        if not world then
            return false, XDlcHuntWorldConfig.CHAPTER_LOCK_STATE.NONE
        end
        if not world:IsPassed() then
            return false, XDlcHuntWorldConfig.CHAPTER_LOCK_STATE.LOCK_FOR_FRONT_WORLD_NOT_PASS
        end
    end

    return true
end

function XDlcHuntChapter:GetWorld(worldId)
    return XDataCenter.DlcHuntManager.GetWorld(worldId)
end

return XDlcHuntChapter