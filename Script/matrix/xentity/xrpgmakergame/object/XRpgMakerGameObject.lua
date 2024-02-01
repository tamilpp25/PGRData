local XRpgMakerGamePosition = require("XEntity/XRpgMakerGame/XRpgMakerGamePosition")

local type = type
local pairs = pairs
local Vector3 = CS.UnityEngine.Vector3
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule
local LookRotation = CS.UnityEngine.Quaternion.LookRotation
local CSXResourceManagerLoad = CS.XResourceManager.Load

local Default = {
    _Id = 0,
}

local MoveSpeed = CS.XGame.ClientConfig:GetInt("RpgMakeGameMoveSpeed")
local DieByTrapTime = CS.XGame.ClientConfig:GetInt("RpgMakerGameDieByTrapTime") / 1000  --掉入陷阱动画时长
local KillByElectricFenceEffectName = XRpgMakerGameConfigs.ModelKeyMaps.KillByElectricFenceEffect

---推箱子物体对象
---@class XRpgMakerGameObject : XRpgMakerGamePosition
local XRpgMakerGameObject = XClass(XRpgMakerGamePosition, "XRpgMakerGameObject")

function XRpgMakerGameObject:Ctor(id, gameObject)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Id = id
    self.ModelPath = nil    --模型路径
    self.ModelRoot = nil    --模型根节点
    self.ModelName = nil    --模型名，作为key检索其他配置表用，可为nil
    self.ModelKey = ""      --RpgMakerGameModel表的Key
    self.RoleModelPanel = nil   --模型控制
    self.ResourcePool = {}  --已加载的资源池
    self.EffectPool = {}    --已加载的特效池
    self:Init()

    if not XTool.UObjIsNil(gameObject) then
        self:SetModel(gameObject)
    end
end

function XRpgMakerGameObject:Init()
    self:ClearDrown()
    self._IsPlayAdsorb = false  --是否播放钢板吸附动作
    self:SetIsTranser(false)
    self:DisposeEffect()
end

function XRpgMakerGameObject:Dispose()
    self:DisposeEffect()

    for _, resource in pairs(self.ResourcePool) do
        resource:Release()
    end
    self.ResourcePool = {}

    if not XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler:RemoveAllListeners()
    end
    self.GoInputHandler = nil

    self:DisposeModel()
    self:StopPlayMoveActionTimer()

    self.ModelPath = nil
    self.RoleModelPanel = nil
    self:Init()
    self:SetIsTranser(false)
end

function XRpgMakerGameObject:DisposeEffect()
    for _, effect in pairs(self.EffectPool) do
        if not XTool.UObjIsNil(effect) then
            XUiHelper.Destroy(effect)
        end
    end
    self.EffectPool = {}
end

function XRpgMakerGameObject:DisposeModel()
    if not XTool.UObjIsNil(self.GameObject) then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
        self.GameObject = nil
        self.Transform = nil
    end
end

function XRpgMakerGameObject:SetId(id)
    self._Id = id
end

function XRpgMakerGameObject:GetId()
    return self._Id
end

--------------场景对象相关 begin----------------
--获得两点间的传送点列表
local GetTransferPointDistanceList = function(data)
    local mapId = data.MapId
    local startPosX = data.StartPosX
    local startPosY = data.StartPosY
    local endPosX = data.EndPosX 
    local endPosY = data.EndPosY
    local cubeDistance = data.CubeDistance

    local distanceList = {}
    local distance = math.sqrt(XTool.MathPow((endPosY - startPosY), 2) + XTool.MathPow((endPosX - startPosX), 2))
    local oneCubeDistance = cubeDistance / distance

    local UpdateDistanceList = function(posX, posY, index)
        -- local transferPointId = XRpgMakerGameConfigs.GetRpgMakerGameTransferPointId(mapId, posX, posY)
        local transferPointId = XRpgMakerGameConfigs.GetMixTransferPointIndexByPosition(mapId, posX, posY)
        local obj = XDataCenter.RpgMakerGameManager.GetTransferPointObj(transferPointId)
        if obj then
            table.insert(distanceList, {
                Distance = oneCubeDistance * index,
                Obj = obj
            })
        end
    end

    
    local nextPosX, nextPosY = startPosX, startPosY
    for i = 1, math.ceil(distance) do
        if startPosX ~= endPosX then
            nextPosX = startPosX > endPosX and startPosX - i or startPosX + i
        end
        if startPosY ~= endPosY then
            nextPosY = startPosY > endPosY and startPosY - i or startPosY + i
        end
        UpdateDistanceList(nextPosX, nextPosY, i)
    end

    return distanceList
end

