---@class XScoreTowerControl : XEntityControl
---@field private _Model XScoreTowerModel
local XScoreTowerControl = XClass(XEntityControl, "XScoreTowerControl")
function XScoreTowerControl:OnInit()
    --初始化内部变量
    self.RequestName = {
        XScoreTowerOpenTowerRequest = "XScoreTowerOpenTowerRequest",             -- 开启一个塔
        XScoreTowerSetStageTeamRequest = "XScoreTowerSetStageTeamRequest",       -- 设置关卡角色
        XScoreTowerBossStageSettleRequest = "XScoreTowerBossStageSettleRequest", -- BOSS关结算，前往下一层，或者最顶层结算
        XScoreTowerAdvanceSettleRequest = "XScoreTowerAdvanceSettleRequest",     -- 提前结算
        XScoreTowerSweepStageRequest = "XScoreTowerSweepStageRequest",           -- 扫荡一关
        XScoreTowerSweepFloorRequest = "XScoreTowerSweepFloorRequest",           -- 一键扫荡
        XScoreTowerSelectPlugInRequest = "XScoreTowerSelectPlugInRequest",       -- 设置BOSS的插件
        XScoreTowerStrengthenRequest = "XScoreTowerStrengthenRequest",           -- 强化
        XScoreTowerQueryRankRequest = "XScoreTowerQueryRankRequest",             -- 查看矿区排行榜信息
    }
end

function XScoreTowerControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XScoreTowerControl:RemoveAgencyEvent()

end

function XScoreTowerControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
    self._Model = false
end

--region 请求相关

--- 请求开启一个塔
---@param towerId number 塔ID
---@param characterInfos XScoreTowerCharacterInfo[] 角色信息
---@param cb function 回调
function XScoreTowerControl:OpenTowerRequest(towerId, characterInfos, cb)
    local req = { TowerId = towerId, CharacterInfos = characterInfos }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.XScoreTowerOpenTowerRequest, req, function(res)
        if self._Model.ActivityData then
            -- 更新章节数据
            self._Model.ActivityData:SetCurChapterId(res.CurChapterId)
            self._Model.ActivityData:AddChapterData(res.ChapterData)
            -- 更新塔记录数据
            self._Model.ActivityData:AddTowerRecord(res.TowerRecord)
        end
        if cb then
            cb()
        end
    end)
end

--- 请求设置关卡角色
---@param team XScoreTowerStageTeam 队伍数据
---@param isJoin boolean 是否上阵 true : 上阵  false : 下阵
---@param cb function 回调
function XScoreTowerControl:SetStageTeamRequestByTeam(team, isJoin, cb)
    self._Model:SetStageTeamRequestByTeam(team, isJoin, cb)
end

--- 请求重置关卡角色
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param stageCfgId number 关卡配置ID ScoreTowerStage表的ID
---@param cb function 回调
function XScoreTowerControl:ResetStageTeamRequest(chapterId, towerId, stageCfgId, cb)
    self._Model:SetStageTeamRequest(chapterId, towerId, stageCfgId, { 0, 0, 0 }, function()
        XEventManager.DispatchEvent(XEventId.EVENT_SCORE_TOWER_STAGE_CHANGE, stageCfgId)
        if cb then
            cb()
        end
    end)
end

--- 请求BOSS关结算，前往下一层，或者最顶层结算
---@param cb function 回调
function XScoreTowerControl:BossStageSettleRequest(cb)
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.XScoreTowerBossStageSettleRequest, nil, function(res)
        if self._Model.ActivityData then
            self._Model.ActivityData:SetCurChapterId(res.CurChapterId)
            -- 更新章节数据和章节记录数据
            self._Model.ActivityData:AddChapterData(res.ChapterData)
            self._Model.ActivityData:AddChapterRecord(res.ChapterRecord)
            -- 更新关卡记录数据
            self._Model.ActivityData:AddStageRecord(res.StageRecord)
        end
        -- 弹出奖励界面
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            XUiManager.OpenUiObtain(res.RewardGoodsList, nil, cb)
            return
        end
        if cb then
            cb()
        end
    end)
end

--- 请求提前结算
---@param towerId number 塔ID
---@param cb function 回调
function XScoreTowerControl:AdvanceSettleRequest(towerId, cb)
    local req = { TowerId = towerId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.XScoreTowerAdvanceSettleRequest, req, function(res)
        -- 更新章节数据
        if self._Model.ActivityData then
            self._Model.ActivityData:SetCurChapterId(res.CurChapterId)
            self._Model.ActivityData:AddChapterData(res.ChapterData)
        end
        -- 清空关卡编队
        self._Model.StageTeamList = nil
        if cb then
            cb()
        end
    end)
end

--- 请求扫荡一关
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param stageCfgId number 关卡配置ID ScoreTowerStage表的ID
---@param cb function 回调
function XScoreTowerControl:SweepStageRequest(chapterId, towerId, stageCfgId, cb)
    local req = { StageCfgId = stageCfgId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.XScoreTowerSweepStageRequest, req, function(res)
        -- 更新关卡数据
        local towerData = self._Model:GetTowerData(chapterId, towerId)
        if towerData then
            towerData:AddStageData(res.StageData)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_SCORE_TOWER_STAGE_CHANGE, stageCfgId)
        if cb then
            cb()
        end
    end)
end

--- 请求一键扫荡
---@param towerId number 塔ID
---@param cb function 回调
function XScoreTowerControl:SweepFloorRequest(towerId, cb)
    local req = { TowerId = towerId }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.XScoreTowerSweepFloorRequest, req, function(res)
        -- 更新章节数据
        if self._Model.ActivityData then
            self._Model.ActivityData:SetCurChapterId(res.CurChapterId)
            self._Model.ActivityData:SetTowerSweepRecord(towerId, res.CurSweepCount)
            self._Model.ActivityData:AddChapterData(res.ChapterData)
        end
        -- 弹出奖励界面
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            XUiManager.OpenUiObtain(res.RewardGoodsList, nil, cb)
            return
        end
        if cb then
            cb()
        end
    end)
end

--- 请求设置BOSS的插件
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param stageCfgId number 关卡配置ID ScoreTowerStage表的ID
---@param plugIndex number[] 插件索引
---@param cb function 回调
function XScoreTowerControl:SelectPlugInRequest(chapterId, towerId, stageCfgId, plugIndex, cb)
    local req = { StageCfgId = stageCfgId, PlugIndex = plugIndex }
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.XScoreTowerSelectPlugInRequest, req, function(res)
        -- 更新关卡插件索引
        local stageData = self._Model:GetStageData(chapterId, towerId, stageCfgId)
        if stageData then
            stageData:UpdateSelectedPlugIndex(plugIndex)
        end
        if cb then
            cb()
        end
    end)
end

--- 请求强化
---@param cfgId number 强化配置表的ID
---@param cb function 回调
function XScoreTowerControl:StrengthenRequest(cfgId, cb)
    local req = { CfgId = cfgId }
    XNetwork.Call(self.RequestName.XScoreTowerStrengthenRequest, req, function(res)
        if res.Code ~= XCode.Success and res.Code ~= XCode.ScoreTowerStrengthenFail then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 更新强化数据
        if self._Model.ActivityData then
            self._Model.ActivityData:AddStrengthen(res.StrengthenData)
        end
        XLuaUiManager.Open("UiScoreTowerToastStrengthen", cfgId, res.Code == XCode.Success)
        if cb then
            cb()
        end
    end)
