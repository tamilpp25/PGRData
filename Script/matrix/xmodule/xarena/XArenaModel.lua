local XArenaActivityResultData = require("XModule/XArena/XData/XArenaActivityResultData")
local XArenaActivityData = require("XModule/XArena/XData/XArenaActivityData")
local XArenaAreaData = require("XModule/XArena/XData/XArenaAreaData")
local XArenaGroupMemberData = require("XModule/XArena/XData/XArenaGroupMemberData")
local XArenaScoreQueryData = require("XModule/XArena/XData/XArenaScoreQueryData")
local XArenaConfigModel = require("XModule/XArena/XArenaConfigModel")

---@class XArenaModel : XArenaConfigModel
local XArenaModel = XClass(XArenaConfigModel, "XArenaModel")

local RequestProtocol = {
    AreaDataRequest = "AreaDataRequest", -- 请求区域信息
    GroupMemberRequest = "GroupMemberRequest", -- 请求主页面成员信息
    ScoreQueryRequest = "ScoreQueryRequest", -- 请求上一期主页面成员信息
    ArenaChallengeGetRankRequest = "ArenaChallengeGetRankRequest", -- 根据ChallengeId获取个人排行榜
    JoinActivityRequest = "JoinActivityRequest", -- 报名参加竞技活动
}

function XArenaModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@type XArenaActivityResultData
    self._ActivityResultData = nil
    ---@type XArenaActivityData
    self._ActivityData = nil

    ---@type XArenaAreaData
    self._ArenaAreaDataCache = nil
    ---@type XArenaGroupMemberData
    self._ArenaGroupMemberCache = nil
    ---@type XArenaScoreQueryData
    self._ArenaScoreQueryCache = nil

    self._PlayerLevelChallengeMap = nil

    self._MaxContributeScore = CS.XGame.Config:GetInt("ArenaMaxContributeScore")
    self._ProtectContributeScore = CS.XGame.Config:GetInt("ArenaProtectContributeScore")
    self._AreaMaxProtectScore = CS.XGame.Config:GetInt("AreaMaxProtectScore")

    self._ContributeScoreItemId = 54
    self._ArenaHeroLv = 6

    self._SyncGroupMemberSecond = 10

    self._LastRequestGroupMemberTime = 0

    self._LocalPlayerResultRankMap = nil
    self._MaxArenaLevel = nil
    self._MaxChallengeId = nil

    self._CurrentSelectFightBuffIndex = 1
    self._IsInFightChangeActivityStatus = false
    self._IsRefreshMainPage = false
    self._CurrentEnterAreaId = 0
    self._CurrentFightEventGroupId = 0

    self:_InitTableKey()
end

function XArenaModel:ClearPrivate()
    -- 这里执行内部数据清理
    self._ArenaAreaDataCache = nil
    self._ArenaGroupMemberCache = nil
    self._LocalPlayerResultRankMap = nil
    -- XLog.Error("请对内部数据进行清理")
end

function XArenaModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self._ArenaScoreQueryCache = nil
end

function XArenaModel:SetActivityResultData(data)
    if self._ActivityResultData then
        self._ActivityResultData:SetData(data)
    else
        self._ActivityResultData = XArenaActivityResultData.New(data)
    end
end

function XArenaModel:SetActivityData(data)
    if self._ActivityData then
        self._ActivityData:SetData(data)
    else
        self._ActivityData = XArenaActivityData.New(data)
    end
end

function XArenaModel:SetActivityDataContributeScore(score)
    if self:CheckHasActivityData() then
        self._ActivityData:SetContributeScore(score)
    end
end

function XArenaModel:SetActivityDataArenaLevel(arenaLevel)
    if self:CheckHasActivityData() then
        self._ActivityData:SetArenaLevel(arenaLevel)
    end
end

function XArenaModel:SetAreaDataPointByAreaId(areaId, point)
    if self._ArenaAreaDataCache and not self._ArenaAreaDataCache:IsClear() then
        self._ArenaAreaDataCache:SetAreaShowDataPointByAreaId(areaId, point)
    end
end

function XArenaModel:CheckHasActivityData()
    return self._ActivityData and not self._ActivityData:IsClear()
end

---@return XArenaActivityData
function XArenaModel:GetActivityData()
    return self._ActivityData
end

---@return XArenaActivityResultData
function XArenaModel:GetActivityResultData()
    return self._ActivityResultData
end

function XArenaModel:ClearActivityResultData()
    if self:CheckHasActivityResultData() then
        self._ActivityResultData:Clear()
    end
end

function XArenaModel:CheckHasActivityResultData()
    return self._ActivityResultData and not self._ActivityResultData:IsClear()
end

function XArenaModel:GetContributeScoreItemId()
    return self._ContributeScoreItemId
end

function XArenaModel:GetArenaHeroLv()
    return self._ArenaHeroLv
end

function XArenaModel:GetMaxContributeScore()
    return self._MaxContributeScore
end

function XArenaModel:GetProtectContributeScore()
    return self._ProtectContributeScore
