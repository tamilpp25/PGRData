---@class XFightCaptureV217Control : XControl
---@field private _Model XFightCaptureV217Model
---@field PlayAttachEffect --XRLAttachEffect
local XFightCaptureV217Control = XClass(XControl, "XFightCaptureV217Control")

local DELAY = 0.25

function XFightCaptureV217Control:OnInit()
    self.IsToggleDofOn = false   --景深开关
    self.IsToggleRoleOn = true  --显示角色开关
    self.PlayingActionId = 0    --当前播放的动作配置id
    self.PlayAttachEffect = nil --当前播放中的特效
    self.UseScreenEffectId = 0  --当前使用中的屏幕特效配置id
    self:SetScreenEffectCallBack(nil) --设置屏幕特效后的回调方法
end

function XFightCaptureV217Control:AddAgencyEvent()
end

function XFightCaptureV217Control:RemoveAgencyEvent()
end

function XFightCaptureV217Control:OnRelease()
    self:SetScreenEffectCallBack(nil)
    local rlNpc = self:GetRLNpc()
    if not rlNpc then
        return
    end
    
    if self.PlayAttachEffect and rlNpc.Npc.Fight then
        rlNpc.Npc.Fight.RLManager:RemoveEntityImmediately(self.PlayAttachEffect)
    end
end

function XFightCaptureV217Control:SetIsToggleFovOn(isToggleFovOn)
    self.IsToggleDofOn = isToggleFovOn
    self:SetActiveDof(isToggleFovOn)
end

function XFightCaptureV217Control:SetIsToggleRoleOn(isToggleRoleOn)
    self.IsToggleRoleOn = isToggleRoleOn
    self:SetNpcActive(isToggleRoleOn)
end

--region 屏幕特效
function XFightCaptureV217Control:SetUseScreenEffectId(screenEffectId)
    self.UseScreenEffectId = screenEffectId
    if self.ScreenEffectCallBack then
        self.ScreenEffectCallBack(screenEffectId)
    end
end

function XFightCaptureV217Control:SetScreenEffectCallBack(func)
    self.ScreenEffectCallBack = func
end
--endregion

--region npc相关
function XFightCaptureV217Control:GetRLNpc()
    local fight = CS.XFight.Instance
    if not fight then
        return
    end
    
    local role = fight:GetClientRole()
    if not role then
        return
    end
    
    if not role.Npc then
        return
    end
    
    return role.Npc.RLNpc
end

function XFightCaptureV217Control:SetNpcActive(isActive)
    local rlNpc = self:GetRLNpc()
    if not rlNpc then
        return
    end
    rlNpc:SetActive(isActive)
end

function XFightCaptureV217Control:GetNpcPos()
    local rlNpc = self:GetRLNpc()
    if not rlNpc then
        return
    end
    return rlNpc.LastPosition
end

function XFightCaptureV217Control:SetActiveDof(isActive)
    if not isActive then
        CS.XDofManager.Instance:SetDofFocus(nil)
        return
    end

    local rlNpc = self:GetRLNpc()
    if not rlNpc or not rlNpc.Transform then
        return
    end
    CS.XDofManager.Instance:SetDofFocus(rlNpc.Transform)
end

function XFightCaptureV217Control:GetRlWeapon()
    if not XTool.IsNumberValid(self.PlayingActionId) then
        return
    end
    
    local rlNpc = self:GetRLNpc()
    if not rlNpc then
        return
    end

    local params = self._Model:GetPlayParams(self.PlayingActionId)
    if not params then
        return
    end

    local weaponId = tonumber(params[3])
    if not weaponId then
        return
    end
    return rlNpc:GetWeapon(weaponId)
end
---=================================================
--- 播放'AnimaName'动画，‘fromBegin’决定动画是否需要调整到从0开始播放，默认值为false
---@param actionId number CaptureV217NpcAction表的id
---@param fromBegin boolean
---=================================================
function XFightCaptureV217Control:PlayNpcAction(actionId, fromBegin)
    local rlNpc = self:GetRLNpc()
    if not rlNpc or not rlNpc.animator then
        return
    end

    rlNpc.animator.speed = 1

    local params = self._Model:GetPlayParams(actionId)
    local stateName, layer = params[2], tonumber(params[1])
    if not stateName or not layer then
        XLog.Error("播放角色动作失败，NpcAnim配置Id：", actionId)
        return
    end

    self.PlayingActionId = actionId
    
    if fromBegin then
        rlNpc.animator:CrossFadeInFixedTime(stateName, DELAY, layer, 0)
    else
        rlNpc.animator:Play(stateName, layer)
    end
    
    -- 播放武器动画
    local weaponId = tonumber(params[3])
    local rlWeapon = weaponId and weaponId > 0 and rlNpc:GetWeapon(weaponId)
    if rlWeapon then
        rlWeapon.Animator.speed = 1
        stateName, layer = params[5], tonumber(params[4])
        rlWeapon:PlayAnimationManually(layer, stateName, DELAY)
    end
    
    -- 播放特效
    if self.PlayAttachEffect and rlNpc.Npc.Fight then
        rlNpc.Npc.Fight.RLManager:RemoveEntityImmediately(self.PlayAttachEffect)
    end
    local effectName = params[6]
    self.PlayAttachEffect = rlNpc:PlayAttachEffect(effectName, "", Vector3.zero, Vector3.zero)
end

function XFightCaptureV217Control:StopNpcAnima()
    local rlNpc = self:GetRLNpc()
    if not rlNpc or not rlNpc.animator then
        return
    end
    rlNpc.animator.speed = 0
    
    local rlWeapon = self:GetRlWeapon()
    if rlWeapon and rlWeapon.Animator then
        rlWeapon.Animator.speed = 0
    end

    if self.PlayAttachEffect then
        self.PlayAttachEffect:ChangeSpeed(0)
    end
end
--endregion

return XFightCaptureV217Control