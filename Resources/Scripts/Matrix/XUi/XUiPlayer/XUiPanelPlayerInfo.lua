local CustomerServiceUrl = CS.XGame.ClientConfig:GetString("CustomerServiceUrl") or ""
local FeedBackUrl = CS.XGame.ClientConfig:GetString("FeedBackUrl") or ""

local CSNetWebRequest = CS.UnityEngine.Networking.UnityWebRequest

local XUiPanelPlayerInfo = XLuaUiManager.Register(XLuaUi, "UiPanelPlayerInfo")
local MaxSignLength = CS.XGame.ClientConfig:GetInt("MaxSignLength")
local XUiPanelSetHeadPortrait = require("XUi/XUiPlayer/XUiPanelSetHeadPortrait")
local MODE_LOOP = 1

function XUiPanelPlayerInfo:OnAwake()
    self:InitAutoScript()
end

function XUiPanelPlayerInfo:OnEnable()
    self:ResumeAnimation()
    self:UpdatePlayerInfo()
end

function XUiPanelPlayerInfo:OnStart()
    self.PanelSetNameInst = XUiPanelSetName.New(self.PanelSetName, self)
    self.PanelSetBirthdayInst = XUiPanelSetBirthday.New(self.PanelSetBirthday, self)
    self.PanelSetHeadPortraitInst = XUiPanelSetHeadPortrait.New(self.PanelSetHeadPortrait, self)

    self.DefaultText = CS.XTextManager.GetText("CharacterSignTip")

    self.TxtVersion.text = CS.XRemoteConfig.DocumentVersion
    self.TxtServerName.text = XServerManager.GetCurServerName()
    self.PanelServerInfo.gameObject:SetActiveEx(false)

    self.BtnFeedback.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Feedback))
    self.PanelDuihuan.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.ExchangeCode))

    XRedPointManager.AddRedPointEvent(self.ImgSetNameTag, self.OnCheckSetName, self, { XRedPointConditions.Types.CONDITION_PLAYER_SETNAME })
    XRedPointManager.AddRedPointEvent(self.ImgExhibitionNew, self.OnCheckExhibition, self, { XRedPointConditions.Types.CONDITION_EXHIBITION_NEW })
    XRedPointManager.AddRedPointEvent(self.NewHead, self.OnCheckHeadPortrait, self, { XRedPointConditions.Types.CONDITION_HEADPORTRAIT_RED })
    XRedPointManager.AddRedPointEvent(self.BtnArchive, self.OnCheckArchive, self, { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_ALL, XRedPointConditions.Types.CONDITION_ARCHIVE_WEAPON, XRedPointConditions.Types.CONDITION_ARCHIVE_AWARENESS, XRedPointConditions.Types.CONDITION_ARCHIVE_CG_ALL })

    self:UpdatePlayerLevelInfo()
end

---
--- 记录动画的播放进度与状态，避免切换到新界面再切回来时动画中断
function XUiPanelPlayerInfo:RecordAnimation()
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
function XUiPanelPlayerInfo:ResumeAnimation()
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
function XUiPanelPlayerInfo:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelPlayerInfo:AutoInitUi()
    self.PanelRight = self.Transform:Find("PanelRight")
    self.PanelCorps = self.Transform:Find("PanelRight/PanelCorps")
    self.TxtCorps = self.Transform:Find("PanelRight/PanelCorps/TxtCorps"):GetComponent("Text")
    self.PanelInfo = self.Transform:Find("PanelRight/PanelInfo")
    self.PanelRole = self.Transform:Find("PanelRight/PanelInfo/PanelRole")
    self.BtnRoleHeadImg = self.Transform:Find("PanelRight/PanelInfo/PanelRole/BtnRoleHeadImg"):GetComponent("Button")
    self.TxtPlayerName = self.Transform:Find("PanelRight/PanelInfo/TxtPlayerName"):GetComponent("Text")
    self.BtnName = self.Transform:Find("PanelRight/PanelInfo/BtnName"):GetComponent("Button")
    self.BtnCopy = self.Transform:Find("PanelRight/PanelInfo/BtnCopy"):GetComponent("Button")
    self.TxtPlayerIdNum = self.Transform:Find("PanelRight/PanelInfo/TxtPlayerIdNum"):GetComponent("Text")
    self.PanelBirthday = self.Transform:Find("PanelRight/PanelInfo/PanelBirthday")
    self.BtnBirModify = self.Transform:Find("PanelRight/PanelInfo/PanelBirthday/BtnGenghuan"):GetComponent("Button")
    self.TxtDate = self.Transform:Find("PanelRight/PanelInfo/PanelBirthday/TxtDate"):GetComponent("Text")
    self.PanelSign = self.Transform:Find("PanelRight/PanelInfo/PanelSign")
    self.BtnSign = self.Transform:Find("PanelRight/PanelInfo/PanelSign/BtnSign"):GetComponent("Button")
    self.TxtSign = self.Transform:Find("PanelRight/PanelInfo/PanelSign/BtnSign/TxtSign"):GetComponent("Text")
    self.TxtSignSet = self.Transform:Find("PanelRight/PanelInfo/PanelSign/BtnSign/TxtSignSet"):GetComponent("Text")
    self.ImgSetNameTag = self.Transform:Find("PanelRight/PanelInfo/ImgSetNameTag"):GetComponent("Image")
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
    self.BtnExhibition = self.Transform:Find("BtnExhibition"):GetComponent("Button")
    self.ImgExhibitionNew = self.Transform:Find("BtnExhibition/ImgExhibitionNew"):GetComponent("Image")
    self.DuihuanInput = self.Transform:Find("PanelRight/PanelDuihuan/PanelSign/DuihuanInput"):GetComponent("InputField")
    self.BtnGenghuan = self.Transform:Find("PanelRight/PanelDuihuan/PanelSign/BtnGenghuan"):GetComponent("XUiButton")
