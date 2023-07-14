--============
--主界面模式入口控件
--============
local XUiSSBMainEntranceGrid = XClass(nil, "XUiSSBMainEntranceGrid")

function XUiSSBMainEntranceGrid:Ctor(gameObject, mode)
    self.Mode = mode
    XTool.InitUiObjectByUi(self, gameObject)
    self:InitPanels()
end
--============
--初始化面板
--============
function XUiSSBMainEntranceGrid:InitPanels()
    self.BtnTips.CallBack = function() self:OnClickBtnTips() end
    self:InitEntranceNor()
    self:InitEntranceDis()
    self.ImgShadow:SetSprite(self.Mode:GetShadowBgPath())
end
--============
--初始化Normal按钮UI
--============
function XUiSSBMainEntranceGrid:InitEntranceNor()
    self.EntranceNormal = {}
    self.BtnEntranceNor.CallBack = function() self:OnClickBtnEntranceNor() end
    self.BtnEntranceNor.gameObject.name = "BtnEntranceNor" .. self.Mode:GetPriority()
    self.BtnEntranceNor:SetRawImage(self.Mode:GetBgPath())
    self.BtnEntranceNor:SetName(self.Mode:GetName())
    XTool.InitUiObjectByUi(self.EntranceNormal, self.BtnEntranceNor)
    local counter = 1
    while(true) do
        local flag1 = self:SetSprite(self.EntranceNormal["BgIcon" .. counter], self.Mode:GetIcon())
        local flag2 = self:SetSprite(self.EntranceNormal["RImgOrder" .. counter], self.Mode:GetOrderIcon())
        local flag3 = self:SetColor(self.EntranceNormal["RImgNameBg" .. counter], self.Mode:GetNamePlateColor())
        if (not flag1) or (not flag2) or (not flag3) then break end
        counter = counter + 1
    end
end
--============
--初始化解锁按钮UI
--============
function XUiSSBMainEntranceGrid:InitEntranceDis()
    self.EntranceDisable = {}
    self.BtnEntranceDis.CallBack = function() self:OnClickBtnEntranceDis() end
    self.BtnEntranceDis.gameObject.name = "BtnEntranceDis" .. self.Mode:GetPriority()
    self.BtnEntranceDis:SetRawImage(self.Mode:GetBgPath())
    --self.BtnEntranceDis:SetName() --设置可解锁文字
    XTool.InitUiObjectByUi(self.EntranceDisable, self.BtnEntranceDis)
    local counter = 1
    while(true) do
        local flag = self:SetSprite(self.EntranceDisable["BgIcon" .. counter], self.Mode:GetIcon())
        if not flag then break end
        counter = counter + 1
    end
    self.EntranceDisable.TxtLeftTime.text = ""
end
--============
--设置组件RawImage的图
--============
function XUiSSBMainEntranceGrid:SetSprite(Image, path)
    if not Image then return false end
    Image:SetSprite(path)
    return true
end
--============
--设置组件RawImage的色值
--============
function XUiSSBMainEntranceGrid:SetColor(rawImage, color)
    if not rawImage then return false end 
    rawImage.color = self.Mode:GetNamePlateColor()
    return true
end
--============
--界面显示时
--============
function XUiSSBMainEntranceGrid:OnEnable()
    self:RefreshEntranceStatus()
    self:RefreshProgress()
    self:RefreshPlaying()
end
--============
--刷新入口按钮状态
--============
function XUiSSBMainEntranceGrid:RefreshEntranceStatus()
    if not self.Mode then
        return
    end
    if self.Red then
        self.Red.gameObject:SetActiveEx(false)
    end
    --首先判定本地有没解锁记录
    --判定本地有没解锁记录
    local unlockFlag = XSaveTool.GetData(XPlayer.Id .. XSuperSmashBrosConfig.ModeUnlockSaveStr .. self.Mode:GetId() .. self.Mode:GetActivityId())
    if unlockFlag then
        --有解锁纪录，说明模式已经解锁
        self.TxtProgress.gameObject:SetActiveEx(true)
        self.BtnEntranceNor.gameObject:SetActiveEx(true)
        self.BtnEntranceDis.gameObject:SetActiveEx(false)
    else
        --没解锁记录,普通按钮隐藏
        self.TxtProgress.gameObject:SetActiveEx(false)
        self.BtnEntranceNor.gameObject:SetActiveEx(false)
        self.BtnEntranceDis.gameObject:SetActiveEx(true)
        --再判定现在模式的可解锁状态
        if not self.Mode:CheckUnlock() then
            --未解锁，则显示倒计时
            self.BtnEntranceDis:SetButtonState(CS.UiButtonState.Disable)
            self:SetTimer()
        else
            --已解锁，则显示可解锁按钮
            self.BtnEntranceNor:SetButtonState(CS.UiButtonState.Normal)
            if self.Red then
                self.Red.gameObject:SetActiveEx(true)
            end
        end
    end
