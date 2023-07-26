---@class XViewModelDlcHuntChapterDetail
local XViewModelDlcHuntChapterDetail = XClass(nil, "XViewModelDlcHuntChapterDetail")

function XViewModelDlcHuntChapterDetail:Ctor()
    self._ChapterId = false
    self._WorldIdSelected = false
end

---@param chapter XDlcHuntChapter
function XViewModelDlcHuntChapterDetail:SetChapter(chapter)
    self._ChapterId = chapter:GetChapterId()
end

---@param world XDlcHuntWorld
function XViewModelDlcHuntChapterDetail:SetWorld(world)
    self._WorldIdSelected = world:GetWorldId()
end

---@return XDlcHuntWorld
function XViewModelDlcHuntChapterDetail:GetWorld()
    return XDataCenter.DlcHuntManager.GetWorld(self._WorldIdSelected)
end

---@return XDlcHuntChapter
function XViewModelDlcHuntChapterDetail:GetChapter()
    return XDataCenter.DlcHuntManager.GetChapter(self._ChapterId)
end

function XViewModelDlcHuntChapterDetail:_GetWorldIdSelected()
    return self._WorldIdSelected
end

function XViewModelDlcHuntChapterDetail:GetWorldList()
    return self:GetChapter():GetWorldList()
end

-- 关卡提示
function XViewModelDlcHuntChapterDetail:GetWorldDesc()
    return XDlcHuntWorldConfig.GetWorldDifficultyDesc(self:_GetWorldIdSelected())
end

function XViewModelDlcHuntChapterDetail:GetRewards()
    local result = {}
    local worldId = self:_GetWorldIdSelected()
    local rewardId = XDlcHuntWorldConfig.GetWorldReward(worldId)
    local isFirstPassed = not XDataCenter.DlcHuntManager.IsPassed(worldId)
    local rewards = XRewardManager.GetRewardList(rewardId) or {}
    for i, item in ipairs(rewards) do
        result[#result + 1] = item
    end
    if isFirstPassed then
        local firstPassedRewardId = XDlcHuntWorldConfig.GetWorldFirstRewardId(worldId)
        local firstPassedRewards = XRewardManager.GetRewardList(firstPassedRewardId) or {}
        for i, item in ipairs(firstPassedRewards) do
            result[#result + 1] = item
        end
    end
    return result
end

return XViewModelDlcHuntChapterDetail