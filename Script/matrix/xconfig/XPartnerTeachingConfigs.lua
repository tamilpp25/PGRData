XPartnerTeachingConfigs = XPartnerTeachingConfigs or {}

local TABLE_PARTNER_TEACHING_CHAPTER = "Share/Fuben/PartnerTeaching/PartnerTeachingChapter.tab"

local PartnerTeachingChapter = {}

function XPartnerTeachingConfigs.Init()
    PartnerTeachingChapter = XTableManager.ReadByIntKey(TABLE_PARTNER_TEACHING_CHAPTER, XTable.XTablePartnerTeachingChapter, "Id")
end

local function GetPartnerTeachingChapterCfg(chapterId)
    local config = PartnerTeachingChapter[chapterId]
    if not config then
        XLog.ErrorTableDataNotFound("XPartnerTeachingConfigs.GetPartnerTeachingChapterCfg",
                "辅助机教学章节", TABLE_PARTNER_TEACHING_CHAPTER, "Id", tostring(chapterId))
        return {}
    end
    return config
end

---
--- 获取所有的教学章节Id
function XPartnerTeachingConfigs.GetAllChapterId()
    local result = {}
    for id, _ in pairs(PartnerTeachingChapter) do
        table.insert(result, id)
    end
    return result
end

---
--- 根据 'chapterId' 获取章节名称
function XPartnerTeachingConfigs.GetChapterName(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.Name
end

---
--- 根据 'chapterId' 获取活动时间
function XPartnerTeachingConfigs.GetChapterActivityTimeId(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.ActivityTimeId
end

---
--- 根据 'chapterId' 获取活动期间展示在副本入口的封面图
function XPartnerTeachingConfigs.GetActivityChapterIconById(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.ChapterIcon
end

---
---@return table
--- 根据 'chapterId' 获取活动开启条件数组
function XPartnerTeachingConfigs.GetChapterActivityCondition(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.ActivityCondition
end

---
--- 根据 'chapterId' 获取开启条件数据
---@return table
function XPartnerTeachingConfigs.GetChapterOpenCondition(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.OpenCondition
end

---
--- 根据 'chapterId' 获取章节图标
function XPartnerTeachingConfigs.GetChapterBannerIcon(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.BannerIcon
end

---
--- 根据 'chapterId' 获取章节背景
function XPartnerTeachingConfigs.GetChapterBackground(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.Background
end

---
--- 根据 'chapterId' 获取章节预制体
function XPartnerTeachingConfigs.GetChapterFubenPrefab(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.FubenPrefab
end

---
--- 根据 'chapterId' 获取战斗关卡预制体
function XPartnerTeachingConfigs.GetChapterFightStagePrefab(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.FightStagePrefab
end

---
--- 根据 'chapterId' 获取故事关卡预制体
function XPartnerTeachingConfigs.GetChapterStoryStagePrefab(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.StoryStagePrefab
end

---
--- 根据 'chapterId' 获取关卡数组
---@return table
function XPartnerTeachingConfigs.GetChapterStageIds(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.StageIds
end

---
--- 根据 'chapterId' 获取关卡编号前缀
---@return string
function XPartnerTeachingConfigs.GetChapterStagePrefix(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.StagePrefix
end

---
--- 根据 'chapterId' 获取剧情关卡详情的背景图
---@return string
function XPartnerTeachingConfigs.GetChapterStoryStageDetailBg(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.StoryStageDetailBg
end

---
--- 根据 'chapterId' 获取剧情关卡详情开始按钮的图标
---@return string
function XPartnerTeachingConfigs.GetChapterStoryStageDetailIcon(chapterId)
    local cfg = GetPartnerTeachingChapterCfg(chapterId)
    return cfg.StoryStageDetailIcon
end