local stringFormat = string.format
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XMovieActionEffectPlay = XClass(XMovieActionBase, "XMovieActionEffectPlay")

function XMovieActionEffectPlay:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.EffectPath = params[1]
    self.EffectLayer = paramToNumber(params[2])
    self.EffectActorIndex = paramToNumber(params[3])
end

function XMovieActionEffectPlay:OnInit()
    XLuaUiManager.SetMask(true)
end

function XMovieActionEffectPlay:OnRunning()
    local effectPath = self.EffectPath
    local effectActorIndex = self.EffectActorIndex
    local isActorEffect = effectActorIndex > 0 and effectActorIndex <= XMovieConfigs.MAX_ACTOR_NUM
    local effectKey = isActorEffect and stringFormat("%s%s", effectPath, effectActorIndex) or effectPath

    local effectGo = self.UiRoot.EffectGoDic[effectPath]
    if not effectGo then
        local baseEffectGo, parentGo, effectLayer

        if isActorEffect then
            local actor = self.UiRoot:GetActor(effectActorIndex)
            baseEffectGo = actor:GetEffectGo()
            parentGo = actor:GetEffectParentGo()
        else
            effectLayer = self.EffectLayer
            baseEffectGo = self.UiRoot.PanelEffects[effectLayer]
            parentGo = self.UiRoot.PanelEffect
        end

        if not baseEffectGo then
            XLog.Error("XMovieActionEffectPlay:OnRunning error: can Not find baseEffectGo, effectActorIndex is: " .. effectActorIndex .. ", effectLayer is: " .. effectLayer)
            return
        end

        effectGo = CSUnityEngineObjectInstantiate(baseEffectGo)
        effectGo.transform:SetParent(parentGo, false)

        self.UiRoot.EffectGoDic[effectKey] = effectGo
        effectGo.gameObject:LoadUiEffect(effectPath)
    else
        effectGo.gameObject:SetActiveEx(false)
        effectGo.gameObject:SetActiveEx(true)
    end
end

function XMovieActionEffectPlay:OnExit()
    XLuaUiManager.SetMask(false)
end

return XMovieActionEffectPlay