---@class XBigWorldResourceAgency : XAgency
---@field private _Model XBigWorldResourceModel
local XBigWorldResourceAgency = XClass(XAgency, "XBigWorldResourceAgency")

function XBigWorldResourceAgency:OnInit()
    self._DefaultUiAnimaName = false
end

function XBigWorldResourceAgency:InitRpc()
end

function XBigWorldResourceAgency:InitEvent()
end

--region Config

--region UiModel

function XBigWorldResourceAgency:GetDlcModelId(uiModelId)
    if string.IsNilOrEmpty(uiModelId) then
        return ""
    end

    return self._Model:GetDlcModelId(uiModelId) or ""
end

function XBigWorldResourceAgency:GetDlcUiDefaultAnimationName(uiModelId)
    local name = self._Model:GetDlcUiDefaultAnimationName(uiModelId)
    if name then
        return name
    end
    return self:GetUiDefaultAnimaName()
end

function XBigWorldResourceAgency:GetUiDefaultAnimaName()
    if self._DefaultUiAnimaName then
        return self._DefaultUiAnimaName
    end

    self._DefaultUiAnimaName = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetString("UiDefaultAnimationName")

    return self._DefaultUiAnimaName
end

function XBigWorldResourceAgency:GetModelControllerUrl(uiModelId)
    local controllerUrl = self._Model:GetDlcUiDisplayControllerPath(uiModelId)
    
    if string.IsNilOrEmpty(controllerUrl) then
        local modelId = self:GetDlcModelId(uiModelId)
        
        controllerUrl = self:GetModelControllerUrlByModelId(modelId)
    end

    return controllerUrl or ""
end

function XBigWorldResourceAgency:GetModelUrl(uiModelId)
    local modelId = self:GetDlcModelId(uiModelId)

    return self:GetModelUrlByModelId(modelId) or ""
end

--endregion

-- region UiEffect

function XBigWorldResourceAgency:GetEffectUrl(id)
    return self._Model:GetDlcUiEffectEffectUrlById(id) or ""
end

-- endregion

--region Model

function XBigWorldResourceAgency:GetModelUrlByModelId(id)
    if string.IsNilOrEmpty(id) then
        return ""
    end

    return CS.StatusSyncFight.XResourceLutManager.GetModelUrl(id)
end

function XBigWorldResourceAgency:GetModelControllerUrlByModelId(id)
    if string.IsNilOrEmpty(id) then
        return ""
    end

    return CS.StatusSyncFight.XResourceLutManager.GetControllerUrl(id)
end

function XBigWorldResourceAgency:GetPartModelUrlByPartId(partId)
    if string.IsNilOrEmpty(partId) then
        return ""
    end

    return CS.StatusSyncFight.XResourceLutManager.GetRolePartModelUrl(partId)
end

function XBigWorldResourceAgency:GetPartModelMaterials(partId, colorName)
    return CS.StatusSyncFight.XResourceLutManager.GetRolePartMaterialTabList(partId, colorName)
end

--endregion

function XBigWorldResourceAgency:GetAssetUrl(name)
    local template = self._Model:GetAssetUrlTemplate(name)
    return template and template.Url or ""
end

--endregion

return XBigWorldResourceAgency
