---@class XPlanetBubbleManager
local XPlanetBubbleManager = XClass(nil, "XPlanet")
local XPlanetBubble = require("XUi/XUiPlanet/Explore/Bubble/XPlanetBubble")
local XPlanetBubbleText = require("XUi/XUiPlanet/Explore/Bubble/XPlanetBubbleText")

function XPlanetBubbleManager:Ctor(rootProxy, rootUi, bubbleRootTransform, camera)
    if not rootProxy or not rootUi or not bubbleRootTransform or not camera then
        return
    end

    ---@type XPlanetRunningExplore
    self.RootProxy = rootProxy
    self.RootUi = rootUi

    -- 所有气泡的父节点
    self.BubbleRootTransform = bubbleRootTransform
    self.Camera = camera
    ---@type XPlanetBubble[]
    self.EntityBubbleDic = {} -- 气泡资源实例 
    ---@type XPlanetBubbleText[]
    self.EntityBubbleTextDict = {}
    self.BubbleControllerDic = {} -- key = ControllerId , value = {XBubble = xBubble, CurTriggerCount = 0, NextIntervalTimeStamp}

    self._IsHideBubbleText = false
end

-- 开启控制器检测
function XPlanetBubbleManager:CheckControllerPass(controllerData)
    -- 间隔检测
    local controllerConfig = controllerData.Config
    local now = XTime.GetServerNowTimestamp()
    if controllerData.NextIntervalTimeStamp and now < controllerData.NextIntervalTimeStamp then
        return false
    end
    -- 间隔检测通过 刷新下次触发间隔时间戳
    controllerData.NextIntervalTimeStamp = now + controllerConfig.IntervalTime

    -- 触发次数检测
    if controllerData.CurTriggerCount >= controllerConfig.TriggerLimitCount then
        return false
    end
    -- 次数检测通过，增加次数
    controllerData.CurTriggerCount = controllerData.CurTriggerCount + 1

    return true
end

function XPlanetBubbleManager:PlayBubble(controllerBubbleId, entityId)
    if not self.RootProxy or not self.BubbleRootTransform then
        return
    end

    local controllerData = self.BubbleControllerDic[controllerBubbleId]
    if not controllerData then
        controllerData = {}
        local controllerConfig = XPlanetExploreConfigs.GetBubbleController(controllerBubbleId)
        controllerData.XBubble = nil
        controllerData.Config = controllerConfig
        controllerData.CurTriggerCount = 0
        controllerData.NextIntervalTimeStamp = nil
        self.BubbleControllerDic[controllerBubbleId] = controllerData
    end

    if not self:CheckControllerPass(controllerData) then
        return
    end

    local xBubble = self.EntityBubbleDic[entityId]
    local panelModel = self.RootProxy:GetModel(entityId)
    if not xBubble then
        xBubble = XPlanetBubble.New(self, self.RootUi, self.Camera, self.RootProxy.Scene, self.BubbleRootTransform, panelModel:GetTransform())
        self.EntityBubbleDic[entityId] = xBubble
    end
    controllerData.XBubble = xBubble
    xBubble:PlayRound(controllerBubbleId)
end

function XPlanetBubbleManager:StopBubble(entityId)
    local xBubble = self.EntityBubbleDic[entityId]
    if not xBubble then
        return
    end
    
    xBubble:Stop()
end

function XPlanetBubbleManager:StopAllBubble()
    for k, xBubble in pairs(self.EntityBubbleDic) do
        xBubble:Stop()
    end
end

function XPlanetBubbleManager:OnDestroy()
    self.RootProxy = nil
    self.RootUi = nil
    self.BubbleRootTransform = nil
    self.Camera = nil

    for k, xBubble in pairs(self.EntityBubbleDic) do
        xBubble:OnDestroy()
    end
    for k, xBubble in pairs(self.EntityBubbleTextDict) do
        xBubble:OnDestroy()
    end
    
    self.EntityBubbleDic = {}
    self.EntityBubbleTextDict = {}
    self.BubbleControllerDic = {}
end

function XPlanetBubbleManager:PlayBubbleText(entityId, text)
    local bubble = self.EntityBubbleTextDict[entityId]
    if not bubble then
        local panelModel = self.RootProxy:GetModel(entityId)
        bubble = XPlanetBubbleText.New(self, self.RootUi, self.Camera, self.RootProxy.Scene, self.BubbleRootTransform, panelModel:GetTransform())
        self.EntityBubbleTextDict[entityId] = bubble
    end
    bubble:Play(text)
    if self._IsHideBubbleText then
        bubble:HideText()
    end
end

function XPlanetBubbleManager:StopBubbleText(entityId)
    local bubble = self.EntityBubbleTextDict[entityId]
    if not bubble then
        return
    end
    bubble:Stop()
end

function  XPlanetBubbleManager:HideAllBubbleText()
    self._IsHideBubbleText = true
    for entityId, bubble in pairs(self.EntityBubbleTextDict) do
        bubble:HideText()
    end
end

function  XPlanetBubbleManager:ShowAllBubbleText()
    self._IsHideBubbleText = false
    for entityId, bubble in pairs(self.EntityBubbleTextDict) do
        bubble:ShowText()
    end
end

---@param entity XPlanetRunningExploreEntity
function XPlanetBubbleManager:UpdateFollowTransform(entity)
    local model = self.RootProxy:GetModel(entity.Id)
    if model then
        local bubbleText = self.EntityBubbleTextDict[entity.Id]
        if bubbleText then
            bubbleText:UpdateFollowTransform(model:GetTransform())
        end

        local bubble = self.EntityBubbleDic[entity.Id]
        if bubble then
            bubble:UpdateFollowTransform(model:GetTransform())
        end
    end
end

return XPlanetBubbleManager