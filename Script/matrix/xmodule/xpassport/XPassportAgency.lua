---@class XPassportAgency : XAgency
---@field private _Model XPassportModel
local XPassportAgency = XClass(XAgency, "XPassportAgency")
function XPassportAgency:OnInit()
end

function XPassportAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyPassportData = Handler(self, self.NotifyPassportData)
    XRpc.NotifyPassportBaseInfo = Handler(self, self.NotifyPassportBaseInfo)
    XRpc.NotifyPassportAutoGetTaskReward = Handler(self, self.NotifyPassportAutoGetTaskReward)
end

function XPassportAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--登录推送数据
function XPassportAgency:NotifyPassportData(data)
    self._Model:NotifyPassportData(data)
end

function XPassportAgency:NotifyPassportBaseInfo(data)
    self._Model:NotifyPassportBaseInfo(data)
end

function XPassportAgency:NotifyPassportAutoGetTaskReward(data)
    self._Model:NotifyPassportAutoGetTaskReward(data)
end

function XPassportAgency:CheckPassportRewardRedPoint()
    return self._Model:CheckPassportRewardRedPoint()
end

function XPassportAgency:GetPassportBaseInfo()
    return self._Model:GetBaseInfo()
end

function XPassportAgency:CheckPassportAchievedTaskRedPoint(...)
    return self._Model:CheckPassportAchievedTaskRedPoint(...)
end

function XPassportAgency:IsActivityClose()
    return self._Model:IsActivityClose()
end

function XPassportAgency:OpenMainUi()
    if not self._Model:CheckActivityIsOpen(true) then
        return
    end
    XLuaUiManager.Open("UiPassport")
end

function XPassportAgency:GetPassportActivityTimeId()
    return self._Model:GetPassportActivityTimeId()
end

function XPassportAgency:GetPassportMaxLevel()
    return self._Model:GetPassportMaxLevel()
end

return XPassportAgency