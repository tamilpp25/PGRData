local strlen = string.len
local strFormat = string.format
local strFind = string.find
local mathFloor = math.floor
local tableInsert = table.insert
local next = next

local MdediumFontSize = CS.XGame.ClientConfig:GetInt("NoticeMediumFontSize")

local NodeType = {
    Head = 1,
    Tail = 2,
}

local ParagraphType = {
    Pic = 1,
    Text = 2,
}

local FontSizeMap = {
    ["xx-small"] = mathFloor(MdediumFontSize * 0.6),
    ["x-small"] = mathFloor(MdediumFontSize * 0.75),
    ["small"] = mathFloor(MdediumFontSize * 0.89),
    ["medium"] = MdediumFontSize,
    ["large"] = mathFloor(MdediumFontSize * 1.2),
    ["x-large"] = mathFloor(MdediumFontSize * 1.5),
    ["xx-large"] = mathFloor(MdediumFontSize * 2),
}

local FontSizeNumMap = {
    [1] = mathFloor(MdediumFontSize * 0.6),
    [2] = mathFloor(MdediumFontSize * 0.75),
    [3] = mathFloor(MdediumFontSize * 0.89),
    [4] = MdediumFontSize,
    [5] = mathFloor(MdediumFontSize * 1.2),
    [6] = mathFloor(MdediumFontSize * 1.5),
    [7] = mathFloor(MdediumFontSize * 2),
}

local HtmlCharMap = {
    ["&quot;"] = "\"",
    ["&amp;"] = "&",
    ["&lt;"] = "<",
    ["&gt;"] = ">",
    ["&nbsp;"] = " ",
    ["<br>"] = "\n",
}

local AlignMap = {
    ["center"] = CS.UnityEngine.TextAnchor.MiddleCenter,
    ["left"] = CS.UnityEngine.TextAnchor.MiddleLeft,
    ["right"] = CS.UnityEngine.TextAnchor.MiddleRight,
    ["justify"] = CS.UnityEngine.TextAnchor.MiddleLeft,
}


local function FilterSpecialSymbol(content)
    if not content then
        return
    end
    return content:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(symbol)
        return "%" .. symbol
    end)
end

local function RemoveBlank(content)
    if not content then
        return
    end
    return content:gsub("^[ \t\n\r]+", ""):gsub("[ \t\n\r]+$", "")
end

local function RemoveNewLine(content)
    return content:gsub("\n", " ")
end

local function RemoveInvalidChar(content)
    if not content then
        return ""
    end

    return content:gsub("<script.-/script>", ""):gsub("<!%-%-.-%-%->", ""):gsub("<style.-/style>", "")
end

local function GetBody(content)
    local i, _, _, subContent = strFind(content, "<body([^>]-)>(.-)</body>")
    if not i then
        return ""
    end

    return subContent
end

local function GetImg(content)
    local _, _, _, imgType, imgData = strFind(content, "<img (.-)src=\"data:(.-);base64,(.-)\"")
    return imgType, imgData
end

local function ConverRGB2Hex(colorR, colorG, colorB)
    if not colorR or not colorG or not colorB then
        return
    end

    local rStr = strFormat("%x", colorR)
    if strlen(rStr) < 2 then
        rStr = "0" .. rStr
    end

    local gStr = strFormat("%x", colorG)
    if strlen(gStr) < 2 then
        gStr = "0" .. gStr
    end

    local bStr = strFormat("%x", colorB)
    if strlen(bStr) < 2 then
        bStr = "0" .. bStr
    end

    return rStr .. gStr .. bStr
end


local function InitAllTagList(content, tagList)
    local count = 0
    local nextOffset = 0;
    local tempContent = content
    while (true and count < 10000) do
        local i, j, tag, param = strFind(tempContent, "<([^>%s]+)(%s-)(.-)>")
        if tag then
            local nodeType
            if tag:sub(1, 1) == "/" then
                nodeType = NodeType.Tail
                tag = tag:sub(2)
            else
                nodeType = NodeType.Head
            end

            tableInsert(tagList, { NodeType = nodeType, BeginPos = i + nextOffset, EndPos = j + nextOffset, Tag = tag, Param = param })

            if j == #tempContent then
                return
            end

            nextOffset = nextOffset + j
            tempContent = tempContent:sub(j + 1)
        else
            return
        end
        count = count + 1
    end
end

local function Match(tagList, matchedList)
    -- 构建tag匹配关系
    local matchingList = {}
    for _, v in ipairs(tagList) do
        if v.NodeType == NodeType.Head then
            tableInsert(matchingList, v)
        elseif v.NodeType == NodeType.Tail then
            for j = #matchingList, 1, -1 do
                local head = matchingList[j]
                table.remove(matchingList, j)
                if v.Tag == head.Tag then
                    tableInsert(matchedList, { Head = head, Tail = v })
                    break
                end
            end
        end
    end

    table.sort(matchedList, function(l, r)
        return l.Head.BeginPos < r.Head.BeginPos
    end)
