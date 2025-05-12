---@class XArenaControl : XControl
---@field private _Model XArenaModel
local XArenaControl = XClass(XControl, "XArenaControl")

function XArenaControl:OnInit()
    -- 初始化内部变量
    self._SelectBuffIndexMap = self:_LoadCurrentAreaSelectBuff()
end

function XArenaControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XArenaControl:RemoveAgencyEvent()

end

function XArenaControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
    self:_SaveCurrentAreaSelectBuff()
end

-- region OpenUi

function XArenaControl:CheckOpenActivityResultUi()
    ---@type XArenaAgency
    local agency = self:GetAgency()

    agency:CheckOpenActivityResultUi(true)
end

function XArenaControl:CheckOpenMainUi()
    if not XLuaUiManager.IsUiLoad("UiArenaNew") then
        ---@type XArenaAgency
        local agency = self:GetAgency()

        agency:ExOpenMainUi()
    end
end

function XArenaControl:CheckOpenNewActivityResultUi()
    local beforeChallengeId = self:GetActivityBeforeChallengeId()
    local beforeArenaLevel = self:GetActivityBeforeArenaLevel()
    local challengeId = self:GetActivityChallengeId()
    local arenaLevel = self:GetActivityCurrentLevel()

    if XTool.IsNumberValid(beforeArenaLevel) and XTool.IsNumberValid(beforeChallengeId) and beforeChallengeId
        ~= challengeId and beforeArenaLevel ~= arenaLevel then
        XLuaUiManager.Open("UiArenaNewActivityResult")

        return true
    end

    return false
end

-- endregion

-- region Data Getter/Setter

function XArenaControl:ClearActivityResultData()
    self._Model:ClearActivityResultData()
end

function XArenaControl:GetActivityStatus()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetStatus()
    end

    return XEnumConst.Arena.ActivityStatus.Default
end

function XArenaControl:GetActivityCurrentLevel()
    ---@type XArenaAgency
    local agency = self:GetAgency()

    return agency:GetActivityCurrentLevel()
end

function XArenaControl:GetActivityChallengeId()
    ---@type XArenaAgency
    local agency = self:GetAgency()

    return agency:GetActivityCurrentChallengeId()
end

function XArenaControl:GetActivityResultTime()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetResultTime()
    end

    return 0
end

function XArenaControl:GetActivityFightStartTime()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetFightTime()
    end

    return 0
end

function XArenaControl:GetActivityNextStatusTime()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetNextStatusTime()
    end

    return 0
end

function XArenaControl:GetActivityContributeScore()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetContributeScore()
    end

    return 0
end

function XArenaControl:GetActivityProtectedScore()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetProtectedScore()
    end

    return 0
end

function XArenaControl:GetActivityBeforeChallengeId()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetBeforeChallengeId()
    end

    return 0
end

function XArenaControl:GetActivityBeforeArenaLevel()
    if self._Model:CheckHasActivityData() then
        return self._Model:GetActivityData():GetBeforeArenaLevel()
    end

    return 0
end

function XArenaControl:ClearBeforeChallengeAndArenaId()
    if self._Model:CheckHasActivityData() then
        self._Model:GetActivityData():ClearBeforeChallengeAndArenaId()
    end
end

function XArenaControl:IsInActivityFightStatus()
    return self:GetActivityStatus() == XEnumConst.Arena.ActivityStatus.Fight
end

function XArenaControl:IsInActivityOverStatus()
    return self:GetActivityStatus() == XEnumConst.Arena.ActivityStatus.Over
end

function XArenaControl:SetAreaDataStagePoint(areaId, point)
    self._Model:SetAreaDataPointByAreaId(areaId, point)
end

-- endregion

-- region Check

function XArenaControl:CheckIsMaxArenaLevel(arenaLevel)
    return arenaLevel >= self:GetMaxArenaLevel()
end

function XArenaControl:CheckCanDownRank(challengeId)
    local downRank = self:GetChallengeDanDownRankByChallengeId(challengeId)

    return XTool.IsNumberValid(downRank)
end

function XArenaControl:CheckCanUpRank(challengeId)
    local upRank = self:GetChallengeDanUpRankByChallengeId(challengeId)

    return XTool.IsNumberValid(upRank)
