---@class XUiCommonRollingNumber
local XUiCommonRollingNumber = XClass(nil, "XUiCommonRollingNumber")

---@type DG.Tweening.DOTween
local DOTween = CS.DG.Tweening.DOTween

function XUiCommonRollingNumber:Ctor(onStart, onRefresh, onFinish)
    self.OnStart = onStart
    self.OnRefresh = onRefresh
    self.OnFinish = onFinish

    self.StartValue = 0
    self.EndValue = 10
    self.Duration = 5

    self.CurrentValue = 0
    self.LastValue = 0
    ---@type DG.Tweening.Tweener
    self.Tweener = false
    ---@type DG.Tweening.Ease
    self.Ease = false
end

function XUiCommonRollingNumber:Play(startValue, endValue, duration, ease)
    self.StartValue = startValue
    self.EndValue = endValue
    self.Duration = duration
    self.Ease = ease or CS.DG.Tweening.Ease.Linear
    self:Kill()
    self:AnimateValue(self.StartValue, self.EndValue, self.Duration)
end

-- 获取当前时间
function XUiCommonRollingNumber:GetCurTimer()
    return self.Tweener and self.Tweener:Elapsed() or 0
end

-- 获取剩余时间
function XUiCommonRollingNumber:GetRemainTime()
    return self.Tweener and self.Tweener:Duration() - self.Tweener:Elapsed() or 0
end

function XUiCommonRollingNumber:IsActive()
    return self.Tweener and self.Tweener:IsActive() or false
end

function XUiCommonRollingNumber:Kill()
    if self:IsActive() then
        self.Tweener:Kill()
    end
end

function XUiCommonRollingNumber:ChangeEndValue(newEndValue, duration)
    self.EndValue = newEndValue or self.EndValue
    self.Duration = duration or -1
    if self:IsActive() then
        CS.XUiHelper.ChangeEndValueEx(self.Tweener, self.EndValue, self.Duration, true)
    end
end

function XUiCommonRollingNumber:AnimateValue(from, to, time)
    self.CurrentValue = from
    self.LastValue = from
    self.Tweener = DOTween.To(
        function() return self.CurrentValue end, -- Getter
        function(value)                          -- Setter
            self.CurrentValue = value
            local intValue = math.floor(value)
            if intValue ~= self.LastValue then
                self.LastValue = intValue
                if self.OnRefresh then
                    self.OnRefresh(intValue)
                end
            end
        end,
        to,  -- End value
        time -- Duration
    ):SetEase(self.Ease):OnStart(function()
        if self.OnStart then
            self.OnStart()
        end
    end):OnComplete(function()
        if self.OnFinish then
            self.OnFinish()
        end
    end):OnKill(function()
        if self.OnFinish then
            self.OnFinish()
        end
    end)
end

return XUiCommonRollingNumber
