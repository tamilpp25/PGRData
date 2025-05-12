---@class XBigWorldSetAgency : XAgency
---@field private _Model XBigWorldSetModel
local XBigWorldSetAgency = XClass(XAgency, "XBigWorldSetAgency")
function XBigWorldSetAgency:OnInit()
    --初始化一些变量
end

function XBigWorldSetAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XBigWorldSetAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XBigWorldSetAgency:GetDefaultSetTypes()
    return {
        XEnumConst.BWSetting.SetType.Voice,
        XEnumConst.BWSetting.SetType.Graphics,
        XEnumConst.BWSetting.SetType.Other,
    }
end

function XBigWorldSetAgency:OpenSettingUi()
    XMVCA.XBigWorldUI:Open("UiBigWorldSet")
end

function XBigWorldSetAgency:SetSpecialScreenOff(value)
    self._Model:SetSpecialScreenOff(value)
end

return XBigWorldSetAgency