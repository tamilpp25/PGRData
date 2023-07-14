local Time = CS.UnityEngine.Time
local Input = CS.UnityEngine.Input
local KeyCode = CS.UnityEngine.KeyCode
local Vector2 = CS.UnityEngine.Vector2
local Env = CS.XLuaEngine.Env
local XGuildDormRunning = XClass(nil, "XGuildDormRunning")

function XGuildDormRunning:Ctor(gameObject)
    self.GameObject = gameObject
    self.Transform = gameObject.transform
    -- 注册luaBehaviour监听
    local behaviour = gameObject:AddComponent(typeof(CS.XLuaBehaviour))
    behaviour.LuaUpdate = function() self:Update() end
    -- 当前房间
    self.CurrentRoom = nil
    self.UiGuildDormCommon = nil
    self.InitMemroy = nil
    self.GCCheckAddMemroy = XGuildDormConfig.GetAutoGCMemroy() * 1024
    self.SyncMsgQueue = XDataCenter.GuildDormManager.GetSyncMsgQueue()
    self.GuildDormManager = XDataCenter.GuildDormManager
end

function XGuildDormRunning:SetUiGuildDormCommon(value)
    self.UiGuildDormCommon = value
end

function XGuildDormRunning:SetData(room)
    self.CurrentRoom = room
    self.CurrentRoom:Init()
    self.InitMemroy = Env.Memroy
end

function XGuildDormRunning:Update()
    if self.CurrentRoom and self.CurrentRoom:GetIsInit() then
        -- ################################# debug begin #################################
        -- debug 键鼠控制
        if XGuildDormConfig.DebugKeyboard then
            if self.__inputComponent == nil then
                self.__inputComponent 
                    = self.CurrentRoom:GetRoleByPlayerId(XPlayer.Id):GetComponent("XGDInputCompoent")
            end
            local direction = Vector2.zero
            if Input.GetKey(KeyCode.W) then direction.y = direction.y + 1  end
            if Input.GetKey(KeyCode.S) then direction.y = direction.y - 1 end
            if Input.GetKey(KeyCode.A) then direction.x = direction.x - 1 end
            if Input.GetKey(KeyCode.D) then direction.x = direction.x + 1 end
            direction = direction.normalized
            self.__inputComponent:UpdateMoveDirection(direction.x, direction.y)
        end
        -- debug 延迟
        if XGuildDormConfig.DebugNetworkDelay then
            local queue = XDataCenter.GuildDormManager.__DebugDelayQueue
            if queue and queue:Count() > 0 then
                local data = queue:Peek()
                if Time.realtimeSinceStartup >= data.Time then
                    queue:Dequeue()
                    XDataCenter.GuildDormManager.HandleSyncEntities(data.data)
                end
            end
        end
        -- debug 断线重连
        if XGuildDormConfig.DebugOpenReconnect then
            if Input.GetKey(KeyCode.R) then
                XGuildDormConfig.DebugReconnectSign = true
            end
        end
        -- ################################# debug end #################################
        if self.SyncMsgQueue:Count() > 0 then
            local msg = self.SyncMsgQueue:Dequeue()
            if msg.SyncType == XGuildDormConfig.SyncMsgType.Entities then
                self.GuildDormManager.HandleSyncEntities(msg.Data)
            elseif msg.SyncType == XGuildDormConfig.SyncMsgType.PlayAction then
                self.GuildDormManager.HandleSyncPlayAction(msg.Data)
            elseif msg.SyncType == XGuildDormConfig.SyncMsgType.PlayerExit then
                self.GuildDormManager.HandleSyncPlayerExit(msg.Data)
            elseif msg.SyncType == XGuildDormConfig.SyncMsgType.Furniture then
                self.GuildDormManager.HandleSyncFurniture(msg.Data)
            end
        end
        self.CurrentRoom:Update(Time.deltaTime)
    end
    if self.UiGuildDormCommon then
        self.UiGuildDormCommon:Update(Time.deltaTime)
    end
    -- 超过一定增加的内存，主动gc一次
    if Env.Memroy - self.InitMemroy >= self.GCCheckAddMemroy then
        XLog.Debug("========= gc", self.InitMemroy, Env.Memroy, self.GCCheckAddMemroy)
        LuaGC()
    end
end

function XGuildDormRunning:Dispose()
    -- 取消luaBehaviour监听
    local xLuaBehaviour = self.Transform:GetComponent(typeof(CS.XLuaBehaviour))
    if (xLuaBehaviour) then
        CS.UnityEngine.GameObject.Destroy(xLuaBehaviour)
    end
    self.CurrentRoom = nil
    if self.UiGuildDormCommon then
        self.UiGuildDormCommon:Clear()
    end
    self.UiGuildDormCommon = nil
end

return XGuildDormRunning