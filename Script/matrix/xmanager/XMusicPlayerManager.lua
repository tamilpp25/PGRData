
--
--Author: wujie
--Note: 音乐播放器管理

local DefaultAlbumId = CS.XGame.ClientConfig:GetInt("MusicPlayerMainViewNeedPlayedAlbumId")

XMusicPlayerManagerCreator = function()
    local XMusicPlayerManager = {}

    local UiMainNeedPlayedAlbumId

    function XMusicPlayerManager.Init()
        local albumId = XSaveTool.GetData(XMusicPlayerConfigs.UiMainSavedAlbumIdKey)
        if not albumId or not XMusicPlayerConfigs.IsHaveAlbumById(albumId) then
            albumId = DefaultAlbumId
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
        if not XMVCA.XSubPackage:CheckNecessaryComplete() then
            return DefaultAlbumId
        end
        return UiMainNeedPlayedAlbumId
    end

    XMusicPlayerManager.Init()
    return XMusicPlayerManager
end

