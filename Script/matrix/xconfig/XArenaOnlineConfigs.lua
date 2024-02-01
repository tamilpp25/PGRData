XArenaOnlineConfigs = XArenaOnlineConfigs or {}

local TABLE_ARENAONLINE_CHAPTER = "Share/Fuben/ArenaOnline/ArenaOnlineChapter.tab"
local TABLE_ARENAONLINE_SECTION = "Share/Fuben/ArenaOnline/ArenaOnlineSection.tab"
local TABLE_ARENAONLINE_STAGEGROUP = "Share/Fuben/ArenaOnline/ArenaOnlineStageGroup.tab"
local TABLE_ARENAONLINE_STAGE = "Share/Fuben/ArenaOnline/ArenaOnlineStage.tab"
local TABLE_ARENAONLINE_ACTIVEBUFF = "Share/Fuben/ArenaOnline/ArenaOnlineActiveBuff.tab"
--local TABLE_NPC_AFFIX = "Client/Fight/Npc/NpcAffix.tab"
local TABLE_BOSS_ONLINE_INVITE = "Client/Fuben/BossOnline/BossOnlineInvite.tab"

local ArenaOnlineChapterCfg = {}
local ArenaOnlineSectionCfg = {}
local ArenaOnlineStageGroupCfg = {}
local ArenaOnlineStageCfg = {}
local ArenaOnlineActiveBuffCfg = {}
local BossOnlineInvite = {}
--local NpcAffixCfg = {}
XArenaOnlineConfigs.MAX_NAILI = CS.XGame.Config:GetInt("ArenaOnlineCharMaxEndurance")
XArenaOnlineConfigs.SHOW_TIME = CS.XGame.ClientConfig:GetInt("ArenaOnlineInviteShowTime")
XArenaOnlineConfigs.DEFAULT_CHAPTERID = CS.XGame.ClientConfig:GetInt("ArenaOnlineDefualtChapterId")

XArenaOnlineConfigs.MaskArenOnlineUIName = {
    UiPurchase = "UiPurchase",
    UiDraw = "UiDraw",
    UiMultiplayerRoom = "UiMultiplayerRoom",
    UiMultiplayerInviteFriend = "UiMultiplayerInviteFriend",
    UiSocial = "UiSocial",
    UiRoomCharacter = "UiRoomCharacter",
    UiDrawMain = "UiNewDrawMain",
    UiLoading = "UiLoading"
}
function XArenaOnlineConfigs.Init()
    ArenaOnlineChapterCfg = XTableManager.ReadByIntKey(TABLE_ARENAONLINE_CHAPTER, XTable.XTableArenaOnlineChapter, "Id")
    ArenaOnlineSectionCfg = XTableManager.ReadByIntKey(TABLE_ARENAONLINE_SECTION, XTable.XTableArenaOnlineSection, "Id")
    ArenaOnlineStageGroupCfg = XTableManager.ReadAllByIntKey(TABLE_ARENAONLINE_STAGEGROUP, XTable.XTableArenaOnlineStageGroup, "Id")
    ArenaOnlineStageCfg = XTableManager.ReadAllByIntKey(TABLE_ARENAONLINE_STAGE, XTable.XTableArenaOnlineStage, "Id")
    ArenaOnlineActiveBuffCfg = XTableManager.ReadByIntKey(TABLE_ARENAONLINE_ACTIVEBUFF, XTable.XTableArenaOnlineActiveBuff, "Id")
    BossOnlineInvite = XTableManager.ReadByIntKey(TABLE_BOSS_ONLINE_INVITE, XTable.XTableBossOnlineInvite, "Id")
    
    --NpcAffixCfg = XTableManager.ReadByIntKey(TABLE_NPC_AFFIX, XTable.XTableNpcAffix, "Id")
    XArenaOnlineConfigs.ArenaOnlineShowTime = CS.XGame.ClientConfig:GetInt("ArenaOnlineShowTime") or -1
end

function XArenaOnlineConfigs.GetChapters()
    return ArenaOnlineChapterCfg
end

function XArenaOnlineConfigs.GetStages()
    return ArenaOnlineStageCfg
end

function XArenaOnlineConfigs.GetChapterById(chapterId)
    local chapter = ArenaOnlineChapterCfg[chapterId]

    if not chapter then
        XLog.ErrorTableDataNotFound("XArenaOnlineConfigs.GetChapterById", "chapter", TABLE_ARENAONLINE_CHAPTER, "chapterId", tostring(chapterId))
        return nil
    end

    return chapter
end

