local type = type
local pairs = pairs
local tableInsert = table.insert

local Default = {
    _StageId = 0,       --关卡ID
    _MapId = 0,         --地图ID
    _SelectRoleId = 0   --选用角色
}

--当前进入的关卡数据
local XRpgMakerGameEnterStageDb = XClass(nil, "XRpgMakerGameEnterStageDb")

function XRpgMakerGameEnterStageDb:Ctor(day)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XRpgMakerGameEnterStageDb:UpdateData(data)
    self._StageId = data.StageId
    self._MapId = data.MapId
    self._SelectRoleId = data.SelectRoleId
end

function XRpgMakerGameEnterStageDb:GetStageId()
    return self._StageId
end

function XRpgMakerGameEnterStageDb:GetMapId()
    return self._MapId
end

function XRpgMakerGameEnterStageDb:GetSelectRoleId()
    return self._SelectRoleId
end

return XRpgMakerGameEnterStageDb