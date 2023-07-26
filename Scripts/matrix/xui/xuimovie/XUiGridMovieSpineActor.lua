local XUiGridMovieSpineActor = XClass(nil, "XUiGridMovieSpineActor")
local DEFAULT_KOU_SPEED = 1
local ROLE_ANIM_TIME = 4
local ROLE_ANIM2_TIME = 1
local DEFAULT_GRAY_SCALE = 0 -- 默认灰度值
local DEFAULT_COLOR = CS.UnityEngine.Color.white
local BLACK_COLOR = CS.UnityEngine.Color(0.39, 0.39, 0.39, 1)

function XUiGridMovieSpineActor:Ctor(uiRoot, obj, actorIndex)
    self.UiRoot = uiRoot
    self.GameObject = obj.gameObject
    self.Transform = obj.transform
    self.ActorIndex = actorIndex
    self.ActorId = nil -- 角色id
    self.AnimIndex = 0 -- 角色动画的下标
    self.TransIndex = 0 -- 转换动画的下标
    self.TalkSpeed = 1 -- 讲话的速度
    self.IsTalking = false -- 是否在讲话状态
    self.GrayValue = 0 -- 灰度值
    XTool.InitUiObject(self)

    self.GameObject.gameObject:SetActiveEx(false)
end

function XUiGridMovieSpineActor:Destroy()
    self.UiRoot = nil
end

function XUiGridMovieSpineActor:UpdateSpineActor(actorId, animIndex)
    if self.ActorId == actorId then 
        self.AnimIndex = animIndex

        -- 播放动画
        self:PlayAnimationsLoop(self.AnimIndex)
        self:UpdateKouAnim()

        -- 更新灰度值
        self:UpdateGrayScale(true)
    else
        self.ActorId = actorId
        self.AnimIndex = animIndex
        self:LoadSpine()
    end
end

function XUiGridMovieSpineActor:LoadSpine()
    self.SpinePath = XMovieConfigs.GetSpineActorSpinePath(self.ActorId)
    if not string.IsNilOrEmpty(self.SpinePath) then
        self:StopAnimationsLoop()
        local spine = self.SpineLink:LoadPrefab(self.SpinePath)
        self.SpineUiObject = spine:GetComponent("UiObject")

        -- 加载完直接播配置的动画
        self:PlayAnimationsLoop(self.AnimIndex)
        self:UpdateKouAnim()

        -- 更新灰度值
        self:UpdateGrayScale(true)
    end
end

function XUiGridMovieSpineActor:SetPos(pos)
    if self.Pos == pos then return end

    self.Pos = pos
    self.SpineLink.anchoredPosition3D = pos
end

function XUiGridMovieSpineActor:GetPos()
    return self.Pos
end

function XUiGridMovieSpineActor:SetShow(isShow)
    self.GameObject.gameObject:SetActiveEx(isShow)
end

function XUiGridMovieSpineActor:IsShow()
    return self.GameObject.gameObject.activeSelf
end

-- 播放讲话动画
function XUiGridMovieSpineActor:PlayKouTalkAnim(speed)
    self.IsTalking = true
    self.TalkSpeed = speed

    local kouComponent = self.SpineUiObject:GetObject("Kou")
    local talkAnim = XMovieConfigs.GetSpineActorKouTalkAnim(self.ActorId, self.AnimIndex)
    if kouComponent and talkAnim and kouComponent.AnimationState then
        local curAnimName = kouComponent.AnimationState:ToString()
        if talkAnim and talkAnim ~= curAnimName then
            kouComponent.AnimationState:SetAnimation(0, talkAnim, true)
            kouComponent.timeScale = speed == 0 and DEFAULT_KOU_SPEED or speed / 1000
        end
    end
end

