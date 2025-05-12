local Quaternion = CS.UnityEngine.Quaternion
local Vector3 = CS.UnityEngine.Vector3
local XGuildDormNetwork = require("XEntity/XGuildDorm/XGuildDormNetwork")
local XGuildDormRoom = require("XEntity/XGuildDorm/Room/XGuildDormRoom")
--=================
--公会宿舍总管理器
--负责人：吕天元，陈思亮
--=================
XGuildDormManagerCreator = function()
    ---@class GuildDormManager
    local GuildDormManager = {}
    local SubManagers = {}
    local DataInit = false
    local CurrentRoomId = 1
    local CurrentChannelIndex = 0
    local HideTalkUi = false -- 隐藏聊天Ui
    local HideNameUi = false -- 隐藏玩家名字Ui
    local HideUi = false -- 隐藏Ui(不包括摇杆，交互)
    local HideOtherPlayers = false -- 隐藏其他玩家
    local HideOwnPlayer = false --隐藏自己
    local WhiteEntityIdNameDic = {}
    local IsRunning = false --公会宿舍是否正在打开
    local IsGuildSceneCDMusicMute = false --公会宿舍音乐播放器是否禁用
    local TempMuteBgmInfo = nil
    local LastWantToPlayButMuteBgmCfgId -- 被禁用拦截的Bgm
    ---@type XGuildDormNetwork
    local GuildDormNetwork = XGuildDormNetwork.New()
    local SyncMsgQueue = XQueue.New()
    local IsHaveTempError = false
    local RemaindRewardCount = 0
    local BgmAudioInfo = nil --公会宿舍背景音乐
    local BgmId = 0
    local BgmQueue = XQueue.New()
    local BgmTimer
    local IsShowUiGuildDormCommon = false
    local UiCommonSortingOrder = 49 --默认SortingOrder
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
    ---@type XGuildDormSceneManager
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
    ---@type XGuildDormRoomData
    local DormData = nil -- XGuildDormRoomData 整个公会宿舍房间服务器数据
    local NpcDataCache={}
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
        XUiHelper.SetSceneType(CS.XSceneType.Dormitory)
        --获取首场景名与地址
        --todo aafasou 根据主题换场景
        local themeCfg = GuildDormManager.GetThemeCfg()
        local sceneName = themeCfg.SceneName
        local scenePrefabPath = themeCfg.ScenePath
        --进入场景
        GuildDormManager.SceneManager.EnterScene(sceneName, scenePrefabPath, nil, onLoadCompleteCb, onExitCb, onLoadingStart)
    end
    --==============
    --退出公会场景
    --==============
    function GuildDormManager.ExitGuildDorm()
        GuildDormManager.SceneManager.ExitGuildDorm()
        GuildDormManager.StopBgm()
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
    --获取当前房间主题
    --=============
    function GuildDormManager.GetThemeId()
        if not DormData then
            return 0
        end

        return DormData.ThemeId or 1
    end
    --=============
    --获取当前房间背景音乐列表
    --=============
    function GuildDormManager.GetBgmIds()
        return DormData.BgmIds
    end
    -- 获取当前房间Npc组Id
    function GuildDormManager.GetNpcGroupId()
        return DormData.NpcGroupId or 0
    end
    --=============
    --获取当前房间主题配置
    --=============
    function GuildDormManager.GetThemeCfg()
        return XGuildDormConfig.GetThemeCfgById(GuildDormManager.GetThemeId())
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
        end, nil, function(ex)
            XLuaUiManager.SetAnimationMask("GuildDormManager.RequestLoadRoom", false)
            XLuaUiManager.Open("UiDialog", nil, XUiHelper.GetText("GuildDormNetworkTimeOutTip"), XUiManager.DialogType.Normal, nil, function()
                if callback then callback(false) end
            end)
            IsHaveTempError = true
        end, function()
            XLuaUiManager.SetAnimationMask("GuildDormManager.RequestLoadRoom", false)
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
            if not XTool.IsTableEmpty(DormData.NpcDatas) then
                for i, npcData in ipairs(DormData.NpcDatas) do
                    GuildDormManager.UpdateNpcData(npcData)
                end
            end
            BgmQueue:Clear()
            for _,bgmId in pairs(DormData.BgmIds) do
                BgmQueue:Enqueue(bgmId)
            end
            BgmId = DormData.BgmIds[1] or 0
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

    function GuildDormManager.GetIsRunning()
        return IsRunning
    end

    -- function GuildDormManager.RequestSyncPlayerState(x, z, angle, state)
    --     GuildDormNetwork:RequestSyncPlayerState(x, z, angle, state)
    -- end

    function GuildDormManager.RequestFurnitureInteract(furnitureId, callback)
        GuildDormNetwork:Call("GuildDormFurnitureInteractRequest", {
            FurnitureId = furnitureId,
        }, function(res)
            if callback then callback() end
        end)
    end

    function GuildDormManager.GuildDormPlayNoteRequest(intNote, callback)
        if not XTool.IsNumberValid(intNote) then
            return
        end

        GuildDormNetwork:Call("GuildDormPlayNoteRequest", {
            Note = intNote,
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
    
    function GuildDormManager.RequestSetRoomTheme(themeId, callback)
        XNetwork.Call("GuildDormSetRoomThemeRequest",{
            RoomId = CurrentRoomId,
            ThemeId = themeId
        },function(res)
            if res.Code == XCode.GuildGdSetThemeInCd then
                local offset = res.NextSetRoomThemeTime - XTime.GetServerNowTimestamp()
                local timeStr = XUiHelper.GetTime(offset)
                XUiManager.TipMsg(CS.XTextManager.GetText("GuildDormSetThemeCd",timeStr))
                return
            end
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if callback then callback() end
        end)
    end

    function GuildDormManager.RequestGetDailyInteractReward(callback)
        XNetwork.Call("GuildDormGetDailyInteractRewardRequest", { }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if callback then callback(false) end
                return
            end
            if callback then callback(true, res.RewardGoodsList) end
            RemaindRewardCount = math.max(RemaindRewardCount - 1, 0)
        end)
    end

    function GuildDormManager.RequestLoadRoom(roomId, channelIndex, inCallback)
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
        XLuaUiManager.SetAnimationMask("GuildDormManager.RequestLoadRoom", true, 0)
        local callback = function(errorCode)
            if errorCode ~= XGuildDormConfig.ErrorCode.PreEnterSuccess then
                XLuaUiManager.SetAnimationMask("GuildDormManager.RequestLoadRoom", false)
            end
            if inCallback then inCallback(errorCode) end
        end
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
            csNetwork:Connect(ip, tcpPort, function(tcpErrorCode)
                if tcpErrorCode ~= XGuildDormConfig.TcpErrorCode.OK then 
                    if tcpErrorCode == XGuildDormConfig.TcpErrorCode.Error then
                        if callback then callback(XGuildDormConfig.ErrorCode.TCPFailed) end
                    elseif tcpErrorCode == XGuildDormConfig.TcpErrorCode.RemoteDisconnect then
                        -- PS:如果后期需要关服对玩家踢出的处理，可以走这个错误码判断，
                        -- 但需要验证和过滤掉TcpErrorCode.RemoteDisconnect枚举中列出的可能性
                        local dict = {}
                        dict["error_code"] = XGuildDormConfig.ErrorCode.RemoteDisconnect
                        CS.XRecord.Record(dict, "200018", "GuildDormNetwork")
                        if callback then callback(XGuildDormConfig.ErrorCode.RemoteDisconnect) end
                    end
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
                    --if callback then callback(XGuildDormConfig.ErrorCode.KCPFailed) end
                    --return
                    XLog.Error("kcp disconnect! use tcp for guild dorm")
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
            XLog.Debug("========== 连接KCP")
            -- 连接KCP
            asyncConnectKcp()
            XLog.Debug("========== 连接KCP流程已完成")
            -- 放到下一帧跑，主要是为了显示报错信息
            XScheduleManager.ScheduleOnce(function()
                if callback then callback(XGuildDormConfig.ErrorCode.Success) end
                -- 做心跳
                XLog.Debug("========== 开始做心跳")
                GuildDormNetwork:RequestHeartbeat()
            end, 1)
        end)
    end
    
    function GuildDormManager.GuildDormSetRoomBgmIdsRequest(bgmIds,cb)
        local req = {
            RoomId = DormData.RoomId,
            BgmIds = bgmIds
        }
        XNetwork.Call("GuildDormSetRoomBgmIdsRequest",req,function(rsp)
            if rsp.Code ~= XCode.Success then
                XUiManager.TipCode(rsp.Code)
                return
            end
            BgmQueue:Clear()
            for _,bgmId in ipairs(bgmIds) do
                BgmQueue:Enqueue(bgmId)
            end
            GuildDormManager.PlayBgm(bgmIds[1])
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_UPDATE_BGM_LIST)
            if cb then
                cb()
            end
        end)
    end

    -- 处理重连成功后的操作
    function GuildDormManager.HandleReConnectSuccess()
        if not GuildDormManager.GetIsRunning() then
            GuildDormManager.Dispose()
            return
        end
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
                currentRoom:UpdateFurnitureRandomReward()
                -- 打开共用组件管理
            end, function() GuildDormManager.Dispose() end)
        end
        XLuaUiManager.ClearAllMask()
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
                local currentRoom = GuildDormManager.GetCurrentRoom()
                currentRoom:SetIsInit(false)
                GuildDormNetwork:Disconnect()
            elseif errorCode == XGuildDormConfig.ErrorCode.Success then
                -- 这里开始正式走切换频道的流程
                local currentRoom = GuildDormManager.GetCurrentRoom()
                currentRoom:DisposeWithoutGo()
                -- 加载角色
                currentRoom:CreateRoles(GuildDormManager.GetPlayerDatas()
                    , currentRoom:GetCharacterRoot())
                currentRoom:UpdateFurnitureRandomReward()
                if callback then callback(true) end
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_SWITCH_CHANNEL)
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_CANCEL_INTERACT_BTN_SHOW, false, XPlayer.Id)
            -- 预先进入房间失败了，不处理
            elseif errorCode == XGuildDormConfig.ErrorCode.PreEnterFailed then
                if callback then callback(false) end
            elseif errorCode == XGuildDormConfig.ErrorCode.TCPFailed 
                or errorCode == XGuildDormConfig.ErrorCode.KCPFailed then
                GuildDormNetwork:StartReconnect()
            elseif errorCode == XGuildDormConfig.ErrorCode.EnterFailed then
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

    function GuildDormManager.SetIsHideUi(value)
        HideUi = value
    end

    function GuildDormManager.GetIsHideUi()
        return HideUi
    end

    function GuildDormManager.SetHideOtherPlayers(value)
        HideOtherPlayers = value
    end

    function GuildDormManager.GetHideOtherPlayers()
        return HideOtherPlayers
    end
    
    function GuildDormManager.SetHideOwnPlayer(value)
        HideOwnPlayer = value
    end

    function GuildDormManager.GetHideOwnPlayer()
        return HideOwnPlayer
    end

    function GuildDormManager.CheckIsWhiteEntityName(id)
        return WhiteEntityIdNameDic[id]
    end

    function GuildDormManager.SetNpcInteractGameStatus(npcId)
        GuildDormManager.__LastHideNameUi = HideNameUi
        GuildDormManager.__LastHideTalkUi = HideTalkUi
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_UI_SETTING, false, true)
        GuildDormManager.SetIsHideNameUi(true)
        GuildDormManager.SetIsHideTalkUi(true)
        -- 隐藏其他玩家
        GuildDormManager.SetHideOtherPlayers(true)
        local currentRoom = GuildDormManager.GetCurrentRoom()
        for _, role in ipairs(currentRoom:GetRoles()) do
            if not role:CheckIsSelfPlayer() then
                role:GetRLRole():PlayTargetAlphaAnim(0, 0.5)
            end
        end
        -- 只显示npc和自己玩家的名字
        WhiteEntityIdNameDic[XPlayer.Id] = true
        WhiteEntityIdNameDic[npcId] = true
    end

    function GuildDormManager.ResetNpcInteractGameStatus(npcId)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_UI_SETTING, not HideUi)
        GuildDormManager.SetIsHideNameUi(GuildDormManager.__LastHideNameUi)
        GuildDormManager.SetIsHideTalkUi(GuildDormManager.__LastHideTalkUi)
        -- 显示其他玩家
        GuildDormManager.SetHideOtherPlayers(false)
        local currentRoom = GuildDormManager.GetCurrentRoom()
        for _, role in ipairs(currentRoom:GetRoles()) do
            if not role:CheckIsSelfPlayer() then
                role:GetRLRole():PlayTargetAlphaAnim(1, 0.5)
            end
        end
        -- 清除白名单
        WhiteEntityIdNameDic[XPlayer.Id] = nil
        WhiteEntityIdNameDic[npcId] = nil
    end
    
    function GuildDormManager.SetFurnitureSpeicalInteractGameStatus(furnitureId)
        GuildDormManager.__LastHideNameUi = HideNameUi
        GuildDormManager.__LastHideTalkUi = HideTalkUi
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_UI_SETTING, false, true)
        GuildDormManager.SetIsHideNameUi(true)
        GuildDormManager.SetIsHideTalkUi(true)
        GuildDormManager.SetHideOwnPlayer(true)
        GuildDormManager.AllowCameraZoom(false)
        GuildDormManager.AllowTouch1ForAxis(false)
        -- 隐藏其他玩家
        GuildDormManager.SetHideOtherPlayers(true)
    end

    function GuildDormManager.ResetFurnitureSpeicalInteractGameStatus(furnitureId)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_UI_SETTING, not HideUi)
        GuildDormManager.SetIsHideNameUi(GuildDormManager.__LastHideNameUi)
        GuildDormManager.SetIsHideTalkUi(GuildDormManager.__LastHideTalkUi)
        GuildDormManager.SetHideOwnPlayer(false)
        GuildDormManager.AllowCameraZoom(true)
        GuildDormManager.AllowTouch1ForAxis(true)
        -- 显示其他玩家
        GuildDormManager.SetHideOtherPlayers(false)
    end
    
    function GuildDormManager.HandleSyncBGM(data)
        if not data or (not data.BgmIds) then
            return
        end
        DormData.BgmIds = data.BgmIds
        BgmQueue:Clear()
        for _,bgmId in pairs(data.BgmIds) do
            BgmQueue:Enqueue(bgmId)
        end
        if #DormData.BgmIds > 0 then
            GuildDormManager.PlayBgm(DormData.BgmIds[1])
        else
            GuildDormManager.StopBgm()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_UPDATE_BGM_LIST)
    end
    
    function GuildDormManager.HandleSyncTheme(data)
        DormData.RoomId = data.RoomId
        DormData.ThemeId = data.ThemeId
        --XUiManager.TipText("GuildDormThemeChanged")
        XLuaUiManager.Open("UiGuildDialog")
        --XLuaUiManager.RunMain()
    end
    
    function GuildDormManager.HandleSyncNpcGroup(data)
        DormData.NpcGroupId = data.NpcGroupId
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
        if not XTool.IsTableEmpty(data.PlayerDatas) then
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
                        local position = Vector3(syncData.X, syncData.Y, syncData.Z)
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
        --2.6 处理NPC同步数据
        if XTool.IsTableEmpty(data.NpcDatas) then return end

        for _, npcData in ipairs(data.NpcDatas) do
            local npcConfig=XGuildDormConfig.GetNpcRefreshConfigById(npcData.Id)
            if npcConfig then
                local combieId=tostring(npcConfig.NpcId)..'_XGuildDormNpc'
                local npc=currentRoom:GetNpc(combieId)
                if npc then
                    if npc.RefreshId==nil then
                        npc.RefreshId=npcData.Id
                    end
                    -- 更新数据
                    GuildDormManager.UpdateNpcData(npcData)
                    if GuildDormManager.GetNpcDataFromDormData(npcData.Id).State~=XGuildDormConfig.NpcState.Static then--not static
                        -- 同步位置
                        GuildDormManager.SyncNpcPosition(npcData,npc)
                        -- 同步待机
                        GuildDormManager.SyncNpcIdle(npcData,npc)
                        --交互处理
                        GuildDormManager.InteractWithPlayer(npcData,npc)
                    end
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
            ---@type XGuildDormRole
            local role
            if value.PlayerId <= 0 then
                role = currentRoom:GetRoleByFurnitureId(value.Id)
                if role then
                    role:StopInteract()
                    XLog.Debug("交互结束 交互信息为, 家具Id:" .. value.Id .. " 角色Id:" .. value.PlayerId .. " 交互前角色Id:" .. role:GetPlayerId())
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

    function GuildDormManager.GetIsHaveTempError()
        return IsHaveTempError
    end
    --==============
    --进入房间
    --==============
    function GuildDormManager.EnterGuildDorm(roomId, channelIndex, onLoadingStart, afterEnterMain)
        if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.Guild) then
            return
        end
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
            if IsHaveTempError or XGuildDormConfig.DebugOpenOldUi then
                XDataCenter.GuildManager.EnterGuild()
                return
            end
            GuildDormManager.RequestLoadRoom(roomId, channelIndex, function(errorCode)
                if errorCode == XGuildDormConfig.ErrorCode.Success then
                    GuildDormManager.StartGuildDorm(function()
                        local currentRoom = GuildDormManager.GetCurrentRoom()
                        -- 加载角色
                        currentRoom:CreateRoles(GuildDormManager.GetPlayerDatas()
                            , currentRoom:GetCharacterRoot())
                        currentRoom:UpdateFurnitureRandomReward()
                        -- 打开共用组件管理
                        --XLuaUiManager.Open("UiGuildDormCommon")
                        IsRunning = true
                        if afterEnterMain then
                            afterEnterMain()
                        end
                    end, function()
                        GuildDormManager.Dispose()
                    end, onLoadingStart)
                elseif errorCode == XGuildDormConfig.ErrorCode.TCPFailed then
                    GuildDormNetwork:StartReconnect()
                elseif errorCode == XGuildDormConfig.ErrorCode.PreEnterFailed
                    or errorCode == XGuildDormConfig.ErrorCode.EnterFailed
                    or errorCode == XGuildDormConfig.ErrorCode.KCPFailed then
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

    function GuildDormManager.SetRemaindRewardCount(value)
        RemaindRewardCount = value
    end

    function GuildDormManager.GetRemaindRewardCount()
        return RemaindRewardCount
    end
    
    function GuildDormManager.PlayBgm(bgmId)
        -- 禁用播放器检测
        if GuildDormManager.GetIsGuildSceneCDMusicMute() then
            LastWantToPlayButMuteBgmCfgId = bgmId
            return
        end

        while BgmQueue:Peek() ~= bgmId and (not BgmQueue:IsEmpty()) do
            local tempBgmId = BgmQueue:Dequeue()
            BgmQueue:Enqueue(tempBgmId)            
        end
        local bgmCfg = XGuildDormConfig.GetBgmCfgById(bgmId)
        BgmId = bgmId
        if BgmId ~= 0 then
            CS.XAudioManager.PlayMusicWithAnalyzer(bgmCfg.CueId)
            XEventManager.DispatchEvent(XEventId.EVENT_DORM_UPDATE_MUSIC)
            if BgmTimer then
                XScheduleManager.UnSchedule(BgmTimer)
            end
            BgmTimer = XScheduleManager.ScheduleOnce(function()
                if not XLuaUiManager.IsUiLoad("UiGuildDormMain") then
                    return
                end
                BgmTimer = nil
                local lastBgmId = BgmQueue:Dequeue()
                BgmQueue:Enqueue(lastBgmId)
                GuildDormManager.PlayBgm(BgmQueue:Peek())
            end, bgmCfg.Duration)
        end
    end
    
    function GuildDormManager.StopBgm()
        CS.XAudioManager.StopMusicWithAnalyzer()
    end
    
    function GuildDormManager.GetPlayedBgmId()
        return BgmId
    end
    
    function GuildDormManager.IsNewVersionFirstIn()
        local key = string.format("GuildDormManager_IsNewVersionFirstIn_V132_%s", XPlayer.Id)
        local data = XSaveTool.GetData(key)
        return data ~= 1 and true or false
    end
    
    function GuildDormManager.MarkNewVersionFirstIn()
        local key = string.format("GuildDormManager_IsNewVersionFirstIn_V132_%s", XPlayer.Id)
        local data = XSaveTool.GetData(key)
        if data == 1 then
            return
        end
        XSaveTool.SaveData(key, 1)
    end
    
    function GuildDormManager.GetGuildDormBgmBtnFirstKey()
        local key = string.format("GuildDormManager_GuildDormBgmBtnFirst_%s", tostring(XPlayer.Id))
        return key
    end
    
    function GuildDormManager.SaveGuildDormBgmBtnFirst()
        local key = GuildDormManager.GetGuildDormBgmBtnFirstKey()
        local data = XSaveTool.GetData(key)
        if data == 1 then
            return
        end
        XSaveTool.SaveData(key, 1)
    end
    
    function GuildDormManager.GetGuildDormBgmBtnFirst()
        local key = GuildDormManager.GetGuildDormBgmBtnFirstKey()
        local data = XSaveTool.GetData(key) or 0
        return data == 1
    end
    
    -- 检测bgm是否在体验时间内
    function GuildDormManager.CheckExperienceTimeIdByBgmId(bgmId)
        local bgmCfg = XGuildDormConfig.GetBgmCfgById(bgmId)
        -- 已购买
        local boughtBgm = XDataCenter.GuildManager.GetDormBgms()
        if bgmCfg.NeedBuy == 1 and XTool.IsNumberValid(bgmCfg.ExperienceTimeId) then
            local isInTime = XFunctionManager.CheckInTimeByTimeId(bgmCfg.ExperienceTimeId)
            local isBoughtBgm = table.contains(boughtBgm, bgmId)
            if not isBoughtBgm and isInTime then
                return true
            end
        end
        return false
    end

    -- 检测bgm是否在体验时间外（过期）
    function GuildDormManager.CheckExperienceExpireByBgmId(bgmId)
        local bgmCfg = XGuildDormConfig.GetBgmCfgById(bgmId)
        -- 已购买
        local boughtBgm = XDataCenter.GuildManager.GetDormBgms()
        if bgmCfg.NeedBuy == 1 and XTool.IsNumberValid(bgmCfg.ExperienceTimeId) then
            local isInTime = XFunctionManager.CheckInTimeByTimeId(bgmCfg.ExperienceTimeId)
            local isBoughtBgm = table.contains(boughtBgm, bgmId)
            if not isBoughtBgm and not isInTime then
                return true
            end
        end
        return false
    end
    
    -- 移除过期的BgmId
    function GuildDormManager.RemoveExperienceExpireBgmId(bgmIds)
        local isExpire = false
        local removeDic = {}
        for _, bgmId in pairs(bgmIds) do
            if GuildDormManager.CheckExperienceExpireByBgmId(bgmId) then
                table.insert(removeDic, bgmId)
            end
        end
        if #removeDic > 0 then
            isExpire = true
            for _, bgmId in pairs(removeDic) do
                XTool.TableRemove(bgmIds, bgmId)
            end
        end
        return isExpire
    end
    
    function GuildDormManager.UpdateSortingOrder(order)
        UiCommonSortingOrder = order
    end
    
    function GuildDormManager.GetCommonSortingOrder()
        return UiCommonSortingOrder - 1
    end
    
    function GuildDormManager.SetUiGuildDormCommon(show)
        IsShowUiGuildDormCommon = show
    end
    
    function GuildDormManager.CheckIsShowUiGuildDormCommon()
        return IsShowUiGuildDormCommon
    end
    
    --- 图文教学弹窗特殊判断，判断指定的引导是否播放完
    function GuildDormManager.CheckGuideGroupsIsCompleteForOpenHelp()
        local ids = XGuildDormConfig.GetCheckGuideGroupIdsForHelpOpen()

        if not XTool.IsTableEmpty(ids) then
            for i, guideGroupId in pairs(ids) do
                if not XDataCenter.GuideManager.CheckIsGuide(guideGroupId) then
                    return false
                end
            end
        end
        
        return true
    end
    
    --region 2.6 NPC同步
    function GuildDormManager.UpdateNpcData(npcData)
        local npcLocalData=GuildDormManager.GetNpcDataFromDormData(npcData.Id)
        if npcLocalData then
            if npcData.State then
                npcLocalData.State=npcData.State
            end
            if npcData.ActionId then
                npcLocalData.ActionId=npcData.ActionId
            end
            if npcData.LastInteractTime then
                npcLocalData.LastInteractTime=npcData.LastInteractTime
            end
        else
            NpcDataCache[npcData.Id]=npcData
        end
        
    end
    
    function GuildDormManager.SyncNpcPosition(npcData,npc)
        if npcData.Position and npc:CheckRLRoleIsCreated() then
            local transform = npc:GetRLRole():GetTransform()
            local position = Vector3(npcData.Position.X,npcData.Position.Y,npcData.Position.Z)
            local eulerAngles = transform.rotation.eulerAngles
            --确定新的Y轴转向：如果角度值是被忽略的，则沿用当前角度，否则使用下发的角度
            local newYangle=(XGuildDormConfig.IgnoreAngle==npcData.Position.Angle or math.abs(npcData.Position.Angle-XGuildDormConfig.IgnoreAngle)<100) and eulerAngles.y or npcData.Position.Angle
            local rotation = Quaternion.Euler(
                    Vector3(eulerAngles.x, newYangle, eulerAngles.z))
            if not npc.SyncAgent then
                local XGDNpcManagerComponent = require("XEntity/XGuildDorm/Components/XGDNpcSyncToClientComponent")
                npc.SyncAgent=XGDNpcManagerComponent.New(npc, transform,GuildDormManager.GetCurrentRoom())
                npc.SyncAgent:UpdateCurrentSyncData(position, rotation)
            else
                npc.SyncAgent:UpdateCurrentSyncData(position, rotation)
            end
            
            if GuildDormManager.GetNpcDataFromDormData(npcData.Id).State==XGuildDormConfig.NpcState.Move then--patrol
                if npc:GetAgent().BTree==nil or (npc:GetAgent().BTree.Id ~=npc:GetPatrolBehaviorId() and npc.InteractStatus~=XGuildDormConfig.InteractStatus.End) then
                    npc:PlayBehavior(npc:GetPatrolBehaviorId())
                end
            end
        end
    end
    
    function GuildDormManager.SyncNpcIdle(npcData,npc)
        if npcData.ActionId and npc:CheckRLRoleIsCreated() then
            if GuildDormManager.GetNpcDataFromDormData(npcData.Id).State==XGuildDormConfig.NpcState.Idle then--Idle
                if npc.SyncAgent then
                    npc.SyncAgent:SetMoveLock(true)
                end
                npc:ChangeStateMachine(XGuildDormConfig.RoleFSMType.PATROL_IDLE)

            end
        end
    end
    
    function GuildDormManager.InteractWithPlayer(npcData,npc)
        local npcLocalData=GuildDormManager.GetNpcDataFromDormData(npcData.Id)
        if npcLocalData.State==XGuildDormConfig.NpcState.Interact and npcData.PlayerId then --Interact
            npcLocalData.lastState=XGuildDormConfig.NpcState.Interact
            local player = GuildDormManager.GetCurrentRoom():GetRoleByPlayerId(npcData.PlayerId)
            if not player then return end
            local position=npc:GetRLRole():GetTransform().position
            local rotation=Quaternion.LookRotation(player:GetRLRole():GetTransform().position-position)

            if not npc.SyncAgent then
                local XGDNpcManagerComponent = require("XEntity/XGuildDorm/Components/XGDNpcSyncToClientComponent")
                npc.SyncAgent=XGDNpcManagerComponent.New(npc, npc:GetRLRole():GetTransform(),GuildDormManager.GetCurrentRoom())
                npc.SyncAgent:UpdateCurrentSyncData(position, rotation,true)
            else
                npc.SyncAgent:UpdateCurrentSyncData(position, rotation,true)
            end
            npc:ChangeStateMachine(XGuildDormConfig.RoleFSMType.INTERACT)

        elseif npcLocalData.lastState==XGuildDormConfig.NpcState.Interact then
            XEventManager.DispatchEvent("GuildDormNpcInteractEndTalk")
            npcLocalData.lastState=nil
        end
    end
    
    function GuildDormManager.GetNpcDataFromDormData(npcRefreshId)
        return NpcDataCache[npcRefreshId]
    end
    
    function GuildDormManager.CheckIfCanInteract(npcId)
        local npcData=GuildDormManager.GetNpcDataFromDormData(npcId)
        if npcData then
            local npcConfig=XGuildDormConfig.GetNpcRefreshConfigById(npcId)
            if npcConfig then
                local curTime=XTime.GetServerNowTimestamp()
                return curTime-npcData.LastInteractTime >=npcConfig.InteractCdTime
            end
        end
        return false
    end
    
    function GuildDormManager.RequestInteractWithDynamicNpc(npcId,callback)
        GuildDormNetwork:Call("GuildDormNpcInteractRequest",{
            NpcId=npcId
        },function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
            end
            if callback then callback(res.Code == XCode.Success) end
        end )
    end
    
    function GuildDormManager.GetNpcRefreshIdByThemeAndNpcId(npcId,themeId)
        local configs=XGuildDormConfig.GetNpcRefreshConfigsByThemeId(themeId)
        for i, value in ipairs(configs) do
            if value.NpcId==npcId then
                return value.Id
            end
        end
    end
    
    function GuildDormManager.CheckNpcIsStatic(npcRefreshId)
        local data=GuildDormManager.GetNpcDataFromDormData(npcRefreshId)
        if data~=nil then
            return data.State==0
        else
            return true    
        end
    end
    --endregion
    
    --region 2.15 特殊家具交互
    
    local RandomBoxCache = {}
    local OneTimeInteractReplyIds = nil
    local InteractedFurnitureIds = nil
    
    function GuildDormManager.GetGuildCreateTime()
        if DormData then
            return DormData.GuildCreateTime
        end
    end
    
    function GuildDormManager.SetRandomBoxCache(randomBoxes)
        if not XTool.IsTableEmpty(randomBoxes) then
            for i, v in ipairs(randomBoxes) do
                RandomBoxCache[v.FurnitureId] = v
            end
        end
    end
    
    function GuildDormManager.SetOneTimeInteractReplyIds(_OneTimeInteractReplyIds)
        if OneTimeInteractReplyIds == nil then
            OneTimeInteractReplyIds = {}
        end
        if not XTool.IsTableEmpty(_OneTimeInteractReplyIds) then
            for i, v in ipairs(_OneTimeInteractReplyIds) do
                OneTimeInteractReplyIds[v] = true 
            end
        end
    end
    
    function GuildDormManager.SetInteractedFurnitureIds(_InteractedFurnitureIds)
        if not XTool.IsTableEmpty(_InteractedFurnitureIds) then
            InteractedFurnitureIds = {}

            for i, v in ipairs(_InteractedFurnitureIds) do
                InteractedFurnitureIds[v] = true
            end
        end
    end
    
    -- 请求一次随机数据，每次打开饮料机时调用
    function GuildDormManager.RequestGuildDormCallRandomBox(furnitureId, cb, defaultReadCache)

        if not XTool.IsTableEmpty(RandomBoxCache) and not XTool.IsTableEmpty(RandomBoxCache[furnitureId]) then
            local randomBoxCfg = XGuildDormConfig.GetFurnitureRandomBox(furnitureId)
            -- 如果已经到达上限就不请求了，只拿缓存数据
            if RandomBoxCache[furnitureId].RandomTimes >= randomBoxCfg.RandomTimes then
                RandomBoxCache[furnitureId]._NoRandomTimes = true
                if cb then
                    cb(RandomBoxCache[furnitureId])
                end
                return
            end
            -- 如果要默认拿缓存，只要缓存有就只拿缓存
            if defaultReadCache then
                if cb then
                    cb(RandomBoxCache[furnitureId])
                end
                return
            end
        end
        
        XNetwork.Call("GuildDormCallRandomBoxRequest", { FurnitureId = furnitureId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            RandomBoxCache[furnitureId] = res.RandomBox
            
            if cb then
                cb(res.RandomBox)
            end
        end)
    end
    
    function GuildDormManager.RequestGuildDormGetOneTimeInteractReward(furnitureId, replyIndex, cb)
        XNetwork.Call("GuildDormGetOneTimeInteractRewardRequest", { FurnitureId = furnitureId, ReplyIndex = replyIndex }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local id = furnitureId * 100 + replyIndex
            if OneTimeInteractReplyIds == nil then
                OneTimeInteractReplyIds = {}
            end
            OneTimeInteractReplyIds[id] = true
            
            if cb then
                cb(res.RewardGoodsList)
            end
        end)        
    end

    function GuildDormManager.RequestGuildDormRecordInteract(furnitureId, cb)
        -- 没有记录过的才请求
        if GuildDormManager.CheckFurnitureInteracted(furnitureId) then
            return
        end
        
        XNetwork.Call("GuildDormRecordInteractRequest", { FurnitureId = furnitureId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            if InteractedFurnitureIds == nil then
                InteractedFurnitureIds = {}
            end

            InteractedFurnitureIds[furnitureId] = true

            if cb then
                cb()
            end
        end)
    end
    
    function GuildDormManager.CheckHasRecieveReward(furnitureId, replyIndex)
        if XTool.IsTableEmpty(OneTimeInteractReplyIds) then
            return false
        end
        
        local id = furnitureId * 100 + replyIndex
        return OneTimeInteractReplyIds[id] and true or false
    end
    
    function GuildDormManager.CheckFurnitureInteracted(furnitureId)
        if XTool.IsTableEmpty(InteractedFurnitureIds) then
            return false
        end
        
        return InteractedFurnitureIds[furnitureId] and true or false
    end
    --endregion

    function GuildDormManager.GetToggleSceneMusicCache()
        local key = string.format("GetToggleSceneMusicCache%dThemeId%d", XPlayer.Id, GuildDormManager.GetThemeId())
        local res = XSaveTool.GetData(key)
        if res == nil then
            return true
        end
        return XTool.IsNumberValid(res)
    end
    
    function GuildDormManager.GetToggleInstrumentMusicCache()
        local key = string.format("GetToggleInstrumentMusicCache%dThemeId%d", XPlayer.Id, GuildDormManager.GetThemeId())
        local res = XSaveTool.GetData(key)
        if res == nil then
            return true
        end
        return XTool.IsNumberValid(res)
    end

    function GuildDormManager.SaveToggleSceneMusicCache(flag)
        local key = string.format("GetToggleSceneMusicCache%dThemeId%d", XPlayer.Id, GuildDormManager.GetThemeId())
        XSaveTool.SaveData(key, flag)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_TOGGLE_MUSIC)
    end

    function GuildDormManager.SaveToggleInstrumentMusicCache(flag)
        local key = string.format("GetToggleInstrumentMusicCache%dThemeId%d", XPlayer.Id, GuildDormManager.GetThemeId())
        XSaveTool.SaveData(key, flag)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_TOGGLE_MUSIC)
    end
    
    function GuildDormManager.SetGuildSceneCDMusicMute(flag)
        IsGuildSceneCDMusicMute = flag
        if flag then
            TempMuteBgmInfo = XLuaAudioManager.GetCurrentMusicAudioInfo()
            if TempMuteBgmInfo then
                TempMuteBgmInfo:Pause()
            end
        else
            local info = XLuaAudioManager.GetCurrentMusicAudioInfo()
            if TempMuteBgmInfo and info and TempMuteBgmInfo.Id == info.Id and XGuildDormConfig.CheckCueIdIsInGuildDormBgm(info.CueId) then
                TempMuteBgmInfo:Resume()
            elseif LastWantToPlayButMuteBgmCfgId then
                GuildDormManager.PlayBgm(LastWantToPlayButMuteBgmCfgId)
            end
        end
    end

    function GuildDormManager.GetIsGuildSceneCDMusicMute()
        return IsGuildSceneCDMusicMute
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

XRpc.NotifyGuildDormThemeChanged = function(data)
    local queue = XDataCenter.GuildDormManager.GetSyncMsgQueue()
    queue:Enqueue({ Data = data, SyncType = XGuildDormConfig.SyncMsgType.Theme })
end

XRpc.NotifyGuildDormBgmChanged = function(data) 
    local queue = XDataCenter.GuildDormManager.GetSyncMsgQueue()
    queue:Enqueue({ Data = data, SyncType = XGuildDormConfig.SyncMsgType.BGM })
end

XRpc.NotifyGuildDormPlayerData = function(data)
    local guildDormData = data.GuildDormData
    XDataCenter.GuildDormManager.SetRemaindRewardCount(guildDormData.DailyInteractRewardTotalTimes 
        - guildDormData.DailyInteractRewardCurTimes)
    XDataCenter.GuildDormManager.SetRandomBoxCache(guildDormData.RandomBoxes)
    XDataCenter.GuildDormManager.SetOneTimeInteractReplyIds(guildDormData.OneTimeInteractReplyIds)
    XDataCenter.GuildDormManager.SetInteractedFurnitureIds(guildDormData.InteractedFurnitureIds)
end

XRpc.NotifyGuildDormNpcGroupChanged = function(data)
    local queue = XDataCenter.GuildDormManager.GetSyncMsgQueue()
    queue:Enqueue({ Data = data, SyncType = XGuildDormConfig.SyncMsgType.NpcGroup })
end

local keyStates = {}
XRpc.NotifyGuildDormPlayNoteRequest = function(data)
    local note = data.Note
    local furnitureId = XEnumConst.InstrumentSimulator.InstrumentFurnitureId.Piano
    -- 一般有22个按键
    local numKeys = XEnumConst.InstrumentSimulator.KeyboradKeyCount
    -- 创建一个表来存储按键状态
    for i = 1, numKeys do
        keyStates[i] = false  -- 初始化所有按键为未按下状态
    end

    -- 检查每个位的状态
    for i = 1, numKeys do
        -- 检查第i位是否为1
        if note & (1 << (i - 1)) ~= 0 then
            keyStates[i] = true  -- 按键被按下
        else
            keyStates[i] = false  -- 按键未被按下
        end
    end

    -- 打印按键状态，或者进行其他处理
    for i = 1, numKeys do
        local isPress = keyStates[i]
        if isPress then
            local config = XMVCA.XInstrumentSimulator:GetModelInstrumentKeyMapConfigByFurnitureIdAndIndex(furnitureId, i)
            local finCb = function()
                XMVCA.XInstrumentSimulator:SetInstrumentPlayingState(furnitureId, false)
            end
            XMVCA.XInstrumentSimulator:PlayInstrumentKeyAudio(config.CueId, finCb)
        end
    end

    XMVCA.XInstrumentSimulator:SetInstrumentPlayingState(furnitureId, true)
end