end

function XArenaControl:CheckRunMainWhenFightOver()
    ---@type XArenaAgency
    local agency = self:GetAgency()

    return agency:CheckRunMainWhenFightOver()
end

-- endregion

-- region Const Getter

function XArenaControl:GetContributeScoreItemId()
    return self._Model:GetContributeScoreItemId()
end

function XArenaControl:GetArenaHeroLv()
    return self._Model:GetArenaHeroLv()
end

function XArenaControl:GetMaxContributeScore()
    return self._Model:GetMaxContributeScore()
end

function XArenaControl:GetProtectContributeScore()
    return self._Model:GetProtectContributeScore()
end

function XArenaControl:GetAreaMaxProtectScore()
    return self._Model:GetAreaMaxProtectScore()
end

-- endregion

-- region Config Getter

function XArenaControl:GetArenaLevelNameById(id)
    return self._Model:GetArenaLevelNameById(id)
end

function XArenaControl:GetArenaLevelIconById(id)
    return self._Model:GetArenaLevelIconById(id)
end

function XArenaControl:GetArenaLevelWordIconById(id)
    return self._Model:GetArenaLevelWordIconById(id)
end

function XArenaControl:GetChallengeArenaLvById(challengeId)
    return self._Model:GetChallengeAreaArenaLvByChallengeId(challengeId)
end

function XArenaControl:GetChallengeDanUpRankCostContributeScoreById(challengeId)
    return self._Model:GetChallengeAreaDanUpRankCostContributeScoreByChallengeId(challengeId)
end

function XArenaControl:GetChallengeContributeScoreById(challengeId)
    return self._Model:GetChallengeAreaContributeScoreByChallengeId(challengeId)
end

function XArenaControl:GetChallengeContributeScoreByIdAndIndex(challengeId, index)
    local contributeScore = self:GetChallengeContributeScoreById(challengeId)

    if XTool.IsTableEmpty(contributeScore) then
        return 0
    end

    return contributeScore[index] or 0
end

function XArenaControl:GetChallengeDanUpRankByChallengeId(challengeId)
    return self._Model:GetChallengeAreaDanUpRankByChallengeId(challengeId)
end

function XArenaControl:GetChallengeDanKeepRankByChallengeId(challengeId)
    return self._Model:GetChallengeAreaDanKeepRankByChallengeId(challengeId)
end

function XArenaControl:GetChallengeDanDownRankByChallengeId(challengeId)
    return self._Model:GetChallengeAreaDanDownRankByChallengeId(challengeId)
end

function XArenaControl:GetChallengeArenaIdGroupByChallengeId(challengeId)
    return self._Model:GetChallengeAreaAreaIdGroupByChallengeId(challengeId)
end

function XArenaControl:GetChallengeUpRewardIdByChallengeId(challengeId)
    return self._Model:GetChallengeAreaUpRewardIdByChallengeId(challengeId)
end

function XArenaControl:GetChallengeDownRewardIdByChallengeId(challengeId)
    return self._Model:GetChallengeAreaDownRewardIdByChallengeId(challengeId)
end

function XArenaControl:GetChallengeKeepRewardIdByChallengeId(challengeId)
    return self._Model:GetChallengeAreaKeepRewardIdByChallengeId(challengeId)
end

function XArenaControl:GetChallengeMaxLvByChallengeId(challengeId)
    return self._Model:GetChallengeAreaMaxLvByChallengeId(challengeId)
end

function XArenaControl:GetChallengeMinLvByChallengeId(challengeId)
    return self._Model:GetChallengeAreaMinLvByChallengeId(challengeId)
end

function XArenaControl:GetChallengeNameByChallengeId(challengeId)
    return self._Model:GetChallengeAreaNameByChallengeId(challengeId)
end

function XArenaControl:GetAreaStageRegionById(arenaId)
    return self._Model:GetAreaStageRegionById(arenaId)
end

