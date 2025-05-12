-- 快速换头像
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGachaAlphaQuickWear : XLuaUi 使用历程奖励弹框
local XUiGachaAlphaQuickWear = XLuaUiManager.Register(XLuaUi, "UiGachaAlphaQuickWear")

function XUiGachaAlphaQuickWear:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnWear, self.OnBtnWearClick)
end

function XUiGachaAlphaQuickWear:OnStart(templateId, rewardId, isConvertFrom, rewardName, callBack)
    self._CallBack = callBack
    self._TemplateId = templateId
    self.TxtDesc.text = XUiHelper.GetText(isConvertFrom and "GachaAlphaRewardTitle1" or "GachaAlphaRewardTitle2", rewardName)
    self.BtnWear.gameObject:SetActiveEx(not isConvertFrom)

    ---@type XUiGridCommon
    local grid = XUiGridCommon.New(self, self.GridFashion)
    grid:Refresh({ TemplateId = self._TemplateId })
    grid:SetCustomItemTip(function(data, hideSkipBtn, rootUiName, lackNum)
        XLuaUiManager.Open("UiGachaAlphaTip", data, hideSkipBtn, rootUiName, lackNum)
    end)

    self._IsHead = XDataCenter.HeadPortraitManager.IsHeadPortraitValid(self._TemplateId)
    self._IsWeaponFashion = XDataCenter.ItemManager.IsWeaponFashion(self._TemplateId)

    if self._IsWeaponFashion then
        self._CharacterId = tonumber(XGachaConfigs.GetClientConfig("WeaponFashionCharacter", rewardId))
        local isHasCharacter = XMVCA.XCharacter:IsOwnCharacter(self._CharacterId)
        self.BtnWear.gameObject:SetActiveEx(isHasCharacter)

        local curWearFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(self._CharacterId)
        if curWearFashionId == self._TemplateId then
            self.BtnWear:SetDisable(true)
            self._IsLock = true
        end
    end
end

function XUiGachaAlphaQuickWear:Close()
    self.Super.Close(self)
    if self._CallBack then
        self._CallBack()
    end
end

function XUiGachaAlphaQuickWear:OnBtnWearClick()
    if self._IsDone or self._IsLock then
        return
    end

    self.BtnWear:SetDisable(true)

    if XDataCenter.HeadPortraitManager.IsHeadPortraitValid(self._TemplateId) then
        local config = XDataCenter.HeadPortraitManager.GetHeadPortraitInfoById(self._TemplateId)
        if config.Type == 1 then
            -- 更换头像
            XDataCenter.HeadPortraitManager.ChangeHeadPortrait(self._TemplateId, function()
                XUiManager.TipText("GachaAlphaSettingSuccess")
                self._IsDone = true
            end)
        else
            -- 更换头像框
            XDataCenter.HeadPortraitManager.ChangeHeadFrame(self._TemplateId, function()
                XUiManager.TipText("GachaAlphaSettingSuccess")
                self._IsDone = true
            end)
        end
        return
    end

    -- 更换武器涂装
    if XDataCenter.ItemManager.IsWeaponFashion(self._TemplateId) then
        local fashionId = XDataCenter.ItemManager.GetWeaponFashionId(self._TemplateId)
        XDataCenter.WeaponFashionManager.UseFashion(fashionId, self._CharacterId, function()
            XUiManager.TipText("GachaAlphaSettingSuccess")
            self._IsDone = true
        end)
        return
    end
end

return XUiGachaAlphaQuickWear