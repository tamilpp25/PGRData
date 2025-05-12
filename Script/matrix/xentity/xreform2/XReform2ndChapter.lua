---@class XReform2ndChapter
local XReform2ndChapter = XClass(nil, "XReform2ndChapter")

function XReform2ndChapter:Ctor(id)
    self.Id = id
end

function XReform2ndChapter:GetId()
    return self.Id
end

function XReform2ndChapter:SetId(id)
    self.Id = id
end

---@param model XReformModel
function XReform2ndChapter:GetStageList(model)
    local stageIds = model:GetChapterStageIdById(self:GetId())
    return stageIds
end

---@param model XReformModel
function XReform2ndChapter:IsHasStageHard(model)
    local stageList = self:GetStageList(model)
    return #stageList > 1
end

---@param model XReformModel
function XReform2ndChapter:IsShowToggleHard(model)
    if not self:IsHasStageHard(model) then
        return false
    end

    --if model:IsChapterUnlocked(self) then
    --    return true
    --end
    if model:IsUnlockStageHard() then
        return true
    end

    return false
end

---@param model XReformModel
function XReform2ndChapter:GetStageByDifficulty(model, isHard)
    ---@type XReform2ndStage[]
    local stageList = self:GetStageList(model)
    if isHard then
        for i = 1, #stageList do
            local stageId = stageList[i]
            local stage = model:GetStage(stageId)
            if stage:IsHardStage(model) then
                return stage
            end
        end
    else
        for i = 1, #stageList do
            local stageId = stageList[i]
            local stage = model:GetStage(stageId)
            if not stage:IsHardStage(model) then
                return stage
            end
        end
    end
end

return XReform2ndChapter
