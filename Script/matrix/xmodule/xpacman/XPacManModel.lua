local TableKey = {
    PacManStage = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
    PacManStory = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private },
}

---@class XPacManModel : XModel
local XPacManModel = XClass(XModel, "XPacManModel")

function XPacManModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("PixelGame/PacMan", TableKey)
end

function XPacManModel:ClearPrivate()
end

function XPacManModel:ResetAll()
end

function XPacManModel:GetStage(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PacManStage, stageId)
end

function XPacManModel:GetStory(storyId)
    local configs = self._ConfigUtil:GetByTableKey(TableKey.PacManStory)
    local story = {}
    for i = 1, 99 do
        local id = storyId * 1000 + i
        local config = configs[id]
        if config and config.StoryId == storyId then
            story[#story + 1] = config
        end
    end
    return story
end

return XPacManModel