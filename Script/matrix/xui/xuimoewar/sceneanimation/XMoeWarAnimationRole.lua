local XMoeWarAnimationRole = XClass(nil, "XMoeWarAnimationRole")

local Vector3 = CS.UnityEngine.Vector3
local VForward = Vector3.forward
local CSXResourceManagerLoad

local PLAY_END_ANIM_DISTANCE = CS.XGame.ClientConfig:GetFloat("MoeWarSceneAnimationPlayEndAnimDistance")--当镜头跟随者到达此位置后播放结束镜头动画和慢镜头动作
local PLAY_GOAL_ANIM_DISTANCE = CS.XGame.ClientConfig:GetFloat("MoeWarSceneAnimationGoalDistance")--当镜头跟随者到达此位置后播放冲线特效
local PLAY_RESTORE_ANIM_DISTANCE = CS.XGame.ClientConfig:GetFloat("MoeWarSceneAnimationRestoreDistance")--当镜头跟随者到达此位置后恢复慢镜头动作
local SLOW_DOWN_PERCENT = 0.01 * CS.XGame.ClientConfig:GetInt("MoeWarSceneAnimationSlowdownPercent")--慢动作速度百分比
local END_ANIM_TOTAL_TIME = CS.XGame.ClientConfig:GetInt("MoeWarSceneAnimationTotalTime")--整个终场动画持续时间/s
local ADD_SUPPORT_DISTANCE_POS = CS.XGame.ClientConfig:GetFloat("MoeWarSceneAnimationAddSupportDistance")--增加投票数间隔，数值越大，间隔时间越长，增加的投票数越多

local SynPlaySlowDownAnim = nil--同步播放慢动作
local SynPlayRestoreAnim = nil--同步恢复原始速度

function XMoeWarAnimationRole:Ctor(data)
    self.Index = data.Index--赛道Index
    self.GroupId = data.GroupId--动画组Id
    self.ModelParent = data.Parent--角色模型父节点
    self.UiName = data.UiName
    self.Scene = data.Scene
    self.SwitchCameraCb = data.SwitchCameraCb--切换相机回调
    self.EndAnimCb = data.EndAnimCb--终场场景动画回调
    self.GoalAnimCb = data.GoalAnimCb--冲线场景动画回调
    self.Ui = data.Ui --ui节点
    self.PlayerId = data.PlayerId --角色Id
    self.RunwayIndex = data.RunwayIndex --场景的跑道下标
    self.Match = data.Match --XMoeWarMatch

    self:Init()
end

function XMoeWarAnimationRole:Dispose()
    self:DestroyTimer()

    for _, effectRoot in pairs(self.SceneEffectRoots) do
        effectRoot.gameObject:SetActiveEx(false)
    end
    self.SceneEffectRoots = {}

    self:ReleaseResource()
end

function XMoeWarAnimationRole:ReleaseResource()
    if self.Resource then
        self.Resource:Release()
        self.Resource = nil
    end
    if self.Model then
        XUiHelper.Destroy(self.Model)
        self.Model = nil
    end
end

function XMoeWarAnimationRole:Init()
    local groupId = self.GroupId
    local player = XDataCenter.MoeWarManager.GetPlayer(self.PlayerId)
    local matchId = self.Match and self.Match:GetId() or XDataCenter.MoeWarManager.GetCurMatchId()

    self.AnimationIds = XMoeWarConfig.GetAnimationIds(groupId)--动画节点组
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
    self.TotalSupportCount = player and player:GetSupportCount(matchId) or 0 --拥有的总投票数
    self.TotalDistance = XMoeWarConfig.GetAnimationTotalDistance(groupId) --总距离
    self.OnceAddSupportCount = self.TotalSupportCount / self.TotalDistance * (ADD_SUPPORT_DISTANCE_POS + 0.5) --每次增加的投票数
    self.CurSupportCount = 0 --当前票数

    SynPlaySlowDownAnim = nil
    SynPlayRestoreAnim = nil

    self:InitUi()

    local modelName = XMoeWarConfig.GetAnimationGroupInitModelName(groupId)
    self:ChangeModel(modelName)

    if player then
        self.Head:SetRawImage(player:GetCircleHead())
    end
    self.RImgIcon:SetRawImage(CS.XGame.ClientConfig:GetString("MoeWarScheduleSupportIcon"))
    self.TxtScore.text = self.CurSupportCount
    self.TxtAddScore.text = ""
