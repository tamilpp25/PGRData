--=============
--家具事件基类
--=============
---@class XGDFBaseEvent
local XGDFBaseEvent = XClass(nil, "XGDFBaseEvent")

function XGDFBaseEvent:Ctor(cb)
    self.CallBack = cb
    self:Init()
end

function XGDFBaseEvent:Init()
    self:CheckOnce()
end

function XGDFBaseEvent:CheckOnce()
    
end

function XGDFBaseEvent:Trigger(value)
    if self.CallBack then
        self.CallBack(value)
    end
end

function XGDFBaseEvent:Dispose()
    
end

return XGDFBaseEvent