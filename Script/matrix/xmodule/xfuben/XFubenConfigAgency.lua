---@class XFubenConfigAgency : XAgency
---@field private _Model XFubenModel
local XFubenConfigAgency = XClass(XAgency, "XFubenConfigAgency")

-- 来自stageConfig, 为了分离原manager和config
function XFubenConfigAgency:Ctor()
end

function XFubenConfigAgency:GetStageCfgs()
    return self._Model:GetStageCfgs()
end

function XFubenConfigAgency:GetBuffDes(buffId)
    return self._Model:GetBuffDes(buffId)
end

function XFubenConfigAgency:GetStageLevelControlCfg()
    return self._Model:GetStageLevelControlCfg()
end

function XFubenConfigAgency:GetStageMultiplayerLevelControlCfg()
    return self._Model:GetStageMultiplayerLevelControlCfg()
end

function XFubenConfigAgency:GetStageMultiplayerLevelControlCfgById(id)
    return self._Model:GetStageMultiplayerLevelControlCfgById(id)
end

function XFubenConfigAgency:GetStageTransformCfg()
    return self._Model:GetStageTransformCfg()
end

function XFubenConfigAgency:GetFlopRewardTemplates()
    return self._Model:GetFlopRewardTemplates()
end

function XFubenConfigAgency:GetActivitySortRules()
    return self._Model:GetActivitySortRules()
end

function XFubenConfigAgency:GetFeaturesById(id)
    return self._Model:GetFeaturesById(id)
end

function XFubenConfigAgency:GetActivityPriorityByActivityIdAndType(activityId, type)
    return self._Model:GetActivityPriorityByActivityIdAndType(activityId, type)
end

function XFubenConfigAgency:GetStageFightControl(id)
    return self._Model:GetStageFightControl(id)
end

function XFubenConfigAgency:IsKeepPlayingStory(stageId)
    return self._Model:IsKeepPlayingStory(stageId)
end

function XFubenConfigAgency:GetChapterBannerByType(bannerType)
    return self._Model:GetChapterBannerByType(bannerType)
end

function XFubenConfigAgency:GetNewChallengeConfigs()
    return self._Model:GetNewChallengeConfigs()
end

function XFubenConfigAgency:GetNewChallengeConfigById(id)
    return self._Model:GetNewChallengeConfigById(id)
end

function XFubenConfigAgency:GetNewChallengeConfigsLength()
    return self._Model:GetNewChallengeConfigsLength()
end

function XFubenConfigAgency:GetNewChallengeFunctionId(index)
    return self._Model:GetNewChallengeFunctionId(index)
end

function XFubenConfigAgency:GetNewChallengeId(index)
    return self._Model:GetNewChallengeId(index)
end

function XFubenConfigAgency:GetNewChallengeStartTimeStamp(index)
    return self._Model:GetNewChallengeStartTimeStamp(index)
end

function XFubenConfigAgency:GetNewChallengeEndTimeStamp(index)
    return self._Model:GetNewChallengeEndTimeStamp(index)
end

function XFubenConfigAgency:IsNewChallengeStartByIndex(index)
    return self._Model:IsNewChallengeStartByIndex(index)
end

function XFubenConfigAgency:IsNewChallengeStartById(id)
    return self._Model:IsNewChallengeStartById(id)
end

function XFubenConfigAgency:GetMultiChallengeStageConfigs()
    return self._Model:GetMultiChallengeStageConfigs()
end

function XFubenConfigAgency:GetTableStagePath()
    return self._Model:GetTableStagePath()
end

function XFubenConfigAgency:GetStageCharacterLimitConfig(characterLimitType)
    return self._Model:GetStageCharacterLimitConfig(characterLimitType)
end

function XFubenConfigAgency:GetStageCharacterLimitType(stageId)
    return self._Model:GetStageCharacterLimitType(stageId)
end

function XFubenConfigAgency:GetStageCareerSuggestTypes(stageId)
    return self._Model:GetStageCareerSuggestTypes(stageId)