end

function XUiPanelPlayerInfo:AutoAddListener()
    self:RegisterClickEvent(self.BtnRoleHeadImg, self.OnBtnRoleHeadImgClick)
    self:RegisterClickEvent(self.BtnName, self.OnBtnNameClick)
    self:RegisterClickEvent(self.BtnCopy, self.OnBtnCopyClick)
    self:RegisterClickEvent(self.BtnBirModify, self.OnBtnBirModifyClick)
    self:RegisterClickEvent(self.BtnSign, self.OnBtnSignClick)
    self:RegisterClickEvent(self.BtnLogout, self.OnBtnLogoutClick)
    self:RegisterClickEvent(self.BtnAssistModify, self.OnBtnAssistModifyClick)
    self:RegisterClickEvent(self.BtnSignSure, self.OnBtnSignSureClick)
    self:RegisterClickEvent(self.BtnSignCancel, self.OnBtnSignCancelClick)
    self:RegisterClickEvent(self.BtnExhibition, self.OnBtnExhibitionClick)
    self.BtnClose.CallBack = function()
        self:OnBtnSignCancelClick()
    end
    self.BtnArchive.CallBack = function() self:OnBtnArchiveClick() end
    self.BtnGenghuan.CallBack = function() self:OnBtnGenghuanClick() end
    self.BtnFeedback.CallBack = function() self:OnBtnFeedbackClick() end
    self.BtnServerInfo.CallBack = function() self:SetPanelServerInfoShow(true) end
    self.BtnCloseServerInfo.CallBack = function() self:SetPanelServerInfoShow(false) end

    self.BtnExhibition.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.CharacterExhibition))
    self.BtnArchive.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Archive))
end
-- auto

function XUiPanelPlayerInfo:OnBtnExhibitionClick()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterExhibition) then
        self:RecordAnimation()
        XLuaUiManager.Open("UiExhibition", true)
    end
end

function XUiPanelPlayerInfo:SetPanelServerInfoShow(isShow)
    self.PanelServerInfo.gameObject:SetActiveEx(isShow)
end

function XUiPanelPlayerInfo:OnCheckSetName(count)
    self.ImgSetNameTag.gameObject:SetActiveEx(count >= 0)
end

function XUiPanelPlayerInfo:OnCheckExhibition(count)
    self.ImgExhibitionNew.gameObject:SetActiveEx(count >= 0)
end

function XUiPanelPlayerInfo:OnCheckHeadPortrait(count)
    self.NewHead.gameObject:SetActiveEx(count >= 0)
end

function XUiPanelPlayerInfo:OnCheckArchive(count)
    self.BtnArchive:ShowReddot(count >= 0)
end

function XUiPanelPlayerInfo:OnBtnSignCancelClick()
    if self.PanelSetSign ~= nil then
        self.PanelSetSign.gameObject:SetActiveEx(false)
    end
end

function XUiPanelPlayerInfo:OnBtnLogoutClick()
    XUserManager.ShowLogout()
end

function XUiPanelPlayerInfo:OnBtnRoleHeadImgClick()
    self.PanelSetHeadPortrait.gameObject:SetActiveEx(true)
    self.PanelSetHeadPortraitInst:Reset()
    self:PlayAnimation("SetHeadPotraitEnable")
end

function XUiPanelPlayerInfo:OnBtnBirModifyClick()
    self.PanelSetBirthday.gameObject:SetActiveEx(true)
    self:PlayAnimation("SetBirthdayEnable")
end

function XUiPanelPlayerInfo:OnBtnAssistModifyClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Character) then
        return
    end
    self:RecordAnimation()
    XLuaUiManager.Open("UiCharacter", nil, nil, nil, true)
end

function XUiPanelPlayerInfo:OnBtnCopyClick()
    XTool.CopyToClipboard(self.TxtPlayerIdNum.text)
end

function XUiPanelPlayerInfo:OnBtnNameClick()
    self.PanelSetNameInst.GameObject:SetActiveEx(true)
    self:PlayAnimation("SetNameEnable")
end

function XUiPanelPlayerInfo:OnBtnSignClick()
    self.PanelSetSign.gameObject:SetActiveEx(true)
    self.InFSigm.text = ""
    self:PlayAnimation("SetSignEnable")
end

