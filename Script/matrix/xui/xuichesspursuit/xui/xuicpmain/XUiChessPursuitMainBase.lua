local XUiChessPursuitMainBase = XClass(nil, "XUiChessPursuitMainBase")

function XUiChessPursuitMainBase:Init(params)
    self.UiType =  params.UiType
end

function XUiChessPursuitMainBase:Update()
    XLog.Error("此接口需要被重写")
end

function XUiChessPursuitMainBase:Dispose()
    XLog.Error("此接口需要被重写")
end

function XUiChessPursuitMainBase:GetUiType()
    return self.UiType
end

return XUiChessPursuitMainBase