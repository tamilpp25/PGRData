local CSXUiPlayTimelineAnimation = CS.XUiPlayTimelineAnimation
local DefaultScale = CS.UnityEngine.Vector3(1, 1, 1)
local DefaultColor = CS.UnityEngine.Color.white
local FrontScale = CS.UnityEngine.Vector3(1.02, 1.02, 1)
local DefaultReverseScale = CS.UnityEngine.Vector3(-1, 1, 1)
local FrontReverseScale = CS.UnityEngine.Vector3(-1.02, 1.02, 1)
local BackColor = CS.UnityEngine.Color(0.39, 0.39, 0.39, 1)

local AnimNameHead = "PanelActor"
local AnimNames = {
    Enable = "Enable",
    Disable = "Disable",
    NormalToFront = "BlowUpNor",
    NormalToBack = "DarkNor",
    BackToFront = "BlowUp",
    FrontToBack = "Dark",
}

local ShowStatus = {
    Normal = 0,
    Back = 1,
    Front = 2,
    Hide = 3,
}

local XUiGridMovieActor = XClass(nil, "XUiGridMovieActor")

function XUiGridMovieActor:Ctor(uiRoot, obj, actorIndex)
    self.UiRoot = uiRoot
    self.ActorIndex = actorIndex
    self.PlayingAnimDic = {}

    local panelActor = {}
    panelActor.Transform = obj.transform
    panelActor.gameObject = obj.gameObject
    XTool.InitUiObject(panelActor)

    self.PanelActor = panelActor
    self.RImgActor = panelActor.RImgActor
    self.RImgFace = panelActor.RImgFace
    self.EffctActor = panelActor.EffctActor
    self.MetearialActor = panelActor.MetearialActor
    self.MeterialFace = panelActor.MeterialFace
    ---@type UnityEngine.CanvasGroup
    self.CanvasGroup = panelActor.Transform:GetComponent("CanvasGroup")
    self.Status = ShowStatus.Hide
    panelActor.gameObject:SetActiveEx(false)
    self.RImgFace.gameObject:SetActiveEx(false)
    self.IsReverse = false
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

function XUiGridMovieActor:Reverse(isReverse)
    self.IsReverse = isReverse
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

    local alpha = self.CanvasGroup.alpha
    local color = DefaultColor
    local scale = self.IsReverse and DefaultReverseScale or DefaultScale
    local status = self.Status
    if status == ShowStatus.Back then
        color = BackColor
    elseif status == ShowStatus.Front then
        self.PanelActor.Transform:SetAsLastSibling()
        scale = self.IsReverse and FrontReverseScale or FrontScale
    elseif status == ShowStatus.Hide then
        alpha = 0
        self.PanelActor.gameObject:SetActiveEx(false)
    elseif status == ShowStatus.Normal then
        alpha = 1    
    end

    self.CanvasGroup.alpha = alpha
    rImgActor.color = color
    rImgFace.color = color
    rImgActor.rectTransform.localScale = scale
end

function XUiGridMovieActor:PlayAnimEnable(skipAnim)
    -- 停止播放Disable动画，避免复用actor时Enable和Disable动画同时播放
    self:StopAnimtion(AnimNames.Disable)

    if self.IsUsing then return end
    self.IsUsing = true

    if self.Status == ShowStatus.Normal then return end
    self.Status = ShowStatus.Normal
    self.PanelActor.gameObject:SetActiveEx(true)

    if skipAnim then
        self.CanvasGroup.alpha = 1
        self:RevertActorPanel()
        return
    end

    local anim = self:GetAnim(AnimNames.Enable)
    if not anim then return end

    local sameAnimPlaying = self.PlayingAnimDic[anim]
    if sameAnimPlaying then
        XLog.Error("XUiGridMovieActor:PlayAnimEnable Error:配置错误，不允许连续配置相同index的角色出现")
        return
    end

    anim.gameObject:SetActiveEx(true)
    anim:PlayTimelineAnimation(function()
        XLuaUiManager.SetMask(false)
        self.IsPlayingEnable = nil
        self.PlayingAnimDic[anim] = nil
        self:StopAnimtion(AnimNames.Enable)

        local tmpAnim = self.DelayAnim
        if tmpAnim then
            tmpAnim.gameObject:SetActiveEx(true)
            tmpAnim:PlayTimelineAnimation(function()
                XLuaUiManager.SetMask(false)
                self:StopAnimtion(AnimNames.NormalToFront)
                self:StopAnimtion(AnimNames.NormalToBack)
                self:RevertActorPanel()
            end, function()
                XLuaUiManager.SetMask(true)
            end)
            self.DelayAnim = nil
        else
            self:RevertActorPanel()
        end
    end, function()
        XLuaUiManager.SetMask(true)
        self.IsPlayingEnable = true
        self.PlayingAnimDic[anim] = true
    end,CS.UnityEngine.Playables.DirectorWrapMode.None)
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

    local anim = self:GetAnim(AnimNames.Disable)
    if not anim then return end

    local sameAnimPlaying = self.PlayingAnimDic[anim]
    if sameAnimPlaying then
        XLog.Error("XUiGridMovieActor:PlayAnimEnable Error:配置错误，不允许连续配置相同index的角色消失")
        return
    end

        anim.gameObject:SetActiveEx(true)
        anim:PlayTimelineAnimation(function()
            XLuaUiManager.SetMask(false)
            self:StopAnimtion(AnimNames.Disable)
            self.PlayingAnimDic[anim] = nil
            if cb then
                cb()
            end
        end, function()
            XLuaUiManager.SetMask(true)
            self.PlayingAnimDic[anim] = true
        end,CS.UnityEngine.Playables.DirectorWrapMode.None)
