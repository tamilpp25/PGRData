--==============
--战斗准备界面我方面板
--==============
---@class XUiSSBReadyPanelOwn
local XUiSSBReadyPanelOwn = XClass(nil, "XUiSSBReadyPanelOwn")

function XUiSSBReadyPanelOwn:Ctor(uiPrefab, mode)
    self.Mode = mode
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitGrids()
end

function XUiSSBReadyPanelOwn:InitGrids()
    if not self.Mode then return end
    self.Grids = {}
    self.TeamData = {}
    local GridScript = require("XUi/XUiSuperSmashBros/Ready/Grids/XUiSSBReadyOwnGrid")
    local maxPosition = self.Mode:GetTeamMaxPosition() --我方队伍位置数
    local pickNum = self.Mode:GetRoleMaxPosition() --我方可最多选的角色数目
    local teamData = XDataCenter.SuperSmashBrosManager.GetTeamByModeId(self.Mode:GetId())
    for num = 1, maxPosition do
        local grid = CS.UnityEngine.Object.Instantiate(self.GridOwn, self.Transform)
        self.Grids[num] = GridScript.New(grid, self.Mode)
        if teamData.Assistance[num] then
            self.Grids[num]:SetAssistance()
        else
            self.Grids[num]:SetOrder(num)
        end
        if num > pickNum then --若超出我方可选最多角色数目，禁用位置
            self.Grids[num]:SetBan()
            self.TeamData[num] = XSuperSmashBrosConfig.PosState.Ban
        end
        self.Grids[num]:HidePanel()
    end
    --最后把模板隐藏
    self.GridOwn.gameObject:SetActiveEx(false)
end

function XUiSSBReadyPanelOwn:Refresh(playAnim, record, recordIndex)
    local isStart = self.Mode:CheckIsStart()
    local ownTeam = self.Mode:GetBattleTeam()
    local battleIndex = self.Mode:GetBattleCharaIndex() -- 第一个存活的构造体在队伍中的顺序下标
    local ownBattleNum = self.Mode:GetRoleBattleNum()   -- 每次出阵人数
    local teamMaxPosition = self.Mode:GetTeamMaxPosition()
    local forceRandomIndex = self.Mode:GetRoleRandomStartIndex() --我方强制随机的开始下标
    if playAnim then XLuaUiManager.SetMask(true) end
    for index = 1, teamMaxPosition do
        local chara = XDataCenter.SuperSmashBrosManager.GetRoleById(ownTeam and ownTeam[index])
        if chara then
            local isEggChara = chara:IsSmashEggRobot()
            local isOut = chara:GetHpLeft() == 0
            local isReady = self.Mode:IsCanReady() and (not isOut) and ((battleIndex + ownBattleNum) > index)
            local isUnknown = forceRandomIndex and index >= forceRandomIndex and (battleIndex + ownBattleNum) <= index

            -- 彩蛋开启条件
            if (battleIndex + ownBattleNum) > index and isEggChara then
                chara:SetOpenEgg() 
                self.Grids[index]:SetOpenEgg()
            end

            self.Grids[index]:Refresh(chara, record, recordIndex)
            self.Grids[index]:SetReady(isReady)

            --强制随机未知模式设为问号，揭开才显示角色（死亡随机模式） cxldV2 
            self.Grids[index]:SetUnknown(isUnknown)
            chara:SetUnknown(isUnknown)

            self.Grids[index]:SetOut(isOut)
            self.Grids[index]:SetWin((not isStart) and (self.Mode:GetLastWin() == true) and ((battleIndex + ownBattleNum) > index))
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

function XUiSSBReadyPanelOwn:OnEnterFight()
    local battleIndex = self.Mode:GetBattleCharaIndex()
    local ownBattleNum = self.Mode:GetRoleBattleNum()
    local teamMaxPosition = self.Mode:GetTeamMaxPosition()
    for index = 1, teamMaxPosition do
        if (index < battleIndex) or (index > (battleIndex + ownBattleNum - 1)) then
            self.Grids[index]:PlayDisableAnimation()
        end
    end
end

return XUiSSBReadyPanelOwn