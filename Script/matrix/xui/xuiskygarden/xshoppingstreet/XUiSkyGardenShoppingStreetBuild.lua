local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetBuildBtnList = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetBuildBtnList")
local XUiSkyGardenShoppingStreetBuildBtnTab = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetBuildBtnTab")
local XUiSkyGardenShoppingStreetBuildGridAttribute = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuildGridAttribute")

---@class XUiSkyGardenShoppingStreetBuild : XLuaUi
---@field UiBigWorldTopControlWhite UnityEngine.RectTransform
---@field PanelOutsideList UnityEngine.RectTransform
---@field PanelInsideList UnityEngine.RectTransform
---@field PanelLock UnityEngine.RectTransform
---@field PanelTop UnityEngine.RectTransform
---@field PanelOutsideUnlock UnityEngine.RectTransform
---@field TxtTitle UnityEngine.UI.Text
---@field TxtDetail1 UnityEngine.UI.Text
---@field TxtDetail2 UnityEngine.UI.Text
---@field ImgAsset UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
---@field BtnUnlock XUiComponent.XUiButton
---@field BtnUpgrade XUiComponent.XUiButton
---@field BtnRecommend XUiComponent.XUiButton
---@field ImgBar UnityEngine.UI.Image
---@field TxtLvNum UnityEngine.UI.Text
---@field TxtNow UnityEngine.UI.Text
---@field TxtNext UnityEngine.UI.Text
---@field GridAttribute UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetBuild = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetBuild")

--region 生命周期
function XUiSkyGardenShoppingStreetBuild:OnAwake()
    self._SpBuildingAttrs = {}
    self._BuildingAttrs = {}
    self._BuildingList = {}
    ---@type XUiSkyGardenShoppingStreetAsset
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelTop, self)
    self:_RegisterButtonClicks()
    self._TxtDefaultColor = self.TxtNum.color
end

function XUiSkyGardenShoppingStreetBuild:OnStart(pos, isInside)
    self._Pos = pos
    self._IsInside = isInside
    self._SelectAreaId = self._Control:GetAreaIdByUiPos(self._Pos, self._IsInside)
    self.PanelInsideList.gameObject:SetActive(self._IsInside)
    self.PanelOutsideList.gameObject:SetActive(not self._IsInside)
    self._Control:X3CSetVirtualCamera(self._SelectAreaId, XMVCA.XSkyGardenShoppingStreet.X3CCameraPosIndex.Middle)
end

function XUiSkyGardenShoppingStreetBuild:OnEnable()
    if self._IsInside then
        self:RefreshInsideShopList()
    else
        self:RefreshOutsideShopList()
    end
end
--endregion

function XUiSkyGardenShoppingStreetBuild:RefreshInsideShopList()
    local stageId = self._Control:GetCurrentStageId()
    local shoppingConfig = self._Control:GetStageShopConfigsByStageId(stageId)
    local parentType = XMVCA.XSkyGardenShoppingStreet.InsideBuildingParentType
    local shopData = {
        [parentType.Consumpt] = { SortType = parentType.Consumpt, ShopConfigs = {} },
        [parentType.Passenger] = { SortType = parentType.Passenger, ShopConfigs = {} },
        [parentType.Environment] = { SortType = parentType.Environment, ShopConfigs = {} },
    }

    local isFound = false
    local defaultId = false
    for _, configId in ipairs(shoppingConfig.InsideShopGroup) do
        local config = self._Control:GetShopConfigById(configId, true)
        local shopId = config.Id
        local pType = config.SortType
        local showData = shopData[pType]
        if showData then
            table.insert(showData.ShopConfigs, config)
            if not defaultId then
                defaultId = shopId
            end
            if not isFound and not self._Control:GetAreaIdByShopId(shopId) then
                defaultId = shopId
                isFound = true
            end
        end
    end

    XTool.UpdateDynamicItem(self._BuildingList, shopData, self.PanelBuild, XUiSkyGardenShoppingStreetBuildBtnList, self)
    self:SelectBuilding(defaultId)
end

function XUiSkyGardenShoppingStreetBuild:SelectBuilding(shopId)
    -- if self._SelectShopId == shopId then return end
    if self._SelectBtn then
        self._SelectBtn:SetSelect(false)
    end

    self._SelectBtn = nil
    local isFound = false
    if self._IsInside then
        for _, btnList in pairs(self._BuildingList) do
            if isFound then break end
            local btns = btnList:GetBtns()
            for _, btn in pairs(btns) do
                if isFound then break end
                if btn:GetShopId() == shopId then
                    self._SelectBtn = btn
                    isFound = true
                    break
                end
            end
        end
    else
        for _, btn in pairs(self._BuildingList) do
            if isFound then break end
            if btn:GetShopId() == shopId then
                self._SelectBtn = btn
                isFound = true
                break
            end
        end
    end
    if self._SelectBtn then
        self._SelectBtn:SetSelect(true)
    end

    self:RefreshBuildingInfo(shopId)
