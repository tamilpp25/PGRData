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
end

function XRLGuildDormRole:UpdateRoleId(roleId)
    self.Id = roleId
    self.SkinWidth = XGuildDormConfig.GetRoleCCSkinWidth(roleId)
    local hasCC = self.CharacterController ~= nil
    local x, z, angle = self.Transform.position.x
        , self.Transform.position.z
        , self.Transform.rotation.eulerAngles.y
    self:UpdateModel()
    if hasCC then
        self:CreateCharacterController()
    end
    self.GameObject:SetActiveEx(true)
    self:UpdateTransform(x,z,angle)
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
    local isSelfPlayer = self:CheckIsSelfPlayer();
    if isSelfPlayer and CS.XMaterialContainerHelper.GlobalShadowVolumeEnable() then
        CS.XMaterialContainerHelper.SetCharacterShadowVolumeEnable(self.GameObject, true)
        CS.XMaterialContainerHelper.ProcessCharacterShadowVolume(self.GameObject)
        CS.XShadowHelper.RemoveShadow(self.GameObject)
    else
        CS.XMaterialContainerHelper.SetCharacterShadowVolumeEnable(self.GameObject, false)
        CS.XShadowHelper.AddShadow(self.GameObject)
    end
    --动态骨骼 开关
    CS.XMaterialContainerHelper.SetDynamicBoneManagerEnable(self.GameObject,self:CheckIsSelfPlayer())
    -- 默认隐藏
    self.GameObject:SetActiveEx(false)
    XDataCenter.GuildDormManager.SceneManager.AddSceneObj(self.GameObject, self)
    return self.GameObject
end

function XRLGuildDormRole:UpdateModel(root)
    if root == nil then root = self.Transform.parent end
    self:LoadModel(root)
end

function XRLGuildDormRole:Born(x, z, angle, isShow)
    self.GameObject:SetActiveEx(true)
    self:UpdateTransform(x, z, angle)
    self:SetMeshRenderersIsEnable(isShow)
end

function XRLGuildDormRole:UpdateTransform(x, z, angle)
    self.Transform.position = CS.UnityEngine.Vector3(x, self.SkinWidth, z)
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

function XRLGuildDormRole:GetCharacterController()
    return self.CharacterController
end

function XRLGuildDormRole:GetTransform()
    return self.Transform
end

function XRLGuildDormRole:GetGameObject()
    return self.GameObject
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

function XRLGuildDormRole:DisableColliders()
    local colliders = self:GetTransform():GetComponentsInChildren(typeof(CS.UnityEngine.Collider))
    for i = 0, colliders.Length - 1 do
        colliders[i].enabled = false
    end
end

function XRLGuildDormRole:SetMeshRenderersIsEnable(value)
    local meshRenderers = self:GetTransform():GetComponentsInChildren(typeof(CS.UnityEngine.SkinnedMeshRenderer))
    for i = 0, meshRenderers.Length - 1 do
        meshRenderers[i].enabled = value
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
end

return XRLGuildDormRole