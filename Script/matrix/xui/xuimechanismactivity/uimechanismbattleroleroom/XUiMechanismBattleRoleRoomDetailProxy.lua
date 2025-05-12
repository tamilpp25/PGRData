local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiMechanismBattleRoomDetailProxy = XClass(XUiBattleRoomRoleDetailDefaultProxy,'XUiMechanismBattleRoomDetailProxy')

function XUiMechanismBattleRoomDetailProxy:GetEntities()
    local chapterId = XMVCA.XMechanismActivity:GetMechanismCurChapterId()

    if XTool.IsNumberValid(chapterId) then
        local mechaismCharacterCfgs = XMVCA.XMechanismActivity:GetMechanismCharacterCfgsByChapterId(chapterId)
        if not XTool.IsTableEmpty(mechaismCharacterCfgs) then
            local characterList = {}
            -- 获取自机、机器人列表
            ---@param v XTableMechanismCharacter
            for i, v in ipairs(mechaismCharacterCfgs) do
                if XMVCA.XCharacter:IsOwnCharacter(v.CharacterId) then
                    table.insert(characterList, XMVCA.XCharacter:GetCharacter(v.CharacterId))
                end
                if XRobotManager.CheckIsRobotId(v.RobotId) then
                    table.insert(characterList, XRobotManager.GetRobotById(v.RobotId))
                end
            end
            
            return characterList
        end
    end
    return {}
end

return XUiMechanismBattleRoomDetailProxy