---@class XPcgControl : XControl
---@field _Model XPcgModel
---@field GameSubControl XPcgGameSubControl
local XPcgControl = XClass(XControl, "XPcgControl")
function XPcgControl:OnInit()
    --初始化内部变量
    local XPcgGameSubControl = require("XModule/XPcg/SubControl/XPcgGameSubControl")
    self.GameSubControl = self:AddSubControl(XPcgGameSubControl)
end

function XPcgControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XPcgControl:RemoveAgencyEvent()

end

function XPcgControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

-- 处理活动结束
function XPcgControl:HandleActivityEnd()
    XUiManager.TipText("ActivityAlreadyOver")
    XLuaUiManager.RunMain()
end

--region 配置表读取
-- 获取活动的结束时间
function XPcgControl:GetActivityEndTime()
    return self._Model:GetActivityEndTime()
end

-- 获取活动核心奖励
function XPcgControl:GetActivityRewardId()
    return self._Model:GetActivityRewardId()
end

-- 获取任务组Id列表
function XPcgControl:GetActivityTaskGroupIds()
    return self._Model:GetActivityTaskGroupIds()
end

-- 获取任务组名称列表
function XPcgControl:GetActivityTaskGroupNames()
    return self._Model:GetActivityTaskGroupNames()
end

-- 获取章节表
function XPcgControl:GetConfigChapter(id)
    return self._Model:GetConfigChapter(id)
end

-- 获取关卡表
function XPcgControl:GetConfigStage(id)
    return self._Model:GetConfigStage(id)
end

-- 获取关卡的推荐队伍
function XPcgControl:GetStageRecommendCharacterIds(stageId)
    return self._Model:GetStageRecommendCharacterIds(stageId)
end

-- 获取关卡类型
function XPcgControl:GetStageType(id)
    return self._Model:GetStageType(id)
end

-- 获取下一关卡Id
function XPcgControl:GetNextStageId(stageId)
    return self._Model:GetNextStageId(stageId)
end

-- 获取关卡类型
function XPcgControl:GetStageType(id)
    return self._Model:GetStageType(id)
end

-- 获取关卡星级条件
function XPcgControl:GetStageStarConditions(id)
    return self._Model:GetStageStarConditions(id)
end

-- 获取关卡星级描述
function XPcgControl:GetStageStarDescs(id)
    return self._Model:GetStageStarDescs(id)
end

-- 获取关卡手牌上限
function XPcgControl:GetStageHandNum(id)
    return self._Model:GetStageHandNum(id)
end

-- 获取关卡初始行动点
function XPcgControl:GetStageInitActionPoint(id)
    return self._Model:GetStageInitActionPoint(id)
end

-- 获取关卡指挥官最大血量
function XPcgControl:GetStageMaxHp(id)
    return self._Model:GetStageMaxHp(id)
end

-- 获取关卡指挥官最大能量
function XPcgControl:GetStageMaxEnergy(id)
    return self._Model:GetStageMaxEnergy(id)
end

-- 获取关卡是否可使用指挥官技能
function XPcgControl:GetStageEnablePlayerSkill(id)
    return self._Model:GetStageEnablePlayerSkill(id)
end

-- 获取角色表
function XPcgControl:GetConfigCharacter(id)
    return self._Model:GetConfigCharacter(id)
end

-- 角色是否包含效果
function XPcgControl:IsCharacterContainEffectId(charId, effectId)
    return self._Model:IsCharacterContainEffectId(charId, effectId)
end

-- 获取解锁的角色Id列表
function XPcgControl:GetUnlockCharacterIds(stageId, colorType)
    return self._Model:GetUnlockCharacterIds(stageId, colorType)
end

-- 获取角色上锁提示
function XPcgControl:GetCharacterLockTips(characterId)
    return self._Model:GetCharacterLockTips(characterId)
end

-- 获取角色类型表
function XPcgControl:GetConfigCharacterType(id)
    return self._Model:GetConfigCharacterType(id)
end

-- 获取效果表
function XPcgControl:GetConfigEffect(id)
    return self._Model:GetConfigEffect(id)
end

function XPcgControl:GetEffectShowDesc(id)
    return self._Model:GetEffectShowDesc(id)
end

function XPcgControl:GetEffectCv(id)
    return self._Model:GetEffectCv(id)
end

-- 获取怪物表
function XPcgControl:GetConfigMonster(id)
    return self._Model:GetConfigMonster(id)
end

-- 获取怪物行为表
function XPcgControl:GetConfigMonsterBehavior(id)
    return self._Model:GetConfigMonsterBehavior(id)
