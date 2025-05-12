--- 定向卡池蓝点
local XRedPointXWheelChairManualLotto = {}


function XRedPointXWheelChairManualLotto:Check()
    if not XMVCA.XWheelchairManual:GetIsOpen(nil, true) then
        return false
    end

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Lotto) then
        return false
    end

    -- 新开启蓝点
    if XMVCA.XWheelchairManual:CheckSubActivityIsNew(XEnumConst.WheelchairManual.ReddotKey.LottoNew) then
        return true
    end
end

return XRedPointXWheelChairManualLotto