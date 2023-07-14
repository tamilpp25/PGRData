-- 庆典类活动章节对象
---@class XFestivalChapter
local XFestivalChapter = XClass(nil, "XFestivalChapter")
--====================
--构造函数
--@param chapterId:章节ID
--====================
function XFestivalChapter:Ctor(chapterId)
    self.ChapterId = chapterId
    self:InitChapter()
    self:InitStages()
end
--====================
--初始化章节配置
--====================
function XFestivalChapter:InitChapter()
    self.ChapterCfg = XFestivalActivityConfig.GetFestivalById(self.ChapterId)
end
--====================
--初始化关卡对象
--====================
function XFestivalChapter:InitStages()
    self.Stages = {}
    ---@type XFestivalStage[]
    self.StageId2Stage = {}
    self.StagePassCount = 0
    self.StageTotalCount = 0
    if not self.ChapterCfg then return end
    local XFestivalStage = require("XEntity/XFestival/XFestivalStage")
    for index, stageId in pairs(self.ChapterCfg.StageId or {}) do
        local newStage = XFestivalStage.New(stageId, index, self)
        self.Stages[index] = newStage
        self.StageId2Stage[stageId] = newStage
        if not newStage:GetIsEggStage() then self.StageTotalCount = self.StageTotalCount + 1 end
        XDataCenter.FubenFestivalActivityManager.AddStageId2ChapterId(stageId, self.ChapterId)
    end
end

function XFestivalChapter:RefreshStages()
    for _, stage in pairs(self.Stages) do
        stage:RefreshStage()
    end
end
--====================
--获取章节ID
--====================
function XFestivalChapter:GetChapterId()
    return self.ChapterId
end
--====================
--获取是否开放
--====================
function XFestivalChapter:GetIsOffline()
    return self.ChapterCfg and self.ChapterCfg.Offline and self.ChapterCfg.Offline > 0 or false
end
--====================
--获取时间ID
--====================
function XFestivalChapter:GetTimeId()
    return self.ChapterCfg and self.ChapterCfg.TimeId or 0
end
--====================
--获取置顶展示时间ID
--====================
function XFestivalChapter:GetActivityTimeId()
    return self.ChapterCfg and self.ChapterCfg.ActivityTimeId or 0
end
--====================
--获取章节名称
--====================
function XFestivalChapter:GetName()
    return self.ChapterCfg and self.ChapterCfg.Name
end
--====================
--获取章节优先度
--====================
function XFestivalChapter:GetPriority()
    return self.ChapterCfg and self.ChapterCfg.Priority
end
--====================
--获取功能开放ID
--====================
function XFestivalChapter:GetFunctionOpenId()
    return self.ChapterCfg and self.ChapterCfg.FunctionOpenId
end
--====================
--获取主界面跳转页Id
--====================
function XFestivalChapter:GetSkipId()
    return self.ChapterCfg and self.ChapterCfg.SkipId
end
--====================
--获取章节关卡名前缀
--====================
function XFestivalChapter:GetStagePrefix()
    return self.ChapterCfg and self.ChapterCfg.StagePrefix
end
--====================
--获取入口图
--====================
function XFestivalChapter:GetBannerBg()
    return self.ChapterCfg and self.ChapterCfg.BannerBg
end
--====================
--获取章节类型
--====================
function XFestivalChapter:GetChapterType()
    return self.ChapterCfg and self.ChapterCfg.ChapterType
end
--====================
--获取Ui类型
--====================
function XFestivalChapter:GetUiType()
    return self.ChapterCfg and self.ChapterCfg.UiType
end
--====================
--获取主页面背景图
--====================
function XFestivalChapter:GetMainBackgound()
    return self.ChapterCfg and self.ChapterCfg.MainBackgound
end
--====================
--获取关卡路线图预制体
--====================
function XFestivalChapter:GetFubenPrefab()
    return self.ChapterCfg and self.ChapterCfg.FubenPrefab
end
--====================
--获取战斗关卡预制体
--====================
function XFestivalChapter:GetGridFubenPrefab()
    return self.ChapterCfg and self.ChapterCfg.GridFubenPrefab
