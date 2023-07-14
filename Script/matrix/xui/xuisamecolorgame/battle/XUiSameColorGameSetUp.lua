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
end

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