end

local CreateChilds
CreateChilds = function(parent, matchedList)
    if not parent then
        return
    end

    local count = 0
    while #matchedList > 0 or count > 10000 do
        local curNode = matchedList[1]
        if parent.Tail.EndPos > curNode.Tail.EndPos then
            parent.Childs = parent.Childs or {}
            table.remove(matchedList, 1)
            tableInsert(parent.Childs, curNode)
            CreateChilds(curNode, matchedList)
        else
            return
        end
        count = count + 1
    end
end

local function CreateTree(matchedList, tagTree)
    local count = 0
    while #matchedList > 0 or count > 10000 do
        local curNode = matchedList[1]
        table.remove(matchedList, 1)
        CreateChilds(curNode, matchedList)
        tableInsert(tagTree, curNode)
        count = count + 1
    end

    return tagTree
end

local function GetNodeStyle(node, content, defaultStyle)
    local style = {}

    local nodeParam = content:sub(node.Head.BeginPos, node.Head.EndPos)
    local tag = FilterSpecialSymbol(node.Head.Tag)
    local _, _, _, paramStr = strFind(nodeParam, "<" .. tag .. "(%s-)(.-)>")

    local findColor = false
    local findSize = false
    if not string.IsNilOrEmpty(paramStr) then
        local _, _, styleParamStr = strFind(paramStr, "style=\"(.-)\"")
        if not string.IsNilOrEmpty(styleParamStr) then
            local _, _, _, colorR, _, colorG, _, colorB = strFind(styleParamStr, "color:(%s-)rgb%((%d+),(%s-)(%d+),(%s-)(%d+)%)")
            if colorR and colorG and colorB then
                findColor = true
                style.ColorStr = ConverRGB2Hex(colorR, colorG, colorB)
            end

            local _, _, _, fontSize = strFind(styleParamStr, "font%-size:(%s-)(.-);")
            if fontSize then
                findSize = true
                style.FontSize = RemoveBlank(fontSize)
            end

            local isBlod = strFind(styleParamStr, "font%-weight:(%s-)bold")
            if isBlod then
                style.IsBlod = isBlod
            end
        end

        if node.Head.Tag == "font" then
            if not findColor then
                local _, _, colorStr = strFind(paramStr, "color=\"#(.-)\"")
                style.ColorStr = colorStr
            end

            if not findSize and node.Head.Tag == "font" then
                local _, _, fontSize = strFind(paramStr, "size=\"(.-)\"")
                style.FontSize = fontSize
            end
        end
    end

    style.ColorStr = style.ColorStr or defaultStyle.ColorStr
    style.FontSize = style.FontSize or defaultStyle.FontSize
    style.IsBlod = defaultStyle.IsBlod or style.IsBlod or node.Head.Tag == "b"

    if node.Head.Tag == "a" then
        style.IsHref = true
        local _, _, hrefParam = string.find(paramStr, "href=\"(.-)\"")
        if hrefParam then
            style.HrefParam = hrefParam
        end
    else
        style.IsHref = defaultStyle.IsHref
    end

    return style
end

local InitTextNode
InitTextNode = function(node, content, defaultStyle, textNodes)
    local style = GetNodeStyle(node, content, defaultStyle)

    local lastEndPos = node.Head.EndPos
    if node.Childs then
        for _, child in ipairs(node.Childs) do
            if child.Head.BeginPos - lastEndPos > 1 then
                local text = content:sub(lastEndPos + 1, child.Head.BeginPos - 1)
                text = RemoveNewLine(text)
                if not string.IsNilOrEmpty(text) then
                    tableInsert(textNodes, { Text = text, Style = style })
                end
            end

            lastEndPos = child.Tail.EndPos
            InitTextNode(child, content, style, textNodes)
        end
    end

    if node.Tail.BeginPos - lastEndPos > 1 then
        local text = content:sub(lastEndPos + 1, node.Tail.BeginPos - 1)
        text = RemoveNewLine(text)
        if not string.IsNilOrEmpty(text) then
            tableInsert(textNodes, { Text = text, Style = style })
        end
    end
end

