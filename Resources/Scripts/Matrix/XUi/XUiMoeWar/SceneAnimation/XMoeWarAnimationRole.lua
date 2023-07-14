local XMoeWarAnimationRole = XClass(nil, "XMoeWarAnimationRole")

local Vector3 = CS.UnityEngine.Vector3
local VForward = Vector3.forward

local PLAY_END_ANIM_DISTANCE = CS.XGame.ClientConfig:GetFloat("MoeWarSceneAnimationPlayEndAnimDistance")--当镜头跟随者到达此位置后播放结束镜头动画和慢镜头动作
local PLAY_GOAL_ANIM_DISTANCE = CS.XGame.ClientConfig:GetFloat("MoeWarSceneAnimationGoalDistance")--当镜头跟随者到达此位置后播放冲线特效
local PLAY_RESTORE_ANIM_DISTANCE = CS.XGame.ClientConfig:GetFloat("MoeWarSceneAnimationRestoreDistance")--当镜头跟随者到达此位置后恢复慢镜头动作
local SLOW_DOWN_PERCENT = 0.01 * CS.XGame.ClientConfig:GetInt("MoeWarSceneAnimationSlowdownPercent")--慢动作速度百分比
local END_ANIM_TOTAL_TIME = CS.XGame.ClientConfig:GetInt("MoeWarSceneAnimationTotalTime")--整个终场动画持续时间/s

local SynPlaySlowDownAnim = nil--同步播放慢动作
local SynPlayRestoreAnim = nil--同步恢复原始速度

function XMoeWarAnimationRole:Ctor(index, groupId, parent, uiName, scene, switchCameraCb, endAnimCb, goalAnimCb)
    self.Index = index--赛道Index
    self.GroupId = groupId--动画组Id
    self.ModelParent = parent--角色模型父节点
    self.UiName = uiName
    self.Scene = scene
    self.SwitchCameraCb = switchCameraCb--切换相机回调
    self.EndAnimCb = endAnimCb--终场场景动画回调
    self.GoalAnimCb = goalAnimCb--冲线场景动画回调

    self:Init()
end

function XMoeWarAnimationRole:Dispose()
    self:DestroyTimer()

    for _, effectRoot in pairs(self.SceneEffectRoots) do
        effectRoot.gameObject:SetActiveEx(false)
    end
    self.SceneEffectRoots = {}
end

function XMoeWarAnimationRole:Init()
    self.AnimationIds = XMoeWarConfig.GetAnimationIds(self.GroupId)--动画节点组
    self.CurrentAnimationIndex = 0--当前播放动画Index
    self.CurrentModelName = nil--当前加载角色模型名称
    self.Model = nil--当前加载角色模型
    self.Animator = nil--动画控制器
    self.FollowCameras = {}--跟随相机
    self.SceneEffectRoots = {}--已加载场景特效根节点
    self._IsEnd = nil--全部动画节点是否播放完毕
    self._IsFocus = nil--是否是相机跟随者
    self.PlaySlowDownAnim = nil--播放慢动作
    self.PlayRestoreAnim = nil--恢复原始速度

    SynPlaySlowDownAnim = nil
    SynPlayRestoreAnim = nil

    local modelName = XMoeWarConfig.GetAnimationGroupInitModelName(self.GroupId)
    self:ChangeModel(modelName)
end

--替换模型
function XMoeWarAnimationRole:ChangeModel(modelName)
    if not modelName or modelName == self.CurrentModelName then return end

    --记录旧模型位置
    local oldPos = self.Model and self.Model.transform.localPosition

    --加载新模型
    local prefabPath = XModelManager.GetModelPath(modelName)
    local model = self.ModelParent:LoadPrefab(prefabPath, false)
    self.Model = model

    if oldPos then
        self.Model.transform.localPosition = oldPos
    end

    --加载controller
    local controllerPath = XModelManager.GetUiControllerPath(modelName)
    local runtimeController = CS.LoadHelper.LoadUiController(controllerPath, self.UiName)
    self.Animator = model.transform:GetComponent("Animator")
    self.Animator.runtimeAnimatorController = runtimeController

    --播放初始动画
    local initAnim = XMoeWarConfig.GetAnimationGroupInitAnim(self.GroupId)
    if not string.IsNilOrEmpty(initAnim) then
        self.Animator:Play(initAnim)
    end

    --切换模型时换一个相机跟随保证平滑，否则会延迟回拉
    if self.CurrentModelName and modelName ~= self.CurrentModelName then
        self.SwitchCameraCb(self.Index)
    end

    self.CurrentModelName = modelName
end

--设置跟随虚拟相机
function XMoeWarAnimationRole:SetFollowCamera(virtualCamera)
    if self.FollowCameras[virtualCamera] then return end
    self._IsFocus = true
    self.FollowCameras = {}
    self.FollowCameras[virtualCamera] = virtualCamera
    self:UpdateFollowCameras()
end

