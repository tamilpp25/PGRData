local XUiPanelPlayerExp = require("XUi/XUiPlayer/XUiPanelPlayerExp")
local XUiPanelSetName = require("XUi/XUiPlayer/XUiPanelSetName")
local XUiPanelSetBirthday = require("XUi/XUiPlayer/XUiPanelSetBirthday")
local XUiPanelPlayerGloryExp = require("XUi/XUiPlayer/XUiPanelPlayerGloryExp")
local CustomerServiceUrl = CS.XGame.ClientConfig:GetString("CustomerServiceUrl") or ""
local MaxSignLength = CS.XGame.ClientConfig:GetInt("MaxSignLength")
local MODE_LOOP = 1
local DefaultAssistCharacterId = 1021001 -- 默认支援角色露西亚
--============
--新玩家信息界面玩家信息面板
--============
local XUiPanelPlayerInfoEx = XClass(XUiNode, "XUiPanelPlayerInfoEx")

function XUiPanelPlayerInfoEx:OnStart()
    self:InitAutoScript()
    self.PlayAnimation = function(s, ...) self.Parent:PlayAnimation(...) end
    self.ShowSetting = function() self.Parent:ShowSetting() end
    self.PanelSetNameInst = XUiPanelSetName.New(self.PanelSetName.gameObject, self)
    self.PanelSetBirthdayInst = XUiPanelSetBirthday.New(self.PanelSetBirthday.gameObject, self)
    
    self.DefaultText = CS.XTextManager.GetText("CharacterSignTip")

    self.TxtVersion.text = CS.XRemoteConfig.DocumentVersion
    self.TxtServerName.text = XServerManager.GetCurServerName()
    self.PanelServerInfo.gameObject:SetActiveEx(false)

    self.BtnFeedback.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Feedback))
    self.PanelDuihuan.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.ExchangeCode))

    self:AddRedPointEvent(self.ImgSetNameTag, self.OnCheckSetName, self, { XRedPointConditions.Types.CONDITION_PLAYER_SETNAME })
    if self.ImgExhibitionNew then
        self:AddRedPointEvent(self.ImgExhibitionNew, self.OnCheckExhibition, self, { XRedPointConditions.Types.CONDITION_EXHIBITION_NEW })
    end
    self:AddRedPointEvent(self.NewHead, self.OnCheckHeadPortrait, self, { XRedPointConditions.Types.CONDITION_HEADPORTRAIT_RED })
    self:AddRedPointEvent(self.BtnArchive, self.OnCheckArchive, self, { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_ALL, XRedPointConditions.Types.CONDITION_ARCHIVE_WEAPON, XRedPointConditions.Types.CONDITION_ARCHIVE_AWARENESS, XRedPointConditions.Types.CONDITION_ARCHIVE_CG_ALL })
    self:AddRedPointEvent(self.BtnBirModify, self.OnCheckBirthDay, self, { XRedPointConditions.Types.CONDITION_PLAYER_BIRTHDAY })
    self:AddRedPointEvent(self.BtnFeedback, self.OnCheckFeedback, self, { XRedPointConditions.Types.CONDITION_FEEDBACK_RED })
    self._GenderSettingReddotEventId = self:AddRedPointEvent(self.BtnGenderSettings, self.OnCheckGenderSettings, self, { XRedPointConditions.Types.CONDITION_PLAYER_GENDERSET })
    self:UpdatePlayerLevelInfo()
end

function XUiPanelPlayerInfoEx:OnEnable()
    self:ResumeAnimation()
    self:UpdatePlayerInfo()
    XEventManager.AddEventListener(XEventId.EVENT_PLAYER_SET_BIRTHDAY, self.SetBirthday, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLAYER_GENER_CHANGED, self.UpdatePlayerGender, self)
end

function XUiPanelPlayerInfoEx:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLAYER_SET_BIRTHDAY, self.SetBirthday, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLAYER_GENER_CHANGED, self.UpdatePlayerGender, self)
end

---
--- 记录动画的播放进度与状态，避免切换到新界面再切回来时动画中断
function XUiPanelPlayerInfoEx:RecordAnimation()
    -- 荣耀勋阶循环
    if self.PanelPlayerGloryExpLoop.state == CS.UnityEngine.Playables.PlayState.Playing then
        self.PanelPlayerGloryExpLoopTime = self.PanelPlayerGloryExpLoop.time
    end
    -- 普通经验循环
    if self.PanelPlayerExpLoop.state == CS.UnityEngine.Playables.PlayState.Playing then
        self.PanelPlayerExpLoopTime = self.PanelPlayerExpLoop.time
    end

    -- 解锁荣耀勋阶
    if self.PanelPlayerGloryExpEnable.state == CS.UnityEngine.Playables.PlayState.Playing then
        self.PanelPlayerGloryExpEnablePlaying = true
    end
