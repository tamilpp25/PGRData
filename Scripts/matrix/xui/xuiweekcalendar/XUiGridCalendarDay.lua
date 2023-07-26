local XUiGridCalendarDay = XClass(nil,"XUiGridCalendarDay")

function XUiGridCalendarDay:Ctor(ui)
	self.GameObject = ui
	---@type UnityEngine.Transform
	self.Transform = ui.transform
	self:InitUiView()
end

function XUiGridCalendarDay:InitUiView()
	self.TxtWeekTitle = self.Transform:Find("Normal/Text1"):GetComponent("Text")
	self.TxtDate = self.Transform:Find("Normal/Text2"):GetComponent("Text")
	self.TxtTodayWeekTitle = self.Transform:Find("today/Text1"):GetComponent("Text")
	self.TxtTodayDate = self.Transform:Find("today/Text2"):GetComponent("Text")
	self.PanelToday = self.Transform:Find("today")
end

---@param time number --时间戳
function XUiGridCalendarDay:Refresh(time)
	self.Time = time
	local weekNum = XTime.GetWeekDayText(self.Time)
	local dateTime = CS.XDateUtil.GetGameDateTime(self.Time)

	self.TxtWeekTitle.text = weekNum
	self.TxtTodayWeekTitle.text = weekNum
	local date = string.format("%02d.%02d", dateTime.Month, dateTime.Day)
	self.TxtDate.text = date
	self.TxtTodayDate.text = date
	self.PanelToday.gameObject:SetActiveEx(self:IsToday())
end

function XUiGridCalendarDay:IsToday()
	local dateTime = CS.XDateUtil.GetGameDateTime(self.Time)
	local nowTime = CS.XDateUtil.GetGameNow()
	local day = dateTime.Day
	local month = dateTime.Month
	local year = dateTime.Year

	local nowDay = nowTime.Day
	local nowMonth = nowTime.Month
	local nowYear = nowTime.Year

	return day == nowDay and month == nowMonth and year == nowYear
end

return XUiGridCalendarDay