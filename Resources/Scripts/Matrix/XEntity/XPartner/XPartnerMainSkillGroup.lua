local XPartnerSkillGroupBase = require("XEntity/XPartner/XPartnerSkillGroupBase")
local XPartnerMainSkillGroup = XClass(XPartnerSkillGroupBase, "XPartnerMainSkillGroup")
local DefaultIndex = 1

function XPartnerMainSkillGroup:Ctor(id, IsDefaultSkillGroup, IsPreview)
    self.Id = id
    self.Level = 1
    
    if IsPreview then
        self.IsCarry = IsDefaultSkillGroup
        self.IsLock = not IsDefaultSkillGroup
    else
        self.IsCarry = false
        self.IsLock = true
    end
    
    self:SetDefaultActiveSkillId()
    self.LevelLimit = XPartnerConfigs.GetPartnerSkillLevelLimit(self.ActiveSkillId)
end

function XPartnerMainSkillGroup:UpdateData(data)
    for key, value in pairs(data) do
        self[key] = value
    end
end

function XPartnerMainSkillGroup:GetSkillType()
    return XPartnerConfigs.SkillType.MainSkill
end

function XPartnerMainSkillGroup:SetDefaultActiveSkillId()
    self.ActiveSkillId = self:GetSkillIdList()[DefaultIndex]
end

function XPartnerMainSkillGroup:GetCfg()
    return XPartnerConfigs.GetPartnerMainSkillGroupById(self.Id)
end

function XPartnerMainSkillGroup:GetConditionId()
    return self:GetCfg().ConditionId
end

function XPartnerMainSkillGroup:GetSkillIdList()
    return self:GetCfg().SkillId
end

function XPartnerMainSkillGroup:GetElementList()
    return self:GetCfg().Element
end

-- return : XPartnerMainSkillGroup list
function XPartnerMainSkillGroup:GetSelfElementSkillS()
    local result = {}
    for _, element in ipairs(self:GetElementList()) do
        local skill = XPartnerMainSkillGroup.New(self:GetId())
        local initData = {
            Level = self:GetLevel(),
            IsLock = self:GetIsLock(),
            ActiveSkillId = self:GetSkillIdByElement(element),
            Type = XPartnerConfigs.SkillType.MainSkill,
        }
        skill:UpdateData(initData)
        table.insert(result, skill)
    end
    return result
end

function XPartnerMainSkillGroup:GetConditionDesc()
    local desc = ""
    if self:GetConditionId() ~= 0 then
        desc = XConditionManager.GetConditionDescById(self:GetConditionId())
    end
    return desc
end

function XPartnerMainSkillGroup:GetActiveElement()
    return self:GetElementBySkillId(self.ActiveSkillId)
end

function XPartnerMainSkillGroup:GetSkillIdByElement(activeElement)
    for index,element in pairs(self:GetElementList() or {}) do
        if element == activeElement then
            if self:GetSkillIdList()[index] then
                return  self:GetSkillIdList()[index]
            else
                XLog.Error("elementSkill is not exist by element :" .. activeElement)
                return  self:GetSkillIdList()[DefaultIndex]
            end
        end
    end
    XLog.Error("element is not exist by element :" .. activeElement)
    return self:GetSkillIdList()[DefaultIndex]
end

function XPartnerMainSkillGroup:GetSkillIdByElementIndex(index)
    return self:GetSkillIdList()[index] or self:GetSkillIdList()[DefaultIndex]
end

function XPartnerMainSkillGroup:GetElementBySkillId(skillId)
    for index,element in pairs(self:GetElementList() or {}) do
        if self:GetSkillIdList()[index] == skillId then
            return element
        end
    end
    XLog.Error("element is Null or  skillId is not exist")
    return XPartnerConfigs.SkillElement.Physics
end

function XPartnerMainSkillGroup:GetElementIndexBySkillId(skillId)
    for index,_ in pairs(self:GetElementList() or {}) do
        if self:GetSkillIdList()[index] == skillId then
            return index
        end
    end
    XLog.Error("element is Null or  skillId is not exist")
    return DefaultIndex
end

return XPartnerMainSkillGroup