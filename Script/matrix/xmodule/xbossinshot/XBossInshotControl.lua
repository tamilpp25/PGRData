---@class XBossInshotControl : XControl
---@field _Model XBossInshotModel
local XBossInshotControl = XClass(XControl, "XBossInshotControl")
function XBossInshotControl:OnInit()
    --初始化内部变量
end

function XBossInshotControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBossInshotControl:RemoveAgencyEvent()

end

function XBossInshotControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

--- 获取当前开启活动Id
function XBossInshotControl:GetActivityId()
    return self._Model:GetActivityId()
end

--- 获取活动的结束时间戳
--- @param id number 活动Id
function XBossInshotControl:GetActivityEndTime(id)
    return self._Model:GetActivityEndTime(id)
end

--- 获取活动是否开启
function XBossInshotControl:IsActivityOpen()
    return self._Model:IsActivityOpen()
end

--- 处理活动结束
function XBossInshotControl:HandleActivityEnd()
    XUiManager.TipText("ActivityAlreadyOver")
    XLuaUiManager.RunMain()
end

--- 设置重新战斗状态
function XBossInshotControl:SetAgainFight(isAgainFight)
    return self._Model:SetAgainFight(isAgainFight)
end

--- 设置重新战斗状态
function XBossInshotControl:GetAgainFight()
    return self._Model:GetAgainFight()
end

--- 获取活动缓存队伍信息
function XBossInshotControl:GetTeam()
    return self._Model:GetTeam()
end

--- 关卡是否解锁
function XBossInshotControl:IsStageUnlock(inshotStageId)
    return self._Model:IsStageUnlock(inshotStageId)
end

--- 获取通关关卡数据
function XBossInshotControl:GetPassStageData(stageId)
    return self._Model:GetPassStageData(stageId)
end

--- 教学关是否通关
function XBossInshotControl:IsTeachStagePass()
    return self._Model:IsTeachStagePass()
end

--- 获取角色选择天赋Id列表
function XBossInshotControl:GetCharacterSelectTalentIds(characterId)
    return self._Model:GetCharacterSelectTalentIds(characterId)
end

--- 角色天赋是否解锁
function XBossInshotControl:IsCharacterTalentUnlock(characterId, talentId)
    return self._Model:IsCharacterTalentUnlock(characterId, talentId)
end

--- 是否显示任务红点
function XBossInshotControl:IsShowTaskRed()
    return self._Model:IsShowTaskRed()
end

--- 获取是否显示回放功能
function XBossInshotControl:GetIsShowPlayback(stageId)
    return self._Model:GetIsShowPlayback(stageId)
end

--- 生成最后战斗的录像数据
function XBossInshotControl:GenLastPlaybackData(bossId, score, scoreLevelIcon, difficulty)
    return self._Model:GenLastPlaybackData(bossId, score, scoreLevelIcon, difficulty)
end

--- 获取回放数据
function XBossInshotControl:GetPlaybackDatas(bossId)
    return self._Model:GetPlaybackDatas(bossId)
end

--- 保存回放数据
function XBossInshotControl:SavePlaybackData(bossId, pos, playbackData)
    return self._Model:SavePlaybackData(bossId, pos, playbackData)
end

--- 删除回放数据
function XBossInshotControl:DeletePlaybackData(bossId, pos)
    return self._Model:DeletePlaybackData(bossId, pos)
end

--- 获取新解锁的天赋列表
function XBossInshotControl:GetNewUnlockTalentIds()
    return self._Model:GetNewUnlockTalentIds()
end

--- 是否节日副本中的特定关卡
function XBossInshotControl:IsFestivalActivityStage(stageId)
    return XDataCenter.FubenFestivalActivityManager.IsBossInshotSettlementShowStage(stageId)
end

---------------------------------------- #region 配置表 ----------------------------------------
--- 获取活动配置表
function XBossInshotControl:GetConfigBossInshotActivity(id)
    return self._Model:GetConfigBossInshotActivity(id)
end

--- 获取活动配置bossId列表
function XBossInshotControl:GetActivityBossIds(id)
    return self._Model:GetActivityBossIds(id)
end

--- 获取活动配置任务组列表
function XBossInshotControl:GetActivityTaskGroupIds(id)
    return self._Model:GetActivityTaskGroupIds(id)
end

--- 获取活动配置教学关卡Id
function XBossInshotControl:GetActivityTeachStageId(id)
    return self._Model:GetActivityTeachStageId(id)
end

--- 获取活动角色Id列表
function XBossInshotControl:GetActivityCharacterIds(id)
    return self._Model:GetActivityCharacterIds(id)
end

--- 获取活动任务展示奖励
function XBossInshotControl:GetActivityPreviewTaskRewardId(id)
    return self._Model:GetActivityPreviewTaskRewardId(id)
end

--- 获取Boss的名称
function XBossInshotControl:GetBossName(id)
    return self._Model:GetBossName(id)
