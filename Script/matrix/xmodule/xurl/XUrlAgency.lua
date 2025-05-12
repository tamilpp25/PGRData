---@class XUrlAgency : XAgency
---@field private _Model XUrlModel
local XUrlAgency = XClass(XAgency, "XUrlAgency")

local PcEmbedTypeMap = {
    [1] = true, -- 内置浏览器
    [2] = false, -- 外部浏览器
}

local ParamsInsert = '{%%%%params%%%%}' -- %正则匹配有含义，表转义，实际对应字符串：{%%params%%}

function XUrlAgency:OnInit()
    self._ParamGetter = {
        ["sojumpparm"] = function(urlCfg)
            return self:GetSojumpParm()
        end,
        ["parmsign"] = function(urlCfg)
            local qid = self._Model:GetUrlExtendParams(urlCfg.Id, 'qid')
            return self:GetParmSign(qid or '')
        end,
        ["token"] = function(urlCfg)
            return XHeroSdkManager.GetAccessToken()
        end,
        ["server_id"] = function(urlCfg)
            return XUserManager.ServerId
        end,
        ["cuid"] = function(urlCfg)
            return XUserManager.UserId
        end,
        ["cname"] = function(urlCfg)
            return string.encodeURIComponent(XUserManager.UserName)
        end,
    }
end

function XUrlAgency:SkipByUrlId(id)
    local cfg = self._Model:GetUrlConfigById(id)
    
    if not cfg then
        XLog.Error("UrlConfig 表缺乏配置, id:" .. tostring(id))
        return false
    end
    
    local url = self:GetFullUrlById(id)
    
    -- 设置浏览器类型
    local isEmbed = nil
    -- 如果是PC平台并且有配置，则使用PC平台的配置
    if XDataCenter.UiPcManager.IsPc() then
        if XTool.IsNumberValid(cfg.PcEmbedType) then
            isEmbed = PcEmbedTypeMap[cfg.PcEmbedType]
        end
    elseif XUserManager.Platform == XUserManager.PLATFORM.IOS then
        -- 如果是IOS平台且有配置，则使用IOS平台的配置
        if XTool.IsNumberValid(cfg.IOSEmbedType) then
            isEmbed = PcEmbedTypeMap[cfg.IOSEmbedType]
        end
    end
    -- 否则按照原有配置
    if isEmbed == nil then
        isEmbed = cfg.IsEmbed
    end
    
    if isEmbed then
        --如果IsPcLandscape == true, 则在pc上强制横屏, 否则无论什么平台都读取IsLandscape字段(true横屏, false竖屏)
        local isLandscape = XDataCenter.UiPcManager.IsPc() and cfg.IsPcLandscape or cfg.IsLandscape
        XHeroSdkManager.OpenWebview(url, cfg.Title or "", cfg.IsTransparent, isLandscape)
    else
        CS.UnityEngine.Application.OpenURL(url)
    end
    
    return true
end

function XUrlAgency:GetFullUrlById(id)
    local cfg = self._Model:GetUrlConfigById(id)

    if not cfg then
        XLog.Error("UrlConfig 表缺乏配置, id:" .. tostring(id))
        return
    end
    
    local url = self:GetUrlBaseWithCurrentPlatform(cfg)

    local stringBuilder = {}
    
    local beginIndex = string.find(url, ParamsInsert)
    
    local hasParamsInsert = XTool.IsNumberValid(beginIndex)

    if hasParamsInsert then
        table.insert(stringBuilder, '?')
    else
        table.insert(stringBuilder, url)
        table.insert(stringBuilder, '?')
    end
    
    -- 判断是否有额外参数
    if not XTool.IsTableEmpty(cfg.UrlParams) then
        for i, v in ipairs(cfg.UrlParams) do
            -- 如果参数已经包含了key和value，则无需再获取
            if string.match(v, '[%w_]+=[%w_]+') then
                table.insert(stringBuilder, v)
            else
                local getter_func = self._ParamGetter[v]

                if getter_func then
                    table.insert(stringBuilder, v..'='..getter_func(cfg))
                else
                    XLog.Error('无效的参数，没有对应的参数获取接口，检查参数是否填写错误:',v)
                    goto CONTINUE
                end
            end

            -- 插入分隔符
            table.insert(stringBuilder, '&')

            :: CONTINUE ::
        end

        -- 移除最后一个分隔符
        if stringBuilder[#stringBuilder] == '&' then
            stringBuilder[#stringBuilder] = nil
        end
        
        local concatStr = table.concat(stringBuilder)

        if hasParamsInsert then
            return string.gsub(url, ParamsInsert, concatStr)
        else
            return concatStr
        end
    else
        if hasParamsInsert then
            XLog.Error('外链存在参数插值: {%%params%%}， 但没有配置对应的配置')
        end
        
        return cfg.Url
    end
end

--- 根据当前平台获取对应的外链路径
---@param config XTableUrlConfig
function XUrlAgency:GetUrlBaseWithCurrentPlatform(config)
    local url = ''

    if XUserManager.Platform == XUserManager.PLATFORM.IOS and not string.IsNilOrEmpty(config.UrlIOS) then
        url = config.UrlIOS
    elseif XDataCenter.UiPcManager.IsPc() and not string.IsNilOrEmpty(config.UrlPC) then
        url = config.UrlPC    
    end

    if string.IsNilOrEmpty(url) then
        url = config.Url
    end
    
    return url
end


--- 获取问卷星问卷参数sojumpparm
function XUrlAgency:GetSojumpParm()
    return XPlayer.Id..';'..XPlayer.ServerId
end

--- 获取问卷星问卷参数parmSign
---@param qid @问卷的id
function XUrlAgency:GetParmSign(qid)
    local key = qid..self:GetSojumpParm()..'34d7eca5-96e9-46d8-b475-e687d9ef9a0d'
    return CS.XTool.ToSHA1(key)
end

return XUrlAgency