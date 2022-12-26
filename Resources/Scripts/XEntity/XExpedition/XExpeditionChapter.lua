-- 虚像地平线章节对象
local XExpeditionChapter = XClass(nil, "XExpeditionChapter")
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
    self.NormalStageLastPassIndex = 1
    self.NightMareStageLastPassIndex = 1
    self.NightMareWave = 0
    self:RefreshChapter(chapterId)
end
--================
--刷新章节
--================
function XExpeditionChapter:RefreshChapter(chapterId)
    self.ChapterId = chapterId
    self.ChapterCfg = XExpeditionConfig.GetChapterCfgById(chapterId)
    self:InitStage()
    self.NormalStageLastPassIndex = 1
    self.NightMareStageLastPassIndex = 1
    self:RefreshNormalStage()
    self:RefreshNightMareStage()
end
--================
--初始化关卡数据
--================
function XExpeditionChapter:InitStage()
    local eStageCfgs = XExpeditionConfig.GetEStageListByChapterId(self:GetChapterId())
    self.NormalStages = {}
    self.NightMareStages = {}
    self.AllStages = {}
    for _, eStageCfg in pairs(eStageCfgs) do
        local eStage = XDataCenter.ExpeditionManager.GetEStageByEStageId(eStageCfg.Id)
        if eStage then
            if eStage:GetIsNightMareStage() then
                table.insert(self.NightMareStages, eStage)
            else
                table.insert(self.NormalStages, eStage)
            end
        end
    end
    self.TotalNormalStageNum = #self.NormalStages or 0
    self.TotalNightMareStageNum = #self.NightMareStages or 0
end
--================
--刷新普通关卡数据
--================
function XExpeditionChapter:RefreshNormalStage()
    self.NormalAllClear = true
    for index = self.NormalStageLastPassIndex > 0 and self.NormalStageLastPassIndex or 1, #self.NormalStages do
        local eStage = self.NormalStages[index]
        if index == 1 and (not eStage:GetIsPass()) then
            self.NormalStageLastPassIndex = 0
        elseif eStage:GetIsPass() then
            self.NormalStageLastPassIndex = index
        else
            self.NormalAllClear = false
        end
    end
    -- 获取当前关卡进度
    self.CurrentNormalIndex = (self.NormalStageLastPassIndex < self.TotalNormalStageNum and (self.NormalStageLastPassIndex + 1)) or self.TotalNormalStageNum
end
--================
--刷新噩梦关卡数据
--================
function XExpeditionChapter:RefreshNightMareStage()
    self.NightMareAllClear = true
    for index = self.NightMareStageLastPassIndex > 0 and self.NightMareStageLastPassIndex or 1, #self.NightMareStages do
        local eStage = self.NightMareStages[index]
        if index == 1 and (not eStage:GetIsPass()) then
            self.NightMareStageLastPassIndex = 0
        elseif eStage:GetIsPass() then
            self.NightMareStageLastPassIndex = index
        else
            self.NightMareAllClear = false
        end
    end
    -- 获取当前关卡进度
    self.CurrentNightMareIndex = (self.NightMareStageLastPassIndex < self.TotalNightMareStageNum and (self.NightMareStageLastPassIndex + 1)) or self.TotalNightMareStageNum
end

function XExpeditionChapter:GetStageCompletePercent(difficulty)
    if difficulty == XDataCenter.ExpeditionManager.StageDifficulty.Normal then
        return self.NormalStageLastPassIndex / self.TotalNormalStageNum
    else
        return self.NightMareStageLastPassIndex / self.TotalNightMareStageNum
    end
end

--================
--获取章节进度字符串
--================
function XExpeditionChapter:GetStageCompleteStr(difficulty)
    if difficulty == XDataCenter.ExpeditionManager.StageDifficulty.Normal then
        return self:GetNormalStageCompleteStr()
    else
        return self:GetNightMareStageCompleteStr()
    end
end
--================
--获取普通关卡进度字符串
--================
function XExpeditionChapter:GetNormalStageCompleteStr()
    return string.format("%d/%d", self.NormalStageLastPassIndex, self.TotalNormalStageNum)
end
--================
--获取噩梦关卡进度字符串
--================
function XExpeditionChapter:GetNightMareStageCompleteStr()
    return string.format("%d/%d", self.NightMareStageLastPassIndex, self.TotalNightMareStageNum)
