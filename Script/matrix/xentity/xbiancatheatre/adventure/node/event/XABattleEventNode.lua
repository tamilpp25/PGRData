local XAEventNode = require("XEntity/XBiancaTheatre/Adventure/Node/Event/XAEventNode")
local XABattleEventNode = XClass(XAEventNode, "XABattleEventNode")

function XABattleEventNode:Ctor()
    
end

function XABattleEventNode:InitWithServerData(data)
    self.Super.InitWithServerData(self, data)
    self.EventClientConfig = XBiancaTheatreConfigs.GetTheatreEventClientConfig(data.EventId)
end

function XABattleEventNode:RequestTriggerNode(callback, optionIndex)
    XLuaUiManager.Open("UiBattleRoleRoom"
        , self:GetFightStageId()
        , XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetSingleTeam()
        , require("XUi/XUiBiancaTheatre/XUiBiancaTheatreBattleRoleRoom"))
end

-- function XABattleEventNode:EnterFight(index)
--     if index == nil then index = 1 end
--     XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
--         :EnterFight(self.EventConfig.StageId, index)
-- end

return XABattleEventNode