---@class XUiLottoSceneVera:XUiNode
---@field AnimEnableLong UnityEngine.Playables.PlayableDirector
---@field AnimEnableShort UnityEngine.Playables.PlayableDirector
---@field ChoukaVioletEnable UnityEngine.Playables.PlayableDirector
---@field ChoukaYellowEnable UnityEngine.Playables.PlayableDirector
---@field ChoukaRedEnable UnityEngine.Playables.PlayableDirector
local XUiLottoSceneVera = XClass(XUiNode, "XUiLottoSceneVera")

function XUiLottoSceneVera:OnStart(sceneRoot)
    ---@type XUiSceneInfo
    self._SceneRoot = sceneRoot
    ---@type UnityEngine.Playables.PlayableDirector[]
    self._CamAnimDrawDir = {}
    self._CamAnimDrawDir.ChoukaVioletEnable = self.ChoukaVioletEnable
    self._CamAnimDrawDir.ChoukaYellowEnable = self.ChoukaYellowEnable
    self._CamAnimDrawDir.ChoukaRedEnable = self.ChoukaRedEnable
    if not self.AnimEnableLong then
        self.AnimEnableLong = XUiHelper.TryGetComponent(self.Transform, "Animation/AnimEnableLong", "PlayableDirector")
    end
    if not self.AnimEnableShort then
        self.AnimEnableShort = XUiHelper.TryGetComponent(self.Transform, "Animation/AnimEnableShort", "PlayableDirector")
    end
    ---@type UnityEngine.Playables.PlayableDirector
    self._SceneAimEnableLong = XUiHelper.TryGetComponent(self._SceneRoot.Transform, "GroupBase/Animation/AnimEnableLong", "PlayableDirector")
end

function XUiLottoSceneVera:PlayLongEnableAnim()
    self:_PlayAnimNextFrame(function()
        self:_PlayTimeLineAnim(self.AnimEnableLong)
        self:_PlayTimeLineAnim(self._SceneAimEnableLong)
    end, 0)
end

function XUiLottoSceneVera:PlayShortEnableAnim()
    self:_PlayAnimNextFrame(function()
        self:_PlayTimeLineAnim(self.AnimEnableShort)
    end, 0)
end

function XUiLottoSceneVera:PlayDrawAnim(timelineName)
    self:PlayAnimation(timelineName, function()
        XEventManager.DispatchEvent(XEventId.EVENT_LOTTO_DRAW_ON_FINISH)
    end)
end

---配合_PlayTimeLineAnim
---延迟一帧是因为_PlayTimeLineAnim自己控制了timeline播放
---ui动画还是走XUiPlayTimelineAnimation会延迟两帧
---所以延迟一帧播放尽量对齐场景动画和Ui动画
function XUiLottoSceneVera:_PlayAnimNextFrame(playAnimFunc)
    if not playAnimFunc then
        return
    end
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        playAnimFunc()
    end, 0)
end

---PlayAnimationWithMask该接口最终使用的是C# XUiPlayTimelineAnimation
---XUiPlayTimelineAnimation的Play接口会因为WaitFrame等两帧
---由于角色动作切换是用【timeLine帧事件】实现的
---所以如果帧事件处于第一帧会导致场景演出对齐上有2帧时间误差,因此不用之,自己另写
---@param anim UnityEngine.Playables.PlayableDirector
---@param directorWrapMode number UnityEngine.Playables.DirectorWrapMode
function XUiLottoSceneVera:_PlayTimeLineAnim(anim, time, directorWrapMode)
    if not anim then
        return
    end
    anim.initialTime = time or 0
    if directorWrapMode then
        anim.extrapolationMode = directorWrapMode
    end
    anim:Evaluate()
    anim:Play()
end

return XUiLottoSceneVera