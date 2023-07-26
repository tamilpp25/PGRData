-- 在dlcHunt里，world = stage
XDlcHuntWorldConfig = XDlcHuntWorldConfig or {}

XDlcHuntWorldConfig.CHAPTER_LOCK_STATE = {
    NONE = 1,
    LOCK_FOR_TIME = 2,
    LOCK_FOR_FRONT_WORLD_NOT_PASS = 3
}

---@type XConfig
local _ConfigChapter

---@type XConfig
local _ConfigDifficulty

---@type XConfig
local _ConfigWorld

---@type XConfig
local _ConfigBossDetail

---@type XConfig
local _ConfigBadge

function XDlcHuntWorldConfig.Init()
    _ConfigChapter = XConfig.New("Share/DlcHunt/World/DlcHuntChapter.tab", XTable.XTableDlcHuntBossChapter, "ChapterId")
    _ConfigWorld = XConfig.New("Share/DlcHunt/World/DlcHuntWorld.tab", XTable.XTableDlcHuntWorld, "WorldId")
    _ConfigDifficulty = XConfig.New("Client/DlcHunt/World/DlcHuntDifficulty.tab", XTable.XTableDlcHuntDifficulty, "Id")
    _ConfigBossDetail = XConfig.New("Client/DlcHunt/World/DlcHuntBossDetail.tab", XTable.XTableDlcHuntBossDetail, "Id")
    _ConfigBadge = XConfig.New("Share/DlcHunt/DlcHuntBadge.tab", XTable.XTableDlcHuntBadge, "Id")
end

function XDlcHuntWorldConfig.GetAllChapter()
    return _ConfigChapter:GetConfigs()
end

function XDlcHuntWorldConfig.GetChapterName(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "Name")
end

function XDlcHuntWorldConfig.GetChapterIndex(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "Index")
end

function XDlcHuntWorldConfig.GetChapterDesc(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "Desc")
end

function XDlcHuntWorldConfig.GetChapterWorlds(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "WorldIds")
end

function XDlcHuntWorldConfig.GetChapterIcon(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "Icon")
end

function XDlcHuntWorldConfig.GetChapterModel(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "ModelId")
end

function XDlcHuntWorldConfig.GetChapterModel2(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "ModelId2")
end

function XDlcHuntWorldConfig.GetChapterTimerId(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "TimeId")
end

function XDlcHuntWorldConfig.GetChapterPreWorldId(chapterId)
    return _ConfigChapter:GetProperty(chapterId, "PreWorldId")
end

function XDlcHuntWorldConfig.IsWorldExist(worldId)
    local config = _ConfigWorld:TryGetConfig(worldId)
    return config and true or false
end

function XDlcHuntWorldConfig.GetWorldName(worldId)
    return _ConfigWorld:GetProperty(worldId, "Name")
end

function XDlcHuntWorldConfig.GetWorldLostTipId(worldId)
    return _ConfigWorld:GetProperty(worldId, "SettleLoseTipId")
end

function XDlcHuntWorldConfig.GetDifficultyId(worldId)
    return _ConfigWorld:GetProperty(worldId, "DifficultyId")
end

function XDlcHuntWorldConfig.GetWorldDifficultyName(worldId)
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "DifficultyName")
end

function XDlcHuntWorldConfig.GetWorldDifficultyDesc(worldId)
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "Des")
end

function XDlcHuntWorldConfig.GetWorldBossDetailId(worldId)
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "BossDetailId")
end

function XDlcHuntWorldConfig.GetWorldBossDetailIdOnPause(worldId)
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "BossDetailOnPause")
end

function XDlcHuntWorldConfig.GetWorldDifficultyNameEn(worldId)
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "EnName")
end

function XDlcHuntWorldConfig.GetWorldDifficultyLevel(worldId)
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "DifficultyLevel")
end

function XDlcHuntWorldConfig.GetWorldFirstRewardId(worldId)
    return _ConfigWorld:GetProperty(worldId, "FirstRewardId")
end

function XDlcHuntWorldConfig.GetWorldReward(worldId)
    return _ConfigWorld:GetProperty(worldId, "FinishRewardShow")
end

function XDlcHuntWorldConfig.GetPreWorldId(worldId)
    return _ConfigWorld:GetProperty(worldId, "PreWorldId")
end

function XDlcHuntWorldConfig.GetWorldNeedFightingPower(worldId)
    return _ConfigWorld:GetProperty(worldId, "NeedFightPower")
end

function XDlcHuntWorldConfig.GetIsRank(worldId)
    return _ConfigWorld:GetProperty(worldId, "IsRank") == 1
end

function XDlcHuntWorldConfig.GetChapterId(worldId)
    local chapters = _ConfigChapter:GetConfigs()
    for chapterId, config in pairs(chapters) do
        local worlds = config.WorldIds
        for i = 1, #worlds do
            if worlds[i] == worldId then
                return chapterId
            end
        end
    end
    return false
end

function XDlcHuntWorldConfig.GetBossDetail(bossDetailId)
    return _ConfigBossDetail:GetConfig(bossDetailId)
end

function XDlcHuntWorldConfig.GetBadgeIcon(badgeId)
    return _ConfigBadge:GetProperty(badgeId, "Icon")
end

function XDlcHuntWorldConfig.GetBadgeName(badgeId)
    return _ConfigBadge:GetProperty(badgeId, "Name")
end

function XDlcHuntWorldConfig.GetBadgeDesc(badgeId)
    return _ConfigBadge:GetProperty(badgeId, "Des")
end

-- 可破坏部位
function XDlcHuntWorldConfig.GetBossPartsCanBreak(world)
    local result = {}
    local worldId = world:GetWorldId()
    local bossDetailId = XDlcHuntWorldConfig.GetWorldBossDetailId(worldId)
    local bossDetail = XDlcHuntWorldConfig.GetBossDetail(bossDetailId)
    for i = 1, #bossDetail.TipName do
        result[#result + 1] = {
            Index = i,
            Name = bossDetail.TipName[i],
            Desc = XUiHelper.ReplaceTextNewLine(bossDetail.TipDes[i] or ""),
            Icon = bossDetail.TipAsset[i] or "",
        }
    end
    return result
end

function XDlcHuntWorldConfig.GetWorldBossDetailOnPause(worldId)
    local result = {}
    local bossDetailId = XDlcHuntWorldConfig.GetWorldBossDetailIdOnPause(worldId)
    local bossDetail = XDlcHuntWorldConfig.GetBossDetail(bossDetailId)
    for i = 1, #bossDetail.TipName do
        result[#result + 1] = {
            Index = i,
            Name = bossDetail.TipName[i],
            Desc = bossDetail.TipDes[i] or "",
        }
    end
    return result
end 