end

function XFubenConfigAgency:GetStageAISuggestType(stageId)
    return self._Model:GetStageAISuggestType(stageId)
end

function XFubenConfigAgency:GetStageCharacterLimitBuffId(stageId)
    return self._Model:GetStageCharacterLimitBuffId(stageId)
end

function XFubenConfigAgency:GetLimitShowBuffId(limitBuffId)
    return self._Model:GetLimitShowBuffId(limitBuffId)
end

function XFubenConfigAgency:IsStageCharacterLimitConfigExist(characterLimitType)
    return self._Model:IsStageCharacterLimitConfigExist(characterLimitType)
end

-- 编队界面限制角色类型Icon
function XFubenConfigAgency:GetStageCharacterLimitImageTeamEdit(characterLimitType)
    return self._Model:GetStageCharacterLimitImageTeamEdit(characterLimitType)
end

-- 编队界面限制角色类型文本
function XFubenConfigAgency:GetStageCharacterLimitTextTeamEdit(characterLimitType, characterType, buffId)
    return self._Model:GetStageCharacterLimitTextTeamEdit(characterLimitType, characterType, buffId)
end

function XFubenConfigAgency:GetStageMixCharacterLimitTips(characterLimitType, characterTypes, isColorText)
    return self._Model:GetStageMixCharacterLimitTips(characterLimitType, characterTypes, isColorText)
end

-- 选人界面限制角色类型Icon
function XFubenConfigAgency:GetStageCharacterLimitImageSelectCharacter(characterLimitType)
    return self._Model:GetStageCharacterLimitImageSelectCharacter(characterLimitType)
end

-- 选人界面限制角色类型文本
function XFubenConfigAgency:GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, buffId)
    return self._Model:GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, buffId)
end

-- 限制角色类型分区名称文本
function XFubenConfigAgency:GetStageCharacterLimitName(characterLimitType)
    return self._Model:GetStageCharacterLimitName(characterLimitType)
end

-- 章节选人界面限制角色类型文本
function XFubenConfigAgency:GetChapterCharacterLimitText(characterLimitType, buffId)
    return self._Model:GetChapterCharacterLimitText(characterLimitType, buffId)
end

function XFubenConfigAgency:IsCharacterFitTeamBuff(teamBuffId, characterId)
    return self._Model:IsCharacterFitTeamBuff(teamBuffId, characterId)
end

function XFubenConfigAgency:GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
    return self._Model:GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
end

function XFubenConfigAgency:GetTeamBuffMaxCountDic()
    return self._Model:GetTeamBuffMaxCountDic()
end

function XFubenConfigAgency:GetTeamBuffMaxBuffCount(teamBuffId)
    return self._Model:GetTeamBuffMaxBuffCount(teamBuffId)
end

function XFubenConfigAgency:GetTeamBuffOnIcon(teamBuffId)
    return self._Model:GetTeamBuffOnIcon(teamBuffId)
end

function XFubenConfigAgency:GetTeamBuffOffIcon(teamBuffId)
    return self._Model:GetTeamBuffOffIcon(teamBuffId)
end

function XFubenConfigAgency:GetTeamBuffTitle(teamBuffId)
    return self._Model:GetTeamBuffTitle(teamBuffId)
end

function XFubenConfigAgency:GetTeamBuffDesc(teamBuffId)
    return self._Model:GetTeamBuffDesc(teamBuffId)
end

-- 根据符合初始品质要求的characterId列表获取对应的同调加成buffId
function XFubenConfigAgency:GetTeamBuffShowBuffId(teamBuffId, characterIds)
    return self._Model:GetTeamBuffShowBuffId(teamBuffId, characterIds)
end

-- 根据关卡ID查找关卡词缀列表
function XFubenConfigAgency:GetStageFightEventByStageId(stageId)
    return self._Model:GetStageFightEventByStageId(stageId)
end