local function CreateTextNode(paragraph, content)
    local textNodes = {}
    local tagTree = paragraph.Childs or {}

    if #tagTree <= 0 then
        if paragraph.Tail.BeginPos - paragraph.Head.EndPos > 1 then
            table.insert(textNodes, { Text = content:sub(paragraph.Head.EndPos + 1, paragraph.Tail.BeginPos - 1) })
        end
    end

    for i = 1, #tagTree do
        if i == 1 then
            if tagTree[i].Head.BeginPos - paragraph.Head.EndPos > 1 then
                local tempText = content:sub(paragraph.Head.EndPos + 1, tagTree[i].Head.BeginPos - 1)
                if not string.IsNilOrEmpty(tempText) then
                    table.insert(textNodes, { Text = tempText })
                end
            end
        else
            if tagTree[i].Head.BeginPos - tagTree[i - 1].Head.EndPos > 1 then
                local tempText = content:sub(tagTree[i - 1].Tail.EndPos + 1, tagTree[i].Head.BeginPos - 1)
                if not string.IsNilOrEmpty(tempText) then
                    table.insert(textNodes, { Text = tempText })
                end
            end
        end

        InitTextNode(tagTree[i], content, {}, textNodes)
    end

    if #tagTree > 0 then
        if paragraph.Tail.BeginPos - tagTree[#tagTree].Tail.EndPos > 1 then
            local tempText = content:sub(tagTree[#tagTree].Tail.EndPos + 1, paragraph.Tail.BeginPos - 1)
            if not string.IsNilOrEmpty(tempText) then
                table.insert(textNodes, { Text = tempText })
            end
        end
    end

    return textNodes
end

local function GenerateText(textNodes)
    local lastNode = textNodes[#textNodes]
    lastNode.Text = RemoveNewLine(lastNode.Text)

    if lastNode.Text:sub(-4) == "<br>" then
        if lastNode.Text == "<br>" then
            lastNode.Text = ""
        else
            lastNode.Text = lastNode.Text:sub(1, -5)
        end
    end

    local fontSize
    local str = ""
    local sourceStr = ""
    for _, v in ipairs(textNodes) do
        local tempStr = CS.XTool.ReplaceNoBreakingSpace(RemoveNewLine(v.Text))
        sourceStr = sourceStr .. tempStr
        if v.Style then
            if v.Style.IsHref then
                local hrefParam = v.Style.HrefParam or ""
                tempStr = "<color=#0000FFFF><a href=" .. hrefParam .. ">" .. tempStr .. "</a></color>"
            end

            if v.Style.FontSize then
                local fontSizePx = FontSizeMap[v.Style.FontSize] or FontSizeNumMap[tonumber(v.Style.FontSize)]
                if fontSizePx then
                    tempStr = "<size=" .. fontSizePx .. ">" .. tempStr .. "</size>"

                    if not fontSize then
                        fontSize = fontSizePx
                    else
                        if fontSizePx > fontSize then
                            fontSize = fontSizePx
                        end
                    end
                end
            end

            if v.Style.IsBlod then
                tempStr = "<b>" .. tempStr .. "</b>"
            end

            if v.Style.ColorStr and not v.Style.IsHref then
                tempStr = "<color=#" .. v.Style.ColorStr .. ">" .. tempStr .. "</color>"
            end
        end

        str = str .. tempStr
    end

    for k, v in pairs(HtmlCharMap) do
        str = str:gsub(k, v)
        sourceStr = sourceStr:gsub(k, v)
    end

    return str, sourceStr, fontSize or FontSizeMap["xx-large"]
end

local function CreateParagraph(paragraph, content)
    local tempContent = content:sub(paragraph.Head.EndPos + 1, paragraph.Tail.BeginPos - 1)
    local _, imgData = GetImg(tempContent)
    if imgData then
        local texture = CS.UnityEngine.Texture2D(1, 1)
        texture:LoadImage(CS.System.Convert.FromBase64String(imgData))
        return { Type = ParagraphType.Pic, Data = texture }
    end

    -- 文本段落
    local textNodes = CreateTextNode(paragraph, content)
    if not textNodes or not next(textNodes) then
        return
    end

    local text, sourceText, fontSize = GenerateText(textNodes)

    return { Type = ParagraphType.Text,
    Data = text,
    SourceData = sourceText,
    FontSize = fontSize,
    Param = content:sub(paragraph.Head.BeginPos + 1, paragraph.Head.EndPos - 1) }
end

local function Deserilize(html)
    local content = RemoveInvalidChar(html)
    if string.IsNilOrEmpty(content) then
        return
    end

    local bodyContent = GetBody(content)
    if string.IsNilOrEmpty(bodyContent) then
        return
    end

    local tagList = {}
    InitAllTagList(bodyContent, tagList)

    local matchedList = {}
    Match(tagList, matchedList)

    local tagTree = {}
    CreateTree(matchedList, tagTree)

    local paragraphObjs = {}
    for _, v in ipairs(tagTree) do
        local paragraphObj = CreateParagraph(v, bodyContent)
        if paragraphObj then
            table.insert(paragraphObjs, paragraphObj)
        end
    end

    return paragraphObjs
end

local XHtmlHandler = {
    Deserilize = Deserilize,
    RemoveBlank = RemoveBlank,
    ParagraphType = ParagraphType,
    FontSizeMap = FontSizeMap,
    AlignMap = AlignMap,
    FilterSpecialSymbol = FilterSpecialSymbol,
}

return XHtmlHandler