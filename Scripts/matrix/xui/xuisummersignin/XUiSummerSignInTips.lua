local XUiSummerSignInTips = XLuaUiManager.Register(XLuaUi, "UiSummerSignInTips")

local PictureFrame = 4

function XUiSummerSignInTips:OnAwake()
    self:RegisterUiEvents()
end

function XUiSummerSignInTips:OnStart(messageId, isSignIn, cancelCb)
    self.MessageId = messageId
    self.IsSignIn = isSignIn
    self.CancelCb = cancelCb
    self:InitTipsView()
end

function XUiSummerSignInTips:InitTipsView()
    local playName = XPlayer.Name or ""
    local config = XSummerSignInConfigs.GetSummerMessageConfig(self.MessageId)
    self.TxtRewardName.text = config.RewardName
    
    local CharacterHeads = config.CharacterHead
    local HeadLength = #CharacterHeads
    for i = 1, PictureFrame do
        local panel = self["PanelPhoto".. i]
        panel.gameObject:SetActiveEx(i == HeadLength)
    end
    -- 信纸信息
    local panelPhoto = {}
    XTool.InitUiObjectByUi(panelPhoto, self["PanelPhoto" .. HeadLength])
    -- 队伍图片
    panelPhoto.RImgName:SetRawImage(config.TeamPic)
    for i = 1, HeadLength do
        local panelPaper = panelPhoto["RImgXinz" .. i]
        -- 描述
        local txtContent = XUiHelper.TryGetComponent(panelPaper.transform, "TxtContent", "Text")
        txtContent.text = string.format(config.SingleMessage[i], playName)
        -- 名字
        local txtName = XUiHelper.TryGetComponent(panelPaper.transform, "TxtName", "Text")
        txtName.text = config.SingleName[i]
        -- 签名
        local rImgName = XUiHelper.TryGetComponent(panelPaper.transform, "RImgName", "RawImage")
        if rImgName then
            rImgName:SetRawImage(config.SinglePic[i])
        end
        -- 头像
        local rImgHead = XUiHelper.TryGetComponent(panelPaper.transform, "Mask/RawImage", "RawImage")
        rImgHead:SetRawImage(CharacterHeads[i])
    end
    
    self.PanelFree.gameObject:SetActiveEx(self.IsSignIn)
    self.PanelReceived.gameObject:SetActiveEx(not self.IsSignIn)
end

function XUiSummerSignInTips:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTcanchaungBlueLight, self.OnBtnTcanchaungBlueLightClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseWhite, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
end

function XUiSummerSignInTips:OnBtnCloseClick()
    self:Close()
    if self.CancelCb then
        self.CancelCb()
    end
end

function XUiSummerSignInTips:OnBtnTcanchaungBlueLightClick()
    -- 前往研发界面
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DrawCard) then
        return
    end
    if self.CancelCb then
        self.CancelCb()
    end
    XDataCenter.DrawManager.OpenDrawUi(nil, nil, nil, true)
end

return XUiSummerSignInTips