end

function XArenaModel:GetAreaMaxProtectScore()
    return self._AreaMaxProtectScore
end

function XArenaModel:GetLocalPlayerRankByPlayerId(playerId)
    if not self._LocalPlayerResultRankMap then
        self:_LoadGroupMemberResult()
    end
    if self._LocalPlayerResultRankMap then
        return self._LocalPlayerResultRankMap[playerId]
    end

    return nil
end

function XArenaModel:GetMaxArenaLevel()
    if not self._MaxArenaLevel then
        local levelConfigs = self:GetArenaLevelConfigs()

        self._MaxArenaLevel = 0
        if not XTool.IsTableEmpty(levelConfigs) then
            for id, _ in pairs(levelConfigs) do
                if self._MaxArenaLevel < id then
                    self._MaxArenaLevel = id
                end
            end
        end
    end

    return self._MaxArenaLevel
end

function XArenaModel:GetMaxChallengeId()
    if not self._MaxChallengeId then
        local challengeConfigs = self:GetChallengeAreaConfigs()

        self._MaxChallengeId = 0
        if not XTool.IsTableEmpty(challengeConfigs) then
            for id, _ in pairs(challengeConfigs) do
                if self._MaxChallengeId < id then
                    self._MaxChallengeId = id
                end
            end
        end
    end

    return self._MaxChallengeId
end

function XArenaModel:GetPlayerLevelChallengeMapByChallengeId(challengeId)
    local playerLevelChallengeMap = self:_GetPlayerLevelChallengeMap()

    for _, map in ipairs(playerLevelChallengeMap) do
        local challenge = map[challengeId]

        if challenge then
            return map
        end
    end

    return nil
end

function XArenaModel:GetCurrentSelectFightBuffIndex()
    return self._CurrentSelectFightBuffIndex or 1
end

function XArenaModel:SetCurrentSelectFightBuffIndex(value)
    self._CurrentSelectFightBuffIndex = value
end

function XArenaModel:GetIsInFightChangeActivityStatus()
    return self._IsInFightChangeActivityStatus
end

function XArenaModel:SetIsInFightChangeActivityStatus(value)
    self._IsInFightChangeActivityStatus = value
end

function XArenaModel:GetIsRefreshMainPage()
    return self._IsRefreshMainPage
end

function XArenaModel:SetIsRefreshMainPage(value)
    self._IsRefreshMainPage = value
end

function XArenaModel:GetCurrentEnterAreaId()
    return self._CurrentEnterAreaId
end

function XArenaModel:SetCurrentEnterAreaId(value)
    self._CurrentEnterAreaId = value
end

function XArenaModel:GetCurrentFightEventGroupId()
    return self._CurrentFightEventGroupId
end

function XArenaModel:SetCurrentFightEventGroupId(value)
    self._CurrentFightEventGroupId = value
end

function XArenaModel:GetCurrentAreaCount()
    if self._ArenaAreaDataCache and not self._ArenaAreaDataCache:IsClear() then
        return self._ArenaAreaDataCache:GetAreaShowDataAmount()
    end

    return 0
end

function XArenaModel:ClearAll()
    self:ClearScoreQueryCache()
    self:ClearAreaDataCache()
    self:ClearGroupMemberCache()
end

function XArenaModel:ClearScoreQueryCache()
    if self._ArenaScoreQueryCache and not self._ArenaScoreQueryCache:IsClear() then
        self._ArenaScoreQueryCache:Clear()
    end
end

function XArenaModel:ClearAreaDataCache()
    if self._ArenaAreaDataCache and not self._ArenaAreaDataCache:IsClear() then
        self._ArenaAreaDataCache:Clear()
    end
end

function XArenaModel:ClearGroupMemberCache()
    if self._ArenaGroupMemberCache and not self._ArenaGroupMemberCache:IsClear() then
        self._ArenaGroupMemberCache:Clear()
    end
end

-- region Request

function XArenaModel:AreaDataRequest(callback, failCallback)
    XNetwork.Call(RequestProtocol.AreaDataRequest, nil, function(res)
        if res.Code ~= XCode.Success then
            if failCallback then
                failCallback()
            end
            return
        end

        if self._ArenaAreaDataCache then
            self._ArenaAreaDataCache:SetData(res)
        else
            self._ArenaAreaDataCache = XArenaAreaData.New(res)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_ARENA_REFRESH_AREA_INFO, self._ArenaAreaDataCache)

        if callback then
            callback(self._ArenaAreaDataCache)
        end
    end)
end

