---@class XDlcSettingDetail
local XDlcSettingDetail = XClass(nil, "XDlcSettingDetail")

function XDlcSettingDetail:Ctor(id, tipName, tipDesc, tipAsset)
    self._Id = id
    self._TipName = tipName
    self._TipDesc = tipDesc
    self._TipAsset = tipAsset
end

function XDlcSettingDetail:GetId()
    return self._Id
end

function XDlcSettingDetail:GetTipName()
    return self._TipName
end

function XDlcSettingDetail:GetTipDesc()
    return self._TipDesc
end

function XDlcSettingDetail:GetTipAsset()
    return self._TipAsset
end

function XDlcSettingDetail:IsEmpty()
    return self._Id == nil
end 

---@param other XDlcSettingDetail
function XDlcSettingDetail:Equals(other)
    if other == nil then
        return false
    end 
    if self:IsEmpty() and other:IsEmpty() then
        return true
    end
    if self:IsEmpty() or other:IsEmpty() then
        return false
    end

    return self:GetId() == other:GetId()
end

return XDlcSettingDetail