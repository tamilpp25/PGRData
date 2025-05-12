
---@class XRestaurantPerformAgent : XLuaBehaviorAgent 厨房演出代理
---@field Perform XRestaurantPerform
local XRestaurantPerformAgent = XLuaBehaviorManager.RegisterAgent(XLuaBehaviorAgent, "RestaurantPerform")

function XRestaurantPerformAgent:SetPerform(perform)
    self.Perform = perform
end

function XRestaurantPerformAgent:LoadPerformProp(isActor, npcId, position, rotation, loadCb)
    if isActor then
        self.Perform:LoadActor(npcId, position, rotation, loadCb)
    else
        self.Perform:LoadFurniture(npcId, position, rotation, loadCb)
    end
end

function XRestaurantPerformAgent:IsEqualState(state)
    return self.Perform:IsEqualState(state)
end

function XRestaurantPerformAgent:ChangeState(state)
    self.Perform:ChangeState(state)
end

function XRestaurantPerformAgent:BeginPerform()
    self.Perform:DoBegin()
end

function XRestaurantPerformAgent:DoBubble(npcId, dialogId, index)
    self.Perform:DoBubble(npcId, dialogId, index)
end

function XRestaurantPerformAgent:DoHideBubble(npcId)
    self.Perform:DoHideBubble(npcId)
end

function XRestaurantPerformAgent:DoDestroyProps(npcId)
    self.Perform:DoDestroyProps(npcId)
end

function XRestaurantPerformAgent:DestroyAllProps()
    self.Perform:DestroyAllProps(true)
end