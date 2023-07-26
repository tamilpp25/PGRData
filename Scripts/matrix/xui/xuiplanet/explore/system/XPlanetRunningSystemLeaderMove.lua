local XUiPlanetRunningFight = require("XUi/XUiPlanet/Fight/XUiPlanetRunningFight")
local MOVE_STATUS = XPlanetExploreConfigs.MOVE_STATUS

---@class XPlanetRunningSystemLeaderMove
local XPlanetRunningSystemLeaderMove = XClass(nil, "XPlanetRunningSystemLeaderMove")

---@param explore XPlanetRunningExplore
function XPlanetRunningSystemLeaderMove:Update(explore, deltaTime)
    local leader = explore:GetLeader()
    if not leader then
        return
    end

    -- 在拐角时, 当前帧时间不一定被用完, 会update多次状态, walk->end->start->walk
    local remainTime = deltaTime

    if leader.LeaderMove.Delay2RequestFunc then
        local time = self:GetTime()
        if leader.LeaderMove.Delay2Request < time then
            leader.LeaderMove.Delay2RequestFunc()
            leader.LeaderMove.Delay2RequestFunc = false
        end
    end

    -- start和end状态跳过, 避免停顿造成的动作卡顿
    for i = 1, MOVE_STATUS.SIZE do
        if i > 3 then
            XLog.Error("[XPlanetRunningSystemLeaderMove] 移动可能有问题" .. i)
        end
        if leader.Move.Status == MOVE_STATUS.START then
            for i = 1, #explore.Entities do
                local entity = explore.Entities[i]
                if entity ~= leader
                        and entity.Camp.CampType == XPlanetExploreConfigs.CAMP.PLAYER
                then
                    entity.Animation.Action = XPlanetExploreConfigs.ACTION.WALK
                end
            end

            local gridId = leader.Move.TileIdCurrent
            local isFight, isNoChangeMoveStatus = self:CheckFight(gridId, explore)
            if isNoChangeMoveStatus then
                return
            end
            remainTime = self:UpdateMove(explore, leader, remainTime)

            -- 移动时，将路径保存
            local pathData = self:GetPathData(explore, leader)
            table.insert(leader.LeaderMove.Path, pathData)
            if #leader.LeaderMove.Path > 4 then
                table.remove(leader.LeaderMove.Path, 1)
            end

            if isFight then
                return
            end
        end

        -- 移动主角
        if leader.Move.Status == MOVE_STATUS.WALK then
            remainTime = self:UpdateMove(explore, leader, remainTime)

            -- 在路走过一半的时候, 提早发起请求
            if leader.Move.Duration / leader.Move.DurationExpected > 0.5 then
                local grid = leader.Move.TileIdEnd
                self:TryRequestMove(explore, false, grid)
            end
        end

        if leader.Move.Status == MOVE_STATUS.END then
            local grid = leader.Move.TileIdEnd
            self:TryRequestMove(explore, false, grid)
            
            -- 等待移动请求完成
            if leader.LeaderMove.IsRequesting then
                return
            end
            remainTime = self:UpdateMove(explore, leader, remainTime)
            leader.Move.Status = MOVE_STATUS.START
        end

        if leader.Move.Status == MOVE_STATUS.WALK
                and remainTime == 0
        then
            break
        end
    end

    self:MoveFollower(explore, leader, deltaTime)
end

