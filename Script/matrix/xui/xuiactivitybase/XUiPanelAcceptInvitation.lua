--
--Author: wujie
--Note: 回归活动接受邀请界面
local XUiPanelAcceptInvitation = XClass(nil, "XUiPanelAcceptInvitation")

local XUiGridAcceptInvitation = require("XUi/XUiActivityBase/XUiGridAcceptInvitation")

function XUiPanelAcceptInvitation:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.GridRewardList = {
        XUiGridAcceptInvitation.New(self.GridReward1, rootUi),
        XUiGridAcceptInvitation.New(self.GridReward2, rootUi),
        XUiGridAcceptInvitation.New(self.GridReward3, rootUi),
    }
    self.InputField.placeholder.text = CS.XTextManager.GetText("RegressionAcceptInvitationDefaultText")
    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
    self.rootUi:BindHelpBtnOnly(self.BtnHelp)
    self.BtnCanGet.CallBack = function() self:OnBtnCanGetClick() end
    self.InputField.onValueChanged:AddListener(function() self:OnInputFieldTextChanged() end)
end

function XUiPanelAcceptInvitation:UpdateHeadContent()
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

function XUiPanelAcceptInvitation:UpdateInvitationContent(index)
    if not self.UseCodeRewardIdList then return end

    local isGet = XDataCenter.RegressionManager.IsUseInvitationCodeRewardHaveGet(index)
    local rewardList = XRewardManager.GetRewardList(self.UseCodeRewardIdList[index])
    local rewardCount = #rewardList
    for i, grid in ipairs(self.GridRewardList) do
        if i > rewardCount then
            grid.GameObject:SetActiveEx(false)
        else
            grid.GameObject:SetActiveEx(true)
            grid:Refresh(rewardList[i])
            grid:UpdateGetStatus(isGet)
        end
    end
end

function XUiPanelAcceptInvitation:UpdateBtnStatus(index)
    local isGet = XDataCenter.RegressionManager.IsUseInvitationCodeRewardHaveGet(index)
    if isGet then
        self.BtnCanGet.gameObject:SetActiveEx(false)
        self.ImgNotGet.gameObject:SetActiveEx(false)
        self.ImgHaveGet.gameObject:SetActiveEx(true)
        self.ImgInputFieldBg.gameObject:SetActiveEx(false)
    else
        self.ImgInputFieldBg.gameObject:SetActiveEx(true)
        self.ImgHaveGet.gameObject:SetActiveEx(false)
        local invitationCode = self.InputField.text
        if string.IsNilOrEmpty(invitationCode) then
            self.BtnCanGet.gameObject:SetActiveEx(false)
            self.ImgNotGet.gameObject:SetActiveEx(true)
        else
            self.BtnCanGet.gameObject:SetActiveEx(true)
            self.ImgNotGet.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelAcceptInvitation:Refresh(activityCfg)
    self.ActivityCfg = activityCfg
    local activityId = XDataCenter.RegressionManager.GetInvitationActivityId()
    local invitationTemplateId = XRegressionConfigs.GetInvitationTemplateId(activityId)
    local invitationTemplate = XRegressionConfigs.GetInvitationTemplate(invitationTemplateId)
    self.ActivityId = activityId
    self.UseCodeRewardIdList = invitationTemplate.UseCodeReward

    self:UpdateHeadContent()
    for i, _ in ipairs(self.UseCodeRewardIdList) do
        if not XDataCenter.RegressionManager.IsUseInvitationCodeRewardHaveGet(i) then
            self.ShowedRewardIndex = i
            break
        end
    end

    self.ShowedRewardIndex = self.ShowedRewardIndex or #self.UseCodeRewardIdList
    self:UpdateInvitationContent(self.ShowedRewardIndex)
    self:UpdateBtnStatus(self.ShowedRewardIndex)
end

function XUiPanelAcceptInvitation:OnBtnHelpClick()
    if not self.ActivityCfg then return end
    local helpId = self.ActivityCfg.Params[2]
    local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
    XUiManager.ShowHelpTip(template.Function)
end

function XUiPanelAcceptInvitation:OnBtnCanGetClick()
    if not XDataCenter.RegressionManager.IsInvitationActivityInTime() then
        XUiManager.TipError(CS.XTextManager.GetText("RegressionInvitationActivityOver"))
        return
    end

    local invitationCode = self.InputField.text
    if string.IsNilOrEmpty(invitationCode) then return end
    if XDataCenter.RegressionManager.GetInvitationCode() == invitationCode then
        XUiManager.TipError(CS.XTextManager.GetText("RegressionAcceptInvitationCodeNotUseSelf"))
        return
    elseif XDataCenter.RegressionManager.IsInvitationCodeHaveUse(invitationCode) then
        XUiManager.TipError(CS.XTextManager.GetText("RegressionAcceptInvitationCodeHaveUse"))
        return
    end
    XDataCenter.RegressionManager.HandleUseInvitationCodeRequest(invitationCode, function()
        self:OnUseInviteCode()
    end)
end

function XUiPanelAcceptInvitation:OnInputFieldTextChanged()
    if self.ShowedRewardIndex then
        self:UpdateBtnStatus(self.ShowedRewardIndex)
    end
end

function XUiPanelAcceptInvitation:OnUseInviteCode()
    if not self.UseCodeRewardIdList or not self.ShowedRewardIndex then return end
    self.ShowedRewardIndex = math.min(self.ShowedRewardIndex, #self.UseCodeRewardIdList)
    self:UpdateInvitationContent(self.ShowedRewardIndex)
    self:UpdateBtnStatus(self.ShowedRewardIndex)
end

return XUiPanelAcceptInvitation