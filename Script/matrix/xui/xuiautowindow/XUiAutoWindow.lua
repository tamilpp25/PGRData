local XUiAutoWindow = XLuaUiManager.Register(XLuaUi, "UiAutoWindow")

function XUiAutoWindow:OnAwake()
    self:AddListener()
end

function XUiAutoWindow:OnStart(configId)
    self:SetInfo(configId)
end

function XUiAutoWindow:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnGoto, self.OnBtnSkipClick)
    self.BtnBigSkin.CallBack = function() self:OnBtnSkipClick() end
    self.BtnSpineSkin.CallBack = function() self:OnBtnSkipClick() end
end

function XUiAutoWindow:OnBtnCloseClick()
    self:Close()
end

function XUiAutoWindow:OnDestroy()
    if not self.IsSkip then
        XDataCenter.AutoWindowManager.NextAutoWindow()
    end
end

function XUiAutoWindow:OnBtnSkipClick()
    if self.ActiveOver then
        XUiManager.TipText("ActivityAlreadyOver")
        return
    end

    if self.Config.SkipURL and self.Config.SkipURL ~= nil then
        CS.UnityEngine.Application.OpenURL(self.Config.SkipURL)
    elseif self.Config.SkipId and self.Config.SkipId ~= nil then
        XFunctionManager.SkipInterface(self.Config.SkipId)
        self.IsSkip = true
    end
    XDataCenter.AutoWindowManager.StopAutoWindow()
    self:Close()
end

function XUiAutoWindow:SetInfo(configId)
    self.Config = XAutoWindowConfigs.GetAutoWindowConfig(configId)
    self.SkinType = XAutoWindowConfigs.GetAutoWindowSkinType(configId)

    self.PanelBigSkin.gameObject:SetActiveEx(false)
    self.PanelBarSkin.gameObject:SetActiveEx(false)
    self.PanelSpineSkin.gameObject:SetActiveEx(false)

    if self.SkinType == XAutoWindowConfigs.AutoWindowSkinType.BarSkin then
        self.PanelBarSkin.gameObject:SetActiveEx(true)
        --self.RImgCharacterBig:SetRawImage(self.Config.CharacterIcon)
        self.RImgBg:SetRawImage(self.Config.BgIcon)
    elseif self.SkinType == XAutoWindowConfigs.AutoWindowSkinType.BigSkin then
        self.PanelBigSkin.gameObject:SetActiveEx(true)
        self.RImgBgNormal:SetRawImage(self.Config.BgIcon)
        self.RImgBgPress:SetRawImage(self.Config.BgIcon)
    elseif self.SkinType == XAutoWindowConfigs.AutoWindowSkinType.SpineSkin then
        self.PanelSpineSkin.gameObject:SetActiveEx(true)
        self.SpineSkinRoot:LoadPrefab(self.Config.SpineBg)
        if self.Config.BgIcon and self.Config.BgIcon ~= "" then
            self.RImgUiSpineSkin.gameObject:SetActiveEx(true)
            self.RImgUiSpineSkin:SetRawImage(self.Config.BgIcon)
        else
            self.RImgUiSpineSkin.gameObject:SetActiveEx(false)
        end
    end

    --local now = XTime.GetServerNowTimestamp()
    --local openTime = XTime.ParseToTimestamp(self.Config.OpenTime)
    --local closeTime = XTime.ParseToTimestamp(self.Config.CloseTime)
    --
    --if now > openTime and now <= closeTime then
        self:SetOpenInfo()
    --elseif now <= openTime then
    --    self:SetCloseInfo(now)
    --elseif now > closeTime then
    --    self:SetOverInfo(now)
    --end
end

-- 处理活动中
function XUiAutoWindow:SetOpenInfo()
    if self.SkinType == XAutoWindowConfigs.AutoWindowSkinType.BarSkin then
        self.PanelNotOpen.gameObject:SetActive(false)
        self.PanelOpen.gameObject:SetActive(true)

        --self.TxtOpenTitle.text = self.Config.OpenTitle
        --self.TxtOpenTime.text = self.Config.OpenDesc
        local scale = (self.Config.SkipURL == nil and self.Config.SkipId <= 0) and CS.UnityEngine.Vector3.zero or CS.UnityEngine.Vector3.one
        self.BtnGoto.gameObject.transform.localScale = scale
    elseif self.SkinType == XAutoWindowConfigs.AutoWindowSkinType.BigSkin then
        self.PanelNotOpen.gameObject:SetActive(false)
        self.PanelOpen.gameObject:SetActive(false)
    end
end

-- 处理尚未开启活动
function XUiAutoWindow:SetCloseInfo(now)
    self.PanelNotOpen.gameObject:SetActive(true)
    self.PanelOpen.gameObject:SetActive(false)

    --self.TxtTitle.text = self.Config.CloseTitle
    --local format = "MM/dd"
    --self.TxtOpenDay.text = XTime.TimestampToGameDateTimeString(self.Config.OpenTime, format)
    --local leftTime = self.Config.OpenTime - now
    --self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.CHALLENGE)
end

-- 处理活动结束
function XUiAutoWindow:SetOverInfo()
    self.ActiveOver = true
    self:SetOpenInfo()
end