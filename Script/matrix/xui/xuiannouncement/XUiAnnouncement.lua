local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiAnnouncement : XLuaUi
local XUiAnnouncement = XLuaUiManager.Register(XLuaUi, "UiAnnouncement")
local XUiGridAnnouncementBtn = require("XUi/XUiAnnouncement/XUiGridAnnouncementBtn")
local XHtmlHandler = require("XUi/XUiGameNotice/XHtmlHandler")

local CsVector2 = CS.UnityEngine.Vector2

local GameNoticeType = XDataCenter.NoticeManager.GameNoticeType

--- 页签下标
---@field GameNotice number 游戏公告下标
---@field ActivityNotice number 活动公告下标
local NoticeTag = {
    GameNotice     = 1,
    ActivityNotice = 2
}

--- 标题等级
---@field LevelOne number 一级标题
---@field LevelTwo number 二级标题
local TitleLevel = {
    LevelOne = "1",
    LevelTwo = "2"
}

local SortNoticeTag = { NoticeTag.GameNotice, NoticeTag.ActivityNotice }

---@desc 页签下标索引公告类型
---@field NoticeTag.ActivityNotice number 活动公告
---@field NoticeTag.GameNotice number 游戏公告
local TabTag2NoticeInfo = {
    [NoticeTag.ActivityNotice] = {
        Type = GameNoticeType.Activity,
        Name = XUiHelper.GetText("NoticeTypeTitle1")
    },
    [NoticeTag.GameNotice]     = {
        Type = GameNoticeType.Game,
        Name = XUiHelper.GetText("NoticeTypeTitle2")
    }
}

local HtmlContent = {}



function XUiAnnouncement:OnAwake()
    self:InitCb()
    self:InitUi()
end 

function XUiAnnouncement:OnStart(noticeType, defaultSelectId)
    local selectIndex = self:GetIndexByNoticeType(noticeType)
    selectIndex = self:GetValidIndex(selectIndex)
    if not selectIndex then
        self:Close()
        XUiManager.TipText("NoInGameNotice")
    end
    self.DefaultSelectId = defaultSelectId
    self.PanelTopTabGroup:SelectIndex(selectIndex)
end 

function XUiAnnouncement:InitCb()
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end
end 

function XUiAnnouncement:InitUi()
    self.SpecialSoundMap = {}
    self.AutoCreateListeners = {}
    --动态列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTjTabEx)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridAnnouncementBtn, handler(self, self.OnSelectGrid))
    self.GridBtn.gameObject:SetActiveEx(false)
    --页签
    self.BtnTabs = {}
    for key, idx in ipairs(SortNoticeTag) do
        local ui = idx == 1 and self.BtnPayTab or XUiHelper.Instantiate(self.BtnPayTab, self.PanelTopTabGroup.transform)
        local btn = ui:GetComponent("XUiButton")
        btn:SetNameByGroup(0, TabTag2NoticeInfo[idx].Name)
        btn:SetNameByGroup(1, string.format("%02d", idx))
        btn.gameObject.name = string.format("Btn%s", key)
        btn.gameObject:SetActiveEx(true)
        local noticeType = TabTag2NoticeInfo[idx].Type
        btn:SetDisable(not XDataCenter.NoticeManager.CheckHaveNotice(noticeType))
        table.insert(self.BtnTabs, btn)
    end
    self.PanelTopTabGroup:Init(self.BtnTabs, function(index) self:OnSelectTag(index) end)
    
    self.WebViewPosCache = {}
    ---@type UnityEngine.UI.ScrollRect
    local panelWebView = self.ParagraphContent.parent.parent.transform:GetComponent("ScrollRect")
    if not XTool.UObjIsNil(panelWebView) then
        panelWebView.onValueChanged:AddListener(handler(self, self.OnWebViewScroll))
    end
    self.PanelWebView = panelWebView
end 

