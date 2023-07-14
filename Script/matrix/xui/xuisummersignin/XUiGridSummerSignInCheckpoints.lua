local XUiGridSummerSignInCheckpoints = XClass(nil, "XUiGridSummerSignInCheckpoints")

function XUiGridSummerSignInCheckpoints:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
end

function XUiGridSummerSignInCheckpoints:Refresh(messageId)
    self.MessageId = messageId
    self:RefreshView()
end

function XUiGridSummerSignInCheckpoints:RefreshView()
    local config = XSummerSignInConfigs.GetSummerMessageConfig(self.MessageId)
    local isSignIn = self:GetIsSignIn()
    
    local headIcon -- 刷新头像
    local teamPicIcon -- 队伍名
    local singlePicIcon = config.SinglePic[1] -- 签名
    if isSignIn then
        headIcon = config.CharacterHead[1] -- 只取第一个头像图片
        teamPicIcon = config.TeamPic
    else
        headIcon = config.UnlockHead
        teamPicIcon = config.UnlockTeamPic
    end
    self.RImgHeadNormal:SetRawImage(headIcon)
    self.RImgHeadPress:SetRawImage(headIcon)
    self.RImgNameNormal:SetRawImage(singlePicIcon)
    self.RImgNamePress:SetRawImage(singlePicIcon)
    self.BtnClick:SetRawImage(teamPicIcon)
    
    -- 是否已签到
    self.NormalPanelCheck.gameObject:SetActiveEx(not isSignIn)
    self.NormalPanelHaveCheck.gameObject:SetActiveEx(isSignIn)
    self.PressPanelCheck.gameObject:SetActiveEx(not isSignIn)
    self.PressPanelHaveCheck.gameObject:SetActiveEx(isSignIn)
end

function XUiGridSummerSignInCheckpoints:GetIsSignIn()
    return XDataCenter.SummerSignInManager.CheckCanMsgIdList(self.MessageId)
end

function XUiGridSummerSignInCheckpoints:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

-- 选择
function XUiGridSummerSignInCheckpoints:OnBtnClick()
    if not self:GetIsSignIn() and XDataCenter.SummerSignInManager.CheckSurplusTimes() then
        XUiManager.TipText("SummerSignInViewCountFinishTip")
        return
    end
    
    if self.ClickCb then
        self.ClickCb(self)
    end
end

return XUiGridSummerSignInCheckpoints