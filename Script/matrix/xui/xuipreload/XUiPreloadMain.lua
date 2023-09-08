local XUiPreloadMain = XLuaUiManager.Register(XLuaUi, "UiPreloadMain")
local XHtmlHandler = require("XUi/XUiGameNotice/XHtmlHandler")
local CsVector2 = CS.UnityEngine.Vector2

--- 标题等级
---@field LevelOne number 一级标题
---@field LevelTwo number 二级标题
local TitleLevel = {
    LevelOne = "1",
    LevelTwo = "2"
}

function XUiPreloadMain:OnStart()
    --self.UpdateTimeFunc = function () self:UpdateLeftTime() end
    --self.ErrorTimeFunc = function (err)
    --    XLog.Error("XMVCA.XPreload:GetLeftDownloadTime():::" .. tostring(XMVCA.XPreload:GetLeftDownloadTime()))
    --end
    self.DownloadEffectPos = nil
    self.DownloadMaxWidth = 0
    self.DownloadProgressEffectTrans = nil
    --self.DownloadProgressEffect:SetLoadedCallback(function() self:OnEffectLoaded() end) --先注释特效代码, 不能引用启动器资源
    self:RegisterUiEvents()

    self.SpecialSoundMap = {}
    self.AutoCreateListeners = {}

    XMVCA.XPreload:OpenRecord() --打开预下载界面埋点
    XMVCA.XPreload:CancelRedPoint() --取消红点
end

function XUiPreloadMain:OnEffectLoaded()
    self.DownloadProgressEffectTrans = self.DownloadProgressEffect.transform
    local originPos = self.DownloadProgressEffectTrans.localPosition
    self.DownloadEffectPos = CS.UnityEngine.Vector3(0, originPos.y, originPos.z)
    self.DownloadMaxWidth = self.DownloadProgressEffectTrans.parent:GetComponent("RectTransform").rect.width
    self.DownloadProgressEffectTrans.localPosition = self.DownloadEffectPos
end

function XUiPreloadMain:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDownload, self.OnBtnDownloadClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDownload2, self.OnBtnDownloadClick)
    if XMain.IsEditorDebug then
        XUiHelper.RegisterClickEvent(self, self.BtnClear, self.OnBtnClearClick)
        XUiHelper.RegisterClickEvent(self, self.BtnMove, self.OnBtnMoveClick)
    else
        self.BtnClear.gameObject:SetActiveEx(false)
        self.BtnMove.gameObject:SetActiveEx(false)
        self.TxtDocVerName.gameObject:SetActiveEx(false)
        self.TxtPreVerName.gameObject:SetActiveEx(false)
    end
end

function XUiPreloadMain:OnBtnClearClick()
    local preloadAgency = XMVCA.XPreload
    preloadAgency:ClearPreloadHistory()
end

function XUiPreloadMain:OnBtnMoveClick()
    self.PanelLoading.gameObject:SetActiveEx(true)
    local preloadAgency = XMVCA.XPreload
    preloadAgency:TestMovePreFiles(function(progress)
        self:UpdateMoveProcess(progress)
    end, function()
        self:MoveComplete()
    end)
end

function XUiPreloadMain:OnBtnDownloadClick()
    local preloadAgency = XMVCA.XPreload
    local state = preloadAgency:GetCurState()
    if state <= XEnumConst.Preload.State.None then
        if not CS.XNetworkReachability.IsViaLocalArea() then --不是wifi状态提示
            local content = XUiHelper.GetText("PreloadNetworkTip")
            XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), content, XUiManager.DialogType.Normal, nil, function()
                self:ClickStartPreload()
            end)
        else
            self:ClickStartPreload()
        end
    elseif state == XEnumConst.Preload.State.Pause then
        if not CS.XNetworkReachability.IsViaLocalArea() then --不是wifi状态提示
            local content = XUiHelper.GetText("PreloadNetworkTip")
            XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), content, XUiManager.DialogType.Normal, nil, function()
                self:ClickResume()
            end)
        else
            self:ClickResume()
        end
    elseif state == XEnumConst.Preload.State.Downloading then
        preloadAgency:SetIsPause(true)
        preloadAgency:SetAutoResume(false) --自己暂停不用再检查网络状态切换
        XUiManager.TipText("PreloadBtnLabelPause", XUiManager.UiTipType.Tip)
    end
end

function XUiPreloadMain:ClickResume()
    local preloadAgency = XMVCA.XPreload
    preloadAgency:SetIsPause(false)
    XUiManager.TipText("PreloadBtnLabelResume", XUiManager.UiTipType.Tip)
end

function XUiPreloadMain:ClickStartPreload()
    local preloadAgency = XMVCA.XPreload
    if preloadAgency:CheckAndStart() then
        XUiManager.TipText("PreloadStart", XUiManager.UiTipType.Tip)
    end
