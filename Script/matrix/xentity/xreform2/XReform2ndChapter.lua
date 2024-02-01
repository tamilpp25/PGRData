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

return XReform2ndChapter
