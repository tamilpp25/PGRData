local XMovieActionInsertTipAppear = XClass(XMovieActionBase,"XMovieActionInsertTipAppear")

function XMovieActionInsertTipAppear:Ctor(actionData)
    self.BgPath = actionData.Params[1]
end

function XMovieActionInsertTipAppear:OnRunning()
    self.UiRoot:SetInsertBg(self.BgPath)
    self.UiRoot:ShowInsertTips()
end

return XMovieActionInsertTipAppear