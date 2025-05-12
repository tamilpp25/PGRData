local CommunicateReplaceStr = CS.XGame.ClientConfig:GetString("CommunicateReplaceStr")

local XUiFunctionalOpen = XLuaUiManager.Register(XLuaUi, "UiFunctionalOpen")

local UiType = { Normal = 1, Special = 2 }

function XUiFunctionalOpen:OnAwake()
    self:InitAutoScript()
    self.BtnClear.gameObject:SetActiveEx(false)
    self.TxtTalk.text = ""
    self.OptionBtnList = {}
    self.OptionBtnList[1] = self.BtnCheck
end

function XUiFunctionalOpen:OnStart(actionList,IsDoEventEnd,IsDoNext,OnDisableCallBack)
    self:RemovePresentTimer()
    self:RefreshTime()
    self:PlayAnimation("ComOpen", function()
        self:SetupContent(actionList)
    end)
    self.IsEnd = false
    self.IsDoEventEnd = IsDoEventEnd
    self.IsDoNext = IsDoNext
    self.OnDisableCallBack = OnDisableCallBack
    self:OffButton()
end

function XUiFunctionalOpen:OnEnable()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Common_UiFunctionalOpen)
end

function XUiFunctionalOpen:SetupContent(actionList)
    self:PlayAnimation("ComLoop")
    self.Content = 1
    self.Index = 1
    self.CanClick = true
    self.CurCharIndex = 0
    self.Interval = 0.5
    self.Timer = nil
    self.ActionList = actionList

    -- if self.ActionList.NpcHalfIcon then
    --     self:SetUiSprite(self.ImgNpcHalf, self.ActionList.NpcHalfIcon)
    -- end

    self:Init()
end

function XUiFunctionalOpen:OnDisable()
    self:CvStop()
    if self.OnDisableCallBack then
        local callBack = self.OnDisableCallBack
        self.OnDisableCallBack = nil
        callBack()
    end
end

function XUiFunctionalOpen:OnDestroy()
end



function XUiFunctionalOpen:Init()
    
    self.TxtNameHand.text = self.ActionList.NpcName
    if self.ActionList.BtnContent then
        self.TextBtnClear.text = self.ActionList.BtnContent
    end
    if self.ActionList.NpcHandIcon then
        self:SetUiSprite(self.ImgNpcHand, self.ActionList.NpcHandIcon)
    end

    self.TxtNameHalf.text = self.ActionList.NpcName
    self.TxtTalk.text = ""

    self.ImgNpcHand.gameObject:SetActiveEx(true)
    self.PanelHintCommunication.gameObject:SetActiveEx(true)
    self.PanelHintAction.gameObject:SetActiveEx(false)

    if self.ActionList.UiType == UiType.Normal then
        self.BtnOpenCommunication.gameObject:SetActiveEx(true)
        self.BtnOpenCommunicationOfMedal.gameObject:SetActiveEx(false)
        self.BtnRefuse.gameObject:SetActiveEx(true)
        self.BtnRefuseOfMedal.gameObject:SetActiveEx(false)
    else
        self.BtnOpenCommunication.gameObject:SetActiveEx(false)
        self.BtnOpenCommunicationOfMedal.gameObject:SetActiveEx(true)
        self.BtnRefuse.gameObject:SetActiveEx(false)
        self.BtnRefuseOfMedal.gameObject:SetActiveEx(true)
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiFunctionalOpen:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiFunctionalOpen:AutoAddListener()
    self:RegisterClickEvent(self.BtnOpenCommunication, self.OnBtnOpenCommunicationClick)
    self:RegisterClickEvent(self.BtnRefuse, self.OnBtnRefuseClick)
    self:RegisterClickEvent(self.BtnOpenCommunicationOfMedal, self.OnBtnOpenCommunicationClick)
    self:RegisterClickEvent(self.BtnRefuseOfMedal, self.OnBtnRefuseClick)
    self:RegisterClickEvent(self.BtnDirty, self.OnBtnDirtyClick)
    self:RegisterClickEvent(self.BtnClear, self.OnBtnClearClick)
    self:RegisterClickEvent(self.BtnInputOn, self.OnBtnInputOnClick)
    self:RegisterClickEvent(self.BtnOnAction, self.OnBtnOnActionClick)
end

-- auto
function XUiFunctionalOpen:OnBtnDirtyClick()

end


