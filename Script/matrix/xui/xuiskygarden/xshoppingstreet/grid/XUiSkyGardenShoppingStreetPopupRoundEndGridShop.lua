---@class XUiSkyGardenShoppingStreetPopupRoundEndGridShop : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field ImgComplete UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetPopupRoundEndGridShop = XClass(XUiNode, "XUiSkyGardenShoppingStreetPopupRoundEndGridShop")

local XUiSkyGardenShoppingStreetBuildBtn = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetBuildBtn")

--region 生命周期
function XUiSkyGardenShoppingStreetPopupRoundEndGridShop:OnStart(...)
    self:_RegisterButtonClicks()
    self._PanelBuildUi = XUiSkyGardenShoppingStreetBuildBtn.New(self.PanelBuild, self)
end

function XUiSkyGardenShoppingStreetPopupRoundEndGridShop:Update(shopArea)
    local shopId = shopArea:GetShopId()
    local config = self._Control:GetShopConfigById(shopId, true)
    self._PanelBuildUi:Update(config)

    if self.PanelRecommend then
        self.PanelRecommend.gameObject:SetActive(self._Control:GetRecommendShopId() == shopId)
    end
    self.ImgUpgrade.gameObject:SetActive(false)--shopArea:CanUpgrade())

    local shopLv = shopArea:GetShopLevel()
    self.TxtNum.text = shopLv
    self.TxtName.text = config.Name
    local customerNum = XMVCA.XSkyGardenShoppingStreet:GetShopCustomerNumInTurnByShopId(shopId)
    local lastCustomerNum = XMVCA.XSkyGardenShoppingStreet:GetShopCustomerNumInLastTurnByShopId(shopId)
    self.ImgUp.gameObject:SetActive(customerNum > lastCustomerNum)
    self.ImgDown.gameObject:SetActive(lastCustomerNum > customerNum)
    self.TxtPassNum.text = customerNum
    if self.TxtScore then
        local isShowScore = config.SortType == 1
        self.PanelScore.gameObject:SetActive(isShowScore)
        if isShowScore then
            local score = shopArea:GetShopScore()
            local maxShopScore = tonumber(self._Control:GetGlobalConfigByKey("MaxShopScore"))
            self.TxtScore.text = XTool.MathGetRoundingValue(score, 1)
            self.ImgBar.fillAmount = score / maxShopScore
            
            local lastScore = XMVCA.XSkyGardenShoppingStreet:GetShopScoreInLastTurnByShopId(shopId)
            local isShowExtraScore = lastScore ~= 0 and lastScore ~= score
            if isShowExtraScore then
                local gapScore = score - lastScore
                local isShowAddScore = gapScore > 0
                if isShowAddScore then
                    self.TxtAdd.text = "+" .. XTool.MathGetRoundingValue(gapScore, 1)
                else
                    self.TxtMinus.text = XTool.MathGetRoundingValue(gapScore, 1)
                end
                self.TxtAdd.gameObject:SetActive(isShowAddScore)
                self.TxtMinus.gameObject:SetActive(not isShowAddScore)
            else
                self.TxtAdd.gameObject:SetActive(isShowExtraScore)
                self.TxtMinus.gameObject:SetActive(isShowExtraScore)
            end
        end
    end
    if self.ImgBar and not shopArea:IsInside() then
        local maxLevel = shopLv >= self._Control:GetShopMaxLevel(shopId)
        if not maxLevel then
            local configLv = self._Control:GetShopLevelConfigById(shopId, shopLv + 1, false)
            local maxCustomerNumNeed = configLv.NeedCustomerNum
            local currentNum = shopArea:GetRunTotalCustomerNum()
            self.ImgBar.fillAmount = math.min(currentNum / maxCustomerNumNeed, 1)
        else
            self.ImgBar.fillAmount = 1
        end
    end
    self.ImgUpgrade.gameObject:SetActive(shopArea:CanShowUpgradeTips())
    self.Transform:SetAsLastSibling()
end
--endregion

--region 按钮事件
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetPopupRoundEndGridShop:_RegisterButtonClicks()
    --在此处注册按钮事件
end
--endregion

return XUiSkyGardenShoppingStreetPopupRoundEndGridShop