---@param explore XPlanetRunningExplore
function XPlanetRunningSystemLeaderMove:TryRequestMove(explore, ignoreSavingRequest, gridId)
    if explore.Scene:CheckIsTalentPlanet() then
        return
    end

    local leader = explore:GetLeader()
    if leader.LeaderMove.IsRequesting then
        return
    end

    -- 在模型即将走到下一格的时候, 拒绝同步坐标
    if not gridId then
        gridId = leader.Move.TileIdCurrent
        if gridId == leader.Move.TileIdStart and
                leader.LeaderMove.TileIdOnServer == leader.Move.TileIdEnd then
            return
        end
    end

    local isRequest = false
    if explore:IsGridInBuildingRange(gridId)
            or explore:IsBossOnGrid(gridId)
            or explore:IsOnStartPoint(gridId)
            or leader.LeaderMove.SavingRequestAmount > leader.LeaderMove.SavingRequestAmountMax
            or ignoreSavingRequest
    then
        isRequest = true
    end

    if leader.LeaderMove.TileIdOnServer == gridId then
        isRequest = false
    end

    if isRequest then
        leader.LeaderMove.TileIdOnServer = gridId
        leader.LeaderMove.IsRequesting = true
        local time = self:GetTime()
        local durationRequest = time - leader.LeaderMove.LastTimeRequestMove
        if durationRequest > leader.LeaderMove.DurationRequestMoveDuration then
            self:RequestMove(explore, leader, gridId)
        else
            local delay = leader.LeaderMove.DurationRequestMoveDuration - durationRequest
            leader.LeaderMove.Delay2Request = delay + time
            leader.LeaderMove.Delay2RequestFunc = function()
                if explore:IsDestroy() then
                    return
                end
                self:RequestMove(explore, leader, gridId)
            end
        end

    elseif leader.LeaderMove.GridHasCheckSavingRequest ~= gridId then
        leader.LeaderMove.SavingRequestAmount = leader.LeaderMove.SavingRequestAmount + 1
        leader.LeaderMove.GridHasCheckSavingRequest = gridId
    end
end

---@param explore XPlanetRunningExplore
function XPlanetRunningSystemLeaderMove:UpdateMove(explore, leader, deltaTime)
    return explore.SystemMove:Update(explore, leader, deltaTime)
end