--获得两点间的实例列表
local GetEntityDistanceList = function(data)
    local mapId = data.MapId
    local startPosX = data.StartPosX
    local startPosY = data.StartPosY
    local endPosX = data.EndPosX 
    local endPosY = data.EndPosY
    local cubeDistance = data.CubeDistance

    local entityDistanceList = {}
    local distance = math.sqrt(XTool.MathPow((endPosY - startPosY), 2) + XTool.MathPow((endPosX - startPosX), 2))
    local oneCubeDistance = cubeDistance / distance

    local UpdateEntityDistanceList = function(posX, posY, index)
        local entityDataList = XRpgMakerGameConfigs.GetMixBlockEntityListByPosition(mapId, posX, posY)
        for _, data in ipairs(entityDataList) do
            local entityId = XRpgMakerGameConfigs.GetEntityIndex(mapId, data)
            local entityObj = XTool.IsNumberValid(entityId) and XDataCenter.RpgMakerGameManager.GetEntityObj(entityId)
            if entityObj and entityObj:IsActive() then
                table.insert(entityDistanceList, {
                    Distance = oneCubeDistance * index,
                    EntityObj = entityObj
                })
            end
        end
    end

    local nextPosX, nextPosY = startPosX, startPosY
    for i = 1, math.ceil(distance) do
        if startPosX ~= endPosX then
            nextPosX = startPosX > endPosX and startPosX - i or startPosX + i
        end
        if startPosY ~= endPosY then
            nextPosY = startPosY > endPosY and startPosY - i or startPosY + i
        end
        UpdateEntityDistanceList(nextPosX, nextPosY, i)
    end

    return entityDistanceList
end

--移动
function XRpgMakerGameObject:PlayMoveAction(action, cb, skillType)
    local transform = self:GetTransform()
    local startPosX = action.StartPosition.PositionX
    local startPosY = action.StartPosition.PositionY
    local endPosX = action.EndPosition.PositionX
    local endPosY = action.EndPosition.PositionY

    local startCube = self:GetCubeObj(startPosY, startPosX)
    local endCube = self:GetCubeObj(endPosY, endPosX)
    local startCubePosition = startCube:GetGameObjUpCenterPosition()
    local endCubePosition = endCube:GetGameObjUpCenterPosition()
    local cubeDistance = CS.UnityEngine.Vector3.Distance(startCubePosition, endCubePosition)
    local playActionTime = cubeDistance / MoveSpeed

    --计算播放音效的位置
    local distance = math.sqrt(XTool.MathPow((endPosY - startPosY), 2) + XTool.MathPow((endPosX - startPosX), 2))
    local playMoveSoundSpacePosition = distance > 0 and (endCubePosition - startCubePosition) / distance or Vector3(0, 0, 0)
    local currPlayMoveSoundPosition = startCubePosition + playMoveSoundSpacePosition

    self:SetGameObjectPosition(startCubePosition)

    --计算移动到目标位置的距离
    local gameObjPosition = self:GetGameObjPosition()
    local enterStageDb = XDataCenter.RpgMakerGameManager:GetRpgMakerGameEnterStageDb()
    local mapId = enterStageDb:GetMapId()
    local trapId = XRpgMakerGameConfigs.GetRpgMakerGameTrapId(mapId, endPosX, endPosY)  --移动到的坐标有陷阱时，不偏移模型的位置
    local moveX = endCubePosition.x - gameObjPosition.x
    local moveZ = endCubePosition.z - gameObjPosition.z

    --在格子边缘停止移动
    if (self:IsDieByDrown() and not self:IsNotPlayDrownAnima()) or self:IsTranser() then
        local cubeSize = endCube:GetGameObjSize()
        local moveTempX = endCubePosition.x - startCubePosition.x
        if moveTempX < 0 then
            moveX = moveX + cubeSize.x / 2
        elseif moveTempX > 0 then
            moveX = moveX - cubeSize.x / 2
        end

        local moveTempZ = endCubePosition.z - startCubePosition.z
        if moveTempZ < 0 then
            moveZ = moveZ + cubeSize.z / 2
        elseif moveTempZ > 0 then
            moveZ = moveZ - cubeSize.z / 2
        end
    end

    self:ChangeDirectionAction(action)

    local modelName = self:GetModelName()
    local runAnima = XRpgMakerGameConfigs.GetRpgMakerGameRunAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(runAnima)

    local getDistanceData = {
        MapId = mapId,
        StartPosX = startPosX,
        StartPosY = startPosY,
        EndPosX = endPosX,
        EndPosY = endPosY,
        CubeDistance = cubeDistance
    }

    --获得移动路径中的实例
    local entityDistanceList
    if skillType then
        entityDistanceList = GetEntityDistanceList(getDistanceData)
    end

    --获得移动路径中的传送点
    local transPointList
    if skillType and skillType ~= XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Dark then
        transPointList = GetTransferPointDistanceList(getDistanceData)
    end

    local movePositionX
    local movePositionZ
    local currPlayMoveSoundPositionX
    local currPlayMoveSoundPositionZ
    local curMoveDistance   --当前距离起点移动了多少
    self.PlayMoveActionTimer = XUiHelper.Tween(playActionTime, function(f)
        if XTool.UObjIsNil(transform) then
            return
        end

        curMoveDistance = playActionTime * f * MoveSpeed

        movePositionX = gameObjPosition.x + moveX * f
        movePositionZ = gameObjPosition.z + moveZ * f

        self:SetGameObjectPosition(Vector3(movePositionX, startCubePosition.y, movePositionZ), trapId)

        --保留2位小数
        movePositionX = movePositionX - movePositionX % 0.01
        movePositionZ = movePositionZ - movePositionZ % 0.01
        currPlayMoveSoundPositionX = currPlayMoveSoundPosition.x - currPlayMoveSoundPosition.x % 0.01
        currPlayMoveSoundPositionZ = currPlayMoveSoundPosition.z - currPlayMoveSoundPosition.z % 0.01

        --每移动一个格子播放一次音效
        if (playMoveSoundSpacePosition.x > 0 and movePositionX >= currPlayMoveSoundPositionX) or
        (playMoveSoundSpacePosition.z > 0 and movePositionZ >= currPlayMoveSoundPositionZ) or
        (playMoveSoundSpacePosition.x < 0 and movePositionX <= currPlayMoveSoundPositionX) or
        (playMoveSoundSpacePosition.z < 0 and movePositionZ <= currPlayMoveSoundPositionZ) then
            XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Move, XSoundManager.SoundType.Sound)
            currPlayMoveSoundPosition = currPlayMoveSoundPosition + playMoveSoundSpacePosition
        end

        
        --检查实体对象是否需要播放状态变化的特效
        if not XTool.IsTableEmpty(entityDistanceList) and curMoveDistance >= entityDistanceList[1].Distance then
            self:CheckEntityDistanceList(entityDistanceList, skillType)
        end

        --检查移动到传送点是否需要播放传送失败的特效
        if not XTool.IsTableEmpty(transPointList) and curMoveDistance >= transPointList[1].Distance then
            local obj = transPointList[1].Obj
            obj:PlayTransFailEffect()
            table.remove(transPointList, 1)
        end
    end, function()
        -- 防止残余
        self:CheckEntityDistanceList(entityDistanceList, skillType)
        self:StopMove(cb)
    end)
