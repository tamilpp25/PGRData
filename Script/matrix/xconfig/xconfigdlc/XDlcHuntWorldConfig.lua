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
end

local function __InitConfigChapter()
    if not _ConfigChapter then
        _ConfigChapter = XConfig.New("Share/DlcHunt/World/DlcHuntChapter.tab", XTable.XTableDlcHuntBossChapter, "ChapterId")
    end
end

local function __InitConfigWorld()
    if not _ConfigWorld then
        _ConfigWorld = XConfig.New("Share/DlcHunt/World/DlcHuntWorld.tab", XTable.XTableDlcHuntWorld, "WorldId")
    end
end

local function __InitConfigDifficulty()
    if not _ConfigDifficulty then
        _ConfigDifficulty = XConfig.New("Client/DlcHunt/World/DlcHuntDifficulty.tab", XTable.XTableDlcHuntDifficulty, "Id")
    end
end

local function __InitConfigBossDetail()
    if not _ConfigBossDetail then
        _ConfigBossDetail = XConfig.New("Client/DlcHunt/World/DlcHuntBossDetail.tab", XTable.XTableDlcHuntBossDetail, "Id")
    end
end

local function __InitConfigBadge()
    if not _ConfigBadge then
        _ConfigBadge = XConfig.New("Share/DlcHunt/DlcHuntBadge.tab", XTable.XTableDlcHuntBadge, "Id")
    end
end

function XDlcHuntWorldConfig.GetAllChapter()
    __InitConfigChapter()
    return _ConfigChapter:GetConfigs()
end

function XDlcHuntWorldConfig.GetChapterName(chapterId)
    __InitConfigChapter()
    return _ConfigChapter:GetProperty(chapterId, "Name")
end

function XDlcHuntWorldConfig.GetChapterIndex(chapterId)
    __InitConfigChapter()
    return _ConfigChapter:GetProperty(chapterId, "Index")
end

function XDlcHuntWorldConfig.GetChapterDesc(chapterId)
    __InitConfigChapter()
    return _ConfigChapter:GetProperty(chapterId, "Desc")
end

function XDlcHuntWorldConfig.GetChapterWorlds(chapterId)
    __InitConfigChapter()
    return _ConfigChapter:GetProperty(chapterId, "WorldIds")
end

function XDlcHuntWorldConfig.GetChapterIcon(chapterId)
    __InitConfigChapter()
    return _ConfigChapter:GetProperty(chapterId, "Icon")
end

function XDlcHuntWorldConfig.GetChapterModel(chapterId)
    __InitConfigChapter()
    return _ConfigChapter:GetProperty(chapterId, "ModelId")
end

function XDlcHuntWorldConfig.GetChapterModel2(chapterId)
    __InitConfigChapter()
    return _ConfigChapter:GetProperty(chapterId, "ModelId2")
end

function XDlcHuntWorldConfig.GetChapterTimerId(chapterId)
    __InitConfigChapter()
    return _ConfigChapter:GetProperty(chapterId, "TimeId")
end

function XDlcHuntWorldConfig.GetChapterPreWorldId(chapterId)
    __InitConfigChapter()
    return _ConfigChapter:GetProperty(chapterId, "PreWorldId")
end

function XDlcHuntWorldConfig.IsWorldExist(worldId)
    __InitConfigWorld()
    local config = _ConfigWorld:TryGetConfig(worldId)
    return config and true or false
end

function XDlcHuntWorldConfig.GetWorldName(worldId)
    __InitConfigWorld()
    return _ConfigWorld:GetProperty(worldId, "Name")
end

function XDlcHuntWorldConfig.GetWorldLostTipId(worldId)
    __InitConfigWorld()
    return _ConfigWorld:GetProperty(worldId, "SettleLoseTipId")
end

function XDlcHuntWorldConfig.GetDifficultyId(worldId)
    __InitConfigWorld()
    return _ConfigWorld:GetProperty(worldId, "DifficultyId")
end

function XDlcHuntWorldConfig.GetWorldDifficultyName(worldId)
    __InitConfigDifficulty()
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "DifficultyName")
end

function XDlcHuntWorldConfig.GetWorldDifficultyDesc(worldId)
    __InitConfigDifficulty()
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "Des")
end

function XDlcHuntWorldConfig.GetWorldBossDetailId(worldId)
    __InitConfigDifficulty()
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "BossDetailId")
end

function XDlcHuntWorldConfig.GetWorldBossDetailIdOnPause(worldId)
    __InitConfigDifficulty()
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "BossDetailOnPause")
end

function XDlcHuntWorldConfig.GetWorldDifficultyNameEn(worldId)
    __InitConfigDifficulty()
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "EnName")
end

function XDlcHuntWorldConfig.GetWorldDifficultyLevel(worldId)
    __InitConfigDifficulty()
    return _ConfigDifficulty:GetProperty(XDlcHuntWorldConfig.GetDifficultyId(worldId), "DifficultyLevel")
end

function XDlcHuntWorldConfig.GetWorldFirstRewardId(worldId)
    __InitConfigWorld()
    return _ConfigWorld:GetProperty(worldId, "FirstRewardId")
end

function XDlcHuntWorldConfig.GetWorldReward(worldId)
    __InitConfigWorld()
    return _ConfigWorld:GetProperty(worldId, "FinishRewardShow")
end

function XDlcHuntWorldConfig.GetPreWorldId(worldId)
    __InitConfigWorld()
    return _ConfigWorld:GetProperty(worldId, "PreWorldId")
end

function XDlcHuntWorldConfig.GetWorldNeedFightingPower(worldId)
    __InitConfigWorld()
    return _ConfigWorld:GetProperty(worldId, "NeedFightPower")
end

function XDlcHuntWorldConfig.GetIsRank(worldId)
    __InitConfigWorld()
    return _ConfigWorld:GetProperty(worldId, "IsRank") == 1
end

function XDlcHuntWorldConfig.GetChapterId(worldId)
    __InitConfigChapter()
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
    __InitConfigBossDetail()
    return _ConfigBossDetail:GetConfig(bossDetailId)
end

function XDlcHuntWorldConfig.GetBadgeIcon(badgeId)
    __InitConfigBadge()
    return _ConfigBadge:GetProperty(badgeId, "Icon")
end

function XDlcHuntWorldConfig.GetBadgeName(badgeId)
    __InitConfigBadge()
    return _ConfigBadge:GetProperty(badgeId, "Name")
end

function XDlcHuntWorldConfig.GetBadgeDesc(badgeId)
    __InitConfigBadge()
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