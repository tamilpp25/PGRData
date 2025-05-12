---@class XDlcRoomModel : XModel
local XDlcRoomModel = XClass(XModel, "XDlcRoomModel")
local XDlcRoomData = require("XModule/XDlcRoom/XEntity/Data/XDlcRoomData")
local XDlcJoinWorldData = require("XModule/XDlcRoom/XEntity/Data/XDlcJoinWorldData")
local XDlcFightBeginData = require("XModule/XDlcRoom/XEntity/Data/XDlcFightBeginData")

function XDlcRoomModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@type XDlcRoomData
    self._RoomData = nil
    ---@type XDlcJoinWorldData
    self._ReJoinWorldData = nil
    ---@type XDlcJoinWorldData
    self._JoinWorldData = nil
    ---@type XDlcFightBeginData
    self._FightBeginData = nil

    self._IsFighting = false
    self._IsCancelingMatch = false
    self._IsMatching = false
    self._IsSettled = true
    self._IsReconnect = false
    self._IsRebuildRoom = false
    self._IsLoginOut = false

    self._InviteChatDataList = {}

    self._FocusType = nil

    self._InviteShowTime = CS.XGame.ClientConfig:GetInt("DlcOnlineInviteShowTime") or -1
    self._InviteChatCacheTime = CS.XGame.Config:GetInt("DlcRoomHrefDisableTime")
    self._ReadyEnterWorldMaskKey = "DLC_READY_ENTER_WORLD"
end

function XDlcRoomModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XDlcRoomModel:ResetAll()
    -- 这里执行重登数据清理
    self:ClearAll()
    self:ClearInviteChatData()
    self:ClearFightBeginData()
    self:ClearReJoinWorldData()
    -- XLog.Error("重登数据清理")
end

-- region RoomData
function XDlcRoomModel:SetRoomData(roomData)
    if not self:IsRoomDataEmpty() then
        self._RoomData:SetData(roomData)
    else
        self._RoomData = XDlcRoomData.New(roomData)
    end
end

---@type XDlcRoomData
function XDlcRoomModel:GetRoomData()
    return self._RoomData
end

function XDlcRoomModel:SetRoomAutoMatching(value)
    if not self:IsRoomDataEmpty() then
        self._RoomData:SetAutoMatch(value)

        return true
    end

    return false
end

function XDlcRoomModel:IsRoomAutoMatch()
    if not self:IsRoomDataEmpty() then
        return self._RoomData:IsAutoMatch()
    end

    return false
end

function XDlcRoomModel:IsRoomDataEmpty()
    return self._RoomData == nil
end

function XDlcRoomModel:IsRoomDataClear()
    return self:IsRoomDataEmpty() or self._RoomData:IsClear()
end

function XDlcRoomModel:SetRoomState(state)
    if not self:IsRoomDataEmpty() then
        self._RoomData:SetState(state)

        return true
    end

    return false
end

function XDlcRoomModel:GetRoomState()
    if self:IsRoomDataEmpty() then
        return XEnumConst.DlcRoom.RoomState.None
    end

    return self._RoomData:GetState()
end

function XDlcRoomModel:SetRoomAbilityLimit(value)
    if not self:IsRoomDataEmpty() then
        self._RoomData:SetAbilityLimit(value)

        return true
    end

    return false
end

function XDlcRoomModel:GetRoomAbilityLimit()
    if not self:IsRoomDataEmpty() then
        return self._RoomData:GetAbilityLimit()
    end

    return -1
end

function XDlcRoomModel:SetRoomWorldId(worldId)
    if not self:IsRoomDataEmpty() then
        self._RoomData:SetWorldId(worldId)
    end
end

function XDlcRoomModel:SetRoomLevelId(levelId)
    if not self:IsRoomDataEmpty() then
        self._RoomData:SetLevelId(levelId)
    end
end

function XDlcRoomModel:GetRoomWorldId()
    if not self:IsRoomDataEmpty() then
        return self._RoomData:GetWorldId()
    end

    return -1
end

function XDlcRoomModel:SetRoomIsTutorial(isTutorial)
    if not self:IsRoomDataEmpty() then
        self._RoomData:SetIsTutorial(isTutorial)
    end
end

function XDlcRoomModel:IsRoomTutorial()
    if not self:IsRoomDataEmpty() then
        return self._RoomData:IsTutorial()
    end

    return false
