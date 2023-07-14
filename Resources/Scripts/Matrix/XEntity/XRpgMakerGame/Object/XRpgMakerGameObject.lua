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
    self.Animator = nil     --动画控制器
    self.ModelPath = nil    --模型路径
    self.ModelRoot = nil    --模型根节点
    self.ModelName = nil    --模型名，作为key检索其他配置表用，可为nil

    if not XTool.UObjIsNil(gameObject) then
        self:SetModel(gameObject)
    end
end

function XRpgMakerGameObject:Dispose()
    if not XTool.UObjIsNil(self.BeAtkEffect) then
        CS.UnityEngine.GameObject.Destroy(self.BeAtkEffect)
        self.BeAtkEffect = nil
    end

    if self.BeAtkResource then
        self.BeAtkResource:Release()
        self.BeAtkResource = nil
    end

    if not XTool.UObjIsNil(self.GameObject) then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
        self.GameObject = nil
        self.Transform = nil
    end

    if self.ModelResource then
        self.ModelResource:Release()
        self.ModelResource = nil
    end

    self.ModelPath = nil
end

function XRpgMakerGameObject:SetId(id)
    self._Id = id
end

function XRpgMakerGameObject:GetId()
    return self._Id
end

--------------场景对象相关 begin----------------
--移动
function XRpgMakerGameObject:PlayMoveAction(action, cb)
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
    local distance = math.sqrt(XTool.MathPow((endPosY-startPosY), 2) + XTool.MathPow((endPosX - startPosX), 2))
    local playMoveSoundSpacePosition = distance > 0 and (endCubePosition - startCubePosition) / distance or Vector3(0, 0, 0)
    local currPlayMoveSoundPosition = startCubePosition + playMoveSoundSpacePosition

    self:SetGameObjectPosition(startCubePosition)

    local moveX = endCubePosition.x - startCubePosition.x
    local moveZ = endCubePosition.z - startCubePosition.z

    local gameObjPositionY = transform.position.y

    self:ChangeDirectionAction(action)

    local modelName = self:GetModelName()
    local runAnima = XRpgMakerGameConfigs.GetRpgMakerGameRunAnimaName(modelName)
    self:PlayAnima(runAnima)

    local movePositionX
    local movePositionZ
    local currPlayMoveSoundPositionX
    local currPlayMoveSoundPositionZ
    local tempCount = 1
    self.PlayMoveActionTimer = XUiHelper.Tween(playActionTime, function(f)
        if XTool.UObjIsNil(transform) then
            return
        end

        movePositionX = startCubePosition.x + moveX * f
        movePositionZ = startCubePosition.z + moveZ * f
        self:SetGameObjectPosition(Vector3(movePositionX, gameObjPositionY, movePositionZ))

        --保留2位小数
        movePositionX = movePositionX - movePositionX % 0.01
        movePositionZ = movePositionZ - movePositionZ % 0.01
        currPlayMoveSoundPositionX = currPlayMoveSoundPosition.x - currPlayMoveSoundPosition.x % 0.01
        currPlayMoveSoundPositionZ = currPlayMoveSoundPosition.z - currPlayMoveSoundPosition.z % 0.01
        --每移动一个格子播放一次音效
        if ((playMoveSoundSpacePosition.x > 0 or playMoveSoundSpacePosition.z > 0) and movePositionX >= currPlayMoveSoundPositionX and movePositionZ >= currPlayMoveSoundPositionZ)
            or ((playMoveSoundSpacePosition.x < 0 or playMoveSoundSpacePosition.z < 0) and movePositionX <= currPlayMoveSoundPositionX and movePositionZ <= currPlayMoveSoundPositionZ) then
            XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Move, XSoundManager.SoundType.Sound)
            currPlayMoveSoundPosition = currPlayMoveSoundPosition + playMoveSoundSpacePosition
        end
    end, function ()
        self:StopPlayMoveActionTimer()
        self:PlayStandAnima(function()
            if cb then
                cb()
            end
        end)
    end)
end

