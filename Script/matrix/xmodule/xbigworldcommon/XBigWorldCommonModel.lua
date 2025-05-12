---@class XBigWorldCommonModel : XModel
local XBigWorldCommonModel = XClass(XModel, "XBigWorldCommonModel")
function XBigWorldCommonModel:OnInit()
    
end

function XBigWorldCommonModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldCommonModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    
end

return XBigWorldCommonModel