-- 移动小弟
---@param explore XPlanetRunningExplore
---@param leader XPlanetRunningExploreEntity
---@param deltaTime number
function XPlanetRunningSystemLeaderMove:MoveFollower(explore, leader, deltaTime)
    local index = 0
    for i = 1, #explore.Entities do
        local entity = explore.Entities[i]
        if entity ~= leader
                and entity.Camp.CampType == XPlanetExploreConfigs.CAMP.PLAYER
                and entity.Attr.Life > 0 then
            index = index + 1
            local isShow = false
            local pathData = leader.LeaderMove.Path
            if index then
                ---@type XPlanetPathPoint
                local path = pathData[#pathData - index + 1]
                -- 第一个角色不能隐藏
                if index == 1 and not path then
                    path = self:GetPathData(explore, leader)
                end

                if path then
                    local positionTarget, positionStart = path.PositionTarget, path.PositionStart
                    if positionTarget and positionStart then
                        local pointStart = positionStart
                        local pointTarget = positionTarget
                        entity.Move.Status = MOVE_STATUS.WALK
                        entity.Move.PositionTarget = pointTarget
                        entity.Move.PositionStart = pointStart
                        entity.Move.Direction = path.Direction
                        entity.Move.Duration = leader.Move.Duration
                        entity.Move.Distance = path.Distance
                        entity.Rotation.RotationTo = path.Rotation
                        explore.SystemMove:Update(explore, entity, 0)
                        isShow = true
                    end
                end
            end
            -- 第一个角色不能隐藏
            if isShow or index == 1 then
                explore:ShowModel(entity)
            else
                explore:HideModel(entity)
            end
        end
    end
end

---@param explore XPlanetRunningExplore
---@return boolean, boolean
function XPlanetRunningSystemLeaderMove:CheckFight(gridId, explore, notSyncPosition)
    if not explore:IsRunning() then
        return
    end
    local boss = explore:FindBossOnGrid(gridId)
    if boss then
        if XDataCenter.PlanetManager.SetGuideFirstFight(true) and XDataCenter.PlanetManager.CheckGuideOpen() then
            explore:Pause(XPlanetExploreConfigs.PAUSE_REASON.GUIDE)
            return true, true
        else
            explore:Pause(XPlanetExploreConfigs.PAUSE_REASON.FIGHT, notSyncPosition)
            if explore:GetLeader().LeaderMove.IsRequesting then
                explore:Resume(XPlanetExploreConfigs.PAUSE_REASON.FIGHT)
                return true, true
            end
            if gridId ~= explore:GetLeader().LeaderMove.TileIdOnServer then
                XLog.Error("[XPlanetRunningSystemLeaderMove] 移动出现问题， 坐标不同步")
                explore:Resume(XPlanetExploreConfigs.PAUSE_REASON.FIGHT)
                return true, true
            end
            self:RequestFight(boss, gridId, explore)
        end

        return true
    end
    return false
end

---@param explore XPlanetRunningExplore
function XPlanetRunningSystemLeaderMove:RequestFight(boss, gridId, explore)
    XDataCenter.PlanetExploreManager.RequestPreFight(gridId, function(success, res)
        if not success then
            XLog.Error("[XPlanetRunningExplore] fight request fail")
            explore:Resume(XPlanetExploreConfigs.PAUSE_REASON.FIGHT)
            return
        end
        local fightData = res.FightData
        XDataCenter.PlanetExploreManager.SetFightData(fightData)
        self:HandleFightData(boss, explore)
    end)
end

---@param boss XPlanetRunningExploreEntity
---@param explore XPlanetRunningExplore
function XPlanetRunningSystemLeaderMove:HandleFightData(boss, explore)
    local fightData = XDataCenter.PlanetExploreManager.GetFightData()

    local bossId = boss.Data.IdFromConfig
    local isCanSkip = XPlanetStageConfigs.IsBossCanSkipFight(bossId)
    if isCanSkip and explore:IsSkipFight() then
        explore:PlayBornEffect(boss)
        self:SetAction2Captain(explore, XPlanetExploreConfigs.ACTION.SKIP_FIGHT)

        ---@type XUiPlanetRunningFight
        local fight = XUiPlanetRunningFight.New()
        fight:SetData(fightData)
        fight:Init()
        fight:Skip(function()
            explore:Resume(XPlanetExploreConfigs.PAUSE_REASON.FIGHT)
            self:SetAction2Captain(explore, XPlanetExploreConfigs.ACTION.WALK)
        end, true)
        return
    end

    local tipType
    if XPlanetStageConfigs.IsSpecialBoss(bossId) then
        tipType = XPlanetConfigs.TipType.Boss
    else
        tipType = XPlanetConfigs.TipType.Monster
    end
    XDataCenter.PlanetExploreManager.OpenUiPlanetEncounter(function()
        -- 撞boss时检测是否有触发剧情
        local stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
        local movieId = XPlanetExploreConfigs.GetMovieIdByCheckControllerBoss(XPlanetExploreConfigs.MOVIE_CONDITION.BOSS_FIGHT, stageId, bossId)
        if movieId then
            explore:PlayMovie(movieId, function()
                XLuaUiManager.Open("UiPlanetFightMain", fightData)
            end)
        else
            XLuaUiManager.Open("UiPlanetFightMain", fightData)
        end
    end, tipType)
end

---@param explore XPlanetRunningExplore
function XPlanetRunningSystemLeaderMove:SetAction2Captain(explore, action)
    local character = explore:GetCaptain()
    if character then
        character.Animation.Action = action
    end
end

---@param explore XPlanetRunningExplore
---@param leader XPlanetRunningExploreEntity
function XPlanetRunningSystemLeaderMove:GetPathData(explore, leader)
    if not leader.Move.PositionStart then
        explore.SystemMove:UpdateMoveStartData(explore, leader)
    end

    ---@class XPlanetPathPoint
    local path = {
        PositionStart = leader.Move.PositionStart,
        PositionTarget = leader.Move.PositionTarget,
        Rotation = leader.Rotation.RotationTo,
        Distance = explore.SystemMove:GetDistance(leader.Move.PositionTarget, leader.Move.PositionStart),
        Direction = (leader.Move.PositionTarget - leader.Move.PositionStart).normalized,
    }
    return path
end

---@param explore XPlanetRunningExplore
function XPlanetRunningSystemLeaderMove:SyncPosition(explore)
    local leader = explore:GetLeader()
    local tileIdOnServer = leader.LeaderMove.TileIdOnServer
    if tileIdOnServer ~= leader.Move.TileIdCurrent then
        self:TryRequestMove(explore, true)
    end
end

---@param explore XPlanetRunningExplore
---@param leader XPlanetRunningExploreEntity
function XPlanetRunningSystemLeaderMove:RequestMove(explore, leader, gridId)
    XDataCenter.PlanetExploreManager.RequestExploreMove(gridId, function(isSuccess)
        leader.LeaderMove.LastTimeRequestMove = self:GetTime()
        leader.LeaderMove.IsRequesting = false
        if isSuccess then
            self:CheckFight(gridId, explore, true)
        else
            explore:Pause()
            XLog.Error("[XPlanetRunningExplore] move request fail")
        end
    end)
    leader.LeaderMove.SavingRequestAmount = 0
end

function XPlanetRunningSystemLeaderMove:GetTime()
    return CS.UnityEngine.Time.unscaledTime
end

return XPlanetRunningSystemLeaderMove