end

---检查移动过程中冰火对象转换
function XRpgMakerGameObject:CheckEntityDistanceList(entityDistanceList, skillType)
    if not XTool.IsTableEmpty(entityDistanceList) then
        local entityObj = entityDistanceList[1].EntityObj
        local mapObjData = entityObj:GetMapObjData()
        local type = mapObjData:GetType()
        if type == XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Water or type == XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Ice then
            if entityObj:GetStatus() == XRpgMakerGameConfigs.XRpgMakerGameWaterType.Water and skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Crystal then
                --冰属性角色触发水结冰
                entityObj:SetStatus(XRpgMakerGameConfigs.XRpgMakerGameWaterType.Ice)
                entityObj:CheckPlayFlat()
            elseif entityObj:GetStatus() == XRpgMakerGameConfigs.XRpgMakerGameWaterType.Ice and skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Flame then
                --火属性对象触发冰融化
                entityObj:SetStatus(XRpgMakerGameConfigs.XRpgMakerGameWaterType.Melt)
                entityObj:CheckPlayFlat()
            end
        end
        table.remove(entityDistanceList, 1)
    end
end

function XRpgMakerGameObject:StopMove(cb)
    self:StopPlayMoveActionTimer()

    if self:IsPlayAdsorbAnima() then
        self:SetIsPlayAdsorbAnima(false)
        self:PlayAdsorbAnima(function()
            self:StopMove(cb)
        end)
        return
    end

    self:PlayStandAnima()
    if cb then
        cb()
    end
end

--isEnforceSetObjPos：是否强制设置场景对象的位置
function XRpgMakerGameObject:StopPlayMoveActionTimer(isEnforceSetObjPos)
    if isEnforceSetObjPos and self.PlayMoveActionTimer then
        CSXScheduleManagerUnSchedule(self.PlayMoveActionTimer)
        self.PlayMoveActionTimer = nil
    end

    if isEnforceSetObjPos then
        local cubePosition = self:GetCurPosByCubeUpCenterPosition()
        self:SetGameObjectPosition(Vector3(cubePosition))
    end
end

--改变方向
function XRpgMakerGameObject:ChangeDirectionAction(action, cb)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    self:SetGameObjectLookRotation(action.Direction)

    if cb then
        cb()
    end
end

--获得对应方向的坐标
function XRpgMakerGameObject:GetDirectionPos(direction)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local objPosition = transform.position
    local directionPos
    if direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft then
        directionPos = objPosition + Vector3.left
    elseif direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight then
        directionPos = objPosition + Vector3.right
    elseif direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp then
        directionPos = objPosition + Vector3.forward
    elseif direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown then
        directionPos = objPosition + Vector3.back
    end
    return directionPos
