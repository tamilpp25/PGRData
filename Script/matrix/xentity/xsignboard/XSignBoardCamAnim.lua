local XSignBoardCamAnim = XClass(nil, "XSignBoardCamAnim")

function XSignBoardCamAnim:Ctor()
    self:_Init()
end

function XSignBoardCamAnim:Exist()
    return self.AnimPlayer and self.AnimPlayer:Exist()
end

function XSignBoardCamAnim:UpdateData(sceneId, signBoardId, ui)
    self.SceneId = sceneId
    self.SignBoardId = signBoardId
    self.UiRoot = ui
end

function XSignBoardCamAnim:UpdateAnim(uiNode, farCam, nearCam)
    local sceneRotationType = XPhotographConfigs.GetBackgroundSceneRotation(self.SceneId) or XPhotographConfigs.SceneRotationType.None

    self:_InitNode(uiNode)
    self:_SetSceneRotation(sceneRotationType)
    self:_InitCam(farCam, nearCam)
    self:_InitEffect()
    self:_InitUiAnim()
end

-- 卸载动画
function XSignBoardCamAnim:UnloadAnim()
    if self.AnimPlayer and self.AnimPlayer:Exist() then
        XUiHelper.Destroy(self.AnimPlayer.gameObject)
    end
    self:_Init()
end

function XSignBoardCamAnim:Play()
    self:_ResetSceneAnim()
    self:_ResetPlayingUiAnim()
    if self:Exist() then
        self.FarCamRoot.gameObject:SetActiveEx(true)
        self.NearCamRoot.gameObject:SetActiveEx(true)
        self.AnimPlayer:Play()          -- 播放镜头动画
        self:_SetEffectAnim(1)          -- 播放镜头动画上的特效
        self:OnScenePlayStart()         -- 播放Ui动画(如果有)
        self.IsPlaying = true
    end
end

function XSignBoardCamAnim:Pause()
    if self:Exist() then
        self.AnimPlayer:Pause()         -- 暂停镜头动画
        self:_SetEffectAnim(0)          -- 暂停镜头动画上的特效
        if self.CurPlayingUiAnim then   -- 暂停Ui动画(如果Ui动画还在继续)
            self.CurPlayingUiAnim:Pause()
        end
    end
end

function XSignBoardCamAnim:Resume()
    if self:Exist() then
        if not self:IsFinish() then
            self.AnimPlayer:Play()      -- 继续播放镜头动画(若动画已完成则不继续)
        end
        self:_SetEffectAnim(1)          -- 继续播放镜头动画上的特效
        if self.CurPlayingUiAnim and self.CurPlayingUiAnim.time < self.CurPlayingUiAnim.duration then
            self.CurPlayingUiAnim:Play()-- 继续播放Ui动画(若动画已完成则不继续)
        end
    end
end

function XSignBoardCamAnim:Close()
    self:_ResetPlayingUiAnim()
    if self:Exist() then
        self.FarCamRoot.gameObject:SetActiveEx(false)
        self.NearCamRoot.gameObject:SetActiveEx(false)
        if self.IsPlaying then
            self:OnScenePlayStop()      -- 播放Ui恢复动画
        end
        self.AnimPlayer.time = self.AnimPlayer.duration
        self.IsPlaying = false
    end
end

function XSignBoardCamAnim:IsFinish()
    if self:Exist() then
        return self.AnimPlayer.time >= self.AnimPlayer.duration
    end
    return true
end

function XSignBoardCamAnim:CheckIsSameAnim(sceneId, signBoardId, rootNode)
    return
        self:Exist() and
        sceneId == self.SceneId and
        self.SignBoardId == signBoardId and
        self.AnimPlayer.transform.parent == rootNode
end

function XSignBoardCamAnim:GetNodeTransform()
    if self.AnimPlayer then
        return self.AnimPlayer.transform
    end
end

function XSignBoardCamAnim:OnScenePlayStart()
    if not self.UiAnimNodeRoot then
        return
    end
    if XSignBoardConfigs.CheckIsUseSelfUiAnim(self.SignBoardId, self.UiAnimNodeRoot.name) then
        self:_PlayUiAnim("UiDisable")
    end
end

function XSignBoardCamAnim:OnScenePlayStop()
    if not self.UiAnimNodeRoot then
        return
    end
    if XSignBoardConfigs.CheckIsUseSelfUiAnim(self.SignBoardId, self.UiAnimNodeRoot.name) then
        self:_PlayUiAnim("UiEnable")
    end
end


-- private
--===============================================================================

