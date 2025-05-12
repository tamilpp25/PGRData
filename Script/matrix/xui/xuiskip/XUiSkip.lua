local XUiGridSkip = require("XUi/XUiTip/XUiGridSkip")
local XUiSkip = XLuaUiManager.Register(XLuaUi, "UiSkip")

function XUiSkip:OnAwake()
    self:InitAutoScript()
end

---
--- showSkipList为需要显示的跳转，包含过期但IsShowExplain字段为true的跳转
function XUiSkip:OnStart(templateId, skipCb, hideSkipBtn, showSkipList)
    self.TemplateId = templateId
    self.SkipCb = skipCb
    self.HideSkipBtn = hideSkipBtn
    self.ShowSkipList = showSkipList
    self.GridPool = {}
    local musicKey = self:GetAutoKey(self.BtnBack, "onClick")
    self.SpecialSoundMap[musicKey] = XLuaAudioManager.UiBasicsMusic.Return
    self:PlayAnimation("AniSkip")
end

function XUiSkip:OnEnable()
    self:Refresh(self.TemplateId)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiSkip:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiSkip:GetAutoKey(uiNode, eventName)
    if not uiNode then
        return
    end
    return eventName .. uiNode:GetHashCode()
end

function XUiSkip:AutoAddListener()
    self.AutoCreateListeners = {}
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
end
-- auto
function XUiSkip:OnBtnBackClick()
    self:Close()
end

function XUiSkip:Refresh(templateId)
    self.GameObject:SetActive(templateId)

    if not templateId then
        return
    end

    local skipIdList = self.ShowSkipList or XGoodsCommonManager.GetGoodsSkipIdParams(templateId)
    if not skipIdList or #skipIdList <= 0 then
        self:Close()
    end

    local hideSkipBtn = {}
    if self.HideSkipBtn == true or not self.ShowSkipList then
        -- HideSkipBtn为true隐藏 或 没有ShowSkipList数据时，使用HideSkipBtn
        for _, skipId in ipairs(skipIdList) do
            hideSkipBtn[skipId] = self.HideSkipBtn
        end
    else
        -- HideSkipBtn为false显示 并且有ShowSkipList数据，需要判断跳转有没有过期(隐藏跳转按钮)
        for _, skipId in ipairs(skipIdList) do
            if XFunctionManager.CheckSkipInDuration(skipId) then
                hideSkipBtn[skipId] = false
            else
                hideSkipBtn[skipId] = true
            end
        end
    end

    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)
    local icon = goodsShowParams.Icon
    if goodsShowParams.BigIcon then
        icon = goodsShowParams.BigIcon
    end

    self.RImgIcon:SetRawImage(icon)
    self.TxtIconName.text = goodsShowParams.Name
    self.TxtIconNum.text = XGoodsCommonManager.GetGoodsCurrentCount(templateId)

    if goodsShowParams.RewardType == XRewardManager.XRewardType.Equip then
        local equipSite = XMVCA.XEquip:GetEquipSite(templateId)
        if equipSite and equipSite ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON then
            self.TxtSite.text = equipSite
            self.PanelSite.gameObject:SetActive(true)
        else
            self.PanelSite.gameObject:SetActive(false)
        end
    else
        self.PanelSite.gameObject:SetActive(false)
    end

    self.PanelGridSkip.gameObject:SetActive(false)
    local onCreate = function(grid, data)
        grid:Refresh(data, hideSkipBtn[data], function()
            self:Close()
            -- 暂停自动弹窗
            XDataCenter.AutoWindowManager.StopAutoWindow()
            if self.SkipCb then
                self.SkipCb()
            end
        end)
    end

    XUiHelper.CreateTemplates(self, self.GridPool, skipIdList, XUiGridSkip.New, self.PanelGridSkip, self.PanelContent, onCreate)
end