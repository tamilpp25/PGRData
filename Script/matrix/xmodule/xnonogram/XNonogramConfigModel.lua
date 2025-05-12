---@class XNonogramConfigModel : XModel
local XNonogramConfigModel = XClass(XModel, "XNonogramConfigModel")

local TableKey = {
    NonogramActivity = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.IntAll, CacheType = XConfigUtil.CacheType.Normal },
    NonogramChapter = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Normal },
    NonogramChapterClient = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Private },
    NonogramStage = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Private },
    NonogramGrid = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Private },
    --NonogramStageGroup = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, CacheType = XConfigUtil.CacheType.Private },
}

function XNonogramConfigModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/Nonogram", TableKey)
end

function XNonogramConfigModel:ClearPrivate()
    
end

function XNonogramConfigModel:ResetAll()
    
end

--region NonogramActivity
function XNonogramConfigModel:GetActivityConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.NonogramActivity)
end

function XNonogramConfigModel:GetActivityConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NonogramActivity, id)
end

function XNonogramConfigModel:GetActivityNameById(id)
    local cfg = self:GetActivityConfigById(id)
    if cfg then
        return cfg.Name
    end
    return ""
end

function XNonogramConfigModel:GetActivityTimeIdById(id)
    local cfg = self:GetActivityConfigById(id)
    if cfg then
        return cfg.TimeId
    end
    return 0
end

function XNonogramConfigModel:GetActivityChapterIdsById(id)
    local cfg = self:GetActivityConfigById(id)
    if cfg then
        return cfg.ChapterIds
    end
    return {}
end

--function XNonogramConfigModel:GetActivityRebrushChapterById(id)
--    local cfg = self:GetActivityConfigById(id)
--    if cfg then
--        return cfg.RebrushChapter
--    end
--end
--endregion

--region NonogramChapter

function XNonogramConfigModel:GetChapterConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.NonogramChapter)
end

function XNonogramConfigModel:GetChapterConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NonogramChapter, id)
end

function XNonogramConfigModel:GetChapterNameById(id)
    local cfg = self:GetChapterConfigById(id)
    if cfg then
        return cfg.Name
    end
    return ""
end

function XNonogramConfigModel:GetChapterPreChapterIdById(id)
    local cfg = self:GetChapterConfigById(id)
    if cfg then
        return cfg.PreChapterId
    end
    return 0
end

function XNonogramConfigModel:GetChapterUnlockItemNumById(id)
    local cfg = self:GetChapterConfigById(id)
    if cfg then
        return cfg.UnlockItemNum
    end
    return 0
end

function XNonogramConfigModel:GetChapterUnlockCgItemIdById(id)
    local cfg = self:GetChapterConfigById(id)
    if cfg then
        return cfg.UnlockCgItemId
    end
    return 0
end

function XNonogramConfigModel:GetChapterUnlockCgItemNumById(id)
    local cfg = self:GetChapterConfigById(id)
    if cfg then
        return cfg.UnlockCgItemNum
    end
    return 0
end

function XNonogramConfigModel:GetChapterCgRewardIdById(id)
    local cfg = self:GetChapterConfigById(id)
    if cfg then
        return cfg.CgRewardId
    end
    return 0
end

function XNonogramConfigModel:GetChapterTimeLimitById(id)
    local cfg = self:GetChapterConfigById(id)
    if cfg then
        return cfg.TimeLimit
    end
    return 0
end

function XNonogramConfigModel:GetChapterDeductTimeById(id)
    local cfg = self:GetChapterConfigById(id)
    if cfg then
        return cfg.DeductTime
    end
    return 0
end

function XNonogramConfigModel:GetChapterIsRebrushById(id)
    local cfg = self:GetChapterConfigById(id)
    if cfg then
        return cfg.IsRebrush
    end
end

--Client
function XNonogramConfigModel:GetChapterClientConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NonogramChapterClient, id)
end

function XNonogramConfigModel:GetBtnChapterImagePathById(id)
    local cfg = self:GetChapterClientConfigById(id)
    if cfg then
        return cfg.BtnChapterImagePath
    end
end

function XNonogramConfigModel:GetCGTexturePathById(id)
    local cfg = self:GetChapterClientConfigById(id)
    if cfg then
        return cfg.CGTexturePath
    end
end

function XNonogramConfigModel:GetCGDetailById(id)
    local cfg = self:GetChapterClientConfigById(id)
    if cfg then
        return cfg.CGDetail
    end
end

function XNonogramConfigModel:GetPlayTipsById(id)
    local cfg = self:GetChapterClientConfigById(id)
    if cfg then
        return cfg.PlayTips
    end
end

function XNonogramConfigModel:GetShowTipCDById(id)
    local cfg = self:GetChapterClientConfigById(id)
    if cfg then
        return cfg.ShowTipCD
    end
end

function XNonogramConfigModel:GetShowTipErrorHitTimesById(id)
    local cfg = self:GetChapterClientConfigById(id)
    if cfg then
        return cfg.ShowTipErrorHitTimes
    end
end

--endregion

--region NonogramStage
function XNonogramConfigModel:GetStageConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.NonogramStage)
end

function XNonogramConfigModel:GetStageConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NonogramStage, id)
end

function XNonogramConfigModel:GetStageRewardIdById(id)
    local cfg = self:GetStageConfigById(id)
    if cfg then
        return cfg.RewardId
    end
    return 0
end

function XNonogramConfigModel:GetStageGridTemplateIdById(id)
    local cfg = self:GetStageConfigById(id)
    if cfg then
        return cfg.GridTemplateId
    end
    return 0
end

function XNonogramConfigModel:GetStageFirstTipIndexStrById(id)
    local cfg = self:GetStageConfigById(id)
    if cfg then
        return cfg.FirstTipIndexStr
    end
end
--endregion

--region NonogramGrid
function XNonogramConfigModel:GetGridConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.NonogramGrid)
end

--function XNonogramConfigModel:GetGridConfigById(id)
--    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NonogramGrid, id)
--end
--
--function XNonogramConfigModel:GetGridTemplateIdById(id)
--    local cfg = self:GetGridConfigById(id)
--    if cfg then
--        return cfg.TemplateId
--    end
--    return 0
--end
--
--function XNonogramConfigModel:GetGridLineIndexById(id)
--    local cfg = self:GetGridConfigById(id)
--    if cfg then
--        return cfg.LineIndex
--    end
--    return 0
--end
--
--function XNonogramConfigModel:GetGridValuesById(id)
--    local cfg = self:GetGridConfigById(id)
--    if cfg then
--        return cfg.Values
--    end
--    return {}
--end

function XNonogramConfigModel:GetGridMapByTemplateId(templateId)
    local gridMap = {}
    local gridConfigs = self:GetGridConfigs()
    local configLines = {}
    for _, cfg in ipairs(gridConfigs) do
        if cfg.TemplateId == templateId then
            table.insert(configLines, cfg)
        end
    end

    table.sort(configLines, function (a, b)
        return a.LineIndex < b.LineIndex
    end)

    for _, cfg in ipairs(configLines) do
        table.insert(gridMap, cfg.Values)
    end
    
    return gridMap
end
--endregion

return XNonogramConfigModel