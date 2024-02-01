local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XFangKuaiAgency : XFubenActivityAgency
---@field private _Model XFangKuaiModel
local XFangKuaiAgency = XClass(XFubenActivityAgency, "XFangKuaiAgency")
function XFangKuaiAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
end

function XFangKuaiAgency:InitRpc()
    XRpc.NotifyFangKuaiData = handler(self, self.NotifyFangKuaiData)
end

function XFangKuaiAgency:InitEvent()
    --实现跨Agency事件注册
end

function XFangKuaiAgency:NotifyFangKuaiData(data)
    self._Model:NotifyFangKuaiData(data)
end

---功能是否有红点
function XFangKuaiAgency:CheckRedPoint()
    if not self._Model.ActivityData then
        return false
    end
    return self._Model:CheckTaskRedPoint() or self._Model:CheckAllChapterRedPoint()
end

---当有未通关的关卡时显示红点
function XFangKuaiAgency:CheckChallangeRedPoint()
    if not self._Model.ActivityData then
        return false
    end
    return self._Model:CheckChapterChallengeRedPoint(XEnumConst.FangKuai.Difficulty.Normal) or self._Model:CheckChapterChallengeRedPoint(XEnumConst.FangKuai.Difficulty.Hard)
end

---活动是否开启
function XFangKuaiAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FangKuai, false, noTips) then
        return false
    end
    if not self._Model.ActivityData or not self:ExCheckInTime() then
        if not noTips then
            XUiManager.TipText("CommonActivityNotStart")
        end
        return false
    end
    return true
end

function XFangKuaiAgency:GetActivityTimeId()
    if not self._Model.ActivityData then
        return 0
    end
    return self._Model:GetActivityConfig(self._Model.ActivityData:GetActivityId()).TimeId
end

---检查是否处于活动的游戏时间
function XFangKuaiAgency:CheckActivityIsInGameTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

---获取关卡结束时间
function XFangKuaiAgency:GetActivityGameEndTime()
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

--region 副本入口扩展

function XFangKuaiAgency:ExOpenMainUi()
    if not self:GetIsOpen() then
        return
    end
    -- 打开主界面
    XLuaUiManager.Open("UiFangKuaiMain")
end

function XFangKuaiAgency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenActivity
        self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    end
    return self.ExConfig
end

function XFangKuaiAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.FangKuai
end

function XFangKuaiAgency:ExCheckInTime()
    if not self.Super.ExCheckInTime(self) then
        return false
    end
    local timeId = self:GetActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XFangKuaiAgency:ExGetProgressTip()
    -- 游戏时间结束，不显示进度
    if not self:CheckActivityIsInGameTime() then
        return ""
    end
    local pass, all = self._Model:GetProgress()
    return XUiHelper.GetText("FangKuaiActivityProgress", pass, all)
end

function XFangKuaiAgency:ExGetRunningTimeStr()
    local isInGameTime = self:CheckActivityIsInGameTime()
    if isInGameTime then
        local gameEndTime = self:GetActivityGameEndTime()
        local gameTime = gameEndTime - XTime.GetServerNowTimestamp()
        local timeStr = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
        return XUiHelper.GetText("FangKuaiResetTime", timeStr)
    else
        return XUiHelper.GetText("FangKuaiActivityEnd")
    end
end

--endregion

function XFangKuaiAgency:EnterDebegMode()
    XSaveTool.SaveData("FangKuai_Debug", true)
end

function XFangKuaiAgency:CloseDebegMode()
    XSaveTool.SaveData("FangKuai_Debug", false)
end

return XFangKuaiAgency