end

---
--- 恢复动画播放
function XUiPanelPlayerInfoEx:ResumeAnimation()
    -- 荣耀勋阶循环
    if self.PanelPlayerGloryExpLoopTime then
        self.PanelPlayerGloryExpLoop.initialTime = self.PanelPlayerGloryExpLoopTime
        self.PanelPlayerGloryExpLoop:Play()
        self.PanelPlayerGloryExpLoopTime = nil
    end
    -- 普通经验循环
    if self.PanelPlayerExpLoopTime then
        self.PanelPlayerExpLoop.initialTime = self.PanelPlayerExpLoopTime
        self.PanelPlayerExpLoop:Play()
        self.PanelPlayerExpLoopTime = nil
    end

    -- 解锁荣耀勋阶中断后直接播放循环动画,需要把解锁动画的时间调成最后，不然界面会卡在动画中断处
    if self.PanelPlayerGloryExpEnablePlaying and not self.FinishedPanelPlayerGloryExpEnable then
        -- 解锁动画播放到最后
        self.PanelPlayerGloryExpEnable.initialTime = self.PanelPlayerGloryExpEnable.duration
        self.PanelPlayerGloryExpEnable:Play()
        self.FinishedPanelPlayerGloryExpEnable = true

        self:PlayAnimation("PanelPlayerGloryExpLoop")
        self.PanelPlayerGloryExpLoop.extrapolationMode = MODE_LOOP
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelPlayerInfoEx:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelPlayerInfoEx:AutoInitUi()
    self.PanelRight = self.Transform:Find("PanelRight")
    self.PanelCorps = self.Transform:Find("PanelRight/PanelCorps")
    self.TxtCorps = self.Transform:Find("PanelRight/PanelCorps/TxtCorps"):GetComponent("Text")
    self.PanelInfo = self.Transform:Find("PanelRight/PanelInfo")
    self.PanelRole = self.Transform:Find("PanelRight/PanelInfo/PanelRole")
    self.BtnRoleHeadImg = self.Transform:Find("PanelRight/PanelInfo/PanelRole/BtnRoleHeadImg"):GetComponent("Button")
    self.TxtPlayerName = self.Transform:Find("PanelRight/PanelInfo/BtnName/TxtPlayerName"):GetComponent("Text")
    self.BtnName = self.Transform:Find("PanelRight/PanelInfo/BtnName"):GetComponent("Button")
    self.BtnCopy = self.Transform:Find("PanelRight/PanelInfo/BtnCopy"):GetComponent("Button")
    self.TxtPlayerIdNum = self.Transform:Find("PanelRight/PanelInfo/BtnCopy/TxtPlayerIdNum"):GetComponent("Text")
    self.PanelBirthday = self.Transform:Find("PanelRight/PanelInfo/PanelBirthday")
    self.BtnBirModify = self.Transform:Find("PanelRight/PanelInfo/PanelBirthday/BtnGenghuan"):GetComponent("Button")
    self.TxtDate = self.Transform:Find("PanelRight/PanelInfo/PanelBirthday/TxtDate"):GetComponent("Text")
    self.PanelSign = self.Transform:Find("PanelRight/PanelInfo/PanelSign")
    self.BtnSign = self.Transform:Find("PanelRight/PanelInfo/PanelSign/BtnSign"):GetComponent("Button")
    self.TxtSign = self.Transform:Find("PanelRight/PanelInfo/PanelSign/BtnSign/TxtSign"):GetComponent("Text")
    self.TxtSignSet = self.Transform:Find("PanelRight/PanelInfo/PanelSign/BtnSign/TxtSignSet"):GetComponent("Text")
    self.ImgSetNameTag = self.Transform:Find("PanelRight/PanelInfo/BtnName/ImgSetNameTag"):GetComponent("Image")
    self.BtnLogout = self.Transform:Find("PanelRight/BtnLogout"):GetComponent("Button")
    self.PanelZhiyuan = self.Transform:Find("PanelRight/PanelZhiyuan")
    self.PanelZhiyuanA = self.Transform:Find("PanelRight/PanelZhiyuan/PanelZhiyuan")
    self.BtnRole = self.Transform:Find("PanelRight/PanelZhiyuan/PanelZhiyuan/BtnRole"):GetComponent("Button")
    self.RImgAssist = self.Transform:Find("PanelRight/PanelZhiyuan/PanelZhiyuan/BtnRole/RImgAssist"):GetComponent("RawImage")
    self.RImgCharacterRank = self.Transform:Find("PanelRight/PanelZhiyuan/PanelZhiyuan/RImgCharacterRank"):GetComponent("RawImage")
    self.TxtRoleName = self.Transform:Find("PanelRight/PanelZhiyuan/PanelZhiyuan/TxtRoleName"):GetComponent("Text")
    self.TxtRoleRank = self.Transform:Find("PanelRight/PanelZhiyuan/PanelZhiyuan/TxtRoleRank"):GetComponent("Text")
    self.BtnAssistModify = self.Transform:Find("PanelRight/PanelZhiyuan/PanelZhiyuan/BtnGenghuan"):GetComponent("Button")
    self.PanelPlayerExp = self.Transform:Find("PanelPlayerExp")
    self.PanelPlayerGloryExp = self.Transform:Find("PanelPlayerGloryExp")
    self.PanelSetSign = self.Transform:Find("PanelSetSign")
    self.BtnSignSure = self.Transform:Find("PanelSetSign/BtnSignSure"):GetComponent("Button")
    self.BtnSignCancel = self.Transform:Find("PanelSetSign/BtnSignCancel"):GetComponent("Button")
    self.Txt = self.Transform:Find("PanelSetSign/Txt"):GetComponent("Text")
    self.InFSigm = self.Transform:Find("PanelSetSign/InFSigm"):GetComponent("InputField")
    self.PanelSetName = self.Transform:Find("PanelSetName")
    self.PanelSetBirthday = self.Transform:Find("PanelSetBirthday")
    self.PanelSetHeadPortrait = self.Transform:Find("PanelSetHeadPotrait")
    self.DuihuanInput = self.Transform:Find("PanelRight/PanelDuihuan/PanelSign/DuihuanInput"):GetComponent("InputField")
    self.BtnGenghuan = self.Transform:Find("PanelRight/PanelDuihuan/PanelSign/BtnGenghuan"):GetComponent("XUiButton")