-- 根据ID查找词缀详细
function XFubenConfigAgency:GetStageFightEventDetailsByStageFightEventId(eventId)
    return self._Model:GetStageFightEventDetailsByStageFightEventId(eventId)
end

---
--- 获取 失败提示描述 数组
function XFubenConfigAgency:GetTipDescList(settleLoseTipId)
    return self._Model:GetTipDescList(settleLoseTipId)
end

---
--- 获取 失败提示跳转Id 数组
function XFubenConfigAgency:GetSkipIdList(settleLoseTipId)
    return self._Model:GetSkipIdList(settleLoseTipId)
end

--获取关卡推荐角色类型（构造体/感染体）
function XFubenConfigAgency:GetStageRecommendCharacterType(stageId)
    return self._Model:GetStageRecommendCharacterType(stageId)
end

--获取关卡推荐角色元素属性（物理/火/雷/冰/暗）
function XFubenConfigAgency:GetStageRecommendCharacterElement(stageId)
    return self._Model:GetStageRecommendCharacterElement(stageId)
end

--是否为关卡推荐角色
function XFubenConfigAgency:IsStageRecommendCharacterType(stageId, id)
    return self._Model:IsStageRecommendCharacterType(stageId, id)
end

function XFubenConfigAgency:GetStageName(stageId, ignoreError)
    return self._Model:GetStageName(stageId, ignoreError)
end

function XFubenConfigAgency:GetStageDescription(stageId, ignoreError)
    return self._Model:GetStageDescription(stageId, ignoreError)
end

function XFubenConfigAgency:GetStageMainlineType(stageId)
    return self._Model:GetStageMainlineType(stageId)
end

---
--- 关卡图标
function XFubenConfigAgency:GetStageIcon(stageId)
    return self._Model:GetStageIcon(stageId)
end

---
--- 三星条件描述数组
function XFubenConfigAgency:GetStarDesc(stageId)
    return self._Model:GetStarDesc(stageId)
end

---
--- 关卡首通奖励
function XFubenConfigAgency:GetFirstRewardShow(stageId)
    return self._Model:GetFirstRewardShow(stageId)
end

---
--- 关卡非首通奖励
function XFubenConfigAgency:GetFinishRewardShow(stageId)
    return self._Model:GetFinishRewardShow(stageId)
end

---
--- 获得战前剧情ID
function XFubenConfigAgency:GetBeginStoryId(stageId)
    return self._Model:GetBeginStoryId(stageId)
end

---
--- 获得战后剧情ID
function XFubenConfigAgency:GetEndStoryId(stageId)
    return self._Model:GetEndStoryId(stageId)
end

---
--- 获得前置关卡id
function XFubenConfigAgency:GetPreStageId(stageId)
    return self._Model:GetPreStageId(stageId)
end

function XFubenConfigAgency:GetStageTypeCfg(stageId)
    return self._Model:GetStageTypeCfg(stageId)
end

---
--- 活动特殊关卡配置机器人列表获取
function XFubenConfigAgency:GetStageTypeRobot(stageType)
    return self._Model:GetStageTypeRobot(stageType)
end

function XFubenConfigAgency:IsAllowRepeatChar(stageType)
    return self._Model:IsAllowRepeatChar(stageType)
end

function XFubenConfigAgency:GetStageMixCharacterLimitBuff()
    return self._Model:GetStageMixCharacterLimitBuff()
end

function XFubenConfigAgency:GetCharacterLimitBuffDic(limitType)
    return self._Model:GetStageMixCharacterLimitBuff(limitType)
end

-----------------------关卡步骤跳过相关------------------------
function XFubenConfigAgency:GetStepSkipListByStageId(stageId)
    return self._Model:GetStepSkipListByStageId(stageId)
end

function XFubenConfigAgency:CheckStepIsSkip(stageId, stepSkipType)
    return self._Model:CheckStepIsSkip(stageId, stepSkipType)
end


--region 暂停界面uiSet，显示可配置的玩法说明
function XFubenConfigAgency:GetStageGamePlayDesc(stageType)
    return self._Model:GetStageGamePlayDesc(stageType)
