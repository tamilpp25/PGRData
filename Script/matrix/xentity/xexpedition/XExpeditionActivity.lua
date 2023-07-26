--虚像地平线活动对象
local XExpeditionActivity = XClass(nil, "XExpeditionActivity")
local XChapter = require("XEntity/XExpedition/XExpeditionChapter")
--================
--构造函数
--================
function XExpeditionActivity:Ctor(activityId)
    self:Init()
    self.ActivityCfg = XExpeditionConfig.GetExpeditionConfigById(activityId)
end
--================
--初始化
--================
function XExpeditionActivity:Init()
    self.RecruitLevel = 1 --招募等级
    self.RecruitTimes = 0 --剩余时间回复的可招募的次数
    self.NextRecruitAddTime = 0 --下一次自然恢复招募点时间
    self.ExtraDrawTimes = 0 --额外可招募的次数
    self.RecruitNum = 0 --已经招募过的次数
    self.DailyLikeCount = 0 --每天留言板可点赞次数，功能暂时已弃用
end

function XExpeditionActivity:InitChapters()
    self.Chapters = {}
    self.ChapterId2ChapterDic = {}
    local chapterIds = self:GetChapterIds()
    for index, id in pairs(chapterIds) do
        local chapter = XChapter.New(id)
        self.Chapters[index] = chapter
        self.ChapterId2ChapterDic[id] = chapter
    end
end
--================
--设置活动ID
--@param activityId:活动ID
--================
function XExpeditionActivity:SetActivityId(activityId)
    self.ActivityCfg = XExpeditionConfig.GetExpeditionConfigById(activityId)
    self:InitChapters()
    XDataCenter.ExpeditionManager.GetTeam():InitTeamPos(self:GetRecruitRobotMaxNum())
end
--================
--刷新活动参数
--@param data:服务器通知的活动参数
--================
function XExpeditionActivity:RefreshActivity(data)
    self.DailyLikeCount = data.DailyLikeCount
    self:UpdateRecruitTimes(data)
    self:RefreshStageInfos(data.Stages)
    self:RefreshEndlessStage(data.EndlessStage)
end
--================
--刷新招募相关参数
--================
function XExpeditionActivity:UpdateRecruitTimes(data, checkLevel)
    self.RecruitTimes = data.CanRefreshTimes or 0
    self.NextRecruitAddTime = data.RefreshTimesRecoveryTime or 0
    self.BuyRecruitTime = data.BuyRefreshTimes or 0
    self.ExtraDrawTimes = data.ExtraRefreshTimes or 0
    self.RecruitNum = data.RefreshTimes or 0
    local isRecruitLevelUp = false
    if checkLevel then
        isRecruitLevelUp = self.RecruitLevel < data.RecruitLevel
    end
    self.RecruitLevel = data.RecruitLevel or 0
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_EXPEDITION_RECRUITTIME_REFRESH, isRecruitLevelUp)
end

function XExpeditionActivity:RefreshEndlessStage(endlessStage)
    for _, stageInfo in pairs(endlessStage) do
        self:SetWave(stageInfo.Stage, stageInfo.Scores)
    end
end

--==================
--刷新关卡信息
--@param newInfoFlag:是否是游戏中刷新
--==================
function XExpeditionActivity:RefreshStageInfos(stageDatas)
    if not stageDatas then
        return
    end
    for _, stageData in pairs(stageDatas) do
        local eStage = self:GetEStageByStageId(stageData.StageId)
        if eStage then
            eStage:RefreshStageInfo(stageData)
        end
    end
end
--================
--获取活动名称
--================
function XExpeditionActivity:GetActivityName()
    return self.ActivityCfg and self.ActivityCfg.Name
end
--================
--获取活动入口图片路径
--================
function XExpeditionActivity:GetBannerTexturePath()
    return self.ActivityCfg and self.ActivityCfg.BannerTexturePath
end
--================
--获取无线关关卡Id信息
--================
function XExpeditionActivity:GetInfinityStageInfo()
    local infinityInfo = {}
    for index, chapter in pairs(self.Chapters or {}) do
        local infinityStageId = chapter:GetInfinityStageId()
        infinityInfo[index] = infinityStageId
    end
    return infinityInfo
end
--================
--获取所有stage对象
--================
function XExpeditionActivity:GetEStages()
    local stageList = {}
    for _, chapter in pairs(self.Chapters or {}) do
        local stages = chapter:GetStages()
        appendArray(stageList, stages)
    end
    return stageList
end
--================
--获取所有队伍配置
--================
function XExpeditionActivity:GetDefaultTeamCfg()
    local allTeamCfg = {}
    for _, chapterId in pairs(self:GetChapterIds()) do
        local tempTeam = XExpeditionConfig.GetDefaultTeamCfgsByChapterId(chapterId)
        appendArray(allTeamCfg, tempTeam)
    end
    return allTeamCfg
