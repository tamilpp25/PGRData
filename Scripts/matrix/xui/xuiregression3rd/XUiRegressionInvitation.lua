
local XUiRegressionInvitation = XLuaUiManager.Register(XLuaUi, "UiRegressionInvitation")

function XUiRegressionInvitation:OnAwake()
    self:InitCb()
end 

function XUiRegressionInvitation:OnStart(onCloseCb)
    self.ViewModel = XDataCenter.Regression3rdManager.GetViewModel()
    self.OnCloseCb = onCloseCb
    self:InitView()
end

function XUiRegressionInvitation:OnEnable()
    self.Super.OnEnable(self)
end

function XUiRegressionInvitation:Close()
    self.Super.Close(self)
    if self.OnCloseCb then
        self.OnCloseCb()
    end
end

function XUiRegressionInvitation:InitCb()
    self:BindExitBtns()
end

function XUiRegressionInvitation:InitView()
    local title = XRegression3rdConfigs.GetClientConfigValue("InvitationContent", 1)
    title = string.format(title, XPlayer.Name)
    
    local line1 = XRegression3rdConfigs.GetClientConfigValue("InvitationContent", 2)
    line1 = XUiHelper.ReplaceTextNewLine(line1)
    local timeStamp = self.ViewModel:GetProperty("_LastOnlineTime")
    local format = string.format("yyyy%sM%sd%s", XUiHelper.GetText("Year"), XUiHelper.GetText("Monthly"), XUiHelper.GetText("Diary"))
    line1 = string.format(line1, XTime.TimestampToLocalDateTimeString(timeStamp, format))
    
    local line2 = XRegression3rdConfigs.GetClientConfigValue("InvitationContent", 3)
    line2 = XUiHelper.ReplaceTextNewLine(line2)
    local timeNowStamp = XTime.GetServerNowTimestamp()
    line2 = string.format(line2, XUiHelper.GetTime(timeNowStamp - timeStamp, XUiHelper.TimeFormatType.RPG_MAKER_GAME))
    
    local tail = XRegression3rdConfigs.GetClientConfigValue("InvitationContent", 4)
    
    self.TxtTitle.text = title
    self.TxtLine1.text = line1
    self.TxtLine2.text = line2
    self.TxtTail.text = tail

    local endTime = self.ViewModel:GetProperty("_ActivityEndTime")
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not XDataCenter.Regression3rdManager.IsOpen() then
            XDataCenter.Regression3rdManager.OnActivityEnd()
        end
    end)
end