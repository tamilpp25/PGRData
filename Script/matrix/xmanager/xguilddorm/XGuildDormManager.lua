local Quaternion = CS.UnityEngine.Quaternion
local Vector3 = CS.UnityEngine.Vector3
local XGuildDormNetwork = require("XEntity/XGuildDorm/XGuildDormNetwork")
local XGuildDormRoom = require("XEntity/XGuildDorm/Room/XGuildDormRoom")
--=================
--公会宿舍总管理器
--负责人：吕天元，陈思亮
--=================
XGuildDormManagerCreator = function()
    local GuildDormManager = {}
    local SubManagers = {}
    local DataInit = false
    local CurrentRoomId = 1
    local CurrentChannelIndex = 0
    local HideTalkUi = false -- 隐藏聊天Ui
    local HideNameUi = false -- 隐藏玩家名字Ui
    local IsRunning = false --公会宿舍是否正在打开
    local GuildDormNetwork = XGuildDormNetwork.New()
    local SyncMsgQueue = XQueue.New()
    --===============
    --获取资源管理器
    --===============
    local function GetResourceManager()
        if not SubManagers.Resource then
            SubManagers.Resource = require("XManager/XGuildDorm/XGuildDormResourceManager")
        end
        return SubManagers.Resource
    end
    GuildDormManager.ResourceManager = SubManagers.Resource or GetResourceManager()
    --===============
    --获取场景管理器
    --===============
    local function GetSceneManager()
        if not SubManagers.Scene then
            SubManagers.Scene = require("XManager/XGuildDorm/XGuildDormSceneManager")
        end
        return SubManagers.Scene
    end
    GuildDormManager.SceneManager = SubManagers.Scene or GetSceneManager()
    --===============
    --获取网格管理器
    --===============
    local function GetMapGridManager()
        if not SubManagers.MapGrid then
            SubManagers.MapGrid = require("XManager/XGuildDorm/XGuildDormMapGridManager")
        end
        return SubManagers.MapGrid
    end
    GuildDormManager.MapGridManager = SubManagers.MapGrid or GetMapGridManager()
    --网络协议名枚举
    local METHOD_NAME = {
            EnterDorm = "",
        }
    --==============
    --RoomData房间数据
    --==============
    local RoomData
    --==============
    --roomId:
    --不传入房间Id返回全部房间数据
    --传入房间Id返回该房间数据
    --==============
    function GuildDormManager.GetRoomData(roomId)
        if not RoomData then RoomData = {} end
        if not roomId then return RoomData end
        return RoomData[roomId]
    end
    --==============
    --roomId:
    --不传入房间Id表示data是全部房间数据，将替换原有RoomData
    --传入房间Id表示data是该房间数据，将更新RoomData中该房间Id的数据
    --==============
    local function SetRoomData(data, roomId)
        if data and not roomId then
            RoomData = data
        elseif data and roomId then
            if not RoomData then RoomData = {} end
            if not RoomData[roomId] then
                RoomData[roomId] = data
            else
                RoomData[roomId]:SetData(data)
            end
        end
    end
    --==============
    --SceneName场景名称 -> 所属所有房间数据列表
    --==============
    local SceneName2RoomDataDic
    function GuildDormManager.GetSceneName2RoomDataDic(sceneName)
        if not SceneName2RoomDataDic then SceneName2RoomDataDic = {} end
        return SceneName2RoomDataDic[sceneName]
    end
    function GuildDormManager.SetSceneName2RoomDataDic(data, sceneName)
        if not data then return end
        if not SceneName2RoomDataDic then SceneName2RoomDataDic = {} end
        if not SceneName2RoomDataDic[sceneName] then
            SceneName2RoomDataDic[sceneName] = {}
        end
        SceneName2RoomDataDic[sceneName][data.Id] = data
    end
    local DormData = nil -- XGuildDormRoomData 整个公会宿舍房间服务器数据
    --==============
    --ChannelData当前房间频道数据
    --==============    
    local ChannelDatas = nil
    --==============
    --Get/Set
    --==============
    function GuildDormManager.GetChannelDatas()
        if not ChannelDatas then return {} end
        return ChannelDatas
    end
    local function SetChannelDatas(data)
        ChannelDatas = data
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_CHANNEL_DATA_REFRESH)
    end
    --=============
    --bool
    --初始化管理器标记，true已初始化管理器，false没有初始化
    --=============
    local Initial_Complete_Flag = false
    --=============
    --检查管理器是否不需要初始化
    --=============
    local function CheckNoNeedInitial()
        return false
    end
    --=============
    --初始化玩家数据
    --无论管理器是否需要初始化，数据也需在登陆时初始化
    --=============
    local function InitData()
        RoomData = {}
        SceneName2RoomDataDic = {}
        ChannelDatas = nil
        DataInit = false    
        IsRunning = false
    end
    --=============
    --初始化
    --=============
    local function Init()
        InitData()
        Initial_Complete_Flag = false
        if CheckNoNeedInitial() then
            return
        end
        Initial_Complete_Flag = true
        GuildDormNetwork:InitTimeConfig()
    end
    --=============
    --初始化房间数据
    --=============
    local function InitRoomDataOnFirst()
        if DataInit then return end
        local allRoomCfgs = XGuildDormConfig.GetAllConfigs(XGuildDormConfig.TableKey.Room)
        local XRoomData = require("XEntity/XGuildDorm/Datas/XGuildDormRoomData")
        for id, cfg in pairs(allRoomCfgs or {}) do
            local data = XRoomData.New(cfg)
            SetRoomData(data, id)
            GuildDormManager.SetSceneName2RoomDataDic(data, cfg.SceneName)
        end
        DataInit = true
    end
    --=============
    --根据公会宿舍数据解锁房间信息
    --=============
    local function SetRoomOpenList(roomList)
        for _, data in pairs(roomList or {}) do
            local roomData = GuildDormManager.GetRoomData[data.Id]
            if roomData then
                roomData.IsUnlock = true
            end
        end
    end
    --=============
    --根据公会宿舍数据初始化宿舍内部家具数据
    --=============
    local function SetRoomFurnitureData(furnitureList)
        --[[
        if not furnitureList or not next(furnitureList) then
            return
        end
        for _, data in pairs(furnitureList) do
            local roomData = GuildDormManager.GetRoomData[data.Id]
            if roomData then
                roomData:AddFurniture(data.Id, data.ConfigId, data.X, data.Y, data.Angle)
            end
        end
        ]]
    end
    --=============
    --请求进入公会宿舍
    --=============
    local function OnReceiveGuildDormData(data, cb)
        InitRoomDataOnFirst()
        SetRoomOpenList(data.DormitoryList)
        SetRoomFurnitureData(data.FurnitureList)
    end
    --=============
    --请求进入公会宿舍
    --=============
    local function RequestEnterGuildDorm(cb)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.EnterDorm, {},
            function(reply)
                GuildDormManager.OnRefreshDormData(reply.DormData)
                if cb then
                    cb()
                end
            end)
    end
    --==============
    --开始进入场景
    --==============
    function GuildDormManager.StartGuildDorm(onLoadCompleteCb, onExitCb, onLoadingStart)
        --①初始化地图网格(第一期暂时不需要网格)
        --GuildDormManager.MapGridManager.InitMapGrid()
        --②加载首个场景
        --修改全局光照
        CS.XGlobalIllumination.SetSceneType(CS.XSceneType.Dormitory)
        --获取首场景名与地址
        local sceneName = CS.XGame.ClientConfig:GetString("GuildDormMainSceneName")
        local scenePrefabPath = CS.XGame.ClientConfig:GetString("GuildDormMainScenePrefabPath")
        --进入场景
        GuildDormManager.SceneManager.EnterScene(sceneName, scenePrefabPath, nil, onLoadCompleteCb, onExitCb, onLoadingStart)
    end
    --==============
    --退出公会场景
    --==============
    function GuildDormManager.ExitGuildDorm()
        GuildDormManager.SceneManager.ExitGuildDorm()
        --GuildDormManager.MapGridManager.CollectMapGrid()
    end
    --=============
    --检查能否进入宿舍
    --=============
    function GuildDormManager.CheckCanEnterGuildDorm()
        --todo
        return true
    end
    --=============
    --获取当前房间
    --=============
    function GuildDormManager.GetCurrentRoom()
        if GuildDormManager.SceneManager.GetCurrentScene() == nil then
            return nil
        end
        return GuildDormManager.SceneManager.GetCurrentScene():GetCurrentRoom()
    end
    --=============
    --重新生成当前房间的导航障碍
    --=============
    function GuildDormManager.ResetRoomNavmeshObstacle()
        local room = GuildDormManager.GetCurrentRoom()
        if not room then return end
        room:ResetNavmeshObstacle()
    end
    --=============
    --获取当前房间所有玩家数据
    --=============
    function GuildDormManager.GetPlayerDatas()
        return DormData.PlayerDatas
    end
    --=============
    --增加当前房间所有玩家数据
    --=============
    function GuildDormManager.AddPlayerData(value)
        for i = #DormData.PlayerDatas, 1, -1 do
            if DormData.PlayerDatas[i].PlayerId == value.PlayerId then
                return
            end
        end
        table.insert(DormData.PlayerDatas, value)
    end
    --=============
    --获取玩家名字
    --=============
    function GuildDormManager.GetPlayerName(playerId)
        for i = #DormData.PlayerDatas, 1, -1 do
            if DormData.PlayerDatas[i].PlayerId == playerId then
                return DormData.PlayerDatas[i].PlayerName
            end
        end
    end
    --=============
    --删除当前房间所有玩家数据
    --=============
    function GuildDormManager.DeletePlayerDataById(id)
        for i = #DormData.PlayerDatas, 1, -1 do
            if DormData.PlayerDatas[i].PlayerId == id then
                table.remove(DormData.PlayerDatas, i)
                return
            end
        end
    end
    --=============
    --获取当前房间所有家具数据
    --=============
    function GuildDormManager.GetFurnitureDatas()
        return DormData.FurnitureDatas
    end
    --=============
    --根据玩家id获取正在交互的家具数据
    --=============
    function GuildDormManager.GetFurnitureDataByPlayerId(playerId)
        if DormData == nil then return end
        for _, data in ipairs(DormData.FurnitureDatas) do
            if data.PlayerId == playerId then
                return data
            end
        end
    end
    --=============
    --更新当前房间所有家具数据
    --=============
    function GuildDormManager.UpdateFurnitureDatas(datas)
        local data2IndexDic = {}
        for i, data in ipairs(DormData.FurnitureDatas) do
            data2IndexDic[data.Id] = i
        end
        local index
        for _, data in ipairs(datas) do
            index = data2IndexDic[data.Id]
            if index then
                DormData.FurnitureDatas[index] = data
            else
                table.insert(DormData.FurnitureDatas, data)
            end
        end
    end
    --=============
    --请求接口
    --=============
    function GuildDormManager.RequestPreEnter(roomId, channelId, callback)
        XNetwork.Call("GuildDormPreEnterRequest", {
            RoomId = roomId,
            ChannelId = channelId,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if callback then callback(false) end
                return
            end
            GuildDormNetwork.IpAddress = res.ConnectData.IpAddress
            GuildDormNetwork.TcpPort = res.ConnectData.TcpPort
            GuildDormNetwork.Token = res.ConnectData.Token
            if callback then callback(true) end
        end)
    end

    function GuildDormManager.RequestEnter(callback)
        GuildDormNetwork:Call("GuildDormEnterRoomRequest", {
            PlayerId = XPlayer.Id,
            Token = GuildDormNetwork.Token,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if callback then callback(false) end
                return
            end
            GuildDormNetwork.KcpPort = res.Port
            GuildDormNetwork.KcpConv = res.Conv
            DormData = res.RoomData
            XLog.Debug("========= DormData", DormData)
            if callback then callback(true) end
        end, false)
    end

    function GuildDormManager.RequestExitRoom(cb)
        -- 这个接口服务器收到后默认断开连接，所以回调也没有执行
        GuildDormNetwork:Call("GuildDormExitRoomRequest", {})
        if cb then
            cb()
        end
    end

    function GuildDormManager.RequestChangeRoleId(roleId, callback)
        local currentRoom = GuildDormManager.GetCurrentRoom()
        local role = currentRoom:GetRoleByPlayerId(XPlayer.Id)
        -- 交互中不可以切换角色
        if role:GetIsInteracting() then
            XUiManager.TipErrorWithKey("GuildDormRoleInteracting")
            return
        end
        -- 播放动作中不可以切换角色
        if role:GetIsPlayingAction() then
            XUiManager.TipErrorWithKey("GuildDormRolePlayingAction")
            return
        end
        GuildDormNetwork:Call("GuildDormChangeCharacterRequest", {
            CharacterId = roleId
        }, function(res)
            local currentRoom = GuildDormManager.GetCurrentRoom()
            if currentRoom == nil then return end
            local role = currentRoom:GetRoleByPlayerId(XPlayer.Id)
            role:UpdateRoleId(roleId)
            if callback then callback() end
        end)
    end

    function GuildDormManager.RequestPlayAction(actionId)
        local currentRoom = GuildDormManager.GetCurrentRoom()
        local role = currentRoom:GetRoleByPlayerId(XPlayer.Id)
        -- 交互中不播放动作
        if role:GetIsInteracting() then
            XUiManager.TipErrorWithKey("GuildDormRoleInteracting")
            return
        end
        GuildDormNetwork:RequestPlayAction(actionId)
    end

    function GuildDormManager.Dispose()
        GuildDormNetwork:Disconnect()
        --销毁房间，场景等会在公会宿舍主界面销毁时销毁
        IsRunning = false
    end

    function GuildDormManager.RequestSyncPlayerState(x, z, angle, state)
        GuildDormNetwork:RequestSyncPlayerState(x, z, angle, state)
    end

    function GuildDormManager.RequestFurnitureInteract(furnitureId, callback)
        GuildDormNetwork:Call("GuildDormFurnitureInteractRequest", {
            FurnitureId = furnitureId,
        }, function(res)
            if callback then callback() end
        end)
    end

    function GuildDormManager.RequestRoomChannelData(callback)
        XNetwork.CallWithAutoHandleErrorCode("GuildDormRoomChannelDataRequest", {
            RoomId = CurrentRoomId,
        }, function(res)
            SetChannelDatas(res.ChannelDatas)
            if callback then callback() end
        end)
    end

    function GuildDormManager.RequestLoadRoom(roomId, channelIndex, callback)
        if roomId == nil then roomId = CurrentRoomId end
        if channelIndex == nil then channelIndex = CurrentChannelIndex end
        local timer = GuildDormManager.__NetworkUpdateTimer
        if timer then
            XScheduleManager.UnSchedule(timer)
            timer = nil
        end
        local csNetwork = GuildDormNetwork:GetCsNetwork()
        GuildDormManager.__NetworkUpdateTimer = XScheduleManager.ScheduleForever(function()
            csNetwork:Update()
        end, 1, 0)
        local guildDormManager = GuildDormManager
        local asyncPreEnter = asynTask(function(cb)
            guildDormManager.RequestPreEnter(roomId, channelIndex, function(res)
                if not res then 
                    if callback then callback(XGuildDormConfig.ErrorCode.PreEnterFailed) end
                    return
                end
                if callback then callback(XGuildDormConfig.ErrorCode.PreEnterSuccess) end
                if cb then cb() end
            end)
        end)
        local asyncConnectTcp = asynTask(function(cb)
            local ip = GuildDormNetwork.IpAddress
            local tcpPort = GuildDormNetwork.TcpPort
            csNetwork:Connect(ip, tcpPort, function(res)
                if not res then 
                    if callback then callback(XGuildDormConfig.ErrorCode.TCPFailed) end
                    return 
                end
                if cb then cb() end
            end)
        end)
        local asyncEnter = asynTask(function(cb)
            guildDormManager.RequestEnter(function(res)
                if not res then 
                    if callback then callback(XGuildDormConfig.ErrorCode.EnterFailed) end
                    return 
                end
                if cb then cb() end
            end)
        end)
        local asyncConnectKcp = asynTask(function(cb)
            local ip = GuildDormNetwork.IpAddress
            local kcpPort = GuildDormNetwork.KcpPort
            local kcpConv = GuildDormNetwork.KcpConv
            csNetwork:ConnectKcp(ip, kcpPort, kcpConv, function(res)
                if not res then
                    if callback then callback(XGuildDormConfig.ErrorCode.KCPFailed) end
                    return 
                end
         
            if cb then cb() end
            end)
        end)
        RunAsyn(function()
            XLog.Debug("========== 开始预先进入房间")
            -- 请求进入公会宿舍
            asyncPreEnter()
            -- 更新当前房间和频道，这里主要是为了重连时的记录
            CurrentRoomId = roomId
            CurrentChannelIndex = channelIndex
            XLog.Debug("========== 开始连接TCP")
            -- 连接TCP
            asyncConnectTcp()
            -- 这里直接标记TCP处理重连完成，才能真正发TCP消息
            csNetwork.IsHandleReconnectionComplete = true
            XLog.Debug("========== 开始真正进入房间")
            -- 进入房间，获取KCP连接信息
            asyncEnter()
            -- 这里重新设置为了获取服务器真正的进入的频道
            CurrentChannelIndex = DormData.ChannelId or 0
            XLog.Debug("========== 开始做心跳和连接KCP")
            -- 连接KCP
            asyncConnectKcp()
            XLog.Debug("========== 连接KCP完成")
            -- 放到下一帧跑，主要是为了显示报错信息
            XScheduleManager.ScheduleOnce(function()
                if callback then callback(XGuildDormConfig.ErrorCode.Success) end
                -- 做心跳
                GuildDormNetwork:RequestHeartbeat()
            end, 1)
        end)
    end

    -- 处理重连成功后的操作
    function GuildDormManager.HandleReConnectSuccess()
        local currentRoom = GuildDormManager.GetCurrentRoom()
        if currentRoom and currentRoom:GetIsInit() then
            -- 更新所有玩家最新的位置 
            currentRoom:UpdateRolesPosition()
            -- 检查交互状态, 避免断线时取消交互失败
            local role = currentRoom:GetRoleByPlayerId(XPlayer.Id)
            local furnitureDatas = GuildDormManager.GetFurnitureDatas()
            for _, furnitureData in ipairs(furnitureDatas) do
                if furnitureData.PlayerId == XPlayer.Id then
                    if role:GetInteractStatus() == XGuildDormConfig.InteractStatus.End then
                        XDataCenter.GuildDormManager.RequestFurnitureInteract(-1)
                    end
                    break
                end
            end
        else
            GuildDormManager.StartGuildDorm(function()
                -- 加载角色
                currentRoom:CreateRoles(GuildDormManager.GetPlayerDatas()
                    , currentRoom:GetCharacterRoot())
                -- 打开共用组件管理
            end, function() GuildDormManager.Dispose() end)
        end
    end

    -- 获取角色数据，从宿舍管理器中获取
    function GuildDormManager.GetCharacterDatas(dormCharacterIndex)
        local sexConditionDic
        if dormCharacterIndex > 0 then
            sexConditionDic = table.arrayToDic({ XDormConfig.GetDormCharacterType(dormCharacterIndex) })
        end
        local result = {}
        local characterDataDic = XDataCenter.DormManager.GetCharacterData()
        local sex
        local currentRoleId = GuildDormManager.GetCurrentPlayerRoleId()
        for _, value in pairs(characterDataDic) do
            sex = XDormConfig.GetCharacterStyleConfigSexById(value.CharacterId)
            if sexConditionDic == nil or sexConditionDic[sex] then
                if value.CharacterId ~= currentRoleId then
                    table.insert(result, value)
                end
            end
        end
        table.sort(result, function(a, b)
            if a.DormitoryId < 0 or b.DormitoryId < 0 then
                return a.DormitoryId < b.DormitoryId
            elseif a.DormitoryId > 0 or b.DormitoryId > 0 then
                return a.CharacterId < b.CharacterId
            end
            return false
        end)
        if currentRoleId > 0 then
            sex = XDormConfig.GetCharacterStyleConfigSexById(currentRoleId)
            if sexConditionDic == nil or sexConditionDic[sex] then
                table.insert(result, 1, characterDataDic[currentRoleId])
            end
        end
        return result
    end

    function GuildDormManager.GetCurrentPlayerRoleId()
        local currentRoom = GuildDormManager.GetCurrentRoom()
        if currentRoom == nil then return 0 end
        local role = currentRoom:GetRoleByPlayerId(XPlayer.Id)
        if role == nil then return 0 end
        return role:GetId()
    end

    function GuildDormManager.GetCurrentChannelIndex()
        return CurrentChannelIndex
    end

    function GuildDormManager.GetCurrentRoomId()
        return CurrentRoomId
    end

    function GuildDormManager.GetMemberCountByChannelIndex(index)
        if ChannelDatas == nil then return 0 end
        for _, data in ipairs(ChannelDatas) do
            if data.ChannelId == index then
                return data.MemberCount
            end
        end
        return 0
    end

    function GuildDormManager.SwitchChannel(channelIndex, callback)
        -- 相同频道不需要处理
        if CurrentChannelIndex == channelIndex then
            callback(true)
            return
        end
        GuildDormManager.RequestLoadRoom(CurrentRoomId, channelIndex, function(errorCode)
            -- 切换频道预先进入房间成功后断开连接
            if errorCode == XGuildDormConfig.ErrorCode.PreEnterSuccess then
                GuildDormNetwork:Disconnect()
            elseif errorCode == XGuildDormConfig.ErrorCode.Success then
                -- 这里开始正式走切换频道的流程
                local currentRoom = GuildDormManager.GetCurrentRoom()
                currentRoom:DisposeWithoutGo()
                -- 加载角色
                currentRoom:CreateRoles(GuildDormManager.GetPlayerDatas()
                    , currentRoom:GetCharacterRoot())
                if callback then callback(true) end
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_SWITCH_CHANNEL)
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_CANCEL_INTERACT_BTN_SHOW, false, XPlayer.Id)
            -- 预先进入房间失败了，不处理
            elseif errorCode == XGuildDormConfig.ErrorCode.PreEnterFailed then
                if callback then callback(false) end
            elseif errorCode == XGuildDormConfig.ErrorCode.TCPFailed
                or errorCode == XGuildDormConfig.ErrorCode.KCPFailed then
                GuildDormManager.Dispose()
                XLuaUiManager.RunMain()
            else
                GuildDormManager.Dispose()
                XLuaUiManager.RunMain()
            end
        end)
    end

    function GuildDormManager.SetIsHideTalkUi(value)
        HideTalkUi = value
    end

    function GuildDormManager.GetIsHideTalkUi()
        return HideTalkUi
    end

    function GuildDormManager.SetIsHideNameUi(value)
        HideNameUi = value
    end

    function GuildDormManager.GetIsHideNameUi()
        return HideNameUi
    end

    function GuildDormManager.HandleSyncEntities(data)
        local currentRoom = GuildDormManager.GetCurrentRoom()
        local role = nil
        -- XGuildDormRoomPosition
        local syncData = nil
        local transform = nil
        -- debug 满员角色情况
        if XGuildDormConfig.DebugFullRole then
            local testPlayerData
            for _, v in ipairs(data.PlayerDatas) do
                if v.PlayerId == XPlayer.Id then
                    testPlayerData = v
                    break
                end
            end
            if testPlayerData then
                local allCharacterDatas = XDataCenter.GuildDormManager.GetCharacterDatas(0)
                for i = 1, XGuildDormConfig.DebugFullRoleCount do
                    local testAddPlayerData = XTool.Clone(testPlayerData)
                    testAddPlayerData.PlayerId = testAddPlayerData.PlayerId .. i
                    testAddPlayerData.CharacterId = allCharacterDatas[i].CharacterId
                    table.insert(data.PlayerDatas, testAddPlayerData)
                end
            end
        end
        for _, playerData in ipairs(data.PlayerDatas) do
            if XPlayer.Id ~= playerData.PlayerId then
                role = currentRoom:GetRoleByPlayerId(playerData.PlayerId)
                if role == nil then 
                    GuildDormManager.AddPlayerData(playerData)
                    role = currentRoom:CreateRole(playerData, currentRoom:GetCharacterRoot())
                end
                syncData = playerData.Position
                if syncData then
                    transform = role:GetRLRole():GetTransform()
                    local position = Vector3(syncData.X, role:GetRLRole():GetSkinWidth(), syncData.Y)
                    local eulerAngles = transform.rotation.eulerAngles
                    local rotation = Quaternion.Euler(
                        Vector3(eulerAngles.x, syncData.Angle, eulerAngles.z))
                    local component = role:GetComponent("XGDSyncToClientComponent")
                    component:UpdateCurrentSyncData(position, rotation, playerData.State)
                end
                if playerData.CharacterId and playerData.CharacterId ~= role:GetId() then
                    role:UpdateRoleId(playerData.CharacterId)
                end
            end
        end
    end

    function GuildDormManager.HandleSyncPlayAction(data)
        local currentRoom = GuildDormManager.GetCurrentRoom()
        local role = currentRoom:GetRoleByPlayerId(data.PlayerId)
        if role == nil then return end
        role:StopPlayAction()
        role:UpdatePlayActionId(data.ActionId)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_PLAY_ACTION
            , data.PlayerId, data.ActionId)
    end

    function GuildDormManager.HandleSyncPlayerExit(data)
        local currentRoom = GuildDormManager.GetCurrentRoom()
        GuildDormManager.DeletePlayerDataById(data.PlayerId)
        currentRoom:DeleteRole(data.PlayerId)
    end

    function GuildDormManager.HandleSyncFurniture(data)
        local currentRoom = GuildDormManager.GetCurrentRoom()
        for _, value in ipairs(data.FurnitureDatas) do
            local role
            if value.PlayerId <= 0 then
                role = currentRoom:GetRoleByFurnitureId(value.Id)
                if role then
                    role:StopInteract()
                end
            else
                role = currentRoom:GetRoleByPlayerId(value.PlayerId)
                if role then
                    role:BeginInteract(value.Id)
                    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ROLE_INTERACT_BEGIN, value.PlayerId)
                end
            end
        end
        GuildDormManager.UpdateFurnitureDatas(data.FurnitureDatas)
    end

    local IsHaveTempError = false
    function GuildDormManager.TempErrorHandleFunc()
        CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_UIDIALOG_VIEW_ENABLE, GuildDormManager.TempErrorHandleFunc)
        GuildDormManager.Dispose()
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.Remove("UiSystemDialog")
            XLuaUiManager.Open("UiDialog", nil, XUiHelper.GetText("GuildDormNetworkTimeOutTip"), XUiManager.DialogType.Normal, nil, function()
                XDataCenter.GuildManager.EnterGuild()
            end)
        end, 1)
        IsHaveTempError = true
    end

    function GuildDormManager.GetIsHaveTempError()
        return IsHaveTempError
    end

    --==============
    --进入房间
    --==============
    function GuildDormManager.EnterGuildDorm(roomId, channelIndex, onLoadingStart, afterEnterMain)
        if IsRunning then
            XLuaUiManager.Open("UiGuildDormMain")
            return
        end
        if not XDataCenter.GuildManager.IsJoinGuild() then
            if XDataCenter.GuildManager.IsNeedRequestRecommendData() then
                XDataCenter.GuildManager.GuildListRecommendRequest(1, function()
                        XLuaUiManager.Open("UiGuildRecommendation")
                    end)
            else
                XLuaUiManager.Open("UiGuildRecommendation")
            end
            return
        end
        --先请求最新的公会数据，再执行Loading
        local func = function()
            LuaGC()
            if roomId == nil then roomId = 1 end
            if channelIndex == nil then channelIndex = 0 end
            -- 因服务器超时错误在c#中处理，lua在这里通过临时注册事件处理
            if IsHaveTempError then
                XDataCenter.GuildManager.EnterGuild()
                return
            end
            CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_UIDIALOG_VIEW_ENABLE
                , GuildDormManager.TempErrorHandleFunc)
            GuildDormManager.RequestLoadRoom(roomId, channelIndex, function(errorCode)
                CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_UIDIALOG_VIEW_ENABLE, GuildDormManager.TempErrorHandleFunc)
                if errorCode == XGuildDormConfig.ErrorCode.Success then
                    GuildDormManager.StartGuildDorm(function()
                        local currentRoom = GuildDormManager.GetCurrentRoom()
                        -- 加载角色
                        currentRoom:CreateRoles(GuildDormManager.GetPlayerDatas()
                            , currentRoom:GetCharacterRoot())
                        -- 打开共用组件管理
                        --XLuaUiManager.Open("UiGuildDormCommon")
                        IsRunning = true
                        if afterEnterMain then
                            afterEnterMain()
                        end
                    end, function()
                        GuildDormManager.Dispose()
                    end, onLoadingStart)
                elseif errorCode == XGuildDormConfig.ErrorCode.TCPFailed
                    or errorCode == XGuildDormConfig.ErrorCode.KCPFailed then
                    -- GuildDormNetwork:StartReconnect()
                    XDataCenter.GuildManager.EnterGuild()
                    GuildDormManager.Dispose()
                elseif errorCode == XGuildDormConfig.ErrorCode.PreEnterFailed
                    or errorCode == XGuildDormConfig.ErrorCode.EnterFailed then
                    XDataCenter.GuildManager.EnterGuild()
                    GuildDormManager.Dispose()
                end
            end)
        end
        XDataCenter.GuildManager.GetGuildDetails(0, func)       
    end
    --================
    --允许场景相机缩放功能
    --================
    function GuildDormManager.AllowCameraZoom(value)
        local cameraController = GuildDormManager.SceneManager.GetCurrentScene():GetCameraController()
        cameraController.AllowZoom = value
    end
    --================
    --允许在双点触碰时检索第二点触碰旋转镜头
    --================
    function GuildDormManager.AllowTouch1ForAxis(value)
        local cameraController = GuildDormManager.SceneManager.GetCurrentScene():GetCameraController()
        cameraController.AllowTouch1ForAxis = value
    end

    function GuildDormManager.GetSyncMsgQueue()
        return SyncMsgQueue
    end

    function GuildDormManager.GetGuildDormNetwork()
        return GuildDormNetwork
    end

    --require时运行初始化
    Init()
    --初始化房间数据
    InitRoomDataOnFirst()
    --GuildDormManager.TestSceneManagerFunc()
    --GuildDormManager.TestResourceManagerFunc()
    return GuildDormManager 