end
--================
--获取章节ID列表
--================
function XExpeditionActivity:GetChapterIds()
    return self.ActivityCfg and self.ActivityCfg.ChapterIds or {}
end
--================
--根据关卡表Id获取活动关卡对象
--@param stageId:Stage表Id
--================
function XExpeditionActivity:GetEStageByStageId(stageId)
    for _, chapter in pairs(self.Chapters or {}) do
        local eStage = chapter:GetEStageByStageId(stageId)
        if eStage then
            return eStage
        end
    end
    return nil
end

--================
--根据关卡表Id获取活动章节对象
--@param stageId:Stage表Id
--================
function XExpeditionActivity:GetEChapterByStageId(stageId)
    for _, chapter in pairs(self.Chapters or {}) do
        local eStage = chapter:GetEStageByStageId(stageId)
        if eStage then
            return chapter
        end
    end
    return nil
end
--================
--获取玩家螺母购买招募机会的购买次数
--================
function XExpeditionActivity:GetBuyRecruitTimes()
    return self.BuyRecruitTime or 0
end
--================
--获取下次自然恢复时间点
--================
function XExpeditionActivity:GetNextRecruitAddTime()
    return self.NextRecruitAddTime or 0
end
--================
--获取招募数量
--================
function XExpeditionActivity:GetRecruitNum()
    return self.RecruitNum or 0
end
--================
--获取招募等级
--================
function XExpeditionActivity:GetRecruitLevel()
    return self.RecruitLevel or 1
end
--================
--获取当前招募次数
--================
function XExpeditionActivity:GetRecruitTimes()
    return self.RecruitTimes or 0
end
--================
--获取额外招募次数
--================
function XExpeditionActivity:GetExtraRecruitTimes()
    return self.ExtraDrawTimes or 0
end
--================
--获取当前招募次数
--================
function XExpeditionActivity:GetTotalRecruitTimes()
    return self:GetRecruitTimes() + self:GetExtraRecruitTimes()
end
--================
--获取当前招募上限次数
--================
function XExpeditionActivity:GetRecruitMaxTime()
    return self.ActivityCfg and self.ActivityCfg.RecruitMaxNum
end
--================
--获取当前招募次数展示字符串
--================
function XExpeditionActivity:GetRecruitTimesStr()
    return string.format("%d/%d", self:GetTotalRecruitTimes(), self:GetRecruitMaxTime())
end
--================
--获取本次活动一次招募的数量
--================
function XExpeditionActivity:GetRecruitDrawNum()
    return self.ActivityCfg and self.ActivityCfg.RecruitDrawNum
end
--================
--获取本次活动一次招募的数量
--================
function XExpeditionActivity:GetRecruitTimeFull()
    return self:GetRecruitTimes() >= self:GetRecruitMaxTime()
end
--================
--获取当前章节无尽关卡波数
--================
function XExpeditionActivity:GetWave(stageId)
    for _, chapter in pairs(self.Chapters or {}) do
        local infinityStageId = chapter:GetInfinityStageId()
        if stageId == infinityStageId then
            return chapter:GetNightMareWave()
        end
    end
    return 0
end
--================
--设置当前章节无尽关卡波数
--@param wave:波数
--================
function XExpeditionActivity:SetWave(stageId, wave)
    for _, chapter in pairs(self.Chapters or {}) do
        local infinityStageId = chapter:GetInfinityStageId()
        if stageId == infinityStageId then
            chapter:SetNightMareWave(wave)
        end
    end
end
--================
--获取是否有招募次数
--================
function XExpeditionActivity:GetCanRecruit()
    return self:GetTotalRecruitTimes() > 0
end
--================
--获取能不能螺母买抽卡
--================
function XExpeditionActivity:GetCanBuyDraw()
    return self:GetBuyRecruitTimes() < XExpeditionConfig.GetBuyDrawMaxTime()
end
--================
--获取TimeId
--================
function XExpeditionActivity:GetTimeId()
    return self.ActivityCfg and self.ActivityCfg.TimeId
end
--================
--获取每日点赞
--================
function XExpeditionActivity:GetDailyLikeMaxNum()
    return self.ActivityCfg and self.ActivityCfg.DailyLikeMaxNum
end
--================
--刷新排行榜数据
--================
function XExpeditionActivity:UpdateRankingData(rankingData)
    self.SelfRank = rankingData.Ranking
    self.TotalRankPlayers = rankingData.TotalCount
    self.MyRankInfo = rankingData.MyRankInfo
    self.RankingList = rankingData.RankList
end
--================
--刷新我的排行榜数据
--================
function XExpeditionActivity:UpdateMyRankingData(rankingData)
    self.SelfRank = rankingData.Ranking
    self.TotalRankPlayers = rankingData.TotalCount
end
--================
--获取自身排行数
--================
function XExpeditionActivity:GetSelfRank()
    return self.SelfRank or 0