end

function XUiGridMovieActor:PlayAnimBack(skipAnim)
    if not self.IsUsing then return end

    if self.Status == ShowStatus.Back then return end

    local anim = self:GetStatusAnim(ShowStatus.Back)
    if not anim then return end

    self.Status = ShowStatus.Back

    if skipAnim then
        self:RevertActorPanel()
        return
    end

    if self.IsPlayingEnable then
        self.DelayAnim = anim
        return
    end
    
        anim.gameObject:SetActiveEx(true)
        anim:PlayTimelineAnimation(function()
            XLuaUiManager.SetMask(false)
            self:StopAnimtion(AnimNames.NormalToBack)
            self:StopAnimtion(AnimNames.FrontToBack)
            self:RevertActorPanel()
        end, function()
            XLuaUiManager.SetMask(true)
        end,CS.UnityEngine.Playables.DirectorWrapMode.None)    
end

function XUiGridMovieActor:PlayAnimFront(skipAnim)
    if not self.IsUsing then return end

    if self.Status == ShowStatus.Front then return end

    local anim = self:GetStatusAnim(ShowStatus.Front)
    if not anim then return end

    self.Status = ShowStatus.Front

    if skipAnim then
        self:RevertActorPanel()
        return
    end

    if self.IsPlayingEnable then
        self.DelayAnim = anim
        return
    end

        anim.gameObject:SetActiveEx(true)
        anim:PlayTimelineAnimation(function()
            XLuaUiManager.SetMask(false)
            self:StopAnimtion(AnimNames.NormalToFront)
            self:StopAnimtion(AnimNames.BackToFront)
            self:RevertActorPanel()
        end, function()
            XLuaUiManager.SetMask(true)
        end,CS.UnityEngine.Playables.DirectorWrapMode.None)    
end

function XUiGridMovieActor:GetStatusAnim(toStatus)
    local anim
    local status = self.Status
    if toStatus == ShowStatus.Back then
        if status == ShowStatus.Normal then
            anim = self:GetAnim(AnimNames.NormalToBack)
        elseif status == ShowStatus.Front then
            anim = self:GetAnim(AnimNames.FrontToBack)
        end
    elseif toStatus == ShowStatus.Front then
        if status == ShowStatus.Normal then
            anim = self:GetAnim(AnimNames.NormalToFront)
        elseif status == ShowStatus.Back then
            anim = self:GetAnim(AnimNames.BackToFront)
        end
    end

    return anim
end

function XUiGridMovieActor:PlayFadeAnimation(beginAlpha,endAlpha,duration)
    self.CanvasGroup.alpha = beginAlpha
    self.CanvasGroup:DOFade(endAlpha, duration)
end

function XUiGridMovieActor:StopAnimtion(animShortName)
    local anim = self:GetAnim(animShortName)
    if anim then
        local timelineAnimation = anim.transform:GetComponent(typeof(CSXUiPlayTimelineAnimation))
        if timelineAnimation then
            timelineAnimation:Stop(false)
        end
        self.PlayingAnimDic[anim] = nil
    end
end

-- 根据动画名称获取动画
function XUiGridMovieActor:GetAnim(animShortName)
    local animName = AnimNameHead .. tostring(self.ActorIndex) .. animShortName
    local anim = self.UiRoot[animName]
    if anim then
        return anim
    end

    animName = AnimNameHead .. animShortName
    anim = self.PanelActor[animName]
    if anim then
        return anim
    end

    return
end

return XUiGridMovieActor