end

function XUiPanelPlayerInfoEx:AutoAddListener()
    self:RegisterClickEvent(self.BtnRoleHeadImg, self.OnBtnRoleHeadImgClick)
    self:RegisterClickEvent(self.BtnName, self.OnBtnNameClick)
    self:RegisterClickEvent(self.BtnCopy, self.OnBtnCopyClick)
    self:RegisterClickEvent(self.BtnBirModify, self.OnBtnBirModifyClick)
    self:RegisterClickEvent(self.BtnSign, self.OnBtnSignClick)
    self:RegisterClickEvent(self.BtnLogout, self.OnBtnLogoutClick)
    self:RegisterClickEvent(self.BtnAssistModify, self.OnBtnAssistModifyClick)
    self:RegisterClickEvent(self.BtnSignSure, self.OnBtnSignSureClick)
    self:RegisterClickEvent(self.BtnSignCancel, self.OnBtnSignCancelClick)
    self.BtnGenderSettings.CallBack = handler(self, self.OnBtnGenerSettingEvent)
    self.BtnClose.CallBack = function()
        self:OnBtnSignCancelClick()
    end
    self.BtnGenghuan.CallBack = function() self:OnBtnGenghuanClick() end
    self.BtnFeedback.CallBack = function() self:OnBtnFeedbackClick() end
    self.BtnServerInfo.CallBack = function() self:SetPanelServerInfoShow(true) end
    self.BtnCloseServerInfo.CallBack = function() self:SetPanelServerInfoShow(false) end
    --self.BtnExhibition.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterExhibition))
    --self.BtnArchive.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Archive))
    if XUiManager.IsHideFunc then
        self.BtnDetails.gameObject:SetActiveEx(false)
        self.BtnAchievement.gameObject:SetActiveEx(false)
        self.BtnExhibition.gameObject:SetActiveEx(false)
        self.BtnArchive.gameObject:SetActiveEx(false)
    else
        self:RegisterClickEvent(self.BtnDetails, self.OnBtnDetailsClick)
    end
end
-- auto

