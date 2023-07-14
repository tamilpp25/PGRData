local DefaultScale = CS.UnityEngine.Vector3(1, 1, 1)
local DefaultColor = CS.UnityEngine.Color.white
local FrontScale = CS.UnityEngine.Vector3(1.02, 1.02, 1)
local BackColor = CS.UnityEngine.Color(0.39, 0.39, 0.39, 1)
local AnimNames = {
    Enable = {
        "PanelActor1Enable",
        "PanelActor2Enable",
        "PanelActor3Enable",
    },
    Disable = {
        "PanelActor1Disable",
        "PanelActor2Disable",
        "PanelActor3Disable",
    },
    NormalToFront = {
        "PanelActor1BlowUpNor",
        "PanelActor2BlowUpNor",
        "PanelActor3BlowUpNor",
    },
    NormalToBack = {
        "PanelActor1DarkNor",
        "PanelActor2DarkNor",
        "PanelActor3DarkNor",
    },
    BackToFront = {
        "PanelActor1BlowUp",
        "PanelActor2BlowUp",
        "PanelActor3BlowUp",
    },
    FrontToBack = {
        "PanelActor1Dark",
        "PanelActor2Dark",
        "PanelActor3Dark",
    },
}

local ShowStatus = {
    Normal = 0,
    Back = 1,
    Front = 2,
    Hide = 3,
}

local XUiGridMovieActor = XClass(nil, "XUiGridMovieActor")

function XUiGridMovieActor:Ctor(uiRoot, actorIndex)
    self.UiRoot = uiRoot
    self.ActorIndex = actorIndex
    self.PlayingAnimDic = {}

    local panelActor = {}
    local go = self.UiRoot["PanelActor" .. actorIndex]
    panelActor.Transform = go.transform
    panelActor.gameObject = go.gameObject
    XTool.InitUiObject(panelActor)

    self.PanelActor = panelActor
    self.RImgActor = panelActor.RImgActor
    self.RImgFace = panelActor.RImgFace
    self.EffctActor = panelActor.EffctActor
    self.MetearialActor = panelActor.MetearialActor
    self.MeterialFace = panelActor.MeterialFace
    self.CanvasGroup = panelActor.Transform:GetComponent("CanvasGroup")
    self.Status = ShowStatus.Hide
    panelActor.gameObject:SetActiveEx(false)
    self.RImgFace.gameObject:SetActiveEx(false)
    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_UI_DESTROY, self.Destroy, self)
end

function XUiGridMovieActor:Destroy()
    self.UiRoot = nil
    self.RImgActor = nil
    self.PanelActor = nil
    self.EffctActor = nil
    self.RImgFace = nil
    self.MetearialActor = nil
    self.MeterialFace = nil
    self.CanvasGroup = nil
end

function XUiGridMovieActor:UpdateActor(actorId)
    if self.ActorId == actorId then return end
    self.ActorId = actorId

    self:SetImage()
    self.PanelActor.gameObject:SetActiveEx(true)
end

function XUiGridMovieActor:SetImage()
    local rImgActor = self.RImgActor
    if not rImgActor then return end

    local actorId = self.ActorId
    local path = XMovieConfigs.GetActorImgPath(actorId)
    rImgActor:SetRawImage(path, function()
        rImgActor:SetNativeSize()
    end)
end

function XUiGridMovieActor:SetImagePos(pos)
    if self.Pos == pos then return end
    local rImgActor = self.RImgActor
    if XTool.UObjIsNil(rImgActor) then return end

    self.Pos = pos
    rImgActor.rectTransform.anchoredPosition3D = pos
end

function XUiGridMovieActor:GetImagePos()
    return self.Pos
end

function XUiGridMovieActor:GetEffectGo()
    return self.EffctActor
end

function XUiGridMovieActor:GetEffectParentGo()
    return self.RImgActor.transform
end

function XUiGridMovieActor:GetActorId()
    return self.ActorId or 0
end

function XUiGridMovieActor:GetFaceId()
    return self.FaceId or 0
end

function XUiGridMovieActor:IsHide()
    return self.Status == ShowStatus.Hide
end

function XUiGridMovieActor:IsBack()
    return self.Status == ShowStatus.Back
end

function XUiGridMovieActor:IsFront()
    return self.Status == ShowStatus.Front
end

function XUiGridMovieActor:SetFace(faceId)
    local rImgFace = self.RImgFace

    local actorId = self.ActorId
    if faceId ~= 0 then
        self.FaceId = faceId
        local path = XMovieConfigs.GetActorFaceImgPath(actorId, faceId)
        rImgFace:SetRawImage(path, function()
            rImgFace:SetNativeSize()
        end)
        rImgFace.rectTransform.anchoredPosition = XMovieConfigs.GetActorFacePosVector2(actorId)
        rImgFace.gameObject:SetActiveEx(true)
    else
        rImgFace.gameObject:SetActiveEx(false)
    end
end

function XUiGridMovieActor:SetGrayScale(value)
    if self.GrayValue == value then return end
    self.GrayValue = value
    self.MetearialActor:SetGrayScale(value)
    self.MeterialFace:SetGrayScale(value)
end

function XUiGridMovieActor:RevertActorPanel()
    local rImgActor = self.RImgActor
    local rImgFace = self.RImgFace
    if XTool.UObjIsNil(rImgActor) then return end

    local alpha = 1
    local color = DefaultColor
    local scale = DefaultScale
    local status = self.Status
    if status == ShowStatus.Back then
        color = BackColor
    elseif status == ShowStatus.Front then
        self.PanelActor.Transform:SetAsLastSibling()
        scale = FrontScale
    elseif status == ShowStatus.Hide then
        alpha = 0
    end

    self.CanvasGroup.alpha = alpha
    rImgActor.color = color
    rImgFace.color = color
    rImgActor.rectTransform.localScale = scale