end

function XMoeWarAnimationRole:InitUi()
    local rootUiTransform = self.Ui.transform
    self.Head = XUiHelper.TryGetComponent(rootUiTransform, "Head1/StandIcon", "RawImage")
    self.TxtScore = XUiHelper.TryGetComponent(rootUiTransform, "PanelRolePoll/TxtScore", "Text")
    self.RImgIcon = XUiHelper.TryGetComponent(rootUiTransform, "PanelRolePoll/RImgIcon", "RawImage")
    self.TxtAddScore = XUiHelper.TryGetComponent(rootUiTransform, "TxtAddScore", "Text")
    self.TxtAddScoreEnable = XUiHelper.TryGetComponent(rootUiTransform, "Animation/TxtAddScoreEnable", "PlayableDirector")
end

--替换模型
function XMoeWarAnimationRole:ChangeModel(modelName)
    if not modelName or modelName == self.CurrentModelName then return end

    --记录旧模型位置
    local oldPos = self.Model and self.Model.transform.localPosition

    --加载新模型
    local prefabPath = XModelManager.GetUiModelPath(modelName)
    local resource = CSXResourceManagerLoad(prefabPath)
    XLog.Error("[XResourceManager优化] 已经无法运行, 从XResourceManager改为loadPrefab")
    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XMoeWarAnimationRole:ChangeModel加载资源失败，路径：%s", prefabPath))
        return
    end

    self:ReleaseResource()
    self.Resource = resource

    local model = XUiHelper.Instantiate(resource.Asset, self.ModelParent)
    model.gameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer("UiNear"))
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
    local isLastAnimation = animationIndex >= #self.AnimationIds - 1 --最后一个动画到达终点，-1来判断是否为终点前的最后一个动画

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
            XLog.Error(string.format("XMoeWarAnimationRole:Run error: 角色特效父节点找不到, roleEffectRoot: %s；animationId: %s", roleEffectRoot, animationId))
        else
            effectRoot:LoadPrefab(roleEffect, false)
            effectRoot.gameObject:SetActiveEx(false)
            effectRoot.gameObject:SetActiveEx(true)
        end
    end

    --场景特效
    local sceneEffect, sceneEffectRoot = XMoeWarConfig.GetAnimationSceneEffect(animationId, self.RunwayIndex)
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

    --终点前加满至拥有的投票数
    if isLastAnimation then
        self:AddScore(self.TotalSupportCount)
    end

    --角色移动
    local position = nil
    local curPosition = nil
    self:DestroyTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(transform) then
            self:DestroyTimer()
            return
        end

        position = transform.localPosition.z

        --增加当前的投票数
        if not isLastAnimation then
            if not curPosition then
                curPosition = position
            elseif math.abs(curPosition - position) >= ADD_SUPPORT_DISTANCE_POS then
                curPosition = position
                self.CurSupportCount = math.min(self.TotalSupportCount, self.CurSupportCount + self.OnceAddSupportCount)
                self:AddScore(self.CurSupportCount)
            end
        end

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

--增加积分动画
function XMoeWarAnimationRole:AddScore(newSupportCount)
    local oldSupportCount = tonumber(self.TxtScore.text)
    if oldSupportCount == newSupportCount or newSupportCount - oldSupportCount < 1 then
        return
    end

    local curShowSupportCount = self.TxtScore.text
    self.TxtScore.text = math.min(self.TotalSupportCount, math.floor(newSupportCount))

    self.TxtAddScore.text = "+" .. math.floor(newSupportCount - oldSupportCount)
    self.TxtAddScoreEnable:Stop()
    self.TxtAddScoreEnable:Play()
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