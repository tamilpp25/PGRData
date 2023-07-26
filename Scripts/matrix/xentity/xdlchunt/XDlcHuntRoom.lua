local XDlcHuntTeam = require("XEntity/XDlcHunt/XDlcHuntTeam")

---@class XDlcHuntRoom
local XDlcHuntRoom = XClass(nil, "XDlcHuntRoom")

function XDlcHuntRoom:Ctor()
    self._IsInRoom = false

    self._TeamId = XDlcHuntConfigs.TeamId.Multi
    self._Data = false
    self._Level = 0
    ---@type XDlcHuntTeam
    self._Team = false
    self._IsMatching = false
    self._IsCancelingMatch = false
    self._IsReconnect = false
    self._IsTutorial = false
end

function XDlcHuntRoom:Reset()
    self._IsInRoom = false
    self._Data = false
    self._Team = false
    self._IsMatching = false
    self._IsCancelingMatch = false
    self._IsReconnect = false
    self._IsTutorial = false
    self._Level = 0
end

function XDlcHuntRoom:IsInRoom()
    return self._IsInRoom
end

function XDlcHuntRoom:IsMatching()
    return self._IsMatching
end

function XDlcHuntRoom:SetMatching(value)
    self._IsMatching = value
    if value then
        XLuaUiManager.Open("UiDlcHuntMatching")
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_MATCH)
    else
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_CANCEL_MATCH)
    end
end

function XDlcHuntRoom:SetCancelingMatch(value)
    self._IsCancelingMatch = value
end

function XDlcHuntRoom:IsCancelingMatch()
    return self._IsCancelingMatch
end

function XDlcHuntRoom:SetData(roomData)
    if not roomData then
        self:Reset()
    else
        self._IsInRoom = true
        self._Data = roomData
        self:UpdateData()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_HUNT_ROOM_UPDATE)
end

function XDlcHuntRoom:UpdateData()
    local team = self:GetTeam()
    team:SetRoomData(self._Data)
end

function XDlcHuntRoom:GetData()
    return self._Data
end

function XDlcHuntRoom:GetId()
    if not self._Data then
        return false
    end
    return self._Data.Id
end

---@return XDlcHuntWorld
function XDlcHuntRoom:GetWorld()
    local data = self:GetData()
    if not data then
        return false
    end
    local worldId = data.WorldId
    return XDataCenter.DlcHuntManager.GetWorld(worldId)
end

function XDlcHuntRoom:GetWorldId()
    local world = self:GetWorld()
    return world and world:GetWorldId()
end

function XDlcHuntRoom:GetName()
    local world = self:GetWorld()
    if not world then
        return ""
    end
    return world:GetName()
end

function XDlcHuntRoom:UpdatePlayerInfo(playerInfoList)
    local roomData = self:GetData()
    if roomData then
        local isBecomeLeader = false

        for _, playerInfo in pairs(playerInfoList) do
            for _, v in pairs(roomData.PlayerDataList) do
                if v.Id == playerInfo.Id then
                    if v.Id == XPlayer.Id and not v.Leader and playerInfo.Leader then
                        isBecomeLeader = true
                    end
                    v.State = playerInfo.State
                    v.Leader = playerInfo.Leader
                    if playerInfo.WorldNpcData then
                        v.WorldNpcData = playerInfo.WorldNpcData
                    end
                    break
                end
            end
        end
        self._Team:SetRoomData(roomData)

        -- 先赋值再通知事件
        for _, playerInfo in pairs(playerInfoList) do
            for _, v in pairs(roomData.PlayerDataList) do
                if v.Id == playerInfo.Id then
                    if playerInfo.FightNpcData then
                        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, v)
                    else
                        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, v)
                    end
                    break
                end
            end
        end

        if isBecomeLeader then
            XUiManager.TipText("DlcHuntBecomeLeader")
        end
    end
end

---@return XDlcHuntTeam
function XDlcHuntRoom:GetTeam()
    if not self._Team then
        self._Team = XDlcHuntTeam.New(self._TeamId, self:GetId())
    end
    return self._Team
end

function XDlcHuntRoom:SetState(state)
    if self._Data then
        self._Data.State = state
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_STAGE_CHANGE, state)
    end
end

function XDlcHuntRoom:GetState()
    if not self._Data then
        return XDlcHuntConfigs.PlayerState.Ready
    end
    return self._Data.State
end

function XDlcHuntRoom:IsAutoMatch()
    if not self._Data then
        return true
    end
    return self._Data.AutoMatch
end

function XDlcHuntRoom:SetAutoMatching(value)
    if self._Data then
        self._Data.AutoMatch = value
        XEventManager.DispatchEvent(XEventId.EVENT_ROOM_AUTO_MATCH_CHANGE, value)
    end
end

function XDlcHuntRoom:JoinPlayer(playerData)
    local roomData = self._Data
    if not roomData then
        return
    end

    local isFind = false
    for i = 1, #roomData.PlayerDataList do
        local data = roomData.PlayerDataList[i]
        if data.Id == playerData.Id then
            roomData.PlayerDataList[i] = playerData
            isFind = true
            break
        end
    end
    if not isFind then
        table.insert(roomData.PlayerDataList, playerData)
    end

    self:UpdateData()
    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_ENTER, playerData)
end

function XDlcHuntRoom:LeavePlayer(playerDataList)
    local roomData = self._Data
    if roomData then
        for _, targetId in pairs(playerDataList) do
            for k, v in pairs(roomData.PlayerDataList) do
                if v.Id == targetId then
                    table.remove(roomData.PlayerDataList, k)
                    self:UpdateData()
                    XEventManager.DispatchEvent(XEventId.EVENT_ROOM_PLAYER_LEAVE, targetId)
                    break
                end
            end
        end
    end
end

function XDlcHuntRoom:GetAbilityLimit()
    if not self._Data then
        return 0
    end
    return self._Data.AbilityLimit or 0
end

function XDlcHuntRoom:SetAbilityLimit(value)
    if not self._Data then
        return
    end
    self._Data.AbilityLimit = value
end

function XDlcHuntRoom:SetIsReconnect(value)
    self._IsReconnect = value
end

function XDlcHuntRoom:SetIsTutorial(value)
    self._IsTutorial = value
end

function XDlcHuntRoom:IsTutorial()
    return self._IsTutorial
end

function XDlcHuntRoom:SetLevel(value)
    self._Level = value
end

function XDlcHuntRoom:GetLevel()
    return self._Level
end

return XDlcHuntRoom