function XUiPanelPlayerInfoEx:RegisterClickEvent(...)
    XUiHelper.RegisterClickEvent(self, ...)
end

function XUiPanelPlayerInfoEx:OnBtnExhibitionClick()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterExhibition) then
        self:RecordAnimation()
        XLuaUiManager.Open("UiExhibition", true)
    end
end

function XUiPanelPlayerInfoEx:OnBtnDetailsClick()
    if self.ShowSetting then
        self.ShowSetting()
    end
end

function XUiPanelPlayerInfoEx:SetPanelServerInfoShow(isShow)
    self.PanelServerInfo.gameObject:SetActiveEx(isShow)
end

function XUiPanelPlayerInfoEx:OnCheckSetName(count)
    self.ImgSetNameTag.gameObject:SetActiveEx(count >= 0)
end

function XUiPanelPlayerInfoEx:OnCheckExhibition(count)
    self.ImgExhibitionNew.gameObject:SetActiveEx(count >= 0)
end

function XUiPanelPlayerInfoEx:OnCheckHeadPortrait(count)
    self.NewHead.gameObject:SetActiveEx(count >= 0)
end

function XUiPanelPlayerInfoEx:OnCheckArchive(count)
    self.BtnArchive:ShowReddot(count >= 0)
end

function XUiPanelPlayerInfoEx:OnCheckBirthDay(count)
    self.BtnBirModify:ShowReddot(count >= 0)
end

function XUiPanelPlayerInfoEx:OnCheckFeedback(count)
    self.BtnFeedback:ShowReddot(count >= 0)
end

function XUiPanelPlayerInfoEx:OnBtnSignCancelClick()
    if self.PanelSetSign ~= nil then
        XDataCenter.UiPcManager.RemoveCustomUI(self.PanelSetSign.gameObject)
        XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
        self.PanelSetSign.gameObject:SetActiveEx(false)
    end
end

function XUiPanelPlayerInfoEx:OnBtnLogoutClick()
    XUserManager.Logout()
end

function XUiPanelPlayerInfoEx:OnBtnRoleHeadImgClick()
    if XUiManager.IsHideFunc then
        return
    end
    XLuaUiManager.OpenWithCloseCallback('UiPlayerPersonalizedSetting', handler(self, self.HidePanelSetHeadPortrait), XHeadPortraitConfigs.HeadType.HeadPortrait)
    self:PlayAnimation("SetHeadPotraitEnable")
end

function XUiPanelPlayerInfoEx:OnBtnBirModifyClick()
    self.PanelSetBirthdayInst:AddPcListener()
    self.PanelSetBirthdayInst.GameObject:SetActiveEx(true)
    self:PlayAnimation("SetBirthdayEnable")
end

function XUiPanelPlayerInfoEx:OnBtnAssistModifyClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Character) then
        return
    end
    self:RecordAnimation()
    XLuaUiManager.Open("UiSelectCharacterPlayerSupport")
end

function XUiPanelPlayerInfoEx:OnBtnCopyClick()
    XTool.CopyToClipboard(self.TxtPlayerIdNum.text)
end

function XUiPanelPlayerInfoEx:OnBtnNameClick()
    self.PanelSetNameInst:AddPcListener()
    self.PanelSetNameInst.GameObject:SetActiveEx(true)
    self:PlayAnimation("SetNameEnable")
end

function XUiPanelPlayerInfoEx:OnBtnSignClick()
    --XDataCenter.UiPcManager.AddCustomUI(self.PanelSetSign.gameObject)
    XDataCenter.UiPcManager.OnUiEnable(self, "OnBtnSignCancelClick")
    self.PanelSetSign.gameObject:SetActiveEx(true)
    self.InFSigm.text = ""
    self:PlayAnimation("SetSignEnable")
end

function XUiPanelPlayerInfoEx:UpdatePlayerInfo()
    self.TxtPlayerIdNum.text = XPlayer.Id
    self.TxtPlayerName.text = XPlayer.Name
    self:SetBirthday(XMVCA.XBirthdayPlot:GetBirthday())
    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    self:UpdateAssistInfo()
    local sign = XPlayer.Sign
    if sign == nil or string.len(sign) == 0 then
        local text = CS.XTextManager.GetText('CharacterSignTip')
        self:SetSign(text)
    else
        self:SetSign(sign)
    end

    if self.TxtLikeCount then
        if XPlayer.Likes > 9999 then
            self.TxtLikeCount.text = "9999+"
        else
            self.TxtLikeCount.text = XPlayer.Likes
        end
    end
    --self.TxtCorpsName.text = ""  -- 需要军团
    self:UpdatePlayerGender()
