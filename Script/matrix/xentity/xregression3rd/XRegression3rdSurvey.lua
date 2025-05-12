---@class XRegression3rdSurvey
---@field ActiveSurveySet
---@field ActiveTaskSet
local XRegression3rdSurvey = XClass(nil, 'XRegression3rdSurvey')

--- 服务端数据更新
---@param notifyData Server.XRegression3SignInData
---@return nil
--------------------------
function XRegression3rdSurvey:UpdateData(notifyData)
    if not notifyData then
        return
    end
    
    self._ActiveSurveyList = notifyData.ActiveSurveyList
end

function XRegression3rdSurvey:AddSurveyData(surveyData)
    if self._ActiveSurveyList == nil then
        self._ActiveSurveyList = {}
    end
    
    table.insert(self._ActiveSurveyList, surveyData)
end

function XRegression3rdSurvey:GetSurveyTaskIdBySurveyId(surveyId)
    if not XTool.IsTableEmpty(self._ActiveSurveyList) then
        for i, v in pairs(self._ActiveSurveyList) do
            if v.SurveyId == surveyId then
                return v.TaskId
            end
        end
    end
end

function XRegression3rdSurvey:CheckHasAnySurvey()
    return not XTool.IsTableEmpty(self._ActiveSurveyList)
end

function XRegression3rdSurvey:CheckHasFinished()
    if not XTool.IsTableEmpty(self._ActiveSurveyList) then
        for i, surveyData in pairs(self._ActiveSurveyList) do
            if not XDataCenter.TaskManager.CheckTaskFinished(surveyData.TaskId) then
                return false
            end
        end
        return true
    end
    return false
end

return XRegression3rdSurvey