end

function XUiGridMovieActor:PlayAnimEnable(skipAnim)
    if self.IsUsing then return end
    self.IsUsing = true

    if self.Status == ShowStatus.Normal then return end
    self.Status = ShowStatus.Normal

    if skipAnim then
        self:RevertActorPanel()
        return
    end

    local actorIndex = self.ActorIndex
    local animName = AnimNames.Enable[actorIndex]
    if not animName then return end

    local sameAnimPlaying = self.PlayingAnimDic[animName]
    if sameAnimPlaying then
        XLog.Error("XUiGridMovieActor:PlayAnimEnable Error:配置错误，不允许连续配置相同index的角色出现")
        return
    end
    self.PlayingAnimDic[animName] = true

    self.IsPlayingEnable = true
    local anim = self.UiRoot[animName]
    anim.gameObject:SetActiveEx(true)

    anim:PlayTimelineAnimation(function()
        XLuaUiManager.SetMask(false)
        self.IsPlayingEnable = nil
        self.PlayingAnimDic[animName] = nil
        anim.gameObject:SetActiveEx(false)

        local tmpAnimName = self.DelayAnimName
        if tmpAnimName then
            local tmpAnim = self.UiRoot[tmpAnimName]
            tmpAnim.gameObject:SetActiveEx(true)
            tmpAnim:PlayTimelineAnimation(function()
                XLuaUiManager.SetMask(false)
                tmpAnim.gameObject:SetActiveEx(false)
                self:RevertActorPanel()
            end, function()
                XLuaUiManager.SetMask(true)
            end)
            self.DelayAnimName = nil
        else
            self:RevertActorPanel()
        end
    end, function()
        XLuaUiManager.SetMask(true)
    end)
end

function XUiGridMovieActor:PlayAnimDisable(skipAnim, cb)
    if not self.IsUsing then return end
    self.IsUsing = nil

    if self.Status == ShowStatus.Hide then return end
    self.Status = ShowStatus.Hide

    if skipAnim then
        self:RevertActorPanel()
        return
    end

    local actorIndex = self.ActorIndex
    local animName = AnimNames.Disable[actorIndex]
    if not animName then return end

    local sameAnimPlaying = self.PlayingAnimDic[animName]
    if sameAnimPlaying then
        XLog.Error("XUiGridMovieActor:PlayAnimEnable Error:配置错误，不允许连续配置相同index的角色消失")
        return
    end
    self.PlayingAnimDic[animName] = true

    local anim = self.UiRoot[animName]
    anim.gameObject:SetActiveEx(true)
    anim:PlayTimelineAnimation(function()
        XLuaUiManager.SetMask(false)
        anim.gameObject:SetActiveEx(false)
        self.PlayingAnimDic[animName] = nil
        if cb then
            cb()
        end
    end, function()
        XLuaUiManager.SetMask(true)
    end)
end

function XUiGridMovieActor:PlayAnimBack(skipAnim)
    if not self.IsUsing then return end

    if self.Status == ShowStatus.Back then return end

    local animName = self:GetStatusAnimName(ShowStatus.Back)
    if not animName then return end

    self.Status = ShowStatus.Back

    if skipAnim then
        self:RevertActorPanel()
        return
    end

    if self.IsPlayingEnable then
        self.DelayAnimName = animName
        return
    end

    local anim = self.UiRoot[animName]
    anim.gameObject:SetActiveEx(true)
    anim:PlayTimelineAnimation(function()
        XLuaUiManager.SetMask(false)
        anim.gameObject:SetActiveEx(false)
        self:RevertActorPanel()
    end, function()
        XLuaUiManager.SetMask(true)
    end)
end

function XUiGridMovieActor:PlayAnimFront(skipAnim)
    if not self.IsUsing then return end

    if self.Status == ShowStatus.Front then return end

    local animName = self:GetStatusAnimName(ShowStatus.Front)
    if not animName then return end

    self.Status = ShowStatus.Front

    if skipAnim then
        self:RevertActorPanel()
        return
    end

    if self.IsPlayingEnable then
        self.DelayAnimName = animName
        return
    end

    local anim = self.UiRoot[animName]
    anim.gameObject:SetActiveEx(true)
    anim:PlayTimelineAnimation(function()
        XLuaUiManager.SetMask(false)
        anim.gameObject:SetActiveEx(false)
        self:RevertActorPanel()
    end, function()
        XLuaUiManager.SetMask(true)
    end)
end

function XUiGridMovieActor:GetStatusAnimName(toStatus)
    local animName

    local actorIndex = self.ActorIndex
    if not actorIndex then return end

    local status = self.Status
    if toStatus == ShowStatus.Back then
        if status == ShowStatus.Normal then
            animName = AnimNames.NormalToBack[actorIndex]
        elseif status == ShowStatus.Front then
            animName = AnimNames.FrontToBack[actorIndex]
        end
    elseif toStatus == ShowStatus.Front then
        if status == ShowStatus.Normal then
            animName = AnimNames.NormalToFront[actorIndex]
        elseif status == ShowStatus.Back then
            animName = AnimNames.BackToFront[actorIndex]
        end
    end

    return animName
end

return XUiGridMovieActor