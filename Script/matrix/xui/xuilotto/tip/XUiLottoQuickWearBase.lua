local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiLottoQuickWearBase : XLuaUi
local XUiLottoQuickWearBase = XLuaUiManager.Register(XLuaUi, "UiLottoQuickWearBase")

function XUiLottoQuickWearBase:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnWear, self.OnBtnWearClick)
end

function XUiLottoQuickWearBase:OnStart(templateId, callBack)
    self._CallBack = callBack
    self._TemplateId = templateId
    self.BtnWear.gameObject:SetActiveEx(true)

    ---@type XUiGridCommon
    local grid = XUiGridCommon.New(self, self.GridFashion)
    grid:Refresh({ TemplateId = self._TemplateId })

    self._IsHead = XDataCenter.HeadPortraitManager.IsHeadPortraitValid(self._TemplateId)
    self._IsWeaponFashion = XDataCenter.ItemManager.IsWeaponFashion(self._TemplateId)

    if self._IsWeaponFashion then
        self._CharacterId = self:DoGetCharacterId()
        local isHasCharacter = XMVCA.XCharacter:IsOwnCharacter(self._CharacterId)
        self.BtnWear.gameObject:SetActiveEx(isHasCharacter)

        local curWearFashionId = XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(self._CharacterId)
        if curWearFashionId == self._TemplateId then
            self.BtnWear:SetDisable(true)
            self._IsLock = true
        end

        self.TxtDesc.text = XUiHelper.GetText("LottoKareninaRewardTitle1", grid.GoodsShowParams.Name)
    elseif self._IsHead then
        self.TxtDesc.text = XUiHelper.GetText("LottoKareninaRewardTitle2", grid.GoodsShowParams.Name)
    else
        self.TxtDesc.text = grid.GoodsShowParams.Name
    end
end

---abstract
function XUiLottoQuickWearBase:DoGetCharacterId()
end

function XUiLottoQuickWearBase:OnBtnCloseClick()
    self:Close()
    if self._CallBack then
        self._CallBack()
    end
end

function XUiLottoQuickWearBase:OnBtnWearClick()
    if self._IsDone or self._IsLock then
        return
    end

    self.BtnWear:SetDisable(true)

    if XDataCenter.HeadPortraitManager.IsHeadPortraitValid(self._TemplateId) then
        local config = XDataCenter.HeadPortraitManager.GetHeadPortraitInfoById(self._TemplateId)
        if config.Type == 1 then
            -- 更换头像
            XDataCenter.HeadPortraitManager.ChangeHeadPortrait(self._TemplateId, function()
                XUiManager.TipText("LottoKareninaSettingSuccess")
                self._IsDone = true
            end)
        else
            -- 更换头像框
            XDataCenter.HeadPortraitManager.ChangeHeadFrame(self._TemplateId, function()
                XUiManager.TipText("LottoKareninaSettingSuccess")
                self._IsDone = true
            end)
        end
        return
    end

    -- 更换武器涂装
    if XDataCenter.ItemManager.IsWeaponFashion(self._TemplateId) then
        local fashionId = XDataCenter.ItemManager.GetWeaponFashionId(self._TemplateId)
        XDataCenter.WeaponFashionManager.UseFashion(fashionId, self._CharacterId, function()
            XUiManager.TipText("LottoKareninaSettingSuccess")
            self._IsDone = true
        end)
        return
    end
end

return XUiLottoQuickWearBase