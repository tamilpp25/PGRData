local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiLinkCraftActivityBattleRoomDetailProxy = XClass(XUiBattleRoomRoleDetailDefaultProxy,'XUiKotodamaActivityBattleRoomDetailProxy')

---战双工艺的编队限制为:LinkCraftActivity表配置的机器人及关联的角色（玩家拥有的话）
function XUiLinkCraftActivityBattleRoomDetailProxy:GetEntities()
    local owner = {}
    local robotList = XMVCA.XLinkCraftActivity:GetRobotListById(XMVCA.XLinkCraftActivity:GetCurActivityId())
    if not XTool.IsTableEmpty(robotList) then
        for i, v in ipairs(robotList) do
            local robot=XRobotManager.GetRobotById(v)
            table.insert(owner,1,robot)
            local ownCharacter =  XMVCA.XCharacter:GetCharacter(robot.CharacterId)

            if ownCharacter and not table.contains(owner, ownCharacter) then
                table.insert(owner, ownCharacter)
            end
        end
    end
    return owner
end

return XUiLinkCraftActivityBattleRoomDetailProxy