end

function XDlcRoomModel:UpdatePlayerInfo(playerInfoList)
    if not self:IsRoomDataEmpty() then
        local data = self:GetRoomData()
        local playerList = {}

        for i = 1, #playerInfoList do
            local playerInfo = playerInfoList[i]
            local player = data:GetPlayerDataById(playerInfo.Id)

            if player then
                player:SetIsLeader(playerInfo.Leader)
                player:SetState(playerInfo.State)
                player:SetCharacterListBySource({
                    playerInfo.WorldNpcData,
                })
            end
        end

        for i = 1, #playerInfoList do
            local playerInfo = playerInfoList[i]
            local player = data:GetPlayerDataById(playerInfo.Id)

            if player then
                playerList[#playerList + 1] = playerInfo.Id
            end
        end

        return playerList
    end
end

function XDlcRoomModel:JoinPlayer(playerData)
    if not self:IsRoomDataClear() then
        local data = self:GetRoomData()
        local player = data:GetPlayerDataById(playerData.Id)
        local worldType = XMVCA.XDlcWorld:GetWorldTypeById(data:GetWorldId())

        if player then
            player:SetDataWithRoomData(playerData, worldType)
        else
            data:AddPlayerDataBySource(playerData)
        end

        return playerData.Id
    end
end

function XDlcRoomModel:LeavePlayer(playerDataList)
    if not self:IsRoomDataEmpty() then
        local data = self:GetRoomData()
        local targetIdList = {}

        for i = 1, #playerDataList do
            local targetId = playerDataList[i]

            if data:RemovePlayerDataById(targetId) then
                targetIdList[#targetIdList + 1] = targetId
            end
        end

        return targetIdList
    end
end

function XDlcRoomModel:UpdateRoomData(data)
    if not self:IsRoomDataEmpty() then
        self:SetRoomWorldId(data.WorldId)
        self:SetRoomLevelId(data.LevelId)
        self:SetRoomAutoMatching(data.AutoMatch)
        self:SetRoomAbilityLimit(data.AbilityLimit)

        return true
    end

    return false
end

function XDlcRoomModel:IsInRoom()
    return self._RoomData and not self._RoomData:IsClear()
end

function XDlcRoomModel:ClearRoomData()
    if not self:IsRoomDataEmpty() then
        self._RoomData:Clear()
    end
end

-- endregion

-- region ReJoinWorldData
function XDlcRoomModel:SetReJoinWorldData(worldInfo)
    if not self:IsReJoinDataEmpty() then
        self._ReJoinWorldData:SetData(worldInfo)
    else
        self._ReJoinWorldData = XDlcJoinWorldData.New(worldInfo)
    end
end

---@type XDlcJoinWorldData
function XDlcRoomModel:GetReJoinWorldData()
    return self._ReJoinWorldData
end

function XDlcRoomModel:ClearReJoinWorldData()
    if not self:IsReJoinDataEmpty() then
        self._ReJoinWorldData:Clear()
    end
end

function XDlcRoomModel:CheckCanRejoinWorld()
    return self._ReJoinWorldData and not self._ReJoinWorldData:IsClear()
end

function XDlcRoomModel:IsReJoinDataEmpty()
    return self._ReJoinWorldData == nil
end

-- endregion

-- region FightBeginData
---@return XDlcFightBeginData
function XDlcRoomModel:GetFightBeginData()
    if self:IsFightBeginDataEmpty() then
        self._FightBeginData = XDlcFightBeginData.New()
    end

    return self._FightBeginData
end

function XDlcRoomModel:IsFightBeginDataEmpty()
    return self._FightBeginData == nil
end

function XDlcRoomModel:ClearFightBeginData()
    if not self:IsFightBeginDataEmpty() then
        self._FightBeginData:Clear()
    end
end

function XDlcRoomModel:SetFightBeginWorldDataBySource(worldData)
    local beginData = self:GetFightBeginData()

    beginData:SetWorldDataBySource(worldData)
    self:_SyncRoomDataFromWorldData()
end

---@param roomData XDlcRoomData
function XDlcRoomModel:SetFightBeginRoomData(roomData)
    local beginData = self:GetFightBeginData()

    beginData:SetRoomData(roomData)
end

-- endregion

-- region JoinWorldData
---@return XDlcJoinWorldData
function XDlcRoomModel:GetJoinWorldDataByResponse(response)
    if self._JoinWorldData then
        self._JoinWorldData:SetData(response)
    else
        self._JoinWorldData = XDlcJoinWorldData.New(response)
    end

    return self._JoinWorldData
end

-- endregion

-- region Other

function XDlcRoomModel:SetIsMatching(value)
    self._IsMatching = value
end

function XDlcRoomModel:IsMatching()
    return self._IsMatching
end

function XDlcRoomModel:SetIsCancelingMatch(value)
    self._IsCancelingMatch = value
end

function XDlcRoomModel:IsCancelingMatch()
    return self._IsCancelingMatch
end

function XDlcRoomModel:SetIsFighting(value)
    self._IsFighting = value
end

function XDlcRoomModel:IsFighting()
    return self._IsFighting
end

function XDlcRoomModel:SetIsSettled(value)
    self._IsSettled = value
end

function XDlcRoomModel:IsSettled()
    return self._IsSettled
end

function XDlcRoomModel:SetIsReconnect(value)
    self._IsReconnect = value
end

function XDlcRoomModel:IsReconnect()
    return self._IsReconnect
end

function XDlcRoomModel:SetIsRebuildRoom(value)
    self._IsRebuildRoom = value
end

function XDlcRoomModel:IsRebuildRoom()
    return self._IsRebuildRoom
end

function XDlcRoomModel:SetIsLoginOut(value)
    self._IsLoginOut = value
end

function XDlcRoomModel:IsLoginOut()
    return self._IsLoginOut
end

function XDlcRoomModel:SetFocusType(focusType)
    self._FocusType = focusType
end

function XDlcRoomModel:GetFocusType()
    return self._FocusType
end

function XDlcRoomModel:IsNeedRevertFocusType()
    return self._FocusType ~= nil
end

function XDlcRoomModel:ClearFocusType()
    self._FocusType = nil
end

function XDlcRoomModel:ClearState()
    self._IsFighting = false
    self._IsCancelingMatch = false
    self._IsMatching = false
    self._IsReconnect = false
    self._IsRebuildRoom = false
    self._IsLoginOut = false
end

function XDlcRoomModel:ClearAll()
    self:ClearRoomData()
    self:ClearFocusType()
    self:ClearState()
end

-- endregion

-- region 邀请

function XDlcRoomModel:GetInviteChatDataList()
    return self._InviteChatDataList
end

function XDlcRoomModel:RecordingInviteChatData(chatData)
    if chatData then
        self:UpdateInviteChatDataList()
        self:RemoveInviteChatData(chatData.SenderId)
        
        table.insert(self._InviteChatDataList, chatData)
    end
end

function XDlcRoomModel:ClearInviteChatData()
    self._InviteChatDataList = {}
end

function XDlcRoomModel:UpdateInviteChatDataList()
    local chatDataList = self._InviteChatDataList

    self._InviteChatDataList = {}
    for i, inviteChat in pairs(chatDataList) do
        local createTime = inviteChat.CreateTime
        local nowTime = XTime.GetServerNowTimestamp()

        if createTime + self:GetInviteChatCacheTime() > nowTime then
            table.insert(self._InviteChatDataList, inviteChat)
        end
    end
end

function XDlcRoomModel:RemoveInviteChatData(senderId)
    if XTool.IsNumberValid(senderId) then
        local chatDataList = self._InviteChatDataList
        
        self._InviteChatDataList = {}
        for i, inviteChat in pairs(chatDataList) do
            if inviteChat.SenderId ~= senderId then
                table.insert(self._InviteChatDataList, inviteChat)
            end
        end
    end
end

function XDlcRoomModel:GetInviteShowTime()
    return self._InviteShowTime
end

function XDlcRoomModel:GetInviteChatCacheTime()
    return self._InviteChatCacheTime
end

-- endregion

-- region 匹配成功遮罩

function XDlcRoomModel:GetReadyEnterWorldMaskKey()
    return self._ReadyEnterWorldMaskKey
end

-- endregion 

-- region 私有方法

function XDlcRoomModel:_SyncRoomDataFromWorldData()
    local beginData = self:GetFightBeginData()
    local worldData = beginData:GetWorldData()

    if not self:IsRoomDataEmpty() then
        self._RoomData:SyncFromWorldData(worldData)
    end
end

-- endregion

return XDlcRoomModel