end

--加载模型（只能存在一个）
function XRpgMakerGameObject:LoadModel(modelPath, root, modelName, modelKey)
    --记录旧模型位置
    local oldPos = self:GetGameObjPosition()

    self:Dispose()

    self.ModelPath = modelPath
    self.ModelRoot = root or self.ModelRoot
    self.ModelName = modelName
    self.ModelKey = modelKey or self.ModelKey

    if modelName and self.ModelRoot then
        local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
        self.RoleModelPanel = XUiPanelRoleModel.New(self.ModelRoot, modelName)
        self.RoleModelPanel:UpdateRoleModel(modelName, nil, nil, function(model)
            self:SetModel(model)
            if oldPos then
                self:SetGameObjectPosition(oldPos)
            end
        end, nil, true, true)
    else
        if not modelPath then
            return
        end
        local resource = self:ResourceManagerLoad(modelPath)
        if not resource then
            return
        end
        local model = CS.UnityEngine.Object.Instantiate(resource.Asset)
        local scale = not string.IsNilOrEmpty(modelKey) and XRpgMakerGameConfigs.GetModelScale(modelKey)
        self:BindToRoot(model, self.ModelRoot, scale)
        self:SetModel(model)
    end

    if oldPos then
        self:SetGameObjectPosition(oldPos)
    end
end

---加载技能特效
function XRpgMakerGameObject:LoadSkillEffect(skillType)
    if not self.RoleModelPanel then
        return
    end

    local skillModelKey = XRpgMakerGameConfigs.GetModelSkillEffctKey(skillType)
    if not skillModelKey then
        return
    end

    local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(skillModelKey)
    self.RoleModelPanel:LoadEffect(effectPath, nil, true, true, true)
end

function XRpgMakerGameObject:GetEffectTransform()
    local modelName = self:GetModelName()
    local transform = self:GetTransform()
    if string.IsNilOrEmpty(modelName) then
        return transform
    end
    
    local effectRootName = XRpgMakerGameConfigs.GetRpgMakerGameEffectRoot(modelName)
    if string.IsNilOrEmpty(effectRootName) then
        return transform
    end

    local effectRoot = transform:FindTransform(effectRootName)
    return XTool.UObjIsNil(effectRoot) and transform or effectRoot
end

--加载特效（可加载多个不同的预制）
--isNotUsePool：是否不使用对象池，为true时需自行存储和释放
function XRpgMakerGameObject:LoadEffect(asset, position, rootTransform, isNotUsePool)
    local transform = rootTransform or self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local model
    if isNotUsePool then
        model = XUiHelper.Instantiate(asset)
    else
        model = self.EffectPool[asset]
        if XTool.UObjIsNil(model) then
            model = XUiHelper.Instantiate(asset)
            -- table.insert(self.EffectPool, model)
            self.EffectPool[asset] = model
        end
    end

    self:BindToRoot(model, transform)

    if position then
        model.transform.position = position
    end

    model.gameObject:SetActiveEx(false)
    model.gameObject:SetActiveEx(true)

    return model
end

function XRpgMakerGameObject:BindToRoot(model, root, scale)
    if XTool.UObjIsNil(model) then
        XLog.Error("绑定根节点失败，model不存在")
        return
    end
    model.transform:SetParent(root)
    model.transform.localPosition = CS.UnityEngine.Vector3.zero
    model.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    model.transform.localScale = scale or CS.UnityEngine.Vector3.one
end

function XRpgMakerGameObject:ResetModel()
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    transform.localScale = CS.UnityEngine.Vector3.one

    local position = self:GetCurPosByCubeUpCenterPosition()
    self:SetGameObjectPosition(position)
end

function XRpgMakerGameObject:SetModel(go)
    self.GameObject = go
    self.Transform = go.transform

    self:OnLoadComplete()
end

function XRpgMakerGameObject:GetGameObject()
    return self.GameObject
end

function XRpgMakerGameObject:GetTransform()
    return self.Transform
end

function XRpgMakerGameObject:GetModelName()
    return self.ModelName or ""
end

function XRpgMakerGameObject:GetModelKey()
    return self.ModelKey
end

--设置场景对象位置
local _XOffset, _YOffset, _ZOffset
function XRpgMakerGameObject:SetGameObjectPosition(position, isNotOffset)
    if XTool.UObjIsNil(self.Transform) then
        return
    end

    if not position then
        XLog.Error("XRpgMakerGameObject:SetGameObjectPosition设置场景对象位置错误，position为nil")
        return
    end

    _XOffset, _YOffset, _ZOffset = 0, 0, 0
    local modelName = self:GetModelName()
    if not string.IsNilOrEmpty(modelName) and not isNotOffset then
        _XOffset = XRpgMakerGameConfigs.GetRpgMakerGameXOffSet(modelName)
        _YOffset = XRpgMakerGameConfigs.GetRpgMakerGameYOffSet(modelName)
        _ZOffset = XRpgMakerGameConfigs.GetRpgMakerGameZOffSet(modelName)
    end

    self.Transform.position = position + Vector3(_XOffset, _YOffset, _ZOffset)
