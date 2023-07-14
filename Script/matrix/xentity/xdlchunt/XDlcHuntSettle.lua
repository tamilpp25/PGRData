---@class XDlcHuntSettle
local XDlcHuntSettle = XClass(nil, "XDlcHuntSettle")

function XDlcHuntSettle:Ctor()
    self._OriginalData = false
    self.IsWin = false
    self.Name = false
    self.PassedTime = false
    ---@type XDlcFightSettlePlayerData[]
    self.Members = {}
    self.SettleLoseTipId = false
    self.RewardList = false
    self.LoseType = false
    self.WorldId = false
end

function XDlcHuntSettle:SetData(result)
    self._OriginalData = result

    --local assistantPoint = result.AssistPoint
    --local assistantPlayerId = result.AssistPlayerId
    local rewardList = result.RewardGoodsList
    local resultData = result.ResultData
    local loseType = result.LoseType

    local isWin = resultData.IsWin
    local finishTime = resultData.FinishTime
    local worldData = resultData.WorldData
    --local isOnLine = worldData.Online
    --local roomId = worldData.RoomId
    --local levelId = worldData.LevelId
    --local missionId = worldData.MissionId
    local playerList = worldData.Players
    local fightPlayerDataDict = resultData.PlayerData
    local worldId = worldData.WorldId

    local strPassedTime = XUiHelper.GetTime(finishTime, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
    
    self.IsWin = isWin
    self.Name = XDlcHuntWorldConfig.GetWorldDifficultyName(worldId)
    self.PassedTime = strPassedTime
    self.RewardList = rewardList
    self.LoseType = loseType
    self.WorldId = worldId

    if isWin then
        self.SettleLoseTipId = false
    else
        self.SettleLoseTipId = XDlcHuntWorldConfig.GetWorldLostTipId(worldId)
    end
    
    if not isWin then
        return
    end
    local members = {}
    self.Members = members
    for i = 1, #playerList do
        local playerData = playerList[i]
        local playerId = playerData.Id
        local firstNpc = playerData.NpcList[1]
        local npcId = firstNpc and firstNpc.Id
        local characterId = XDlcHuntCharacterConfigs.GetCharacterIdByNpcId(npcId)
        local icon = XDlcHuntCharacterConfigs.GetCharacterHalfBodyImage(characterId)

        local fightPlayerData = fightPlayerDataDict[playerId]
        local bossDataDict = fightPlayerData.BossSettlementData

        --对BOSS造成的伤害值
        local damage = 0
        for bossId, bossData in pairs(bossDataDict) do
            damage = damage + bossData.TotalHurt
        end

        --承受的伤害值
        local beHurt = fightPlayerData.HitHurt or 0

        --钉入猎矛的次数
        local controlCount = 0
        for bossId, bossData in pairs(bossDataDict) do
            controlCount = controlCount + bossData.ControlCount
        end

        --重启次数（就是复活）
        local reviveCount = fightPlayerData.ResurrectionCount or 0

        --救援队友次数
        local helpOthersCount = fightPlayerData.ResurrectionPlayerCount or 0

        -- 徽章
        local badgeList = {}
        for j = 1, #fightPlayerData.UnlockBadge do
            local badgeId = fightPlayerData.UnlockBadge[j]
            badgeList[j] = {
                Icon = XDlcHuntWorldConfig.GetBadgeIcon(badgeId),
                Name = XDlcHuntWorldConfig.GetBadgeName(badgeId),
                Desc = XDlcHuntWorldConfig.GetBadgeDesc(badgeId)
            }
        end
        ---@class XDlcFightSettlePlayerData
        local member = {
            Name = playerData.Name,
            Icon = icon,
            IsLeader = playerData.IsLeader,
            PlayerId = playerId,
            Badge = badgeList,
            Damage = damage,
            IsMvp = false,
            DetailValue = {
                damage, beHurt, controlCount, reviveCount, helpOthersCount
            },
            CharacterId = characterId
        }
        members[i] = member
    end

    -- 将自己移到第一位
    local myPlayerId = XPlayer.Id
    if myPlayerId ~= members[1].PlayerId then
        for i = 2, #members do
            local member = members[i]
            if member.PlayerId == myPlayerId then
                local memberOther = members[1]
                members[1] = member
                members[i] = memberOther
                break
            end
        end
    end

    -- mvp
    local mvpIndex = 0
    local mvpDamage = 0
    for i = 1, #members do
        local member = members[i]
        if member.Damage > mvpDamage then
            mvpDamage = member.Damage
            mvpIndex = i
        end
    end
    local mvpMember = members[mvpIndex]
    if mvpMember then
        mvpMember.IsMvp = true
    end
end

function XDlcHuntSettle:GetMyData()
    -- 已将自己移到第一位
    return self.Members[1]
end

function XDlcHuntSettle:IsFail4FightingPower()
    local member = self:GetMyData()
    if not member then
        return false
    end
    local characterId = member.CharacterId
    local character = XDataCenter.DlcHuntCharacterManager.GetCharacter(characterId)
    if not character then
        return false
    end
    local myFightingPower = character:GetFightingPower()
    local worldId = self.WorldId
    local needFightingPower = XDlcHuntWorldConfig.GetWorldNeedFightingPower(worldId)
    return myFightingPower <= needFightingPower
end

function XDlcHuntSettle:_GetWorld()
    return XDataCenter.DlcHuntManager.GetWorld(self.WorldId)
end

function XDlcHuntSettle:GetLoseTipBoss()
    return XDlcHuntWorldConfig.GetWorldBossDetailOnPause(self.WorldId)
end

return XDlcHuntSettle