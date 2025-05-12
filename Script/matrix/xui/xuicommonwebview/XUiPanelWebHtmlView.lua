local XHtmlHandler = require("XUi/XUiGameNotice/XHtmlHandler")
---@class XUiPanelWebHtmlView : XUiNode
local XUiPanelWebHtmlView = XClass(XUiNode, "XUiPanelWebHtmlView")

local CsVector2 = CS.UnityEngine.Vector2
--- 标题等级
---@field LevelOne number 一级标题
---@field LevelTwo number 二级标题
local TitleLevel = {
    LevelOne = "1",
    LevelTwo = "2"
}

function XUiPanelWebHtmlView:OnStart()
    self.SpecialSoundMap = {}
    self.AutoCreateListeners = {}
end

function XUiPanelWebHtmlView:ShowHtml(content)
    local html = XHtmlHandler.Deserialize(content)
    if not html then
        XLog.Error("XUiPanelWebHtmlView:ShowHtml error: html is nil")
        return
    end
    self:SetLoadingActive(false)
    self:ClearAllElement()
    for _, value in ipairs(html) do
        if value.Type == XHtmlHandler.ParagraphType.Text then
            value.Obj = self:CreateTxt(value.Param, value.Data, value.SourceData, value.FontSize)
        else
            value.Obj = self:CreateImg(value.Data)
        end
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.ParagraphContent)
    self.Html = html
end

function XUiPanelWebHtmlView:ClearAllElement()
    if XTool.IsTableEmpty(self.Html) then
        return
    end
    for _, value in pairs(self.Html) do
        if value.Obj then
            CS.UnityEngine.Object.DestroyImmediate(value.Obj.gameObject)
        end
    end
end

function XUiPanelWebHtmlView:CreateTxt(param, data, sourceData, fontSize)
    local parent = self.ParagraphContent
    local textComponent, obj = self:GetTextAndObj(param, parent)

    textComponent.fontSize = fontSize or XHtmlHandler.FontSizeMap["large"]
    textComponent.lineSpacing = 1.0

    local width = parent.rect.width
    local layout = textComponent.cachedTextGeneratorForLayout
    local setting = textComponent:GetGenerationSettings(CsVector2(width, 0))

    local height = math.ceil(layout:GetPreferredHeight(CS.XTool.ReplaceNoBreakingSpace(sourceData), setting) / textComponent.pixelsPerUnit) + textComponent.fontSize * (textComponent.lineSpacing - 1)

    textComponent.rectTransform.sizeDelta = CsVector2(width, height)
    textComponent.text = data
    self:RegisterListener(textComponent, "onHrefClick", self.OnBtnHrefClick)

    local align
    local _, _, styleParam = string.find(param, "style=\"(.-)\"")

    if styleParam then
        _, _, align = string.find(styleParam, "text%-align:(.-);")
        if align then
            align = XHtmlHandler.RemoveBlank(align)
            textComponent.alignment = XHtmlHandler.AlignMap[align]
        end
    end

    if not align then
        _, _, align = string.find(param, "align=\"(.-)\"")
        if align then
            align = XHtmlHandler.RemoveBlank(align)
            textComponent.alignment = XHtmlHandler.AlignMap[align]
        end
    end

    return obj
end

function XUiPanelWebHtmlView:CreateImg(tex)
    local parent = self.ParagraphContent
    local ui = XUiHelper.Instantiate(self.Img, parent)
    ui.gameObject:SetActiveEx(true)
    ui.texture = tex

    local width = parent.rect.width
    local height = math.floor(width * tex.height / tex.width)
    ui.rectTransform.sizeDelta = CsVector2(width, height)

    return ui
end

function XUiPanelWebHtmlView:GetTextAndObj(param, parent)
    local _, _, titleLevel = string.find(param, "h(%d)")
    local textComponent, obj
    if titleLevel == TitleLevel.LevelOne then
        obj = XUiHelper.Instantiate(self.ImgMainTittle, parent)
        textComponent = obj:GetObject("Txt01")
        obj.gameObject:SetActiveEx(true)
        textComponent.gameObject:SetActiveEx(true)
    elseif titleLevel == TitleLevel.LevelTwo then
        obj = XUiHelper.Instantiate(self.ImgSecondTittle, parent)
        textComponent = obj:GetObject("Txt03")
        obj.gameObject:SetActiveEx(true)
        textComponent.gameObject:SetActiveEx(true)
    else
        textComponent = XUiHelper.Instantiate(self.Txt02, parent)
        textComponent.gameObject:SetActiveEx(true)
        obj = textComponent
    end
    return textComponent, obj
end

function XUiPanelWebHtmlView:OnBtnHrefClick(str)
    local skipId = tonumber(str)
    if skipId then
        XFunctionManager.SkipInterface(skipId)
    else
        CS.UnityEngine.Application.OpenURL(str)
    end
end

function XUiPanelWebHtmlView:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiPanelWebHtmlView:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then
        return
    end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiPanelWebHtmlView:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

--- 设置loading状态
function XUiPanelWebHtmlView:SetLoadingActive(isActive)
    self.ImgLoading.gameObject:SetActiveEx(isActive)
end

return XUiPanelWebHtmlView
