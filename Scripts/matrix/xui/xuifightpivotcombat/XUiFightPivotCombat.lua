local XUiFightPivotCombat = XLuaUiManager.Register(XLuaUi, "UiFightPivotCombat")

local _, COLOR_EXECUTION_BAR_HIGH = CS.UnityEngine.ColorUtility.TryParseHtmlString("#C0D816")
local _, COLOR_EXECUTION_BAR_MID = CS.UnityEngine.ColorUtility.TryParseHtmlString("#E3CB45")
local _, COLOR_EXECUTION_BAR_LOW = CS.UnityEngine.ColorUtility.TryParseHtmlString("#ED624F")
local MAX_MULTI_SLASH_TIMES = 8

function XUiFightPivotCombat:OnAwake()
    self.ImgTimeBar.fillAmount = 0
    self.ImgTimeBar.gameObject:SetActiveEx(false)
    self.TextIntegralNum.text = 0
    self.TextAddIntegralNum.text = nil
    self.MultiSlashDotImgs = {}
    for i = 1, MAX_MULTI_SLASH_TIMES do
        self.MultiSlashDotImgs[#self.MultiSlashDotImgs + 1] = self["ImgDot0" .. tostring(i)]
    end
    self.MultiSlashDotsActive = true
    self.MultiSlashTimes = 0
end

function XUiFightPivotCombat:AddScore(deltaScore)
    if deltaScore == 0 then
        return
    end

    local addScoreString = deltaScore
    if deltaScore > 0 then
        addScoreString = "+" .. addScoreString
    else
        addScoreString = "-" .. addScoreString
    end

    self.TotalScore = (self.TotalScore or 0) + deltaScore
    local totalScoreString = self.TotalScore
    if self.TotalScore >= 10000 then
        totalScoreString = string.format("%.2fW", self.TotalScore / 10000)
    end

    self.TextIntegralNum.text = totalScoreString
    self.TextAddIntegralNum.text = addScoreString
    
    self:PlayAnimation("TextAddIntegralNumEnable")
end

function XUiFightPivotCombat:SetFillAmount(fillAmount)
    self.ImgTimeBar.fillAmount = fillAmount
    self.ImgTimeBar.gameObject:SetActiveEx(fillAmount > 0)

    if fillAmount > 0.5 then
        self.ImgTimeBar.color = COLOR_EXECUTION_BAR_HIGH
    elseif fillAmount <= 0.5 and fillAmount >= 0.2 then
        self.ImgTimeBar.color = COLOR_EXECUTION_BAR_MID
    else
        self.ImgTimeBar.color = COLOR_EXECUTION_BAR_LOW
    end
end

function XUiFightPivotCombat:SetTimeBarLength(length)
    local barWidth = self.ImgTimeBar:GetComponent("RectTransform").sizeDelta.x
    local bgWidth = self.ImgTimeBarBg:GetComponent("RectTransform").sizeDelta.x
    local widthOffset = bgWidth - barWidth
    self.ImgTimeBar:GetComponent("RectTransform"):SetSizeDeltaX(length)
    self.ImgTimeBarBg:GetComponent("RectTransform"):SetSizeDeltaX(length + widthOffset)
end

function XUiFightPivotCombat:SetMultiSlashTimes(times)
    if times > MAX_MULTI_SLASH_TIMES then
        XLog.Error("XUiFightPivotCombat:SetMultiSlashTimes times must less than MAX:" .. tostring(MAX_MULTI_SLASH_TIMES))
        return
    end

    if self.MultiSlashDotsActive then
        for i = 1, MAX_MULTI_SLASH_TIMES do
            self.MultiSlashDotImgs[i].gameObject:SetActiveEx(i <= times)
        end
    end

    self.MultiSlashTimes = times
end

function XUiFightPivotCombat:SetMultiSlashDotsActive(active)
    if active then
        for i = 1, self.MultiSlashTimes do
            self.MultiSlashDotImgs[i].gameObject:SetActiveEx(true)
        end
    else
        for i = 1, MAX_MULTI_SLASH_TIMES do
            self.MultiSlashDotImgs[i].gameObject:SetActiveEx(false)
        end
    end

    self.MultiSlashDotsActive = active
end