end

--- 请求查看矿区排行榜信息
---@param cb function 回调
function XScoreTowerControl:QueryRankRequest(cb)
    XNetwork.CallWithAutoHandleErrorCode(self.RequestName.XScoreTowerQueryRankRequest, nil, function(res)
        -- 更新矿区排行榜数据
        self:UpdateQueryRankData(res)
        if cb then
            cb()
        end
    end)
end

--endregion

--region 编队相关

--- 获取塔编队数据
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@return XScoreTowerTowerTeam 队伍数据
function XScoreTowerControl:GetTowerTeam(chapterId, towerId)
    local team = self._Model:GetTowerTeam(towerId)
    -- 设置章节Id和塔Id
    team:SetChapterId(chapterId)
    team:SetTowerId(towerId)
    -- 过滤掉无效的机器Id
    team:FilterInvalidEntityIds(self._Model:GetAllRobotIds(chapterId))
    return team
end

--- 获取关卡编队数据
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param floorId number 塔层ID
---@param cfgId number ScoreTowerStage表Id
---@return XScoreTowerStageTeam 队伍数据
function XScoreTowerControl:GetStageTeam(chapterId, towerId, floorId, cfgId)
    local team = self._Model:GetStageTeam(towerId, cfgId)
    -- 设置章节Id、塔Id、关卡Id和塔层Id
    team:SetChapterId(chapterId)
    team:SetTowerId(towerId)
    team:SetFloorId(floorId)
    team:SetStageCfgId(cfgId)
    -- 过滤掉无效的角色Id
    team:FilterInvalidEntityIds(self._Model:GetTowerLockedCharacterIds(chapterId, towerId, floorId, cfgId))
    return team
end

--endregion

--region 排行榜相关

--- 更新矿区排行榜数据
function XScoreTowerControl:UpdateQueryRankData(data)
    if not data then
        self._Model.QueryRankData = nil
        return
    end
    if not self._Model.QueryRankData then
        self._Model.QueryRankData = require("XModule/XScoreTower/XEntity/XScoreTowerQueryRank").New()
    end
    self._Model.QueryRankData:NotifyScoreTowerQueryRankData(data)
end

--- 获取自己的排名
function XScoreTowerControl:GetQueryRankSelfRank()
    return self._Model.QueryRankData and self._Model.QueryRankData:GetSelfRank() or 0
end

--- 获取当前自己的信息
function XScoreTowerControl:GetQueryRankSelfPlayerInfo()
    return self._Model.QueryRankData and self._Model.QueryRankData:GetSelfRankPlayer() or nil
end

--- 获取排行榜总人数
function XScoreTowerControl:GetQueryRankTotalCount()
    return self._Model.QueryRankData and self._Model.QueryRankData:GetTotalCount() or 0
end

--- 获取排行榜玩家信息列表
function XScoreTowerControl:GetQueryRankPlayerInfoList()
    return self._Model.QueryRankData and self._Model.QueryRankData:GetRankPlayerInfos() or {}
end

--- 检查排行榜是否开启
---@return boolean, string 是否开启，未开启提示
function XScoreTowerControl:IsActivityRankOpen()
    -- 检查时间
    local openTimeId = self._Model:GetActivityRankOpenTimeId()
    if XTool.IsNumberValid(openTimeId) and not XFunctionManager.CheckInTimeByTimeId(openTimeId) then
        local startTime = XFunctionManager.GetStartTimeByTimeId(openTimeId)
        return false, XUiHelper.FormatText(self:GetClientConfig("RankNotOpen"), XTime.TimestampToGameDateTimeString(startTime))
    end
    -- 检查条件
    local openConditions = self._Model:GetActivityRankOpenConditions()
    for _, conditionId in pairs(openConditions) do
        local isOpen, desc = XConditionManager.CheckCondition(conditionId)
        if not isOpen then
            return false, desc
        end
    end
    return true, ""
end

--endregion

--region 记录数据相关

--- 获取章节记录的最大分数
---@param chapterId number 章节ID
function XScoreTowerControl:GetChapterRecordMaxPoint(chapterId)
    local chapterRecord = self._Model:GetChapterRecord(chapterId)
    if not chapterRecord then
        return 0
    end
    return chapterRecord:GetMaxPoint() or 0
end

--endregion

--region 活动相关

--- 获取活动章节Id列表
function XScoreTowerControl:GetActivityChapterIds()
    return self._Model:GetActivityChapterIds()
end

--endregion

--region 章节相关

