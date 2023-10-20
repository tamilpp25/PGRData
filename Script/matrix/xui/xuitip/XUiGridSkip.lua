XUiGridSkip = XClass(nil, "XUiGridSkip")

function XUiGridSkip:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self:InitAutoScript()
end

function XUiGridSkip:InitAutoScript()
    XTool.InitUiObject(self)
    self.BtnSkip.CallBack = function()
        XFunctionManager.SkipInterface(self.SkipId, self.Args)
        if self.SkipCb then
            self.SkipCb()
        end
    end
end

function XUiGridSkip:Refresh(skipId, hideSkipBtn, skipCb, ...)
    if not skipId then
        self.GameObject:SetActive(false)
        return
    end
    self.GameObject:SetActive(true)

    self.SkipId = skipId
    self.SkipCb = skipCb
    self.Args = {...}

    local canSkip = XFunctionManager.IsCanSkip(skipId) and not XFunctionManager.CheckSkipPanelIsLoad(skipId)
    local template = XFunctionConfig.GetSkipList(skipId)
    --时间控制跳转显示
    if XTool.IsNumberValid(template.TimeId) then
        local isoutTime=XFunctionManager.CheckInTimeByTimeId(template.TimeId,true)
        if not isoutTime then
            self.GameObject:SetActiveEx(false)
            return
        end
    else
        local now=XTime.GetServerNowTimestamp()
        local startTime=XTime.ParseToTimestamp(template.StartTime)
        local endTime=XTime.ParseToTimestamp(template.CloseTime)
        local lateForBegin= XTool.IsNumberValid(startTime) and now>=startTime or not startTime
        local earlyForEnd=XTool.IsNumberValid(endTime) and now<endTime or not endTime
        if not(lateForBegin and earlyForEnd) then
            self.GameObject:SetActiveEx(false)
            return
        end
    end
    self.TxtNameOn.text = template.Explain
    if hideSkipBtn then
        self.BtnSkip.gameObject:SetActive(false)
    else
        self.BtnSkip.gameObject:SetActive(true)
        self.BtnSkip:SetDisable(not canSkip,canSkip)
    end
end