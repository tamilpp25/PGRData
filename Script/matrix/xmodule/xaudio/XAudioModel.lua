---@class XAudioModel : XModel
local XAudioModel = XClass(XModel, "XAudioModel")
local TableKey = 
{
    MusicPlayerAlbum = { DirPath = XConfigUtil.DirectoryType.Client },
}

function XAudioModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    self._ConfigUtil:InitConfigByTableKey("Audio", TableKey, XConfigUtil.CacheType.Normal)

    self.DefaultAlbumId = CS.XGame.ClientConfig:GetInt("MusicPlayerMainViewNeedPlayedAlbumId")
    self.UiMainSavedAlbumIdKey = "UiMainSavedAlbumId"
    self.AlbumIdList = {}
    self.CueIdToMusicAlbumIdDic = {}

end

function XAudioModel:ClearPrivate()
    --这里执行内部数据清理
end

function XAudioModel:ResetAll()
    --这里执行重登数据清理
end

----------public start----------
function XAudioModel:GetMusicPlayerAlbum()
    return self._ConfigUtil:GetByTableKey(TableKey.MusicPlayerAlbum)
end

-- 初始化/获取相关数据 开始
function XAudioModel:CreateAlbumIdList()
    local AlbumTemplates = self:GetMusicPlayerAlbum()
    for _, template in pairs(AlbumTemplates) do
        table.insert(self.AlbumIdList, template.Id)
    end
    table.sort(self.AlbumIdList, function(aId, bId)
        local aTemplate = AlbumTemplates[aId]
        local bTemplate = AlbumTemplates[bId]
        return aTemplate.Priority > bTemplate.Priority
    end)
end

function XAudioModel:GetCueIdToMusicAlbumIdDic()
    if XTool.IsTableEmpty(self.CueIdToMusicAlbumIdDic) then
        local allConfig = self:GetMusicPlayerAlbum()
        for k, v in pairs(allConfig) do
            self.CueIdToMusicAlbumIdDic[v.CueId] = v.Id
        end
    end

    return self.CueIdToMusicAlbumIdDic
end

-- 初始化/获取相关数据 结束

----------public end----------

----------private start----------


----------private end----------

----------config start----------


----------config end----------


return XAudioModel