---@class XSubPackageControl : XControl
---@field private _Model XSubPackageModel
local XSubPackageControl = XClass(XControl, "XSubPackageControl")
function XSubPackageControl:OnInit()
    
end

function XSubPackageControl:AddAgencyEvent()

end

function XSubPackageControl:RemoveAgencyEvent()

end

function XSubPackageControl:OnRelease()
end

--region   ------------------Group start-------------------

function XSubPackageControl:GetGroupIdList()
    return self._Model:GetGroupIdList()
end

function XSubPackageControl:GetGroupName(groupId)
    local template = self._Model:GetGroupTemplate(groupId)
    return template and template.Name or "???"
end

function XSubPackageControl:GetGroupNameEn(groupId)
    local template = self._Model:GetGroupTemplate(groupId)
    return template and template.NameEn or "???"
end

function XSubPackageControl:GetSubpackageIds(groupId)
    local template = self._Model:GetGroupTemplate(groupId)
    return template and template.SubPackageId or {}
end
--endregion------------------Group finish------------------

--region   ------------------SubPackage start-------------------

function XSubPackageControl:GetSubPackageName(subpackageId)
    return self._Model:GetSubPackageName(subpackageId)
end

function XSubPackageControl:GetSubPackageDesc(subpackageId)
    local template = self._Model:GetSubpackageTemplate(subpackageId)
    return template and template.Desc or "???"
end

function XSubPackageControl:GetSubPackageBanner(subpackageId)
    local template = self._Model:GetSubpackageTemplate(subpackageId)
    return template and template.Banner or ""
end

function XSubPackageControl:GetSubpackageIndex(subpackageId)
    return self._Model:GetSubpackageIndex(subpackageId)
end

---@return XSubpackage
function XSubPackageControl:GetSubpackageItem(subpackageId)
    return self._Model:GetSubpackageItem(subpackageId)
end

function XSubPackageControl:GetNecessarySubIds()
    return self._Model:GetNecessarySubIds()
end

--endregion------------------SubPackage finish------------------



return XSubPackageControl