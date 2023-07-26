local XGuildDormRoleFSMFactory = require("XEntity/XGuildDorm/Role/FSM/XGuildDormRoleFSMFactory")
local XGuildDormBaseSceneObj = require("XEntity/XGuildDorm/Base/XGuildDormBaseSceneObj")
---@class XGuildDormRoom : XGuildDormBaseSceneObj
local XGuildDormRoom = XClass(XGuildDormBaseSceneObj, "XGuildDormRoom")
local XRoomBuild = require("XEntity/XGuildDorm/Room/XGuildDormRoomBuild")
local XGuildDormRole = require("XEntity/XGuildDorm/Role/XGuildDormRole")
local XGDComponentManager = require("XEntity/XGuildDorm/Base/XGDComponentManager")

--===========
--获取房间建筑管理控件
--===========
function XGuildDormRoom:GetRoomBuild()
    return self.RoomBuild
end
--===========
--获取房间数据
--===========
function XGuildDormRoom:GetRoomData()
    return self.RoomBuild and self.RoomBuild.Data
end
--===========
--获取房间名称
--===========
function XGuildDormRoom:GetRoomName()
    local roomData = self:GetRoomData()
    return roomData and roomData.Name or "UnNamed"
end
--===========
--获取房间模型外壳生成根节点
--===========
function XGuildDormRoom:GetSurfaceRoot()
    return self.RoomBuild and self.RoomBuild.SurfaceRoot
end
--===========
--获取房间模型角色生成根节点
--===========
function XGuildDormRoom:GetCharacterRoot()
    return self.RoomBuild and self.RoomBuild.CharacterRoot
end
--===========
--获取房间npc交互生成根节点
--===========
function XGuildDormRoom:GetNpcInteractRoot()
    return self.RoomBuild and self.RoomBuild.NpcInteractRoot
end
--===========
--获取房间模型家具生成根节点
--===========
function XGuildDormRoom:GetFurnitureRoot()
    return self.RoomBuild and self.RoomBuild.FurnitureRoot
end
--=============
--根据家具Id获取家具控件
--=============
function XGuildDormRoom:GetFurnitureById(id)
    return self.RoomBuild and self.RoomBuild.Data:GetFurniture(id)
end
--===========
--获取房间游戏对象
--===========
function XGuildDormRoom:GetGameObject()
    return self.GameObject
end

function XGuildDormRoom:GetSyncTime()
    return self.SyncTime
end

function XGuildDormRoom:GetRunTime()
    return self.RunTime
end
--================
--根据家具id获取家具交互信息列表
--================
function XGuildDormRoom:GetInteractInfoByFurnitureId(id)
    local furniture = self:GetFurnitureById(id)
    if not furniture then return {} end
    return furniture:GetInteractInfoList()
end
---@param roomData XGuildDormRoomData
function XGuildDormRoom:Ctor(roomData)
    ---@type XGuildDormRole[]
    self.Roles = {}
    self.PlayerId2RoleDic = {}
    -- 同步到服务器的时间
    self.SyncTime = XGuildDormConfig.GetSyncServerTime()
    -- 运行时间
    self.RunTime = 0
    self.GuildDormManager = XDataCenter.GuildDormManager
    self.IsInit = false
    ---@type XGuildDormRoomBuild
    self.RoomBuild = XRoomBuild.New(roomData)
    self.Running = nil
    self.IsShow = false
    -- 组件 XGDComponet
    self.GDComponentManager = XGDComponentManager.New()
end

function XGuildDormRoom:GetId()
    return self:GetRoomData().Id
end

---@param role XGuildDormRole
function XGuildDormRoom:AddRole(role)
    local playerId = role:GetPlayerId()
    if self:GetRoleByPlayerId(playerId) then
        XLog.Error("XGuildDormRoom.AddRole 重复增加角色：" .. playerId)
        return
    end
    table.insert(self.Roles, role)
    self.PlayerId2RoleDic[playerId] = role
