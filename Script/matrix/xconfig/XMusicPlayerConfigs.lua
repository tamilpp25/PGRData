--
-- Author: wujie
-- Note: 音乐播放器配置相关

XMusicPlayerConfigs = XMusicPlayerConfigs or {}

XMusicPlayerConfigs.UiMainSavedAlbumIdKey = "UiMainSavedAlbumId"

local TABLE_ALBUM = "Client/MusicPlayer/MusicPlayerAlbum.tab"

local AlbumTemplates
local AlbumIdList = {}

function XMusicPlayerConfigs.Init()
    XMusicPlayerConfigs.InitAlbum()
    XMusicPlayerConfigs.CreateAlbumIdList()
end

function XMusicPlayerConfigs.InitAlbum()
    AlbumTemplates = XTableManager.ReadByIntKey(TABLE_ALBUM, XTable.XTableMusicPlayerAlbum,"Id")

    local cueIdDic = {}
    local id
    local cueId
    local priority
    for _, template in pairs(AlbumTemplates) do
        id = template.Id
        cueId = template.CueId
        if not cueId or cueId == 0 then
            XLog.ErrorTableDataNotFound("XMusicPlayerConfigs.InitAlbum", "cueId", TABLE_ALBUM, "id", tostring(id))
        end

        if not cueIdDic[cueId] then
            cueIdDic[cueId] = true
        else
            XLog.Error("XMusicPlayerConfigs.InitAlbum 函数错误, 存在相同的cueId: " .. cueId .. "检查配置表: " .. TABLE_ALBUM)
        end

        priority = template.Priority
        if not priority or priority == 0 then
            XLog.ErrorTableDataNotFound("XMusicPlayerConfigs.InitAlbum", "Priority", TABLE_ALBUM, "id", tostring(id))
        end
    end
end

function XMusicPlayerConfigs.CreateAlbumIdList()
    for _, template in pairs(AlbumTemplates) do
        table.insert(AlbumIdList, template.Id)
    end
    table.sort(AlbumIdList, function(aId, bId)
        local aTemplate = AlbumTemplates[aId]
        local bTemplate = AlbumTemplates[bId]
        return aTemplate.Priority > bTemplate.Priority
    end)
end

function XMusicPlayerConfigs.GetAlbumIdList()
    return AlbumIdList
end

function XMusicPlayerConfigs.GetAlbumTemplateById(id)
    local template = AlbumTemplates[id]
    if template then
        return template
    end
    XLog.ErrorTableDataNotFound("XMusicPlayerConfigs.GetAlbumTemplateById", "template", TABLE_ALBUM, "id", tostring(id))
end

function XMusicPlayerConfigs.IsHaveAlbumById(id)
    return AlbumTemplates[id] ~= nil
end

function XMusicPlayerConfigs.GetAlbumTemplateByCueId(cueId)
    for _, template in pairs(AlbumTemplates) do
        if template.CueId == cueId then
            return template
        end
    end
end