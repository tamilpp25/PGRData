---@class XUiMazeRandomTimeline
local XUiMazeRandomTimeline = XClass(nil, "XUiMazeRandomTimeline")

function XUiMazeRandomTimeline:Ctor()
    self._TimelineHelper = false
    self._Duration = 10
    self._RandomArray = {}
    self._Time = 0
    self._LastIndex = 1
    self._IsPlaying = false
    self._Timer = false
    self._ObjectBind = {}
end

function XUiMazeRandomTimeline:Play(time)
    self._Time = time or 0
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:Update()
        end, 0)
    end
end

function XUiMazeRandomTimeline:PlayDelay()
    local delayTime = 5
    self:Play(self._Duration - delayTime)
end

function XUiMazeRandomTimeline:Pause()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiMazeRandomTimeline:Stop()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
    self._TimelineHelper = false
    self:ClearObjectBind()
end

function XUiMazeRandomTimeline:Update()
    if self._IsPlaying then
        return
    end
    local deltaTime = CS.UnityEngine.Time.deltaTime
    self._Time = self._Time + deltaTime
    if self._Time > self._Duration then
        self._Time = 0
        self:PlayRandomTimeline()
    end
end

function XUiMazeRandomTimeline:ClearObjectBind()
    self._ObjectBind = {}
end

function XUiMazeRandomTimeline:SetRandomArray(dataArray)
    self._RandomArray = {}
    for i = 1, #dataArray do
        local data = dataArray[i]
        self._RandomArray[i] = data
    end
end

function XUiMazeRandomTimeline:SetTimelineHelper(helper)
    self._TimelineHelper = helper
end

function XUiMazeRandomTimeline:Load(path)
    self._TimelineHelper:Load(path)
end

function XUiMazeRandomTimeline:BindObject(key, object)
    self._ObjectBind[key] = object
end

function XUiMazeRandomTimeline:BindFace(key, object)
    self:BindObject(key, object)
end

function XUiMazeRandomTimeline:PlayRandomTimeline()
    local nextIndex = self:GetNextIndex()
    self._LastIndex = nextIndex
    local path = self._RandomArray[nextIndex]
    if string.IsNilOrEmpty(path) then
        return
    end
    self:Load(path)
    self._IsPlaying = true
    for key, object in pairs(self._ObjectBind) do
        self._TimelineHelper:SetBindingTarget(key, object)
    end
    self._TimelineHelper:Play(function()
        self._IsPlaying = false
    end)
end

function XUiMazeRandomTimeline:GetNextIndex()
    local index = 1
    local poolAmount = #self._RandomArray
    if poolAmount > 1 then
        index = math.random(1, #self._RandomArray - 1)
        if index >= self._LastIndex then
            index = index + 1
        end
    end
    return index
end

return XUiMazeRandomTimeline