end

function XUiPanelPlayerInfoEx:UpdateAssistInfo()
    local id = XDataCenter.AssistManager.GetAssistCharacterId()
    local character = XMVCA.XCharacter:GetCharacter(id)
    if character then
        self:_UpdateAssistInfoShow(character, id)
    else
        -- 数据异常时默认使用露西亚
        XDataCenter.AssistManager.ChangeAssistCharacterId(DefaultAssistCharacterId, function(code)
            if (code == XCode.Success) then
                character = XMVCA.XCharacter:GetCharacter(DefaultAssistCharacterId)
                self:_UpdateAssistInfoShow(character, XDataCenter.AssistManager.GetAssistCharacterId())
            end
        end)
    end
end

function XUiPanelPlayerInfoEx:_UpdateAssistInfoShow(character, id)
    if character then
        self.RImgCharacterRank:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))
        self.RImgAssist:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(id))
        self.TxtRoleRank.text = character.Level
        self.TxtRoleName.text = XMVCA.XCharacter:GetCharacterName(id)
    else
        XLog.Error('支援角色数据出错，没有找到玩家拥有的角色数据，角色Id：'..tostring(id))
    end
end

function XUiPanelPlayerInfoEx:SetName(name)
    self.TxtPlayerName.text = name
end

function XUiPanelPlayerInfoEx:SetSign(sign)
    self.TxtSignSet.text = sign
    self.TxtSign.gameObject:SetActiveEx(false)
    self.TxtSignSet.gameObject:SetActiveEx(true)
end

function XUiPanelPlayerInfoEx:SetBirthday(birthday)
    if not XMVCA.XBirthdayPlot:IsSetBirthday() then
        self.TxtDate.text = CS.XTextManager.GetText("Birthday", "--", "--")
    else
        self.TxtDate.text = CS.XTextManager.GetText("Birthday", birthday.Mon, birthday.Day)
    end
    self.BtnBirModify.gameObject:SetActiveEx(XMVCA.XBirthdayPlot:CheckCanChangeBirthday())
end

function XUiPanelPlayerInfoEx:OnBtnSignSureClick()
    if string.len(self:trim(self.InFSigm.text)) > 0 then
        if self.InFSigm.text ~= nil then
            local signText = self.InFSigm.text
            local utf8Count = self.InFSigm.textComponent.cachedTextGenerator.characterCount - 1
            if utf8Count > MaxSignLength then
                XUiManager.TipError(CS.XTextManager.GetText("MaxSignLengthTips", MaxSignLength))
                return
            end
            XPlayer.ChangeSign(signText,
                function()
                    self:ChangeSignCallback()
                end)
        end
    else
        XUiManager.TipError(CS.XTextManager.GetText("SignLengthError"))
    end
end

function XUiPanelPlayerInfoEx:OnBtnGenghuanClick()
    local cdKey = self.DuihuanInput.text
    if not cdKey then
        return
    end

    XDataCenter.CdKeyManager.UseCdKeyRequest(cdKey)
end

function XUiPanelPlayerInfoEx:OnBtnFeedbackClick()
    XHeroSdkManager.ClearReddot()
    self.BtnFeedback:ShowReddot(false)
    if not XHeroSdkManager.Feedback(XEnumConst.FeedBackType.From.Setting, XEnumConst.FeedBackType.isLogin.Login) then
        if CustomerServiceUrl and CustomerServiceUrl ~= "" then
            CS.UnityEngine.Application.OpenURL(CustomerServiceUrl)
        end
    end
end

function XUiPanelPlayerInfoEx:ChangeSignCallback()
    if not XPlayer.Sign or string.len(XPlayer.Sign) == 0 then
        self:SetSign(self.DefaultText)
    else
        self:SetSign(XPlayer.Sign)
    end
    if self.PanelSetSign.gameObject ~= nil then
        XDataCenter.UiPcManager.RemoveCustomUI(self.PanelSetSign.gameObject)
        XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
        self.PanelSetSign.gameObject:SetActiveEx(false)
    end
end

function XUiPanelPlayerInfoEx:ChangeNameCallback()
    self:HidePanelSetName()
    self:SetName(XPlayer.Name)
    XEventManager.DispatchEvent(XEventId.EVENT_PLAYER_SET_NAME)
