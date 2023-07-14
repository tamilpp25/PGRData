--===========================
--超级爬塔 目标关卡(普通关卡) 实体
--模块负责：吕天元
--===========================
local XSuperTowerTargetStage = XClass(nil, "XSuperTowerTargetStage")

function XSuperTowerTargetStage:Ctor(theme, cfg)
    self.Theme = theme
    self.StStageCfg = cfg
    self:Init()
end
--=================
--初始化
--=================
function XSuperTowerTargetStage:Init()

end

function XSuperTowerTargetStage:InitStageInfo()
    local stageIds = self:GetStageId()
    for _, stageId in pairs(stageIds) do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo then
            stageInfo.Type = XDataCenter.FubenManager.StageType.SuperTower
        end
    end
end
--=================
--获取活动关卡Id
--=================
function XSuperTowerTargetStage:GetId()
    return self.StStageCfg and self.StStageCfg.Id
end
--=================
--获取关卡配置
--=================
function XSuperTowerTargetStage:GetStageCfg(id)
    return XDataCenter.FubenManager.GetStageCfg(id or self:GetFirstStageId())
end

--=================
--刷新关卡进度
--=================
function XSuperTowerTargetStage:RefreshProgress(progress, checkFunc)
    self.CurrentProgress = progress or 0
    if checkFunc then
        XDataCenter.SuperTowerManager.GetFunctionManager():CheckUnLock()
    end
end
--=================
--获取活动关卡对应的StageId组
--=================
function XSuperTowerTargetStage:GetStageId()
    return self.StStageCfg and self.StStageCfg.StageId or {}
end
--=================
--根据stageId获取关卡对应的Index
--=================
function XSuperTowerTargetStage:GetStageIndexByStageId(stageId)
    for index,id in pairs(self:GetStageId()) do
        if id == stageId then
            return index
        end
    end
    return 0
end
--=================
--获取活动关卡对应的第一个关卡表ID
--=================
function XSuperTowerTargetStage:GetFirstStageId()
    return self.StStageCfg and self.StStageCfg.StageId and self.StStageCfg.StageId[1] or 0
end
--=================
--获取活动关卡对应的RewardId组
--=================
function XSuperTowerTargetStage:GetRewardId()
    return self.StStageCfg and self.StStageCfg.RewardId or {}
end
--=================
--获取活动关卡对应的RewardId组
--=================
function XSuperTowerTargetStage:GetRewardIdByProgress(curProgress)
    return self.StStageCfg and self.StStageCfg.RewardId and self.StStageCfg.RewardId[curProgress] or 0
end
--=================
--获取关卡名称
--=================
function XSuperTowerTargetStage:GetStageName(id)
    return self:GetStageCfg(id) and self:GetStageCfg(id).Name
end
--=================
--获取关卡序号缩略名称
--=================
function XSuperTowerTargetStage:GetSimpleName()
    return self.StStageCfg and self.StStageCfg.SimpleName
end
--=================
--获取完整的关卡名称(关卡序号名称 + 关卡名称)
--=================
function XSuperTowerTargetStage:GetFullStageName()
    return self:GetStageName() .. self:GetSimpleName()
end
--=================
--获取关卡描述
--=================
function XSuperTowerTargetStage:GetStageDescription(id)
    return self:GetStageCfg(id) and self:GetStageCfg(id).Description
end
--=================
--获取现在通过的波数(单波关卡波数为1)
--=================
function XSuperTowerTargetStage:GetCurrentProgress()
    return self.CurrentProgress or 0
end
--=================
--获取关卡总波数(单波关卡波数为1)
--=================
function XSuperTowerTargetStage:GetProgress()
    return self.StStageCfg and self.StStageCfg.Progress or 1
end

--=================
--获取当前关卡进度显示
--=================
function XSuperTowerTargetStage:GetProgressStr()
    return self:GetCurrentProgress() .."/".. self:GetProgress()
end
--=================
--检查关卡进度是否达标
--@param progress:目标进度
--=================
function XSuperTowerTargetStage:CheckProgress(progress)
    return progress <= self:GetCurrentProgress()
end
--=================
--检查是否已通关
--=================
function XSuperTowerTargetStage:CheckIsClear()
    return self:GetProgress() <= self:GetCurrentProgress()
end
--=================
--获取活动关卡类型(XSuperTowerManager.StageType)
--=================
function XSuperTowerTargetStage:GetStageType()
    return self.StStageCfg and self.StStageCfg.Type
end
--=================
--获取前置解锁条件要求关卡
--=================
function XSuperTowerTargetStage:GetPreStageId()
    return self.StStageCfg and self.StStageCfg.PreId
end
--=================
--获取前置解锁条件要求波数
--=================
function XSuperTowerTargetStage:GetPreStageProgress()
    return self.StStageCfg and self.StStageCfg.PreProgress
end
--=================
--根据关卡序号获取关卡推荐战力
--=================
function XSuperTowerTargetStage:GetStageAbilityByIndex(index)
    return self.StStageCfg and self.StStageCfg.StageAbility and self.StStageCfg.StageAbility[index] or 0
end
--=================
--根据关卡序号获取登场成员数
--=================
function XSuperTowerTargetStage:GetMemberCountByIndex(index)
    return self.StStageCfg and self.StStageCfg.MemberCount and self.StStageCfg.MemberCount[index] or 0
