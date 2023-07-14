local boxAnim
local animOpen = "BoxBegan"
local animReset = "BoxReset"
local animLength --ms

local Init = function(panelAnim)
    local box = panelAnim:GetChild(0)
    boxAnim = box:GetComponent("Animation")
    local clip = boxAnim:GetClip(animOpen)
    animLength = math.floor(clip.length * 1000)
end

local OpenBox = function(cb)
    boxAnim:Play(animOpen)
    XScheduleManager.ScheduleOnce(cb, animLength)
end

local ResetBox = function()
    boxAnim:Play(animReset)
end

local XUiDrawBox = {}

XUiDrawBox.Init = Init
XUiDrawBox.OpenBox = OpenBox
XUiDrawBox.ResetBox = ResetBox

return XUiDrawBox