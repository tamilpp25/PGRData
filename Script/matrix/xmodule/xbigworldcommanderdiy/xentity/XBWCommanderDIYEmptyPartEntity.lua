local XBWCommanderDIYPartEntity = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYPartEntity")

---@class XBWCommanderDIYEmptyPartEntity : XBWCommanderDIYPartEntity
local XBWCommanderDIYEmptyPartEntity = XClass(XBWCommanderDIYPartEntity, "XBWCommanderDIYEmptyPartEntity")

function XBWCommanderDIYEmptyPartEntity:Ctor()
    self._TypeId = 0
end

function XBWCommanderDIYEmptyPartEntity:IsTemporary()
    return true
end

function XBWCommanderDIYEmptyPartEntity:SetTypeId(typeId)
    self._TypeId = typeId
end

function XBWCommanderDIYEmptyPartEntity:GetTypeId()
    return self._TypeId
end

function XBWCommanderDIYEmptyPartEntity:GetName()
    return XMVCA.XBigWorldService:GetText("DIYUnRequiredPartName")
end

function XBWCommanderDIYEmptyPartEntity:GetColorEntitys()
    return {}
end

return XBWCommanderDIYEmptyPartEntity