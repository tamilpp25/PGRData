local XUiMultClickHelper = {}

local MultClickState = {
    NORMAL = 0,
    CLICKING = 1,
    COOLING = 2
}

function XUiMultClickHelper.New(delegate, interval, maxClickLimit)
    local helper = {}

    --初始化
    function helper:Init(tmpDelegate, tmpInterval, tmpMaxClickLimit)
        self.Delegate = tmpDelegate
        self.Interval = tmpInterval --点击间隔
        self.LastClickTime = -1 -- 上次的点击时间
        self.LastFinishTime = -1
        self.ClickTimes = 0   --当前点击次数
        self.ClickTimesLimit = tmpMaxClickLimit --点击次数限制
        self.CoolTime = 0 --冷却时间秒
        self.Status = MultClickState.NORMAL
        self.Time = 0
    end

    --点击
    function helper:Click()
        if self.Status == MultClickState.COOLING then
            return
        end

        if self.ClickTimesLimit <= self.ClickTimes then
            return
        end

        self.LastClickTime = self.Time
        self.ClickTimes = self.ClickTimes + 1

        self.Status = MultClickState.CLICKING
    end

    --更新
    function helper:Update(deltaTime)
        self.Time = self.Time + deltaTime

        if not self:IsActive() then
            return
        end

        if self.Status == MultClickState.NORMAL then
            return
        end


        --如果是CD中
        if self.Status == MultClickState.COOLING and self.Time < self.LastFinishTime + self.CoolTime then
            return
        end

        --CD完
        if self.Status ~= MultClickState.CLICKING then
            self:Reset()
        end

        if self.Status == MultClickState.CLICKING and self.Time >= self.LastClickTime + self.Interval then
            self:OnFinishMultClick()
        end

    end

    --完成回调
    function helper:OnFinishMultClick()
        if self.Delegate and self.ClickTimes > 0 then
            self.Delegate:OnMultClick(self.ClickTimes)
        end

        self.LastClickTime = -1 -- 上次的点击时间
        self.ClickTimes = 0
        self.Status = MultClickState.COOLING

        self.LastFinishTime = self.Time
    end

    --重置
    function helper:Reset()
        self.LastClickTime = -1 -- 上次的点击时间
        self.ClickTimes = 0
        self.Status = MultClickState.NORMAL
    end


    ---生命周期----------------------------------------------
    function helper:IsActive()
        return self.Active
    end

    function helper:OnEnable()
        self.Active = true
    end

    function helper:OnDisable()
        self.Active = false
    end

    function helper:OnDestroy()
        self.Delegate = nil
    end

    helper:Init(delegate, interval, maxClickLimit)

    return helper
end

return XUiMultClickHelper