end

function XUiPanelPlayerInfoEx:HidePanelSetName()
    self.PanelSetNameInst:RemovePcListener()
    self.PanelSetNameInst.GameObject:SetActiveEx(false)
end

function XUiPanelPlayerInfoEx:HidePanelSetHeadPortrait()
    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
end

function XUiPanelPlayerInfoEx:ChangeBirthdayCallback()
    self:HidePanelSetBirthday()
    self:SetBirthday(XMVCA.XBirthdayPlot:GetBirthday())
end

function XUiPanelPlayerInfoEx:HidePanelSetBirthday()
    self.PanelSetBirthdayInst:RemovePcListener()
    self.PanelSetBirthdayInst.GameObject:SetActiveEx(false)
end

function XUiPanelPlayerInfoEx:OnDestroy()
    
end

function XUiPanelPlayerInfoEx:trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function XUiPanelPlayerInfoEx:UpdatePlayerLevelInfo()
    if XPlayer.IsHonorLevelOpen() then
        self:ShowGloryExp()
    else
        self:ShowDefaultExp()
    end
end

function XUiPanelPlayerInfoEx:ShowGloryExp()
    if not self.PanelPlayerGloryExpInst then
        self.PanelPlayerGloryExpInst = XUiPanelPlayerGloryExp.New(self.PanelPlayerGloryExp, self)
    end
    self.PanelPlayerGloryExpInst:UpdatePlayerLevelInfo()

    if XPlayer.CheckIsFirstOpenHonor() then
        self.PanelPlayerExp.gameObject:SetActiveEx(true)
        self.PanelPlayerGloryExp.gameObject:SetActiveEx(false)
        self:PlayAnimation("AnimEnablePanelPlayerExp", function()
                self.PanelPlayerGloryExp.gameObject:SetActiveEx(true)
                self:PlayAnimation("PanelPlayerGloryExpEnable", function()
                        self:PlayAnimation("PanelPlayerGloryExpLoop")
                        self.PanelPlayerGloryExpLoop.extrapolationMode = MODE_LOOP
                    end)
            end)
    else
        self.PanelPlayerExp.gameObject:SetActiveEx(false)
        self.PanelPlayerGloryExp.gameObject:SetActiveEx(true)
        self:PlayAnimation("AnimEnablePanelPlayerGloryExp", function()
                self:PlayAnimation("PanelPlayerGloryExpLoop")
                self.PanelPlayerGloryExpLoop.extrapolationMode = MODE_LOOP
            end)
    end
end

function XUiPanelPlayerInfoEx:ShowDefaultExp()
    if not self.PanelPlayerExpInst then
        self.PanelPlayerExpInst = XUiPanelPlayerExp.New(self.PanelPlayerExp, self)
    end
    self.PanelPlayerExpInst:UpdatePlayerLevelInfo()
    self.PanelPlayerExp.gameObject:SetActiveEx(true)
    self.PanelPlayerGloryExp.gameObject:SetActiveEx(false)
    self:PlayAnimation("AnimEnablePanelPlayerExp", function()
            self:PlayAnimation("PanelPlayerExpLoop")
            self.PanelPlayerExpLoop.extrapolationMode = MODE_LOOP
        end)
end

function XUiPanelPlayerInfoEx:UpdatePlayerGender()
    self._LockGenderSettings, self._LeftTime = XPlayerManager:CheckGenderCd()
    local genderDesc = XTool.IsNumberValid(XPlayer.Gender) and XPlayerInfoConfigs.GetPlayerGenderDescById(XPlayer.Gender) or XUiHelper.GetText('PlayerGenderNoSetDesc')
    self.TxtGender.text = genderDesc
    self.BtnGenderSettings:SetButtonState(self._LockGenderSettings and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    XRedPointManager.Check(self._GenderSettingReddotEventId)
end

function XUiPanelPlayerInfoEx:OnCheckGenderSettings(count)
    self.BtnGenderSettings:ShowReddot(count >= 0)
end

function XUiPanelPlayerInfoEx:OnBtnGenerSettingEvent()
    if self._LockGenderSettings then
        XUiManager.TipText('PlayerGenderSetLeftTimeTips', nil, nil, XUiHelper.GetTime(self._LeftTime or 0, XUiHelper.TimeFormatType.DAY_HOUR_2))
    else
        XLuaUiManager.Open('UiPlayerPopupSetGender')
    end
end

return XUiPanelPlayerInfoEx