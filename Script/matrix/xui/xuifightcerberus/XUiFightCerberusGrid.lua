local XUiFightCerberusGrid = XClass(nil, "XUiFightCerberusGrid")
local Instantiate = CS.UnityEngine.Object.Instantiate
local Vector3 = CS.UnityEngine.Vector3
local math = math
local DURATION = 0.3
local MAX_ROLLING_COUNT = 10

function XUiFightCerberusGrid:Ctor(ui, img, place)
    self.Ui = ui
    self.Count = 0
    self.NumQueue = XQueue.New()
    self.BaseCount = math.pow(10, place)
    self.LastImg = img
    self.NextImg = Instantiate(self.LastImg, self.LastImg.transform)
    self.NextImg.transform.anchoredPosition3D = Vector3(0, self.NextImg.transform.rect.height, 0)
    self.OriginPos = self.LastImg.transform.anchoredPosition3D
    self.ToPos = self.OriginPos - self.NextImg.transform.anchoredPosition3D
    self.LastImg.transform.anchoredPosition3D = self.ToPos
end

function XUiFightCerberusGrid:SetCount(count)
    if self.Count == count then
        return
    end

    local sign = count > self.Count and 1 or -1
    local delta = math.abs(count - self.Count)
    local total = math.min(delta, MAX_ROLLING_COUNT)
    local startIndex = count - sign * total + sign

    for i = startIndex, count, sign  do
        self.NumQueue:Enqueue({
            Num = i % 10,
            Duration = DURATION / total,
        })
    end

    self.Count = count
    if not self.Timer then
        self:DoTween()
    end
end

function XUiFightCerberusGrid:DoTween()
    if self.LastImgUrl then
        self.LastImg:SetSprite(self.LastImgUrl)
    end
    self.LastImg.transform.anchoredPosition3D = self.OriginPos
    local data = self.NumQueue:Dequeue()
    self.LastImgUrl = self.Ui:GetSpriteUrl((data.Num == 0 and self.BaseCount > 1) and 10 or data.Num)
    self.NextImg:SetSprite(self.LastImgUrl)
    self.Timer = XUiHelper.DoUiMove(self.LastImg.transform, self.ToPos,
            data.Duration, XUiHelper.EaseType.Linear, function()
                self.Timer = nil
                -- 检查是否有后续的动画
                if not self.NumQueue:IsEmpty() then
                    self:DoTween()
                end
            end)
end

function XUiFightCerberusGrid:OnDestroy()
    -- 清除数字滚动动画
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
end

return XUiFightCerberusGrid