end

function XRpgMakerGameObject:GetGameObjPosition()
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    return transform.position
end

--获得模型所在的根节点
function XRpgMakerGameObject:GetGameObjModelRoot()
    return self.ModelRoot
end

--设置场景对象朝向
function XRpgMakerGameObject:SetGameObjectLookRotation(direction)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    local objPos = self:GetGameObjPosition()
    local directionPos = self:GetDirectionPos(direction)
    if not objPos or not directionPos then
        return
    end

    local lookRotation = LookRotation(directionPos - objPos)
    self:SetGameObjectRotation(lookRotation)
end

--设置场景对象角度
function XRpgMakerGameObject:SetGameObjectRotation(rotation)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end
    transform.rotation = rotation
end

--获得场景对象大小
function XRpgMakerGameObject:GetGameObjSize()
    local gameObject = self:GetGameObject()
    if XTool.UObjIsNil(gameObject) then
        return {}
    end

    local meshFilter = gameObject:GetComponent("MeshFilter")
    if not XTool.UObjIsNil(meshFilter) then
        return meshFilter.mesh.bounds.size
    end

    local modelKey = self:GetModelKey()
    return XRpgMakerGameConfigs.GetModelSize(modelKey)
end

function XRpgMakerGameObject:OnLoadComplete()
    self.GoInputHandler = self.Transform:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler = self.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    end

    self.GoInputHandler:AddPointerClickListener(function(eventData) self:OnClick(eventData) end)
    self.GoInputHandler:AddPointerDownListener(function(eventData) self:OnPointerDown(eventData) end)
    self.GoInputHandler:AddPointerUpListener(function(eventData) self:OnPointerUp(eventData) end)
end

function XRpgMakerGameObject:OnClick(eventData)
    local modelKey = self:GetModelKey()
    local modelName = self:GetModelName()
    XDataCenter.RpgMakerGameManager.FireClickObjectCallback(modelKey, modelName)
end

function XRpgMakerGameObject:OnPointerDown()
    XDataCenter.RpgMakerGameManager.FirePointerDownObjectCallback()
end

function XRpgMakerGameObject:OnPointerUp()
    XDataCenter.RpgMakerGameManager.FirePointerUpObjectCallback()
end

--播放攻击动画
function XRpgMakerGameObject:PlayAtkAction(cb)
    local modelName = self:GetModelName()
    local atkAnima = XRpgMakerGameConfigs.GetRpgMakerGameAtkAnimaName(modelName)
    local callBack = function()
        self:PlayStandAnima()
        if cb then
            cb()
        end
    end
    self.RoleModelPanel:PlayAnima(atkAnima, true, callBack, callBack)
end

--播放被攻击特效和音效
function XRpgMakerGameObject:PlayBeAtkAction(cb)
    local modelName = self:GetModelName()
    local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.BeAtkEffect)
    local effectRootName = XRpgMakerGameConfigs.GetRpgMakerGameEffectRoot(modelName)
    local effectRoot
    local beAtkEffect

    --被攻击特效
    if not string.IsNilOrEmpty(effectPath) and not string.IsNilOrEmpty(effectRootName) then
        local transform = self:GetTransform()
        effectRoot = transform:FindTransform(effectRootName)

        local resource = self:ResourceManagerLoad(effectPath)
        if XTool.UObjIsNil(effectRoot) then
            XLog.Error(string.format("XRpgMakerGameObject:PlayBeAtkAction error: 被攻击特效父节点找不到, effectRootName: %s", effectRootName))
        else
            beAtkEffect = self:LoadEffect(resource.Asset, effectRoot.transform.position, effectRoot)
        end
    end

    XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Death, XSoundManager.SoundType.Sound)

    local delay = XRpgMakerGameConfigs.BeAtkEffectDelayCallbackTime
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(beAtkEffect) then
            beAtkEffect.gameObject:SetActiveEx(false)
        end
        self:Death(cb)
    end, delay)
end

function XRpgMakerGameObject:Death(cb)
    self:SetActive(false)
    if cb then
        cb()
    end
end

--播放站立动画
function XRpgMakerGameObject:PlayStandAnima()
    local modelName = self:GetModelName()
    local standAnima = XRpgMakerGameConfigs.GetRpgMakerGameStandAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(standAnima)
end

