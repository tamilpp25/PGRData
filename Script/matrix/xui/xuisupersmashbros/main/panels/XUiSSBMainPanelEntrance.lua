--=================
--主界面模式入口面板
--=================
local XUiSSBMainPanelEntrance = {}
--=================
--面板
--=================
local Panel = {}
--=================
--模式入口控件列表(按模式优先级排序)
--=================
local Entrances = {}
--=================
--初始化入口
--=================
local InitEntrances = function()
    if Panel.GridEntrance then
        --先把模板隐藏
        Panel.GridEntrance.gameObject:SetActiveEx(false)
        local entranceScript = require("XUi/XUiSuperSmashBros/Main/Grids/XUiSSBMainEntranceGrid")
        local modes = XDataCenter.SuperSmashBrosManager.GetAllModes()
        for priority, mode in pairs(modes) do
            local entranceGo = CS.UnityEngine.Object.Instantiate(Panel.GridEntrance, Panel.Transform)
            Entrances[priority] = entranceScript.New(entranceGo, mode)
            Entrances[priority]:Show()
        end
    end
end
--=================
--初始化
--=================
function XUiSSBMainPanelEntrance.Init(ui)
    Panel = XTool.InitUiObjectByUi(Panel, ui.PanelEntrance)
    InitEntrances()
end
--=================
--显示时
--=================
function XUiSSBMainPanelEntrance.OnEnable()
    for _, entrance in pairs(Entrances) do
        entrance:OnEnable()
    end
end
--=================
--隐藏时
--=================
function XUiSSBMainPanelEntrance.OnDisable()
    for _, entrance in pairs(Entrances) do
        entrance:OnDisable()
    end
end
--=================
--销毁时
--=================
function XUiSSBMainPanelEntrance.OnDestroy()
    for _, entrance in pairs(Entrances) do
        entrance:OnDestroy()
    end
    Panel = {}
    Entrances = {}
end

return XUiSSBMainPanelEntrance