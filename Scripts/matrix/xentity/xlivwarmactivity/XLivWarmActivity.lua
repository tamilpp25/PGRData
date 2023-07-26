local XLivWarmActivityStageDb = require("XEntity/XLivWarmActivity/XLivWarmActivityStageDb")

local type = type

local XLivWarmActivity = XClass(nil, "XLivWarmActivity")

local DefaultMain = {
    _ActivityId = 0,
    _StageDbs = {}
}

function XLivWarmActivity:Ctor()
    for key, value in pairs(DefaultMain) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XLivWarmActivity:UpdateData(data)
    self._ActivityId = data.ActivityId

    self._StageDbs = {}
    for _, stageDb in ipairs(data.StageDbs) do
        local stageDbEntity = XLivWarmActivityStageDb.New()
        stageDbEntity:UpdateData(stageDb)
        self._StageDbs[stageDb.StageId] = stageDbEntity
    end
end

function XLivWarmActivity:UpdateStageDb(stageId, data)
    local stageDb = self:GetStageDb(stageId)
    stageDb:UpdateData(data)
end

function XLivWarmActivity:GetStageDb(stageId)
    if not self._StageDbs[stageId] then
        self._StageDbs[stageId] = XLivWarmActivityStageDb.New()
    end
    return self._StageDbs[stageId]
end

return XLivWarmActivity