function XUiFunctionalOpen:OnBtnOnActionClick()
    self.BtnOnAction.gameObject:SetActiveEx(false)
    self.BtnInputOn.gameObject:SetActiveEx(true)
    self.PanelHintCommunication.gameObject:SetActiveEx(false)
    self.PanelHintAction.gameObject:SetActiveEx(true)
    self.BtnClear.gameObject:SetActiveEx(false)
    local onEnd = function()
        XUiHelper.StopAnimation()

        self:PlayAnimation("TongxinLoop")
        self.Content = self.Content - 1
        self.CurrCharTab = string.CharsConvertToCharTab(self.ActionList.Repulse)--这里其实是废弃的 但是不知道为什么没有删除
        local interval = math.floor(self.Interval * 1000 / #self.CurrCharTab)
        self.Timer = XScheduleManager.Schedule(function(...)
            self:PlayDialog(...)
        end, interval, #self.CurrCharTab + 2, 0)
    end
    XUiHelper.StopAnimation()

    self:PlayAnimation("TongxinBegan", onEnd)
end

function XUiFunctionalOpen:OnBtnOpenCommunicationClick()
    local onEnd = function()
        XUiHelper.StopAnimation()
        self:PlayAnimation("TongxinLoop")
        self:HintActionInit()
    end
    self.PanelHintCommunication.gameObject:SetActiveEx(false)
    self.BtnOnAction.gameObject:SetActiveEx(false)
    self.BtnInputOn.gameObject:SetActiveEx(true)
    self.BtnClear.gameObject:SetActiveEx(false)

    self.PanelHintAction.gameObject:SetActiveEx(true)
    XUiHelper.StopAnimation()

    self:PlayAnimation("TongxinBegan", onEnd)
end

function XUiFunctionalOpen:OnBtnRefuseClick()
    self:OnBtnClearClick()
end

function XUiFunctionalOpen:OnBtnClearClick()
    if self.IsEnd then
        return
    end

    local data = self.IsDoNext and XDataCenter.CommunicationManager.GetNextCommunication(self.ActionList.Type) or nil
    XUiHelper.StopAnimation()

    if data then
        local onEnd = function()
            self:SetupContent(data)
        end
        self.ImgNpcHand.gameObject:SetActiveEx(false)
        self:PlayAnimation("ComOpen", onEnd)
        self:OffButton()
    else
        local onEnd = function()
            self:RemovePresentTimer()
            self:RemoveTimer()

            local axtionSkipId = self.ActionList.SkipId

            XTipManager.Execute()

            self.PanelHintCommunication.gameObject:SetActiveEx(false)
            self.PanelHintAction.gameObject:SetActiveEx(false)
            XDataCenter.CommunicationManager.SetCommunicating(false)

            self:Close()


            if axtionSkipId then
                XFunctionManager.SkipInterface(axtionSkipId)
            end

            if self.IsDoEventEnd then
                XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
            end

        end

        self:PlayAnimation("TongxinClose", onEnd)
        self.IsEnd = true
    end
end

function XUiFunctionalOpen:OnBtnInputOnClick()
    if self.PanelBtnGroupShow then return end
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
        self.TxtTalk.text = ""
        self.TxtTalk.text = table.concat(self.CurrCharTab)
        self.CurCharIndex = 0
        self:ShowOptionBtn()
        self:TypewritingFinish()
    else
        self:RemoveTimer()
    
        if self.CurFuntionalContentsInfo and self.CurFuntionalContentsInfo.ContentsSkip ~= 0 then
            self.CurFuntionalContentsInfo = XCommunicationConfig.GetFunctionalContentsInfoById(self.CurFuntionalContentsInfo.ContentsSkip)
        else
            self.CurFuntionalContentsInfo = XCommunicationConfig.GetFunctionalContentsGroupFirstInfoByGroupId(self.ActionList.ContentsGroupId)
        end
        self:Typewriting()
    end
end

function XUiFunctionalOpen:ShowOptionBtn()
    if self.PanelBtnGroupShow then return end
    if self.CurFuntionalContentsInfo and XCommunicationConfig.ComminictionType.OptionType == self.CurFuntionalContentsInfo.Type then
        self.PanelBtnGroup.gameObject:SetActiveEx(true)
        self.PanelBtnGroupShow = true
    else
        self.PanelBtnGroup.gameObject:SetActiveEx(false)
        self.PanelBtnGroupShow = false
        return
    end

    for index , option in ipairs(self.CurFuntionalContentsInfo.OptionTitle) do
        local checkBtn = false
        if not self.OptionBtnList[index] then
            checkBtn = CS.UnityEngine.Object.Instantiate(self.BtnCheck, self.PanelBtnGroup.transform)
            self.OptionBtnList[index] = checkBtn
        else
            checkBtn = self.OptionBtnList[index]
        end
        checkBtn.gameObject:SetActiveEx(true)
        local checkBtnLabel = XUiHelper.TryGetComponent(checkBtn.transform, "Text", "Text")
        checkBtnLabel.text = option
        checkBtn.CallBack = function()
            self:OnOptionBtnClick(index)
        end
    end
    if #self.OptionBtnList > #self.CurFuntionalContentsInfo.OptionTitle then
        for i = #self.CurFuntionalContentsInfo.OptionTitle, #self.OptionBtnList, 1 do
            self.OptionBtnList[i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiFunctionalOpen:OnOptionBtnClick(index)

    if self.CurFuntionalContentsInfo and self.CurFuntionalContentsInfo.Optionskip[index] and self.CurFuntionalContentsInfo.Optionskip[index] ~= 0 then
        self.CurFuntionalContentsInfo = XCommunicationConfig.GetFunctionalContentsInfoById(self.CurFuntionalContentsInfo.Optionskip[index])
    end
    self.PanelBtnGroup.gameObject:SetActiveEx(false)
    self.PanelBtnGroupShow = false
    self:Typewriting()

end

function XUiFunctionalOpen:OffButton()
    self.BtnOpenCommunication.gameObject:SetActiveEx(false)
    self.BtnOpenCommunicationOfMedal.gameObject:SetActiveEx(false)
    self.BtnRefuse.gameObject:SetActiveEx(false)
    self.BtnRefuseOfMedal.gameObject:SetActiveEx(false)
end

function XUiFunctionalOpen:HintActionInit()
    self.CurFuntionalContentsInfo = XCommunicationConfig.GetFunctionalContentsGroupFirstInfoByGroupId(self.ActionList.ContentsGroupId)
    self:Typewriting()
end

function XUiFunctionalOpen:Typewriting()
    self:RemoveTimer()
    self.TxtTalk.text = ""
    local content = self.CurFuntionalContentsInfo.Contents
    
    if self.CurFuntionalContentsInfo.NpcHalfIconPath then
        self:SetUiSprite(self.ImgNpcHalf, self.CurFuntionalContentsInfo.NpcHalfIconPath)
    end

    if self.CurFuntionalContentsInfo.NpcName then
        self.TxtNameHalf.text = self.CurFuntionalContentsInfo.NpcName
    end

    local temp = XUiHelper.ReplaceWithPlayerName(content, CommunicateReplaceStr)
    self.CurrCharTab = {}
    if temp and type(temp) == "string" then
        self.CurrCharTab = string.CharsConvertToCharTab(temp)
    end

    local interval = math.floor(self.Interval * 1000 / #self.CurrCharTab)
    self.Timer = XScheduleManager.Schedule(function(...)
        self:PlayDialog(...)
    end, interval, #self.CurrCharTab + 2, 0)

    if self.CurFuntionalContentsInfo.CueId ~= 0 then
        if self.CurPlayingCvId and self.CurPlayingCvId == self.CurFuntionalContentsInfo.CueId then
        else
            self:PlayCv(self.CurFuntionalContentsInfo.CueId)
        end
    else
        self:CvStop()
    end
end

--播放CV
function XUiFunctionalOpen:PlayCv(cvId)
    self:CvStop()
    self.PlayingCv = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, cvId)
    self.CurPlayingCvId = cvId
end

--停止
function XUiFunctionalOpen:CvStop()
    if self.PlayingCv then
        self.PlayingCv:Stop()
        self.PlayingCv = nil
    end
end

function XUiFunctionalOpen:TypewritingFinish()
    if self.CurFuntionalContentsInfo and self.CurFuntionalContentsInfo.ContentsSkip == 0 and self.CurFuntionalContentsInfo.Type ~= XCommunicationConfig.ComminictionType.OptionType then
        self.BtnInputOn.gameObject:SetActiveEx(false)
        self.CanClick = true
        self.BtnClear.gameObject:SetActiveEx(true)
    end
end

function XUiFunctionalOpen:PlayDialog(timer)
    if not timer or self.Timer == nil then
        return
    end
    if self.CurCharIndex + 1 > #self.CurrCharTab then
        self.CurCharIndex = 0
        self:RemoveTimer()
        self:ShowOptionBtn()
        if self.CurFuntionalContentsInfo.ContentsSkip == 0 then
            self:TypewritingFinish()
        end
        return
    end

    -- if not self.TxtTalk then
    --     return
    -- end
    self.CurCharIndex = self.CurCharIndex + 1
    self.TxtTalk.text = self.TxtTalk.text .. self.CurrCharTab[self.CurCharIndex]
end

function XUiFunctionalOpen:RefreshTime()
    local refreshFunc = function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.getTime = XTime.TimestampToGameDateTimeString(XTime.GetServerNowTimestamp(), "HH:mm:ss")
        self.TxtTimeHand.text = self.getTime
        self.TxtTimeHalf.text = self.getTime
    end
    refreshFunc()
    self.PresentTimer = XScheduleManager.ScheduleForever(refreshFunc, 1000, 0)
end

function XUiFunctionalOpen:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiFunctionalOpen:RemovePresentTimer()
    if self.PresentTimer then
        XScheduleManager.UnSchedule(self.PresentTimer)
        self.PresentTimer = nil
    end
end

