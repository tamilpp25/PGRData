require("XBehavior/XLuaBehaviorManager")
require("XBehavior/XLuaBehaviorAgent")
local XGuildDormCharAgent = XLuaBehaviorManager.RegisterAgent(XLuaBehaviorAgent, "XGuildDormCharAgent")

function XGuildDormCharAgent:Ctor()
    self.Role = nil
end

function XGuildDormCharAgent:GetId()
    return self.Role:GetId()
end

function XGuildDormCharAgent:GetPlayerId()
    return self.Role:GetPlayerId()
end

function XGuildDormCharAgent:SetRole(role)
    self.Role = role
end

-- 设置角色交互触发
function XGuildDormCharAgent:SetCharInteractTrigger(isOn)
    XLog.Warning("================= SetCharInteractTrigger 用不上 ", isOn)
end

-- 关联家具
function XGuildDormCharAgent:InteractFurniture()
    XLog.Warning("================= InteractFurniture 用不上")
    return true
end

-- eventType : DormCharacterEvent表的CompletedType
function XGuildDormCharAgent:CheckEventCompleted(eventType, callback)
    XLog.Warning("================= CheckEventCompleted 用不上")
    -- 主要检查【想要抚摸】【想要给奖励】【想要坐沙发】这样的事件是否完成
    -- 公会宿舍用不上
    if callback then callback() end
    return true
end

function XGuildDormCharAgent:ShowEventReward()
    XLog.Warning("================= ShowEventReward 用不上")
    -- 播放事件奖励，暂时用不上
end

-- 做动画
function XGuildDormCharAgent:DoAction(actionId, needFadeCross, crossDuration)
    self.Role:GetRLRole():PlayAnimation(actionId, needFadeCross, crossDuration)
end

function XGuildDormCharAgent:ShowBubble(dialogId, callback)
    XLog.Warning("================= ShowBubble 用不上", dialogId, callback)
    -- 暂时用不上
    if callback then callback() end
end

-- 隐藏汽包
function XGuildDormCharAgent:HideBubble()
    XLog.Warning("================= HideBubble 用不上")
    -- 暂时用不上
end

-- 播放特效
function XGuildDormCharAgent:PlayEffect(effectId, worldPos)
    local rlRole = self.Role:GetRLRole()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ROLE_SHOW_EFFECT, self:GetPlayerId(), self:GetId()
    , effectId, rlRole:GetTransform(), worldPos)
end

-- 隐藏特效
function XGuildDormCharAgent:HideEffect()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ROLE_HIDE_EFFECT, self:GetPlayerId())
end

-- 检测是否结束家具交互
function XGuildDormCharAgent:CheckDisInteractFurniture()
    XLog.Warning("================= CheckDisInteractFurniture 用不上 ")
    return true
end

-- 设置是否有阻挡
function XGuildDormCharAgent:SetObstackeEnable(value)
    XLog.Warning("================= SetObstackeEnable 用不上 ")
end

function XGuildDormCharAgent:CheckCharInteractPosByIndex(index)
    XLog.Warning("================= CheckCharInteractPosByIndex 用不上 ")
    return true
end

-- 改变状态
function XGuildDormCharAgent:ChangeStatus(state)
    if state == XGuildDormConfig.RoleFSMType.IDLE then
        self.Role:UpdateInteractStatus(XGuildDormConfig.InteractStatus.End)
        self.Role:EnableCharacterController(true)
    end
end

function XGuildDormCharAgent:SetForwardToFurniture(forward)
    local currentInteractInfo = self.Role:GetCurrentInteractInfo()
    if currentInteractInfo == nil then
        XLog.Error("公会宿舍行为树SetForwardToFurniture时交互信息为空")
        return
    end
    local eulerAngle = currentInteractInfo.InteractPos.transform.eulerAngles
    if forward < 0 then
        eulerAngle = eulerAngle + CS.UnityEngine.Vector3(0, 180, 0)
    end
    self.Role:GetAgent():SetVarDicByKey("TurnTo", eulerAngle)
    return true
end

function XGuildDormCharAgent:TurnToFurnitureStayPos(cb, isSlerp, isSetPosition)
    local currentInteractInfo = self.Role:GetCurrentInteractInfo()
    -- 设置停留位置
    local stayPos = currentInteractInfo.StayPos
    local transform = self.Role:GetRLRole():GetTransform()
    if isSetPosition then
        transform.position = stayPos.transform.position
    end
    if isSlerp then
        self.Role:GetAgent():SetVarDicByKey("TurnToData", {
            rotation = stayPos.transform.rotation,
            finishedCb = cb
        })
    else
        transform.rotation = stayPos.transform.rotation
        if cb then cb() end
    end
end

function XGuildDormCharAgent:CheckIsDirectInteract()
    return self.Agent:GetVarDicByKey("IsDirectInteract")
end

return XGuildDormCharAgent