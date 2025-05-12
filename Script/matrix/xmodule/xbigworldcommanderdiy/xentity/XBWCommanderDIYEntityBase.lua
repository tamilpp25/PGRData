---@class XBWCommanderDIYEntityBase : XEntity
---@field _Model XBigWorldCommanderDIYModel
---@field _OwnControl XBigWorldCommanderDIYControl
local XBWCommanderDIYEntityBase = XClass(XEntity, "XBWCommanderDIYEntityBase")

function XBWCommanderDIYEntityBase:OnInit(...)
    self:SetData(...)
end

function XBWCommanderDIYEntityBase:SetData(...)
    
end

function XBWCommanderDIYEntityBase:IsExist()
    return self._OwnControl ~= nil and self._Model ~= nil
end

function XBWCommanderDIYEntityBase:IsEmpty()
    return false
end

function XBWCommanderDIYEntityBase:IsNil()
    return self:IsEmpty() or not self:IsExist()
end

function XBWCommanderDIYEntityBase:OnRelease()
    
end

return XBWCommanderDIYEntityBase