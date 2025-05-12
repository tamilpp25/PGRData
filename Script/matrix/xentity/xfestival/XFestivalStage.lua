-- 庆典类活动关卡对象
---@class XFestivalStage
local XFestivalStage = XClass(nil, "XFestivalStage")
--====================
--构造函数
--@param stageId:关卡ID
--@param orderIndex:关卡在章节中的序号
--@param chapter:章节对象
--====================
function XFestivalStage:Ctor(stageId, orderIndex, chapter)
    self.StageId = stageId
    self.Chapter = chapter
    self.OrderIndex = orderIndex
    self:InitStage()
end
--====================
--初始化关卡配置
--====================
function XFestivalStage:InitStage()
    self.FestivalStageCfg = XFestivalActivityConfig.GetFestivalStageCfgByStageId(self.StageId)
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.PassCount = 0
end

function XFestivalStage:RefreshStage()
    self:RefreshStageInfo()
end
--====================
--获取关卡ID
--====================
function XFestivalStage:GetStageId()
    return self.StageId
end
--====================
--获取所属章节对象
--====================
function XFestivalStage:GetChapter()
    return self.Chapter
end
--====================
--获取关卡基本配置
--====================
function XFestivalStage:GetStageCfg()
    return self.StageCfg
end
--====================
--获取关卡序号名称
--====================
function XFestivalStage:GetOrderName()
    return self.Chapter and string.format("%s%d", self.Chapter:GetStagePrefix(), self.OrderIndex)
end
--====================
--获取关卡名称
--====================
function XFestivalStage:GetName()
    return (self.FestivalStageCfg and self.FestivalStageCfg.StageName) or self.StageCfg.Name
end
--====================
--获取关卡序号
--====================
function XFestivalStage:GetOrderIndex()
    return self.OrderIndex
end
--====================
--获取开放条件ID
--====================
function XFestivalStage:GetOpenConditionId()
    return self.FestivalStageCfg and self.FestivalStageCfg.OpenConditionId or {}
end
--====================
--获取解锁类型，默认是0：未解锁整个节点不显示  1：未解锁显示上锁
--====================
function XFestivalStage:GetUnlockType()
    return self.FestivalStageCfg and self.FestivalStageCfg.UnlockType or 0
end
--====================
--上锁的时候是否显示
--====================
function XFestivalStage:IsLockShow()
    return self:GetUnlockType() == 1
end
--====================
--获取关卡是否开启
--====================
function XFestivalStage:GetCanOpen()
    local stageInfo = self:_GetStageInfo()
    if not stageInfo.Unlock then return false, CS.XTextManager.GetText("FubenNotUnlock") end
    if self.StageCfg.RequireLevel > 0 and XPlayer.Level < self.StageCfg.RequireLevel then
        return false, CS.XTextManager.GetText("TeamLevelToOpen", self.StageCfg.RequireLevel)
    end
    for _, conditionId in pairs(self:GetOpenConditionId()) do
        local ret, desc = XConditionManager.CheckCondition(conditionId)
        if not ret then
            return false, desc
        end
    end
    -- 如果是彩蛋关
    if self:GetIsEggStage() then
        if stageInfo.Unlock and XDataCenter.FubenManager.GetUnlockHideStageById(self.StageId) then
            -- 彩蛋已经解锁
            return true, ""
        else
            -- 彩蛋未解锁
            return false, CS.XTextManager.GetText("FubenNotUnlock")
        end
    end
    return true, ""
end
--====================
--获取关卡类型
--====================
function XFestivalStage:GetStageType()
    return self.StageCfg and self.StageCfg.StageType
end
--====================
--获取是否彩蛋关
--====================
function XFestivalStage:GetIsEggStage()
    local stageType = self:GetStageType()
    return stageType and ((stageType == XFubenConfigs.STAGETYPE_STORYEGG) or (stageType == XFubenConfigs.STAGETYPE_FIGHTEGG))
end
--====================
--获取关卡预制体
--====================
function XFestivalStage:GetStagePrefab()
    if self.FestivalStageCfg and self.FestivalStageCfg.StageStyle then
        return self.FestivalStageCfg.StageStyle
    elseif self.StageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHT then
        return self.Chapter and self.Chapter:GetGridFubenPrefab()
    elseif self.StageCfg.StageType == XFubenConfigs.STAGETYPE_STORY then
        return self.Chapter and self.Chapter:GetGridStoryPrefab()
    else
        return self.Chapter and self.Chapter:GetGridFubenPrefab()
    end
    return nil
