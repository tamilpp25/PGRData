---@class XDlcRoom XDlcRoomAgency的代理类(需继承并重写内部方法)
local XDlcRoom = XClass(nil, "XDlcRoom")
local XDlcTeam = require("XModule/XDlcRoom/XEntity/XDlcTeam")

function XDlcRoom:Ctor()
    ---@type XDlcTeam
    self._Team = nil
    self._FightCharacterId = 0
    self._CurrentTutorialRoomLevelId = 0
end

--region Get/Set

function XDlcRoom:SetTeamByRoomData(roomData)
    if self._Team then
        self._Team:SetDataWithRoomData(roomData)
    else
        self._Team = XDlcTeam.New(roomData)
    end
end

function XDlcRoom:GetTeam()
    return self._Team
end

function XDlcRoom:GetName()
    if XMVCA.XDlcRoom:IsInRoom() then
        local worldId = XMVCA.XDlcRoom:GetRoomData():GetWorldId()

        return XMVCA.XDlcWorld:GetWorldNameById(worldId)
    end

    return ""
end

function XDlcRoom:GetFightCharacterId()
    return self._FightCharacterId
end

function XDlcRoom:SetFightCharacterId(characterId)
    self._FightCharacterId = characterId
end

function XDlcRoom:GetTutorialNpcId()
    
end

function XDlcRoom:GetTutorialLevelId()
    return self._CurrentTutorialRoomLevelId
end

function XDlcRoom:SetTutorialLevelId(levelId)
    self._CurrentTutorialRoomLevelId = levelId
end

--endregion

function XDlcRoom:ClearRoomChatMessage()
    XDataCenter.ChatManager.ResetRoomChat()
end

--region 打开UI

function XDlcRoom:OpenMultiplayerRoom()
    XLuaUiManager.Open("UiDlcCasualplayerRoomCute")
end

function XDlcRoom:PopThenOpenMultiplayerRoom()
    XLuaUiManager.PopThenOpen("UiDlcCasualplayerRoomCute")
end

function XDlcRoom:OpenFightUiLoading()
    XLuaUiManager.Open("UiLoading")
end

function XDlcRoom:CloseFightUiLoading()
    XLuaUiManager.Close("UiLoading")
end

--endregion

--region 触发方法(当XDlcRoomAgency调用同名函数时)

function XDlcRoom:OnDisconnect()
    XLuaUiManager.Open("UiDlcSettleLose")
end

function XDlcRoom:OnTutorialFightFinish()
    XLuaUiManager.Open("UiDlcSettleLose")
end

function XDlcRoom:OnFightExit()

end

function XDlcRoom:OnRoomLeaderTimeOut()
    
end

function XDlcRoom:OnKickOut(code)
    
end

function XDlcRoom:OnCreateRoom()
    
end

function XDlcRoom:OnRebuildRoom()
    
end

function XDlcRoom:OnReadyEnterWorld()
    
end

function XDlcRoom:OnEnterWorld()
    
end

--endregion

--region 其他
--如果需要更换请求协议，操作如下：
--    1.重写下面IsNeedChangeProtocol方法，让其返回true
---   2.在XDlcRoom的子类中实现XDlcRoomAgency同名方法(详情请参阅XDlcRoomAgency协议方法————ReqXXX)
function XDlcRoom:IsNeedChangeProtocol()
    return false
end

--endregion

return XDlcRoom
