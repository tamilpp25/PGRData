---@class XRiftAttributeTemplate 战双大秘境队伍加点
local XRiftAttributeTemplate = XClass(nil, "RiftAttributeTemplate")

function XRiftAttributeTemplate:Ctor(id, attrList, name)
    self.Id = id
    self.AttrList = attrList or {}
    self.CustomName = name

    if attrList == nil then
        for id = 1, XEnumConst.Rift.AttrCnt do
            self:SetAttrLevel(id, 0)
        end
    end
end

function XRiftAttributeTemplate:SetName(name)
    self.CustomName = name
end

function XRiftAttributeTemplate:GetName()
    return self.CustomName
end

function XRiftAttributeTemplate:GetAttrLevel(attrId)
    if self.AttrList[attrId] then
        return self.AttrList[attrId].Level
    else
        return 0
    end
end

function XRiftAttributeTemplate:SetAttrLevel(attrId, level)
    self.AttrList[attrId] = { Id = attrId, Level = level}
end

function XRiftAttributeTemplate:GetAllLevel()
    local allLevel = 0
    for _, attr in ipairs(self.AttrList) do
        allLevel = allLevel + attr.Level
    end
    return allLevel
end

function XRiftAttributeTemplate:GetAbility()

end

-- 是否是空模板
function XRiftAttributeTemplate:IsEmpty()
    return self.Id ~= XEnumConst.Rift.DefaultAttrTemplateId and self:GetAllLevel() == 0
end

---@param data XRiftAttributeTemplate
function XRiftAttributeTemplate:Copy(data)
    for attrId = 1, 4 do
        self:SetAttrLevel(attrId, data:GetAttrLevel(attrId))
    end
end

return XRiftAttributeTemplate