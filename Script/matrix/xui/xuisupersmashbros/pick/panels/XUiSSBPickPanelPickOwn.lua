--===============
--
--===============
local XUiSSBPickPanelPickOwn = {}

local GridScript = require("XUi/XUiSuperSmashBros/Pick/Grids/XUiSSBPickGridPickOwn")

local Panel = {}

local Grids = {}

local RootPanel

local Mode

function XUiSSBPickPanelPickOwn.Init(panel)
    XTool.InitUiObjectByUi(Panel, panel.PanelPickOwn)
    Mode = panel.Mode
    RootPanel = panel
    XUiSSBPickPanelPickOwn.InitGrids()
end

function XUiSSBPickPanelPickOwn.InitGrids()
    if not Mode then return end
    local maxPosition = Mode:GetTeamMaxPosition() --我方队伍位置数
    local pickNum = Mode:GetRoleMaxPosition() --我方可最多选的角色数目
    local forceRandomIndex = Mode:GetRoleRandomStartIndex()--我方可强制随机的开始下标
    local defaultTeam = XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(Mode:GetId())
    XLuaUiManager.SetMask(true)
    for num = 1, maxPosition do
        local grid = CS.UnityEngine.Object.Instantiate(Panel.GridPickOwn, Panel.Transform)
        grid.name = "GridPickOwn" .. num --命名用于引导
        Grids[num] = GridScript.New(grid, num, RootPanel, Grids)
        Grids[num].GameObject:SetActiveEx(false)
        Grids[num]:SetColor(XSuperSmashBrosConfig.ColorTypeIndex[defaultTeam.Color[num]])
        if forceRandomIndex and num >= forceRandomIndex then --强制随机不可编辑
            Grids[num]:SetOnlyRandom(true)
            defaultTeam.RoleIds[num] = XSuperSmashBrosConfig.PosState.OnlyRandom --强制设为随机
        end

        if num == 1 then
            Grids[num].GameObject:SetActiveEx(true)
            Grids[num]:PlayEnableAnim()
        else
            XScheduleManager.ScheduleOnce(function()
                    Grids[num].GameObject:SetActiveEx(true)
                    Grids[num]:PlayEnableAnim()
                    if num == maxPosition then
                        XLuaUiManager.SetMask(false)
                    end
                end, 300 * num)
        end
    end
    --最后把模板隐藏
    Panel.GridPickOwn.gameObject:SetActiveEx(false)
end

function XUiSSBPickPanelPickOwn.GetTeam()
    return XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(Mode:GetId())
end

function XUiSSBPickPanelPickOwn.OnEnable()
    XUiSSBPickPanelPickOwn.Refresh()
end

function XUiSSBPickPanelPickOwn.Refresh()
    local teamData = XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(Mode:GetId())
    for index, grid in pairs(Grids) do 
        grid:Refresh(teamData)
    end
end

function XUiSSBPickPanelPickOwn.OnDisable()
    
end

function XUiSSBPickPanelPickOwn.OnDestroy()
    Panel = {}
    Grids = {}
    RootPanel = nil
    Mode = nil
end

return XUiSSBPickPanelPickOwn