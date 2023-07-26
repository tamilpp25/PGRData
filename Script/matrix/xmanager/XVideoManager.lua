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
        
        if not XDataCenter.UiPcManager.IsPc() and not CS.XResourceManager.HasFile(config.VideoUrl, true) then
            if callback then
                callback()
            end
            return
        end

        if XDataCenter.UiPcManager.IsPc() and not CS.XResourceManager.HasFile(config.VideoUrlPc, true) then
            if callback then
                callback()
            end
            return
        end

        -- PlayingId = id
        State = VideoPlayState.Playing

        XLuaUiManager.Open("UiVideoPlayer", id, callback, needAuto, needSkip)
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

    -- 注意pv资源需要放在launch目录下，和下载pv使用同一份
    function XVideoManager.CheckCgUrl()
        local needCGBtn = false
        local videoUrl = CS.XAudioManager.LaunchVideoAsset
        local videoUrlPc = CS.XAudioManager.LaunchVideoAssetPc
        local width = CS.XLaunchManager.LaunchConfig:GetInt("LaunchVideoWidth")
        local height = CS.XLaunchManager.LaunchConfig:GetInt("LaunchVideoHeight")
        local hasVideo = (videoUrl and videoUrl ~= "" and videoUrl ~= "null")
        if hasVideo then
            local bundleName = CS.XResourceManager.GetBundleUrl(videoUrl)
            videoUrl = CS.XBundleManager.GetFile(bundleName)
            local bundleNamePc = CS.XResourceManager.GetBundleUrl(videoUrlPc)
            videoUrlPc = CS.XBundleManager.GetFile(bundleNamePc)
            needCGBtn = true
            if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.Android then
                local path = videoUrl
                local streamingAssetPath = CS.UnityEngine.Application.streamingAssetsPath
                local len = string.len(streamingAssetPath)

                local prefix = string.sub(videoUrl, 0, len)
                if prefix == streamingAssetPath then
                    videoUrl = string.sub(videoUrl, len + 2)
                end

                local prefixPc = string.sub(videoUrlPc, 0, len)
                if prefixPc == streamingAssetPath then
                    prefixPc = string.sub(videoUrlPc, len + 2)
                end
            end
        end
        return needCGBtn, videoUrl, videoUrlPc, width, height
    end

    return XVideoManager
end