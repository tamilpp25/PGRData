--=================
--主界面标题面板
--=================
local XUiSSBMainPanelTitle = {}
--=================
--面板
--=================
local Panel = {}
--=================
--计时器Id
--=================
local TimerId
--=================
--获取活动剩余时间字符串
--=================
local GetLeftTimeStr = function()
    local leftTime = XDataCenter.SuperSmashBrosManager.GetActivityLeftTime()
    return XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
end
--=================
--设置剩余时间
--=================
local SetLeftTime = function()
    if Panel.TxtLeftTime then
        Panel.TxtLeftTime.text = GetLeftTimeStr()
    end
end
--=================
--初始化
--=================
function XUiSSBMainPanelTitle.Init(ui)
    Panel = XTool.InitUiObjectByUi(Panel, ui.PanelTitle)
end
--=================
--显示时
--=================
function XUiSSBMainPanelTitle.OnEnable()
    XUiSSBMainPanelTitle.StartLeftTimer()
end
--=================
--开始活动时间计时器
--=================
function XUiSSBMainPanelTitle.StartLeftTimer()
    --若已经存在计时器，将其移除
    if TimerId then
        XUiSSBMainPanelTitle.RemoveLeftTimer()
    end
    --先设置文本，再开始计时器持续更新文本
    SetLeftTime()
    TimerId = XScheduleManager.ScheduleForever(function()
            if XTool.UObjIsNil(Panel.Transform) then
                XUiSSBMainPanelTitle.RemoveLeftTimer()
                return
            end
            SetLeftTime()
        end, 0)
end
--=================
--移除计时器
--=================
function XUiSSBMainPanelTitle.RemoveLeftTimer()
    if not TimerId then return end
    XScheduleManager.UnSchedule(TimerId)
    TimerId = nil
end
--=================
--设置背景图
--=================
function XUiSSBMainPanelTitle.SetBg(path)
    if Panel.RImgBg then
        Panel.RImgBg:SetRawImage(path)
    end
end
--=================
--隐藏时
--=================
function XUiSSBMainPanelTitle.OnDisable()
    XUiSSBMainPanelTitle.RemoveLeftTimer()
end
--=================
--销毁时
--=================
function XUiSSBMainPanelTitle.OnDestroy()
    Panel = {}
end

return XUiSSBMainPanelTitle