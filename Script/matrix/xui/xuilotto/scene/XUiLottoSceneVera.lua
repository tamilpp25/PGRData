---@class XUiLottoSceneVera:XUiNode
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
end

function XUiLottoSceneVera:PlayLongEnableAnim()
    self:PlayAnimationWithMask("AnimEnableLong")
end

function XUiLottoSceneVera:PlayShortEnableAnim()
    self:PlayAnimation("AnimEnableShort")
end

function XUiLottoSceneVera:PlayDrawAnim(timelineName)
    self:PlayAnimation(timelineName, function()
        XEventManager.DispatchEvent(XEventId.EVENT_LOTTO_DRAW_ON_FINISH)
    end)
end

return XUiLottoSceneVera