--播放进入陷阱死亡动画
function XRpgMakerGameObject:PlayDieByTrapAnima(cb)
    local easeMethod = function(f)
        return XUiHelper.Evaluate(XUiHelper.EaseType.Increase, f)
    end

    local objPos = self:GetGameObjPosition()
    local scale
    XUiHelper.Tween(DieByTrapTime, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        self:SetGameObjectPosition(Vector3(objPos.x, objPos.y - f * objPos.y, objPos.z), true)

        scale = 1 - f
        self:SetGameObjScale(Vector3(scale, scale, scale))
    end, function()
        self:ResetModel()
        self:Death(cb)
    end, easeMethod)

    XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_DieByTrap, XSoundManager.SoundType.Sound)
end

--播放被电死亡动画
function XRpgMakerGameObject:PlayKillByElectricFenceAnima(cb)
    local callback = function()
        self:Death(cb)
    end
    local modelName = self:GetModelName()
    local electricFenceAnima = XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(electricFenceAnima, true, callback, callback)

    --被电的材质动画和特效
    local killByElectricFenceEffectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(KillByElectricFenceEffectName)
    self.RoleModelPanel:LoadEffect(killByElectricFenceEffectPath, KillByElectricFenceEffectName, true, true, true)

    XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Elecboom, XSoundManager.SoundType.Sound)
end

--播放惊吓动画
function XRpgMakerGameObject:PlayAlarmAnima(cb)
    local modelName = self:GetModelName()
    local alarmAnima = XRpgMakerGameConfigs.GetRpgMakerGameAlarmAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(alarmAnima, true, cb, cb)
end

---------溺死相关 begin----------
--设置溺死，判断播放哪种动画
--x, y：二维坐标
function XRpgMakerGameObject:DieByDrown(mapId, x, y)
    local isDieByDrown = true
    local entityMapDataList = XRpgMakerGameConfigs.GetMixBlockEntityListByPosition(mapId, x, y)
    if XTool.IsTableEmpty(entityMapDataList) then
        return
    end

    for _, entityMapData in pairs(entityMapDataList) do
        local type = entityMapData:GetType()
        if type == XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Water or type == XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Ice then
            local entityId = XRpgMakerGameConfigs.GetEntityIndex(mapId, entityMapData)
            --目的地是冰面，会死说明站在冰面融化了，不播放模型动作
            local entityObj = XDataCenter.RpgMakerGameManager.GetEntityObj(entityId)
            local isNotPlayDrownAnima = (entityObj) and (entityObj:GetStatus() == XRpgMakerGameConfigs.XRpgMakerGameWaterType.Ice or entityObj:GetStatus() == XRpgMakerGameConfigs.XRpgMakerGameWaterType.Melt)
            self:SetDieByDrownAction(isDieByDrown, isNotPlayDrownAnima, entityObj)
            return
        end
    end
end

function XRpgMakerGameObject:SetDieByDrownAction(isDieByDrown, isNotPlayDrownAnima, entityObj)
    if isDieByDrown ~= nil then
        self._IsDieByDrown = isDieByDrown
    end
    if isNotPlayDrownAnima ~= nil then
        self._IsNotPlayDrownAnima = isNotPlayDrownAnima
    end
    if entityObj ~= nil then
        self._PlayDrownEffectObj = entityObj
    end
end

function XRpgMakerGameObject:ClearDrown()
    self._IsNotPlayDrownAnima = false   --是否不播放溺死的动作，为true时改播渐渐变小并落下的动画
    self._IsDieByDrown = false  --是否溺死
    self._PlayDrownEffectObj = nil  --播放落水特效的对象
end

function XRpgMakerGameObject:IsDieByDrown()
    return self._IsDieByDrown
end

function XRpgMakerGameObject:IsNotPlayDrownAnima()
    return self._IsNotPlayDrownAnima
end

--播放溺死动画
--isNotPlayAnima：是否不播放溺死的动作；为true时改播渐渐变小并落下的动画
function XRpgMakerGameObject:PlayDrownAnima(cb, isNotPlayAnima)
    isNotPlayAnima = isNotPlayAnima ~= nil and isNotPlayAnima or self:IsNotPlayDrownAnima()

    local callback = function()
        XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_DieByDrown, XSoundManager.SoundType.Sound)
        self:PlayDrownEffect()
        self:ClearDrown()
        self:Death(cb)
    end

    if isNotPlayAnima then
        local easeMethod = function(f)
            return XUiHelper.Evaluate(XUiHelper.EaseType.Increase, f)
        end

        local objPos = self:GetGameObjPosition()
        local scale
        local isShowDrownEffect = true
        XUiHelper.Tween(DieByTrapTime, function(f)
            if XTool.UObjIsNil(self.Transform) then
                return
            end

            self:SetGameObjectPosition(Vector3(objPos.x, objPos.y - f * objPos.y, objPos.z), true)

            scale = 1 - f
            self:SetGameObjScale(Vector3(scale, scale, scale))
        end, function()
            self:ResetModel()
            callback()
        end, easeMethod)
        return
    end

    local modelName = self:GetModelName()
    local drownAnima = XRpgMakerGameConfigs.GetRpgMakerGameDrownAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(drownAnima, true, callback, callback)
