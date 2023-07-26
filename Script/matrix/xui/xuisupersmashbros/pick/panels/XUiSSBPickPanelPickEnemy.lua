
local XUiSSBPickPanelPickEnemy = {}

local GridScript = require("XUi/XUiSuperSmashBros/Pick/Grids/XUiSSBPickGridPickEnemy")

local Panel = {}

local Grids = {}

local TeamData = {}

local Mode

local RootPanel

function XUiSSBPickPanelPickEnemy.Init(panel)
    XTool.InitUiObjectByUi(Panel, panel.PanelPickEnemy)
    Mode = panel.Mode
    RootPanel = panel
    XUiSSBPickPanelPickEnemy.InitGrids()
end

function XUiSSBPickPanelPickEnemy.InitGrids()
    if not Mode then return end
    local isLine = Mode:GetIsLinearStage()
    local maxPosition = Mode:GetTeamMaxPosition() --敌人队伍位置数
    local pickNum = Mode:GetMonsterMaxPosition() --敌人可最多选的角色数目
    local battleNum = Mode:GetMonsterBattleNum() --敌人每场出击数
    local randomNum = Mode:GetMonsterRandomNum() --敌人随机位置
    XLuaUiManager.SetMask(true)
    for num = 1, maxPosition do
        local grid = CS.UnityEngine.Object.Instantiate(Panel.GridPickEnemy, Panel.Transform)
        grid.name = "GridPickEnemy" .. num --命名用于引导
        Grids[num] = GridScript.New(grid, num, RootPanel, TeamData, Grids)
        if num > pickNum then --若超出敌人可选最多角色数目，禁用位置
            Grids[num]:SetBan()
            TeamData[num] = XSuperSmashBrosConfig.PosState.Ban
        elseif num <= randomNum then
            if isLine then
                local monsterGroups = XDataCenter.SuperSmashBrosManager.GetMonsterGroupListByModeId(Mode:GetId())
                local firstMonster = monsterGroups[1]
                Grids[num]:SetSelected(firstMonster)
                Grids[num]:SetLock()
                TeamData[num] = firstMonster:GetId()
            else
                Grids[num]:SetOnlyRandom()
                TeamData[num] = XSuperSmashBrosConfig.PosState.OnlyRandom
            end
        else
            Grids[num]:SetRandom()
            TeamData[num] = XSuperSmashBrosConfig.PosState.Random
        end
        Grids[num].GameObject:SetActiveEx(false)
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
    Panel.GridPickEnemy.gameObject:SetActiveEx(false)
end

function XUiSSBPickPanelPickEnemy.GetTeam()
    return TeamData
end

function XUiSSBPickPanelPickEnemy.OnEnable()
    XUiSSBPickPanelPickEnemy.Refresh()
end

function XUiSSBPickPanelPickEnemy.Refresh()
    for index, data in pairs(TeamData) do
        Grids[index]:Refresh(data)
    end
end

function XUiSSBPickPanelPickEnemy.OnDisable()

end

function XUiSSBPickPanelPickEnemy.OnDestroy()
    Panel = {}
    Grids = {}
    TeamData = {}
    RootPanel = nil
    Mode = nil
end

return XUiSSBPickPanelPickEnemy