function XArenaOnlineConfigs.GetSectionById(sectionId)
    local section = ArenaOnlineSectionCfg[sectionId]

    if not section then
        XLog.ErrorTableDataNotFound("XArenaOnlineConfigs.GetSectionById", "section", TABLE_ARENAONLINE_SECTION, "sectionId", tostring(sectionId))
        return nil
    end

    return section
end

function XArenaOnlineConfigs.GetStageById(stageId)
    local stage = ArenaOnlineStageCfg[stageId]

    if not stage then
        XLog.ErrorTableDataNotFound("XArenaOnlineConfigs.GetStageById", "stage", TABLE_ARENAONLINE_STAGE, "stageId", tostring(stageId))
        return nil
    end

    return stage
end

function XArenaOnlineConfigs.GetStageGroupById(groupId)
    local group = ArenaOnlineStageGroupCfg[groupId]

    if not group then
        XLog.ErrorTableDataNotFound("XArenaOnlineConfigs.GetStageGroupById", "group", TABLE_ARENAONLINE_STAGEGROUP, "groupId", tostring(groupId))
        return nil
    end

    return group
end

function XArenaOnlineConfigs.GetStageGroupPrefabPathById(groupId)
    local cfg = XArenaOnlineConfigs.GetStageGroupById(groupId)
    if cfg then
        return cfg.PrefabPath
    end
end

function XArenaOnlineConfigs.GetStageGroupIconById(groupId)
    local cfg = XArenaOnlineConfigs.GetStageGroupById(groupId)
    if cfg then
        return cfg.Icon
    end
end
function XArenaOnlineConfigs.GetActiveBuffById(activeBuffId)
    local buff = ArenaOnlineActiveBuffCfg[activeBuffId]

    if not buff then
        XLog.ErrorTableDataNotFound("XArenaOnlineConfigs.GetActiveBuffById",
        "buff", TABLE_ARENAONLINE_ACTIVEBUFF, "activeBuffId", tostring(activeBuffId))
        return nil
    end

    return buff
end

function XArenaOnlineConfigs.GetNpcAffixById(buffId)
    local npcAffix = nil

    if CS.XNpcManager.AffixTable:ContainsKey(buffId) then
        npcAffix = CS.XNpcManager.AffixTable[buffId]
    end

    if not npcAffix then
        XLog.ErrorTableDataNotFound("XArenaOnlineConfigs.GetNpcAffixById", "npcAffix", TABLE_NPC_AFFIX, "buffId", tostring(buffId))
        return nil
    end

    return npcAffix
end


function XArenaOnlineConfigs.GetChaprerNameByChapterId(chapterId)
    local chapter = XArenaOnlineConfigs.GetChapterById(chapterId)
    return chapter.Name
end

function XArenaOnlineConfigs.GetStageSortByStageId(stageId)
    local stage = XArenaOnlineConfigs.GetStageById(stageId)
    return stage.Sort
end

function XArenaOnlineConfigs.GetStageEnduranceCostByStageId(stageId)
    local stage = XArenaOnlineConfigs.GetStageById(stageId)
    return stage.EnduranceCost
end

function XArenaOnlineConfigs.GetStageActiveBuffIdByStageId(stageId)
    local stage = XArenaOnlineConfigs.GetStageById(stageId)
    return stage.ActiveBuffId
end

function XArenaOnlineConfigs.GetStageBottomCountByStageId(stageId)
    local stage = XArenaOnlineConfigs.GetStageById(stageId)
    return stage.BottomCount
end

function XArenaOnlineConfigs.GetStageDropKeyByStageId(stageId)
    local stage = XArenaOnlineConfigs.GetStageById(stageId)
    return tostring(stage.ShowDropId) .. tostring(stage.ShowBottomId)
end


function XArenaOnlineConfigs.GetStageGroupRequireStar(groupId)
    local group = XArenaOnlineConfigs.GetStageGroupById(groupId)
    return group.RequireStar
end

function XArenaOnlineConfigs.GetFirstChapterName()
    local name = ""
    for _, v in pairs(ArenaOnlineChapterCfg) do
        name = v.Name
        break
    end

    return name
end

local _BossOnlineInviteUi
function XArenaOnlineConfigs.GetBossOnlineInviteUi()
    if _BossOnlineInviteUi then
        return _BossOnlineInviteUi
    end
    _BossOnlineInviteUi = {}
    for i, v in pairs(BossOnlineInvite) do
        _BossOnlineInviteUi[v.UiName] = true
    end
    return _BossOnlineInviteUi
end 