function XArenaControl:GetAreaStageLastStageIdById(arenaId)
    local stageIds = self._Model:GetAreaStageStageIdById(arenaId)

    if XTool.IsTableEmpty(stageIds) then
        return 0
    end

    return stageIds[#stageIds]
end

function XArenaControl:GetArenaStageNameByStageId(stageId)
    return self._Model:GetArenaStageNameByStageId(stageId)
end

function XArenaControl:GetArenaStageIconByStageId(stageId)
    return self._Model:GetArenaStageBgIconBigByStageId(stageId)
end

function XArenaControl:GetAreaStageNameByAreaId(areaId)
    return self._Model:GetAreaStageNameById(areaId) or ""
end

function XArenaControl:GetAreaStageBuffNameByAreaIdAndIndex(areaId, index)
    return self:GetAreaStageBuffNameListByAreaId(areaId)[index]
end

function XArenaControl:GetAreaStageBuffNameListByAreaId(areaId)
    return self._Model:GetAreaStageBuffNameById(areaId) or {}
end

function XArenaControl:GetAreaStageBuffDescByAreaIdAndIndex(areaId, index)
    return self:GetAreaStageBuffDescListByAreaId(areaId)[index]
end

function XArenaControl:GetAreaStageBuffDescListByAreaId(areaId)
    return self._Model:GetAreaStageBuffDescById(areaId) or {}
end

function XArenaControl:GetAreaStageDescByAreaId(areaId)
    return self._Model:GetAreaStageDescById(areaId)
end

function XArenaControl:GetBuffDetailsIconById(buffId)
    return self._Model:GetArenaAreaBuffDetailsIconById(buffId)
end

function XArenaControl:GetBuffDetailsDescById(buffId)
    return self._Model:GetArenaAreaBuffDetailsDescById(buffId)
end

function XArenaControl:GetBuffDetailsNameById(buffId)
    return self._Model:GetArenaAreaBuffDetailsNameById(buffId)
end

function XArenaControl:GetMarkMaxEnemyHpPointByMarkId(markId)
    if not XTool.IsNumberValid(markId) then
        return 0
    end

    return self._Model:GetMarkMaxEnemyHpPointByMarkId(markId) or 0
end

function XArenaControl:GetMarkMaxMyHpPointByMarkId(markId)
    if not XTool.IsNumberValid(markId) then
        return 0
    end

    return self._Model:GetMarkMaxMyHpPointByMarkId(markId) or 0
end

function XArenaControl:GetMarkMaxTimePointByMarkId(markId)
    if not XTool.IsNumberValid(markId) then
        return 0
    end

    return self._Model:GetMarkMaxTimePointByMarkId(markId) or 0
end

function XArenaControl:GetMarkMaxNpcGroupPointByMarkId(markId)
    if not XTool.IsNumberValid(markId) then
        return 0
    end

    return self._Model:GetMarkMaxNpcGroupPointByMarkId(markId) or 0
end

function XArenaControl:GetMarkMaxPointByMarkId(markId)
    if not XTool.IsNumberValid(markId) then
        return 0
    end

    return self._Model:GetMarkMaxPointByMarkId(markId) or 0
end

function XArenaControl:GetFightEventsByGroupId(id)
    return self._Model:GetArenaGroupFightEventsById(id)
end

-- endregion

-- region Other

function XArenaControl:GetRankStatisticalTimeStr(beginTime, endTime)
    if not XTool.IsNumberValid(beginTime) or not XTool.IsNumberValid(endTime) then
        return ""
    end

    local beginTimeStr = XTime.TimestampToGameDateTimeString(beginTime, "yy.MM.dd")
    local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, "yy.MM.dd")

    return XUiHelper.GetText("ArenaRankStatisticalTime", beginTimeStr, endTimeStr)
end

function XArenaControl:GetChallengeLevelStrByChallengeId(challengeId)
    local maxLevel = self:GetChallengeMaxLvByChallengeId(challengeId)
    local minLevel = self:GetChallengeMinLvByChallengeId(challengeId)

    return XUiHelper.GetText("ArenaPlayerLevelRange", minLevel, maxLevel)
end

function XArenaControl:GetChallengeLevelNotDescStrByChallengeId(challengeId)
    local maxLevel = self:GetChallengeMaxLvByChallengeId(challengeId)
    local minLevel = self:GetChallengeMinLvByChallengeId(challengeId)

    return XUiHelper.GetText("ArenaPlayerLevelRangeNotDesc", minLevel, maxLevel)
end

