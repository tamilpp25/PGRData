local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiSpecialTrainBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiSpecialTrainBattleRoomRoleDetail")

function XUiSpecialTrainBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
end

function XUiSpecialTrainBattleRoomRoleDetail:GetEntities(characterType)
    return XDataCenter.FubenSpecialTrainManager.GetCanFightRoles(self.StageId, characterType)
end

-- return : bool 是否开启自动关闭检查, number 自动关闭的时间戳(秒), function 每秒更新的回调 function(isClose) isClose标志是否到达结束时间
function XUiSpecialTrainBattleRoomRoleDetail:GetAutoCloseInfo()
    return true, XDataCenter.FubenSpecialTrainManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.FubenSpecialTrainManager.HandleActivityEndTime()
        end
    end
end

function XUiSpecialTrainBattleRoomRoleDetail:AOPSetJoinBtnIsActiveAfter(rootUi)
    -- 卸下队伍
    rootUi.BtnQuitTeam.gameObject:SetActiveEx(false)
    -- 教学按钮
    rootUi.BtnTeaching.gameObject:SetActiveEx(false)
end

function XUiSpecialTrainBattleRoomRoleDetail:AOPCloseBefore(rootUi)
    local charIdMap = rootUi.Team:GetEntityIds()
    if not XDataCenter.RoomManager.RoomData then
        -- 被踢出房间不回调
        return
    end

    XDataCenter.RoomManager.EndSelectRequest()
    if not charIdMap then
        return
    end
    local charId = charIdMap[1]
    XDataCenter.RoomManager.Select(charId, function(code)
        if code ~= XCode.Success then
            XUiManager.TipCode(code)
            return
        end
        XUiManager.TipText("OnlineFightSuccess", XUiManager.UiTipType.Success)
    end)
end

return XUiSpecialTrainBattleRoomRoleDetail