--==============================--
-- 字符串相关扩展方法
--==============================--
local tonumber = tonumber
local next = next
local pairs = pairs
local string = string
local table = table
local math = math

local stringLen = string.len
local stringByte = string.byte
local stringSub = string.sub
local stringGsub = string.gsub
local stringFind = string.find
local stringMatch = string.match
local tableInsert = table.insert
local mathFloor = math.floor

--==============================--
--desc: 通过utf8获取字符串长度
--@str: 字符串
--@return 字符串长度
--==============================--
function string.Utf8Len(str)
    local len = stringLen(str)
    local left = len
    local cnt = 0
    local arr = { 0, 192, 224, 240, 248, 252 }
    while left ~= 0 do
        local tmp = stringByte(str, -left)
        local i = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

--==============================--
--desc: 通过utf8获取单个字符大小
--@str: 单个字符
--@return 字符大小(字节为单位)
--==============================--
function string.Utf8Size(char)
    if not char then
        return 0
    elseif char >= 252 then
        return 6
    elseif char >= 248 then
        return 5
    elseif char >= 240 then
        return 4
    elseif char >= 225 then
        return 3
    elseif char >= 192 then
        return 2
    else
        return 1
    end
end

--==============================--
--desc: 按utf8长度截取字符串
--@str: 字符串
--@return 字符串
--==============================--
function string.Utf8Sub(str, startChar, numChars)
    local startIndex = 1
    while startChar > 1 do
        local char = stringByte(str, startIndex)
        startIndex = startIndex + string.Utf8Size(char)
        startChar = startChar - 1
    end

    local currentIndex = startIndex
    while numChars > 0 and currentIndex <= #str do
        local char = stringByte(str, currentIndex)
        currentIndex = currentIndex + string.Utf8Size(char)
        numChars = numChars - 1
    end
    return str:sub(startIndex, currentIndex - 1)
end

--==============================--
--desc: 通过utf8并且以(中文为2,其余为1)的方式获取字符串长度
--@str: 字符串(中文为2,其余为1)
--@return 字符串长度
--==============================--
function string.Utf8LenCustom(str)
    local len = stringLen(str)
    local left = len
    local cnt = 0
    local arr = { 0, 192, 224, 240, 248, 252 }
    while left ~= 0 do
        local tmp = stringByte(str, -left)
        local i = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        if tmp >= 228 and tmp <= 233 then
            cnt = cnt + 2
        else
            cnt = cnt + 1
        end
    end
    return cnt
end

--==============================--
--desc: 通过utf8以(中文为2,其余为1)的方式获取单个字符长度
--@str: 单个字符
--@return 字符长度
--==============================--
function string.Utf8CharLenCustom(char)
    if not char then
        return 0
    elseif char >= 228 and char <= 233 then
        return 2
    else
        return 1
    end
end

--==============================--
--desc: 按utf8长度并且以(中文为2,其余为1)的方式截取字符串
--@str: 字符串(中文为2)
--@return 字符串
--==============================--
function string.Utf8SubCustom(str, startChar, numChars)
    local startIndex = 1
    while startChar > 1 do
        local char = stringByte(str, startIndex)
        startIndex = startIndex + string.Utf8Size(char)
        startChar = startChar - string.Utf8CharLenCustom(char)
    end

    local currentIndex = startIndex
    while numChars > 0 and currentIndex <= #str do
        local char = stringByte(str, currentIndex)
        currentIndex = currentIndex + string.Utf8Size(char)
        numChars = numChars - string.Utf8CharLenCustom(char)
    end
    return str:sub(startIndex, currentIndex - 1)
end

--==============================--
--desc: 将字符串分割成char table
--@str: 字符串
--@return char table
--==============================--
function string.SplitWordsToCharTab(str)
    local len = stringLen(str)
    local left = len
    local chartab = {}
    local arr = { 0, 192, 224, 240, 248, 252 }
    while left ~= 0 do
        local tmp = stringByte(str, -left)
        local i = #arr
        local value = left

        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end

        local char = stringSub(str, -value, -left - 1)
        if stringSub(str, -left, -left + 1) == "\\n" then
            left = left - 2
            char = char .. "\n"
        end
        tableInsert(chartab, char)
    end
    return chartab
end