function XArenaControl:GetCurrentChallengeLevelStr()
    local challengeId = self:GetActivityChallengeId()

    return self:GetChallengeLevelStrByChallengeId(challengeId)
end

function XArenaControl:GetCurrentChallengeLevelNotDescStr()
    local challengeId = self:GetActivityChallengeId()

    return self:GetChallengeLevelNotDescStrByChallengeId(challengeId)
end

function XArenaControl:GetActivityResultTimeStr()
    return self:_GetGameDateTimeStr(self:GetActivityResultTime())
end

function XArenaControl:GetActivityFightStartTimeStr()
    return self:_GetGameDateTimeStr(self:GetActivityFightStartTime())
end

-- 获取个人排行区文字
function XArenaControl:GetRankRegionText(regionType)
    if regionType == XEnumConst.Arena.RegionType.Up then
        return XUiHelper.GetText("ArenaActivityUpRegion")
    elseif regionType == XEnumConst.Arena.RegionType.Down then
        return XUiHelper.GetText("ArenaActivityDownRegion")
    else
        return XUiHelper.GetText("ArenaActivityKeepRegion")
    end
end

-- 获取个人排行区文字带颜色
function XArenaControl:GetRankRegionColorText(regionType)
    if regionType == XEnumConst.Arena.RegionType.Up then
        return XUiHelper.GetText("ArenaActivityUpRegionColor")
    elseif regionType == XEnumConst.Arena.RegionType.Down then
        return XUiHelper.GetText("ArenaActivityDownRegionColor")
    else
        return XUiHelper.GetText("ArenaActivityKeepRegionColor")
    end
end

-- 获取个人排行区描述
function XArenaControl:GetRankRegionDescText(regionType, challengeId)
    if regionType == XEnumConst.Arena.RegionType.Up then
        local upRank = self:GetChallengeDanUpRankByChallengeId(challengeId)

        return XUiHelper.GetText("ArenaActivityRegionDesc", 1, upRank)
    elseif regionType == XEnumConst.Arena.RegionType.Down then
        local keepRank = self:GetChallengeDanKeepRankByChallengeId(challengeId)
        local downRank = self:GetChallengeDanDownRankByChallengeId(challengeId)

        return XUiHelper.GetText("ArenaActivityRegionDesc", keepRank + 1, downRank)
    else
        local upRank = self:GetChallengeDanUpRankByChallengeId(challengeId)
        local keepRank = self:GetChallengeDanKeepRankByChallengeId(challengeId)

        return XUiHelper.GetText("ArenaActivityRegionDesc", upRank + 1, keepRank)
    end
end

-- 获取个人排行不升段位描述
function XArenaControl:GetRankNotRegionDescText(regionType)
    if regionType == XEnumConst.Arena.RegionType.Up then
        return XUiHelper.GetText("ArenaActivityNotUpRegionDesc")
    elseif regionType == XEnumConst.Arena.RegionType.Down then
        return XUiHelper.GetText("ArenaActivityNotDownRegionDesc")
    else
        return XUiHelper.GetText("ArenaActivityNotKeepRegionDesc")
    end
end

-- 获取个人排行区奖励id
function XArenaControl:GetRankRegionRewardId(regionType, challengeId)
    if regionType == XEnumConst.Arena.RegionType.Up then
        return self:GetChallengeUpRewardIdByChallengeId(challengeId)
    elseif regionType == XEnumConst.Arena.RegionType.Down then
        return self:GetChallengeDownRewardIdByChallengeId(challengeId)
    else
        return self:GetChallengeKeepRewardIdByChallengeId(challengeId)
    end
end

function XArenaControl:GetCurrentChallengeRewardIdByRegionType(regionType)
    local challengeId = self:GetActivityChallengeId()

    if regionType == XEnumConst.Arena.RegionType.Up then
        return self:GetChallengeUpRewardIdByChallengeId(challengeId)
    elseif regionType == XEnumConst.Arena.RegionType.Down then
        return self:GetChallengeDownRewardIdByChallengeId(challengeId)
    else
        return self:GetChallengeKeepRewardIdByChallengeId(challengeId)
    end
end

