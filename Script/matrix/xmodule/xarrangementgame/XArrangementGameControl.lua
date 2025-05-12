---@class XArrangementGameControl : XControl
---@field private _Model XArrangementGameModel
local XArrangementGameControl = XClass(XControl, "XArrangementGameControl")
function XArrangementGameControl:OnInit()
    --初始化内部变量
end

function XArrangementGameControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XArrangementGameControl:RemoveAgencyEvent()
end

function XArrangementGameControl:OnRelease()
end

function XArrangementGameControl:GetModelArrangementGameSelection()
    return self._Model:GetArrangementGameSelection()
end

return XArrangementGameControl