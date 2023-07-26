---@class XUiGuideNew : XLuaUi
---@field Guide XGuide
local XUiGuideNew = XLuaUiManager.Register(XLuaUi, "UiGuide")


function XUiGuideNew:OnAwake()
    self:AutoAddListener()
    self.PanelInfoRect = self.PanelInfo
    self.PanelWarning.gameObject:SetActive(false)
    self.BtnSkip.gameObject:SetActive(false)
    self.BtnPass.gameObject:SetActive(false)
    self.PanelInfo.gameObject:SetActive(false)

    self.LastClickTime = 0
    self.ContinueClickTimes = 0
    self.ClickInterval = 0.5
end

function XUiGuideNew:OnStart(targetImg, isWeakGuide, guideDesc, icon, name, callback)
    
    self.Guide = self.BtnPanelMaskGuide:GetComponent("XGuide")
    if (not self.Guide) then
        self.Guide = self.BtnPanelMaskGuide.gameObject:AddComponent(typeof(CS.XGuide))
    end
    self.Guide:SetPass(false)
    self.Guide:SetTimeText(self.TxtTime)

    self.Callback = callback
    self.IsWeakGuide = isWeakGuide
    if targetImg then
        CS.XGuideEventPass.IsPassEvent = true
        CS.XGuideEventPass.IsFightGuide = true
        self.IsFight = true
        self:ShowMark(true, true)
        local anchor = CS.UnityEngine.Vector2(0, 1)
        self:ShowDialog(icon, name, guideDesc, anchor, anchor, CS.UnityEngine.Vector2(500, -380))
        self:FocusOnFightPanel(targetImg)
        self.UiWidget = self.Transform:Find("FullScreenBackground/BtnPanelMaskGuide/BtnPass").gameObject:AddComponent(typeof(CS.XUiWidget))
        self.UiWidget:AddPointerDownListener(function(eventData)
            self.Transform:Find("SafeAreaContentPane").gameObject:SetActive(false)
            self.Transform:Find("FullScreenBackground/BtnPanelMaskGuide"):GetComponent("Image").enabled = false
            self.Transform:Find("FullScreenBackground/BtnPanelMaskGuide/BtnPass/Bg").gameObject:SetActive(false)
        end)
        self.UiWidget:AddPointerUpListener(function(eventData)
            self:OnBtnPassClick()
        end)
    end

    -- CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_GUIDE_FIGHT_BTNDOWN, function(evt, args)
    --     if self.Callback and not self.IsWeakGuide then
    --         self.Callback()
    --         self.Callback = nil
    --     end
    -- end)
end

function XUiGuideNew:OnDestroy()
    -- CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_GUIDE_FIGHT_BTNDOWN, function(evt, args)
    --     if self.Callback and not self.IsWeakGuide then
    --         self.Callback = nil
    --     end
    -- end)
end

