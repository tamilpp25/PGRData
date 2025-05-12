
local XRegression3rd = XClass(XDataEntityBase, "XRegression3rd")

local default = {
    _Id = 0, --活动Id
    _State = XRegression3rdConfigs.ActivityState.NotInRegression, --活动状态
    _BeginTime = 0,         --活动开始时间
    _LastOnlineTime = 0,    --最后上线时间
    _ActivityEndTime = 0,   --活动结束时间
    _AutoRewardList = {},   --自动领取奖励
    _SignViewModel = {},    --签到视图数据
    _PassportViewModel = {}, --战令视图数据
    _TaskVideModel = {},    --任务视图数据
    _NewContents = {},      --新活动数据
}

function XRegression3rd:Ctor(activityId)
    self:Init(default, activityId)
end

function XRegression3rd:InitData(activityId)
    self:SetProperty("_Id", activityId)
    local passportId = XRegression3rdConfigs.GetPassportActivityId(self._Id)
    self._PassportViewModel = require("XEntity/XRegression3rd/XRegression3rdPassport").New(passportId)
    self._SignViewModel = require("XEntity/XRegression3rd/XRegression3rdSign").New(self._Id)
    self._TaskVideModel = require("XEntity/XRegression3rd/XRegression3rdTask").New(passportId)
    self._SurveyViewModel = require("XEntity/XRegression3rd/XRegression3rdSurvey").New()
end

--- 服务端数据更新
---@param notifyData Server.XRegression3ActivityData
---@return nil
--------------------------
function XRegression3rd:UpdateData(notifyData)
    self:SetProperty("_State", notifyData.State)
    self:SetProperty("_BeginTime", notifyData.BeginTime)
    self:SetProperty("_LastOnlineTime", notifyData.LastLogoutTime)
    self:SetProperty("_NewContents", XRegression3rdConfigs.GetNewContentList(self._LastOnlineTime))
    self:SetEndTimeStamp()
end

function XRegression3rd:IsOpen()
    return self._Id > 0 and self._State == XRegression3rdConfigs.ActivityState.InRegression and self:GetLeftTime() > 0
end

function XRegression3rd:IsEmptyNewContent()
    return XTool.IsTableEmpty(self._NewContents)
end

function XRegression3rd:GetSignViewModel()
    return self._SignViewModel
end

function XRegression3rd:GetPassportViewModel()
    return self._PassportViewModel
end

---@return XRegression3rdSurvey
function XRegression3rd:GetSurveyViewModel()
    return self._SurveyViewModel
end

function XRegression3rd:GetActivityOverViewList()
    return XRegression3rdConfigs.GetActivityOverViewList(self._Id)
end

function XRegression3rd:GetShopId()
    return XRegression3rdConfigs.GetShopId(self._Id)
end

function XRegression3rd:GetStoryId()
    return XRegression3rdConfigs.GetStoryId(self._Id)
end

function XRegression3rd:GetHelpKey()
    return XRegression3rdConfigs.GetHelpKey(self._Id)
end

function XRegression3rd:GetPackageUiType()
    return XRegression3rdConfigs.GetPackageUiType(self._Id)
end

function XRegression3rd:GetActivityContent()
    return self._NewContents
end

--- 检查页签功能是否开启
---@param activityType number 活动类型
---@return boolean, string
--------------------------
function XRegression3rd:CheckOpenByActivityType(activityType)
    if activityType == XRegression3rdConfigs.ActivityType.Activity then
        return not self:IsEmptyNewContent(), XRegression3rdConfigs.GetClientConfigValue("ActivityNotOpenTips", 1)
    elseif activityType == XRegression3rdConfigs.ActivityType.Shop then
        local functionNameId = XFunctionManager.FunctionName.ShopCommon
        return XFunctionManager.JudgeCanOpen(functionNameId), XFunctionManager.GetFunctionOpenCondition(functionNameId)
    elseif activityType == XRegression3rdConfigs.ActivityType.Questionnaire then
        local surveyData = self:GetSurveyViewModel()
        if surveyData then
            return surveyData:CheckHasAnySurvey()
        end
        return false, ""
    else
        return true, ""
    end
end

---@return "剩余时间：xxx天"
function XRegression3rd:GetLeftTimeDesc(colorStr, format)
    return XUiHelper.GetText("CommonActivityTimeStr", self:GetLeftTimeDescWithoutPrefix(colorStr, format))
end

---@return "xxx天"
function XRegression3rd:GetLeftTimeDescWithoutPrefix(colorStr, format)
    format = format or XUiHelper.TimeFormatType.ACTIVITY
    colorStr = colorStr or "0f70bc"
    return string.format("<color=#%s>%s</color>", colorStr, XUiHelper.GetTime(self:GetLeftTime(), format))
end

--- 距离活动结束剩余时间
function XRegression3rd:GetLeftTime()
    local timeOfNow = XTime.GetServerNowTimestamp()
    local timeOfEnd = self._ActivityEndTime
    if timeOfEnd == 0 then
        self:SetEndTimeStamp()
        timeOfEnd = self._ActivityEndTime
    end
    return math.max(0, timeOfEnd - timeOfNow)
end

function XRegression3rd:SetEndTimeStamp()
    local days = XRegression3rdConfigs.GetContinueDays(self._Id)
    local timeStamp = self._BeginTime + days * 24 * 60 * 60
    self:SetProperty("_ActivityEndTime", XTime.GetTimeDayFreshTime(timeStamp))
end

function XRegression3rd:ClearAutoRewardList()
    self._AutoRewardList = {}
end

return XRegression3rd