-- 播放待机动画
function XUiGridMovieSpineActor:PlayKouIdleAnim()
    self.IsTalking = false

    local kouComponent = self.SpineUiObject:GetObject("Kou")
    local idleAnim = XMovieConfigs.GetSpineActorKouIdleAnim(self.ActorId, self.AnimIndex)
    if kouComponent and idleAnim and kouComponent.AnimationState then
        local curAnimName = kouComponent.AnimationState:ToString()
        if idleAnim and idleAnim ~= curAnimName then
            kouComponent.AnimationState:SetAnimation(0, idleAnim, true)
            kouComponent.timeScale = DEFAULT_KOU_SPEED
        end
    end
end

-- 更新当前口的动画
function XUiGridMovieSpineActor:UpdateKouAnim()
    if self.IsTalking then
        self:PlayKouTalkAnim(self.TalkSpeed)
    else
        self:PlayKouIdleAnim()
    end
end

-- 播放ui动画
-- isOnce为只播一次，再次触发时，则跳过不播
function XUiGridMovieSpineActor:PlayUiAnimation(animName, finishCb, isOnce)
    if not self.SpineUiObject or not self:IsShow() then
        return
    end

    if isOnce then
        if self.LastUiAnimation == animName then
            return
        end

        -- PanelActorEnable与PanelActorDarkDisable效果相似
        if self.LastUiAnimation == XMovieConfigs.SpineActorAnim.PanelActorEnable and 
            animName == XMovieConfigs.SpineActorAnim.PanelActorDarkDisable then
            return
        end
    end

    self.LastUiAnimation = animName
    local anim = self.SpineUiObject:GetObject(animName)
    if anim then
        anim.gameObject:PlayTimelineAnimation(finishCb)
    elseif finishCb then
        finishCb()
    end
end

-- 播放spine角色动画
function XUiGridMovieSpineActor:PlayAnim(animIndex, transIndex)
    self.AnimIndex = animIndex
    self.TransIndex = transIndex

    local roleComponent = self.SpineUiObject:GetObject("Role") -- Spine.Unity.SkeletonGraphic
    if roleComponent then
        self:StopAnimationsLoop()

        -- 当前动画播完回调
        self.CurCompleteCb = function()
            local transAnimName = transIndex == 0 and nil or XMovieConfigs.GetSpineActorTransitionAnim(self.ActorId, transIndex)
            if transAnimName then
                roleComponent.AnimationState:SetAnimation(0, transAnimName, false)

                -- 过渡动画播完回调
                self.TransCompleteCb = function()
                    self:PlayAnimationsLoop(animIndex)
                    self:UpdateKouAnim()
                    roleComponent.AnimationState:Complete('-', self.TransCompleteCb)
                end
                roleComponent.AnimationState:Complete('+', self.TransCompleteCb)
            else
                self:PlayAnimationsLoop(animIndex)
                self:UpdateKouAnim()
            end

            roleComponent.AnimationState:Complete('-', self.CurCompleteCb)
        end
        roleComponent.AnimationState:Complete('+', self.CurCompleteCb)
    end
end

-- 播放两个动画组成的循环动画
function XUiGridMovieSpineActor:PlayAnimationsLoop(animIndex)
    self:StopAnimationsLoop()

    local roleComponent = self.SpineUiObject:GetObject("Role") -- Spine.Unity.SkeletonGraphic
    local animName = XMovieConfigs.GetSpineActorRoleAnim(self.ActorId, animIndex)
    local anim2Name = XMovieConfigs.GetSpineActorRoleAnim2(self.ActorId, animIndex)

    if not anim2Name then
        roleComponent.AnimationState:SetAnimation(0, animName, true)
    else
        self.PlayRoleAnim = function()
            self.RoleAnimPlayTime = 0
            roleComponent.AnimationState:SetAnimation(0, animName, true)
            roleComponent.AnimationState:Complete('+', self.OnPlayRoleAnimComplete)
        end

        self.OnPlayRoleAnimComplete = function()
            self.RoleAnimPlayTime = self.RoleAnimPlayTime + 1
            if self.RoleAnimPlayTime == ROLE_ANIM_TIME then
                self:PlayRoleAnim2()
                roleComponent.AnimationState:Complete('-', self.OnPlayRoleAnimComplete)
                self.RoleAnimPlayTime = 0
            end
        end

        self.PlayRoleAnim2 = function()
            self.RoleAnimPlayTime2 = 0
            roleComponent.AnimationState:SetAnimation(0, anim2Name, true)
            roleComponent.AnimationState:Complete('+', self.OnPlayRoleAnim2Complete)
        end

        self.OnPlayRoleAnim2Complete = function()
            self.RoleAnimPlayTime2 = self.RoleAnimPlayTime2 + 1
            if self.RoleAnimPlayTime2 == ROLE_ANIM2_TIME then
                self:PlayRoleAnim()
                roleComponent.AnimationState:Complete('-', self.OnPlayRoleAnim2Complete)
                self.RoleAnimPlayTime2 = 0
            end
        end

        self.PlayRoleAnim()
    end
