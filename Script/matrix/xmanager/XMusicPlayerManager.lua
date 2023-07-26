
--
--Author: wujie
--Note: 音乐播放器管理

XMusicPlayerManagerCreator = function()
    local XMusicPlayerManager = {}

    local UiMainNeedPlayedAlbumId

    function XMusicPlayerManager.Init()
        local albumId = XSaveTool.GetData(XMusicPlayerConfigs.UiMainSavedAlbumIdKey)
        if not albumId or not XMusicPlayerConfigs.IsHaveAlbumById(albumId) then
            albumId = CS.XGame.ClientConfig:GetInt("MusicPlayerMainViewNeedPlayedAlbumId")
            if albumId == 0 then
                XLog.Error("Client/Config/ClientConfig.tab 表里面的 MusicPlayerMainViewNeedPlayedAlbumId 字段对应的值不能为0")
            end
        end
        UiMainNeedPlayedAlbumId = albumId
        local template = XMusicPlayerConfigs.GetAlbumTemplateById(albumId)
        CS.XAudioManager.UiMainNeedPlayedBgmCueId = template.CueId
    end

    function XMusicPlayerManager.ChangeUiMainAlbumId(albumId)
        UiMainNeedPlayedAlbumId = albumId
        XSaveTool.SaveData(XMusicPlayerConfigs.UiMainSavedAlbumIdKey, albumId)
        local template = XMusicPlayerConfigs.GetAlbumTemplateById(albumId)
        CS.XAudioManager.UiMainNeedPlayedBgmCueId = template.CueId
    end

    function XMusicPlayerManager.GetUiMainNeedPlayedAlbumId()
        return UiMainNeedPlayedAlbumId
    end

    XMusicPlayerManager.Init()
    return XMusicPlayerManager
end

