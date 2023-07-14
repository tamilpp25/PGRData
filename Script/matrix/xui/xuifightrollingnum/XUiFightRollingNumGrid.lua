local XUiFightRollingNumGrid = XClass(nil, "XUiFightRollingNumGrid")
local math = math
local tostring = tostring
local Vector3 = CS.UnityEngine.Vector3
local Instantiate = CS.UnityEngine.Object.Instantiate
local SignTextTable = { [-1] = "-", [0] = "", [1] = "" }

function XUiFightRollingNumGrid:Ctor(text, height, index, count)
    self.MoveTime = 0.3
    self.NumQueue = XQueue.New()
    self.IsRolling = false
    self.TotalShowCount = count
    self.BasedNum = math.pow(10, index) --用于获取对应位数的数字
    self.LimitCount = 10 -- 避免要显示的滚动过程过长 必须是10的倍数
    self.NextText = text
    self.LastText = Instantiate(self.NextText, self.NextText.transform.parent)
    local centerPos = self.NextText.transform.anchoredPosition3D
    self.CenterPos = centerPos
    self.TopPos = centerPos + Vector3(0, height, 0)
    self.LastText.transform.anchoredPosition3D = centerPos - Vector3(0, height, 0)
    self.LastText.transform:SetParent(self.NextText.transform)
    self.LastText.text = ""
    if self.BasedNum > count and self.BasedNum <= count * 10 then
        self.Sign = 1
        self.NextText.text = tostring(SignTextTable[self.Sign])
    else
        self.Sign = 0
        if self.BasedNum > count and self.BasedNum > 1 then
            self.NextText.text = tostring(SignTextTable[self.Sign])
        else
            self.NextText.text = tostring(self:GetNumber())
        end
    end
end

function XUiFightRollingNumGrid:OnDestroy()
    -- 清除数字滚动动画
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
end

function XUiFightRollingNumGrid:GetNumber()
    return math.floor(self.TotalShowCount / self.BasedNum) % 10
end

function XUiFightRollingNumGrid:SetTotalShowCount(count, sign)
    local c = math.abs(math.floor(count / self.BasedNum) - math.floor(self.TotalShowCount / self.BasedNum))

    if c > self.LimitCount then
        c = self.LimitCount + (c % 10) -- 限制显示数
    end

    local n = self:GetNumber()
    local d
    if count > self.TotalShowCount then
        d = 1
    else
        d = -1
    end
    
    local tempData = { }
    for _ = 1, c do
        n = (n + d + 10) % 10
        tempData = { Count = c, Text = tostring(n) } -- Count用于控制每个动画的时间
        self.NumQueue:Enqueue(tempData)
    end

    if self.BasedNum > count and self.BasedNum <= count * 10 then
        if self.Sign ~= sign then
            self.Sign = sign
            tempData.Text = SignTextTable[self.Sign]
            if c == 0 then
                tempData.Count = 1
                self.NumQueue:Enqueue(tempData)
            end
        end
    else
        if self.Sign == 0 then
            if c > 0 then
                if self.BasedNum > count and self.BasedNum > 1 then
                    tempData.Text = SignTextTable[self.Sign]
                end
            end
        else
            self.Sign = 0
            if c == 0 then
                tempData.Count = 1
                tempData.Text = SignTextTable[self.Sign]
                self.NumQueue:Enqueue(tempData)
            end
        end
    end

    self.TotalShowCount = count

    if not (self.IsRolling or self.NumQueue:IsEmpty()) then
        self:DoTextMove()
    end
end

function XUiFightRollingNumGrid:DoTextMove()
    self.IsRolling = true
    self.LastText.text = self.NextText.text
    self.NextText.transform.anchoredPosition3D = self.TopPos
    local data = self.NumQueue:Dequeue()
    self.NextText.text = data.Text
    
    self.Timer = XUiHelper.DoUiMove(self.NextText.transform, self.CenterPos,
            self.MoveTime / data.Count, XUiHelper.EaseType.Linear, function()
                self.Timer = nil
                self.IsRolling = false
                
                -- 检查是否有后续的动画
                if not self.NumQueue:IsEmpty() then
                    self:DoTextMove()
                end
            end)
end

return XUiFightRollingNumGrid