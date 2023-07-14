---@class XUiFestivalActivityProxyDefault
local XUiFestivalActivityProxyDefault = XClass(nil, "XUiFestivalActivityProxyDefault")

function XUiFestivalActivityProxyDefault:GetTimeFormatType()
    return XUiHelper.TimeFormatType.ACTIVITY
end

function XUiFestivalActivityProxyDefault:GetScrollOffsetX(ui)
    return 0
end

return XUiFestivalActivityProxyDefault