local XUiPlanetPropertyShop = XLuaUiManager.Register(XLuaUi, "UiPlanetPropertyShop")

function XUiPlanetPropertyShop:OnAwake()
    self:AddBtnClickListener()
    self.CurShopIdList = XDataCenter.PlanetManager.GetViewModel():GetActivityShopIdList()
    self.ItemList = XUiPanelItemList.New(self.PanelItemList, self, nil, self.UiParams, handler(self, self.OnRefreshGrid))
    self.AssetPanel = XUiHelper.NewPanelActivityAsset({ XDataCenter.ItemManager.ItemId.PlanetRunningShopActivity }, self.PanelSpecialTool)

    self.CurSelectIndex = 1
    XDataCenter.PlanetManager.SetSceneActive(false)
end

function XUiPlanetPropertyShop:OnEnable()
    XShopManager.GetBaseInfo(function()
        if not self:GetCurShopId() then
            return
        end

        XShopManager.GetShopInfo(self:GetCurShopId(), function()
            self.BtnTab:SelectIndex(1)
        end)
    end)
    self:RefreshTime()
end

function XUiPlanetPropertyShop:RefreshTime()
    local timeText = self.Transform:Find("SafeAreaContentPane/PanelMainShop/PanelShop/PanelBt/Text2"):GetComponent("Text")
    local endTime = XDataCenter.PlanetManager.GetViewModel():GetEndTime()
    if not XTool.IsNumberValid(endTime) then
        timeText.gameObject:SetActiveEx(false)
        return
    end

    local shopTimeInfo = XShopManager.GetShopTimeInfo(self:GetCurShopId())
    local leftTime = shopTimeInfo.ClosedLeftTime
    if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.PLANET_RUNNING)
        timeText.text = timeStr
        timeText.gameObject:SetActiveEx(true)
    else
        timeText.gameObject:SetActiveEx(false)
    end
end

function XUiPlanetPropertyShop:OnDestroy()
    XDataCenter.PlanetManager.SetSceneActive(true)
end

function XUiPlanetPropertyShop:OnRefreshGrid(grid, index)
    grid:RefreshCondition()
end

function XUiPlanetPropertyShop:GetCurShopId()
    return self.CurShopIdList[self.CurSelectIndex]
end

function XUiPlanetPropertyShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
end

function XUiPlanetPropertyShop:RefreshBuy()
    self.ItemList:ShowPanel(self:GetCurShopId())
end

function XUiPlanetPropertyShop:OnShopSelect(index)
    self.CurSelectIndex = index

    self.ItemList:ShowPanel(self:GetCurShopId())
    self:RefreshGridRedInfo()
    self:PlayAnimation("QieHuan")
end

-- 外部检测新商品刷新红点
function XUiPlanetPropertyShop:RefreshGridRedInfo()
    local goodsList = XShopManager.GetShopGoodsList(self:GetCurShopId(), true)
    for k, data in pairs(goodsList) do
        -- 检测每个商品
        local key = XPlayer.Id .. "PlanetShopId" .. data.Id
        local isCurrLock = nil -- 此次是否上锁
        local allCdPass = true
        local conditionIds = data.ConditionIds
        -- 检测此次该商品是否解锁
        if conditionIds and #conditionIds > 0 then
            for _, cId in pairs(conditionIds) do
                local ret, desc = XConditionManager.CheckCondition(cId)
                if not ret then
                    allCdPass = false
                end
            end
        end

        isCurrLock = not allCdPass
        XSaveTool.SaveData(key, isCurrLock)
    end
end

--#region 按钮绑定
function XUiPlanetPropertyShop:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    
    local tabBtns = { self.BtnTong1, self.BtnTong2 }
    self.BtnTab:Init(tabBtns, function(index) self:OnShopSelect(index) end)
end
--endregion