function XUiGuideNew:AutoAddListener()
    self:RegisterClickEvent(self.BtnPanelMaskGuide, self.OnBtnPanelMaskGuideClick)
    self:RegisterClickEvent(self.BtnPass, self.OnBtnPassClick)
    self:RegisterClickEvent(self.BtnSkip, self.OnBtnSkipClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
end
-- auto
function XUiGuideNew:OnBtnSkipClick()
    self.PanelWarning.gameObject:SetActive(true)
end

function XUiGuideNew:OnBtnConfirmClick()
    XDataCenter.GuideManager.ReqCompleteGuideGroup(function()
        XDataCenter.GuideManager.RecordBuryingPoint(XDataCenter.GuideManager.BuryingPointType.Skip)
        XDataCenter.GuideManager.ResetGuide()
        XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
    end)
end

function XUiGuideNew:CheckDouble()
    if XTime.GetServerNowTimestamp() - self.LastClickTime > self.ClickInterval then
        self.ContinueClickTimes = 0
    else
        self.ContinueClickTimes = self.ContinueClickTimes + 1
    end

    if self.ContinueClickTimes == 3 then
        self.ContinueClickTimes = 0
        self.BtnSkip.gameObject:SetActive(true)
    end

    self.LastClickTime = XTime.GetServerNowTimestamp()
end

function XUiGuideNew:OnBtnCancelClick()
    self.PanelWarning.gameObject:SetActive(false)
end

function XUiGuideNew:OnBtnPassClick()
    self.Guide:Reset()

    if self.Callback and not self.IsWeakGuide then
        self.Callback()
        self.Callback = nil
    end
end

function XUiGuideNew:OnBtnPanelMaskGuideClick()
    if not XDataCenter.GuideManager.CheckIsFightGuide() and not CS.XGuideEventPass.IsFightGuide then
        self:CheckDouble()
    end

    CsXGameEventManager.Instance:Notify(CS.XEventId.EVENT_GUIDE_ANYCLICK)
end

--显示头像
function XUiGuideNew:ShowDialog(icon, name, content, anchorMax, anchorMin, position)
    self.PanelInfo.gameObject:SetActive(true)
    self:SetUiSprite(self.ImgRole, icon)
    self.TxtName.text = name or ""
    self.TxtDesc.text = content

    self.PanelInfoRect.anchorMax = anchorMax
    self.PanelInfoRect.anchorMin = anchorMin
    self.PanelInfoRect.anchoredPosition = position
end

--隐藏头像
function XUiGuideNew:HideDialog()
    self.PanelInfo.gameObject:SetActive(false)
end

--聚焦panel
function XUiGuideNew:FocusOnPanel(panel, eulerAngles, passEvent, sizeDelta)
    eulerAngles = eulerAngles or CS.UnityEngine.Vector3.zero
    sizeDelta = sizeDelta or CS.UnityEngine.Vector2.zero
    self.BtnPass.gameObject:SetActive(true)
    self.BtnPass.gameObject.transform.eulerAngles = eulerAngles
    self.Guide:SetTarget(panel, sizeDelta)

    if not XTool.UObjIsNil(panel.gameObject) then
        CS.XGuideEventPass.Target = panel.gameObject
    end

    CS.XGuideEventPass.IsPassEvent = passEvent
    if self.AniGuideJiaoLoop then
        self.AniGuideJiaoLoop.gameObject:SetActive(false)
        self.AniGuideJiaoLoop.gameObject:SetActive(true)
    end
end

function XUiGuideNew:FocusOn3DPanel(camera, panel, offset, eulerAngles, passEvent, sizeDelta)
    
    eulerAngles = eulerAngles or CS.UnityEngine.Vector3.zero
    sizeDelta = sizeDelta or CS.UnityEngine.Vector2.zero
    self.BtnPass.gameObject:SetActive(true)
    self.BtnPass.gameObject.transform.eulerAngles = eulerAngles
    self.Guide:SetTarget(panel, camera, sizeDelta, offset)

    if not XTool.UObjIsNil(panel.gameObject) then
        CS.XGuideEventPass.Target = panel.gameObject
    end

    CS.XGuideEventPass.IsPassEvent = passEvent
    if self.AniGuideJiaoLoop then
        self.AniGuideJiaoLoop.gameObject:SetActive(false)
        self.AniGuideJiaoLoop.gameObject:SetActive(true)
    end
end

function XUiGuideNew:FocusOnFightPanel(panel)
    self.BtnPass.gameObject:SetActive(true)
    self.Guide:SetTarget(panel, CS.UnityEngine.Vector2.zero)
    CS.XGuideEventPass.Target = nil
end

--显示遮罩
function XUiGuideNew:ShowMark(isShowMask, isShowRay)
    self.PanelMaskAll.gameObject:SetActive(isShowMask)
    self.BtnPanelMaskGuide.gameObject:SetActive(true)
    self.Guide:SetPass(not isShowMask)
end


--显示遮罩
function XUiGuideNew:ShowMarkNew(isShowMask, isShowRay)
    self.PanelMaskAll.gameObject:SetActive(isShowMask)
    self.BtnPanelMaskGuide.gameObject:SetActive(isShowRay)
    self.Guide:SetPass(not isShowMask)
end