function XArenaModel:GroupMemberRequest(callback)
    -- 请求间隔保护
    local now = XTime.GetServerNowTimestamp()

    if self._LastRequestGroupMemberTime + self._SyncGroupMemberSecond >= now then
        if self._ArenaGroupMemberCache then
            XEventManager.DispatchEvent(XEventId.EVENT_ARENA_MAIN_INFO)
            if callback then
                callback(self._ArenaGroupMemberCache, true)
            end

            return
        end
    end

    XNetwork.Call(RequestProtocol.GroupMemberRequest, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if callback then
                callback(nil, false)
            end
            return
        end

        if self._ArenaGroupMemberCache then
            self._ArenaGroupMemberCache:SetData(res)
        else
            self._ArenaGroupMemberCache = XArenaGroupMemberData.New(res)
        end

        self._LastRequestGroupMemberTime = now
        self:_SaveGroupMemberResult(res.GroupPlayerList)
        XEventManager.DispatchEvent(XEventId.EVENT_ARENA_MAIN_INFO)
        if callback then
            callback(self._ArenaGroupMemberCache, true)
        end
    end)
end

function XArenaModel:ScoreQueryRequest(callback)
    if self._ArenaScoreQueryCache and not self._ArenaScoreQueryCache:IsClear() then
        if self._ArenaScoreQueryCache:GetIsSuccess() then
            if callback then
                callback(self._ArenaScoreQueryCache, true)
            end
        else
            if callback then
                callback()
            end
            XUiManager.TipCode(self._ArenaScoreQueryCache:GetCode())
        end
        return
    end

    XNetwork.Call(RequestProtocol.ScoreQueryRequest, nil, function(res)
        if self._ArenaScoreQueryCache then
            self._ArenaScoreQueryCache:SetData(res)
        else
            self._ArenaScoreQueryCache = XArenaScoreQueryData.New(res)
        end
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if callback then
                callback()
            end
        else
            if callback then
                callback(self._ArenaScoreQueryCache, true)
            end
        end
    end)
end

function XArenaModel:ArenaChallengeGetRankRequest(challengeId, callback)
    XNetwork.Call(RequestProtocol.ArenaChallengeGetRankRequest, {
        ChallengeId = challengeId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback(res)
        end
    end)
end

function XArenaModel:JoinActivityRequest(callback)
    if not self._ActivityData then
        if callback then
            callback(false)
        end
        return
    end
    if self._ActivityData:GetStatus() == XEnumConst.Arena.ActivityStatus.Over then
        if callback then
            callback(true)
        end
        return
    end
    if self._ActivityData:GetIsJoinActivity() then
        if callback then
            callback(true)
        end
        return
    end

    XNetwork.Call(RequestProtocol.JoinActivityRequest, nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if callback then
                callback(false)
            end
            return
        end

        self._ActivityData:SetIsJoinActivity(true)
        if XTool.IsNumberValid(res.ChallengeId) then
            self._ActivityData:SetChallengeId(res.ChallengeId)
        end
        if callback then
            callback(true)
        end
    end)
end

-- endregion

-- region Private

function XArenaModel:_SaveGroupMemberResult(playerRankResultList)
    if not self._ActivityData or not XTool.IsNumberValid(self._ActivityData:GetActivityNo()) then
        return
    end

    local activityNo = self._ActivityData:GetActivityNo()
    local key = XPrefs.ArenaTeamResult .. tostring(XPlayer.Id)
    local value = tostring(activityNo) .. "|"

    for i, info in ipairs(playerRankResultList) do
        value = value .. tostring(info.Id)

        if i < #playerRankResultList then
            value = value .. "|"
        end
    end

    CS.UnityEngine.PlayerPrefs.SetString(key, value)
    CS.UnityEngine.PlayerPrefs.Save()
end

function XArenaModel:_LoadGroupMemberResult()
    local key = XPrefs.ArenaTeamResult .. tostring(XPlayer.Id)

    if not CS.UnityEngine.PlayerPrefs.HasKey(key) then
        return
    end

    local value = CS.UnityEngine.PlayerPrefs.GetString(key)
    local valueStrs = string.Split(value)

    if not valueStrs or #valueStrs < 2 then
        return
    end
    if not self._ArenaScoreQueryCache or self._ArenaScoreQueryCache:GetActivityNo() ~= tonumber(valueStrs[1]) then
        return
    end

    self._LocalPlayerResultRankMap = {}
    for i = 2, #valueStrs do
        self._LocalPlayerResultRankMap[tonumber(valueStrs[i])] = i - 1
    end
end

function XArenaModel:_GetPlayerLevelChallengeMap()
    if not self._PlayerLevelChallengeMap then
        local tempMap = {}
        local tempTypeId = 0
        local challengeConfigs = self:GetChallengeAreaConfigs()

        self._PlayerLevelChallengeMap = {}
        for id, config in pairs(challengeConfigs) do
            if config.Ignore ~= 1 then
                local typeId = tempMap[config.MinLv]

                if not typeId then
                    typeId = tempTypeId + 1
                    tempMap[config.MinLv] = typeId
                    tempTypeId = typeId
                end

                local challengeMap = self._PlayerLevelChallengeMap[typeId]
                if not challengeMap then
                    challengeMap = {}
                    self._PlayerLevelChallengeMap[typeId] = challengeMap
                end

                challengeMap[id] = id
            end
        end
    end

    return self._PlayerLevelChallengeMap
end

-- endregion

return XArenaModel
