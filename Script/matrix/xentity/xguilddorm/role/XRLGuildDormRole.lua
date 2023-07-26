---@class XRLGuildDormRole
local XRLGuildDormRole = XClass(nil, "XRLGuildDormRole")

function XRLGuildDormRole:Ctor(id)
    self.Id = id
    -- 角色资源
    self.Resource = nil
    self.GameObject = nil
    self.Transform = nil
    -- 动画组件
    self.Animator = nil
    -- 角色控制器组件
    self.CharacterController = nil
    self.PlayerId = nil
    self.SkinWidth = XGuildDormConfig.GetRoleCCSkinWidth(id)
    self.TempCopyFollowGo = nil
    self.InteractInfos = nil
    self.ChessRendering = nil
    self.CurrentRenderingAlpha = 1
    self.AlphaTweenId = nil
    self.AnimationFrameEventManager = nil
    self.NPCRendering = nil
end

function XRLGuildDormRole:GetChessRendering()
    if self.ChessRendering == nil then
        self.ChessRendering = self.GameObject:AddComponent(typeof(CS.XChessRendering))
    end
    return self.ChessRendering
end

function XRLGuildDormRole:PlayTargetAlphaAnim(value, time, cb)
    if time == nil then time = 0.5 end
    if self.CurrentRenderingAlpha == value then return end
    self:ResetAlphaTweenId()
    if value > 0 then
        self:SetSubGosActive(true)
    end
    local offset = self.CurrentRenderingAlpha - value
    self.AlphaTweenId = XUiHelper.Tween(time, function(weight)
        self:GetChessRendering():SetTransparent(self.CurrentRenderingAlpha - offset * weight)
    end, function()
        self.CurrentRenderingAlpha = value
        self:GetChessRendering():SetTransparent(value)
        self:SetSubGosActive(value > 0)
        if cb then cb() end
    end)
end

function XRLGuildDormRole:SetTransparent(value)
    self:GetChessRendering():SetTransparent(value)
    self.CurrentRenderingAlpha = value
    self:SetSubGosActive(value > 0)
end

function XRLGuildDormRole:SetSubGosActive(value)
    for i = 0, self.Transform.childCount - 1 do
        self.Transform:GetChild(i).gameObject:SetActiveEx(value)
    end
end

function XRLGuildDormRole:UpdateRoleId(roleId)
    self.Id = roleId
    self.SkinWidth = XGuildDormConfig.GetRoleCCSkinWidth(roleId)
    local hasCC = self.CharacterController ~= nil
    local x, y, z, angle = self.Transform.position.x
        , self.Transform.position.y
        , self.Transform.position.z
        , self.Transform.rotation.eulerAngles.y
    self:UpdateModel()
    if hasCC then
        self:CreateCharacterController()
    end
    self.GameObject:SetActiveEx(true)
    self:UpdateTransform(x, y, z,angle)
end

function XRLGuildDormRole:UpdatePlayerId(value)
    self.PlayerId = value
end

function XRLGuildDormRole:CheckIsSelfPlayer()
    return self.PlayerId == XPlayer.Id
end

function XRLGuildDormRole:GetSkinWidth()
    return self.SkinWidth
end