function XArenaControl:GetCurrentChallengeRewardByRegionType(regionType)
    local rewardId = self:GetCurrentChallengeRewardIdByRegionType(regionType)
    local rewards = XRewardManager.GetRewardList(rewardId)

    if not rewards or #rewards <= 0 then
        return nil
    end

    return rewards[1]
end

---@param groupData XArenaGroupDataBase
function XArenaControl:GetRankDataByGroupPlayerData(groupData)
    local challengeId = self:GetActivityChallengeId()
    local arenaLv = self:GetChallengeArenaLvById(challengeId)
    local danUpRankCost = self:GetChallengeDanUpRankCostContributeScoreById(challengeId)
    local danUpRank = self:GetChallengeDanUpRankByChallengeId(challengeId)
    local danKeepRank = self:GetChallengeDanKeepRankByChallengeId(challengeId)
    local danDownRank = self:GetChallengeDanDownRankByChallengeId(challengeId)
    -- 是否合并DanUpRank，DanKeepRank排名变为保级区
    local isMerge = arenaLv == self:GetArenaHeroLv() and danUpRankCost > 0
    local playerRankList = groupData:GetGroupPlayerList()
    local rankData = {}

    rankData[XEnumConst.Arena.RegionType.Up] = {}
    rankData[XEnumConst.Arena.RegionType.Keep] = {}
    rankData[XEnumConst.Arena.RegionType.Down] = {}
    for i, info in ipairs(playerRankList) do
        if info:GetPoint() > 0 then
            if (i - danUpRank <= 0) then
                rankData[XEnumConst.Arena.RegionType.Up][i] = info
            elseif (i - danKeepRank <= 0) then
                rankData[XEnumConst.Arena.RegionType.Keep][i] = info
            else
                rankData[XEnumConst.Arena.RegionType.Down][i] = info
            end
        else
            if danDownRank <= 0 then
                rankData[XEnumConst.Arena.RegionType.Keep][i] = info
            else
                rankData[XEnumConst.Arena.RegionType.Down][i] = info
            end
        end
    end

    if isMerge or danUpRank <= 0 then
        local upRankData = rankData[XEnumConst.Arena.RegionType.Up]

        rankData[XEnumConst.Arena.RegionType.Up] = nil
        for rank, playerData in pairs(upRankData) do
            rankData[XEnumConst.Arena.RegionType.Keep][rank] = playerData
        end
    end
    if danDownRank <= 0 then
        local downRankData = rankData[XEnumConst.Arena.RegionType.Down]

        rankData[XEnumConst.Arena.RegionType.Down] = nil
        for rank, playerData in pairs(downRankData) do
            rankData[XEnumConst.Arena.RegionType.Keep][rank] = playerData
        end
    end

    return rankData
end

---@param playerData XArenaGroupPlayerData
function XArenaControl:GetRegionTypeByPlayerDataAndRank(playerData, rank)
    local challengeId = self:GetActivityChallengeId()
    local danUpRank = self:GetChallengeDanUpRankByChallengeId(challengeId)
    local danKeepRank = self:GetChallengeDanKeepRankByChallengeId(challengeId)
    local arenaLv = self:GetChallengeArenaLvById(challengeId)

    if playerData:GetPoint() > 0 then
        if (rank - danUpRank <= 0) then
            return XEnumConst.Arena.RegionType.Up
        elseif (rank - danKeepRank <= 0) then
            return XEnumConst.Arena.RegionType.Keep
        else
            return XEnumConst.Arena.RegionType.Down
        end
    else
        if arenaLv <= 1 then
            return XEnumConst.Arena.RegionType.Keep
        else
            return XEnumConst.Arena.RegionType.Down
        end
    end

    return XEnumConst.Arena.RegionType.Keep
end

function XArenaControl:GetLocalPlayerRankByPlayerId(playerId)
    return self._Model:GetLocalPlayerRankByPlayerId(playerId)
end

function XArenaControl:GetMaxArenaLevel()
    return self._Model:GetMaxArenaLevel()
end

function XArenaControl:GetMaxChallengeId()
    return self._Model:GetMaxChallengeId()
end

function XArenaControl:GetPlayerLevelChallengeListById(challengeId)
    local result = {}
    local map = self._Model:GetPlayerLevelChallengeMapByChallengeId(challengeId)

    if map then
        for _, config in pairs(map) do
            table.insert(result, config)
        end

        table.sort(result, Handler(self, self._SortChallengeHandler))
    end

    return result
