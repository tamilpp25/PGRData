local XMovieActionVideoPlay = XClass(XMovieActionBase, "XMovieActionVideoPlay")

function XMovieActionVideoPlay:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.VideoId = paramToNumber(params[1])
end

function XMovieActionVideoPlay:IsBlock()
    return true
end

function XMovieActionVideoPlay:GetBeginDelay()
    return 1000
end

function XMovieActionVideoPlay:OnRunning()
    self.UiRoot:Hide()
    XDataCenter.VideoManager.PlayUiVideo(self.VideoId, function()
        if self.UiRoot and self.UiRoot.Show then
            self.UiRoot:Show()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
    end)
end


return XMovieActionVideoPlay