end

function XUiPreloadMain:ShowHtml(html)
    self:ClearAllElement()
    for _, value in ipairs(html or {}) do
        if value.Type == XHtmlHandler.ParagraphType.Text then
            value.Obj = self:CreateTxt(value.Param, value.Data, value.SourceData, value.FontSize)
        else
            value.Obj = self:CreateImg(value.Data)
        end
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.ParagraphContent)
    --local cachePos = self.WebViewPosCache[self.WebUrl]
    --cachePos = cachePos and cachePos or CS.UnityEngine.Vector2.zero
    --self.ParagraphContent.anchoredPosition = cachePos
    self.Html = html
end

function XUiPreloadMain:ClearAllElement()
    if not self.Html then
        return
    end

    for _, value in pairs(self.Html or {}) do
        if value.Obj then
            CS.UnityEngine.Object.DestroyImmediate(value.Obj.gameObject)
        end
    end
end

function XUiPreloadMain:CreateTxt(param, data, sourceData, fontSize)
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

function XUiPreloadMain:CreateImg(tex)
    local parent = self.ParagraphContent
    local ui = XUiHelper.Instantiate(self.Img, parent)
    ui.gameObject:SetActiveEx(true)
    ui.texture = tex


    local width = parent.rect.width
    local height = math.floor(width * tex.height / tex.width)
    ui.rectTransform.sizeDelta =CsVector2(width, height)

    return ui
end

function XUiPreloadMain:GetTextAndObj(param, parent)
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

function XUiPreloadMain:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiPreloadMain:OnBtnHrefClick(str)
    local skipId = tonumber(str)
    if skipId then
        XFunctionManager.SkipInterface(skipId)
    else
        CS.UnityEngine.Application.OpenURL(str)
    end
end

