local next = next
local tableInsert = table.insert
local TagTextPrefix = "NoticeTag"
local XHtmlHandler = require("XUi/XUiGameNotice/XHtmlHandler")
local mathFloor = math.floor
local mathCeil = math.ceil
local strFind = string.find

local HtmlParagraphs = {}
local BTN_INDEX = {
    First = 1,
    Second = 2,
}

local XUiGameNotice = XLuaUiManager.Register(XLuaUi, "UiGameNotice")
function XUiGameNotice:OnStart(rootUi, selectIdx, selectId, type)
    self.RootUi = rootUi
    self.HttpTextures = {}
    self.HtmlIndexDic = {}
    self.TabBtns = {}
    self.Type = type
    self.SelectIndex = selectIdx
    self.SelectId = selectId
    self:InitAutoScript()
end

function XUiGameNotice:OnDisable()
    self.CurUrl = nil
    if self.WebViewPanel then
        CS.UnityEngine.Object.DestroyImmediate(self.WebViewPanel.gameObject)
        self.WebViewPanel = nil
    end

    self:ClearTabBtns()
    self:ClearAllChildren()

    LuaGC()
end

function XUiGameNotice:InitAutoScript()
    self.SpecialSoundMap = {}
    self.AutoCreateListeners = {}
end

function XUiGameNotice:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiGameNotice:RegisterListener(uiNode, eventName, func)
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
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiGameNotice:OnEnable()
    self:UpdateLeftTabBtns(self.SelectIndex, self.SelectId, self.Type)
    self:OnSelectedTog()
end

function XUiGameNotice:OnDestroy()
    for index, httpTexture in pairs(self.HttpTextures) do
        if httpTexture:Exist() then
            CS.UnityEngine.Object.Destroy(httpTexture)
            self.HttpTextures[index] = nil
        end
    end
end

function XUiGameNotice:OnGetEvents()
    return { XEventId.EVENT_UIDIALOG_VIEW_ENABLE, XEventId.EVENT_NOTICE_TYPE_CHANAGE, XEventId.EVENT_NOTICE_CONTENT_RESP }
end

function XUiGameNotice:OnNotify(evt, ...)
    if evt == XEventId.EVENT_UIDIALOG_VIEW_ENABLE then
        self.RootUi:Close()
    elseif evt == XEventId.EVENT_NOTICE_TYPE_CHANAGE then
        local arg = {...}
        self:UpdateLeftTabBtns(nil,nil, arg[1])
        self:OnSelectedTog()
    elseif evt == XEventId.EVENT_NOTICE_CONTENT_RESP then
       local args = {...} 
       self:OnNoticeContentResp(args[1])
    end
end

function XUiGameNotice:GetCertainBtnModel(index, hasChild, pos, totalNum)
    if index == BTN_INDEX.First then
        if hasChild then
            return self.BtnFirstHasSnd
        else
            return self.BtnFirst
        end
    elseif index == BTN_INDEX.Second then
        if totalNum == 1 then
           return self.BtnSecondAll
        end

        if pos == 1 then
            return self.BtnSecondTop
        elseif pos == totalNum then
            return self.BtnSecondBottom
        else
            return self.BtnSecond
        end
    end
end

function XUiGameNotice:ClearTabBtns()
    if not self.TabBtns then
        return
    end

    for _, v in pairs(self.TabBtns) do
        CS.UnityEngine.GameObject.Destroy(v.gameObject)
    end

    self.TabBtns = {}
end