end
--====================
--获取故事关卡预制体
--====================
function XFestivalChapter:GetGridStoryPrefab()
    return self.ChapterCfg and self.ChapterCfg.GridStoryPrefab
end
--====================
--获取标题图标
--====================
function XFestivalChapter:GetTitleIcon()
    return self.ChapterCfg and self.ChapterCfg.TitleIcon
end
--====================
--获取标题背景图
--====================
function XFestivalChapter:GetTitleBg()
    return self.ChapterCfg and self.ChapterCfg.TitleBg
end
--====================
--获取背景音乐ID
--====================
function XFestivalChapter:GetChapterBgm()
    return self.ChapterCfg and self.ChapterCfg.ChapterBgm
end
--====================
--获取总关卡数
--====================
function XFestivalChapter:GetStageTotalCount()
    return self.StageTotalCount or 0
end
--====================
--获取总通关关卡数
--====================
function XFestivalChapter:GetStagePassCount()
    return self.StagePassCount or 0
end
--====================
--根据关卡序号获取关卡对象
--@param orderIndex:关卡序号
--====================
function XFestivalChapter:GetStageByOrderIndex(orderIndex)
    return self.Stages[orderIndex]
end
--====================
--根据关卡ID获取关卡对象
--@param stageId:关卡Id
--====================
function XFestivalChapter:GetStageByStageId(stageId)
    return self.StageId2Stage[stageId]
end
--====================
--获取关卡ID列表
--====================
function XFestivalChapter:GetStageIdList()
    return self.ChapterCfg and self.ChapterCfg.StageId
end
--====================
--根据关卡ID获取关卡是否已通过
--@param stageId:关卡Id
--====================
function XFestivalChapter:GetChapterStageIsPass(stageId)
    if not stageId or stageId == 0 then return true end
    local stage = self.StageId2Stage[stageId]
    if not stage then
        stage = XDataCenter.FubenManager.GetStageInfo(stageId)
        return stage and stage.Passed or false
    end
    return stage:GetIsPass()
end
--====================
--获取是否已经通关
--@param stageId:关卡Id
--====================
function XFestivalChapter:GetChapterIsPassed()
    for id, stage in pairs(self.StageId2Stage) do
        if not self:GetChapterStageIsPass(id) then
            return false
        end
    end
    return true
end
--====================
--刷新章节关卡信息
--====================
function XFestivalChapter:RefreshChapterStageInfos()
    self.StagePassCount = 0
    for _, stage in pairs(self.Stages) do
        if stage then
            stage:RefreshStageInfo()
            if stage:GetIsPass() then self.StagePassCount = self.StagePassCount + 1 end
        end
    end
end
--====================
--获取章节是否在活动时间内
--====================
function XFestivalChapter:GetIsInTime()
    if self:GetIsOffline() then return false end
    local startTime, endTime = XFunctionManager.GetTimeByTimeId(self:GetTimeId())
    local nowTime = XTime.GetServerNowTimestamp()
    return (nowTime >= startTime) and (nowTime < endTime or endTime == 0)
end
--====================
--获取章节是否在活动时间内及对应提示文本
--====================
function XFestivalChapter:GetIsInTimeAndTips()
    if self:GetIsOffline() then return false, CS.XTextManager.GetText("EliminateNotOpen") end
    local nowTime = XTime.GetServerNowTimestamp()
    local beginTime, endTime = XFunctionManager.GetTimeByTimeId(self:GetTimeId())
    if beginTime ~= 0 and nowTime < beginTime then
        return false, CS.XTextManager.GetText("EliminateNotOpen")
    elseif endTime ~= 0 and nowTime > endTime then
        return false, CS.XTextManager.GetText("EliminateTimeOut")
    end
    return true, ""
end
--====================
--获取章节是否开放
--====================
function XFestivalChapter:GetIsOpen()
    return (not XFunctionManager.CheckFunctionFitter(self:GetFunctionOpenId())) and self:GetIsInTime()
end
--====================
--获取章节结束时间
--====================
function XFestivalChapter:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self:GetTimeId())
end
return XFestivalChapter