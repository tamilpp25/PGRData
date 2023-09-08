---@class XUiButtonLongClick
XUiButtonLongClick = XClass(nil, "XUiButtonLongClick")

-- AddPointerDownListener
-- AddPointerUpListener
-- AddPointerExitListener
-- AddPointerClickListener
-- AddDragListener
-- RemoveAllListeners
local LONG_CLICK_START_OFFSET = 0.5
--onlyOneCallback 控制长短按钮只有一个响应
--noAutoUp 控制setDisable的自动触发OnUp方法
function XUiButtonLongClick:Ctor(widget, interval, caller, clickCallback, longClickCallback, longClickUpCallback, isCanExit, proxy,onlyOneCallback,noAutoUp,TriggerOffset)
    self.GameObject = widget.gameObject
    self.Transform = widget.transform
    self:SetInterval(interval)
    self:SetTriggerOffset(TriggerOffset)
    self.Caller = caller
    self.Proxy = proxy
    self.OnlyOneCallback = onlyOneCallback
    self.noAutoUp = noAutoUp

    if XTool.UObjIsNil(widget) then
        XLog.Error("XUiButtonLongClick:Ctor error: widget is nil!")
        return
    end

    self.Widget = widget.gameObject:GetComponent("XUiPointer")
    if not self.Widget then
        widget.gameObject:AddComponent(typeof(CS.XUiPointer))
        self.Widget = widget.gameObject:GetComponent("XUiPointer")
    end

    self.ClickCallbacks = {}
    if clickCallback then
        table.insert(self.ClickCallbacks, clickCallback)
    end
    self.LongClickCallback = {}
    if longClickCallback then
        table.insert(self.LongClickCallback, longClickCallback)
    end
    self.longClickUpCallbacks = {}
    if longClickUpCallback then
        table.insert(self.longClickUpCallbacks, longClickUpCallback)
    end
    self.Widget:AddPointerDownListener(
    function(eventData)
        self:OnDown(eventData)
    end
    )
    self.Widget:AddPointerExitListener(
    function(eventData)
        if isCanExit then
            self:OnUp(eventData)
        end
    end
    )
    self.Widget:AddPointerUpListener(
    function(eventData)
        self:OnUp(eventData)
    end
    )
end

function XUiButtonLongClick:OnDown(eventData)
    if self.IsPressing then
        return
    end
    self.PointerId = eventData.pointerId
    self.IsPressing = true
    self.frameCount = 0
    self.PressTime = 0
    self:RemoveTimer()
    self.Timer = XScheduleManager.ScheduleForever(
    function() self:Tick() end,
    self.Interval
    )
    self.DownTime = CS.UnityEngine.Time.time
end

function XUiButtonLongClick:OnUp(eventData,isLongClickCallback)
    if eventData and eventData.pointerId ~= self.PointerId then
        return
    end
    local onlyOneCallback
    self.PointerId = -1
    self.IsPressing = false
    self:RemoveTimer()
    if self.DownTime and CS.UnityEngine.Time.time - self.DownTime < self.Offset and not isLongClickCallback then

        for i = 1, #self.ClickCallbacks do
            local callback = self.ClickCallbacks[i]
            if callback then
                callback(self.Caller)
            end
        end
        if self.OnlyOneCallback then
            onlyOneCallback = true
        end
    end

    if onlyOneCallback then
        return
    end

    for i = 1, #self.longClickUpCallbacks do
        local callback = self.longClickUpCallbacks[i]
        if callback then
            callback(self.Caller)
        end
    end
end

function XUiButtonLongClick:SetInterval(interval)
    if interval == nil or interval < 0 then
        self.Interval = 100
    else
        self.Interval = interval
    end
end

function XUiButtonLongClick:SetTriggerOffset(offset)
    if offset == nil or offset < 0 then
        self.Offset = LONG_CLICK_START_OFFSET
    else
        self.Offset = offset
    end
end

function XUiButtonLongClick:Tick()
    if not self.GameObject:Exist() or not self.GameObject.activeSelf or not self.GameObject.activeInHierarchy then
        if not self.noAutoUp then
            self:OnUp()
            return
        end
    end
    self.PressTime = self.PressTime + self.Interval
    local pressingTime = self.PressTime - self.Offset
    if pressingTime > 0 then
        for i = 1, #self.LongClickCallback do
            local callback = self.LongClickCallback[i]
            if callback then
               local isExit,isLongClickCallback =  callback(self.Caller, pressingTime, self, self.Proxy) --通过返回值决定调用长、短按按钮的方法类型
                if isExit then
                    self:OnUp(nil,isLongClickCallback)
                end
            end
        end
    end
end

function XUiButtonLongClick:Reset()
    self.PointerId = -1
    self.IsPressing = false
    self:RemoveTimer()
end

function XUiButtonLongClick:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiButtonLongClick:Destroy()
    self:Reset()
    self.Widget:RemoveAllListeners()

    self.GameObject = nil
    self.Transform = nil
    self.Caller = nil
    self.Proxy = nil
    self.OnlyOneCallback = nil
    self.noAutoUp = nil
    self.Widget = nil
    self.ClickCallbacks = nil
    self.LongClickCallback = nil
    self.longClickUpCallbacks = nil
end