end

function XUiSkyGardenShoppingStreetBuild:RefreshBuildingInfo(shopId)
    self._SelectShopId = shopId
    self._Config = self._Control:GetShopConfigById(self._SelectShopId, self._IsInside)
    self.TxtTitle.text = self._Config.Name
    self.TxtDetail1.text = self._Config.Desc
    self.TxtDetail2.text = self._Config.Desc2
    if self.TxtTitleAccount then
        self.TxtTitleAccount.text = self._Config.AccountDesc
    end
    self.Icon:SetSprite(self._Config.SignboardImg)

    local resCfgs = self._Control:GetStageResConfigs()
    local attrData = self._Control:GetShopAttributes(self._SelectShopId, 1, self._IsInside)
    local spData = {}
    local nData = {}
    for i = 1, #attrData do
        local attr = attrData[i]
        local resCfg = resCfgs[attr.ResConfigId]
        if resCfg.IsSp then
            table.insert(spData, attr)
        else
            table.insert(nData, attr)
        end
    end

    if self.GridAttributeSpecial then
        XTool.UpdateDynamicItem(self._SpBuildingAttrs, spData, self.GridAttributeSpecial, XUiSkyGardenShoppingStreetBuildGridAttribute, self)
    end
    self.GridAttribute.gameObject:SetActive(true)
    if self.AttributeGold then
        XTool.UpdateDynamicItem(self._BuildingAttrs, nData, self.AttributeGold, XUiSkyGardenShoppingStreetBuildGridAttribute, self)
    end
    self.GridAttribute.gameObject:SetActive(#nData > 0)
    self.GridAttribute.transform:SetAsLastSibling()

    self._ShopAreaData = self._Control:GetShopAreaByShopId(self._SelectShopId, self._IsInside)
    self._HasShop = false
    self._ShopLv = 0

    local isUnlock = true
    if self._ShopAreaData then
        self._HasShop = self._ShopAreaData:HasShop()
        self._ShopLv = self._ShopAreaData:GetShopLevel()
        isUnlock = self._ShopAreaData:IsUnlock()
    end
    self._NotShop = not self._HasShop

    local isShowUnlockBtn = self._IsInside or self._NotShop
    self.PanelLock.gameObject:SetActive(isShowUnlockBtn and isUnlock)
    self.PanelOutsideUnlock.gameObject:SetActive(not isShowUnlockBtn)

    local buffId = self._Config.BuffShowId
    if buffId and buffId > 0 then
        local buffConfig = self._Control:GetBuffConfigById(buffId)
        self.TxtScienceDetail2.text = self._Control:ParseBuffDescById(buffId)
        self.RImgScience:SetRawImage(buffConfig.Icon)
        if self.TxtLock then
            self.TxtLock.gameObject:SetActive(self._ShopLv < 2)
        end
        self.PanelScience.gameObject:SetActive(true)
    else
        self.PanelScience.gameObject:SetActive(false)
    end

    if isShowUnlockBtn then
        self.BtnUnlock:ShowReddot(false)
        if isUnlock then
            local hasRes = true
            local resCfgs = self._Control:GetStageResConfigs()
            local StageResType = XMVCA.XSkyGardenShoppingStreet.StageResType
            if self._IsInside then
                local cost = self._Config.Cost
                local reduceCost = self._Control:ShopBuildCostReduceBySubType(self._Config.SubType, cost)
                self.TxtNum.text = reduceCost
                local showDiscount = reduceCost ~= cost
                self.TxtDiscount.gameObject:SetActive(showDiscount)

                local resCfg = resCfgs[StageResType.InitGold]
                self.ImgAsset:SetSprite(resCfg.Icon)
                self.ImgAsset.color = XUiHelper.Hexcolor2Color(resCfg.IconColor)
                if showDiscount then
                    self.TxtDiscount.text = cost
                end
    
                local hasRes = self._Control:EnoughStageResById(reduceCost)
                if hasRes then
                    self.TxtNum.color = self._TxtDefaultColor
                else
                    self.TxtNum.color = CS.UnityEngine.Color(1, 0, 0)
                end

                local btnNameKey = self._HasShop and "SG_SS_BuildBtnGo" or "SG_SS_BuildBtnBuild"
                self.BtnUnlock:SetName(XMVCA.XBigWorldService:GetText(btnNameKey))
                self.PanelNeed.gameObject:SetActive(self._NotShop)
            else
                self.PanelNeed.gameObject:SetActive(true)
                local canUnlockOutside, unlockCfg = self._Control:CanUnlockOutisdeShop()
                hasRes = canUnlockOutside
                local resCfg = resCfgs[StageResType.InitFriendly]
                self.TxtNum.text = self._Control:GetValueByResConfig(unlockCfg.NeedSatisfaction, resCfg)
                self.TxtNum.color = XUiHelper.Hexcolor2Color(resCfg.Color)
                self.ImgAsset:SetSprite(resCfg.Icon)
                self.ImgAsset.color = XUiHelper.Hexcolor2Color(resCfg.IconColor)
                self.BtnUnlock:SetName(XMVCA.XBigWorldService:GetText("SG_SS_BuildBtnUnlock"))
            end

            local canBuildShop = self._Control:CanBuildShop(self._IsInside)
            if self._HasShop or not self._IsInside then
                self.TxtBuildTips.text = ""
            else
                if canBuildShop then
                    self.TxtBuildTips.text = XMVCA.XBigWorldService:GetText("SG_SS_BuildChanceText", 1)
                else
                    self.TxtBuildTips.text = XMVCA.XBigWorldService:GetText("SG_SS_BuildChanceText", 0)
                end
            end

            local canClickBuild = hasRes and canBuildShop or self._HasShop
            self.BtnUnlock:SetButtonState(canClickBuild and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
            self.BtnUnlock:ShowReddot(canClickBuild)
        end
    else
        self.TxtBuildTips.text = ""
        self._MaxLevel = self._ShopLv >= self._Control:GetShopMaxLevel(self._SelectShopId)
        self.BtnUpgrade:ShowReddot(false)
        if not self._MaxLevel then
            local configLv = self._Control:GetShopLevelConfigById(self._SelectShopId, self._ShopLv + 1, self._IsInside)
            local maxCustomerNumNeed = configLv.NeedCustomerNum
            local currentNum = self._ShopAreaData:GetRunTotalCustomerNum()
            self.TxtNow.text = XMVCA.XBigWorldService:GetText("SG_SS_UpgradeText1", currentNum)
            self.ImgBar.fillAmount = math.min(currentNum / maxCustomerNumNeed, 1)
            local canUpgrade = currentNum >= maxCustomerNumNeed
            if canUpgrade then
                self.BtnUpgrade:SetButtonState(CS.UiButtonState.Normal)
                self.TxtNext.text = XMVCA.XBigWorldService:GetText("SG_SS_BuildBtnCanUpgrade")
            else
                self.BtnUpgrade:SetButtonState(CS.UiButtonState.Disable)
                self.TxtNext.text = XMVCA.XBigWorldService:GetText("SG_SS_UpgradeText2", math.max(0, maxCustomerNumNeed - currentNum))
            end
            self.BtnUpgrade:ShowReddot(canUpgrade)
        else
            self.BtnUpgrade:SetButtonState(CS.UiButtonState.Disable)
            self.TxtNext.text = XMVCA.XBigWorldService:GetText("SG_SS_BuildLevelMax")
        end
        self.BtnUpgrade:SetName(XMVCA.XBigWorldService:GetText("SG_SS_BuildBtnUpgrade"))

        self.TxtLvNum.text = self._ShopLv
        self._IsRecommand = self._Control:GetRecommendShopId() == self._SelectShopId
        self.BtnRecommend:SetButtonState(self._IsRecommand and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    end

    self:RefreshShopInScene()
end

function XUiSkyGardenShoppingStreetBuild:RefreshShopInScene()
    -- 场景
    if self._IsInside then
        if self._HasShop then
            if self._lastSceneObjectBaseId then
                self._lastSceneObjectBaseId = nil
                self._Control:X3CBuildingDestroy(self._SelectAreaId)
            end

            local areaId = self._Control:GetAreaIdByShopId(self._SelectShopId)
            self._Control:X3CSetVirtualCamera(areaId, XMVCA.XSkyGardenShoppingStreet.X3CCameraPosIndex.Middle)
        else
            local sceneObjectBaseId = self._Config.ShopResId
            if self._lastSceneObjectBaseId then
                if sceneObjectBaseId ~= self._lastSceneObjectBaseId then
                    self._Control:X3CBuildingDestroy(self._SelectAreaId)
                    self._Control:X3CBuildingCreate(self._SelectAreaId, sceneObjectBaseId)
                end
            else
                self._Control:X3CBuildingCreate(self._SelectAreaId, sceneObjectBaseId)
            end
            local X3CEShopEffectType = XMVCA.XSkyGardenShoppingStreet.X3CEShopEffectType
            self._Control:X3CPlayShopEffect(self._SelectAreaId, X3CEShopEffectType.ShopPreview)

            self._lastSceneObjectBaseId = sceneObjectBaseId
            local configLv = self._Control:GetShopLevelConfigById(self._SelectShopId, 1, self._IsInside)
            self._Control:X3CBuildingChange(self._SelectAreaId, configLv.ShowLevel, self._IsInside)
            self._Control:X3CSetVirtualCamera(self._SelectAreaId, XMVCA.XSkyGardenShoppingStreet.X3CCameraPosIndex.Middle)
        end
    else
        local areaId = self._Control:GetAreaIdByShopId(self._SelectShopId)
        self._Control:X3CSetVirtualCamera(areaId, XMVCA.XSkyGardenShoppingStreet.X3CCameraPosIndex.Middle)
    end
end

function XUiSkyGardenShoppingStreetBuild:RefreshOutsideShopList()
    local outSideBuilding = self._Control:GetShopAreas(self._IsInside)
    XTool.UpdateDynamicItem(self._BuildingList, outSideBuilding, self.BtnTab1, XUiSkyGardenShoppingStreetBuildBtnTab, self)
    self:SelectBuilding(self._SelectShopId or outSideBuilding[self._Pos]:GetShopId())
end

--region 按钮事件
function XUiSkyGardenShoppingStreetBuild:OnBtnUnlockClick()
    if self._HasShop then
        local uiPos = self._Control:GetUiPositionByShopId(self._SelectShopId, self._IsInside)
        XMVCA.XBigWorldUI:PopThenOpen("UiSkyGardenShoppingStreetInsideBuild", uiPos, self._IsInside)
        return
    end

    local uiPos = self._IsInside and self._Pos or self._Control:GetUiPositionByShopId(self._SelectShopId, self._IsInside)
    self._Control:UnlockShop(self._SelectShopId, uiPos, self._IsInside, function()
        if self._SelectAreaId then
            local X3CEShopEffectType = XMVCA.XSkyGardenShoppingStreet.X3CEShopEffectType
            self._Control:X3CPlayShopEffect(self._SelectAreaId, X3CEShopEffectType.None)
        end
        if self._IsInside then
            XMVCA.XBigWorldUI:PopThenOpen("UiSkyGardenShoppingStreetInsideBuild", self._Pos, self._IsInside)
        else
            if self._IsInside then
                self:RefreshInsideShopList()
            else
                self:RefreshOutsideShopList()
            end
        end
    end)
end

function XUiSkyGardenShoppingStreetBuild:OnBtnUpgradeClick()
    if not self._ShopAreaData or self._MaxLevel then return end

    local shopId = self._ShopAreaData:GetShopId()
    local level = self._ShopAreaData:GetShopLevel()
    local shopConfig = self._Control:GetShopLevelConfigById(shopId, level + 1, self._IsInside)
    local enoughCustomerNum = self._ShopAreaData:GetRunTotalCustomerNum() >= shopConfig.NeedCustomerNum
    if not enoughCustomerNum then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_NotEnoughCustomer"))
        return
    end

    local uiPos = self._Control:GetUiPositionByShopId(self._SelectShopId, self._IsInside)
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetUpgrade", uiPos, self._IsInside)
end

function XUiSkyGardenShoppingStreetBuild:OnBtnRecommendClick()
    if self._IsRecommand then return end
    self._Control:SgStreetShopSetRecommendRequest(self._SelectShopId, function()
        self:RefreshOutsideShopList()
    end)
end

function XUiSkyGardenShoppingStreetBuild:OnBtnBackClick()
    if self._SelectAreaId then
        local X3CEShopEffectType = XMVCA.XSkyGardenShoppingStreet.X3CEShopEffectType
        self._Control:X3CPlayShopEffect(self._SelectAreaId, X3CEShopEffectType.None)
    end
    if self._IsInside then
        self._Control:X3CBuildingDestroy(self._SelectAreaId)
    end
    self:Close()
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetBuild:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnUnlock.CallBack = function() self:OnBtnUnlockClick() end
    self.BtnUpgrade.CallBack = function() self:OnBtnUpgradeClick() end
    self.BtnRecommend.CallBack = function() self:OnBtnRecommendClick() end
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
end
--endregion

return XUiSkyGardenShoppingStreetBuild