-- 加载模型
-- root : 模型加载所在的根transform节点
function XRLGuildDormRole:LoadModel(root)
    local assetPath = XGuildDormConfig.GetModelPathByRoleId(self.Id)
    -- 先清空下原有的资源
    self:Dispose()
    -- 加载检查资源
    local resource = CS.XResourceManager.Load(assetPath)
    if resource == nil or not resource.Asset then
        XLog.Error(string.format("加载公会宿舍角色资源:%s失败", assetPath))
        return
    end
    -- 设置资源
    self.Resource = resource
    local model = CS.UnityEngine.Object.Instantiate(resource.Asset)
    -- 重置到根节点上
    model.transform:SetParent(root)
    model.transform.localPosition = CS.UnityEngine.Vector3.zero
    model.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    model.transform.localScale = CS.UnityEngine.Vector3.one
    -- 设置gameObject
    self.GameObject = model
    self.Transform = model.transform
    -- 设置动画组件
    self.Animator = self.GameObject:GetComponent(typeof(CS.UnityEngine.Animator))
    --层级
    self.GameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer(HomeSceneLayerMask.HomeCharacter))
    --阴影 开关
    local isSelfPlayer = self:CheckIsSelfPlayer()
    if isSelfPlayer and CS.XMaterialContainerHelper.GlobalShadowVolumeEnable() then
        CS.XMaterialContainerHelper.SetCharacterShadowVolumeEnable(self.GameObject, true)
        CS.XMaterialContainerHelper.ProcessCharacterShadowVolume(self.GameObject)
        CS.XShadowHelper.RemoveShadow(self.GameObject, true)
    else
        CS.XMaterialContainerHelper.SetCharacterShadowVolumeEnable(self.GameObject, false)
        CS.XShadowHelper.AddShadow(self.GameObject, true)
    end
    --动态骨骼 开关
    CS.XMaterialContainerHelper.SetDynamicBoneManagerEnable(self.GameObject,self:CheckIsSelfPlayer())
    --npc rendering
    local renderingUIProxy = CS.XNPCRendingUIProxy.GetNPCRendingUIProxy(self.GameObject)
    self.NPCRendering = renderingUIProxy.NPCRendering
    -- 动画事件管理
    self:UpdateFrameEventManager()
    -- 3d音效
    if self:CheckIsSelfPlayer() then
        local listener = self.GameObject:GetComponent(typeof(CS.CriAtomListener))
        if not listener then
            listener = self.GameObject:AddComponent(typeof(CS.CriAtomListener))
        end
    end
    -- 默认隐藏
    self.GameObject:SetActiveEx(false)
    XDataCenter.GuildDormManager.SceneManager.AddSceneObj(self.GameObject, self)
    return self.GameObject
end

function XRLGuildDormRole:UpdateModel(root)
    if root == nil then root = self.Transform.parent end
    self:LoadModel(root)
end

function XRLGuildDormRole:UpdateFrameEventManager()
    local frameEventManager = self.GameObject:GetComponent(typeof(CS.XAnimationFrameEventManager))
    if not frameEventManager then
        frameEventManager = self.GameObject:AddComponent(typeof(CS.XAnimationFrameEventManager))
    end
    self.AnimationFrameEventManager = frameEventManager
    self.AnimationFrameEventManager.EnableStepSound = self:CheckIsSelfPlayer()
end

function XRLGuildDormRole:UpdateCurrentStepCueId(value)
    if self.AnimationFrameEventManager then
        self.AnimationFrameEventManager.StepCueId = value
    end
end

function XRLGuildDormRole:Born(x, y, z, angle, isShow)
    self.GameObject:SetActiveEx(true)
    self:UpdateTransform(x, y, z, angle)
    self:SetMeshRenderersIsEnable(isShow)
end

function XRLGuildDormRole:BornWithTransform(transform, isShow)
    self.GameObject:SetActiveEx(true)
    self:SetMeshRenderersIsEnable(isShow)
    self.Transform.position = transform.position
    self.Transform.rotation = transform.rotation
end

function XRLGuildDormRole:UpdateTransform(x, y, z, angle)
    self.Transform.position = CS.UnityEngine.Vector3(x, y, z)
    local eulerAngles = self.Transform.rotation.eulerAngles
    local rotation = CS.UnityEngine.Quaternion.Euler(
        CS.UnityEngine.Vector3(eulerAngles.x, angle, eulerAngles.z))
    self.Transform.rotation = rotation
end

function XRLGuildDormRole:CreateCharacterController()
    local height, radius, center, skinWidth = XGuildDormConfig.GetCharacterControllerArgs(self.Id)
    -- 设置角色控制器组件
    self.CharacterController = self.GameObject:GetComponent(typeof(CS.UnityEngine.CharacterController))
    if XTool.UObjIsNil(self.CharacterController) then
        self.CharacterController = self.GameObject:AddComponent(typeof(CS.UnityEngine.CharacterController))
        self.CharacterController.height = height
        self.CharacterController.radius = radius
        self.CharacterController.center = center
        self.CharacterController.skinWidth = skinWidth
    end
    return self.CharacterController
end

---@return UnityEngine.CharacterController
function XRLGuildDormRole:GetCharacterController()
    return self.CharacterController
end

---@return UnityEngine.Transform
function XRLGuildDormRole:GetTransform()
    return self.Transform
end

function XRLGuildDormRole:GetGameObject()
    return self.GameObject
end

function XRLGuildDormRole:SetAlpha(alpha, useDistanceDither)
    self.NPCRendering:SetAlpha(alpha, useDistanceDither)