end

---@return XGuildDormRole[]
function XGuildDormRoom:GetRoles()
    return self.Roles
end

function XGuildDormRoom:GetFurnitureDic()
    return self.RoomBuild:GetRoomData():GetAllFurnitures()
end

function XGuildDormRoom:GetNpcs(withRL)
    local npcManagerCom = self.GDComponentManager:GetComponent("XGDNpcManagerComponent")
    return npcManagerCom:GetNpcs(withRL)
end

function XGuildDormRoom:GetNpc(npcId)
    local npcManagerCom = self.GDComponentManager:GetComponent("XGDNpcManagerComponent")
    return npcManagerCom:GetNpc(npcId)
end

function XGuildDormRoom:GetIsInit()
    return self.IsInit
end

function XGuildDormRoom:SetIsInit(value)
    self.IsInit = value
end

---@return XGuildDormRole
function XGuildDormRoom:GetRoleByPlayerId(value)
    return self.PlayerId2RoleDic[value]
end

-- 设置宿舍内3D坐标 对应2D坐标
function XGuildDormRoom:SetViewPosToTransformLocalPosition(setTransform, fromTransform, offset)
    local camera = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCamera()
    if XTool.UObjIsNil(camera) then
        return
    end
    CS.XGuildDormHelper.SetViewPosToTransformLocalPosition(camera, setTransform, fromTransform, offset)
end

function XGuildDormRoom:UpdateRolesPosition()
    local playerDatas = XDataCenter.GuildDormManager.GetPlayerDatas()
    -- 转换字典
    local playerDataDic = {}
    for _, data in ipairs(playerDatas) do
        playerDataDic[data.PlayerId] = data
    end
    local role, playerData
    for i = #self.Roles, 1, -1 do
        role = self.Roles[i]
        playerData = playerDataDic[role:GetPlayerId()]
        if playerData then
            if not role:GetIsInteracting() then
                if not role:CheckIsSelfPlayer() then
                    role:GetRLRole():UpdateTransform(playerData.Position.X
                        , playerData.Position.Y
                        , playerData.Position.Z
                        , playerData.Position.Angle)
                else
                    role:SyncToServer()
                end
            end
        else
            self:DeleteRole(role:GetPlayerId())
        end
    end
end

function XGuildDormRoom:CreateRoles(playerDatas, containerGo)
    if XTool.UObjIsNil(containerGo) then
        XLog.Error("XGuildDormRoom.CreateRoles : containerGo参数不能为空！")
        return
    end
    -- debug 满员角色情况
    if XGuildDormConfig.DebugFullRole then
        local testPlayerData = playerDatas[1]
        local allCharacterDatas = XDataCenter.GuildDormManager.GetCharacterDatas(0)
        for i = 1, XGuildDormConfig.DebugFullRoleCount do
            local testAddPlayerData = XTool.Clone(testPlayerData)
            testAddPlayerData.PlayerId = testAddPlayerData.PlayerId .. i
            testAddPlayerData.CharacterId = allCharacterDatas[i].CharacterId
            table.insert(playerDatas, testAddPlayerData)
        end
    end
    for _, playerData in ipairs(playerDatas) do
        self:CreateRole(playerData, containerGo)
    end
    -- 创建运行中
    local XGuildDormRunning = require("XEntity/XGuildDorm/XGuildDormRunning")
    ---@type XGuildDormRunning
    self.Running = XGuildDormRunning.New(self:GetGameObject())
    self.Running:SetData(self)
end

