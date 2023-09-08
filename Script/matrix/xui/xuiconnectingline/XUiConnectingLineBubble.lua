---@class XUiConnectingLineBubble:XUiNode
local XUiConnectingLineBubble = XClass(XUiNode, "XUiConnectingLineBubble")

function XUiConnectingLineBubble:Ctor()
    self._Timer = false
    ---@type XConnectingLineModelBubble[]
    self._BubbleDict = false
    self._BubbleType = XEnumConst.CONNECTING_LINE.BUBBLE.DEFAULT
    self._IdleTime = 15000
end

function XUiConnectingLineBubble:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_CONNECTING_LINE_BUBBLE, self.OnBubbleChange, self)
end

function XUiConnectingLineBubble:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_CONNECTING_LINE_BUBBLE, self.OnBubbleChange, self)
    self:StopTimer()
end

function XUiConnectingLineBubble:SetBubbleDataSource(dict)
    self._BubbleDict = dict
end

function XUiConnectingLineBubble:SetText(text)
    self.TextBubble.text = text
end

function XUiConnectingLineBubble:SetFace(face)
    self.ImageFace:SetRawImage(face)
end

function XUiConnectingLineBubble:StartTimer(time)
    self:StopTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self:StopTimer()
        XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_BUBBLE, XEnumConst.CONNECTING_LINE.BUBBLE.DEFAULT)
    end, time)
end

function XUiConnectingLineBubble:StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiConnectingLineBubble:OnBubbleChange(bubbleType)
    self._BubbleType = bubbleType
    local bubblePool = self._BubbleDict[bubbleType]
    local bubble
    if bubblePool then
        -- 随机
        if #bubblePool > 1 then
            local index = math.random(2, #bubblePool)
            bubble = table.remove(bubblePool, index)
            table.insert(bubblePool, 1, bubble)
        else
            bubble = bubblePool[1]
        end
        if bubble then
            self:SetText(bubble.Text)
            self:SetFace(bubble.Face)
        end
    end
    if bubbleType == XEnumConst.CONNECTING_LINE.BUBBLE.DEFAULT then
        self:StartIdle()
        return
    end
    if bubble then
        self:StartTimer(bubble.Duration)
    end
end

function XUiConnectingLineBubble:StartIdle()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleOnce(function()
            self._Timer = false
            XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_BUBBLE, XEnumConst.CONNECTING_LINE.BUBBLE.IDLE_SECOND_15)
        end, self._IdleTime)
    end
end

return XUiConnectingLineBubble
