 --- 一个主线或外篇章节对应一个周目(ZhouMuId)，把周目（ZhouMuId）当成一个模式，第几周目对应周目的第几个周目章节(ZhouMuChapterId)

XFubenZhouMuConfigs = XFubenZhouMuConfigs or {}

local TABLE_ZHOUMU = "Share/Fuben/ZhouMu/ZhouMu.tab"
local TABLE_ZHOUMU_CHAPTER = "Share/Fuben/ZhouMu/ZhouMuChapter.tab"

local ZhouMuCfg = {}
local ZhouMuChapterCfg = {}

-- 播放周目弹窗动画的类型
XFubenZhouMuConfigs.EnumZhouMuTipAnima = {
    None = 1,           -- 无动画
    PlayStart = 2,      -- 周目开始
    PlayEndStart = 3,   -- 先播放周目结束，然后再播放周目开启
    PlayEnd = 4,        -- 周目结束
}

function XFubenZhouMuConfigs.Init()
    ZhouMuCfg = XTableManager.ReadByIntKey(TABLE_ZHOUMU, XTable.XTableZhouMu, "Id")
    ZhouMuChapterCfg = XTableManager.ReadByIntKey(TABLE_ZHOUMU_CHAPTER, XTable.XTableZhouMuChapter, "Id")
end

------------------------------------------------------------------ ZhouMu.tab数据读取 -------------------------------------------------------

---
--- 根据'zhouMuId'获取多周目章节配置
---@param zhouMuChapterId number
---@return table
function XFubenZhouMuConfigs.GetZhouMuCfg(zhouMuId)
    local config = ZhouMuCfg[zhouMuId]

    if not config then
        XLog.ErrorTableDataNotFound("XFubenZhouMuConfigs.GetZhouMuCfg",
                "多周目章节配置", TABLE_ZHOUMU, "Id", tostring(zhouMuId))
        return {}
    end

    return config
end

---
--- 根据'zhouMuId'获取周目章节Id数组
---@param zhouMuId number
---@return table
function XFubenZhouMuConfigs.GetZhouMuChapters(zhouMuId)
    local config = XFubenZhouMuConfigs.GetZhouMuCfg(zhouMuId)
    return config.ChapterId or {}
end

---
--- 根据'zhouMuId'获取周目挑战任务Id数组
---@param zhouMuId number
---@return table
function XFubenZhouMuConfigs.GetZhouMuTasks(zhouMuId)
    local config = XFubenZhouMuConfigs.GetZhouMuCfg(zhouMuId)
    return config.TaskId or {}
end

---
--- 根据'zhouMuId'获取最后一个周目章节Id
---@param zhouMuId number
---@return number
function XFubenZhouMuConfigs.GetZhouMuLastChapter(zhouMuId)
    local zhouMuChapters = XFubenZhouMuConfigs.GetZhouMuChapters(zhouMuId)
    return zhouMuChapters[#zhouMuChapters]
end


------------------------------------------------------------------ ZhouMuChapter.tab数据读取 -------------------------------------------------------

 ---
 --- 获取整个ZhouMuChapter配表数据
 ---@return table
 function XFubenZhouMuConfigs.GetAllZhouMuChapterCfg()
     return ZhouMuChapterCfg
 end

---
--- 根据'zhouMuChapterId'获取周目章节配置
---@param zhouMuChapterId number
---@return table
function XFubenZhouMuConfigs.GetZhouMuChapterCfg(zhouMuChapterId)
    local config = ZhouMuChapterCfg[zhouMuChapterId]

    if not config then
        XLog.ErrorTableDataNotFound("XFubenZhouMuConfigs.GetZhouMuChapterCfg",
                "多周目章节配置", TABLE_ZHOUMU_CHAPTER, "Id", tostring(zhouMuChapterId))
        return {}
    end

    return config
end

---
--- 根据'zhouMuChapterId'获取周目章节的解锁条件数组
---@param zhouMuChapterId number
---@return table
function XFubenZhouMuConfigs.GetZhouMuChapterCondition(zhouMuChapterId)
    local config = XFubenZhouMuConfigs.GetZhouMuChapterCfg(zhouMuChapterId)
    return config.ConditionId or {}
end

---
--- 根据'zhouMuChapterId'获取周目章节的关卡数组
---@param zhouMuChapterId number
---@return table
function XFubenZhouMuConfigs.GetZhouMuChapterStages(zhouMuChapterId)
    local config = XFubenZhouMuConfigs.GetZhouMuChapterCfg(zhouMuChapterId)

    if config.StageId == nil or #config.StageId == 0 then
        XLog.ErrorTableDataNotFound("XFubenZhouMuConfigs.GetZhouMuChapterStages",
                "多周目章节关卡", TABLE_ZHOUMU_CHAPTER, "Id", tostring(zhouMuChapterId))
        return {}
    end

    return config.StageId
end

---
--- 根据'zhouMuChapterId'获取周目章节最后一个关卡Id
---@param zhouMuChapterId number
---@return number
function XFubenZhouMuConfigs.GetZhouMuChapterLastStage(zhouMuChapterId)
    local stages = XFubenZhouMuConfigs.GetZhouMuChapterStages(zhouMuChapterId)
    return stages[#stages]
end