function XUiGameNotice:UpdateLeftTabBtns(selectIdx, selectId, type)
    self.NoticeMap = XDataCenter.NoticeManager.GetInGameNoticeMap(type)
    local noticeInfos = self.NoticeMap
    if not noticeInfos then return end

    self.HtmlIndexDic = {}

    self:ClearTabBtns()
    local btnIndex = 0
    local firstRedPointIndex

    --一级标题
    for groupIndex, data in ipairs(noticeInfos) do
        local htmlList = data.Content
        local totalNum = #htmlList

        local btnModel = self:GetCertainBtnModel(BTN_INDEX.First, totalNum > 1)
        local btn = CS.UnityEngine.Object.Instantiate(btnModel)
        btn.transform:SetParent(self.PanelNoticeTitleBtnGroup.transform, false)
        btn.gameObject:SetActiveEx(true)
        btn:SetName(data.Title)

        if not data.Tag or data.Tag == 0 then
            btn:ShowTag(false)
        else
            local txtTag = btn.transform:Find("Tag/ImgTag/Text"):GetComponent("Text")
            txtTag.text = CS.XTextManager.GetText(TagTextPrefix .. data.Tag)
            btn:ShowTag(true)
        end

        local uiButton = btn:GetComponent("XUiButton")
        tableInsert(self.TabBtns, uiButton)
        btnIndex = btnIndex + 1

        --二级标题
        local needRedPoint = false
        local firstIndex = btnIndex
        local onlyOne = totalNum == 1
        for htmlIndex, htmlCfg in ipairs(htmlList) do
            needRedPoint = XDataCenter.NoticeManager.CheckInGameNoticeRedPointIndividual(data, htmlIndex)
            if needRedPoint and not firstRedPointIndex then
                firstRedPointIndex = btnIndex
            end
            if not onlyOne then
                local tmpBtnModel = self:GetCertainBtnModel(BTN_INDEX.Second, nil, htmlIndex, totalNum)
                local tmpBtn = CS.UnityEngine.Object.Instantiate(tmpBtnModel)
                tmpBtn:SetName(htmlCfg.Title)
                tmpBtn.transform:SetParent(self.PanelNoticeTitleBtnGroup.transform, false)

                local tmpUiButton = tmpBtn:GetComponent("XUiButton")
                tmpUiButton.SubGroupIndex = firstIndex
                tableInsert(self.TabBtns, tmpUiButton)
                btnIndex = btnIndex + 1

                if needRedPoint then
                    tmpUiButton:ShowReddot(true)
                else
                    tmpUiButton:ShowReddot(false)
                end
            end

            local indexInfo = {
                HtmlReadKey = XDataCenter.NoticeManager.GetGameNoticeReadDataKey(data, htmlIndex),
                HtmlUrl = htmlCfg.Url,
                HtmlUrlSlave = htmlCfg.UrlSlave,
                GroupIndex = groupIndex
            }
            self.HtmlIndexDic[btnIndex] = indexInfo
            if selectId and selectId == tonumber(htmlCfg.Order) then
                selectIdx = btnIndex
            end
        end

        uiButton:ShowReddot(needRedPoint)
    end

    local selectIndex = selectIdx or firstRedPointIndex or 1
    self.PanelNoticeTitleBtnGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
    self.PanelNoticeTitleBtnGroup:SelectIndex(selectIndex, false)
    self.SelectIndex = selectIndex
    self.SelectId = nil
end

function XUiGameNotice:OnSelectedTog(index)
    if self.SelectIndex and self.SelectIndex == index then return end
    index = index or self.SelectIndex
    self.SelectIndex = index

    local indexInfo = self.HtmlIndexDic[index]
    if not indexInfo or not next(indexInfo) then
        return
    end

    --刷新右边UI
    self:UpdateWebView(indexInfo.HtmlUrl)

    --取消小红点
    XDataCenter.NoticeManager.ChangeInGameNoticeReadStatus(indexInfo.HtmlReadKey, true)
    local uiButton = self.TabBtns[index]
    uiButton:ShowReddot(false)

    --判断一级按钮小红点
    local subGroupIndex = uiButton.SubGroupIndex
    if subGroupIndex and self.TabBtns[subGroupIndex] then
        local needRed = false
        for _, btn in pairs(self.TabBtns) do
            if btn.SubGroupIndex and btn.SubGroupIndex == subGroupIndex
            and btn.ReddotObj.activeSelf then
                needRed = true
                break
            end
        end
        if not needRed then
            self.TabBtns[subGroupIndex]:ShowReddot(false)
        end
    end
end

function XUiGameNotice:CreateImgObj(texture)
    local parent = self.Img.transform.parent.transform
    local newImgObj = CS.UnityEngine.Object.Instantiate(self.Img, parent)
    newImgObj.gameObject:SetActiveEx(true)
    newImgObj.texture = texture

    local width = parent.rect.width
    local height = mathFloor(width * texture.height / texture.width)
    newImgObj.rectTransform.sizeDelta = CS.UnityEngine.Vector2(width, height)

    return newImgObj
end

