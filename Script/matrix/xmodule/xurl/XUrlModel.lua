---@class XUrlModel : XModel
local XUrlModel = XClass(XModel, "XUrlModel")

local TableMap = {
    UrlConfig = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = 'Id', ReadFunc = XConfigUtil.ReadType.Int },
}

function XUrlModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey('UrlSkip', TableMap, XConfigUtil.CacheType.Normal)
end

function XUrlModel:ClearPrivate()

end

function XUrlModel:ResetAll()
    self._UrlExtendParams = nil
end

---@param self XUrlModel
---@param cfg XTableUrlConfig
local InitExtendParamsById = function(self, cfg)
    if cfg and not XTool.IsTableEmpty(cfg.ExtendParams) then
        if self._UrlExtendParams == nil then
            self._UrlExtendParams = {}
        end

        if self._UrlExtendParams[cfg.Id] == nil then
            self._UrlExtendParams[cfg.Id] = {}

            for i, param in pairs(cfg.ExtendParams) do
                -- 把参数以‘=’划分，左边为key，右边为value
                local strs = string.Split(param, '=')
                if #strs >=2 then
                    self._UrlExtendParams[cfg.Id][strs[1]] = strs[2]
                end
            end
        end
    end
end


---@return XTableUrlConfig
function XUrlModel:GetUrlConfigById(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableMap.UrlConfig)

    if not XTool.IsTableEmpty(cfgs) then
        InitExtendParamsById(self, cfgs[id])
        return cfgs[id]
    end
end

function XUrlModel:GetUrlExtendParams(urlId, key)
    -- 如果为空则尝试触发一次初始化
    if XTool.IsTableEmpty(self._UrlExtendParams) or XTool.IsTableEmpty(self._UrlExtendParams[urlId]) then
        self:GetUrlConfigById(urlId)
    end

    if not XTool.IsTableEmpty(self._UrlExtendParams) and not XTool.IsTableEmpty(self._UrlExtendParams[urlId]) then
        return self._UrlExtendParams[urlId][key]
    end
end



return XUrlModel