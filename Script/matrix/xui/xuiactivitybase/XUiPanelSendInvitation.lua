--
--Author: wujie
--Note: 回归活动发送邀请界面
local XUiPanelSendInvitation = XClass(nil, "XUiPanelSendInvitation")

local XUiGridSendInvitation = require("XUi/XUiActivityBase/XUiGridSendInvitation")

function XUiPanelSendInvitation:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.GridRewardList = {
        XUiGridSendInvitation.New(self.GridReward1, rootUi),
        XUiGridSendInvitation.New(self.GridReward2, rootUi),
        XUiGridSendInvitation.New(self.GridReward3, rootUi),
    }

    self.BtnShareList = {
        self.BtnShare1,
        self.BtnShare2,
        self.BtnShare3,
        self.BtnShare4,
        self.BtnShare5,
    }

    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
    self.RootUi:BindHelpBtnOnly(self.BtnHelp)
    self.BtnCopy.CallBack = function() self:OnBtnCopyClick() end
end

function XUiPanelSendInvitation:UpdateHeadContent()
    if not self.ActivityId or not self.ActivityCfg then return end

    local startTime, endTime = XRegressionConfigs.GetActivityTime(self.ActivityId)
    if startTime and endTime then
        local formatStr = "yyyy-MM-dd HH:mm"
        self.TxtStartTime.text = XTime.TimestampToGameDateTimeString(startTime, formatStr)
        self.TxtEndTime.text = XTime.TimestampToGameDateTimeString(endTime, formatStr)
    end

    local helpId = self.ActivityCfg.Params[2]
    self.BtnHelp.gameObject:SetActiveEx(helpId ~= nil and helpId ~= 0)

    self.TxtActivityTitle.text = self.ActivityCfg.ActivityTitle
    local matchedStr = "\\n"
    local replacedStr = "\n"
    self.TxtActivityDesc.text = string.gsub(self.ActivityCfg.ActivityDes, matchedStr, replacedStr)
end

function XUiPanelSendInvitation:UpdateInvitationContent()
    if not self.InvitationTemplate then return end
    local invitationTemplate = self.InvitationTemplate
    local maxInvitationCount = XRegressionConfigs.GetInvitationRewardMaxPeople(invitationTemplate.Id)
    local curInvitationCount = XDataCenter.RegressionManager.GetAcceptMyInvitationCount()
    self.TxtCurInvitationNum.text = math.min(curInvitationCount, maxInvitationCount)
    self.TxtMaxInvitationNum.text = maxInvitationCount
    self.TxtInvitationCode.text = XDataCenter.RegressionManager.GetInvitationCode()
    local invitationRewardIdList = invitationTemplate.InviteRewardId
    local rewardCount = #invitationRewardIdList
    for i, grid in ipairs(self.GridRewardList) do
        if i > rewardCount then
            grid.GameObject:SetActiveEx(false)
        else
            grid.GameObject:SetActiveEx(true)
            grid:Refresh(invitationRewardIdList[i])
        end
    end
end

function XUiPanelSendInvitation:UpdateShare()
    --当 1.活动配置存在 2.服务端未屏蔽邀请码分享 3.当前玩家所在服务器可以进行分享 4.目前仅限英雄互娱的包 时 可以分享
    if self.ActivityCfg
    and not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.InvitationCodeShare)
    and XPlatformShareConfigs.IsPlatformShareOpen(XPlayer.ServerId)
    and CS.XAppPlatBridge.GetAppPackageName() == XAppConfigs.PackageName.Hero then
        self.PanelShareBtn.gameObject:SetActiveEx(true)
        local platformShareId = self.ActivityCfg.Params[3]
        local platformShareTemplate = XPlatformShareConfigs.GetPlatformShareTemplate(platformShareId)
        for i, btn in ipairs(self.BtnShareList) do
            if platformShareTemplate.PlatformType[i] then
                btn.gameObject:SetActiveEx(true)
                btn:SetSprite(platformShareTemplate.PlatformIcon[i])
                btn:SetName(platformShareTemplate.PlatformShowedText[i])
                btn.CallBack = function() self:OnBtnShareClick(platformShareTemplate.PlatformType[i], platformShareTemplate) end
            else
                btn.gameObject:SetActiveEx(false)
            end
        end
    else
        self.PanelShareBtn.gameObject:SetActiveEx(false)
    end
end

function XUiPanelSendInvitation:Refresh(activityCfg)
    self.ActivityCfg = activityCfg
    XDataCenter.RegressionManager.HandleGetInvitationCodeInfoRequest(true, function() self:OnUpdateInfo() end)

    self:UpdateShare()
end

function XUiPanelSendInvitation:OnShareCallback(result)
    if result == XPlatformShareConfigs.ShareResult.Failed then
        XUiManager.TipError(CS.XTextManager.GetText("RegressionSendInvitationShareFailed"))
    end
end

function XUiPanelSendInvitation:OnBtnHelpClick()
    if not self.ActivityCfg then return end
    local helpId = self.ActivityCfg.Params[2]
    local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
    XUiManager.ShowHelpTip(template.Function)
end

function XUiPanelSendInvitation:OnBtnCopyClick()
    XUiManager.TipError(CS.XTextManager.GetText("RegressionAcceptInvitationCodeCopy"))
    CS.UnityEngine.GUIUtility.systemCopyBuffer = self.TxtInvitationCode.text
end

function XUiPanelSendInvitation:OnBtnShareClick(targetPlatformType, platformShareTemplate)
    local invitationCode = XDataCenter.RegressionManager.GetInvitationCode()
    if string.IsNilOrEmpty(invitationCode) then return end
    local shareText = string.format(platformShareTemplate.ShareParam[1], invitationCode)
    XPlatformShareManager.Share(platformShareTemplate.ShareType, targetPlatformType, function(result) self:OnShareCallback(result) end, shareText)
end

function XUiPanelSendInvitation:OnUpdateInfo()
    if not self.ActivityId or self.InvitationTemplate then
        local activityId = XDataCenter.RegressionManager.GetInvitationActivityId()
        local invitationTemplateId = XRegressionConfigs.GetInvitationTemplateId(activityId)
        local invitationTemplate = XRegressionConfigs.GetInvitationTemplate(invitationTemplateId)
        self.ActivityId = activityId
        self.InvitationTemplate = invitationTemplate
        self:UpdateHeadContent()
        self:UpdateInvitationContent()
    else
        local rewardCount = #self.InvitationTemplate.InviteRewardId
        for i, grid in ipairs(self.GridRewardList) do
            if i <= rewardCount then
                grid:UpdateGetStatus()
            end
        end
    end
end

return XUiPanelSendInvitation