function XSignBoardCamAnim:_Init()
    self.AnimPlayer = nil       -- 场景动画控制器：Playable Director
    self.IsPlaying = false      -- 播发状态

    self.FarRotation = nil      -- 场景镜头旋转坐标
    self.FarCamRoot = nil       -- 场景镜头根节点
    self.FarAnimNode = nil      -- 动画实际控制的场景镜头节点
    self.FarCam = nil           -- 场景镜头，动态挂载于FarAnimNode下
    self.NearCamRoot = nil      -- 角色镜头根节点
    self.NearAnimNode = nil     -- 角色镜头轨迹动画节点
    self.NearCam = nil          -- 角色镜头，动态挂载于NearAnimNode下

    self.EffectDic = {}         -- 特效动画控制器字典

    self.UiAnimNodeRoot = nil   -- 预制体里用的Ui动画根节点
    ---@type UnityEngine.Playables.PlayableDirector[]
    self.UiAnim = {}            -- Ui动画字典
    self.CurPlayingUiAnim = nil -- 正在播放的Ui动画

    self.SceneId = nil
    self.SignBoardId = nil
    self.UiRoot = nil           -- Ui动画控制的Ui对象根节点
end

-- SceneAnim
-------------------------------------------------------------------------------------

function XSignBoardCamAnim:_InitNode(uiNode)
    self.AnimPlayer = uiNode.gameObject:GetComponent("PlayableDirector")
    self:_ResetSceneAnim()

    self.FarCamRoot = uiNode.transform:FindTransform("FarCamRoot")
    self.FarAnimNode = self.FarCamRoot:FindTransform("AnimNode")

    self.NearCamRoot = uiNode.transform:FindTransform("NearCamRoot")
    self.NearAnimNode = self.NearCamRoot:FindTransform("AnimNode")

    if self.SignBoardId ~= 1020305 then
        self.AnimPlayer.transform.position = Vector3(0, 0, 0)
        self.AnimPlayer.transform.rotation = CS.UnityEngine.Quaternion.identity
    end
end

function XSignBoardCamAnim:_InitCam(farCam, nearCam)
    -- v2.3 支持self.FarAnimNode和self.NearAnimNode使用Cam的position和rotation
    local isUseCamPosAndRot = XSignBoardConfigs.CheckIsUseCamPosAndRot(self.SignBoardId)

    --同步Far镜头相对空间位置 Far镜头可能是场景本身的
    self.FarCamRoot.position = farCam.transform.position
    self.FarCamRoot.rotation = farCam.transform.rotation
    self.FarRotation = self.FarCamRoot.rotation
    if not self.FarCam then
        self.FarCam = XUiHelper.Instantiate(farCam, self.FarAnimNode)
        self.FarCam.transform.position = farCam.transform.position
        self.FarCam.transform.rotation = farCam.transform.rotation

        if isUseCamPosAndRot then
            self.FarCamRoot.transform.position = self.FarCam.transform.position
            self.FarCamRoot.transform.rotation = self.FarCam.transform.rotation
            self.FarCam.transform.localPosition = Vector3(0, 0, 0)
            self.FarCam.transform.localRotation = CS.UnityEngine.Quaternion.identity
        end

        -- 关闭陀螺仪摇晃控件
        local farGyroController =  self.FarCam.transform:GetComponent("XCameraGyroController")
        if farGyroController then
            farGyroController.enabled = false
        end
    end

    -- v2.1比安卡深痕镜头动画坐标临时调整，待后续版本修正
    -- 特殊处理是因为阿尔法的镜头动画坐标基准不一样
    if self.SignBoardId ~= 1020305 then
        self.NearCamRoot.position = self.AnimPlayer.transform.position
        self.NearCamRoot.rotation = self.AnimPlayer.transform.rotation
    end
    if not self.NearCam then
        self.NearCam = XUiHelper.Instantiate(nearCam, self.NearAnimNode)
        self.NearCam.transform.position = nearCam.transform.position
        self.NearCam.transform.rotation = nearCam.transform.rotation

        if isUseCamPosAndRot then
            self.NearCamRoot.transform.position = self.NearCam.transform.position
            self.NearCamRoot.transform.rotation = self.NearCam.transform.rotation
            self.NearCam.transform.localPosition = Vector3(0, 0, 0)
            self.NearCam.transform.localRotation = CS.UnityEngine.Quaternion.identity
        end

        local nearGyroController =  self.NearCam.transform:GetComponent("XCameraGyroController")
        if nearGyroController then
            nearGyroController.enabled = false
        end
    end
end

