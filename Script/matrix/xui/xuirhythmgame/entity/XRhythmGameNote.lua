
---@class XRhythmGameNote
local XRhythmGameNote = XClass(XEntity, "XRhythmGameNote")

function XRhythmGameNote:OnInit()
    self.Transform = false
    self.RectTransform = false
    self.Index = false
    self.Type = false
    self.TempItem = false
    self.TempAnchoredPos = CS.UnityEngine.Vector2.zero -- 作为一个移动值去控制，因为note的起点和终点是已知的，不需要实时拿RectTransform去计算
    self.Width = false
    -- 这里的Time都是时间戳
    self.JudgmentTimeStamp = false
    self.TransmitTimeStamp = false
    self.ReleaseTimeStamp = false
    self.HitTimeStamp = false
    self.NewSpeedMs = false -- 滑条头需要使用特殊的速度控制
    self.State = false
    self.Score = false
end

function XRhythmGameNote:OnRelease()
    self.Transform = nil
    self.RectTransform = nil
    self.Index = nil
    self.Type = nil
    self.TempItem = nil
    self.TempAnchoredPos = nil
    self.Width = nil
    self.JudgmentTimeStamp = nil
    self.TransmitTimeStamp = nil
    self.ReleaseTimeStamp = nil
    self.HitTimeStamp = nil
    self.NewSpeedMs = nil
    self.State = nil
    self.Score = nil
end

return XRhythmGameNote