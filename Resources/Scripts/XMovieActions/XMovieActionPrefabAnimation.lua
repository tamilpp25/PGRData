local next = next

local XMovieActionPrefabAnimation = XClass(XMovieActionBase, "XMovieActionPrefabAnimation")

function XMovieActionPrefabAnimation:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    local transTimeLineSeconds = XDataCenter.MovieManager.TransTimeLineSeconds

    self.ParentName = params[1]
    self.PrefabPath = params[2]
    self.AnimName = params[3]
    self.PauseTime = transTimeLineSeconds(paramToNumber(params[4]))
    self.Resume = paramToNumber(params[5]) ~= 0
end

function XMovieActionPrefabAnimation:OnInit()
    local parentName = self.ParentName
    local parent = self.UiRoot[parentName]
    if XTool.UObjIsNil(parent) then
        XLog.Error("XMovieActionPrefabAnimation:OnInit error: parentName is: " .. parentName)
        return
    end

    local prefabPath = self.PrefabPath
    local animName = self.AnimName
    local animInfo = self.UiRoot.AnimPrefabDic[prefabPath] or {}
    if not next(animInfo) then
        local prefab = parent.gameObject:LoadPrefab(prefabPath)
        animInfo.Prefab = prefab

        local transfrom = prefab:FindTransform(animName)
        animInfo.Transform = transfrom

        self.UiRoot.AnimPrefabDic[prefabPath] = animInfo
    end
end

function XMovieActionPrefabAnimation:OnRunning()
    local prefabPath = self.PrefabPath
    local animInfo = self.UiRoot.AnimPrefabDic[prefabPath]
    local transfrom = animInfo.Transform

    if not animInfo.IsPlaying then
        transfrom.gameObject:SetActiveEx(true)
        transfrom:PlayTimelineAnimation(function()
            transfrom.gameObject:SetActiveEx(false)
            animInfo.IsPlaying = nil
        end)
        animInfo.IsPlaying = true
    end

    local animScript = animInfo.AnimScript
    if not animScript then
        animScript = transfrom:GetComponent("XUiPlayTimelineAnimation")
        animInfo.AnimScript = animScript
    end

    local pauseTime = self.PauseTime
    if pauseTime > 0 then
        animScript:SetPauseTime(pauseTime)
    end

    if self.Resume then
        animScript:Resume()
    end
end

return XMovieActionPrefabAnimation