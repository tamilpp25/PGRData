--==============
--战斗准备界面敌方面板
--==============
---@class XUiSSBReadyPanelEnemy
local XUiSSBReadyPanelEnemy = XClass(nil, "XUiSSBReadyPanelEnemy")

function XUiSSBReadyPanelEnemy:Ctor(uiPrefab, mode)
    self.Mode = mode
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitGrids()
end

function XUiSSBReadyPanelEnemy:InitGrids()
    if not self.Mode then return end
    self.Grids = {}
    self.TeamData = {}
    local GridScript = require("XUi/XUiSuperSmashBros/Ready/Grids/XUiSSBReadyEnemyGrid")
    local maxPosition = self.Mode:GetTeamMaxPosition() --我方队伍位置数
    for num = 1, maxPosition do
        local grid = CS.UnityEngine.Object.Instantiate(self.GridEnemy, self.Transform)
        self.Grids[num] = GridScript.New(grid, self.Mode)
        self.Grids[num]:SetOrder(num)
        self.Grids[num].GameObject:SetActiveEx(false)
    end
    --最后把模板隐藏
    self.GridEnemy.gameObject:SetActiveEx(false)
end

function XUiSSBReadyPanelEnemy:Refresh(playAnim)
    local isStart = self.Mode:CheckIsStart()
    local enemyTeam = self.Mode:GetEnemyTeam()
    local battleIndex = self.Mode:GetBattleEnemyIndex()
    local battleNum = self.Mode:GetMonsterBattleNum()
    local teamMaxPosition = self.Mode:GetTeamMaxPosition()
    local isLine = self.Mode:GetIsLinearStage()
    if playAnim then XLuaUiManager.SetMask(true) end
    for index = 1, teamMaxPosition do
        local monsterGroup = XDataCenter.SuperSmashBrosManager.GetMonsterGroupById(enemyTeam and enemyTeam[index])
        if monsterGroup then
            if isLine then
                local isWin = (not isStart) and ((self.Mode:GetLastWin() ~= 0) and (not self.Mode:GetLastWin())) and ((battleIndex + battleNum) > index)
                self.Grids[index]:HidePanelHp()
                self.Grids[index]:SetReady(not isWin and ((battleIndex + battleNum) > index))
                self.Grids[index]:SetOut((not isStart) and not isWin)
                local teamWin = (not isStart) and ((self.Mode:GetLastWin() ~= 0) and (not self.Mode:GetLastWin())) and ((battleIndex + battleNum) > index)
                self.Grids[index]:SetWin(teamWin)
                self.Grids[index]:SetNextEnemy(self.Mode:GetNextEnemy())
            else
                local isOut = monsterGroup:GetHpLeft() == 0
                self.Grids[index]:SetReady(not isOut and ((battleIndex + battleNum) > index))
                self.Grids[index]:SetOut(isOut)
                self.Grids[index]:SetWin((not isStart) and ((self.Mode:GetLastWin() ~= 0) and (not self.Mode:GetLastWin())) and ((battleIndex + battleNum) > index))
            end
            
            self.Grids[index]:Refresh(monsterGroup)
        else
            self.Grids[index]:SetBan()
        end
        if playAnim then
            if index == 1 then
                self.Grids[index]:ShowPanel()
                self.Grids[index]:PlayAnimation()
            else
                XScheduleManager.ScheduleOnce(function()
                        self.Grids[index]:ShowPanel()
                        self.Grids[index]:PlayAnimation()
                        if index == teamMaxPosition then
                            XScheduleManager.ScheduleOnce(function()
                                    XLuaUiManager.SetMask(false)
                                end, 500
                            )
                        end
                    end, 300 * index)
            end
        else
            self.Grids[index]:ShowPanel()
        end
    end
end

function XUiSSBReadyPanelEnemy:PlaySwitchAnima(cb)
    self.Grids[1]:PlaySwitchAnima(cb)
end

function XUiSSBReadyPanelEnemy:OnEnterFight()
    local battleIndex = self.Mode:GetBattleEnemyIndex()
    local battleNum = self.Mode:GetMonsterBattleNum()
    local teamMaxPosition = self.Mode:GetTeamMaxPosition()
    for index = 1, teamMaxPosition do
        if (index < battleIndex) or (index > (battleIndex + battleNum - 1)) then
            self.Grids[index]:PlayDisableAnimation()
        end
    end
end

return XUiSSBReadyPanelEnemy