end

--播放落水特效
function XRpgMakerGameObject:PlayDrownEffect()
    local obj = self._PlayDrownEffectObj
    if not obj then
        return
    end
    local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.Drown)
    local resource = obj:ResourceManagerLoad(effectPath)
    local drownEffect = obj:LoadEffect(resource.Asset)
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(drownEffect) then
            drownEffect.gameObject:SetActiveEx(false)
        end
    end, XScheduleManager.SECOND)
end
---------溺死相关 end----------

---------钢板相关 begin----------
--检查是否需要播放钢板吸附动作
function XRpgMakerGameObject:CheckIsSteelAdsorb(mapId, x, y, skillType)
    if skillType ~= XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Raiden then
        return
    end
    local isPlay = XRpgMakerGameConfigs.IsSameMixBlock(mapId, x, y, XRpgMakerGameConfigs.XRpgMakeBlockMetaType.Steel)
    self:SetIsPlayAdsorbAnima(isPlay)
end

function XRpgMakerGameObject:SetIsPlayAdsorbAnima(isPlay)
    self._IsPlayAdsorb = isPlay
end

function XRpgMakerGameObject:IsPlayAdsorbAnima()
    return self._IsPlayAdsorb and true or false
end

--播放吸附动作
function XRpgMakerGameObject:PlayAdsorbAnima(cb)
    local modelName = self:GetModelName()
    local adsorbAnima = XRpgMakerGameConfigs.GetRpgMakerGameAdsorbAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(adsorbAnima, true, cb, cb)
    XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Adsorb, XSoundManager.SoundType.Sound)
end
---------钢板相关 end----------

---------传送相关 begin----------
local _IsTranser --是否传送
function XRpgMakerGameObject:SetIsTranser(isTranser)
    _IsTranser = isTranser
end

function XRpgMakerGameObject:IsTranser()
    return _IsTranser
end

--传送
--startPosX, startPosZ：开始传送的位置（地面的二维坐标）
--endPosX, endPosY：结束传送的位置（地面的二维坐标）
function XRpgMakerGameObject:PlayTransfer(startPosX, startPosY, endPosX, endPosY, cb)
    self:SetIsTranser(false)
    local gameObjPosition = self:GetGameObjPosition()
    local startCubePosition = self:GetCubeUpCenterPosition(startPosY, startPosX)
    local cubeDistance = CS.UnityEngine.Vector3.Distance(gameObjPosition, startCubePosition)
    local playActionTime = cubeDistance / MoveSpeed
    local transform = self:GetTransform()
    local moveX = startCubePosition.x - gameObjPosition.x
    local moveZ = startCubePosition.z - gameObjPosition.z

    --当前位置到传送点的位移
    local movePositionX, movePositionZ
    local moveToTransPointFunc = XUiHelper.Tween(0.5, function(f)
        if XTool.UObjIsNil(transform) then
            return
        end
        movePositionX = gameObjPosition.x + moveX * f
        movePositionZ = gameObjPosition.z + moveZ * f
        self:SetGameObjectPosition(Vector3(movePositionX, gameObjPosition.y, movePositionZ))
    end)

    self:PlayTransferDisAnima(function()
        if moveToTransPointFunc then
            CSXScheduleManagerUnSchedule(moveToTransPointFunc)
            moveToTransPointFunc = nil
        end
        local endCubePosition = self:GetCubeUpCenterPosition(endPosY, endPosX)
        self:SetGameObjectPosition(Vector3(endCubePosition.x, gameObjPosition.y, endCubePosition.z))
        self:PlayTransferAnima(cb)
    end)
end

--播放传送消失动作
function XRpgMakerGameObject:PlayTransferDisAnima(cb)
    local modelName = self:GetModelName()
    local transferDis = XRpgMakerGameConfigs.GetRpgMakerGameTransferDisAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(transferDis, true, cb, cb)
    XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_TransferDis, XSoundManager.SoundType.Sound)
end

--播放传送出现动作
function XRpgMakerGameObject:PlayTransferAnima(cb)
    local modelName = self:GetModelName()
    local transferAnima = XRpgMakerGameConfigs.GetRpgMakerGameTransferAnimaName(modelName)
    self.RoleModelPanel:PlayAnima(transferAnima, true, cb, cb)
    XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Transfer, XSoundManager.SoundType.Sound)
end
---------传送相关 end----------

--#region 掉落物相关

---角色捡起掉落物动画
---@param cb function
function XRpgMakerGameObject:PlayPickUpAnim(cb)
    local modelName = self:GetModelName()
    local transferAnima = XRpgMakerGameConfigs.GetRpgMakerGameDropPickAnimaName(modelName)
    local callBack = function()
        self:PlayStandAnima()
        if cb then
            cb()
        end
    end
    self.RoleModelPanel:PlayAnima(transferAnima, true, callBack, callBack)
    -- XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Transfer, XSoundManager.SoundType.Sound)