end

--- 获取Boss的模型Id
function XBossInshotControl:GetBossModelId(id)
    return self._Model:GetBossModelId(id)
end

--- 获取Boss的头像
function XBossInshotControl:GetBossHeadIcon(id)
    return self._Model:GetBossHeadIcon(id)
end

--- 获取Boss的技能Id列表
function XBossInshotControl:GetBossSkillIds(id)
    return self._Model:GetBossSkillIds(id)
end

--- 获取Boss的开启时间
function XBossInshotControl:GetBossOpenTimeId(id)
    return self._Model:GetBossOpenTimeId(id)
end

--- 获取成员配置表
function XBossInshotControl:GetConfigBossInshotCharacter(id)
    return self._Model:GetConfigBossInshotCharacter(id)
end

-- 获取成员名称
function XBossInshotControl:GetCharacterName(id)
    return self._Model:GetCharacterName(id)
end

--- 获取分数配置表
function XBossInshotControl:GetConfigBossInshotScore(id)
    return self._Model:GetConfigBossInshotScore(id)
end

--- 获取评分对应等级图标
function XBossInshotControl:GetScoreLevelIcon(difficulty, score)
    return self._Model:GetScoreLevelIcon(difficulty, score)
end

--- 获取评分对应等级大图标
function XBossInshotControl:GetScoreLevelBigIcon(difficulty, score)
    return self._Model:GetScoreLevelBigIcon(difficulty, score)
end

--- 获取评分对应特效名
function XBossInshotControl:GetScoreLevelEffectName(difficulty, score)
    return self._Model:GetScoreLevelEffectName(difficulty, score)
end

--- 获取达到下一评分等级提示
function XBossInshotControl:GetNextScoreLevelTips(difficulty, score)
    return self._Model:GetNextScoreLevelTips(difficulty, score)
end

--- 获取技能配置表
function XBossInshotControl:GetConfigBossInshotSkill(id)
    return self._Model:GetConfigBossInshotSkill(id)
end

--- 获取技能名称
function XBossInshotControl:GetSkillName(id)
    return self._Model:GetSkillName(id)
end

--- 获取技能提示
function XBossInshotControl:GetSkillTips(id)
    return self._Model:GetSkillTips(id)
end

--- 获取技能描述
function XBossInshotControl:GetSkillDesc(id)
    return self._Model:GetSkillDesc(id)
end

--- 获取技能视频路径
function XBossInshotControl:GetSkillVideoUrl(id)
    return self._Model:GetSkillVideoUrl(id)
end

--- 获取技能对应练习关
function XBossInshotControl:GetSkillPracticeStageId(id)
    return self._Model:GetSkillPracticeStageId(id)
end

--- 获取关卡名称
function XBossInshotControl:GetStageName(id)
    return self._Model:GetStageName(id)
end

--- 获取关卡难度
function XBossInshotControl:GetStageDifficulty(inshotStageId)
    return self._Model:GetStageDifficulty(inshotStageId)
end

--- 获取关卡Id
function XBossInshotControl:GetInshotStageIdByStageId(stageId)
    return self._Model:GetInshotStageIdByStageId(stageId)
end

--- 获取关卡解锁conditionId
function XBossInshotControl:GetStageUnlockConditionId(id)
    return self._Model:GetStageUnlockConditionId(id)
end

--- 获取关卡对应stageId
function XBossInshotControl:GetStageStageId(id)
    return self._Model:GetStageStageId(id)
end

--- 获取关卡的BossId
function XBossInshotControl:GetStageBossId(id)
    return self._Model:GetStageBossId(id)
end

--- 获取Boss的关卡列表
function XBossInshotControl:GetBossStageIds(bossId)
    return self._Model:GetBossStageIds(bossId)
end

--- 获取天赋配置表
function XBossInshotControl:GetConfigBossInshotTalent(id)
    return self._Model:GetConfigBossInshotTalent(id)
end

--- 获取角色默认穿戴天赋配置表
function XBossInshotControl:GetCharacterDefaultWearTalentCfg(characterId)
    return self._Model:GetCharacterDefaultWearTalentCfg(characterId)
end

--- 获取角色手动穿戴天赋配置表列表
function XBossInshotControl:GetCharacterHandWearTalentCfgs(characterId)
    return self._Model:GetCharacterHandWearTalentCfgs(characterId)
end

-- 获取排名特殊图片
function XBossInshotControl:GetRankingSpecialIcon(rank)
    if type(rank) ~= "number" or rank < 1 or rank > 3 then
        return
    end
    return CS.XGame.ClientConfig:GetString("BabelTowerRankIcon" .. rank)
end

-- 获取结算评分特效名
function XBossInshotControl:GetMarkEffectName(id)
    return self._Model:GetMarkEffectName(id)
end
---------------------------------------- #endregion 配置表 ----------------------------------------

return XBossInshotControl