end

function XRLGuildDormRole:PlayAnimation(actionId, needFadeCross, crossDuration)
    if needFadeCross then
        self.Animator:CrossFade(actionId, crossDuration, -1, 0)
    else
        self.Animator:Play(actionId, -1, 0)
    end
end

function XRLGuildDormRole:UpdateCameraFollow(isFollowCopy)
    if isFollowCopy == nil then isFollowCopy = false end
    -- 设置摄像机跟随角色
    local cameraController = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCameraController()
    cameraController.IsTweenCamera = true
    if isFollowCopy then
        if XTool.UObjIsNil(self.TempCopyFollowGo) then
            local go = CS.UnityEngine.GameObject(self.GameObject.name .. "_follow_copy")
            self.TempCopyFollowGo = go
            self.TempCopyFollowGo.transform:SetParent(self.Transform.parent)
        end
        self.TempCopyFollowGo.transform.position = self.Transform.position        
        cameraController:SetFollowObj(self.TempCopyFollowGo.transform, 0, false)
    else
        cameraController:SetFollowObj(self:GetTransform(), 0, false)
    end
end

function XRLGuildDormRole:DisableColliders(IsDisableTrigger)
    if IsDisableTrigger == nil then IsDisableTrigger = false end
    local colliders = self:GetTransform():GetComponentsInChildren(typeof(CS.UnityEngine.Collider))
    for i = 0, colliders.Length - 1 do
        if IsDisableTrigger then
            colliders[i].isTrigger = true
        else
            colliders[i].enabled = false
        end
    end
end

-- 设置Npc触发器半径
function XRLGuildDormRole:SetCollidersRadius(value)
    if not XTool.IsNumberValid(value) then
        return
    end
    local colliders = self:GetTransform():GetComponentsInChildren(typeof(CS.UnityEngine.CapsuleCollider))
    for i = 0, colliders.Length - 1 do
        colliders[i].radius = value
    end
end

function XRLGuildDormRole:SetMeshRenderersIsEnable(value)
    if self.__MeshRenderersIsEnable == value then return end
    self.__MeshRenderersIsEnable = value
    local meshRenderers = self:GetTransform():GetComponentsInChildren(typeof(CS.UnityEngine.SkinnedMeshRenderer))
    for i = 0, meshRenderers.Length - 1 do
        meshRenderers[i].enabled = value
    end
end

function XRLGuildDormRole:SetCollidersLayer(layer)
    local colliders = self:GetTransform():GetComponentsInChildren(typeof(CS.UnityEngine.Collider))
    for i = 0, colliders.Length - 1 do
        colliders[i].gameObject.layer = layer
    end
end

function XRLGuildDormRole:Dispose()
    if not XTool.UObjIsNil(self.GameObject) then 
        XDataCenter.GuildDormManager.SceneManager.RemoveObj(self.GameObject)
    end
    -- 清空gameObject
    if self.GameObject and self.GameObject:Exist() then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
        self.GameObject = nil
        self.Transform = nil
    end
    if self.TempCopyFollowGo and self.TempCopyFollowGo:Exist() then
        CS.UnityEngine.GameObject.Destroy(self.TempCopyFollowGo)
    end
    -- 清空资源
    if self.Resource then
        self.Resource:Release()
        self.Resource = nil
    end
    self.Animator = nil
    self.CharacterController = nil
    self.TempCopyFollowGo = nil
    self.InteractInfos = nil
    self.ChessRendering = nil
    self.CurrentRenderingAlpha = 1
    self.AnimationFrameEventManager = nil
    self:ResetAlphaTweenId()
end

function XRLGuildDormRole:ResetAlphaTweenId()
    if self.AlphaTweenId then
        XScheduleManager.UnSchedule(self.AlphaTweenId)
    end
    self.AlphaTweenId = nil
end

function XRLGuildDormRole:CheckCanInteract()
    return self.InteractInfos ~= nil
end

function XRLGuildDormRole:AddInteractInfo(value)
    if self.InteractInfos == nil then
        self.InteractInfos = {}
    end
    table.insert(self.InteractInfos, value)
end

function XRLGuildDormRole:GetInteractInfoList()
    return self.InteractInfos[1]
end

function XRLGuildDormRole:SetAnimatorController(value)
    if self.Animator == nil then return end
    self.Animator.runtimeAnimatorController = value
end

return XRLGuildDormRole