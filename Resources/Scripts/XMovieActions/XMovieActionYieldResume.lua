local XMovieActionYieldResume = XClass(XMovieActionBase, "XMovieActionYieldResume")

local tableInsert = table.insert
local MAX_SKIP_NUM = 3

function XMovieActionYieldResume:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.ResumeActionIds = {}
    for i = 1, MAX_SKIP_NUM do
        local actionId = paramToNumber(params[i])
        if actionId ~= 0 then
            tableInsert(self.ResumeActionIds, actionId)
        end
    end
end

function XMovieActionYieldResume:OnInit()
    self.ResumeActionId = 0
end

function XMovieActionYieldResume:OnRunning()
    XDataCenter.MovieManager.YiledMovie()
end

function XMovieActionYieldResume:ResumeAtIndex(index)
    self.ResumeActionId = self.ResumeActionIds[index] or 0
end

function XMovieActionYieldResume:GetResumeActionId()
    return self.ResumeActionId
end

return XMovieActionYieldResume