local XUiGridPokemonMonster = require("XUi/XUiPokemon/XUiMonster/XUiGridPokemonMonster")
local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")

local ipairs = ipairs
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiPanelSettleWinPokemon = XClass(nil, "XUiPanelSettleWinPokemon")

function XUiPanelSettleWinPokemon:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MonsterGrids = {}

    XTool.InitUiObject(self)

    self.GridMonster.gameObject:SetActiveEx(false)
end

function XUiPanelSettleWinPokemon:Refresh(data)
    self.Data = data

    self:UpdateMonsters()
    self:UpdatePlayerInfo()
end

function XUiPanelSettleWinPokemon:UpdateMonsters()
    local monsterCount = 0

    local monsterIds = XDataCenter.PokemonManager.GetTeamMonsterIds()
    for _, monsterId in ipairs(monsterIds) do

        if monsterId > 0 then
            monsterCount = monsterCount + 1

            local grid = self.MonsterGrids[monsterCount]
            if not grid then
                local ui = CSUnityEngineObjectInstantiate(self.GridMonster, self.PanelMonsterContent)
                grid = XUiGridPokemonMonster.New(ui)
                self.MonsterGrids[monsterCount] = grid
            end

            grid:Refresh(monsterId)
            grid.GameObject:SetActiveEx(true)

        end

    end

    for index = monsterCount + 1, #self.MonsterGrids do
        local grid = self.MonsterGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

end

-- 玩家经验
function XUiPanelSettleWinPokemon:UpdatePlayerInfo()
    local data = self.Data
    if XTool.IsTableEmpty(data) then return end

    local lastLevel = data.RoleLevel
    local lastExp = data.RoleExp
    local lastMaxExp = XPlayerManager.GetMaxExp(lastLevel, XPlayer.IsHonorLevelOpen())
    local curLevel = XPlayer.GetLevelOrHonorLevel()
    local curExp = XPlayer.Exp
    local curMaxExp = XPlayerManager.GetMaxExp(curLevel, XPlayer.IsHonorLevelOpen())
    local txtLevelName = XPlayer.IsHonorLevelOpen() and CS.XTextManager.GetText("HonorLevel") or nil
    local addExp = XDataCenter.FubenManager.GetTeamExp(data.StageId)
    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp, addExp, txtLevelName)
end

return XUiPanelSettleWinPokemon