end
--====================
--获取关卡显示类型
--====================
function XFestivalStage:GetStageShowType()
    local stageType = self:GetStageType()
    if stageType == XFubenConfigs.STAGETYPE_FIGHT or stageType == XFubenConfigs.STAGETYPE_FIGHTEGG then
        return XDataCenter.FubenFestivalActivityManager.StageFuben
    elseif stageType == XFubenConfigs.STAGETYPE_STORY or stageType == XFubenConfigs.STAGETYPE_STORYEGG then
        return XDataCenter.FubenFestivalActivityManager.StageStory
    else
        return XDataCenter.FubenFestivalActivityManager.StageFuben
    end
end
--====================
--设置关卡通过状态
--@param isPass:要设置的关卡通过状态
--====================
function XFestivalStage:SetIsPass(isPass)
    self.Passed = isPass
end
--====================
--获取关卡是否通过
--====================
function XFestivalStage:GetIsPass()
    return self.Passed or false
end
--====================
--获取关卡是否开放
--====================
function XFestivalStage:GetIsOpen()
    local stageInfo = self:_GetStageInfo()
    return stageInfo.IsOpen or false
end
--====================
--获取关卡是否显示
--====================
function XFestivalStage:GetIsShow()
    -- 已解锁
    local stageInfo = self:_GetStageInfo()
    if stageInfo.IsOpen then 
        return true
    elseif self:IsLockShow() and self:_IsAllPreStagePassed() then
        return true
    end
    return false
end
--====================
--设置关卡通关次数
--@param count:设置的次数
--====================
function XFestivalStage:SetPassCount(count)
    self.PassCount = count
end
--====================
--增加关卡通关次数
--@param addCount:增加的次数
--====================
function XFestivalStage:AddPassCount(addCount)
    self.PassCount = self.PassCount + addCount
end
--====================
--获取关卡通关次数
--====================
function XFestivalStage:GetPassCount()
    return self.PassCount
end
--====================
--获取前置关卡ID组
--====================
function XFestivalStage:GetPreStageId()
    return self.StageCfg and self.StageCfg.PreStageId or {}
end
--====================
--获取关卡通关三星描述
--====================
function XFestivalStage:GetStarDesc()
    return self.StageCfg and self.StageCfg.StarDesc
end
--====================
--根据序号获取关卡通关星数条件描述
--@param index:条件序号
--====================
function XFestivalStage:GetStarDescByIndex(index)
    local desc = self:GetStarDesc()
    if not desc then return "" end
    return desc[index]
end
--====================
--获取关卡通关星数字典
--====================
function XFestivalStage:GetStarMaps()
    local stageInfo = self:_GetStageInfo()
    return stageInfo and stageInfo.StarMaps
end
--====================
--根据序号获取该项通关星数是否通过
--====================
function XFestivalStage:GetStarMapsByIndex(index)
    local maps = self:GetStarMaps()
    if not maps then return end
    return maps[index]
end
--====================
--获取关卡挑战上限数
--====================
function XFestivalStage:GetMaxChallengeNum()
    return XDataCenter.FubenManager.GetStageMaxChallengeNums(self.StageId)
end
--====================
--获取关卡挑战所需体力
--====================
function XFestivalStage:GetRequireActionPoint()
    return XDataCenter.FubenManager.GetRequireActionPoint(self.StageId)
end
--====================
--获取关卡图标
--====================
function XFestivalStage:GetIcon()
    return self.StageCfg and self.StageCfg.Icon
end
--====================
--获取剧情关卡图标
--====================
function XFestivalStage:GetStoryIcon()
    return self.StageCfg and self.StageCfg.StoryIcon
end
--====================
--获取关卡首通奖励
--====================
function XFestivalStage:GetFirstRewardShow()
    return self.StageCfg and self.StageCfg.FirstRewardShow
end
--====================
--获取关卡非首通通关奖励
--====================
function XFestivalStage:GetFinishRewardShow()
    return self.StageCfg and self.StageCfg.FinishRewardShow
end
--====================
--刷新关卡信息
--====================
function XFestivalStage:RefreshStageInfo()
end

function XFestivalStage:_GetStageInfo()
    return XMVCA.XFuben:GetStageInfo(self.StageId)
end

--====================
--是否所有前置关卡都通过
--====================
function XFestivalStage:_IsAllPreStagePassed()
    local preStageIds = self:GetPreStageId()
    if not XTool.IsTableEmpty(preStageIds) then
        for _, stageId in pairs(preStageIds) do
            local isPass = XMVCA.XFuben:CheckStageIsPass(stageId)
            if not isPass then
                return false
            end
        end
    end
    return true
end
return XFestivalStage