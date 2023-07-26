
local XUiHitMouseMainPanelInfo = {}

local TimerId

local TempPanel
--=================
--获取活动剩余时间字符串
--=================
local GetLeftTimeStr = function()
    local leftTime = XDataCenter.HitMouseManager.GetActivityLeftTime()
    return XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
end
--=================
--设置剩余时间
--=================
local SetLeftTime = function()
    if TempPanel.TxtRemainTime then
        TempPanel.TxtRemainTime.text = GetLeftTimeStr()
    end
end
function XUiHitMouseMainPanelInfo.Init(ui)
    ui.InfoPanel = {}
    XTool.InitUiObjectByUi(ui.InfoPanel, ui.PanelInformation)
end

function XUiHitMouseMainPanelInfo.OnEnable(ui)
    if not TempPanel then TempPanel = ui.InfoPanel end
    XUiHitMouseMainPanelInfo.StartLeftTimer()
end

function XUiHitMouseMainPanelInfo.OnDisable(ui)
    XUiHitMouseMainPanelInfo.RemoveLeftTimer()
end

function XUiHitMouseMainPanelInfo.StartLeftTimer()
    --若已经存在计时器，将其移除
    if TimerId then
        XUiHitMouseMainPanelInfo.RemoveLeftTimer()
    end
    --先设置文本，再开始计时器持续更新文本
    SetLeftTime()
    TimerId = XScheduleManager.ScheduleForever(function()
            SetLeftTime()
        end, 0)
end
--=================
--移除计时器
--=================
function XUiHitMouseMainPanelInfo.RemoveLeftTimer()
    if not TimerId then return end
    XScheduleManager.UnSchedule(TimerId)
    TimerId = nil
end

function XUiHitMouseMainPanelInfo.OnDestroy()
    XUiHitMouseMainPanelInfo.RemoveLeftTimer()
    TempPanel = nil
end

return XUiHitMouseMainPanelInfo