function XGuildDormRoom:CreateRole(playerData, containerGo)
    if self:GetRoleByPlayerId(playerData.PlayerId) then
        XLog.Error("XGuildDormRoom.CreateRole 重复创建角色：" .. playerData.PlayerId)
        return
    end
    local XGDInputCompoent = require("XEntity/XGuildDorm/Components/XGDInputCompoent")
    local XGDMoveComponent = require("XEntity/XGuildDorm/Components/XGDMoveComponent")
    local XGDSyncToServerComponent = require("XEntity/XGuildDorm/Components/XGDSyncToServerComponent")
    local XGDInteractCheckComponent = require("XEntity/XGuildDorm/Components/XGDInteractCheckComponent")
    local XGDFurnitureInteractComponent = require("XEntity/XGuildDorm/Components/XGDFurnitureInteractComponent")
    local XGDNpcInteractComponent = require("XEntity/XGuildDorm/Components/XGDNpcInteractComponent")
    local XGDSyncToClientComponent = require("XEntity/XGuildDorm/Components/XGDSyncToClientComponent")
    local XGDActionPlayComponent = require("XEntity/XGuildDorm/Components/XGDActionPlayComponent")
    -- 创建角色数据
    ---@type XGuildDormRole
    local role = XGuildDormRole.New(playerData.CharacterId)
    -- 更新数据
    role:UpdateWithServerData(playerData)
    -- 获取RL角色数据
    local rlRole = role:GetRLRole()
    -- 加载角色模型
    rlRole:LoadModel(containerGo)
    -- 出生
    rlRole:Born(playerData.Position.X, playerData.Position.Y, playerData.Position.Z
        , playerData.Position.Angle, self:GetIsShow())
    self:AddRole(role)
    if XPlayer.Id == playerData.PlayerId then
        -- 创建角色控制器，只有自身玩家才有
        rlRole:CreateCharacterController()
        role:AddComponent(XGDInputCompoent.New())
        role:AddComponent(XGDMoveComponent.New(role))
        role:AddComponent(XGDSyncToServerComponent.New(role, self))
        role:AddComponent(XGDInteractCheckComponent.New(role, self))
        role:AddComponent(XGDFurnitureInteractComponent.New(role))
        role:AddComponent(XGDNpcInteractComponent.New(role, self))
        role:AddComponent(XGDActionPlayComponent.New(role))
        -- 设置摄像机跟随角色
        rlRole:UpdateCameraFollow()
    else
        role:AddComponent(XGDSyncToClientComponent.New(role, self))
        role:AddComponent(XGDFurnitureInteractComponent.New(role))
        role:AddComponent(XGDActionPlayComponent.New(role))
        rlRole:DisableColliders()
        -- 处理已经在交互的角色
        local furnitureData = XDataCenter.GuildDormManager.GetFurnitureDataByPlayerId(playerData.PlayerId)
        if furnitureData then 
            role:BeginInteract(furnitureData.Id, true)
        end
        rlRole:SetTransparent(XDataCenter.GuildDormManager.GetHideOtherPlayers() and 0 or 1)
    end
    rlRole:UpdateCurrentStepCueId(self:GetWalkCueId())
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ENTITY_ENTER, role)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_PLAYER_ENTER, role)
    return role
end

function XGuildDormRoom:DeleteRole(playerId)
    local role = self:GetRoleByPlayerId(playerId)
    if role == nil then return end
    role:Dispose()
    for i = #self.Roles, 1, -1 do
        if self.Roles[i]:GetPlayerId() == playerId then
            table.remove(self.Roles, i)
            break
        end
    end
    self.PlayerId2RoleDic[playerId] = nil
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_PLAYER_EXIT, playerId)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ENTITY_EXIT, playerId)
end

function XGuildDormRoom:Init()
    self.IsInit = true
    -- 增加npc管理组件
    local XGDNpcManagerComponent = require("XEntity/XGuildDorm/Components/XGDNpcManagerComponent")
    self.GDComponentManager:AddComponent(XGDNpcManagerComponent.New())
    -- 增加透明管理组件
    local XGDNpcRenderingComponent = require("XEntity/XGuildDorm/Components/XGDNpcRenderingComponent")
    self.GDComponentManager:AddComponent(XGDNpcRenderingComponent.New())
end

