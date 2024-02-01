---@class XDlcRoom XDlcRoomAgency的代理类(需继承并重写内部方法)
local XDlcRoom = XClass(nil, "XDlcRoom")
local XDlcTeam = require("XModule/XDlcRoom/XEntity/XDlcTeam")

function XDlcRoom:Ctor()
    ---@type XDlcTeam
    self._Team = nil
    self._FightCharacterId = 0
end

--region Get/Set
function XDlcRoom:SetTeamByRoomData(roomData)
    self:SetTeam(XDlcTeam.New(roomData))
end

---@param team XDlcTeam
function XDlcRoom:SetTeam(team)
    self._Team = team
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

function XDlcRoom:GetTutorialNpcId()
    
end

function XDlcRoom:SetFightCharacterId(characterId)
    self._FightCharacterId = characterId
end

--endregion

--region 打开UI
function XDlcRoom:OpenMultiplayerRoom()
    XLuaUiManager.Open("UiDlcCasualplayerRoomCute")
end

function XDlcRoom:OpenFightLoading()
    XLuaUiManager.Open("UiLoading", LoadingType.Fight)
end

function XDlcRoom:CloseFightLoading()
    XLuaUiManager.SafeClose("UiLoading")
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

function XDlcRoom:OnKickOut()
    
end

function XDlcRoom:OnCreateRoom()
    
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
