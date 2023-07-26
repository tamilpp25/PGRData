local XDlcHuntPlayerData = require("XEntity/XDlcHunt/XDlcHuntPlayerData")

---@class XDlcHuntFightBeginData
local XDlcHuntFightBeginData = XClass(nil, "XDlcHuntFightBeginData")

function XDlcHuntFightBeginData:Ctor()
    ---@private
    self._WorldData = false
    ---@type XDlcHuntPlayerData[]
    self._PlayerDataList = {}
    self._RoomData = {}
end

function XDlcHuntFightBeginData:SetRoomData(roomData)
    self._RoomData = roomData
end

function XDlcHuntFightBeginData:SetWorldData(data)
    self._WorldData = data

    if self._RoomData then
        for i = 1, #self._WorldData.Players do
            local data = self._WorldData.Players[i]
            local playerId = data.Id

            for i = 1, #self._RoomData.PlayerDataList do
                local playerInfo = self._RoomData.PlayerDataList[i]
                if playerInfo.Id == playerId then
                    data.Name = playerInfo.Name
                end
            end

            if not data.Name then
                XLog.Error("[XDlcHuntFightBeginData] player not found in room data:" .. tostring(playerId))
            end
        end
    end
end

function XDlcHuntFightBeginData:GetPlayerAmount()
    return #self._WorldData.Players
end

function XDlcHuntFightBeginData:GewPlayerData(pos)
    if not self._PlayerDataList[pos] then
        self._PlayerDataList[pos] = XDlcHuntPlayerData.New()
    end
    local playerData = self._PlayerDataList[pos]
    local data = self._WorldData.Players[pos]
    --local data = {
    --    Id = self:GetPlayerId(pos),
    --    MedalId = -1,
    --    Character = {
    --        Id = 1021001,
    --        CharacterHeadInfo = {
    --            HeadFashionId = 0,
    --            HeadFashionType = 0,
    --        }
    --    },
    --    StageType = nil,
    --    HaveFirstPass = nil
    --}
    playerData:SetData(data)
    return playerData
end

function XDlcHuntFightBeginData:GetWorldId()
    return self._WorldData.WorldId
end

return XDlcHuntFightBeginData