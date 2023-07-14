XVideoManagerCreator = function()

    local XVideoManager = {}

    local VideoPlayState = {
        Stop = 0,
        Playing = 1,
        Pause = 2
    }

    local State = VideoPlayState.Stop
    -- local PlayingId = -1
    local VideoPlayer = nil

    function XVideoManager.PlayMovie(id, callback, needAuto, needSkip)
        if not id then
            return
        end

        if State == VideoPlayState.Playing then
            XLog.Error("XVideoManager.PlayMovie: Video正在播放")
            return
        end

        local config = XVideoConfig.GetMovieById(id)

        if not CS.XResourceManager.HasFile(config.VideoUrl) then
            if callback then
                callback()
            end
            return
        end
        -- PlayingId = id
        State = VideoPlayState.Playing

        CsXUiManager.Instance:Open("UiVideoPlayer", id, callback, needAuto, needSkip)
    end

    --停止播放
    function XVideoManager.Stop()
        if State ~= VideoPlayState.Playing then
            return
        end

        if not VideoPlayer then
            return
        end

        State = VideoPlayState.Stop
        -- PlayingId = -1
        VideoPlayer = nil

    end

    function XVideoManager.Pause()
        if State ~= VideoPlayState.Playing then
            return
        end

        if not VideoPlayer then
            return
        end

        State = VideoPlayState.Pause
        VideoPlayer:Pause()

    end

    function XVideoManager.Resume()
        if State ~= VideoPlayState.Pause then
            return
        end

        if not VideoPlayer then
            return
        end

        State = VideoPlayState.Playing
        VideoPlayer:Resume()

    end

    function XVideoManager.SetVideoPlayer(player)
        VideoPlayer = player
    end

    function XVideoManager.IsPlaying()
        return VideoPlayer and VideoPlayer:IsPlaying()
    end

    return XVideoManager
end