function XGuildDormRoom:Update(dt)
    self.RunTime = self.RunTime + dt
    self.GDComponentManager:Update(dt)
    for _, role in ipairs(self.Roles) do
        role:Update(dt)
    end
    for _, furniture in pairs(self:GetFurnitureDic()) do
        furniture:Update(dt)
    end
end

function XGuildDormRoom:OnLoadComplete(loadtype)
    self.RoomBuild:OnLoadComplete(self.Transform)
end

-- 设置房间数据
function XGuildDormRoom:SetData(data, loadtype)
    self.Data = data
    self.CurLoadType = loadtype
    --self:CleanRoom()
    --self:CleanCharacter()
    self.RoomBuild:InitFurnitures()
    --暂时不需要网格
    --self.RoomBuild:GenerateRoomMap()
    --self:LoadCharacter()
end

function XGuildDormRoom:OnEnterRoom()
    self.RoomBuild:OnEnter()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ON_ENTER_ROOM, self)
end

function XGuildDormRoom:OnLeaveRoom()
    self.RoomBuild:OnLeave()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ON_LEAVE_ROOM, self)
end

function XGuildDormRoom:ResetNavmeshObstacle()
    self.RoomBuild:ResetNavmeshObstacle()
end

function XGuildDormRoom:Dispose()
    self.RoomBuild:Dispose()
    self:DisposeWithoutGo()
end

function XGuildDormRoom:DisposeWithoutGo()
    if self.Running then
        self.Running:Dispose()
        self.Running = nil
    end
    if self.Roles then
        for _, role in ipairs(self.Roles) do
            role:Dispose()
        end
    end
    self.Roles = nil
    self.Roles = {}
    self.PlayerId2RoleDic = nil
    self.PlayerId2RoleDic = {}
    self.IsInit = false
    self.RunTime = 0
    self.GDComponentManager:Dispose()
    XGuildDormRoleFSMFactory.Dispose()
end

function XGuildDormRoom:GetRoleByFurnitureId(id)
    local furnitureDatas = XDataCenter.GuildDormManager.GetFurnitureDatas()
    for _, data in pairs(furnitureDatas) do
        if data.Id == id then
            return self:GetRoleByPlayerId(data.PlayerId)
        end
    end
end

function XGuildDormRoom:CheckPlayerIsInteract(playerId)
    local furnitureDatas = XDataCenter.GuildDormManager.GetFurnitureDatas()
    for _, data in ipairs(furnitureDatas) do
        if data.PlayerId == playerId then
            return true
        end
    end
    return false
end

function XGuildDormRoom:GetRunning()
    return self.Running
end
--============
--获取房间是否正在显示
--============
function XGuildDormRoom:GetIsShow()
    return self.IsShow
end
--============
--设置房间是否正在显示
--============
function XGuildDormRoom:SetIsShow(value)
    if self.IsShow == value then return end
    self.IsShow = value
    ---@param role XGuildDormRole
    for _, role in pairs(self.Roles) do
        role:GetRLRole():SetMeshRenderersIsEnable(value)
        if not role:CheckIsSelfPlayer() then
            role:GetRLRole():SetTransparent(XDataCenter.GuildDormManager.GetHideOtherPlayers() and 0 or 1)
        end
    end
    for _, com in ipairs(self.GDComponentManager:GetComponents()) do
        if com.CheckRoomIsShow then
            com:CheckRoomIsShow(value)
        end
    end
end
--============
--显示房间GameObject
--============
function XGuildDormRoom:Show()
    self.RoomBuild:Show()
    self.IsShow = true
end
--============
--隐藏房间GameObject
--============
function XGuildDormRoom:Hide()
    self.RoomBuild:Hide()
    self.IsShow = false
end

function XGuildDormRoom:SetRolesMeshRendererIsEnable(value)
    for _, role in ipairs(self.Roles) do
        role:GetRLRole():SetMeshRenderersIsEnable(value)
    end
