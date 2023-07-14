local XUiGridPokemonMonster = require("XUi/XUiPokemon/XUiMonster/XUiGridPokemonMonster")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiPokemonMonsterObtain = XLuaUiManager.Register(XLuaUi, "UiPokemonMonsterObtain")

function XUiPokemonMonsterObtain:OnAwake()
    self:AutoAddListener()

    self.GridMonster.gameObject:SetActiveEx(false)
end

function XUiPokemonMonsterObtain:OnStart(monsterIds)
    self.MonsterIds = monsterIds
    self.MonsterGrids = {}
end

function XUiPokemonMonsterObtain:OnEnable()
    self:UpdateMonsters()
end

function XUiPokemonMonsterObtain:UpdateMonsters()
    local monsterIds = self.MonsterIds

    for index = 1, #monsterIds do
        local grid = self.MonsterGrids[index]
        if not grid then
            local go = index == 1 and self.GridMonster or CSUnityEngineObjectInstantiate(self.GridMonster, self.PanelContent)
            grid = XUiGridPokemonMonster.New(go)
        end

        local monsterId = monsterIds[index]
        grid:Refresh(monsterId)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiPokemonMonsterObtain:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
end

function XUiPokemonMonsterObtain:OnClickBtnBack()
    self:Close()
end