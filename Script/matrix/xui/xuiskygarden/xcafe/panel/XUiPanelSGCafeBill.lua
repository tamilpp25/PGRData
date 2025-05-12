
---@class XUiPanelSGCafeBill : XUiNode
---@field _Control XSkyGardenCafeControl
---@field Parent XUiSkyGardenCafeGame
local XUiPanelSGCafeBill = XClass(XUiNode, "XUiPanelSGCafeBill")

local Duration = 0.8
local tableRemove = table.remove

function XUiPanelSGCafeBill:OnStart()
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGCafeBill:OnDestroy()
    
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_FLY_COMPLETE, self.Dequeue, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ROUND_BEGIN, self.Refresh, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_BEGIN_FLY, self.Enqueue, self)
end

function XUiPanelSGCafeBill:InitUi()
    self._DataPool = {}
    self._DataQueue = {}
    local battleInfo = self._Control:GetBattle():GetBattleInfo()
    
    local stageId = battleInfo:GetStageId()
    self._CurTotalCafe = battleInfo:GetTotalScore()
    self._LastCafe = battleInfo:GetScore()
    self._CurCafe = battleInfo:GetAddScore()
    local nextTarget, maxTarget = self._Control:GetNextTargetAndMaxTargetByCoffee(stageId, self._CurTotalCafe)
    self._NextTarget = nextTarget
    self._MaxTarget = maxTarget
    
    self._CurTotalReview = battleInfo:GetTotalReview()

    self._IsReviewStage = self._Control:IsReviewStage()
    self.PanelFavorability.gameObject:SetActiveEx(self._IsReviewStage)

    if self._IsReviewStage then
        self.TxtReviewNum.text = self._CurTotalReview
    end
    
    self.ImgTargetYuan.fillAmount = self._CurTotalCafe / maxTarget
    self.TxtTotalNum.text = self._CurTotalCafe
    self.TxtTargetNum.text = string.format("<color=#FF000>/%s</color>", maxTarget)
    self.TxtHistoryNum.text = self._LastCafe
    self.TxtCurrentNum.text = self._CurCafe
    self.TxtEstimateNum.text = self._NextTarget
end

function XUiPanelSGCafeBill:InitCb()
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_FLY_COMPLETE, self.Dequeue, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ROUND_BEGIN, self.Refresh, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_BEGIN_FLY, self.Enqueue, self)
end

function XUiPanelSGCafeBill:Refresh()
    if not XTool.IsTableEmpty(self._DataQueue) then
        for i =#self._DataQueue, 1, -1 do
            local data = self._DataQueue[i]
            self:RecycleData(data)
            tableRemove(self._DataQueue, i)
        end
    end
    self:Enqueue()
    self:Dequeue(false)
end

---@param data XSkyGardenCafeBillData
function XUiPanelSGCafeBill:RefreshCoffee(data)
    local total = data.TotalCoffee
    local last = data.LastCoffee
    local sameTotal = self._CurTotalCafe == total
    if sameTotal and self._LastCafe == last then
        return
    end
    if self._CoffeeTimer then
        XScheduleManager.UnSchedule(self._CoffeeTimer)
        self._CoffeeTimer = nil
    end
   
    local cur = data.CurrentCoffee
    local nextTarget = data.NextTarget
    local maxTarget = self._MaxTarget
    if not sameTotal then
        self.Parent:SetBillEffect(true, true)
    end
    local mathFloor = math.floor
    self._CoffeeTimer = self:Tween(Duration, function(dt)
        local t = (total - self._CurTotalCafe) * dt + self._CurTotalCafe
        self.TxtTotalNum.text = mathFloor(t)
        self.ImgTargetYuan.fillAmount = t / maxTarget

        self.TxtHistoryNum.text = mathFloor((last - self._LastCafe) * dt + self._LastCafe)
        self.TxtCurrentNum.text = mathFloor((cur - self._CurCafe) * dt + self._CurCafe)
        self.TxtEstimateNum.text = mathFloor((nextTarget - self._NextTarget) * dt + self._NextTarget)
        
    end, function()
        self._CurTotalCafe = total
        self._LastCafe = last
        self._CurCafe = cur
        self._NextTarget = nextTarget
        self.Parent:SetBillEffect(true, false)
    end)
end

---@param data XSkyGardenCafeBillData
function XUiPanelSGCafeBill:RefreshReview(data)
    if not self._IsReviewStage then
        return
    end
    local total = data.TotalReview
    if total == self._CurTotalReview then
        return
    end
    
    if self._ReviewTimer then
        XScheduleManager.UnSchedule(self._ReviewTimer)
        self._ReviewTimer = nil
    end
    
    self.Parent:SetBillEffect(false, true)
    local mathFloor = math.floor
    local cur = self._CurTotalReview
    self._ReviewTimer = self:Tween(Duration, function(dt)
        self.TxtReviewNum.text = mathFloor((total - cur) * dt + cur)
    end, function()
        self._CurTotalReview = total
        self.Parent:SetBillEffect(false, false)
    end)
end

function XUiPanelSGCafeBill:Enqueue()
    local data = self:CreateData()
    local battleInfo = self._Control:GetBattle():GetBattleInfo()
    local stageId = battleInfo:GetStageId()
    
    data.TotalCoffee = battleInfo:GetTotalScore()
    data.CurrentCoffee = battleInfo:GetAddScore()
    data.LastCoffee = battleInfo:GetScore()
    local nextTarget, _ = self._Control:GetNextTargetAndMaxTargetByCoffee(stageId, data.TotalCoffee)
    data.NextTarget = nextTarget
    data.TotalReview = battleInfo:GetTotalReview()
    self._DataQueue[#self._DataQueue + 1] = data
end

function XUiPanelSGCafeBill:Dequeue()
    local data = tableRemove(self._DataQueue, 1)
    if not data then
        return
    end
    self:RefreshCoffee(data)
    self:RefreshReview(data)
    
    self:RecycleData(data)
end

---@return XSkyGardenCafeBillData
function XUiPanelSGCafeBill:CreateData()
    if not XTool.IsTableEmpty(self._DataPool) then
        return tableRemove(self._DataPool)
    end
    return {
        TotalCoffee = 0,
        CurrentCoffee = 0,
        LastCoffee = 0,
        NextTarget = 0,
        TotalReview = 0,
    }
end

function XUiPanelSGCafeBill:RecycleData(data)
    self._DataPool[#self._DataPool + 1] = data
end

---@class XSkyGardenCafeBillData
---@field TotalCoffee number
---@field CurrentCoffee number
---@field LastCoffee number
---@field NextTarget number
---@field TotalReview number

return XUiPanelSGCafeBill