end

function XArenaControl:ChangeCurrentSelectBuffIndex(index)
    self._Model:SetCurrentSelectFightBuffIndex(index or 1)
end

function XArenaControl:RestoreSelectBuffIndex()
    self:ChangeCurrentSelectBuffIndex()
end

function XArenaControl:GetCurrentChallengeTaskList()
    ---@type XArenaAgency
    local agency = self:GetAgency()

    return agency:GetCurrentChallengeTasks()
end

function XArenaControl:GetCurrentEnterAreaId()
    return self._Model:GetCurrentEnterAreaId()
end

function XArenaControl:SetCurrentEnterAreaId(areaId)
    self._Model:SetCurrentEnterAreaId(areaId)
end

function XArenaControl:SetCurrentFightEventGroupId(groupId)
    self._Model:SetCurrentFightEventGroupId(groupId)
end

function XArenaControl:GetCurrentEnterAreaStageName()
    local areaId = self:GetCurrentEnterAreaId()

    if XTool.IsNumberValid(areaId) then
        local selectIndex = self._Model:GetCurrentSelectFightBuffIndex()
        local buffName = self:GetAreaStageBuffNameByAreaIdAndIndex(areaId, selectIndex)

        return buffName or ""
    end

    return ""
end

function XArenaControl:GetContributeScoreByChallengeId(groupRank, challengeId, point)
    local score = self:GetChallengeContributeScoreById(challengeId)

    if point > 0 then
        return score[groupRank] or 0
    else
        return 0
    end
end

function XArenaControl:GetMarkIdByAreaId(areaId)
    local stageId = self:GetAreaStageLastStageIdById(areaId)

    if XTool.IsNumberValid(stageId) then
        return self._Model:GetArenaStageMarkIdByStageId(stageId) or 0
    end

    return 0
end

function XArenaControl:IsMarkShowEnemyHp(markId)
    if XTool.IsNumberValid(markId) then
        return not string.IsNilOrEmpty(self._Model:GetMarkEnemyHpPointByMarkId(markId))
    end

    return false
end

function XArenaControl:IsMarkShowMyHp(markId)
    if XTool.IsNumberValid(markId) then
        return not string.IsNilOrEmpty(self._Model:GetMarkMyHpPointByMarkId(markId))
    end

    return false
end

function XArenaControl:IsMarkShowLeftTime(markId)
    if XTool.IsNumberValid(markId) then
        return not string.IsNilOrEmpty(self._Model:GetMarkTimePointByMarkId(markId))
    end

    return false
end

function XArenaControl:IsMarkShowGourp(markId)
    if XTool.IsNumberValid(markId) then
        return not string.IsNilOrEmpty(self._Model:GetMarkNpcGroupPointByMarkId(markId))
    end

    return false
end

function XArenaControl:IsHasMark(markId)
    if XTool.IsNumberValid(markId) then
        return not XTool.IsTableEmpty(self._Model:GetMarkConfigByMarkId(markId))
    end

    return false
end

function XArenaControl:GetIsRefreshMainPage()
    return self._Model:GetIsRefreshMainPage()
end

function XArenaControl:SetIsRefreshMainPage(value)
    ---@type XArenaAgency
    local agency = self:GetAgency()

    return agency:SetIsRefreshMainPage(value)
end

function XArenaControl:GetLocalSelectBuffIndex(areaId)
    return self._SelectBuffIndexMap[areaId] or 1
end

function XArenaControl:SetLocalSelectBuffIndex(areaId, index)
    self._SelectBuffIndexMap[areaId] = index
end

function XArenaControl:GetActivityRemainTimeStr()
    ---@type XArenaAgency
    local agency = self:GetAgency()

    return agency:GetActivityRemainTimeStr()
end

function XArenaControl:GetMedalIconByMedalId(medalId)
    local medalConfig = XMedalConfigs.GetMeadalConfigById(medalId)

    if not medalConfig then
        return nil
    end

    return medalConfig.MedalIcon
end

-- endregion

-- region Private/Protected

