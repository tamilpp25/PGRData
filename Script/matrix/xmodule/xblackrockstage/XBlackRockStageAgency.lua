local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XBlackRockStageAgency : XAgency
---@field private _Model XBlackRockStageModel
local XBlackRockStageAgency = XClass(XFubenActivityAgency, "XBlackRockStageAgency")
function XBlackRockStageAgency:OnInit()
    --初始化一些变量

    --添加到Manager里
    self:RegisterActivityAgency()
end

function XBlackRockStageAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XBlackRockStageAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XBlackRockStageAgency:IsOpen()
    return self._Model:IsOpen()
end

--region   ------------------副本入口扩展 start-------------------

function XBlackRockStageAgency:ExOpenMainUi()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FubenActivityFestival) then
        return
    end

    if not self:IsOpen() then
        XUiManager.TipText("CommonActivityNotStart")
        return
    end

    XLuaUiManager.Open("UiBlackRockStage")
end

function XBlackRockStageAgency:ExCheckInTime()
    if not XBlackRockStageAgency.Super.ExCheckInTime(self) then
        return false
    end
    return self:IsOpen()
end

function XBlackRockStageAgency:ExGetConfig()
    if not XTool.IsTableEmpty(self.ExConfig) then
        return self.ExConfig
    end
    self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    return self.ExConfig
end

function XBlackRockStageAgency:ExGetProgressTip()
    local v1, v2 = self._Model:GetStageProgress()
    return v1 .. "/" .. v2
end

--endregion------------------副本入口扩展 finish------------------

return XBlackRockStageAgency