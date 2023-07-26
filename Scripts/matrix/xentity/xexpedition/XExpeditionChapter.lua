-- 虚像地平线章节对象
local XExpeditionChapter = XClass(nil, "XExpeditionChapter")
local XStage = require("XEntity/XExpedition/XExpeditionStage")
--================
--构造函数
--================
function XExpeditionChapter:Ctor(chapterId)
    self:Init(chapterId)
end
--================
--初始化
--================
function XExpeditionChapter:Init(chapterId)
    self.ChapterId = chapterId
    self.ChapterCfg = XExpeditionConfig.GetChapterCfgById(chapterId)
    self.NightMareWave = 0
    self.InfinityStageId = 0
    self:InitStages()
    self:InitInfinityStageId()
end
--================
--初始化关卡
--================
function XExpeditionChapter:InitStages()
    local stageIds = XExpeditionConfig.GetEStageIdsByChapterId(self:GetChapterId())
    self.Stages = {}
    self.StageId2EStageDic = {}
    for _, stageId in pairs(stageIds) do
        local eStage = XStage.New(stageId)
        table.insert(self.Stages, eStage)
        self.StageId2EStageDic[eStage:GetStageId()] = eStage
    end
end

function XExpeditionChapter:InitInfinityStageId()
    for _, stage in pairs(self.Stages) do
        if stage:GetIsInfinity() then
            self.InfinityStageId = stage:GetStageId()
        end
    end
end

function XExpeditionChapter:SetScore(score)
    self.Score = score
end
--================
--根据关卡表Id获取活动关卡对象
--@param stageId:Stage表Id
--================
function XExpeditionChapter:GetEStageByStageId(stageId)
    return self.StageId2EStageDic and self.StageId2EStageDic[stageId]
end
--================
--获取章节ID
--================
function XExpeditionChapter:GetChapterId()
    return self.ChapterId
end
--================
--获取章节时间ID
--================
function XExpeditionChapter:GetChapterTimeId()
    return self.ChapterCfg and self.ChapterCfg.TimeId or 0
end
--================
--获取关卡对象列表
--================
function XExpeditionChapter:GetStages()
    return self.Stages
end
--================
--获取无尽关卡当前波数
--================
function XExpeditionChapter:GetNightMareWave()
    if XTool.IsNumberValid(self.NightMareWave) then
        return self.NightMareWave
    end
    return 0
end
--================
--设置无尽关卡当前波数
--@param wave:波数
--================
function XExpeditionChapter:SetNightMareWave(wave)
    self.NightMareWave = wave
end
--================
--获取无线关关卡Id
--================
function XExpeditionChapter:GetInfinityStageId()
    return self.InfinityStageId
end


return XExpeditionChapter