end

XRpc.NotifyGuildDormSyncEntities = function(data)
    if XGuildDormConfig.DebugNetworkDelay then
        if XDataCenter.GuildDormManager.__DebugDelayQueue == nil then
            XDataCenter.GuildDormManager.__DebugDelayQueue = XQueue.New()
        end
        local currentDelayTime = XTool.Random(XGuildDormConfig.DebugNetworkDelayMin
            , XGuildDormConfig.DebugNetworkDelayMax)
        XDataCenter.GuildDormManager.__DebugDelayQueue:Enqueue({
            data = data,
            Time = CS.UnityEngine.Time.realtimeSinceStartup + currentDelayTime / 1000
        })
        return
    end
    local queue = XDataCenter.GuildDormManager.GetSyncMsgQueue()
    queue:Enqueue({ Data = data, SyncType = XGuildDormConfig.SyncMsgType.Entities })
end

XRpc.NotifyGuildDormPlayerExit = function(data)
    local queue = XDataCenter.GuildDormManager.GetSyncMsgQueue()
    queue:Enqueue({ Data = data, SyncType = XGuildDormConfig.SyncMsgType.PlayerExit })
end

XRpc.NotifyGuildDormPlayAction = function(data)
    local queue = XDataCenter.GuildDormManager.GetSyncMsgQueue()
    queue:Enqueue({ Data = data, SyncType = XGuildDormConfig.SyncMsgType.PlayAction })
end

XRpc.NotifyGuildDormSyncFurniture = function(data)
    local queue = XDataCenter.GuildDormManager.GetSyncMsgQueue()
    queue:Enqueue({ Data = data, SyncType = XGuildDormConfig.SyncMsgType.Furniture })
end