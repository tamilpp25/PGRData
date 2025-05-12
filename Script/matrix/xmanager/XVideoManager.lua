XVideoManagerCreator = function()

    ---@class XVideoManager
    local XVideoManager = {}

    function XVideoManager.PlayUiVideo(id, callback, needAuto, needSkip)
        if not id then
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

        XLuaUiManager.Open("UiVideoPlayer", id, callback, needAuto, needSkip)
    end

    function XVideoManager.LoadVideoPlayerUguiWithPrefab(parentTransform)
        if not parentTransform then
            return
        end

        local loader = CS.XLoaderUtil.GetModuleLoader(ModuleId.XUiMain)
        local prefabUrl = CS.XGame.ClientConfig:GetString("VideoPlayerUguiPrefabUrl")
        local resource = loader:Load(prefabUrl)
        local videoPrefab = XUiHelper.Instantiate(resource, parentTransform.transform)
        local videoPlayerUGUI = videoPrefab:GetComponent(typeof(CS.XVideoPlayerUGUI))
        loader:Unload(prefabUrl)
        return videoPlayerUGUI
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