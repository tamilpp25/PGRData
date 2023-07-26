local XGuildDormNpc = require("XEntity/XGuildDorm/Role/XGuildDormNpc")
local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
---@class XGDNpcManagerComponent : XGDComponet
---@field Npcs XGuildDormNpc[]
local XGDNpcManagerComponent = XClass(XGDComponet, "XGDNpcManagerComponent")

function XGDNpcManagerComponent:Ctor()
    self.Npcs = {}
    self.NpcDic = {}
    self.Room = nil
end

function XGDNpcManagerComponent:Init()
    XGDNpcManagerComponent.Super.Init(self)
    self:SetUpdateIntervalTime(0.05)
    ---@type XGuildDormRoom
    self.Room = XDataCenter.GuildDormManager.GetCurrentRoom()
    self:InitNpcConfig()
end

function XGDNpcManagerComponent:InitNpcConfig()
    self.NpcGroupId = XDataCenter.GuildDormManager.GetNpcGroupId()
    if XTool.IsNumberValid(self.NpcGroupId) then
        -- 获取对应房间刷新的npcId
        local npcConfigs = XGuildDormConfig.GetNpcRefreshConfigsByNpcGroupId(self.NpcGroupId, self.Room:GetCurrentThemeId())
        for _, config in ipairs(npcConfigs) do
            self:CreateNpc(config)
        end
    end
end

function XGDNpcManagerComponent:CreateNpc(refreshConfig)
    local npcConfig = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormNpc, refreshConfig.NpcId)
    ---@type XGuildDormNpc
    local npc = XGuildDormNpc.New(npcConfig.CharacterId)
    npc:SetNpcConfig(npcConfig)
    npc:SetNpcRefreshConfig(refreshConfig)
    self:AddNpc(npc)
end

---@param npc XGuildDormNpc
function XGDNpcManagerComponent:CreateRLNpc(npc)
    if npc:CheckRLRoleIsCreated() then return end
    -- 获取RL角色数据
    local rlRole = npc:GetRLRole()
    -- 加载角色模型
    rlRole:LoadModel(self.Room:GetCharacterRoot())
    -- 加载自身的动画状态机
    local controllerPath = npc:GetAnimControllerPath()
    if not string.IsNilOrEmpty(controllerPath) then
        local runtimeController = CS.LoadHelper.LoadUiController(controllerPath, "UiGuildDormMain")
        rlRole:SetAnimatorController(runtimeController)
    end
    -- 出生
    local refreshConfig = npc:GetRefreshConfig()
    -- 出生点
    local interactRoot = self.Room:GetNpcInteractRoot()
    local initPos=nil
    if interactRoot and refreshConfig.InitPos then
        initPos = interactRoot:Find(refreshConfig.InitPos)
    end

    if initPos then
        rlRole:BornWithTransform(initPos.transform)
    elseif not XDataCenter.GuildDormManager.CheckNpcIsStatic(npc.RefreshId) then
        rlRole:Born(0, 0, 0, 0)  
    else
        XLog.Error("npc找不到配置的出生点" .. refreshConfig.InitPos)
    end
    rlRole:DisableColliders(true)
    rlRole:SetCollidersLayer(CS.UnityEngine.LayerMask.NameToLayer(HomeSceneLayerMask.Device))
    rlRole:SetCollidersRadius(refreshConfig.ColliderRadius)
    rlRole:AddInteractInfo({
        Id = npc:GetEntityId(),
        ButtonType = XGuildDormConfig.FurnitureButtonType.Npc,
        ButtonId = npc:GetEntityId(),
        ShowButtonName = refreshConfig.InteractName,
        InitPos = initPos,
        BehaviorType = refreshConfig.TalkBehaviorId
    })
    -- 添加组件
    -- 设置显示
    rlRole:SetMeshRenderersIsEnable(self.Room:GetIsShow())
    -- 进来默认播放idle行为树
    --2.6 存在动态npc，只有静态npc才播放idle
    if XDataCenter.GuildDormManager.CheckNpcIsStatic(self.RefreshId) and npc:GetIdleBehaviorId()~=nil then
        npc:PlayBehavior(npc:GetIdleBehaviorId())
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ENTITY_ENTER, npc)
    rlRole:SetTransparent(0)
    rlRole:PlayTargetAlphaAnim(1, 0.5)
end

function XGDNpcManagerComponent:DestroyNpc(npc)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ENTITY_EXIT, npc:GetEntityId())
    self.NpcDic[npc:GetEntityId()] = nil
    npc:Dispose()
    -- 移除Npc数据
    self:RemoveNpc(npc:GetEntityId())
end

function XGDNpcManagerComponent:RemoveNpc(entityId)
    local removePos
    for index, npc in pairs(self.Npcs) do
        if npc:GetEntityId() == entityId then
            removePos = index
            break
        end
    end
    if removePos then
        table.remove(self.Npcs, removePos)
    end
end

function XGDNpcManagerComponent:GetNpcs(withRL)
    if withRL == nil then withRL = false end
    local result = {}
    for _, npc in ipairs(self.Npcs) do
        if withRL == false or npc:CheckRLRoleIsCreated() then
            table.insert(result, npc)
        end
    end
    return result
end

---@return XGuildDormNpc
function XGDNpcManagerComponent:GetNpc(id)
    return self.NpcDic[id]
end

---@param npc XGuildDormNpc
function XGDNpcManagerComponent:AddNpc(npc)
    table.insert(self.Npcs, npc)
    self.NpcDic[npc:GetEntityId()] = npc
end

function XGDNpcManagerComponent:Update(dt)
    -- 切换Npc组
    local currNpcGroupId = XDataCenter.GuildDormManager.GetNpcGroupId()
    if currNpcGroupId ~= self.NpcGroupId then
        if #self.Npcs <= 0 then
            self:InitNpcConfig()
        end
    end
    -- Npc刷新
    for _, npc in pairs(self.Npcs) do
        if not npc:GetIsRemove() then
            npc:Update(dt)
            if npc:CheckInTime() then
                self:CreateRLNpc(npc)
            end
            if npc:CheckIsEndTime() or (not npc:GetIsTalking() and currNpcGroupId ~= self.NpcGroupId) then
                npc:SetIsRemove(true)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_ROLE_CAN_DESTROY, npc:GetEntityId())
            end
        end
    end
end

-- 检查房间是否被显示
function XGDNpcManagerComponent:CheckRoomIsShow(value)
    -- 设置角色是否
    for _, npc in pairs(self.Npcs) do
        if npc:CheckRLRoleIsCreated() then
            npc:GetRLRole():SetMeshRenderersIsEnable(value)
        end
    end
end

function XGDNpcManagerComponent:Dispose()
    if self.Npcs then
        for i = #self.Npcs, 1, -1 do
            self:DestroyNpc(self.Npcs[i])
        end
    end
end

return XGDNpcManagerComponent