end

-- 停止动画的循环播放回调
function XUiGridMovieSpineActor:StopAnimationsLoop()
    if not self.SpineUiObject then
        return
    end

    local roleComponent = self.SpineUiObject:GetObject("Role") -- Spine.Unity.SkeletonGraphic
    if self.RoleAnimPlayTime then
        roleComponent.AnimationState:Complete('-', self.OnPlayRoleAnimComplete)
    end
    if self.RoleAnimPlayTime2 then
        roleComponent.AnimationState:Complete('-', self.OnPlayRoleAnim2Complete)
    end
end

-- 设置灰度值
function XUiGridMovieSpineActor:SetGrayScale(value)
    if self.GrayValue == value then return end
    self.GrayValue = value

    self:UpdateGrayScale()
end

-- 更新灰度值
-- ignoreDefault忽略默认灰度值
function XUiGridMovieSpineActor:UpdateGrayScale(ignoreDefault)
    if not self:IsShow() then return end
    if not self.SpineUiObject then return end
    if ignoreDefault and self.GrayValue == DEFAULT_GRAY_SCALE then return end

    local kou = self.SpineUiObject:GetObject("Kou")
    if kou then 
        local matController = kou.gameObject:GetComponent("XUiMaterialController")
        if not matController then 
            matController = kou.gameObject:AddComponent(typeof(CS.XUiMaterialController))
        end
        matController:SetGrayScale(self.GrayValue)
    end
    local role = self.SpineUiObject:GetObject("Role")
    if role then 
        local matController = role.gameObject:GetComponent("XUiMaterialController")
        if not matController then 
            matController = role.gameObject:AddComponent(typeof(CS.XUiMaterialController))
        end
        matController:SetGrayScale(self.GrayValue)
    end
end

-- 播放spine变亮动画，skipAnim为true时，直接设置最终的颜色，不播动画
function XUiGridMovieSpineActor:PlayAnimFront(skipAnim)
    if not self:IsShow() then return end
    if not self.SpineUiObject then return end

    local role = self.SpineUiObject:GetObject("Role")
    local kou = self.SpineUiObject:GetObject("Kou")
    if skipAnim then
        role.color = DEFAULT_COLOR
        kou.color = DEFAULT_COLOR
        self.LastUiAnimation = XMovieConfigs.SpineActorAnim.PanelActorDarkDisable
    else
        self:PlayUiAnimation(XMovieConfigs.SpineActorAnim.PanelActorDarkDisable, nil, true)
    end
end

-- 播放spine变暗动画，skipAnim为true时，直接设置最终的颜色，不播动画
function XUiGridMovieSpineActor:PlayAnimBack(skipAnim)
    if not self:IsShow() then return end
    if not self.SpineUiObject then return end

    local role = self.SpineUiObject:GetObject("Role")
    local kou = self.SpineUiObject:GetObject("Kou")
    if skipAnim then
        role.color = BLACK_COLOR
        kou.color = BLACK_COLOR
        self.LastUiAnimation = XMovieConfigs.SpineActorAnim.PanelActorDarkNor
    else
        self:PlayUiAnimation(XMovieConfigs.SpineActorAnim.PanelActorDarkNor, nil, true)
    end
end

return XUiGridMovieSpineActor