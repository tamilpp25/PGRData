---@class XScoreTowerActivity
local XScoreTowerActivity = XClass(nil, "XScoreTowerActivity")

function XScoreTowerActivity:Ctor()
    -- 活动Id
    self.ActivityId = 0
    -- 当前章节Id
    self.CurChapterId = 0
    -- 章节数据
    ---@type XScoreTowerChapter[]
    self.ChapterDatas = {}
    -- 关卡分数记录
    ---@type XScoreTowerStageRecord[]
    self.StageRecords = {}
    -- 章节分数记录
    ---@type XScoreTowerChapterRecord[]
    self.ChapterRecords = {}
    -- 塔记录
    ---@type XScoreTowerTowerRecord[]
    self.TowerRecords = {}
    -- 塔扫荡次数
    ---@type table<number, number>
    self.TowerSweepRecord = {}
    -- 外循环
    ---@type XScoreTowerStrengthen[]
    self.Strengthens = {}
end

function XScoreTowerActivity:NotifyScoreTowerActivityData(data)
    self.ActivityId = data.ActivityNo or 0
    self.CurChapterId = data.CurChapterId or 0
    self:UpdateChapterDatas(data.ChapterDatas)
    self:UpdateStageRecords(data.StageRecords)
    self:UpdateChapterRecords(data.ChapterRecords)
    self:UpdateTowerRecords(data.TowerRecords)
    self.TowerSweepRecord = data.TowerSweepRecord or {}
    self:UpdateStrengthens(data.Strengthens)
end

--region 数据更新

-- 更新当前章节Id
function XScoreTowerActivity:SetCurChapterId(chapterId)
    self.CurChapterId = chapterId or 0
end

function XScoreTowerActivity:UpdateChapterDatas(data)
    self.ChapterDatas = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddChapterData(v)
    end
end

function XScoreTowerActivity:AddChapterData(data)
    if not data then
        return
    end
    local chapterData = self.ChapterDatas[data.ChapterId]
    if not chapterData then
        chapterData = require("XModule/XScoreTower/XEntity/Data/XScoreTowerChapter").New()
        self.ChapterDatas[data.ChapterId] = chapterData
    end
    chapterData:NotifyScoreTowerChapterData(data)
end

function XScoreTowerActivity:UpdateStageRecords(data)
    self.StageRecords = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddStageRecord(v)
    end
end

function XScoreTowerActivity:AddStageRecord(data)
    if not data then
        return
    end
    local stageRecord = self.StageRecords[data.StageCfgId]
    if not stageRecord then
        stageRecord = require("XModule/XScoreTower/XEntity/Data/XScoreTowerStageRecord").New()
        self.StageRecords[data.StageCfgId] = stageRecord
    end
    stageRecord:NotifyScoreTowerStageRecordData(data)
end

function XScoreTowerActivity:UpdateChapterRecords(data)
    self.ChapterRecords = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddChapterRecord(v)
    end
end

function XScoreTowerActivity:AddChapterRecord(data)
    if not data then
        return
    end
    local chapterRecord = self.ChapterRecords[data.ChapterId]
    if not chapterRecord then
        chapterRecord = require("XModule/XScoreTower/XEntity/Data/XScoreTowerChapterRecord").New()
        self.ChapterRecords[data.ChapterId] = chapterRecord
    end
    chapterRecord:NotifyScoreTowerChapterRecordData(data)
end

function XScoreTowerActivity:UpdateTowerRecords(data)
    self.TowerRecords = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddTowerRecord(v)
    end
end

function XScoreTowerActivity:AddTowerRecord(data)
    if not data then
        return
    end
    local towerRecord = self.TowerRecords[data.TowerId]
    if not towerRecord then
        towerRecord = require("XModule/XScoreTower/XEntity/Data/XScoreTowerTowerRecord").New()
        self.TowerRecords[data.TowerId] = towerRecord
    end
    towerRecord:NotifyScoreTowerTowerRecordData(data)
end

-- 设置塔扫荡次数
---@param towerId number 塔Id
---@param sweepCount number 扫荡次数
function XScoreTowerActivity:SetTowerSweepRecord(towerId, sweepCount)
    self.TowerSweepRecord[towerId] = sweepCount or 0
end

function XScoreTowerActivity:UpdateStrengthens(data)
    self.Strengthens = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddStrengthen(v)
    end
end

function XScoreTowerActivity:AddStrengthen(data)
    if not data then
        return
    end
    local strengthen = self.Strengthens[data.CfgId]
    if not strengthen then
        strengthen = require("XModule/XScoreTower/XEntity/Data/XScoreTowerStrengthen").New()
        self.Strengthens[data.CfgId] = strengthen
    end
    strengthen:NotifyScoreTowerStrengthenData(data)
end

--endregion

--region 数据获取

-- 获取活动Id
function XScoreTowerActivity:GetActivityId()
    return self.ActivityId
end

-- 获取当前章节Id
function XScoreTowerActivity:GetCurChapterId()
    return self.CurChapterId
end

-- 获取所有的章节数据
---@return XScoreTowerChapter[]
function XScoreTowerActivity:GetChapterDatas()
    return self.ChapterDatas
end

-- 获取章节数据
---@param chapterId number
---@return XScoreTowerChapter
function XScoreTowerActivity:GetChapterData(chapterId)
    return self.ChapterDatas[chapterId]
end

-- 获取所有的关卡分数记录
---@return XScoreTowerStageRecord[]
function XScoreTowerActivity:GetStageRecords()
    return self.StageRecords
end

-- 获取关卡分数记录
---@param stageCfgId number
---@return XScoreTowerStageRecord
function XScoreTowerActivity:GetStageRecord(stageCfgId)
    return self.StageRecords[stageCfgId]
end

-- 获取所有的章节分数记录
---@return XScoreTowerChapterRecord[]
function XScoreTowerActivity:GetChapterRecords()
    return self.ChapterRecords
end

-- 获取章节分数记录
---@param chapterId number
---@return XScoreTowerChapterRecord
function XScoreTowerActivity:GetChapterRecord(chapterId)
    return self.ChapterRecords[chapterId]
end

-- 获取所有的塔记录
---@return XScoreTowerTowerRecord[]
function XScoreTowerActivity:GetTowerRecords()
    return self.TowerRecords
end

-- 获取塔记录
---@param towerId number 塔Id
---@return XScoreTowerTowerRecord
function XScoreTowerActivity:GetTowerRecord(towerId)
    return self.TowerRecords[towerId]
end

-- 获取塔扫荡次数
---@param towerId number 塔Id
---@return number 扫荡次数
function XScoreTowerActivity:GetTowerSweepRecord(towerId)
    return self.TowerSweepRecord[towerId] or 0
end

-- 获取所有外循环
---@return XScoreTowerStrengthen[]
function XScoreTowerActivity:GetStrengthens()
    return self.Strengthens
end

-- 获取外循环
---@param cfgId number
---@return XScoreTowerStrengthen
function XScoreTowerActivity:GetStrengthen(cfgId)
    return self.Strengthens[cfgId]
end

--endregion

return XScoreTowerActivity
