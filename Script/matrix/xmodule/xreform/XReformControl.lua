---@class XReformControl : XControl
---@field private _Model XReformModel
local XReformControl = XClass(XControl, "XReformControl")
function XReformControl:OnInit()
    --初始化内部变量
end

function XReformControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
    self:GetAgency():AddEventListener(XEventId.EVENT_REFORM_SERVER_DATA, self.UpdateServerData, self)
end

function XReformControl:RemoveAgencyEvent()
    self:GetAgency():RemoveEventListener(XEventId.EVENT_REFORM_SERVER_DATA, self.UpdateServerData, self)
end

function XReformControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

function XReformControl:UpdateServerData()
    self._Model:InitWithServerData()
end

---@return XViewModelReform2ndList
function XReformControl:GetViewModel()
    return self._Model:GetViewModel()
end

---@return XViewModelReform2ndList
function XReformControl:GetViewModelList()
    return self._Model:GetViewModelList()
end

function XReformControl:GetActivityTime()
    return self._Model:GetActivityTime()
end

function XReformControl:GetActivityEndTime()
    return self._Model:GetActivityEndTime()
end

function XReformControl:GetActivityTime()
    return self._Model:GetActivityTime()
end

function XReformControl:GetHelpKey()
    return self._Model:GetHelpKey()
end

function XReformControl:GetChapterStarDesc(chapter)
    return self._Model:GetChapterStarDesc(chapter)
end

function XReformControl:IsChapterFinished(chapter)
    return self._Model:IsChapterFinished(chapter)
end

function XReformControl:GetChapterName(chapter)
    return self._Model:GetChapterName(chapter)
end

function XReformControl:GetStageName(stageId)
    return self._Model:GetStageName(stageId)
end

return XReformControl