local XMovieActionInsertTipDisappear = XClass(XMovieActionBase,"XMovieActionInsertTipDisappear")

function XMovieActionInsertTipDisappear:Ctor(actionData)
    
end

function XMovieActionInsertTipDisappear:OnRunning()
    self.UiRoot:HideInsertTips()
end

return XMovieActionInsertTipDisappear