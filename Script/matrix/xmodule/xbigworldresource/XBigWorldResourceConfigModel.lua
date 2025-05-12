---@class XBigWorldResourceConfigModel : XModel
local XBigWorldResourceConfigModel = XClass(XModel, "XBigWorldResourceConfigModel")

local DlcResourceTableKey = {
    BigWorldUiEffect = { ReadFunc = XConfigUtil.ReadType.String, DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, },
    BigWorldUiModel = { ReadFunc = XConfigUtil.ReadType.String, DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal, },
    BigWorldAssetUrl = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Name",
                         CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.String}
}

function XBigWorldResourceConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Resource", DlcResourceTableKey)
end

---@return XTableBigWorldUiEffect[]
function XBigWorldResourceConfigModel:GetDlcUiEffectConfigs()
    return self._ConfigUtil:GetByTableKey(DlcResourceTableKey.BigWorldUiEffect) or {}
end

---@return XTableBigWorldUiEffect
function XBigWorldResourceConfigModel:GetDlcUiEffectConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcResourceTableKey.BigWorldUiEffect, id, false) or {}
end

function XBigWorldResourceConfigModel:GetDlcUiEffectEffectUrlById(id)
    local config = self:GetDlcUiEffectConfigById(id)

    return config.EffectUrl
end

---@return XTableBigWorldUiModel[]
function XBigWorldResourceConfigModel:GetDlcUiModelConfigs()
    return self._ConfigUtil:GetByTableKey(DlcResourceTableKey.BigWorldUiModel) or {}
end

---@return XTableBigWorldUiModel
function XBigWorldResourceConfigModel:GetDlcUiModelConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcResourceTableKey.BigWorldUiModel, id, false) or {}
end

---@return XTableBigWorldAssetUrl
function XBigWorldResourceConfigModel:GetAssetUrlTemplate(name)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcResourceTableKey.BigWorldAssetUrl, name)
end

function XBigWorldResourceConfigModel:GetDlcModelId(id)
    local config = self:GetDlcUiModelConfigById(id)

    return config.ModelId
end

function XBigWorldResourceConfigModel:GetDlcUiDefaultAnimationName(id)
    local config = self:GetDlcUiModelConfigById(id)

    return config.DefaultAnimationName
end

function XBigWorldResourceConfigModel:GetDlcUiDisplayControllerPath(id)
    local config = self:GetDlcUiModelConfigById(id)

    return config.DisplayControllerPath
end

return XBigWorldResourceConfigModel