function XMoeWarAnimationRole:UpdateFollowCameras()
    for virtualCamera in pairs(self.FollowCameras) do
        virtualCamera.Follow = self.Model.transform
    end
end

--执行动画节点
function XMoeWarAnimationRole:Run()
    local animationIndex = self.CurrentAnimationIndex + 1
    local animationId = self.AnimationIds[animationIndex]

    if not XTool.IsNumberValid(animationId) then
        self:OnExit()
        return
    end

    self.CurrentAnimationIndex = animationIndex
    self._IsEnd = false

    --替换动画模型
    local modelName = XMoeWarConfig.GetAnimationModelName(animationId)
    self:ChangeModel(modelName)

    --角色动作
    local animName = XMoeWarConfig.GetAnimationAnimName(animationId)
    self.Animator:Play(animName)

    --角色特效
    local roleEffect, roleEffectRoot = XMoeWarConfig.GetAnimationRoleEffect(animationId)
    if not string.IsNilOrEmpty(roleEffect)
    and not string.IsNilOrEmpty(roleEffectRoot)
    then
        local effectRoot = self.Model.transform:FindTransform(roleEffectRoot)
        if XTool.UObjIsNil(effectRoot) then
            XLog.Error("XMoeWarAnimationRole:Run error: 角色特效父节点找不到, roleEffectRoot: " .. roleEffectRoot)
        else
            effectRoot:LoadPrefab(roleEffect, false)
            effectRoot.gameObject:SetActiveEx(false)
            effectRoot.gameObject:SetActiveEx(true)
        end
    end

    --场景特效
    local sceneEffect, sceneEffectRoot = XMoeWarConfig.GetAnimationSceneEffect(animationId)
    if not string.IsNilOrEmpty(sceneEffect)
    and not string.IsNilOrEmpty(sceneEffectRoot)
    then
        local effectRoot = self.SceneEffectRoots[sceneEffectRoot]
        if not effectRoot then
            effectRoot = self.Scene:FindTransform(sceneEffectRoot)
            self.SceneEffectRoots[sceneEffectRoot] = effectRoot
        end

        if XTool.UObjIsNil(effectRoot) then
            XLog.Error("XMoeWarAnimationRole:Run error: 场景特效父节点找不到, sceneEffectRoot: " .. sceneEffectRoot)
        else
            effectRoot.gameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer("UiNear"))
            effectRoot:LoadPrefab(sceneEffect, false)
            effectRoot.gameObject:SetActiveEx(false)
            effectRoot.gameObject:SetActiveEx(true)
        end
    end

    --速度
    local speed = XMoeWarConfig.GetAnimationSpeed(animationId)

    --目标点
    local distance = XMoeWarConfig.GetAnimationDistance(animationId)
    local transform = self.Model.transform
    local start = transform.localPosition.z
    local target = start + distance

    --触发动画
    local playEndAnim = nil
    local playGoalAnim = nil

    --角色移动
    local position = nil
    self:DestroyTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(transform) then
            self:DestroyTimer()
            return
        end

        position = transform.localPosition.z

        --到达目标位置后执行下一动画节点
        if position >= target then
            self:DestroyTimer()
            self:Run()
            return
        end

        --终场镜头动画
        if self._IsFocus and position >= PLAY_END_ANIM_DISTANCE then
            if not playEndAnim then
                playEndAnim = true

                --播放场景动画
                self.EndAnimCb(END_ANIM_TOTAL_TIME)
            end

            if not SynPlaySlowDownAnim then
                SynPlaySlowDownAnim = true
            end
        end

        --慢动作
        if SynPlaySlowDownAnim and not self.PlaySlowDownAnim then
            self.PlaySlowDownAnim = true

            speed = speed * SLOW_DOWN_PERCENT
            self.Animator.speed = self.Animator.speed * SLOW_DOWN_PERCENT
        end

        --冲线动画
        if not playGoalAnim and self._IsFocus and position >= PLAY_GOAL_ANIM_DISTANCE then
            playGoalAnim = true

            --播放冲线特效
            self.GoalAnimCb()
        end

        --恢复原始速度
        if self._IsFocus and not SynPlayRestoreAnim and position >= PLAY_RESTORE_ANIM_DISTANCE then
            SynPlayRestoreAnim = true
        end

        if SynPlayRestoreAnim and not self.PlayRestoreAnim then
            self.PlayRestoreAnim = true

            speed = speed / SLOW_DOWN_PERCENT
            self.Animator.speed = self.Animator.speed / SLOW_DOWN_PERCENT
        end

        --角色移动
        transform:Translate(speed * VForward * CS.UnityEngine.Time.deltaTime)
    end, 0, 0)

end

--动画全部执行完毕
function XMoeWarAnimationRole:OnExit()
    self._IsEnd = true

    self:DestroyTimer()
end

function XMoeWarAnimationRole:DestroyTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XMoeWarAnimationRole:IsEnd()
    return self._IsEnd or false
end

return XMoeWarAnimationRole