end
--=================
--根据关卡序号获取关卡ID
--=================
function XSuperTowerTargetStage:GetStageIdByIndex(index)
    return self.StStageCfg and self.StStageCfg.StageId and self.StStageCfg.StageId[index]
end
--=================
--获取活动关卡对应的队伍数
--=================
function XSuperTowerTargetStage:GetTeamCount()
    return self.StStageCfg and self.StStageCfg.StageId and #self.StStageCfg.StageId or 0
end
--=================
--获取前置解锁条件要求关卡的SimpleName
--=================
function XSuperTowerTargetStage:GetPreStageSimpleName()
    local preStageId = self:GetPreStageId()
    if preStageId == 0 then return "" end --没有前置关卡返空字符串
    local preStage = self:GetPreStStage()
    if preStage then
        return preStage:GetSimpleName()
    else
        return ""--没有前置关卡返回空字符串
    end
end
--=================
--获取前置解锁条件要求关卡的类型
--=================
function XSuperTowerTargetStage:GetPreStageType()
    local preStageId = self:GetPreStageId()
    if preStageId == 0 then return nil end
    local preStage = self:GetPreStStage()
    if preStage then
        return preStage:GetStageType()
    else
        return nil
    end
end
--=================
--检查前置关卡解锁条件(前置关卡的开放与进度)
--=================
function XSuperTowerTargetStage:CheckStagePreCondition()
    local preStageId = self:GetPreStageId()
    if preStageId == 0 then return true end --没有前置关卡表示没有前置关卡类条件
    local preStage = self:GetPreStStage()
    if preStage then
        --检查前置关卡有没开放，之后检查前置关卡进度是否达到前置条件
        return preStage:CheckStageIsOpen() and preStage:CheckProgress(self:GetPreStageProgress())
    else
        return false
    end
end
--=================
--获取所属主题ID
--=================
function XSuperTowerTargetStage:GetThemeId()
    return self.StStageCfg and self.StStageCfg.MapId
end
--=================
--获取关卡的开放延时时间（小时
--=================
function XSuperTowerTargetStage:GetOpenTimeDelay()
    return self.StStageCfg and self.StStageCfg.OpenHour
end
--=================
--获取关卡的背景图
--=================
function XSuperTowerTargetStage:GetStageBg()
    return self.StStageCfg and self.StStageCfg.Bg
end
--=================
--获取关卡开放的时间戳(使用主题开放时间+开放延时时间)
--=================
function XSuperTowerTargetStage:GetStartTime()
    return XUiHelper.GetTimeOfDelay(self.Theme:GetStartTime(), self:GetOpenTimeDelay(), XUiHelper.DelayType.Hour)
end
--=================
--获取关卡结束的时间戳（使用主题的结束时间）
--=================
function XSuperTowerTargetStage:GetEndTime()
    return self.Theme:GetEndTime()
end
--=================
--获取关卡开放的本地时间日期字符串
--@param isFullDate:是否显示全部时间显示格式。true显示年月日时分秒，false显示月日
--=================
function XSuperTowerTargetStage:GetStartTimeStr(isFullDate)
    return XTime.TimestampToLocalDateTimeString(self:GetStartTime(), isFullDate and "yyyy-MM-dd HH:mm:ss" or "MM-dd")
end

function XSuperTowerTargetStage:GetPreStStage()
    return self.Theme.StageManager:GetTargetStageByStStageId(self:GetPreStageId())
end
--=================
--检查关卡是否在开放时间内
--=================
function XSuperTowerTargetStage:CheckIsInTime()
    local now = XTime.GetServerNowTimestamp()
    return (now >= self:GetStartTime()) and (now < self:GetEndTime())
end
--=================
--检查关卡是否已开放
--=================
function XSuperTowerTargetStage:CheckStageIsOpen()
    --先检查开放时间,再检查关卡开放前置条件
    return self:CheckIsInTime() and self:CheckStagePreCondition()
end
--=================
--检查关卡是否是多波关卡
--=================
function XSuperTowerTargetStage:CheckIsMultiWave()
    return self:CheckIsSingleTeamMultiWave() or self:CheckIsMultiTeamMultiWave()
end
--=================
--检查关卡是否是单队多波关卡
--=================
function XSuperTowerTargetStage:CheckIsSingleTeamMultiWave()
    return self:GetStageType() == XDataCenter.SuperTowerManager.StageType.SingleTeamMultiWave
end
--=================
--检查关卡是否是多队多波关卡
--=================
function XSuperTowerTargetStage:CheckIsMultiTeamMultiWave()
    return self:GetStageType() == XDataCenter.SuperTowerManager.StageType.MultiTeamMultiWave
end
--=================
--检查关卡是否是单队单波
--=================
function XSuperTowerTargetStage:CheckIsSingleTeamOneWave()
    return self:GetStageType() == XDataCenter.SuperTowerManager.StageType.SingleTeamOneWave
end
--=================
--检查关卡是否是爬塔
--=================
function XSuperTowerTargetStage:CheckIsLllimitedTower()
    return self:GetStageType() == XDataCenter.SuperTowerManager.StageType.LllimitedTower
end

return XSuperTowerTargetStage