end
--============
--刷新入口进行中状态文本
--============
function XUiSSBMainEntranceGrid:RefreshPlaying()
    self.TxtPlaying.gameObject:SetActiveEx(self.Mode:CheckIsPlaying())
end
--============
--设置解锁时间计时器
--============
function XUiSSBMainEntranceGrid:SetTimer()
    self.EntranceDisable.TxtLeftTime.text = XUiHelper.GetTime(self:GetLeftTime(), XUiHelper.TimeFormatType.ACTIVITY)
    self.Timer = XScheduleManager.ScheduleForever(function()
            if XTool.UObjIsNil(self.BtnEntranceDis) then self:RemoveTimer() return end 
            local leftTime = self:GetLeftTime()
            if leftTime <= 0 then
                self.EntranceDisable.TxtLeftTime.text = 0
                self:RemoveTimer()
                self.BtnEntranceDis:SetButtonState(CS.UiButtonState.Normal)
                if self.Red then
                    self.Red.gameObject:SetActiveEx(true)
                end
                return
            end
            self.EntranceDisable.TxtLeftTime.text = XUiHelper.GetTime(self:GetLeftTime(), XUiHelper.TimeFormatType.ACTIVITY)
        end, 1)
end
--============
--获取解锁剩余时间(秒数)
--============
function XUiSSBMainEntranceGrid:GetLeftTime()
    local now = XTime.GetServerNowTimestamp()
    local startTime = XDataCenter.SuperSmashBrosManager.GetActivityStartTime()
    local openTime = self.Mode:GetOpenCondition()
    local leftTime = startTime + openTime - now
    return leftTime
end
--============
--移除解锁时间计时器
--============
function XUiSSBMainEntranceGrid:RemoveTimer()
    if not self.Timer then return end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end
--============
--解锁模式
--============
function XUiSSBMainEntranceGrid:UnlockMode()
    --再检查一次开放时间
    if not self.Mode:CheckUnlock() then return end
    self.TxtProgress.gameObject:SetActiveEx(true)
    self.BtnEntranceNor.gameObject:SetActiveEx(true)
    self.BtnEntranceDis.gameObject:SetActiveEx(false)
    XSaveTool.SaveData(XPlayer.Id .. XSuperSmashBrosConfig.ModeUnlockSaveStr .. self.Mode:GetId() .. self.Mode:GetActivityId(), true)
    XLuaUiManager.SetMask(true)
    --延迟一点播放动画再弹窗
    XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.Open("UiSuperSmashBrosModeRules", self.Mode)
            XLuaUiManager.SetMask(false)
            end, 750)
    self.Red.gameObject:SetActiveEx(false) --提示可解锁的红点取消
end
--============
--设置进度条
--============
function XUiSSBMainEntranceGrid:RefreshProgress()
    self.ImgProgress.fillAmount = self.Mode:GetPassMonsters() / self.Mode:GetTotalMonsters()
    local text = string.gsub(CSXTextManagerGetText("SuperSmashProgressText", self.Mode:GetPassMonsters(), self.Mode:GetTotalMonsters()), "\\n", "\n")
    self.TxtProgress.text = text
end
--============
--界面隐藏时
--============
function XUiSSBMainEntranceGrid:OnDisable()
    self:RemoveTimer()
end
--============
--点击提示按钮
--============
function XUiSSBMainEntranceGrid:OnClickBtnTips()
    XLuaUiManager.Open("UiSuperSmashBrosModeRules", self.Mode)
end
--============
--点击普通入口按钮
--============
function XUiSSBMainEntranceGrid:OnClickBtnEntranceNor()
    if not XDataCenter.SuperSmashBrosManager.CheckOtherModeNotPlaying(self.Mode:GetPriority()) then
        XUiManager.TipText("SSBOtherModeIsPlaying")
        return
    end
    if self.Mode:CheckIsPlaying() then --若此模式正在进行就进入战斗准备界面
        XLuaUiManager.Open("UiSuperSmashBrosReady")
    else
        if self.Mode:GetIsLinearStage() then
            XLuaUiManager.Open("UiSuperSmashBrosPick", self.Mode, nil, nil)
        else
            XLuaUiManager.Open("UiSuperSmashBrosSelectStage", self.Mode)
        end
    end
end
--============
--点击解锁按钮
--============
function XUiSSBMainEntranceGrid:OnClickBtnEntranceDis()
    if not self.Mode:CheckUnlock() then
        XUiManager.TipText("SSBNotReachOpenTime")
        return
    end
    self:UnlockMode()
end
--============
--显示
--============
function XUiSSBMainEntranceGrid:Show()
    self.GameObject:SetActiveEx(true)
end
--============
--隐藏
--============
function XUiSSBMainEntranceGrid:Hide()
    self.GameObject:SetActiveEx(false)
end
--============
--销毁时
--============
function XUiSSBMainEntranceGrid:OnDestroy()
    
end
return XUiSSBMainEntranceGrid