function XUiPreloadMain:RegisterListener(uiNode, eventName, func)
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
            XLog.Error("XUiPreloadMain:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end


--更新界面信息
function XUiPreloadMain:UpdateInfo()
    local preloadAgency = XMVCA.XPreload

    self.TxtDocVer.text = preloadAgency:GetLocalDocVersion() --本地doc版本号
    self.TxtPreVer.text = preloadAgency:GetPreloadVersion() --预下载版本号

    --self.PanelLoading.gameObject:SetActiveEx(preloadAgency:GetIsDownloading()) --正在下载要显示
    self:UpdateBtnState()
    self:UpdateMessage()
    self:UpdateLoading()
    self:UpdateProcess()

    if not self:UpdateNotice() then
        preloadAgency:RequestNotice()
    end
end

function XUiPreloadMain:UpdateNotice()
    local htmlContent = XMVCA.XPreload:GetPreloadNotice()
    if htmlContent then
        self.ImgLoading.gameObject:SetActiveEx(false)
        self:ShowHtml(htmlContent)
        return true
    else
        self.ImgLoading.gameObject:SetActiveEx(true)
        return false
    end
end

function XUiPreloadMain:UpdateBtnState()
    local preloadAgency = XMVCA.XPreload
    local btnLabel = ""
    local isDownload2 = false
    local isDisable = false

    if preloadAgency:IsComplete() then
        btnLabel = XUiHelper.GetText("PreloadBtnLabelComplete")
        isDisable = true
    else
        local state = preloadAgency:GetCurState()
        if state <= XEnumConst.Preload.State.None then
            btnLabel = XUiHelper.GetText("PreloadBtnLabelPreload")
        elseif state == XEnumConst.Preload.State.Downloading then
            isDownload2 = true
            btnLabel = XUiHelper.GetText("PreloadBtnLabelPause")
        elseif state == XEnumConst.Preload.State.Pausing then
            btnLabel = XUiHelper.GetText("PreloadBtnLabelPausing")
        elseif state == XEnumConst.Preload.State.Pause then
            btnLabel = XUiHelper.GetText("PreloadBtnLabelResume")
        elseif state >= XEnumConst.Preload.State.Start then
            btnLabel = XUiHelper.GetText("PreloadBtnLabelDownloading")
        end
    end
    if isDownload2 then
        self.BtnDownload2.gameObject:SetActiveEx(true)
        self.BtnDownload2:SetName(btnLabel)
        self.BtnDownload2:SetDisable(isDisable)
        self.BtnDownload.gameObject:SetActiveEx(false)
    else
        self.BtnDownload.gameObject:SetActiveEx(true)
        self.BtnDownload:SetName(btnLabel)
        self.BtnDownload:SetDisable(isDisable)
        self.BtnDownload2.gameObject:SetActiveEx(false)
    end
end

function XUiPreloadMain:UpdateMessage()
    local preloadAgency = XMVCA.XPreload
    self.TxtMessage.text = preloadAgency:GetCurStateMessage()
end

--更新进度面板
function XUiPreloadMain:UpdateLoading()
    local preloadAgency = XMVCA.XPreload
    local state = preloadAgency:GetCurState()
    if state > XEnumConst.Preload.State.None and state < XEnumConst.Preload.State.Complete then
        self.PanelLoading.gameObject:SetActiveEx(true) --正在下载要显示
        if state == XEnumConst.Preload.State.Pause then
            self:UpdateSpeed()
            self:UpdateLeftTime()
        end
    else
        self.PanelLoading.gameObject:SetActiveEx(false)
    end
end

function XUiPreloadMain:UpdateMoveProcess(progress)
    self.SliderDownload.value = progress
    self.TxtDownloadProgress.text = string.format("%d%%", math.floor(progress * 100))
    self:UpdateDownloadProgressEffect(progress)
end

function XUiPreloadMain:MoveComplete()
    XLog.Error("移动文件完成")
end

function XUiPreloadMain:UpdateProcess()
    local preloadAgency = XMVCA.XPreload
    local progress = preloadAgency:GetCurProgress()
    local allSize = preloadAgency:GetAllDownloadSize() / 1024 / 1024
    self.SliderDownload.value = progress
    self:UpdateDownloadProgressEffect(progress)

    self.TxtDownloadProgress.text = string.format("%d%%", math.floor(progress * 100))
    self.TxtDownloadSize.text = string.format("(%dMB/%dMB)", math.floor(allSize * progress), math.floor(allSize))

    self:UpdateSpeed()
    self:UpdateLeftTime()
end

function XUiPreloadMain:UpdateDownloadProgressEffect(progress)
    if self.DownloadProgressEffectTrans then
        self.DownloadEffectPos.x = math.floor(self.DownloadMaxWidth * progress)
        self.DownloadProgressEffectTrans.localPosition = self.DownloadEffectPos
    end
end

function XUiPreloadMain:UpdateSpeed()
    local preloadAgency = XMVCA.XPreload
    local speed = preloadAgency:GetTickSpeed() / 1024
    if speed > 1024 then
        self.TxtDownloadSpeed.text = string.format("%0.1fMB/S", speed / 1024)
    else
        self.TxtDownloadSpeed.text = string.format("%dKB/S", math.floor(speed))
    end
end

function XUiPreloadMain:UpdateLeftTime()
    local preloadAgency = XMVCA.XPreload
    local leftTime = preloadAgency:GetLeftDownloadTime()
    self.TxtDownloadTime.text = XUiHelper.GetText("PreloadLeftTime") .. self:FormatSec2Min(leftTime) -- "预计时间："
end

function XUiPreloadMain:FormatSec2Min(seconds)
    local min = math.floor(seconds / 60)
    seconds = seconds - min * 60

    local hour = 0
    if min >= 60 then
        hour = math.floor(min / 60)
        min = min - hour * 60
    end
    return string.format("%02d:%02d:%02d", math.floor(hour), math.floor(min), math.floor(seconds))
end


function XUiPreloadMain:OnEnable()
    XMVCA.XPreload:AddAgencyEvent(XAgencyEventId.EVENT_PRELOAD_STATE_UPDATE, self.OnPreloadStateUpdate, self)
    XMVCA.XPreload:AddAgencyEvent(XAgencyEventId.EVENT_PRELOAD_PROCESS, self.OnPreloadProcess, self)
    XMVCA.XPreload:AddAgencyEvent(XAgencyEventId.EVENT_PRELOAD_NOTICE_UPDATE, self.UpdateNotice, self)
    self:UpdateInfo()
end

function XUiPreloadMain:OnDisable()
    XMVCA.XPreload:RemoveAgencyEvent(XAgencyEventId.EVENT_PRELOAD_STATE_UPDATE, self.OnPreloadStateUpdate, self)
    XMVCA.XPreload:RemoveAgencyEvent(XAgencyEventId.EVENT_PRELOAD_PROCESS, self.OnPreloadProcess, self)
    XMVCA.XPreload:RemoveAgencyEvent(XAgencyEventId.EVENT_PRELOAD_NOTICE_UPDATE, self.UpdateNotice, self)
end

function XUiPreloadMain:OnPreloadStateUpdate()
    self:UpdateMessage()
    self:UpdateBtnState()
    self:UpdateLoading()
end


function XUiPreloadMain:OnPreloadProcess()
    self:UpdateProcess()
end

function XUiPreloadMain:OnBtnBackClick()
    self:Close()
end

function XUiPreloadMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPreloadMain:OnDestroy()

end

return XUiPreloadMain