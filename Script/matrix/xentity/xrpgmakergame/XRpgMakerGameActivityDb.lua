local XRpgMakerActivityStageDb = require("XEntity/XRpgMakerGame/XRpgMakerActivityStageDb")

local type = type
local pairs = pairs
local tableInsert = table.insert

local Default = {
    _StageDbs = {},         --所有已通关的关卡数据
    _UnlockRoleId = {},     --已解锁的角色id列表
}

--活动数据
local XRpgMakerGameActivityDb = XClass(nil, "XRpgMakerGameActivityDb")

function XRpgMakerGameActivityDb:Ctor(day)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XRpgMakerGameActivityDb:UpdateData(data)
    self._StageDbs = {}
    local stageDb
    for i, v in ipairs(data.StageDbs) do
        stageDb = XRpgMakerActivityStageDb.New()
        stageDb:UpdateData(v)
        tableInsert(self._StageDbs, stageDb)
    end
    self._UnlockRoleId = data.UnlockRoleId
end

function XRpgMakerGameActivityDb:UpdateStageDb(data)
    local stageDb = XRpgMakerActivityStageDb.New()
    stageDb:UpdateData(data)
    tableInsert(self._StageDbs, stageDb)
end

function XRpgMakerGameActivityDb:UpdateUnlockRoleId(unlockRoleId)
    for _, roleId in ipairs(self._UnlockRoleId) do
        if roleId == unlockRoleId then
            return
        end
    end
    tableInsert(self._UnlockRoleId, unlockRoleId)
end

function XRpgMakerGameActivityDb:GetUnlockRoleIdList()
    return self._UnlockRoleId
end

function XRpgMakerGameActivityDb:GetStageDb(stageCfgId)
    for _, stageDb in ipairs(self._StageDbs) do
        if stageDb:GetStageCfgId() == stageCfgId then
            return stageDb
        end
    end

    local stageDb = XRpgMakerActivityStageDb.New(stageCfgId)
    tableInsert(self._StageDbs, stageDb)
    return stageDb
end

return XRpgMakerGameActivityDb