--isEnforceSetObjPos：是否强制设置场景对象的位置
function XRpgMakerGameObject:StopPlayMoveActionTimer(isEnforceSetObjPos)
    if isEnforceSetObjPos and self.PlayMoveActionTimer then
        CSXScheduleManagerUnSchedule(self.PlayMoveActionTimer)
        self.PlayMoveActionTimer = nil
    end

    if isEnforceSetObjPos then
        local x = self:GetPositionX()
        local y = self:GetPositionY()
        local transform = self:GetTransform()
        local cube = self:GetCubeObj(y, x)
        local cubePosition = cube:GetGameObjUpCenterPosition()
        local gameObjPositionY = transform.position.y
        self:SetGameObjectPosition(Vector3(cubePosition.x, gameObjPositionY, cubePosition.z))
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

--加载模型
function XRpgMakerGameObject:LoadModel(modelPath, root, modelName)
    --记录旧模型位置
    local oldPos = self:GetGameObjPosition()

    self:Dispose()

    if not modelPath then
        return
    end

    self.ModelPath = modelPath
    self.ModelRoot = root
    self.ModelName = modelName

    local resource = self:ResourceManagerLoad(modelPath)
    if not resource then
        return
    end
    self.ModelResource = resource

    local model = CS.UnityEngine.Object.Instantiate(resource.Asset)
    self:BindToRoot(model, root)
    self:SetModel(model)

    if oldPos then
        self:SetGameObjectPosition(oldPos)
    end

    local meshFilter = model.transform:GetComponent("MeshFilter")
    if not XTool.UObjIsNil(meshFilter) and meshFilter.mesh then
        local mesh = meshFilter.mesh
        --实例化出来的模型会静态合批，延迟重新设置（预制体tag改成Dynamic就好，等活动结束再删了这代码）
        XScheduleManager.ScheduleOnce(function()
            self:SetGameObjMesh(mesh)
        end, 1)
    end
end

--加载特效
function XRpgMakerGameObject:LoadEffect(asset, position, rootTransform)
    local transform = rootTransform or self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end
    local model = CS.UnityEngine.Object.Instantiate(asset)
    self:BindToRoot(model, transform)

    if position then
        model.transform.position = position
    end

    return model
end

--设置动画控制器
function XRpgMakerGameObject:SetAnimator(modelName, uiName)
    local gameObject = self:GetGameObject()
    if XTool.UObjIsNil(gameObject) then
        return
    end

    --加载controller
    local controllerPath = XModelManager.GetUiControllerPath(modelName)
    local runtimeController = CS.LoadHelper.LoadUiController(controllerPath, uiName)
    self.Animator = gameObject.transform:GetComponent("Animator")
    self.Animator.runtimeAnimatorController = runtimeController
end

--播放动画
--animaName：动画名
--callBack：播放成功回调
--finishCallBack：播放动画结束后或播放失败回调
function XRpgMakerGameObject:PlayAnima(animaName, callBack, finishCallBack)
    local animator = self:GetAnimator()
    local gameObj = self:GetGameObject()
    XModelManager.PlayAnima(gameObj, animator, animaName, nil, callBack, finishCallBack, finishCallBack)
end

function XRpgMakerGameObject:BindToRoot(model, root)
    model.transform:SetParent(root)
    model.transform.localPosition = CS.UnityEngine.Vector3.zero
    model.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    model.transform.localScale = CS.UnityEngine.Vector3.one
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

function XRpgMakerGameObject:GetAnimator()
    return self.Animator
end

function XRpgMakerGameObject:GetModelName()
    return self.ModelName or ""
end

--设置场景对象位置
function XRpgMakerGameObject:SetGameObjectPosition(position)
    local transform = self:GetTransform()
    if XTool.UObjIsNil(transform) then
        return
    end

    if not position then
        XLog.Error("XRpgMakerGameObject:SetGameObjectPosition设置场景对象位置错误，position为nil")
        return
    end

    local xOffset = 0
    local yOffset = 0
    local zOffset = 0
    local modelName = self:GetModelName()
    if not string.IsNilOrEmpty(modelName) then
        xOffset = XRpgMakerGameConfigs.GetRpgMakerGameXOffSet(modelName)
        yOffset = XRpgMakerGameConfigs.GetRpgMakerGameYOffSet(modelName)
        zOffset = XRpgMakerGameConfigs.GetRpgMakerGameZOffSet(modelName)
    end

    transform.position = position + Vector3(xOffset, yOffset, zOffset)
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
    return meshFilter and meshFilter.mesh.bounds.size or {}