end

--#endregion


--#region 魔法阵相关

---角色魔法阵传送特效
---@param cb function
function XRpgMakerGameObject:PlayMagicTransferAnim(endPosX, endPosY, cb)
    local gameObjPosition = self:GetGameObjPosition()
    --当前位置到传送点的位移
    self:PlayMagicTransferDisEffect(function()
        local endCubePosition = self:GetCubeUpCenterPosition(endPosY, endPosX)
        self:SetGameObjectPosition(Vector3(endCubePosition.x, gameObjPosition.y, endCubePosition.z))
        self:PlayMagicTransferEffect(cb)
    end)
end

--播放传送阵消失特效
function XRpgMakerGameObject:PlayMagicTransferDisEffect(cb)
    if XTool.UObjIsNil(self._MagicDisEffect) then
        local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.MagicDisEffect)
        local resource = self:ResourceManagerLoad(effectPath)
        local position = self:GetTransform().position
        if not position then
            return
        end
        self._MagicDisEffect = self:LoadEffect(resource.Asset, position)
    end
    self._MagicDisEffect.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(self._MagicDisEffect) then
            self._MagicDisEffect.gameObject:SetActiveEx(false)
        end
        if cb then cb() end
    end, XScheduleManager.SECOND)
    XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_TransferDis, XSoundManager.SoundType.Sound)
end

--播放传送阵出现特效
function XRpgMakerGameObject:PlayMagicTransferEffect(cb)
    if XTool.UObjIsNil(self._MagicShowEffect) then
        local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameModelPath(XRpgMakerGameConfigs.ModelKeyMaps.MagicShowEffect)
        local resource = self:ResourceManagerLoad(effectPath)
        local position = self:GetTransform().position
        if not position then
            return
        end
        self._MagicShowEffect = self:LoadEffect(resource.Asset, position)
    end
    self._MagicShowEffect.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(self._MagicDisEffect) then
            self._MagicShowEffect.gameObject:SetActiveEx(false)
        end
        if cb then cb() end
    end, XScheduleManager.SECOND)
    XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Transfer, XSoundManager.SoundType.Sound)
end

--#endregion


--#region 泡泡相关

---推动泡泡动画
---@param cb function
function XRpgMakerGameObject:PlayPushBubbleAnim(cb)
    local modelName = self:GetModelName()
    local pushAnima = XRpgMakerGameConfigs.GetRpgMakerGameBubblePushAnimaName(modelName)
    local callBack = function()
        self:PlayStandAnima()
        if cb then
            cb()
        end
    end
    self.RoleModelPanel:PlayAnima(pushAnima, true, callBack, callBack)
    -- XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Transfer, XSoundManager.SoundType.Sound)
end

--#endregion

function XRpgMakerGameObject:SetActive(isActive)
    local gameObject = self:GetGameObject()
    if XTool.UObjIsNil(gameObject) then
        return
    end
    gameObject:SetActiveEx(isActive)

    if self.RoleModelPanel then
        self.RoleModelPanel:HideEffectByParentName(KillByElectricFenceEffectName)
    end
end

function XRpgMakerGameObject:IsActive()
    local gameObject = self:GetGameObject()
    if XTool.UObjIsNil(gameObject) then
        return false
    end
    return gameObject.activeSelf
end

function XRpgMakerGameObject:SetGameObjScale(scale)
    if XTool.UObjIsNil(self.Transform) then
        return
    end

    self.Transform.localScale = scale
end

function XRpgMakerGameObject:GetCubeObj(row, col)
    return XDataCenter.RpgMakerGameManager.GetSceneCubeObj(row, col)
end

function XRpgMakerGameObject:GetCubeUpCenterPosition(row, col)
    return XDataCenter.RpgMakerGameManager.GetSceneCubeUpCenterPosition(row, col)
end

function XRpgMakerGameObject:GetCubeTransform(row, col)
    return XDataCenter.RpgMakerGameManager.GetSceneCubeTransform(row, col)
end

--获得当前模型所在的3D场景坐标
function XRpgMakerGameObject:GetCurPosByCubeUpCenterPosition()
    local x = self:GetPositionX()
    local y = self:GetPositionY()
    return self:GetCubeUpCenterPosition(y, x)
end

function XRpgMakerGameObject:ResourceManagerLoad(path)
    local resource = self.ResourcePool[path]
    if resource then
        return resource
    end
    
    resource = CSXResourceManagerLoad(path)
    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XRpgMakerGameObject:ResourceManagerLoad加载资源失败，路径：%s", path))
        return
    end

    self.ResourcePool[path] = resource
    return resource
end

function XRpgMakerGameObject:GetStatus()
end
--------------场景对象相关 end------------------
return XRpgMakerGameObject