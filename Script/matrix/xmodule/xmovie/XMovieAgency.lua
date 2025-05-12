---@class XMovieAgency : XAgency
---@field _Model XMovieModel
local XMovieAgency = XClass(XAgency, "XMovieAgency")

function XMovieAgency:OnInit()
    --初始化一些变量
    self.XEnumConst = {
        -- spine的组成部位名称
        SPINE_PART_NAME = {
            ROLE = "Role",
            BODY = "Body",
            KOU = "Kou",
        },
        -- 剧情跳过类型
        SkipType = {
            OnlyTips = 1, -- 仅跳过提示
            Summary = 2, -- 带剧情梗概
        },
        -- 自动播放辅助点击，key为ActionType，value为时间间隔毫秒
        -- 支持不同的ActionType自定义延迟时间。支持配置节点忽略辅助点击(value不为number类型)
        AUTO_PLAY_CLICK_ACTION = {
            ["DEFAULT"] = 2000, -- 默认间隔时间
            [301] = "Ignore", -- 此节点的对话自己实现了自动播放逻辑，忽略辅助点击
        },
    }
end

function XMovieAgency:InitRpc()
    -- 注册服务器事件
end

function XMovieAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--============================================================== #region 配置表 ==============================================================
-- 获取ClientConfig表配置
function XMovieAgency:GetClientConfig(key, index)
    return self._Model:GetClientConfig(key, index)
end

-- 获取ClientConfig表配置所有参数
function XMovieAgency:GetClientConfigParams(key)
    return self._Model:GetClientConfigParams(key)
end
--============================================================== #endregion 配置表 ==============================================================

--============================================================== #region rpc ==============================================================
-- 请求剧情选项记录
function XMovieAgency:RequestMovieOptions(movieId)
    if not XLoginManager.IsLogin() then
        return
    end

    local isCfgExit = self._Model:IsRecordOptionsConfigExit(movieId)
    if not isCfgExit then
        return
    end

    local req = { MovieId = movieId }
    XNetwork.CallWithAutoHandleErrorCode("QueryMovieOptionsRequest", req, function(res)
        self._Model:UpdateMovieOptions(movieId, res.MovieList)
    end)
end

-- 请求记录剧情选项
function XMovieAgency:RequestRecordOption(movieId, actionId, optionIndex)
    local isNeed = self._Model:IsOptionNeedRecord(movieId, actionId, optionIndex)
    if not isNeed then
        return
    end

    local optionId = self._Model:PackOptionId(actionId, optionIndex)
    local req = { MovieId = movieId, OptionId = optionId }
    XNetwork.CallWithAutoHandleErrorCode("UpdateMovieOptionsRequest", req, function(res)
        self._Model:AddMovieOption(movieId, optionId)
    end)
end

-- 是否选择过选项
function XMovieAgency:IsOptionPassed(movieId, actionId, optionIndex)
    return self._Model:IsOptionPassed(movieId, actionId, optionIndex)
end

--============================================================== #endregion rpc ==============================================================
-- 参数转数字
function XMovieAgency:ParamToNumber(param)
    if param and param ~= "" then
        return tonumber(param)
    else
        return 0
    end
end

-- 切割参数
function XMovieAgency:SplitParam(param, splitStr, isNumber)
    if not param or param == "" then
        return {}
    end
    
    local result = string.Split(param, splitStr)
    if isNumber then
        local cnt = #result
        for i = 1, cnt do
            result[i] = tonumber(result[i])
        end
    end
    return result
end

-- 提取指挥官性别对应文本
function XMovieAgency:ExtractGenderContent(content)
    local gender = XPlayer.GetShowGender()
    if gender == XEnumConst.PLAYER.GENDER_TYPE.MAN then
        local result = string.gsub(content, '<W>.-</W>', '')
        result = string.gsub(result, '<M>', '')
        result = string.gsub(result, '</M>', '')

        return result
    elseif gender == XEnumConst.PLAYER.GENDER_TYPE.WOMAN then
        local result = string.gsub(content, '<M>.-</M>', '')
        result = string.gsub(result, '<W>', '')
        result = string.gsub(result, '</W>', '')
        
        return result
    end
    return content
end

-- 将十进制编码转换成字符串
-- 配置表string和List<string>里的文本只要有英文逗号，加载出来的文本会自动增加英文的双引号
-- 配置示例：配置{226|153|170}，运行时转{226,153,170}
function XMovieAgency:ReplaceDecimalismCodeToStr(content)
    local replaceDic = {}
    for matchStr in string.gmatch(content, "{.-}") do
        if not replaceDic[matchStr] then
            local bytesStr = string.gsub(matchStr, "|", ",")
            local bytes = load("return " .. bytesStr)()
            local str = self:BytesToStr(bytes)
            content = string.gsub(content, matchStr, str)
            replaceDic[matchStr] = true
        end
    end
    return content
end

-- 十进制数组转字符串
function XMovieAgency:BytesToStr(bytes)
    local str = ""
    for i, v in ipairs(bytes) do
        str = str .. string.char(v)
    end
    return str
end

-- 检查需要设置性别
function XMovieAgency:CheckTipsSetGender(movieId)
    -- 已设置性别
    if XPlayer.Gender and  XPlayer.Gender ~= 0 then return false end

    --local movieCfg = XMovieConfigs.GetMovieCfg(movieId)
    XLuaUiManager.Open("UiPlayer")
    XLuaUiManager.Open('UiPlayerPopupSetGender')
    return true
end

return XMovieAgency