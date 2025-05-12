local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiWeekCalendarTip = XLuaUiManager.Register(XLuaUi,"UiWeekCalendarTip")

function XUiWeekCalendarTip:OnStart(activityId)
    self.ActivityId = activityId
    self.GridItem = {}

    self:RegisterButtonEvent()
    self:Refresh()
    self:RefreshReward()
end

function XUiWeekCalendarTip:RefreshReward()
    local activityInfo = XDataCenter.ActivityCalendarManager.GetActivityInfo(self.ActivityId)
    local showItemList = activityInfo:GetShowItemList()
    for i = 1, #showItemList do
        local grid = XUiGridCommon.New(self,self["GridReward"..i])
        grid:Refresh(showItemList[i])
        self.GridItem[i] = grid
    end

    for i = #showItemList+1 , 3 do
        self["GridReward"..i].gameObject:SetActiveEx(false)
    end
end

function XUiWeekCalendarTip:RegisterButtonEvent()
    CsXUiHelper.RegisterClickEvent(self.BtnBack, function() self:Close() end)
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnGo.CallBack = function()
        local activityInfo = XDataCenter.ActivityCalendarManager.GetActivityInfo(self.ActivityId)
        if not self:CheckInTime(activityInfo) then
            return
        end
        local skipId = activityInfo:GetSkipId()
        if skipId and skipId ~= 0 then
            XFunctionManager.SkipInterface(skipId)
        end
    end
end

function XUiWeekCalendarTip:Refresh()
    local activityInfo = XDataCenter.ActivityCalendarManager.GetActivityInfo(self.ActivityId)
    self.TxtActivityName.text = activityInfo:GetName()
    local desc = activityInfo:GetDesc()
    self.TxtWorldDesc.text = string.gsub(desc, "\\n", "\n")
end

function XUiWeekCalendarTip:CheckInTime(activityInfo)
    if not activityInfo then
        return false
    end
    local functionId = activityInfo:GetFunctionId()
    local now = XTime.GetServerNowTimestamp()
    if not activityInfo:IsJudgeOpen() then
        XUiManager.TipMsg(XFunctionManager.GetFunctionOpenCondition(functionId))
        return false
    end
    if now < activityInfo:GetStartTime() then
        XUiManager.TipText("CommonActivityNotStart")
        return false
    end

    if now > activityInfo:GetEndTime() then
        XUiManager.TipText("CommonActivityEnd")
        return false
    end
    
    return true
end