end

function XFubenConfigAgency:HasStageGamePlayDesc(stageType)
    return self._Model:HasStageGamePlayDesc(stageType)
end

function XFubenConfigAgency:GetStageGamePlayBtnVisible(stageType)
    return self._Model:GetStageGamePlayBtnVisible(stageType)
end

function XFubenConfigAgency:GetStageGamePlayTitle(stageType)
    return self._Model:GetStageGamePlayTitle(stageType)
end

function XFubenConfigAgency:GetStageGamePlayDescDataSource(stageType)
    return self._Model:GetStageGamePlayDescDataSource(stageType)
end

function XFubenConfigAgency:GetFubenActivityConfigByManagerName(managerName)
    return self._Model:GetFubenActivityConfigByManagerName(managerName)
end

function XFubenConfigAgency:GetSecondTagConfigsByFirstTagId(firstTagId)
    return self._Model:GetSecondTagConfigsByFirstTagId(firstTagId)
end

function XFubenConfigAgency:GetSecondTagConfigById(id)
    return self._Model:GetSecondTagConfigById(id)
end

function XFubenConfigAgency:GetCollegeChapterBannerByType(chapterType)
    return self._Model:GetCollegeChapterBannerByType(chapterType)
end

function XFubenConfigAgency:GetActivityPanelPrefabPath()
    return self._Model:GetActivityPanelPrefabPath()
end

function XFubenConfigAgency:GetMainPanelTimeId()
    return self._Model:GetMainPanelTimeId()
end

function XFubenConfigAgency:GetMainFestivalBg()
    return self._Model:GetMainFestivalBg()
end

function XFubenConfigAgency:GetMainPanelItemId()
    return self._Model:GetMainPanelItemId()
end

function XFubenConfigAgency:GetMainPanelName()
    return self._Model:GetMainPanelName()
end

function XFubenConfigAgency:GetMain3DBgPrefab()
    return self._Model:GetMain3DBgPrefab()
end

function XFubenConfigAgency:GetMain3DCameraPrefab()
    return self._Model:GetMain3DCameraPrefab()
end

function XFubenConfigAgency:GetMainVideoBgUrl()
    return self._Model:GetMainVideoBgUrl()
end

function XFubenConfigAgency:GetStageSettleWinSoundId()
    return self._Model:GetStageSettleWinSoundId()
end

function XFubenConfigAgency:GetStageSettleLoseSoundId()
    return self._Model:GetStageSettleLoseSoundId()
end

function XFubenConfigAgency:GetQxmsTryIcon()
    return self._Model:GetQxmsTryIcon()
end

function XFubenConfigAgency:GetQxmsUseIcon()
    return self._Model:GetQxmsUseIcon()
end

function XFubenConfigAgency:GetChallengeShowGridCount()
    return self._Model:GetChallengeShowGridCount()
end

function XFubenConfigAgency:GetChallengeShowGridList()
    return self._Model:GetChallengeShowGridList()
end

-- 判断副本主界面是否是用3D场景
function XFubenConfigAgency:GetIsMainHave3DBg()
    return self._Model:GetIsMainHave3DBg()
end

-- 判断副本主界面是否是用视频背景
function XFubenConfigAgency:GetIsMainHaveVideoBg()
    return self._Model:GetIsMainHaveVideoBg()
end
--endregion

function XFubenConfigAgency:GetSettleSpecialSoundCfgByStageId(stageId)
    return self._Model:GetSettleSpecialSoundCfgByStageId(stageId)
end

function XFubenConfigAgency:DebugGetModel()
    --XLog.Error(self._Model._ConfigUtil._Configs)
    --XLog.Error(self._Model._ConfigUtil._ConfigArgs)
    local configs = self._Model._ConfigUtil._Configs
    local str = ""
    for path, v in pairs(configs) do
        str = str .. path .. "\n"
    end
    print(str)
end

return XFubenConfigAgency