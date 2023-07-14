local stringFormat = string.format

local XMovieActionUnLoad = XClass(XMovieActionBase, "XMovieActionUnLoad")

function XMovieActionUnLoad:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.AnimName = params[1]
    self.EffectPath = params[2]
    self.PrefabAnimPath = params[3]
    self.EffectActorIndex = paramToNumber(params[4])

    if not self.AnimName and not self.EffectPath and not self.PrefabAnimPath then
        XLog.Error("XMovieActionUnLoad:Ctor error: params can not be empty!")
        return
    end
end

function XMovieActionUnLoad:OnRunning()
    local animName = self.AnimName
    local effectPath = self.EffectPath
    local effectActorIndex = self.EffectActorIndex
    local isActorEffect = effectActorIndex > 0 and effectActorIndex <= XMovieConfigs.MAX_ACTOR_NUM
    local effectKey = isActorEffect and stringFormat("%s%s", effectPath, effectActorIndex) or effectPath

    if animName then
        local anim = self.UiRoot[animName]
        if not XTool.UObjIsNil(anim) then
            anim.gameObject:SetActiveEx(false)
        end
    end

    if effectPath then
        local effectGo = self.UiRoot.EffectGoDic[effectKey]
        if not XTool.UObjIsNil(effectGo) then
            effectGo.gameObject:SetActiveEx(false)
        end
    end

    local prefabAnimPath = self.PrefabAnimPath
    if prefabAnimPath then
        local animInfo = self.UiRoot.AnimPrefabDic[prefabAnimPath]
        if animInfo then
            animInfo.Prefab.gameObject:SetActiveEx(false)
        end
    end
end

return XMovieActionUnLoad