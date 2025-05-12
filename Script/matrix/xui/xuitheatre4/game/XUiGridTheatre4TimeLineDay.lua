---@class XUiGridTheatre4TimeLineDay : XUiNode
---@field private _Control XTheatre4Control
local XUiGridTheatre4TimeLineDay = XClass(XUiNode, "XUiGridTheatre4TimeLineDay")

function XUiGridTheatre4TimeLineDay:OnStart()
    self.ImgEventBg.gameObject:SetActiveEx(false)
    self.ListEvent.gameObject:SetActiveEx(false)
    self.Day = 0
    ---@type UiObject[]
    self.ImgList = {}
end

---@param fate XTheatre4Fate
function XUiGridTheatre4TimeLineDay:Refresh(fate, day, eventId, bossContentId)
    self.Day = day
    -- 显示天数
    self.TxtDayNum.text = day
    local curDay = self._Control:GetDays()
    -- 事件触发点
    local isFateTriggerDay = self._Control:CheckIsFateTriggerDay(day)
    local isEvent = XTool.IsNumberValid(eventId)
    local isBoss = XTool.IsNumberValid(bossContentId)
    self.ListEvent.gameObject:SetActiveEx(isFateTriggerDay or isEvent or isBoss)
    local index = 1
    if isFateTriggerDay and day > curDay then
        local img = self.ImgList[index]
        if not img then
            img = XUiHelper.Instantiate(self.ImgEventBg, self.ListEvent)
            self.ImgList[index] = img
        end
        img.gameObject:SetActiveEx(true)
        img:GetObject("ImgEvent"):SetRawImage(self._Control:GetClientConfig("FateExclamationMarkIcon"))
        index = index + 1
    end
    -- 不显示事件结束
    --if isEvent then
    --    local img = self.ImgList[index]
    --    if not img then
    --        img = XUiHelper.Instantiate(self.ImgEventBg, self.ListEvent)
    --        self.ImgList[index] = img
    --    end
    --    img.gameObject:SetActiveEx(true)
    --    local icon = self._Control:GetEventIcon(eventId)
    --    img:GetObject("ImgEvent"):SetRawImage(icon)
    --    index = index + 1
    --end
    if isBoss then
        local img = self.ImgList[index]
        if not img then
            img = XUiHelper.Instantiate(self.ImgEventBg, self.ListEvent)
            self.ImgList[index] = img
        end
        img.gameObject:SetActiveEx(true)
        img:GetObject("ImgEvent"):SetRawImage(self._Control:GetFightIcon(bossContentId))
        index = index + 1
    end
    for i = index, #self.ImgList do
        self.ImgList[i].gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre4TimeLineDay:GetDay()
    return self.Day
end

return XUiGridTheatre4TimeLineDay
