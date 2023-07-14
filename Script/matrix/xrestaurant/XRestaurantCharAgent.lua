
---@class XRestaurantCharAgent : XLuaBehaviorAgent 厨房员工行为代理
---@field Role XRestaurantChar
local XRestaurantCharAgent = XLuaBehaviorManager.RegisterAgent(XLuaBehaviorAgent, "RestaurantChar")

function XRestaurantCharAgent:OnAwake()
end

function XRestaurantCharAgent:SetRole(role)
    self.Role = role
end

function XRestaurantCharAgent:DoAction(actionId, needFadeCross, crossDuration)
    self.Role:DoAction(actionId, needFadeCross, crossDuration)
end

function XRestaurantCharAgent:DoActionIndex(index, needFadeCross, crossDuration)
    self.Role:DoActionIndex(index, needFadeCross, crossDuration)
end

function XRestaurantCharAgent:DoRandomBubble()
    self.Role:DoRandomBubble()
end

function XRestaurantCharAgent:DoBubbleIndex(index)
    self.Role:DoBubble(index)
end

function XRestaurantCharAgent:DoHideBubble()
    self.Role:DoHideBubble()
end

function XRestaurantCharAgent:DoLoadEffect(path, position)
    self.Role:DoLoadEffect(path, position)
end

function XRestaurantCharAgent:DoHideEffect()
    self.Role:DoHideEffect()
end

function XRestaurantCharAgent:DoDestroyEffect()
    self.Role:DoDestroyEffect()
end

function XRestaurantCharAgent:GetActionId(index)
    return self.Role:GetActionId(index)
end

function XRestaurantCharAgent:GetActionDuration(index)
    return self.Role:GetActionDuration(index)
end

function XRestaurantCharAgent:DelayRelease()
    self.Role:Dispose()
end

function XRestaurantCharAgent:DoIsWorking()
    return self.Role:DoIsWorking()
end

function XRestaurantCharAgent:CheckPlayRepeat(index, isRequireRepeat)
    return self.Role:CheckPlayRepeat(index, isRequireRepeat)
end

function XRestaurantCharAgent:DoCheckInt(intValue)
    return self.Role:DoCheckInt(intValue)
end

function XRestaurantCharAgent:DoIsExist()
    return self.Role:Exist() and self.Role._GameObject.activeInHierarchy
end

function XRestaurantCharAgent:DoRandomPath()
    self.Role:DoFindRandomPoint()
end

function XRestaurantCharAgent:IsShowDelayBubble()
    return self.Role:IsShowDelayBubble()
end

function XRestaurantCharAgent:DoRandomBubbleDelay(delay)
    self.Role:DoRandomBubbleDelay(delay)
end

function XRestaurantCharAgent:DoLoadComplete()
    self.Role:DoLoadComplete()
end

function XRestaurantCharAgent:DoSetRedPoint()
    self.Role:DoSetRedPoint()
end

function XRestaurantCharAgent:DoSetGreenPoint()
    self.Role:DoSetGreenPoint()
end

function XRestaurantCharAgent:DoSetStartPoint()
    self.Role:DoSetStartPoint()
end

function XRestaurantCharAgent:DoStopMove()
    self.Role:DoStopMove()
end

function XRestaurantCharAgent:DoIsWorkWithBuff()
    return self.Role:IsWorkWithBuff()
end