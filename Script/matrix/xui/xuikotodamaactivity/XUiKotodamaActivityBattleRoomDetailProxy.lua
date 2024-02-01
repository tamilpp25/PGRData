local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiKotodamaActivityBattleRoomDetailProxy=XClass(XUiBattleRoomRoleDetailDefaultProxy,'XUiKotodamaActivityBattleRoomDetailProxy')

function XUiKotodamaActivityBattleRoomDetailProxy:GetEntities()
    local owner=XMVCA.XCharacter:GetOwnCharacterList()
    local ownerfilt={}
    local characterList,robotList=XMVCA.XKotodamaActivity:GetCharacterIdsByStageId(XMVCA.XKotodamaActivity:GetCurStageId())
    characterList=characterList or {}
    robotList=robotList or {}
    for i, v in pairs(robotList) do
        if XTool.IsNumberValid(v) then
            local robot=XRobotManager.GetRobotById(v)
            if robot then
                table.insert(ownerfilt,robot)
            end
        end
    end
    for i, v in pairs(owner or {}) do
        if table.contains(characterList,v.Id) then
            table.insert(ownerfilt,v)
        end
    end
    
    return ownerfilt
end

return XUiKotodamaActivityBattleRoomDetailProxy