function XArenaControl:_GetGameDateTimeStr(time)
    if not time or time <= 0 then
        return ""
    end

    return XTime.TimestampToGameDateTimeString(time, "yy/MM/dd  HH:mm")
end

function XArenaControl:_SortChallengeHandler(challengeIdA, challengeIdB)
    return self._Model:GetChallengeAreaArenaLvByChallengeId(challengeIdA)
               < self._Model:GetChallengeAreaArenaLvByChallengeId(challengeIdB)
end

function XArenaControl:_GetSelectBuffIndexSaveKey()
    return "ARENA_AREA_SELECT_BUFF_INDEX_" .. XPlayer.Id
end

function XArenaControl:_GetArenaClearSelectBuffSaveKey()
    ---@type XArenaAgency
    local agency = self:GetAgency()

    return agency:_GetArenaClearSelectBuffSaveKey()
end

function XArenaControl:_ParseFromAreaSelectBuffStr(localStr)
    local keyValueList = string.Split(localStr, "-")
    local result = {}

    if not XTool.IsTableEmpty(keyValueList) then
        for _, keyValue in pairs(keyValueList) do
            if not string.IsNilOrEmpty(keyValue) then
                local key, value = table.unpack(string.Split(keyValue, "|"))

                result[tonumber(key)] = tonumber(value)
            end
        end
    end

    return result
end

function XArenaControl:_ParseToAreaSelectBuffStr(localMap)
    local result = ""

    if not XTool.IsTableEmpty(localMap) then
        for areaId, index in pairs(localMap) do
            result = result .. tostring(areaId) .. "|"
            result = result .. tostring(index) .. "-"
        end
    end

    return result
end

function XArenaControl:_LoadCurrentAreaSelectBuff()
    local isClear = XSaveTool.GetData(self:_GetArenaClearSelectBuffSaveKey())
    local localStr = XSaveTool.GetData(self:_GetSelectBuffIndexSaveKey())

    if isClear or string.IsNilOrEmpty(localStr) then
        XSaveTool.SaveData(self:_GetSelectBuffIndexSaveKey(), false)
        XSaveTool.SaveData(self:_GetArenaClearSelectBuffSaveKey(), false)

        return {}
    end

    return self:_ParseFromAreaSelectBuffStr(localStr)
end

function XArenaControl:_SaveCurrentAreaSelectBuff()
    local localStr = self:_ParseToAreaSelectBuffStr(self._SelectBuffIndexMap)

    XSaveTool.SaveData(self:_GetSelectBuffIndexSaveKey(), localStr)
end

-- endregion

-- region Request

function XArenaControl:AreaDataRequest(callback)
    if not self:IsInActivityFightStatus() then
        XUiManager.TipText("ArenaActivityStatusWrong")
        return
    end

    self._Model:AreaDataRequest(callback)
end

function XArenaControl:GroupMemberRequest(callback)
    if not self:IsInActivityFightStatus() then
        XUiManager.TipText("ArenaActivityStatusWrong")
        return
    end

    self._Model:GroupMemberRequest(callback)
end

function XArenaControl:ScoreQueryRequest(callback)
    self._Model:ScoreQueryRequest(callback)
end

function XArenaControl:ArenaChallengeGetRankRequest(challengeId, callback)
    self._Model:ArenaChallengeGetRankRequest(challengeId, callback)
end

-- endregion

function XArenaControl:OpenBattleRoleRoom(stageId, popThenOpen)
    -- v3.2 需要根据分区类型，（表AreaStage的Region字段）记录玩家上次挑战时使用的队伍，并在下次进入对应类型的关卡中时上阵上次选中的队伍
    local team = XDataCenter.TeamManager.GetXTeamByStageId(stageId)
    local proxyTable = {
        GetRoleDetailProxy = function(proxy)
            return {
                GetFilterControllerConfig = function()
                    return XMVCA.XCharacter:GetModelCharacterFilterController()["UiArenaChapterDetail"]
                end,
            }
        end,
    }
    local proxy = XTool.CreateBattleRoomDetailProxy(proxyTable)
    if popThenOpen then
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", stageId, team, proxy)
    else
        XLuaUiManager.Open("UiBattleRoleRoom", stageId, team, proxy)
    end
end

return XArenaControl
