--============
--家具动画事件
--============
local XGuildDormFurnitureAnimationEvent = XClass(nil, "XGuildDormFurnitureAnimationEvent")

function XGuildDormFurnitureAnimationEvent:Ctor(eventType, cb)
    self.EventType = eventType
    self.CallBack = cb
end

function XGuildDormFurnitureAnimationEvent:OnEventTrigger(...)
    if self.CallBack then
        self.CallBack(...)
    end
end

function XGuildDormFurnitureAnimationEvent:Dispose()
    
end

return XGuildDormFurnitureAnimationEvent