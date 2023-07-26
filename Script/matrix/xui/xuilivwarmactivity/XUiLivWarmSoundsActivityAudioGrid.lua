local XUiLivWarmSoundsActivityAudioGrid = XClass(nil, "UiLivWarmSoundsActivityAudioGrid")

function XUiLivWarmSoundsActivityAudioGrid:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.BtnCd = ui
    self.Parent = parent
    XTool.InitUiObject(self)

    self.RawImgShadeNormal = self.Transform:Find("Normal/ImgShade"):GetComponent("RawImage")
    self.RawImgShadePress = self.Transform:Find("Press/ImgShade"):GetComponent("RawImage")
    self.RawImgShadeSelect = self.Transform:Find("Select/ImgShade"):GetComponent("RawImage")
end

function XUiLivWarmSoundsActivityAudioGrid:RefreshData(soundIndex, singlePanelPop, playCallBack)
    self.SoundIndex = soundIndex
    self.CallBack = playCallBack
    self.SinglePanelPop = singlePanelPop
    self.GameObject:SetActiveEx(true)
    self.BtnCd:SetRawImage(XLivWarmSoundsActivityConfig.GetSoundAttachedImgUrl(soundIndex))
    local reflectPath = XLivWarmSoundsActivityConfig.GetSoundReflectedImgUrl(soundIndex)
    self.RawImgShadeNormal:SetRawImage(reflectPath)
    self.RawImgShadePress:SetRawImage(reflectPath)
    self.RawImgShadeSelect:SetRawImage(reflectPath)
    self.BtnCd:SetName(XLivWarmSoundsActivityConfig.GetSoundRankNumber(soundIndex))
end


--isSingleTouch单点不连续播放，否则会连续播放
function XUiLivWarmSoundsActivityAudioGrid:PlaySound(isSingleTouch)
    local soundCueId = XLivWarmSoundsActivityConfig.GetSoundCueId(self.SoundIndex)
    if self.GameObject and  not self.GameObject.activeSelf then
        return
    end
    XSoundManager.PauseMusic()
    if isSingleTouch then
        self.Parent:PlayAnimation("PanelPopupEnable", function()
            self.PlayAudioInfo = CS.XAudioManager.PlaySound(soundCueId, CS.XAudioManager.EAudioBelong.E1p, function()
                if self.CallBack then
                    self.CallBack(isSingleTouch)
                end
                self.Parent:PlayAnimation("PanelPopupDisable")
                XSoundManager.ResumeMusic()
            end)
        end, function()
            self.SinglePanelPop.TextOrder1.text = self.SoundIndex
            self.SinglePanelPop.TextOrder2.text = self.SoundIndex
            self.SinglePanelPop.RImgPoupCd:SetRawImage(XLivWarmSoundsActivityConfig.GetSoundAttachedImgUrl(self.SoundIndex))
        end)
    else
        self.PlayAudioInfo = CS.XAudioManager.PlaySound(soundCueId, CS.XAudioManager.EAudioBelong.E1p, function()
            if self.CallBack then
                self.CallBack(isSingleTouch)
            end
        end)
    end
end

function XUiLivWarmSoundsActivityAudioGrid:StopPlaySound()
    if XTool.IsNumberValid(self.PlayAudioInfo) then
        self.PlayAudioInfo:Stop()
    end
end

return XUiLivWarmSoundsActivityAudioGrid