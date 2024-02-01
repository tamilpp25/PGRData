---@class XUiSameColorGameSetUp:XLuaUi
local XUiSameColorGameSetUp = XLuaUiManager.Register(XLuaUi, "UiSameColorGameSetUp")
function XUiSameColorGameSetUp:OnAwake()
    self:SetButtonCallBack()
end 

function XUiSameColorGameSetUp:OnStart(isMusicClose, isSoundClose, closeMusicFunc, closeSoundFunc, backFunc, rePlayFunc, continueFunc)
    self.IsMusicClose = isMusicClose
    self.IsSoundClose = isSoundClose
    self.CloseMusicFunc = closeMusicFunc
    self.CloseSoundFunc = closeSoundFunc
    self.BackFunc = backFunc
    self.RePlayFunc = rePlayFunc
    self.ContinueFunc = continueFunc
    self:Refresh()
    self:_InitReplayBtn()
    self:_RefreshReplayBtn()
end

function XUiSameColorGameSetUp:OnEnable()
    self:_StartRefreshReplayBtn()
end

function XUiSameColorGameSetUp:OnDisable()
    self:_StopRefreshReplayBtn()
end

--region Replay
function XUiSameColorGameSetUp:_InitReplayBtn()
    ---@type UnityEngine.UI.Text
    self._TxtReplayObjList = {
        XUiHelper.TryGetComponent(self.BtnRePlay.transform, "Normal/Text (1)", "Text"),
        XUiHelper.TryGetComponent(self.BtnRePlay.transform, "Press/Text (2)", "Text"),
        XUiHelper.TryGetComponent(self.BtnRePlay.transform, "Disable/Text (2)", "Text")
    }
    if XTool.IsTableEmpty(self._TxtReplayObjList) then
        self._IsCanReplay = true
        return
    end
    self._ReplayTxt = self._TxtReplayObjList[1].text
    self._ReplayCD = 5  -- 策划要写死
end

function XUiSameColorGameSetUp:_StartRefreshReplayBtn()
    self._Timer = XScheduleManager.ScheduleForever(function()
        if self._IsCanReplay or XTool.UObjIsNil(self.Transform) then
            self:_StopRefreshReplayBtn()
        end
        self:_RefreshReplayBtn()
    end, 0, 0)
end

function XUiSameColorGameSetUp:_StopRefreshReplayBtn()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
    end
end

function XUiSameColorGameSetUp:_RefreshReplayBtn()
    if XTool.IsTableEmpty(self._TxtReplayObjList) then
        return
    end
    local time = XDataCenter.SameColorActivityManager.GetGameRunningRecordTime()
    self._IsCanReplay = time >= self._ReplayCD
    self:_UpdateReplayText(self._IsCanReplay, math.floor(self._ReplayCD - time))
end

function XUiSameColorGameSetUp:_UpdateReplayText(isCanReplay, cdTime)
    for _, text in ipairs(self._TxtReplayObjList) do
        if text then
            text.text = isCanReplay and self._ReplayTxt or self._ReplayTxt.."("..cdTime.."s)"
        end
    end
    self.BtnRePlay:SetDisable(not isCanReplay)
end
--endregion

function XUiSameColorGameSetUp:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnClickBtnBack)
    XUiHelper.RegisterClickEvent(self, self.BtnRePlay, self.OnClickBtnRePlay)
    XUiHelper.RegisterClickEvent(self, self.BtnContinue, self.OnClickBtnContinue)
    XUiHelper.RegisterClickEvent(self, self.ToggleMusic, self.OnClickToggleMusic)
    XUiHelper.RegisterClickEvent(self, self.ToggleSound, self.OnClickToggleSound)
end

function XUiSameColorGameSetUp:OnClickBtnBack()
    self:Close()
    self.BackFunc()
end

function XUiSameColorGameSetUp:OnClickBtnRePlay()
    if not self._IsCanReplay then
        return
    end
    self:Close()
    self.RePlayFunc()
end

function XUiSameColorGameSetUp:OnClickBtnContinue()
    self:Close()
    self.ContinueFunc()
end

function XUiSameColorGameSetUp:OnClickToggleMusic()
    self.IsMusicClose = not self.IsMusicClose
    self.ToggleMusic.isOn = not self.IsMusicClose
    self.CloseMusicFunc(self.IsMusicClose)
end

function XUiSameColorGameSetUp:OnClickToggleSound()
    self.IsSoundClose = not self.IsSoundClose
    self.ToggleSound.isOn = not self.IsSoundClose
    self.CloseSoundFunc(self.IsSoundClose)
end

function XUiSameColorGameSetUp:Refresh()
    self.ToggleMusic.isOn = not self.IsMusicClose
    self.ToggleSound.isOn = not self.IsSoundClose
end