function XUiAnnouncement:RefreshChildView(index)
    local noticeType = TabTag2NoticeInfo[index].Type
    if not XDataCenter.NoticeManager.CheckHaveNotice(noticeType) then
        XUiManager.TipText("NoInGameNotice")
        return
    end
    local noticeInfo = XDataCenter.NoticeManager.GetInGameNoticeMap(noticeType)
    self.NoticeInfo = noticeInfo
    local tmpIdx
    if self.DefaultSelectId then
        for idx, info in ipairs(noticeInfo) do
            if info.Id == self.DefaultSelectId then
                tmpIdx = idx
                self.DefaultSelectId = nil
            end
        end
    end
    self.NoticeIndex = tmpIdx and tmpIdx or XDataCenter.NoticeManager.GetShowNoticeIndex(noticeType)
    self.DynamicTable:SetDataSource(noticeInfo)
    self.DynamicTable:ReloadDataSync(self.NoticeIndex)
end

function XUiAnnouncement:RefreshWebView(url)
    self.WebUrl = url
    if HtmlContent[url] then
        self:ShowHtml(HtmlContent[url])
        return
    end
    
    self.ImgLoading.gameObject:SetActiveEx(true)
    XLuaUiManager.SetMask(true)
    local request = CS.XUriPrefixRequest.Get(url)
    CS.XTool.WaitCoroutine(request:SendWebRequest(), function()
        XLuaUiManager.SetMask(false)
        
        if request.isNetworkError or request.isHttpError then
            return
        end
        local content = request.downloadHandler.text

        if string.IsNilOrEmpty(content) then
            return
        end
        
        request:Dispose()
        
        local html = XHtmlHandler.Deserialize(content)
        if not html then
            XLog.Error("html deserialize error, html is empty! " .. url)
            return
        end
        HtmlContent[url] = html
        self.ImgLoading.gameObject:SetActiveEx(false)
        self:ShowHtml(html)
    end)
end

function XUiAnnouncement:ShowHtml(html)
    self:ClearAllElement()
    for _, value in ipairs(html or {}) do
        if value.Type == XHtmlHandler.ParagraphType.Text then
            value.Obj = self:CreateTxt(value.Param, value.Data, value.SourceData, value.FontSize)
        else
            value.Obj = self:CreateImg(value.Data)
        end
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.ParagraphContent)
    local cachePos = self.WebViewPosCache[self.WebUrl]
    cachePos = cachePos and cachePos or CS.UnityEngine.Vector2.zero
    self.ParagraphContent.anchoredPosition = cachePos
    self.Html = html
end