end

function XRpgMakerGameObject:OnLoadComplete()
    -- body
end

--播放攻击动画
function XRpgMakerGameObject:PlayAtkAction(cb)
    local modelName = self:GetModelName()
    local atkAnima = XRpgMakerGameConfigs.GetRpgMakerGameAtkAnimaName(modelName)
    self:PlayAnima(atkAnima, nil, function() 
        self:PlayStandAnima()
        if cb then
            cb()
        end
    end)
end

--播放被攻击特效和音效
function XRpgMakerGameObject:PlayBeAtkAction(cb)
    local modelName = self:GetModelName()
    local effectPath = XRpgMakerGameConfigs.GetRpgMakerGameBeAtkEffectPath(modelName)
    local effectRootName = XRpgMakerGameConfigs.GetRpgMakerGameEffectRoot(modelName)
    local effectRoot
    --被攻击特效
    if not string.IsNilOrEmpty(effectPath) and not string.IsNilOrEmpty(effectRootName) then
        local transform = self:GetTransform()
        effectRoot = transform:FindTransform(effectRootName)

        if not self.BeAtkResource then
            self.BeAtkResource = self:ResourceManagerLoad(effectPath)
        end

        if XTool.UObjIsNil(effectRoot) then
            XLog.Error(string.format("XRpgMakerGameObject:PlayBeAtkAction error: 被攻击特效父节点找不到, effectRootName: %s", effectRootName))
        else
            if not self.BeAtkEffect then
                self.BeAtkEffect = self:LoadEffect(self.BeAtkResource.Asset, effectRoot.transform.position, effectRoot)
            end
            if not XTool.UObjIsNil(self.BeAtkEffect) then
                self.BeAtkEffect.gameObject:SetActiveEx(false)
                self.BeAtkEffect.gameObject:SetActiveEx(true)
            end
        end
    end

    XSoundManager.PlaySoundByType(XSoundManager.UiBasicsMusic.RpgMakerGame_Death, XSoundManager.SoundType.Sound)

    local delay = XRpgMakerGameConfigs.BeAtkEffectDelayCallbackTime
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(self.BeAtkEffect) then
            self.BeAtkEffect.gameObject:SetActiveEx(false)
        end
        self:SetActive(false)
        if cb then
            cb()
        end
    end, delay)
end

--播放站立动画
function XRpgMakerGameObject:PlayStandAnima(cb)
    local modelName = self:GetModelName()
    local standAnima = XRpgMakerGameConfigs.GetRpgMakerGameStandAnimaName(modelName)
    self:PlayAnima(standAnima, cb)
end

function XRpgMakerGameObject:SetActive(isActive)
    local gameObject = self:GetGameObject()
    if XTool.UObjIsNil(gameObject) then
        return
    end
    gameObject:SetActiveEx(isActive)
end

function XRpgMakerGameObject:SetGameObjScale(scale)
    local transform = self:GetTransform()
    if not transform then
        return
    end

    transform.localScale = scale
end

function XRpgMakerGameObject:SetGameObjMesh(mesh)
    local transform = self:GetTransform()
    if not transform then
        return
    end

    local meshFilter = transform:GetComponent("MeshFilter")
    if XTool.UObjIsNil(meshFilter) or XTool.UObjIsNil(meshFilter.mesh) then
        return
    end

    meshFilter.mesh = mesh
end

function XRpgMakerGameObject:GetGameObjMesh()
    local transform = self:GetTransform()
    if not transform then
        return
    end

    return transform:GetComponent("MeshFilter").mesh
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

function XRpgMakerGameObject:ResourceManagerLoad(path)
    local resource = CSXResourceManagerLoad(path)
    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XRpgMakerGameObject:ResourceManagerLoad加载资源，路径：%s", path))
        return
    end

    return resource
end
--------------场景对象相关 end------------------

return XRpgMakerGameObject