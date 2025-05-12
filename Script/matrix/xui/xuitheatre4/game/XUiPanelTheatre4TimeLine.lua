---@class XUiPanelTheatre4TimeLine : XUiNode
---@field private _Control XTheatre4Control
---@field Parent XUiTheatre4Game
---@field AutoLayoutGroup XAutoLayoutGroup
---@field GridDay UnityEngine.RectTransform
---@field ListDay UnityEngine.RectTransform
local XUiPanelTheatre4TimeLine = XClass(XUiNode, "XUiPanelTheatre4TimeLine")

function XUiPanelTheatre4TimeLine:OnStart()
    self.GridDay.gameObject:SetActiveEx(false)
    self.ImgBoss.gameObject:SetActiveEx(false)
    self.TimeLineDays = self._Control:GetClientConfig("TimelineDays", 1, true)
    -- 格子宽度
    self.GirdWidth = self.GridDay.sizeDelta.x + self.AutoLayoutGroup.Spacing.x
    -- 列表初始位置
    ---@type UnityEngine.Vector2
    self.ListInitPos = self.ListDay.anchoredPosition
    ---@type XUiGridTheatre4TimeLineDay[]
    self.DayList = {}
end

function XUiPanelTheatre4TimeLine:Refresh(isAnim, callback, isTimeBack, oldMin, oldMax)
    local curDays = self._Control:GetDays()
    if not XTool.IsNumberValid(curDays) then
        if callback then
            callback()
        end
        return
    end
    -- 显示天数
    local minDay = curDays + 1 - (isAnim and 1 or 0)
    local maxDay = curDays + self.TimeLineDays
    -- 还原位置
    self.ListDay.anchoredPosition = self.ListInitPos
    self:RefreshTimeLine(minDay, maxDay)

    if isTimeBack then
        local oldMinDay =  oldMin or self._MinDay
        local oldMaxDay = oldMax or self._MaxDay
        if oldMinDay and oldMaxDay then
            local diff = oldMinDay - minDay
            local times = diff
            -- 避免死循环，设置回溯上限为9
            if diff > 0 and diff < 9 then
                local timeBackOnce
                timeBackOnce = function()
                    local startPos = self.ListDay.anchoredPosition3D
                    local targetPos = startPos + CS.UnityEngine.Vector3(self.GirdWidth, 0, 0)
                    self.ListDay.anchoredPosition3D = targetPos
                    self:RefreshTimeLine(oldMinDay, oldMaxDay)
                    self:PlayAnimTimeBack(function()
                        diff = diff - 1
                        if diff <= 0 then
                            if callback then
                                callback()
                            end
                        else
                            oldMinDay = oldMinDay - 1
                            oldMaxDay = oldMaxDay - 1
                            timeBackOnce()
                        end
                    end, times)
                end
                timeBackOnce()

            elseif diff < 0 then
                self:PlayAnim(callback)
            else
                if callback then
                    callback()
                end
            end
        else
            self:PlayAnim(callback)
        end
    end
    self._MinDay = minDay
    self._MaxDay = maxDay
    if isTimeBack then
        return
    end

    if isAnim then
        self:PlayAnim(callback)
    elseif callback then
        callback()
    end
end

function XUiPanelTheatre4TimeLine:RefreshTimeLine(minDay, maxDay)
    -- Boss触发天数, boss内容Id
    local bossTriggerDay, bossContentId = self._Control.MapSubControl:GetBossTriggerDayAndContentId()
    local index = 1
    for day = maxDay, minDay, -1 do
        local grid = self.DayList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridDay, self.ListDay)
            grid = require("XUi/XUiTheatre4/Game/XUiGridTheatre4TimeLineDay").New(go, self)
            self.DayList[index] = grid
        end
        grid:Open()

        local fate = self._Control:GetFateByDay(day)
        -- 事件生效天数
        local fateEffectDay = self._Control:GetFateTriggerDay(fate)
        -- 触发事件Id
        local eventId = fate and fate:GetEventId()

        -- 是否是事件生效天
        local isFateTriggerDay = fateEffectDay > 0 and fateEffectDay == day
        -- 是否是Boss触发天
        local isBossTriggerDay = bossTriggerDay > 0 and bossTriggerDay == day
        grid:Refresh(fate, day, isFateTriggerDay and eventId or 0, isBossTriggerDay and bossContentId or 0)
        index = index + 1
    end
    for i = index, #self.DayList do
        self.DayList[i]:Close()
    end
    --self.ImgBoss.gameObject:SetActiveEx(bossTriggerDay > maxDay)
    --if bossTriggerDay > maxDay and self.RImgBoss then
    --    self.RImgBoss:SetRawImage(self._Control:GetFightIcon(bossContentId))
    --end
end

function XUiPanelTheatre4TimeLine:PlayAnim(callback)
    local startPos = self.ListDay.anchoredPosition3D
    local targetPos = startPos + CS.UnityEngine.Vector3(self.GirdWidth, 0, 0)
    local duration = self._Control:GetClientConfig("TimelineAnimTime", 1, true) / 1000
    XLuaUiManager.SetMask(true)
    self:DoUiMove(self.ListDay, targetPos, duration, XUiHelper.EaseType.Sin, function()
        XLuaUiManager.SetMask(false)
        if callback then
            callback()
        end
    end)
end

function XUiPanelTheatre4TimeLine:PlayAnimTimeBack(callback, times)
    times = times or 1
    local startPos = self.ListDay.anchoredPosition3D
    local targetPos = startPos - CS.UnityEngine.Vector3(self.GirdWidth, 0, 0)
    local duration = self._Control:GetClientConfig("TimelineAnimTime", 1, true) / 1000 / times
    XLuaUiManager.SetMask(true)
    self:DoUiMove(self.ListDay, targetPos, duration, XUiHelper.EaseType.Sin, function()
        XLuaUiManager.SetMask(false)
        if callback then
            callback()
        end
    end)
end

return XUiPanelTheatre4TimeLine
