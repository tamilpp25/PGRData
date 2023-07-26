local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiFubenExperimentBanner = XClass(nil, "XUiFubenExperimentBanner")
local CSXTextManagerGetText = CS.XTextManager.GetText
function XUiFubenExperimentBanner:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsLock = false
    self.IsShowPass = false
    self.LockText = ""
end

function XUiFubenExperimentBanner:Init(index, callback)
    self.Index = index
    self.Callback = callback
    self:InitUiObjects()
    self.TrialLevelInfo = {}
end

function XUiFubenExperimentBanner:InitUiObjects()
    XTool.InitUiObject(self)
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnModelSwitch, self.OnBtnModelSwitchClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self.OnBtnEnter)
end

function XUiFubenExperimentBanner:RegisterListener(uiNode, eventName, func)
    if not uiNode then return end
    local key = eventName .. uiNode:GetHashCode()
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiBtnTab:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiFubenExperimentBanner:OnBtnModelSwitchClick()
    if self.TrialLevelInfo.Type == XDataCenter.FubenExperimentManager.TrialLevelType.Switch then
        if self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.Signle then
            self.CurType = XDataCenter.FubenExperimentManager.TrialLevelType.Mult
        else
            self.CurType = XDataCenter.FubenExperimentManager.TrialLevelType.Signle
        end
        XDataCenter.FubenExperimentManager.RecordMode(self.TrialLevelInfo.MultStageId,self.CurType)
        self:UpdateType()
    end
end

function XUiFubenExperimentBanner:OnBtnEnter()
    self:CheckLock()
    if self.IsLock then
        XUiManager.TipError(self.LockText)
        return
    end
    self.Callback(self.Index, self.CurType)
end

function XUiFubenExperimentBanner:UpdateBanner(trialLevelInfo)
    self.TrialLevelInfo = trialLevelInfo
    self.CurType = trialLevelInfo.Type
    if self.TrialLevelInfo.Type ~= XDataCenter.FubenExperimentManager.TrialLevelType.Switch then
        self.BtnModelSwitch.gameObject:SetActiveEx(false)
    else
        self.BtnModelSwitch.gameObject:SetActiveEx(true)
        self.CurType = XDataCenter.FubenExperimentManager.GetRecordMode(self.TrialLevelInfo.MultStageId)
    end
    self.TxtLevelName.text = trialLevelInfo.Name
    self.Back:SetRawImage(trialLevelInfo.Ico)
    self:UpdateType()
    self:CheckLock()
    self:CheckShowPass()
    self:CheckProgress()
    self:CheckRedPoint()
    self:UpdateTime()
end

function XUiFubenExperimentBanner:UpdateType()
    self.ModelIconSingle.gameObject:SetActiveEx(false)
    self.ModelIconTeam.gameObject:SetActiveEx(false)
    self.ImageSingle.gameObject:SetActiveEx(false)
    self.ImageTeam.gameObject:SetActiveEx(false)
    self.PanelImgJindu.gameObject:SetActiveEx(false)

    if self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.Signle or self.CurType == XDataCenter.FubenExperimentManager.TrialLevelType.SkinTrial then
        self.ModelIconSingle.gameObject:SetActiveEx(true)
        self.ImageSingle.gameObject:SetActiveEx(true)
    else
        self.ModelIconTeam.gameObject:SetActiveEx(true)
        self.ImageTeam.gameObject:SetActiveEx(true)
    end

    if self.TrialLevelInfo.StarReward and self.TrialLevelInfo.StarReward > 0 then
        self.PanelImgJindu.gameObject:SetActiveEx(true)
    end
end

function XUiFubenExperimentBanner:CheckLock()
    local conditionIds = XDataCenter.FubenExperimentManager.GetStageCondition(self.TrialLevelInfo.Id)
    local ret = true
    local desc = ""
    for _, v in pairs(conditionIds) do
        if v ~= 0 then
            ret, desc = XConditionManager.CheckCondition(v)
            if not ret then
                break
            end
        end
    end
    self.IsLock = not ret
    self.PaenlLock.gameObject:SetActiveEx(not ret)
    self.TxtLock.text = desc
    self.LockText = desc
end

function XUiFubenExperimentBanner:CheckShowPass()
    if self.TrialLevelInfo.StarReward and self.TrialLevelInfo.StarReward > 0 then
        self.PanelUse.gameObject:SetActiveEx(false)
        return
    end

    local showPass = XDataCenter.FubenExperimentManager.GetStageShowPass(self.TrialLevelInfo.Id)
    local finishExperimentIds = XDataCenter.FubenExperimentManager.GetFinishExperimentIds()
    self.PanelUse.gameObject:SetActiveEx(false)

    for _, v in pairs(finishExperimentIds) do
        if v == self.TrialLevelInfo.Id then
            self.PanelUse.gameObject:SetActiveEx(showPass ~= nil and showPass > 0)
        end
    end
end

function XUiFubenExperimentBanner:CheckProgress()
    if not self.TrialLevelInfo.StarReward or self.TrialLevelInfo.StarReward == 0 then
        return
    end

    local curStarNum, maxStarNum = XDataCenter.FubenExperimentManager.GetExperimentStarProgressById(self.TrialLevelInfo.Id)
    self.ImgPercent.fillAmount = curStarNum / maxStarNum
    self.TxtPercentNormal.text = CSXTextManagerGetText("FuBenExperimentProgress", curStarNum, maxStarNum)
end

function XUiFubenExperimentBanner:CheckRedPoint()
    if self.RedPoint then
        self.RedPoint.gameObject:SetActiveEx(false)
        if self.TrialLevelInfo then
            if self.RedPointId then
                XRedPointManager.RemoveRedPointEvent(self.RedPointId)
            end
            self.RedPointId = XRedPointManager.AddRedPointEvent(self.RedPoint, self.OnCheckRedPoint, self, { XRedPointConditions.Types.CONDITION_EXPERIMENT_CHAPTER_REWARD }, self.TrialLevelInfo, true)
        end
    end
end

function XUiFubenExperimentBanner:OnCheckRedPoint(count)
    self.RedPoint.gameObject:SetActiveEx(count >= 0)
end

function XUiFubenExperimentBanner:UpdateTime()
    if self.TxtTime then
        local isVisible = XFunctionManager.CheckInTimeByTimeId(self.TrialLevelInfo.TimeId)
        self.TxtTime.gameObject:SetActiveEx(isVisible)
        if isVisible then
            local nowTime = XTime.GetServerNowTimestamp()
            local endTime = XFunctionManager.GetEndTimeByTimeId(self.TrialLevelInfo.TimeId)
            local timeStr = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
            local text = CSXTextManagerGetText("ActivityBriefLeftTime", timeStr)
            self.TxtTime.text = text
        end
    end
end

return XUiFubenExperimentBanner