end
--================
--获取章节ID
--================
function XExpeditionChapter:GetChapterId()
    return self.ChapterId
end
--================
--根据难度获取章节预制体
--@param difficulty:难度
--================
function XExpeditionChapter:GetChapterPrefabByDifficulty(difficulty)
    return self.ChapterCfg and self.ChapterCfg.PrefabPath and self.ChapterCfg.PrefabPath[difficulty]
end
--================
--根据难度获取关卡背景图
--@param difficulty:难度
--================
function XExpeditionChapter:GetStageBgByDifficult(difficulty)
    return self.ChapterCfg and self.ChapterCfg.StageBgPath and self.ChapterCfg.StageBgPath[difficulty]
end
--================
--根据难度获取关卡背景特效
--@param difficulty:难度
--================
function XExpeditionChapter:GetChapterBgFxByDifficult(difficulty)
    return self.ChapterCfg and self.ChapterCfg.BgFx and self.ChapterCfg.BgFx[difficulty]
end
--================
--根据难度获取章节奖励图标地址
--@param difficulty:难度
--================
function XExpeditionChapter:GetRewardIconByDifficult(difficulty)
    return self.ChapterCfg and self.ChapterCfg.RewardIcon and self.ChapterCfg.RewardIcon[difficulty]
end
--================
--根据难度获取关卡对象列表
--================
function XExpeditionChapter:GetStagesByDifficulty(difficulty)
    if difficulty == XDataCenter.ExpeditionManager.StageDifficulty.Normal then
        return self:GetNoramlEStages()
    else
        return self:GetNightMareEStages()
    end
end
--================
--获取普通关卡对象列表
--================
function XExpeditionChapter:GetNoramlEStages()
    return self.NormalStages
end
--================
--获取噩梦关卡对象列表
--================
function XExpeditionChapter:GetNightMareEStages()
    return self.NightMareStages
end
--================
--根据难度获取该难度关卡是否全部完成
--================
function XExpeditionChapter:GetIsClearByDifficulty(difficulty)
    if difficulty == XDataCenter.ExpeditionManager.StageDifficulty.Normal then
        return self:GetIsNormalClear()
    else
        return self:GetIsNightMareClear()
    end
end
--================
--获取普通关卡是否全部完成
--================
function XExpeditionChapter:GetIsNormalClear()
    return self.NormalAllClear
end
--================
--获取噩梦关卡是否全部完成
--================
function XExpeditionChapter:GetIsNightMareClear()
    return self.NightMareAllClear
end
--================
--根据难度获取当前关卡
--================
function XExpeditionChapter:GetCurrentIndexByDifficulty(difficulty)
    if difficulty == XDataCenter.ExpeditionManager.StageDifficulty.Normal then
        return self:GetNoramlCurrentIndex()
    else
        return self:GetNightMareCurrentIndex()
    end
end
--================
--获取当前章节通关的最后关卡
--================
function XExpeditionChapter:GetLastStage()
    if self:GetIsNormalClear() then
        if self.NightMareStageLastPassIndex == 0 then return self.NormalStages[self.NormalStageLastPassIndex] end
        local lastIndex = self.NightMareStageLastPassIndex
        return self.NightMareStages[lastIndex]
    else
        if self.NormalStageLastPassIndex == 0 then return nil end
        return self.NormalStages[self.NormalStageLastPassIndex]
    end
end
--================
--获取普通关卡当前关卡
--================
function XExpeditionChapter:GetNoramlCurrentIndex()
    return self.CurrentNormalIndex or 1
end
--================
--获取噩梦关卡当前关卡
--================
function XExpeditionChapter:GetNightMareCurrentIndex()
    return self.CurrentNightMareIndex or 1
end
--================
--获取噩梦无尽关卡当前波数
--================
function XExpeditionChapter:GetNightMareWave()
    return (self.NightMareWave and self.NightMareWave > 0 and (self.NightMareWave - 1)) or 0
end
--================
--设置噩梦无尽关卡当前波数
--@param wave:波数
--================
function XExpeditionChapter:SetNightMareWave(wave)
    self.NightMareWave = wave
end
--================
--根据难度获取通关奖励ID
--@param difficulty:难度
--================
function XExpeditionChapter:GetChapterReward(difficulty)
    return self.ChapterCfg and self.ChapterCfg.RewardId[difficulty]
end
return XExpeditionChapter