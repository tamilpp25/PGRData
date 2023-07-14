XFubenBossOnlineConfig = XFubenBossOnlineConfig or {}

local OnlineBossSectionTemplates = {}
local OnlineBossChapterTemplates = {}
local OnlineBossRiskTemplates = {}

local TABLE_FUBEN_ONLINEBOSS_SECTION = "Share/Fuben/BossOnline/BossOnlineSection.tab"
local TABLE_FUBEN_ONLINEBOSS_CHAPTER = "Share/Fuben/BossOnline/BossOnlineChapter.tab"
local TABLE_FUBEN_ONLINEBOSS_RISK = "Share/Fuben/BossOnline/BossOnlineRisk.tab"

function XFubenBossOnlineConfig.Init()
    OnlineBossChapterTemplates = XTableManager.ReadByIntKey(TABLE_FUBEN_ONLINEBOSS_CHAPTER, XTable.XTableBossOnlineChapter, "Id")
    OnlineBossSectionTemplates = XTableManager.ReadByIntKey(TABLE_FUBEN_ONLINEBOSS_SECTION, XTable.XTableBossOnlineSection, "Id")
    OnlineBossRiskTemplates = XTableManager.ReadByIntKey(TABLE_FUBEN_ONLINEBOSS_RISK, XTable.XTableBossOnlineRisk, "Id")
end

function XFubenBossOnlineConfig.GetChapterTemplates()
    return OnlineBossChapterTemplates
end

function XFubenBossOnlineConfig.GetSectionTemplates()
    return OnlineBossSectionTemplates
end

function XFubenBossOnlineConfig.GetRiskTemplate(count)
    for _, v in pairs(OnlineBossRiskTemplates) do
        if (v.MinCount <= 0 or count >= v.MinCount) and (v.MaxCount <= 0 or count <= v.MaxCount) then
            return v
        end
    end
end