function XUiGameNotice:CreateTextObj(params, textData, sourceTextData, fontSize)
    local parent = self.Txt.transform.parent.transform
    local newTextObj = CS.UnityEngine.Object.Instantiate(self.Txt, parent):GetComponent("XUiHrefText")
    newTextObj.gameObject:SetActiveEx(true)
    newTextObj.fontSize = fontSize or XHtmlHandler.FontSizeMap["xx-large"]
    newTextObj.lineSpacing = 1.5

    local width = parent.rect.width
    local tg = newTextObj.cachedTextGeneratorForLayout
    local set = newTextObj:GetGenerationSettings(CS.UnityEngine.Vector2(width, 0))
    local height = mathCeil(tg:GetPreferredHeight(CS.XTool.ReplaceNoBreakingSpace(sourceTextData), set) / newTextObj.pixelsPerUnit) + newTextObj.fontSize * (newTextObj.lineSpacing - 1)

    newTextObj.rectTransform.sizeDelta = CS.UnityEngine.Vector2(width, height)
    newTextObj.text = textData

    local align
    local _, _, styleParam = strFind(params, "style=\"(.-)\"")
    if styleParam then
        _, _, align = strFind(styleParam, "text%-align:(.-);")
        if align then
            align = XHtmlHandler.RemoveBlank(align)
            newTextObj.alignment = XHtmlHandler.AlignMap[align]
        end
    end

    if not align then
        _, _, align = strFind(params, "align=\"(.-)\"")
        if align then
            align = XHtmlHandler.RemoveBlank(align)
            newTextObj.alignment = XHtmlHandler.AlignMap[align]
        end
    end

    return newTextObj
end


function XUiGameNotice:ShowHtml(paragraphs)
    self:ClearAllChildren()

    for _, v in ipairs(paragraphs) do
        if v.Type == XHtmlHandler.ParagraphType.Text then
            v.Obj = self:CreateTextObj(v.Param, v.Data, v.SourceData, v.FontSize)
            self:RegisterListener(v.Obj, "onHrefClick", self.OnBtnHrefClick)
        else
            v.Obj = self:CreateImgObj(v.Data)
        end
    end

    self.CurParagraphs = paragraphs
end

function XUiGameNotice:OnBtnHrefClick(str)
    if string.find(str, "whiteday") ~= nil or string.find(str, "thelastspark") ~= nil then -- 情人节网页活动和黄金周的
        local uid = XLoginManager.GetUserId()
        local serverId = CS.XHeroBdcAgent.ServerId
        if uid and uid ~= "" then
            CS.UnityEngine.Application.OpenURL(str.."?uid="..uid.."&hostid=".. serverId) -- todo 服务器id
            return
        end
    elseif string.find(str, "natsumatsuri") ~= nil then -- 夏日祭活动
        local uid = XLoginManager.GetUserId()
        if uid and uid ~= "" then
            CS.UnityEngine.Application.OpenURL(str.."?code_id="..uid)
            return
        end
    elseif string.find(str, "seeed") ~= nil or string.find(str, "rooot") ~= nil then -- rooot活动的
        XDataCenter.ActivityManager.OpenRoootUrl(str)
    else
        if string.find(str, "eden") ~= nil then -- 萌战网页活动接入需求
            local uid = XUserManager.UserId
            local serverId = CS.XHeroBdcAgent.ServerId
            if uid and serverId then
                CS.UnityEngine.Application.OpenURL(str.."?uid="..uid.."&serverId="..serverId)
            end
        else
            CS.UnityEngine.Application.OpenURL(str)
        end
    end
    CS.UnityEngine.Application.OpenURL(str)
end

function XUiGameNotice:UpdateWebView(url)
    if self.CurUrl == url then
        return
    end

    self.CurUrl = url

    if HtmlParagraphs[url] then
        self:ShowHtml(HtmlParagraphs[url])
        return
    end

    self.ImgLoading.gameObject:SetActiveEx(true)

    local request = CS.XUriPrefixRequest.Get(url)
    CS.XTool.WaitCoroutine(request:SendWebRequest(), function()
        if request.isNetworkError or request.isHttpError then
            return
        end

        local content = request.downloadHandler.text
        if string.IsNilOrEmpty(content) then
            return
        end
        request:Dispose()
        
        HtmlParagraphs[url] = XHtmlHandler.Deserilize(content)
        if not HtmlParagraphs[url] then
            XLog.Error("content deserilized is nil, url:" .. tostring(url))
            return 
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_NOTICE_CONTENT_RESP, HtmlParagraphs[url])
    end)
end

function XUiGameNotice:OnNoticeContentResp(content)
    self:ShowHtml(content)
    self.ImgLoading.gameObject:SetActiveEx(false)
end

function XUiGameNotice:ClearAllChildren()
    if self.CurParagraphs then
        for _, v in ipairs(self.CurParagraphs) do
            CS.UnityEngine.Object.DestroyImmediate(v.Obj.gameObject)
        end
    end

    self.CurParagraphs = {}
end