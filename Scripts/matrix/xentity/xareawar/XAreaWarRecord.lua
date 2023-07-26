local type = type
local pairs = pairs
local tableInsert = table.insert

--[[    
public class XAreaWarPopupRecord
{
    //弹窗净化等级
    public int PurificationLv;

    //弹窗已净化区块ID
    public List<int> CleanBlockIds = new List<int>();

    //弹窗已解锁特攻角色
    public List<int> SpecialRole = new List<int>();
}
]]
local Default = {
    _PurificationLv = 0, --净化等级
    _ClearedBlockIdDic = {}, --已净化区块Id
    _UnlockedSpecialRoleIdDic = {} --已解锁特工角色Id
}

local XAreaWarRecord = XClass(nil, "XAreaWarRecord")

function XAreaWarRecord:Ctor()
    self:Clear()
end

function XAreaWarRecord:UpdateData(data)
    if not data then
        return
    end

    self._PurificationLv = data.PurificationLv or self._PurificationLv

    self._ClearedBlockIdDic = {}
    for _, blockId in pairs(data.CleanBlockIds or {}) do
        self:RecordBlockId(blockId)
    end

    self._UnlockedSpecialRoleIdDic = {}
    for _, roleId in pairs(data.SpecialRole or {}) do
        self:RecordRoleId(roleId)
    end
end

function XAreaWarRecord:Clear()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XAreaWarRecord:CheckRoleIdExist(roleId)
    return self._UnlockedSpecialRoleIdDic[roleId] and true or false
end

function XAreaWarRecord:RecordRoleId(roleId)
    if not XTool.IsNumberValid(roleId) then
        return
    end
    self._UnlockedSpecialRoleIdDic[roleId] = roleId
end

function XAreaWarRecord:GetSpecialRoleIds()
    local roleIds = {}
    for roleId in pairs(self._UnlockedSpecialRoleIdDic) do
        tableInsert(roleIds, roleId)
    end
    return roleIds
end

function XAreaWarRecord:CheckblockIdExist(blockId)
    return self._ClearedBlockIdDic[blockId] and true or false
end

function XAreaWarRecord:RecordBlockId(blockId)
    if not XTool.IsNumberValid(blockId) then
        return
    end
    self._ClearedBlockIdDic[blockId] = blockId
end

function XAreaWarRecord:GetBlockIdDic()
    return self._ClearedBlockIdDic
end

function XAreaWarRecord:GetClearBlockCount()
    local count = 0
    for _, _ in pairs(self._ClearedBlockIdDic) do
        count = count + 1
    end
    return count
end

function XAreaWarRecord:GetUnlockSpecialRoleCount()
    local count = 0
    for _, _ in pairs(self._UnlockedSpecialRoleIdDic) do
        count = count + 1
    end
    return count
end

function XAreaWarRecord:GetPurificationLevel()
    return self._PurificationLv
end

function XAreaWarRecord:CheckPurificationLvExist(level)
    if not XTool.IsNumberValid(level) then
        return false
    end
    return self._PurificationLv == level
end

function XAreaWarRecord:RecordPurificationLv(level)
    if not XTool.IsNumberValid(level) then
        return
    end
    self._PurificationLv = level
end

return XAreaWarRecord