function XUiAnnouncement:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiAnnouncement:RegisterListener(uiNode, eventName, func)
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
            XLog.Error("XUiPanelWorldChatMyMsgItem:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XLuaAudioManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiAnnouncement:ClearAllElement()
    if not self.Html then
        return
    end

    for _, value in pairs(self.Html or {}) do
        if value.Obj then
            CS.UnityEngine.Object.DestroyImmediate(value.Obj.gameObject)
        end
    end
end

function XUiAnnouncement:CreateTxt(param, data, sourceData, fontSize)
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

function XUiAnnouncement:OnBtnHrefClick(str)
    local skipId = tonumber(str)
    if skipId then
        XFunctionManager.SkipInterface(skipId)
    else
        CS.UnityEngine.Application.OpenURL(str)
    end
end

function XUiAnnouncement:GetTextAndObj(param, parent)
    local _, _, titleLevel = string.find(param, "h(%d)")
    local textComponent, obj
    if titleLevel == TitleLevel.LevelOne then
        obj = XUiHelper.Instantiate(self.ImgMainTittle, parent)
        textComponent = obj.transform:Find("Txt01"):GetComponent("XUiHrefText")
        obj.gameObject:SetActiveEx(true)
        textComponent.gameObject:SetActiveEx(true)
    elseif titleLevel == TitleLevel.LevelTwo then
        obj = XUiHelper.Instantiate(self.ImgSecondTittle, parent)
        textComponent = obj.transform:Find("Txt03"):GetComponent("XUiHrefText")
        obj.gameObject:SetActiveEx(true)
        textComponent.gameObject:SetActiveEx(true)
    else
        textComponent = XUiHelper.Instantiate(self.Txt02, parent):GetComponent("XUiHrefText")
        textComponent.gameObject:SetActiveEx(true)
        obj = textComponent
    end
    
    return textComponent, obj
end

function XUiAnnouncement:CreateImg(tex)
    local parent = self.ParagraphContent
    local ui = XUiHelper.Instantiate(self.Img, parent)
    ui.gameObject:SetActiveEx(true)
    ui.texture = tex


    local width = parent.rect.width
    local height = math.floor(width * tex.height / tex.width)
    ui.rectTransform.sizeDelta =CsVector2(width, height)
    
    return ui
end

---@desc 获取有内容的公告下标
---@param index number 可不填
function XUiAnnouncement:GetValidIndex(index)
    local valid = XTool.IsNumberValid(index)
    if valid then
        local noticeType = TabTag2NoticeInfo[index].Type
        local hasNotice = XDataCenter.NoticeManager.CheckHaveNotice(noticeType)
        if hasNotice then
            return index
        end
    end
    for _, idx in ipairs(SortNoticeTag) do
        local noticeType = TabTag2NoticeInfo[idx].Type
        local hasNotice = XDataCenter.NoticeManager.CheckHaveNotice(noticeType)
        if hasNotice then
            return idx
        end
    end
    return nil
end

function XUiAnnouncement:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.NoticeInfo[index])
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if XTool.IsNumberValid(self.NoticeIndex) then
            local selectGrid = self.DynamicTable:GetGridByIndex(self.NoticeIndex)
            if selectGrid then
                selectGrid:OnBtnClick()
            end
        end
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:SetSelect(false)
    end
end

function XUiAnnouncement:GetIndexByNoticeType(noticeType)
    if not noticeType or noticeType < 0 then
        return GameNoticeType.Game
    end
    for idx, info in pairs(TabTag2NoticeInfo) do
        if info.Type == noticeType then
            return idx
        end
    end
    return GameNoticeType.Game
end

function XUiAnnouncement:CheckTabRedPoint()
    for _, idx in ipairs(SortNoticeTag) do
        local noticeType = TabTag2NoticeInfo[idx].Type
        local btn = self.BtnTabs[idx]
        btn:ShowReddot(XDataCenter.NoticeManager.CheckInGameNoticeRedPoint(noticeType))
    end
end

--region   ------------------UI事件 start-------------------

function XUiAnnouncement:OnSelectTag(index)
    if index == self.TabIndex then
        return
    end
    self:CheckTabRedPoint()
    local noticeType = TabTag2NoticeInfo[index].Type
    if not XDataCenter.NoticeManager.CheckHaveNotice(noticeType) then
        XUiManager.TipText("NoInGameNotice")
        return
    end
    
    self:PlayAnimation("QieHuanUp")
    self.TabIndex = index
    self.LastGrid = nil
    self:RefreshChildView(self.TabIndex)
end

function XUiAnnouncement:OnSelectGrid(grid)
    if self.LastGrid then
        self.LastGrid:SetSelect(false)
    end
    self.PanelWebView:StopMovement()
    self:CheckTabRedPoint()
    self:PlayAnimation("QiehuanLeft")
    self.LastGrid = grid
    self:RefreshWebView(grid.Info.Content[1].Url)
end

---@param vec2 UnityEngine.Vector2
function XUiAnnouncement:OnWebViewScroll(vec2)
    if string.IsNilOrEmpty(self.WebUrl) then
        return
    end
    self.WebViewPosCache[self.WebUrl] = self.ParagraphContent.anchoredPosition
end

--endregion------------------UI事件 finish------------------