--- 获取章节时间
---@param chapterId number 章节ID
function XScoreTowerControl:GetChapterTime(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.TimeId or 0
end

-- 获取章节塔Id列表
function XScoreTowerControl:GetChapterTowerIds(chapterId)
    return self._Model:GetChapterTowerIds(chapterId)
end

--- 获取章节前置条件
---@param chapterId number 章节ID
function XScoreTowerControl:GetChapterPreCondition(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.ChapterIdCondition or 0
end

--- 获取章节前置分数条件
---@param chapterId number 章节ID
function XScoreTowerControl:GetChapterPreScoreCondition(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.ScoreCondition or 0
end

--- 获取章节名称
---@param chapterId number 章节ID
function XScoreTowerControl:GetChapterName(chapterId)
    local config = self._Model:GetChapterConfig(chapterId)
    return config and config.ChapterName or ""
end

--- 检查是否在章节时间内
---@param chapterId number 章节ID
function XScoreTowerControl:IsInChapterTime(chapterId)
    local timeId = self:GetChapterTime(chapterId)
    local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
    local nowTime = XTime.GetServerNowTimestamp()

    if startTime > 0 and nowTime < startTime then
        local timeStr = XUiHelper.GetTime(startTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
        return false, XUiHelper.FormatText(self:GetClientConfig("ChapterNotStart"), timeStr)
    end
    if endTime > 0 and nowTime >= endTime then
        return false, self:GetClientConfig("ChapterAlreadyOver")
    end
    return true, ""
end

--- 章节的前置章节是否达到对应的积分
---@param chapterId number 章节ID
---@return boolean, string 是否达到对应的积分，未达到原因
function XScoreTowerControl:IsChapterPreChapterScorePass(chapterId)
    local preChapterId = self:GetChapterPreCondition(chapterId)
    local preChapterScore = self:GetChapterPreScoreCondition(chapterId)
    if not XTool.IsNumberValid(preChapterId) or not XTool.IsNumberValid(preChapterScore) then
        return true, ""
    end
    local currentScore = self:GetChapterCurPoint(preChapterId)
    if currentScore >= preChapterScore then
        return true, ""
    end
    local preChapterName = self:GetChapterName(preChapterId)
    return false, XUiHelper.FormatText(self:GetClientConfig("ChapterPreChapterScoreNotPass"), preChapterName, preChapterScore)
end

--- 章节是否解锁
---@param chapterId number 章节ID
---@return boolean, string 是否解锁，未解锁原因
function XScoreTowerControl:IsChapterUnlock(chapterId)
    local inTime, timeTip = self:IsInChapterTime(chapterId)
    if not inTime then
        return false, timeTip
    end
    local preChapterScorePass, preChapterScoreTip = self:IsChapterPreChapterScorePass(chapterId)
    if not preChapterScorePass then
        return false, preChapterScoreTip
    end
    return true, ""
end

--- 章节是否通关
---@param chapterId number 章节ID
function XScoreTowerControl:IsChapterPass(chapterId)
    return self:GetChapterCurStar(chapterId) > 0
end

--- 获取章节当前积分
---@param chapterId number 章节ID
function XScoreTowerControl:GetChapterCurPoint(chapterId)
    return self._Model:GetChapterCurPoint(chapterId)
end

--- 获取章节当前星级
---@param chapterId number 章节ID
function XScoreTowerControl:GetChapterCurStar(chapterId)
    return self._Model:GetChapterCurStar(chapterId)
end

--- 获取章节的总星级
---@param chapterId number 章节ID
function XScoreTowerControl:GetChapterTotalStar(chapterId)
    return self._Model:GetChapterTotalStar(chapterId)
end

--- 获取章节最后一个塔Id
---@param chapterId number 章节ID
function XScoreTowerControl:GetChapterLastTowerId(chapterId)
    return self._Model:GetChapterLastTowerId(chapterId)
end

--- 获取当前的章节Id
function XScoreTowerControl:GetCurrentChapterId()
    return self._Model:GetCurrentChapterId()
end

--- 章节是否正在进行中
---@param chapterId number 章节ID
function XScoreTowerControl:IsChapterProgress(chapterId)
    return self:GetCurrentChapterId() == chapterId
end

--endregion

--region 塔相关

--- 获取塔名称
---@param towerId number 塔ID
function XScoreTowerControl:GetTowerName(towerId)
    local config = self._Model:GetTowerConfig(towerId)
    return config and config.TowerName or ""
end

--- 获取塔解锁塔Id
---@param towerId number 塔ID
function XScoreTowerControl:GetTowerUnlockTowerId(towerId)
    local config = self._Model:GetTowerConfig(towerId)
    return config and config.UnlockTowerId or 0
end

--- 获取塔的上阵角色数量要求
---@param towerId number 塔ID
function XScoreTowerControl:GetTowerCharacterNum(towerId)
    return self._Model:GetTowerCharacterNum(towerId)
end

--- 获取塔的扫荡次数限制
---@param towerId number 塔ID
function XScoreTowerControl:GetTowerSweepCount(towerId)
    local config = self._Model:GetTowerConfig(towerId)
    return config and config.SweepCount or 0
end

--- 获取塔的推荐Tag类型
---@param towerId number 塔ID
function XScoreTowerControl:GetTowerSuggestTagType(towerId)
    return self._Model:GetTowerSuggestTagType(towerId)
end

--- 获取塔的推荐Tag数量
---@param towerId number 塔ID
function XScoreTowerControl:GetTowerSuggestTagCount(towerId)
    local config = self._Model:GetTowerConfig(towerId)
    return config and config.SuggestTagCount or 0
end

--- 获取当前的塔Id
---@param chapterId number 章节ID
function XScoreTowerControl:GetCurrentTowerId(chapterId)
    local chapterData = self._Model:GetChapterData(chapterId)
    if not chapterData then
        return 0
    end
    return chapterData:GetCurTowerId() or 0
end

--- 获取塔的总插件点数
---@param chapterId number 章节ID
---@param towerId number 塔ID
function XScoreTowerControl:GetTowerTotalPlugInPoint(chapterId, towerId)
    local towerData = self._Model:GetTowerData(chapterId, towerId)
    if not towerData then
        return 0
    end
    return towerData:GetTotalPlugInPoint() or 0
end

--- 获取塔推荐的实体Id列表
---@param chapterId number 章节ID
---@param towerId number 塔Id
function XScoreTowerControl:GetTowerSuggestEntityIdIds(chapterId, towerId)
    if not XTool.IsNumberValid(chapterId) or not XTool.IsNumberValid(towerId) then
        return {}
    end
    local suggestCharacterIds = self._Model:GetTowerSuggestCharacterIds(towerId)
    local tempEntityIds = {}
    for index, characterId in ipairs(suggestCharacterIds) do
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(characterId)
        local robotId = self:GetRobotIdByCharacterId(chapterId, characterId)
        if isOwn then
            if robotId > 0 then
                local charAbility = XMVCA.XCharacter:GetCharacterAbilityById(characterId)
                local robotAbility = XRobotManager.GetRobotAbility(robotId)
                tempEntityIds[index] = (charAbility > robotAbility) and characterId or robotId
            else
                tempEntityIds[index] = characterId
            end
        elseif robotId > 0 then
            tempEntityIds[index] = robotId
        end
    end
    return tempEntityIds
end

--- 通过角色Id获取机器人Id
---@param chapterId number 章节ID
---@param characterId number 角色Id
function XScoreTowerControl:GetRobotIdByCharacterId(chapterId, characterId)
    local robotIds = self._Model:GetAllRobotIds(chapterId)
    for _, robotId in pairs(robotIds) do
        if XRobotManager.GetCharacterId(robotId) == characterId then
            return robotId
        end
    end
    return 0
end

--- 获取塔当前分数
---@param chapterId number 章节ID
---@param towerId number 塔ID
function XScoreTowerControl:GetTowerCurPoint(chapterId, towerId)
    local towerData = self._Model:GetTowerData(chapterId, towerId)
    if not towerData then
        return 0
    end
    return towerData:GetCurPoint() or 0
end

--- 获取塔当前星级
---@param chapterId number 章节ID
---@param towerId number 塔ID
function XScoreTowerControl:GetTowerCurStar(chapterId, towerId)
    local towerData = self._Model:GetTowerData(chapterId, towerId)
    if not towerData then
        return 0
    end
    return towerData:GetCurStar() or 0
end

--- 获取塔的总星级
---@param towerId number 塔ID
function XScoreTowerControl:GetTowerTotalStar(towerId)
    local finalBossStageId = self:GetFinalBossStageIdByTowerId(towerId)
    if not XTool.IsNumberValid(finalBossStageId) then
        return 0
    end
    return self:GetStageTotalStar(finalBossStageId)
end

--- 获取塔显示的角色信息列表
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param towerTeam XScoreTowerTowerTeam 塔队伍数据
function XScoreTowerControl:GetTowerShowCharacterInfoList(chapterId, towerId, towerTeam)
    local ownCharacterList = XMVCA.XCharacter:GetOwnCharacterList()
    ---@type { Id:number }[]
    local showCharacterInfos = {}
    -- 已拥有的角色Id列表
    for _, character in pairs(ownCharacterList) do
        table.insert(showCharacterInfos, { Id = character:GetId() })
    end
    -- 机器Id列表
    local robotIds = self._Model:GetAllRobotIds(chapterId)
    for _, robotId in pairs(robotIds) do
        table.insert(showCharacterInfos, { Id = robotId })
    end
    return self:GetTowerCharacterFilterSort(showCharacterInfos, towerId, towerTeam)
end

--- 检查塔是否通关
---@param chapterId number 章节ID
---@param towerId number 塔ID
function XScoreTowerControl:IsTowerPass(chapterId, towerId)
    return self:GetTowerCurStar(chapterId, towerId) > 0
end

--- 检查塔是否解锁
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@return boolean, string 是否解锁，未解锁原因
function XScoreTowerControl:IsTowerUnlock(chapterId, towerId)
    local unlockTowerId = self:GetTowerUnlockTowerId(towerId)
    if unlockTowerId > 0 and not self:IsTowerPass(chapterId, unlockTowerId) then
        return false, XUiHelper.FormatText(self:GetClientConfig("TowerPreTowerNotPass"), self:GetTowerName(unlockTowerId))
    end
    return true, ""
end

--- 检查是否是塔推荐Tag
---@param towerId number 塔ID
---@param entityId number 实体ID
function XScoreTowerControl:IsTowerSuggestTag(towerId, entityId)
    if not XTool.IsNumberValid(towerId) or not XTool.IsNumberValid(entityId) then
        return false
    end
    return self._Model:IsTowerSuggestTag(towerId, entityId)
end

--- 获取塔是否满足扫荡条件
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@return boolean, boolean, number 是否满足扫荡条件 是否扫荡整座塔 当前扫荡的层Id
function XScoreTowerControl:IsTowerSweepConditionPass(chapterId, towerId)
    -- 检查挑战次数是否满足
    local sweepCount = self:GetTowerSweepCount(towerId)
    local recordCount = self._Model:GetTowerSweepRecord(towerId)
    if recordCount >= sweepCount then
        return false, false, 0
    end

    local curFloorCount, curFloorId = 0, 0
    local allFloorIds = self:GetAllFloorIds(towerId)
    for index, floorId in ipairs(allFloorIds) do
        if not self:IsFloorPass(chapterId, towerId, floorId) then
            if self:IsFloorSweepConditionPass(floorId) then
                curFloorCount = index
            else
                break
            end
        end
    end

    -- 获取当前扫荡的层Id
    if curFloorCount > 0 and curFloorCount < #allFloorIds then
        curFloorId = allFloorIds[curFloorCount + 1]
    end

    return curFloorCount > 0, curFloorCount >= #allFloorIds, curFloorId
end

--endregion

--region 塔层相关

--- 获取所有的塔层Id列表
function XScoreTowerControl:GetAllFloorIds(towerId)
    if not XTool.IsNumberValid(towerId) then
        return {}
    end
    -- 获取塔层Id列表
    local floorIdList = self._Model:GetFloorIdListByTowerId(towerId)
    -- 排序
    table.sort(floorIdList, function(a, b)
        return a < b
    end)
    return floorIdList
end

--- 获取塔层名称
---@param floorId number 塔层ID
function XScoreTowerControl:GetFloorName(floorId)
    local config = self._Model:GetFloorConfig(floorId)
    return config and config.FloorName or ""
end

--- 获取塔层上一个塔层Id
---@param floorId number 塔层ID
function XScoreTowerControl:GetFloorPreFloorId(floorId)
    local config = self._Model:GetFloorConfig(floorId)
    return config and config.PreFloorId or 0
end

--- 获取塔层的扫荡条件需要通过的章节ID
---@param floorId number 塔层ID
function XScoreTowerControl:GetFloorSweepChapterIdCondition(floorId)
    local config = self._Model:GetFloorConfig(floorId)
    return config and config.SweepChapterIdCondition or 0
end

--- 获取塔层的扫荡条件需要获得的章节积分
---@param floorId number 塔层ID
function XScoreTowerControl:GetFloorSweepScoreCondition(floorId)
    local config = self._Model:GetFloorConfig(floorId)
    return config and config.SweepScoreCondition or 0
end

--- 获取塔层通关奖励Id
---@param floorId number 塔层ID
function XScoreTowerControl:GetFloorPassRewardId(floorId)
    local config = self._Model:GetFloorConfig(floorId)
    return config and config.RewardId or 0
end

--- 获取塔层的背景图片
---@param floorId number 塔层ID
function XScoreTowerControl:GetFloorBgImgUrl(floorId)
    local config = self._Model:GetFloorConfig(floorId)
    return config and config.BgImgUrl or ""
end

--- 获取当前层Id
---@param chapterId number 章节ID
---@param towerId number 塔ID
function XScoreTowerControl:GetCurrentFloorId(chapterId, towerId)
    local towerData = self._Model:GetTowerData(chapterId, towerId)
    if not towerData then
        return 0
    end
    return towerData:GetCurFloorId() or 0
end

--- 检查塔层是否通关
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param floorId number 塔层ID
function XScoreTowerControl:IsFloorPass(chapterId, towerId, floorId)
    local stageIds = self:GetFloorStageIdsByStageType(floorId, XEnumConst.ScoreTower.StageType.Boss)
    if XTool.IsTableEmpty(stageIds) then
        return true
    end
    for _, stageId in pairs(stageIds) do
        if not self:IsStagePass(chapterId, towerId, stageId) then
            return false
        end
    end
    return true
end

--- 检查塔层是否解锁
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param floorId number 塔层ID
---@return boolean, string 是否解锁
function XScoreTowerControl:IsFloorUnlock(chapterId, towerId, floorId)
    local preFloorId = self:GetFloorPreFloorId(floorId)
    if preFloorId > 0 and not self:IsFloorPass(chapterId, towerId, preFloorId) then
        return false
    end
    return true
end

--- 检查塔层是否满足扫荡条件
---@param floorId number 塔层ID
function XScoreTowerControl:IsFloorSweepConditionPass(floorId)
    -- 检查章节积分是否满足
    local sweepChapterId = self:GetFloorSweepChapterIdCondition(floorId)
    local sweepScore = self:GetFloorSweepScoreCondition(floorId)
    if not XTool.IsNumberValid(sweepChapterId) or not XTool.IsNumberValid(sweepScore) then
        return false
    end
    local curScore = self:GetChapterRecordMaxPoint(sweepChapterId)
    if curScore < sweepScore then
        return false
    end
    return true
end

--endregion

--region 塔层关卡相关

--- 获取所有的塔层关卡Id列表
function XScoreTowerControl:GetAllStageIds(floorId)
    if not XTool.IsNumberValid(floorId) then
        return {}
    end
    -- 获取塔层关卡Id列表
    local stageIdList = self._Model:GetStageIdListByFloorId(floorId)
    -- 排序
    table.sort(stageIdList, function(a, b)
        return a < b
    end)
    return stageIdList
end

--- 获取塔层关卡Id列表 通过关卡类型
---@param floorId number 塔层ID
---@param stageType number 关卡类型
function XScoreTowerControl:GetFloorStageIdsByStageType(floorId, stageType)
    local stageIdList = self:GetAllStageIds(floorId)
    local stageIds = {}
    for _, stageId in ipairs(stageIdList) do
        if self:GetStageType(stageId) == stageType then
            table.insert(stageIds, stageId)
        end
    end
    return stageIds
end

--- 获取塔层关卡类型
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageType(stageId)
    return self._Model:GetStageType(stageId)
end

--- 获取塔层关卡上阵角色数量
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageCharacterNum(stageId)
    return self._Model:GetStageCharacterNum(stageId)
end

--- 获取关卡Id
---@param stageId number 塔层关卡ID ScoreTowerStage表的ID
---@return number 关卡配置ID Stage.tab的ID
function XScoreTowerControl:GetStageCfgId(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.StageId or 0
end

--- 获取塔层关卡扫荡战力要求
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageSweepAverFaRequire(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.SweepAverFaRequire or 0
end

--- 获取塔层关卡怪物组Id
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageMonsterGroupId(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.MonsterGroupIds or {}
end

--- 获取塔层关卡弱点
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageWeakness(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.Weakness or 0
end

--- 获取塔层关卡插件关条目ID
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStagePlugPointIds(stageId)
    return self._Model:GetStagePlugPointIds(stageId)
end

--- 获取塔层关卡是否是最终BOSS
---@param stageId number 塔层关卡ID
function XScoreTowerControl:IsStageFinalBoss(stageId)
    return self._Model:IsStageFinalBoss(stageId)
end

--- 获取塔层关卡BOSS关玩家插件
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageBossPlugIds(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.BossPlugIds or {}
end

--- 获取塔层关卡boss词缀
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageBossAffixEvent(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.BossAffixEvent or {}
end

--- 获取塔层关卡boss关战斗时长
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageBossFightTime(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.BossFightTime or 0
end

--- 获取塔层关卡BOSS积分星级要求
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageBossFightScore(stageId)
    return self._Model:GetStageBossFightScore(stageId)
end

--- 获取塔层关卡词缀关最大点数
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageMaxPlugPoint(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.MaxPlugPoint or 0
end

--- 获取塔层关卡怪物立绘
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageBossIcon(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.BossIcon or ""
end

--- 获取塔层关卡怪物头像图标
---@param stageId number 塔层关卡ID
function XScoreTowerControl:GetStageBossHeadIcon(stageId)
    local config = self._Model:GetStageConfig(stageId)
    return config and config.BossHeadIcon or ""
end

--- 获取关卡战斗事件名称
---@param fightEventId number 战斗事件Id
function XScoreTowerControl:GetFightEventName(fightEventId)
    ---@type XTableStageFightEventDetails
    local config = XMVCA.XFuben:GetStageFightEventDetailsByStageFightEventId(fightEventId)
    return config and config.Name or ""
end

--- 获取关卡战斗事件描述
---@param fightEventId number 战斗事件Id
function XScoreTowerControl:GetFightEventDesc(fightEventId)
    ---@type XTableStageFightEventDetails
    local config = XMVCA.XFuben:GetStageFightEventDetailsByStageFightEventId(fightEventId)
    return config and config.Description or ""
end

--- 获取关卡战斗事件图标
---@param fightEventId number 战斗事件Id
function XScoreTowerControl:GetFightEventIcon(fightEventId)
    ---@type XTableStageFightEventDetails
    local config = XMVCA.XFuben:GetStageFightEventDetailsByStageFightEventId(fightEventId)
    return config and config.Icon or ""
end

--- 获取塔层关卡当前插件点数
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param cfgId number ScoreTowerStage表Id
function XScoreTowerControl:GetStageTotalPlugPoint(chapterId, towerId, cfgId)
    local stageData = self._Model:GetStageData(chapterId, towerId, cfgId)
    if not stageData then
        return 0
    end
    return stageData:GetPlugInPoint() or 0
end

--- 获取塔层关卡当前星级
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param cfgId number ScoreTowerStage表Id
---@return number 当前星级
function XScoreTowerControl:GetStageCurStar(chapterId, towerId, cfgId)
    local stageData = self._Model:GetStageData(chapterId, towerId, cfgId)
    if not stageData then
        return 0
    end
    return stageData:GetCurStar() or 0
end

--- 获取塔层关卡总星级
---@param stageId number 塔层关卡ID
---@return number 总星级
function XScoreTowerControl:GetStageTotalStar(stageId)
    return self._Model:GetStageTotalStar(stageId)
end

--- 获取塔层关卡积分描述
---@param stageId number 塔层关卡ID
---@param index number 积分索引
---@param addFightTime number 增加的战斗时长
---@param reduceScore number 减少的分数
---@param key string 配置Key
function XScoreTowerControl:GetStageBossScoreDesc(stageId, index, addFightTime, reduceScore, key)
    local bossScores = self:GetStageBossFightScore(stageId)
    local baseScore = bossScores[index] or 0
    local curScore = math.max(baseScore - (index == 1 and reduceScore or 0), 0)

    local baseFightTime = self:GetStageBossFightTime(stageId)
    local curFightTime = baseFightTime + addFightTime

    local timeColor = self:GetStageBossTargetOrStarColor(curFightTime, baseFightTime, "StageDetailDescColor")
    local scoreColor = self:GetStageBossTargetOrStarColor(curScore, baseScore, "StageDetailDescColor")

    return self:GetStageBossTargetOrStarDesc(timeColor, curFightTime, scoreColor, curScore, key)
end

--- 获取塔层关卡通关描述
---@param stageId number 塔层关卡ID
---@param index number 积分索引
---@param reduceScore number 减少的分数
function XScoreTowerControl:GetStageBossPassDesc(stageId, index, reduceScore)
    local bossScores = self:GetStageBossFightScore(stageId)
    local baseScore = bossScores[index] or 0
    local curScore = math.max(baseScore - (index == 1 and reduceScore or 0), 0)

    local scoreColor = self:GetStageBossTargetOrStarColor(curScore, baseScore, "StagePassDescColor")
    return XUiHelper.FormatText(self:GetClientConfig("StageBossPassDesc"), scoreColor, curScore)
end

--- 获取塔层boss关卡分数的颜色
function XScoreTowerControl:GetStageBossTargetOrStarColor(curValue, baseValue, key)
    if not XTool.IsNumberValid(baseValue) then
        return self:GetClientConfig(key)
    end
    local colorIndex = 1
    if curValue > baseValue then
        colorIndex = 2
    elseif curValue < baseValue then
        colorIndex = 3
    end
    return self:GetClientConfig(key, colorIndex)
end

--- 获取塔层boss关卡目标或者星级描述
---@param key string 配置Key
function XScoreTowerControl:GetStageBossTargetOrStarDesc(timeColor, time, scoreColor, score, key)
    return XUiHelper.FormatText(self:GetClientConfig(key), timeColor, time, scoreColor, score)
end

--- 获取塔层关卡显示的角色信息列表
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param floorId number 塔层Id
---@param cfgId number ScoreTowerStage表的Id
---@param stageTeam XScoreTowerStageTeam 关卡队伍数据
---@return { Id:number, Pos:number, IsUsed:boolean, IsNow:boolean, StageId:number }[]
function XScoreTowerControl:GetStageShowCharacterInfoList(chapterId, towerId, floorId, cfgId, stageTeam)
    local showCharacterInfos = self._Model:GetStageShowCharacterInfoList(chapterId, towerId, floorId, cfgId)
    return self:GetStageCharacterFilterSort(showCharacterInfos, cfgId, stageTeam)
end

--- 获取塔层关卡选择的插件索引列表
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param cfgId number ScoreTowerStage表Id
function XScoreTowerControl:GetStageSelectedPlugIndex(chapterId, towerId, cfgId)
    local stageData = self._Model:GetStageData(chapterId, towerId, cfgId)
    if not stageData then
        return {}
    end
    return stageData:GetSelectedPlugIndex() or {}
end

-- 获取塔层关卡选择的插件Id列表
---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param cfgId number ScoreTowerStage表Id
function XScoreTowerControl:GetStageSelectedPlugIds(chapterId, towerId, cfgId)
    local plugIds = self:GetStageBossPlugIds(cfgId)
    local selectedIndexList = self:GetStageSelectedPlugIndex(chapterId, towerId, cfgId)
    local selectedPlugIds = {}
    for _, index in ipairs(selectedIndexList) do
        local plugId = plugIds[index]
        if XTool.IsNumberValid(plugId) then
            table.insert(selectedPlugIds, plugId)
        end
    end
    return selectedPlugIds
end

-- 根据插件Id列表获取插件索引列表
---@param selectedPlugIds number[] 插件Id列表
---@param plugIds number[] 插件Id列表
---@return number[] 插件索引列表
function XScoreTowerControl:GetPlugIndexByPlugIds(selectedPlugIds, plugIds)
    if XTool.IsTableEmpty(selectedPlugIds) then
        return {}
    end
    local selectedPlugSet = {}
    for _, id in ipairs(selectedPlugIds) do
        selectedPlugSet[id] = true
    end
    local selectedIndexList = {}
    for index, id in ipairs(plugIds) do
        if selectedPlugSet[id] then
            table.insert(selectedIndexList, index)
        end
    end
    table.sort(selectedIndexList)
    return selectedIndexList
end

--- 获取最终boss的关卡Id
---@param towerId number 塔Id
---@return number 关卡Id ScoreTowerStage表的Id
function XScoreTowerControl:GetFinalBossStageIdByTowerId(towerId)
    return self._Model:GetFinalBossStageIdByTowerId(towerId)
end

--- 获取关卡推荐TagId列表
---@param cfgId number ScoreTowerStage表Id
function XScoreTowerControl:GetStageSuggestTagIds(cfgId)
    if not XTool.IsNumberValid(cfgId) then
        return {}
    end
    local plugPointIds = self:GetStagePlugPointIds(cfgId)
    local suggestTagIds = {}
    local tagMap = {}
    for _, pointId in pairs(plugPointIds) do
        local pointType = self:GetPlugPointType(pointId)
        local pointParams = self:GetPlugPointParams(pointId)
        if pointType == XEnumConst.ScoreTower.PointType.Tag then
            for _, tagId in ipairs(pointParams) do
                if not string.IsNilOrEmpty(tagId) and string.IsNumeric(tagId) then
                    -- 去重检查
                    if not tagMap[tagId] then
                        tagMap[tagId] = true
                        table.insert(suggestTagIds, tonumber(tagId))
                    end
                end
            end
        elseif pointType == XEnumConst.ScoreTower.PointType.TagCompose then
            for _, tagFormula in ipairs(pointParams) do
                if not string.IsNilOrEmpty(tagFormula) then
                    local result = string.Split(tagFormula, '|')
                    if not string.IsNilOrEmpty(result[2]) and string.IsNumeric(result[2]) then
                        -- 去重检查
                        if not tagMap[result[2]] then
                            tagMap[result[2]] = true
                            table.insert(suggestTagIds, tonumber(result[2]))
                        end
                    end
                end
            end
        end
    end
    return suggestTagIds
end

--- 获取塔层关卡是否通关
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param cfgId number ScoreTowerStage表Id
function XScoreTowerControl:IsStagePass(chapterId, towerId, cfgId)
    return self._Model:IsStagePass(chapterId, towerId, cfgId)
end

--- 获取塔层普通关卡是否全部通关
---@param chapterId number 章节Id
---@param towerId number 塔Id
---@param floorId number 塔层Id
function XScoreTowerControl:IsNormalStageAllPass(chapterId, towerId, floorId)
    local stageIds = self:GetFloorStageIdsByStageType(floorId, XEnumConst.ScoreTower.StageType.Normal)
    if XTool.IsTableEmpty(stageIds) then
        return true
    end
    for _, stageId in pairs(stageIds) do
        if not self:IsStagePass(chapterId, towerId, stageId) then
            return false
        end
    end
    return true
end

--- 检查是否是关卡推荐Tag
---@param cfgId number ScoreTowerStage表Id
---@param entityId number 实体ID
function XScoreTowerControl:IsStageSuggestTag(cfgId, entityId)
    if not XTool.IsNumberValid(cfgId) or not XTool.IsNumberValid(entityId) then
        return false
    end
    return self._Model:IsStageSuggestTag(cfgId, entityId)
end

--endregion

--region 塔层关卡插件点数相关

--- 获取插件点数的类型
---@param plugPointId number 插件点数ID
function XScoreTowerControl:GetPlugPointType(plugPointId)
    return self._Model:GetPlugPointType(plugPointId)
end

--- 获取插件点数的参数
---@param plugPointId number 插件点数ID
function XScoreTowerControl:GetPlugPointParams(plugPointId)
    return self._Model:GetPlugPointParams(plugPointId)
end

--- 获取插件点数的点数
---@param plugPointId number 插件点数ID
function XScoreTowerControl:GetPlugPointPoint(plugPointId)
    local config = self._Model:GetPlugPointConfig(plugPointId)
    return config and config.Point or 0
end

--- 获取插件点数的描述
---@param plugPointId number 插件点数ID
function XScoreTowerControl:GetPlugPointDesc(plugPointId)
    local config = self._Model:GetPlugPointConfig(plugPointId)
    return config and config.Desc or ""
end

--endregion

--region 塔层关卡插件相关

--- 获取插件的类型
---@param plugId number 插件ID
function XScoreTowerControl:GetPlugType(plugId)
    local config = self._Model:GetPlugConfig(plugId)
    return config and config.Type or 0
end

--- 获取插件的参数
---@param plugId number 插件ID
function XScoreTowerControl:GetPlugParams(plugId)
    local config = self._Model:GetPlugConfig(plugId)
    return config and config.Params or {}
end

--- 获取插件需要的点数
---@param plugId number 插件ID
function XScoreTowerControl:GetPlugNeedPoint(plugId)
    local config = self._Model:GetPlugConfig(plugId)
    return config and config.NeedPoint or 0
end

--- 获取插件的描述
---@param plugId number 插件ID
function XScoreTowerControl:GetPlugDesc(plugId)
    local config = self._Model:GetPlugConfig(plugId)
    return config and config.Desc or ""
end

--- 获取插件的名称
---@param plugId number 插件ID
function XScoreTowerControl:GetPlugName(plugId)
    local config = self._Model:GetPlugConfig(plugId)
    return config and config.Name or ""
end

--- 获取插件的图标
---@param plugId number 插件ID
function XScoreTowerControl:GetPlugIcon(plugId)
    local config = self._Model:GetPlugConfig(plugId)
    return config and config.PlugImg or ""
end

--- 获取插件的视频
---@param plugId number 插件ID
function XScoreTowerControl:GetPlugVideo(plugId)
    local config = self._Model:GetPlugConfig(plugId)
    return config and config.PlugVideo or ""
end

--- 获取插件需要的点数总数
---@param pluginIds number[] 插件ID列表
function XScoreTowerControl:GetPlugTotalNeedPoint(pluginIds)
    local totalNeedPoint = 0
    for _, pluginId in pairs(pluginIds) do
        totalNeedPoint = totalNeedPoint + self:GetPlugNeedPoint(pluginId)
    end
    return totalNeedPoint
end

--- 获取插件的效果添加的战斗时间和降低的分数
---@param pluginIds number[] 插件ID列表
function XScoreTowerControl:GetPlugEffectAddFightTimeAndReduceScore(pluginIds)
    local addFightTime, reduceScore = 0, 0
    for _, pluginId in pairs(pluginIds) do
        local type, params = self:GetPlugType(pluginId), self:GetPlugParams(pluginId)
        if type == XEnumConst.ScoreTower.PlugType.AddFightTime then
            addFightTime = addFightTime + (params[1] or 0)
        elseif type == XEnumConst.ScoreTower.PlugType.SetScore then
            reduceScore = reduceScore + (params[1] or 0)
        end
    end
    return addFightTime, reduceScore
end

--- 获取插件的效果移除的词缀Id列表
---@param pluginIds number[] 插件ID列表
function XScoreTowerControl:GetPlugEffectRemoveAffixIds(pluginIds)
    local affixIds = {}
    for _, pluginId in pairs(pluginIds) do
        local type, params = self:GetPlugType(pluginId), self:GetPlugParams(pluginId)
        if type == XEnumConst.ScoreTower.PlugType.RemoveBuff then
            for _, affixId in pairs(params) do
                if XTool.IsNumberValid(affixId) then
                    table.insert(affixIds, affixId)
                end
            end
        end
    end
    return affixIds
end

--endregion

--region 角色标签相关

--- 获取角色标签列表
---@param characterId number 角色ID
function XScoreTowerControl:GetCharacterTagList(characterId)
    return self._Model:GetCharacterTagList(characterId)
end

--- 获取标签图标
---@param tagId number 标签ID
function XScoreTowerControl:GetTagIcon(tagId)
    local config = self._Model:GetTagConfig(tagId)
    return config and config.Icon or ""
end

--- 获取标签描述
---@param tagId number 标签ID
function XScoreTowerControl:GetTagDesc(tagId)
    local config = self._Model:GetTagConfig(tagId)
    return config and config.Desc or ""
end

--- 获取角色标签图标
---@param characterId number 角色ID
---@param index number 标签索引 1 元素 2 效应 3 职业
function XScoreTowerControl:GetCharacterTagIcon(characterId, index)
    local tagList = self:GetCharacterTagList(characterId)
    local tagId = tagList[index] or 0
    if tagId <= 0 then
        return ""
    end
    return self:GetTagIcon(tagId)
end

--- 获取角色标签描述
---@param characterId number 角色ID
---@param index number 标签索引 1 元素 2 效应 3 职业
function XScoreTowerControl:GetCharacterTagDesc(characterId, index)
    local tagList = self:GetCharacterTagList(characterId)
    local tagId = tagList[index] or 0
    if tagId <= 0 then
        return ""
    end
    return self:GetTagDesc(tagId)
end

--endregion

--region 强化相关

--- 获取所属章节Ids
function XScoreTowerControl:GetAllBelongChapterIds()
    local chapterIds = self._Model:GetAllBelongChapterIds()
    table.sort(chapterIds, function(a, b)
        return a < b
    end)
    return chapterIds
end

--- 获取强化Id列表
---@param chapterId number 章节ID
function XScoreTowerControl:GetStrengthenIdsByChapterId(chapterId)
    return self._Model:GetStrengthenIdsByChapterId(chapterId)
end

--- 获取强化Buff等级
---@param strengthenId number 强化ID
function XScoreTowerControl:GetStrengthenBuffLvs(strengthenId)
    local config = self._Model:GetStrengthenConfig(strengthenId)
    return config and config.BuffLv or {}
end

--- 获取强化Buff等级概率
---@param strengthenId number 强化ID
function XScoreTowerControl:GetStrengthenBuffLvRates(strengthenId)
    local config = self._Model:GetStrengthenConfig(strengthenId)
    return config and config.BuffLvRate or {}
end

--- 获取强化Buff等级消耗
---@param strengthenId number 强化ID
function XScoreTowerControl:GetStrengthenBuffLvCosts(strengthenId)
    local config = self._Model:GetStrengthenConfig(strengthenId)
    return config and config.BuffLvCost or {}
end

--- 获取强化Buff当前等级FightEventId
---@param strengthenId number 强化ID
---@param curLv number 当前等级
function XScoreTowerControl:GetStrengthenBuffFightEventId(strengthenId, curLv)
    local buffLvs = self:GetStrengthenBuffLvs(strengthenId)
    curLv = math.max(curLv, 1)
    return buffLvs[curLv] or 0
end

--- 获取强化Buff强化到下一级概率(万分比)
---@param strengthenId number 强化ID
---@param curLv number 当前等级
function XScoreTowerControl:GetStrengthenBuffNextLvRate(strengthenId, curLv)
    local buffLvRates = self:GetStrengthenBuffLvRates(strengthenId)
    local nextLvRate = buffLvRates[curLv + 1] or "0"
    local rates = string.Split(nextLvRate, "|")
    local failCount = self:GetStrengthenBuffFailCount(strengthenId)
    return tonumber(rates[math.min(failCount + 1, #rates)]) or 0
end

--- 获取强化Buff强化到下一级消耗
---@param strengthenId number 强化ID
---@param curLv number 当前等级
function XScoreTowerControl:GetStrengthenBuffNextLvCost(strengthenId, curLv)
    local buffLvCost = self:GetStrengthenBuffLvCosts(strengthenId)
    return buffLvCost[curLv + 1] or 0
end

--- 获取强化Buff当前等级
---@param strengthenId number 强化ID
function XScoreTowerControl:GetStrengthenBuffCurLv(strengthenId)
    local strengthenData = self._Model:GetStrengthenData(strengthenId)
    if not strengthenData then
        return 0
    end
    return strengthenData:GetLv() or 0
end

--- 获取强化Buff指定等级的战力提升量
---@param strengthenId number 强化ID
---@param level number 等级
function XScoreTowerControl:GetStrengthenBuffPower(strengthenId, level)
    local buffPowers = self._Model:GetStrengthenBuffPowers(strengthenId)
    return buffPowers[level] or 0
end

--- 获取强化Buff当前强化失败次数
---@param strengthenId number 强化ID
function XScoreTowerControl:GetStrengthenBuffFailCount(strengthenId)
    local strengthenData = self._Model:GetStrengthenData(strengthenId)
    if not strengthenData then
        return 0
    end
    return strengthenData:GetStrengthenFailCount() or 0
end

--- 获取强化Buff是否满级
---@param strengthenId number 强化ID
---@param curLv number 当前等级
function XScoreTowerControl:IsStrengthenBuffMaxLv(strengthenId, curLv)
    local buffLv = self:GetStrengthenBuffLvs(strengthenId)
    return curLv >= #buffLv
end

--- 检测强化是否解锁
---@return boolean, string 是否解锁, 描述
function XScoreTowerControl:IsStrengthenUnlock()
    local allChapterIds = self:GetAllBelongChapterIds()
    for _, chapterId in pairs(allChapterIds) do
        if self:IsChapterPass(chapterId) then
            return true, ""
        end
    end
    local chapterId = allChapterIds[1] or 0
    local desc = self:GetClientConfig("StrengthenChapterUnlockDesc")
    return false, XUiHelper.FormatText(desc, self:GetChapterName(chapterId))
end

--- 检测强化Buff是否可以强化
---@param strengthenId number 强化ID
function XScoreTowerControl:CheckStrengthenBuffCanStrengthen(strengthenId)
    -- 检查是否满级
    local curLv = self:GetStrengthenBuffCurLv(strengthenId)
    if self:IsStrengthenBuffMaxLv(strengthenId, curLv) then
        return false
    end
    -- 强化消耗是否满足
    local cost = self:GetStrengthenBuffNextLvCost(strengthenId, curLv)
    local coinId = XDataCenter.ItemManager.ItemId.ScoreTowerCoin
    return XDataCenter.ItemManager.CheckItemCountById(coinId, cost)
end

--endregion

--region 任务相关

--- 获取任务组Id列表
function XScoreTowerControl:GetAllTaskGroupIdList()
    return self._Model:GetTaskGroupIdList()
end

--- 获取任务组名称
---@param taskGroupId number 任务组ID
function XScoreTowerControl:GetTaskGroupName(taskGroupId)
    local config = self._Model:GetTaskConfig(taskGroupId)
    return config and config.Name or ""
end

--- 获取任务信息列表
---@param taskGroupId number 任务组ID
function XScoreTowerControl:GetTaskDataListByGroupId(taskGroupId)
    local taskIds = self._Model:GetTaskIdsByGroupId(taskGroupId)
    return XDataCenter.TaskManager.GetTaskIdListData(taskIds)
end

--- 检查是否有可领取的任务奖励
---@param taskGroupId number 任务组ID
function XScoreTowerControl:CheckHasCanReceiveTaskReward(taskGroupId)
    return self._Model:CheckHasCanReceiveTaskReward(taskGroupId)
end

--endregion

--region 客户端配置相关

--- 获取客户端配置
function XScoreTowerControl:GetClientConfig(key, index, isNumber)
    local value = self._Model:GetClientConfig(key, XTool.IsNumberValid(index) and index or 1)
    return isNumber and tonumber(value) or value
end

--endregion

--region 红点相关

--- 检查当前章节是否显示红点
---@param chapterId number 章节ID
function XScoreTowerControl:CheckChapterRedPoint(chapterId)
    return self._Model:CheckChapterRedPoint(chapterId)
end

--- 强化按钮是否显示红点
function XScoreTowerControl:IsShowStrengthenRedPoint()
    local allChapterIds = self:GetAllBelongChapterIds()
    for _, chapterId in pairs(allChapterIds) do
        if self:IsChapterPass(chapterId) then
            local strengthenIds = self:GetStrengthenIdsByChapterId(chapterId)
            for _, strengthenId in pairs(strengthenIds) do
                if self:CheckStrengthenBuffCanStrengthen(strengthenId) then
                    return true
                end
            end
        end
    end
    return false
end

--- 任务按钮是否显示红点
function XScoreTowerControl:IsShowTaskRedPoint()
    return self._Model:IsShowTaskRedPoint()
end

--- 排行榜按钮是否显示红点
function XScoreTowerControl:IsShowRankRedPoint()
    return self._Model:IsShowRankRedPoint()
end

--endregion

--region 角色排序相关

--- 获取塔角色筛选排序
---@param relatedChars table 相关角色
---@param towerId number 塔ID
---@param towerTeam XScoreTowerTowerTeam 塔队伍数据
function XScoreTowerControl:GetTowerCharacterFilterSort(relatedChars, towerId, towerTeam)
    return self:GetCharacterFilterSort(relatedChars, towerId, towerTeam, "UiScoreTowerTowerBattleRoomRoleDetail",
        self._Model.GetTowerCharacterFilterSort)
end

--- 获取关卡角色筛选排序
---@param relatedChars table 相关角色
---@param stageCfgId number 关卡配置ID ScoreTowerStage表的ID
---@param stageTeam XScoreTowerStageTeam 关卡队伍数据
function XScoreTowerControl:GetStageCharacterFilterSort(relatedChars, stageCfgId, stageTeam)
    return self:GetCharacterFilterSort(relatedChars, stageCfgId, stageTeam, "UiScoreTowerStageBattleRoomRoleDetail",
        self._Model.GetStageCharacterFilterSort)
end

--- 获取角色筛选排序
---@param relatedChars table 相关角色
---@param id number 塔ID或关卡配置ID
---@param team XTeam 塔队伍数据或关卡队伍数据
---@param filterKey string 筛选器配置表键
---@param filterFunc function 筛选器函数
function XScoreTowerControl:GetCharacterFilterSort(relatedChars, id, team, filterKey, filterFunc)
    local filterConfig = XMVCA.XCharacter:GetModelCharacterFilterController()[filterKey]
    local sortFunList = filterConfig and filterConfig.SortTagList or nil
    -- 用筛选器配置表排序
    local sortRes = relatedChars
    if sortFunList then
        local overrideTable = filterFunc(self._Model, id)
        if overrideTable and team then
            overrideTable.CheckFunList[CharacterSortFunType.InTeam] = function(idA, idB)
                local inTeamA = team:GetEntityIdIsInTeam(idA)
                local inTeamB = team:GetEntityIdIsInTeam(idB)
                if inTeamA ~= inTeamB then
                    return true
                end
            end
            overrideTable.SortFunList[CharacterSortFunType.InTeam] = function(idA, idB)
                local inTeamA = team:GetEntityIdIsInTeam(idA)
                local inTeamB = team:GetEntityIdIsInTeam(idB)
                if inTeamA ~= inTeamB then
                    return inTeamA
                end
            end
        end
        sortRes = XMVCA.XCommonCharacterFilter:DoSortFilterV2P6(relatedChars, sortFunList, nil, overrideTable)
    end
    return sortRes
end

--endregion

--region 本地记录相关

--- 记录章节的点击
---@param chapterId number 章节ID
function XScoreTowerControl:RecordChapterClick(chapterId)
    if not self._Model:GetChapterClickCache(chapterId) then
        self._Model:SaveChapterClickCache(chapterId)
    end
end

--- 记录排行榜的点击
function XScoreTowerControl:RecordRankClick()
    if not self._Model:GetRankClickCache() then
        self._Model:SaveRankClickCache()
    end
end

--endregion

return XScoreTowerControl