-- 因为Ui中具有两个相机参考系，如果两者方向相反则需要旋转方向使动画运动轨迹效果保持一致
-- sceneRotation:旋转类型 XPhotographConfigs.SceneRotationType
function XSignBoardCamAnim:_SetSceneRotation(sceneRotation)
    if self.FarCam or not self.FarCamRoot then
        return
    end

    if sceneRotation == XPhotographConfigs.SceneRotationType.None then
        return
    elseif sceneRotation == XPhotographConfigs.SceneRotationType.YRotation then
        self.FarCamRoot.transform:Rotate(0, 180, 0)
    end
end

-- 重置动画进度
function XSignBoardCamAnim:_ResetSceneAnim()
    if self:Exist() then
        self.AnimPlayer.gameObject:SetActiveEx(true)
        self.AnimPlayer.time = 0
        self.AnimPlayer:Evaluate()
    end
end

-------------------------------------------------------------------------------------


-- SceneAnimEffect
-------------------------------------------------------------------------------------

function XSignBoardCamAnim:_InitEffect()
    -- NearEffect
    for i = 0, self.NearAnimNode.childCount - 1, 1 do
        local effectTransform = self.NearAnimNode:GetChild(i)
        local effect = effectTransform:GetComponent("XUiEffectLayer")
        if not XTool.UObjIsNil(effect) then
            self.EffectDic[effectTransform.gameObject.name] = effectTransform
            effectTransform.transform.position = self.AnimPlayer.transform.parent.position
            effectTransform.transform.rotation = self.AnimPlayer.transform.parent.rotation
        end
    end
    -- FarEffect
    for i = 0, self.FarAnimNode.childCount - 1, 1 do
        local effectTransform = self.FarAnimNode:GetChild(i)
        local effect = effectTransform:GetComponent("XUiEffectLayer")
        if not XTool.UObjIsNil(effect) then
            self.EffectDic[effectTransform.gameObject.name] = effectTransform
            effectTransform.transform.position = self.AnimPlayer.transform.parent.position
            effectTransform.transform.rotation = self.AnimPlayer.transform.parent.rotation
        end
    end
end

function XSignBoardCamAnim:_SetEffectAnim(speed)
    local animater
    for _, effect in pairs(self.EffectDic) do
        animater = effect.childCount > 0 and effect:GetChild(0):GetComponent("Animator") or nil
        if not XTool.UObjIsNil(animater) then
            animater.speed = speed
        end
    end
end
-------------------------------------------------------------------------------------


-- UiAnim
-------------------------------------------------------------------------------------

function XSignBoardCamAnim:_InitUiAnim()
    local uiAnimRoot = self.AnimPlayer.transform:FindTransform("Animation")
    if not self.UiRoot or not uiAnimRoot then
        return
    end
    self.UiAnimNodeRoot = uiAnimRoot:FindTransform(self.UiRoot.Name)
    if not self.UiAnimNodeRoot then
        return
    end
    for i = 0, self.UiAnimNodeRoot.childCount - 1, 1 do
        local anim = self.UiAnimNodeRoot:GetChild(i)
        local playableDirector = anim:GetComponent("PlayableDirector")

        if not playableDirector then
            goto CONTINUE
        end
        local tracks = playableDirector.playableAsset:GetOutputTracks()

        for i = 0, tracks.Length - 1, 1 do
            playableDirector:SetGenericBinding(tracks[i], self.UiRoot.GameObject:GetComponent("Animator"))
        end
        self.UiAnim[anim.name] = playableDirector
        self.UiAnim[anim.name].gameObject:SetActiveEx(false)
        :: CONTINUE ::
    end
end

function XSignBoardCamAnim:_PlayUiAnim(animName, cbFunc)
    if not self.UiAnim[animName] then
        if cbFunc then
            cbFunc()
        end
        return
    end

    self.CurPlayingUiAnim = self.UiAnim[animName]
    self.UiAnim[animName].gameObject:SetActiveEx(true)
    self.UiAnim[animName].gameObject:PlayTimelineAnimation(function ()
        self.CurPlayingUiAnim = nil
        if cbFunc then
            cbFunc()
        end
    end)
end

-- 停止所有动画
function XSignBoardCamAnim:_ResetPlayingUiAnim()
    if not self:Exist() then
        return
    end
    if self.CurPlayingUiAnim == nil then
        return
    end
    self.CurPlayingUiAnim:Evaluate()
    self.CurPlayingUiAnim.gameObject:SetActiveEx(false)
    self.CurPlayingUiAnim = nil
end

-------------------------------------------------------------------------------------

--===============================================================================

return XSignBoardCamAnim