--==============================--
--desc: 把有富文本格式的字符串变成char table
--@str: 富文本字符串
--@return char table
--==============================--
function string.CharsConvertToCharTab(str)
    --str = "我只是用来{<color=#00ffffff><size=40>测一测</size></color>}别xiabibi{<size=25><color=#ff0000ff>红色试一试</color></size>}试玩啦"--
    local leftindexs = {}
    local rightindexs = {}
    local startpos = 1
    while true do
        local pos = stringFind(str, "{", startpos)

        if not pos then
            break
        end

        tableInsert(leftindexs, pos)
        pos = stringFind(str, "}", pos + 1)
        if not pos then
            break
        end

        tableInsert(rightindexs, pos)
        startpos = pos + 1
    end

    local words = {}
    if #leftindexs > 0 then
        startpos = 1
        for i = 1, #leftindexs do
            tableInsert(words, stringSub(str, startpos, leftindexs[i] - 1))
            tableInsert(words, stringSub(str, leftindexs[i] + 1, rightindexs[i] - 1))
            startpos = rightindexs[i] + 1
        end

        if rightindexs[#rightindexs] ~= stringLen(str) then
            tableInsert(words, stringSub(str, startpos))
        end
    else
        tableInsert(words, str)
    end

    local result = {}
    for i = 1, #words do
        local tab
        local IsRichText
        local format

        if stringSub(words[i], 1, 1) == "<" then
            IsRichText = true
            local pa = stringMatch(words[i], "%b></")
            pa = stringMatch(pa, ">(.*)<")
            format = stringGsub(words[i], "%b></", ">#$#</", 1)
            tab = string.SplitWordsToCharTab(pa)
        else
            IsRichText = false
            format = ""
            tab = string.SplitWordsToCharTab(words[i])
        end

        for j = 1, #tab do
            if IsRichText then
                local char = stringGsub(format, "#$#", tab[j])
                tableInsert(result, char)
            else
                tableInsert(result, tab[j])
            end
        end
    end
    return result
end

--==============================--
--desc: 检查字符串的开头是否与指定字符串匹配
--@str: 需要检查的字符串
--@value: 指定的字符串
--@return true：匹配，false：不匹配
--==============================--
function string.StartsWith(str, value)
    return stringSub(str, 1, stringLen(value)) == value
end

--==============================--
--desc: 检查字符串的结尾是否与指定字符串匹配
--@str: 需要检查的字符串
--@value: 指定的字符串
--@return true：匹配，false：不匹配
--==============================--
function string.EndsWith(str, value)
    return value == "" or stringSub(str, -stringLen(value)) == value
end

--==============================--
--desc: 字符串分割
--@str: 原字符串
--@separator: 分割符
--@return 字符串数组
--==============================--
function string.Split(str, separator)
    if str == nil or str == "" then
        return {}
    end

    if not separator then
        separator = "|"
    end

    local result = {}
    local startPos = 1
    while true do
        local endPos = str:find(separator, startPos)
        if endPos == nil then
            break
        end

        local elem = str:sub(startPos, endPos - 1)
        tableInsert(result, elem)
        startPos = endPos + #separator
    end

    tableInsert(result, str:sub(startPos))
    return result
end

--==============================--
--desc: 将字符串分割成int数组
--@str: 原字符串
--@separator: 分割符
--@return int数组
--==============================--
function string.ToIntArray(str, separator)
    local strs = string.Split(str, separator)
    local array = {}
    if next(strs) then
        for _, v in pairs(strs) do
            tableInsert(array, mathFloor(tonumber(v)))
        end
    end
    return array
end

--==============================--
--desc: 从一个字符串中查找另一个字符串的第一次匹配的索引
--@str: 原字符串
--@separator: 需要匹配的字符串
--@return 索引号
--==============================--
function string.IndexOf(str, separator)
    if not str or str == "" or not separator or separator == "" then
        return -1
    end
    for i = 1, #str do
        local success = true
        for s = 1, #separator do
            local strChar = stringByte(str, i + s - 1)
            local sepChar = stringByte(separator, s)
            if strChar ~= sepChar then
                success = false
                break
            end
        end
        if success then
            return i
        end
    end
    return -1
end

--==============================--
--desc: 从一个字符串中查找另一个字符串的最后一次匹配的索引
--@str: 原字符串
--@separator: 需要匹配的字符串
--@return 索引号
--==============================--
function string.LastIndexOf(str, separator)
    if not str or str == "" or not separator or separator == "" then
        return -1
    end
    local strLen = #str
    local sepLen = #separator
    for i = 0, strLen - 1 do
        local success = true
        for s = 0, sepLen - 1 do
            local strChar = stringByte(str, strLen - i - s)
            local sepChar = stringByte(separator, sepLen - s)
            if strChar ~= sepChar then
                success = false
                break
            end
        end
        if success then
            return strLen - i - sepLen + 1
        end
    end
    return -1
end

--==============================--
--desc: 判断字符串是否为nil或者为空
--@str: 字符串对象
--@return 如果为nil或者为空，返回true，否则返回fale
--==============================--
function string.IsNilOrEmpty(str)
    return str == nil or #str == 0
end

--==============================--
--desc: 过滤utf文本特殊屏蔽字干扰字符
--@str: 字符串对象
--@return 过滤后文本
--==============================--
local FilterSymbols = [[·~！@#￥%……&*（）-=——+【】｛｝、|；‘’：“”，。、《》？[]{}""'';:./?,<>\|-_=+*()!@#$%^&*~` ]]
local FilterSymbolsTable = FilterSymbols:SplitWordsToCharTab()
function string.FilterWords(str)
    local result = ""
    for i = 1, string.Utf8Len(str) do
        local nowStr = string.Utf8Sub(str, i, 1)
        local isValid = true
        for _, v in pairs(FilterSymbolsTable) do
            if nowStr == v then
                isValid = false
                break
            end
        end
        if isValid then
            result = result .. nowStr
        end
    end

    return result
end

--==============================--
--desc: 字符串每隔X个字符插入 需要的字符串
--@str: 字符串对象
--@interval: 间隔多少个字符
--@insertStr: 插入的字符串
--@return 过滤后文本
--==============================--
function string.InsertStr(str, interval, insertStr)
    local index = 1
    local worldCount = 0
    local result = ""

    while true do
        local world = stringSub(str, index, index)
        local byte = stringByte(world)

        if byte > 128 then
            world = stringSub(str, index, index + 2)
            index = index + 3
        else
            index = index + 1
        end

        result = result .. world
        worldCount = worldCount + 1
        if worldCount >= interval then
            result = result .. insertStr
            worldCount = 0
        end

        if index > #str then
            break
        end
    end

    return result
end

--判断字符串是否为合法IP"[0-255].[0-255].[0-255].[0-255]"
function string.IsIp(ip)
    if string.IsNilOrEmpty(ip) then return false end
    local valueSet = table.pack(string.find(ip, "(%d+)%.(%d+)%.(%d+)%.(%d+)"))
    local pureIpStr = table.concat(valueSet, '.', 3, 6)

    if not valueSet[1] then return false end

    local ipNum
    for i = 3, 6 do
        ipNum = tonumber(valueSet[i])
        if not ipNum or ipNum < 0 or ipNum > 255 then
            return false
        end
    end

    return true, pureIpStr
end

-- 判断一个字符串是不是纯数字
function string.IsNumeric(inputString)
    local isNumeric = string.match(inputString, "^%d+$")
    if isNumeric then
        return true
    else
        return false
    end
end

-- 判断一个字符串是不是一个浮点数
function string.IsFloatNumber(inputString)
    local isNumeric = string.match(inputString, "^-?%d+%.?%d*$")
    if isNumeric then
        return true
    else
        return false
    end
end

local function pchar_to_char(str)
    return string.char(tonumber(str, 16))
end

local function char_to_pchar(c)
    return string.format("%%%02X", c:byte(1,1))
end

function string.decodeURIComponent(str)
    return (str:gsub("%%(%x%x)", pchar_to_char))
end

function string.encodeURIComponent(str)
    return (str:gsub("[^%w%-_%.%!%~%*%'%(%)]", char_to_pchar))
end

-- 格式化字符串用table替换 参数
function string.ConcatWithPlaceholdersWithTable(str, args)
    return string.gsub(str, "{(%d+)}", function(index)
        local i = tonumber(index)
        return args[i + 1] or ""
    end)
end

-- 格式化字符串
function string.ConcatWithPlaceholders(str, ...)
    local args = {...}
    return string.ConcatWithPlaceholdersWithTable(str, args)
end