end

-- 播放镜头切换 （已废弃）
function XGuildDormRoom:PlayCameraSwitchAnim(targetTrans, finishedCb)
    -- 获取原先镜头
    local camera = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCamera()
    local cameraController = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCameraController()
    -- 获取切换主镜头，设置相同位置，旋转，大小
    local switchMainCamera = self.RoomBuild:GetSwitchMainCamera()
    local orginCamera = self.RoomBuild:GetSwitchCameraByName("NearCamera1")
    local targetCamera = self.RoomBuild:GetSwitchCameraByName("NearCamera2")
    -- 获取指定名称的镜头，设置相同偏移，隐藏原镜头
    orginCamera.transform.position = camera.transform.position
    orginCamera.transform.rotation = camera.transform.rotation
    orginCamera.transform.localScale = camera.transform.localScale
    orginCamera.m_Lens = CS.Cinemachine.LensSettings.FromCamera(camera)
    -- 设置目标镜头的位置信息
    targetCamera.transform.position = targetTrans.position
    targetCamera.transform.rotation = targetTrans.rotation
    -- 设置禁用相关
    cameraController.enabled = false
    switchMainCamera.enabled = true
    orginCamera.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function()
        targetCamera.gameObject:SetActiveEx(true)
        local time = XCameraHelper.GetBlendTime(switchMainCamera, 0)
        XScheduleManager.ScheduleOnce(finishedCb, math.ceil(time * 1000))
    end, 1)
end

-- 恢复镜头控制 （已废弃）
function XGuildDormRoom:ResetCameraController(finishedCb)
    -- 获取切换主镜头
    local camera = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCamera()
    local cameraController = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCameraController()
    local switchMainCamera = self.RoomBuild:GetSwitchMainCamera()
    local orginCamera = self.RoomBuild:GetSwitchCameraByName("NearCamera1")
    local targetCamera = self.RoomBuild:GetSwitchCameraByName("NearCamera2")
    targetCamera.gameObject:SetActiveEx(false)
    local time = XCameraHelper.GetBlendTime(switchMainCamera, 1)
    XScheduleManager.ScheduleOnce(function()
        switchMainCamera.enabled = false
        cameraController.enabled = true
        if finishedCb then finishedCb() end
    end, math.ceil(time * 1000))
end

function XGuildDormRoom:DestroyNpc(npc)
    local npcManagerCom = self.GDComponentManager:GetComponent("XGDNpcManagerComponent")
    npcManagerCom:DestroyNpc(npc)
end

function XGuildDormRoom:GetSpecialUiEntities()
    local result = {}
    for _, v in pairs(self:GetFurnitureDic()) do
        if #v:GetSpecialUiNames() > 0 then
            table.insert(result, v)
        end
    end
    return result
end

-- 更新家具随机奖励
function XGuildDormRoom:UpdateFurnitureRandomReward()
    local remaindCount = XDataCenter.GuildDormManager.GetRemaindRewardCount()
    local furnitures = {}
    for _, v in pairs(self:GetFurnitureDic()) do
        if v:CheckIsAllocatedReward() then
            remaindCount = remaindCount - 1
        else
            if v:CheckIsGetReward() then
                table.insert(furnitures, v)
            end
        end
    end
    remaindCount = math.max(remaindCount, 0)
    if #furnitures <= 0 then return end
    local index = nil
    while remaindCount > 0 do
        index = XTool.Random(1, #furnitures)
        furnitures[index]:SetIsAllocatedReward(true)
        remaindCount = remaindCount - 1
        table.remove(furnitures, index)
        if #furnitures <= 0 then return end
    end
end

function XGuildDormRoom:GetWalkCueId()
    return XDataCenter.GuildDormManager.GetThemeCfg().StepCueId
end

function XGuildDormRoom:GetCurrentThemeId()
    return XDataCenter.GuildDormManager.GetThemeCfg().Id
end

return XGuildDormRoom