function XUiPanelPlayerInfo:UpdatePlayerInfo()
    self.TxtPlayerIdNum.text = XPlayer.Id
    self.TxtPlayerName.text = XPlayer.Name
    self:SetBirthday(XPlayer.Birthday)
    XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
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
end

function XUiPanelPlayerInfo:UpdateAssistInfo()
    local id = XDataCenter.AssistManager.GetAssistCharacterId()
    local character = XDataCenter.CharacterManager.GetCharacter(id)
    self.RImgCharacterRank:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(character.Quality))
    self.RImgAssist:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(id))
    self.TxtRoleRank.text = character.Level
    self.TxtRoleName.text = XCharacterConfigs.GetCharacterName(id)
end

function XUiPanelPlayerInfo:SetName(name)
    self.TxtPlayerName.text = name
end

function XUiPanelPlayerInfo:SetSign(sign)
    self.TxtSignSet.text = sign
    self.TxtSign.gameObject:SetActiveEx(false)
    self.TxtSignSet.gameObject:SetActiveEx(true)
end

function XUiPanelPlayerInfo:SetBirthday(birthday)
    if (birthday == nil) then
        self.TxtDate.text = CS.XTextManager.GetText("Birthday", "--", "--")
    else
        self.TxtDate.text = CS.XTextManager.GetText("Birthday", birthday.Mon, birthday.Day)
        self.BtnBirModify.gameObject:SetActiveEx(false)
    end
end

function XUiPanelPlayerInfo:OnBtnSignSureClick()
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

function XUiPanelPlayerInfo:OnBtnGenghuanClick()
    local cdKey = self.DuihuanInput.text
    if not cdKey then
        return
    end

    XDataCenter.CdKeyManager.UseCdKeyRequest(cdKey)
end

function XUiPanelPlayerInfo:OnBtnFeedbackClick()
    if FeedBackUrl and FeedBackUrl ~= "" then
        --local playerName = CSNetWebRequest.EscapeURL(XPlayer.Name)
        --local playerId = CSNetWebRequest.EscapeURL(tostring(XPlayer.Id))
        --local documentVersion = CSNetWebRequest.EscapeURL(tostring(CS.XRemoteConfig.DocumentVersion))
        --local os = CSNetWebRequest.EscapeURL(tostring(CS.UnityEngine.SystemInfo.operatingSystem))
        --local device = CSNetWebRequest.EscapeURL(tostring(CS.UnityEngine.SystemInfo.deviceModel))
        --local resStr = "%s?playerName=%s&playerId=%s&type=%s&os=%s&documentVersion=%s"
        --local targetUrl = string.format(resStr, FeedBackUrl, playerName, playerId, device, os, documentVersion)
        --targetUrl = string.gsub(targetUrl, "+", ".")
        --XLog.Debug(targetUrl)
        local targetUrl = FeedBackUrl
        CS.UnityEngine.Application.OpenURL(targetUrl)
    end
end

function XUiPanelPlayerInfo:OnBtnArchiveClick()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Archive) then
        self:RecordAnimation()
        XLuaUiManager.Open("UiArchiveMain")
    end
end

function XUiPanelPlayerInfo:ChangeSignCallback()
    if not XPlayer.Sign or string.len(XPlayer.Sign) == 0 then
        self:SetSign(self.DefaultText)
    else
        self:SetSign(XPlayer.Sign)
    end
    if self.PanelSetSign.gameObject ~= nil then
        self.PanelSetSign.gameObject:SetActiveEx(false)
    end
end

function XUiPanelPlayerInfo:ChangeNameCallback()
    self:HidePanelSetName()
    self:SetName(XPlayer.Name)
    XEventManager.DispatchEvent(XEventId.EVENT_PLAYER_SET_NAME)
end

function XUiPanelPlayerInfo:HidePanelSetName()
    self.PanelSetNameInst.GameObject:SetActiveEx(false)
end

function XUiPanelPlayerInfo:HidePanelSetHeadPortrait()
    self.PanelSetHeadPortrait.gameObject:SetActiveEx(false)
    XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
end

function XUiPanelPlayerInfo:ChangeBirthdayCallback()
    self:HidePanelSetBirthday()
    self:SetBirthday(XPlayer.Birthday)
end

function XUiPanelPlayerInfo:HidePanelSetBirthday()
    self.PanelSetBirthday.gameObject:SetActiveEx(false)
end

function XUiPanelPlayerInfo:OnDestroy()
    self.PanelSetHeadPortraitInst:Release()
end

function XUiPanelPlayerInfo:trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function XUiPanelPlayerInfo:UpdatePlayerLevelInfo()
    if XPlayer.IsHonorLevelOpen() then
        self:ShowGloryExp()
    else
        self:ShowDefaultExp()
    end
end

function XUiPanelPlayerInfo:ShowGloryExp()
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

function XUiPanelPlayerInfo:ShowDefaultExp()
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

--- 记录动画的播放进度与状态，避免切换到新界面再切回来时动画中断
function XUiPanelPlayerInfo:RecordAnimation()
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
function XUiPanelPlayerInfo:ResumeAnimation()
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