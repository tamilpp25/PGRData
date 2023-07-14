---@class XViewModelDlcHuntChapter
local XViewModelDlcHuntChapter = XClass(nil, "XViewModelDlcHuntChapter")

function XViewModelDlcHuntChapter:Ctor()
    self._ChapterId = false
end

---@return XDlcHuntChapter[]
function XViewModelDlcHuntChapter:GetAllChapters()
    local list = {}
    local allChapter = XDataCenter.DlcHuntManager.GetAllChapters()
    for id, chapter in pairs(allChapter) do
        if chapter:IsUnlock() then
            list[#list + 1] = chapter
        end
    end
    table.sort(list, function(a, b)
        return a:GetIndex() < b:GetIndex()
    end)
    return list
end

---@param chapter XDlcHuntChapter
function XViewModelDlcHuntChapter:SetChapter(chapter)
    self._ChapterId = chapter:GetChapterId()
end

---@return XDlcHuntChapter
function XViewModelDlcHuntChapter:GetChapter()
    return XDataCenter.DlcHuntManager.GetChapter(self._ChapterId)
end

--function XViewModelDlcHuntChapter:UpdateTask()
--    self._Data.IsShowRedPointTask = XDataCenter.DlcHuntManager.IsShowRedDotTask()
--    local task = self:GetCurrentTask()
--    if task then
--        local config = XDataCenter.TaskManager.GetTaskTemplate(task.Id)
--        self._Data.TxtTask = config.Desc
--    else
--        self._Data.TxtTask = XUiHelper.GetText("DlcHuntTaskFinish")
--    end
--end
--
--function XViewModelDlcHuntChapter:GetCurrentTask()
--    local XTaskManager = XDataCenter.TaskManager
--    local tasks = XTaskManager.GetDlcHuntTaskList()
--    local amountFinish = 0
--    for i = 1, #tasks do
--        local task = tasks[i]
--        if task.State == XTaskManager.TaskState.Finish then
--            amountFinish = amountFinish + 1
--        end
--    end
--    if amountFinish == #tasks then
--        return false
--    end
--    return tasks[1]
--end

return XViewModelDlcHuntChapter