end
--================
--获取排行榜总玩家数
--================
function XExpeditionActivity:GetTotalRankPlayers()
    return self.TotalRankPlayers > 0 and self.TotalRankPlayers or 1
end
--================
--获取自己排行数字符串
--================
function XExpeditionActivity:GetSelfRankStr()
    local selfR = self:GetSelfRank()
    if selfR == 0 then return CS.XTextManager.GetText("ExpeditionNoRanking") end
    if selfR ~= 0 and selfR <= 100 then return selfR end
    local percent = selfR / self:GetTotalRankPlayers()
    local result = math.ceil(percent * 100)
    return string.format("%d%s", (result > 99 and 99 or result), "%")
end
--================
--获取前百排行榜数据
--================
function XExpeditionActivity:GetRankingList()
    return self.RankingList or {}
end
--================
--获取自己排行榜数据
--================
function XExpeditionActivity:GetMyRankInfo()
    return self.MyRankInfo or {}
end
--================
--获取排位图片
--================
function XExpeditionActivity:GetRankSpecialIcon(ranking)
    if not self.ActivityCfg then return nil end
    local maxNum = self.ActivityCfg.RankIcon and #self.ActivityCfg.RankIcon or 0
    return maxNum > 0 and self.ActivityCfg.RankIcon[ranking] or nil
end
--================
--检查给予的Id是否是当前选择的预设队伍Id
--================
function XExpeditionActivity:CheckDefaultTeam(checkId)
    return checkId == self.DefaultTeamId
end
--================
--设置当前预设队伍Id
--================
function XExpeditionActivity:SetDefaultTeamId(teamId, needAddMember)
    if not teamId or self.DefaultTeamId == teamId then return end
    self.DefaultTeamId = teamId
    XDataCenter.ExpeditionManager.ResetDefaultTeamMember()
    local defaultTeamCfg = self.DefaultTeamId and self.DefaultTeamId > 0 and XExpeditionConfig.GetDefaultTeamCfgByTeamId(self.DefaultTeamId)
    if defaultTeamCfg then
        if needAddMember then
            local team = XDataCenter.ExpeditionManager.GetTeam()
            team:AddMemberListByECharaIds(defaultTeamCfg.ECharacterIds)
        end
        for _, eCharaId in pairs(defaultTeamCfg.ECharacterIds) do
            local baseId = XExpeditionConfig.GetBaseIdByECharId(eCharaId)
            local chara = XDataCenter.ExpeditionManager.GetECharaByEBaseId(baseId)
            if chara then
                chara:SetDefaultTeamMember(true)
            end
        end
    end
end
--================
--获取当前预设队伍Id
--================
function XExpeditionActivity:GetDefaultTeamId()
    return self.DefaultTeamId or 0
end

function XExpeditionActivity:GetResetStageConsumeId()
    return self.ActivityCfg and self.ActivityCfg.ResetStageConsumeId or 0
end

function XExpeditionActivity:GetResetStageConsumeCount()
    return self.ActivityCfg and self.ActivityCfg.ResetStageConsumeCount or 0
end

function XExpeditionActivity:GetResetChapterConsumeId()
    return self.ActivityCfg and self.ActivityCfg.ResetChapterConsumeId
end

function XExpeditionActivity:GetResetChapterConsumeCount()
    return self.ActivityCfg and self.ActivityCfg.ResetChapterConsumeCount
end

function XExpeditionActivity:GetTaskGroupId()
    return self.ActivityCfg and self.ActivityCfg.TaskGroupId or 0
end

function XExpeditionActivity:GetChapterPrefab()
    return self.ActivityCfg and self.ActivityCfg.ChapterPrefab or ""
end
-- 核心成员位置不和羁绊成员位置一起计算 需要减去核心成为数量
function XExpeditionActivity:GetRecruitRobotMaxNum()
    return self.ActivityCfg and self.ActivityCfg.RecruitRobotMaxNum - 2 or 0
end

function XExpeditionActivity:GetStageCompleteStr()
    local eStages = self:GetEStages()
    local totalStageNum = #eStages
    local lastPassIndex = 0
    for _, eStage in pairs(eStages) do
        if eStage:GetIsPass() then
            lastPassIndex = lastPassIndex + 1
        end 
    end
    return string.format("%d/%d", lastPassIndex, totalStageNum)
end

-- 返回true就是全部关卡通过了
function XExpeditionActivity:CheckIsChapterClear()
    local isClear = true
    for _, chapter in pairs(self.Chapters or {}) do
        -- 判断当前章节是否开启
        local timeId = chapter:GetChapterTimeId()
        if not XFunctionManager.CheckInTimeByTimeId(timeId) then
            goto CONTINUE
        end
        -- 查找关卡是否有未通关的
        local eStages = chapter:GetStages()
        for _, eStage in pairs(eStages or {}) do
            if not eStage:GetIsPass() then
                isClear = false
                break
            end
        end
        :: CONTINUE ::
    end
    return isClear
end

return XExpeditionActivity