end

-- 获取关卡的Boss级别怪物
function XPcgControl:GetStageBossMonsterId(stageId)
    return self._Model:GetStageBossMonsterId(stageId)
end

-- 获取卡牌表
function XPcgControl:GetConfigCards(id)
    return self._Model:GetConfigCards(id)
end

-- 获取卡牌类型
function XPcgControl:GetCardType(id)
    return self._Model:GetCardType(id)
end

-- 获取卡牌颜色
function XPcgControl:GetCardColor(id)
    return self._Model:GetCardColor(id)
end

-- 获取标记表
function XPcgControl:GetConfigToken(id)
    return self._Model:GetConfigToken(id)
end

function XPcgControl:GetTokenIsShow(id)
    return self._Model:GetTokenIsShow(id)
end

-- 获取手牌的角色头像
function XPcgControl:GetCardCharacterHeadIcon(id)
    return self._Model:GetCardCharacterHeadIcon(id)
end

-- 获取活动对应章节配置表
function XPcgControl:GetActivityChapterConfigs()
    return self._Model:GetActivityChapterConfigs()
end

-- 获取章节关卡列表
function XPcgControl:GetChapterStageIds(chapterId)
    return self._Model:GetChapterStageIds(chapterId)
end

-- 获取ClientConfig表配置
function XPcgControl:GetClientConfig(key, index)
    return self._Model:GetClientConfig(key, index)
end

-- 获取ClientConfig表配置所有参数
function XPcgControl:GetClientConfigParams(key)
    return self._Model:GetClientConfigParams(key)
end

-- 获取角色标签配置
function XPcgControl:GetConfigCharacterTag(id)
    return self._Model:GetConfigCharacterTag(id)
end

-- 获取角色的胜利CvId
function XPcgControl:GetCharacterFinishCv(charId)
    return self._Model:GetCharacterFinishCv(charId)
end

-- 获取角色的QteCvId
function XPcgControl:GetCharacterQteCv(charId)
    return self._Model:GetCharacterQteCv(charId)
end

-- 获取队伍名称
function XPcgControl:GetTeamName(characterIds)
    return self._Model:GetTeamName(characterIds)
end
--endregion

--region 活动数据读取
-- 获取活动数据
---@return XPcgActivity
function XPcgControl:GetActivityData()
    return self._Model.ActivityData
end

-- 是否在游戏中
function XPcgControl:IsInGame()
    return self._Model:IsInGame()
end

-- 获取当前进行中的关卡Id
function XPcgControl:GetCurrentStageId()
    return self._Model:GetCurrentStageId()
end

-- 获取当前进行中关卡的章节Id
function XPcgControl:GetCurrentChapterId()
    return self._Model:GetCurrentChapterId()
end

-- 角色是否解锁
function XPcgControl:IsCharacterUnlock(characterId)
    local activityData = self:GetActivityData()
    return activityData and activityData:IsCharacterUnlock(characterId) or false
end

-- 关卡是否解锁
function XPcgControl:IsStageUnlock(stageId)
    return self._Model:IsStageUnlock(stageId)
end

-- 关卡是否通关
function XPcgControl:IsStagePassed(stageId)
    return self._Model:IsStagePassed(stageId)
end

-- 章节是否解锁
function XPcgControl:IsChapterUnlock(chapterId)
    return self._Model:IsChapterUnlock(chapterId)
end

-- 章节是否通过
function XPcgControl:IsChapterPassed(chapterId)
    return self._Model:IsChapterPassed(chapterId)
end

-- 获取章节的星星数量
function XPcgControl:GetChapterStarCount(chapterId)
    return self._Model:GetChapterStarCount(chapterId)
end

-- 是否显示任务蓝点
function XPcgControl:IsTaskShowRed()
    return self._Model:IsTaskShowRed()
end

-- 是否显示角色解锁蓝点
function XPcgControl:IsCharacterShowRed(characterId)
    return self._Model:IsCharacterShowRed(characterId)
end

-- 设置角色查看过图鉴
function XPcgControl:SetCharacterReviewedBrochure(characterId)
    return self._Model:SetCharacterReviewedBrochure(characterId)
end

-- 是否显示章节蓝点
function XPcgControl:IsChapterShowRed(chapterId)
    return self._Model:IsChapterShowRed(chapterId)
end

-- 设置进入过章节
function XPcgControl:SetChapterEntered(chapterId)
    return self._Model:SetChapterEntered(chapterId)
end
--endregion

return XPcgControl