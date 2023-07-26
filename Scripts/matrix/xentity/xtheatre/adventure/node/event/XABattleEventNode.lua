local XAEventNode = require("XEntity/XTheatre/Adventure/Node/Event/XAEventNode")
local XABattleEventNode = XClass(XAEventNode, "XABattleEventNode")

function XABattleEventNode:Ctor()
    
end

function XABattleEventNode:RequestTriggerNode(callback, optionIndex)
    XLuaUiManager.Open("UiBattleRoleRoom"
        , self.EventConfig.StageId
        , XDataCenter.TheatreManager.GetCurrentAdventureManager():GetSingleTeam()
        , require("XUi/XUiTheatre/XUiTheatreBattleRoleRoom"))
end

-- function XABattleEventNode:EnterFight(index)
--     if index == nil then index = 1 end
--     XDataCenter.TheatreManager.GetCurrentAdventureManager()
--         :EnterFight(self.EventConfig.StageId, index)
-- end

return XABattleEventNode