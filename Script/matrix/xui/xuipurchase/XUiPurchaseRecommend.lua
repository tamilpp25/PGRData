--######################## XUiPanelRecommend ########################
local XUiPanelRecommend = XClass(nil, "XUiPanelRecommend")

function XUiPanelRecommend:Ctor()
    self.PurchaseManager = XDataCenter.PurchaseManager
    self.Recommend = nil
    self.SkipFunc = nil
    self.BuyFinished = nil
    self.BtnGiftNameList = {}
end

function XUiPanelRecommend:SetUi(ui)
    -- 清除无用Btn引用
    for _, btnName in ipairs(self.BtnGiftNameList) do
        self[btnName] = nil
    end
    XUiHelper.InitUiClass(self, ui)
end

function XUiPanelRecommend:SetData(data, skipFunc, buyFinished)
    self.Recommend = data
    self.SkipFunc = skipFunc
    self.BuyFinished = buyFinished
    
    -- v1.28-采购优化-根据PurchasePackageId注册跳转方式
    local isHavePackageId = XTool.IsNumberValid(#self.Recommend:GetPurchasePackageIdList())
    if isHavePackageId and self.BtnGiftBuy1 then  -- 配了PurchasePackageId且拥有礼包按钮
        --self.BtnBuy.gameObject:SetActiveEx(false)
        for index, _ in ipairs(self.Recommend:GetPurchasePackageIdList()) do
            local package = self.Recommend:GetPurchasePackage()[index]
            local btnName = "BtnGiftBuy" .. index
            if package == nil then
                -- 页签显示时间内但找不到礼包数据则不显示
                self[btnName].gameObject:SetActiveEx(false)
            else
                -- 保存已有Btn引用
                self.BtnGiftNameList[index] = btnName
                -- 设置礼包状态
                if package:GetIsSellOut() then
                    self[btnName]:SetDisable(true)
                end
                -- 注册礼包购买
                XUiHelper.RegisterClickEvent(self, self[btnName], function ()
                    if package:GetIsSellOut() then
                        XUiManager.TipErrorWithKey("PurchaseSettOut")
                        return
                    end
                    local buyData = self.Recommend:GetPurchasePackage()
                    if buyData then
                        local rawData = package:GetRawData()
                        if rawData and not XDataCenter.PayManager.CheckCanBuy(rawData.Id) then
                            return
                        end
                        self.PurchaseManager.OpenPurchaseBuyUiByPurchasePackage(package, function()
                            self.SkipFunc(XPurchaseConfigs.TabsConfig.Pay)
                        end, nil, self.BuyFinished)
                    end
                end)
            end
        end
    -- else                                          -- 不配PurchasePackageId
    --     self.BtnBuy.gameObject:SetActiveEx(true)
    --     XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)
    end
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)

    -- self.TxtTime.gameObject:SetActiveEx(data:GetIsShowTimeTip())
    -- self.TxtTime.text = string.format("%s~%s", data:GetStartTimeDate(), data:GetEndTimeDate())
    -- self.ImgSellOut.gameObject:SetActiveEx(data:GetIsSellOut())
end

function XUiPanelRecommend:OnBtnBuyClicked()
    local skipSteps = self.Recommend:GetSkipSteps()
    if #skipSteps > 0 then
        self.SkipFunc(skipSteps[1], skipSteps[2])
        return
    end
    if self.Recommend:GetIsSellOut() then
        XUiManager.TipErrorWithKey("PurchaseSettOut")
        return
    end
end

function XUiPanelRecommend:PlayEnableAnim()
    if not XTool.UObjIsNil(self.AnimEnable) then
        self.AnimEnable:Stop()
        self.AnimEnable:Play()
    end    
end

--######################## XUiRecommendGrid ########################
local XUiRecommendGrid = XClass(nil, "XUiRecommendGrid")

function XUiRecommendGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.UiPanelRecommend = XUiPanelRecommend.New()
end

function XUiRecommendGrid:SetData(data, skipFunc, buyFinished)
    local go
    if self.Transform.childCount > 0 then
        go = self.Transform:GetChild(0):LoadPrefab(data:GetAssetPath())
    else
        go = self.GameObject:LoadPrefab(data:GetAssetPath())
    end
    self.UiPanelRecommend:SetUi(go)
    self.UiPanelRecommend:SetData(data, skipFunc, buyFinished)
end

function XUiRecommendGrid:PlayEnableAnim()
    self.UiPanelRecommend:PlayEnableAnim()
end

--######################## XUiPurchaseRecommend ########################
local XUiPurchaseRecommend = XClass(nil, "XUiPurchaseRecommend")

function XUiPurchaseRecommend:Ctor(ui, rootUi, skipFunc)
    XUiHelper.InitUiClass(self, ui)
    self.PurchaseManager = XDataCenter.PurchaseManager
    self.RecommendManager = self.PurchaseManager.GetRecommendManager()
    self.Recommends = nil
    self.CurrentIndex = 1
    self.RootUi = rootUi
    self.SkipFunc = skipFunc
    self.DynamicTable = XDynamicTableCurve.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiRecommendGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridPanel.gameObject:SetActiveEx(false)
end

function XUiPurchaseRecommend:OnRefresh(uiType)
    self:ShowPanel()
    -- 页签按钮
    self.Recommends = self.RecommendManager:GetRecommends()
    if #self.Recommends <= 0 then
        local index = self.RootUi:GetTabIndexByTabType(XPurchaseConfigs.TabsConfig.Recommend)
        local button = self.RootUi.TabGroup:GetButtonByIndex(index)
        button.gameObject:SetActiveEx(false)
        self.SkipFunc(XPurchaseConfigs.TabsConfig.LB)
        return
    end
    local btns = {}
    XUiHelper.RefreshCustomizedList(self.PanelTabGroup.transform, self.BtnTab, #self.Recommends, function(index, child)
        local button = child:GetComponent("XUiButton")
        local uiObject = child:GetComponent("UiObject")
        local recommend = self.Recommends[index]
        local timeTip = recommend:GetLeaveTimeTip()
        button:SetNameByGroup(0, recommend:GetName())
        button:SetNameByGroup(1, timeTip)
        button:SetNameByGroup(2, timeTip)
        local isRare = recommend:GetIsRare()
        local isShowTimeTip = recommend:GetIsShowTimeTip()
        uiObject:GetObject("PanelCountdownNormal").gameObject:SetActiveEx(not isRare and isShowTimeTip)
        uiObject:GetObject("PanelCountdownPress").gameObject:SetActiveEx(not isRare and isShowTimeTip)
        uiObject:GetObject("PanelCountdownSelect").gameObject:SetActiveEx(not isRare and isShowTimeTip)
        uiObject:GetObject("PanelLimitNormal").gameObject:SetActiveEx(isRare and isShowTimeTip)
        uiObject:GetObject("PanelLimitPress").gameObject:SetActiveEx(isRare and isShowTimeTip)
        uiObject:GetObject("PanelLimitSelect").gameObject:SetActiveEx(isRare and isShowTimeTip)
        button:ShowReddot(recommend:GetIsShowRedPoint())
        table.insert(btns, button)
    end)
    self.PanelTabGroup:Init(btns, function(tabIndex)
        self:OnBtnTabClicked(tabIndex)
    end)
    if #btns > 0 then
        -- 数组越界处理
        if self.CurrentIndex > #btns then self.CurrentIndex = #btns end
        self.PanelTabGroup:SelectIndex(self.CurrentIndex)
    end
    -- 刷新推荐
    self.DynamicTable:SetDataSource(self.Recommends)
    self.DynamicTable:ReloadData(self.CurrentIndex - 1)
end

function XUiPurchaseRecommend:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.DynamicTable.DataSource[index + 1], self.SkipFunc, function()
            self:OnRefresh()
        end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        if self.DynamicTable:GetTweenIndex() == self.CurrentIndex - 1 then
            return
        end
        self.CurrentIndex = self.DynamicTable:GetTweenIndex() + 1
        self.PanelTabGroup:SelectIndex(self.CurrentIndex)
    end
end

function XUiPurchaseRecommend:ShowPanel()
    self.GameObject:SetActiveEx(true)
    if self.RootUi.PanelTjTabEx then
        self.RootUi.PanelTjTabEx.gameObject:SetActiveEx(true)
    end
end

function XUiPurchaseRecommend:HidePanel()
    self.GameObject:SetActiveEx(false)
    if self.RootUi.PanelTjTabEx then
        self.RootUi.PanelTjTabEx.gameObject:SetActiveEx(false)
    end
end

function XUiPurchaseRecommend:OnBtnTabClicked(index)
    self.CurrentIndex = index
    local recommend = self.Recommends[index]
    recommend:SetShowRedPoint()
    self.DynamicTable:TweenToIndex(index - 1)
    local button = self.PanelTabGroup:GetButtonByIndex(index)
    button:ShowReddot(false)
    XEventManager.DispatchEvent(XEventId.EVENT_PURCHASE_RECOMMEND_RED)
    local isActiveSellOut = recommend:GetIsSellOut()
    if isActiveSellOut then
        self.RootUi.ImgSellOutDisable:Stop()
        self.RootUi.ImgSellOutEnable.time = 0
        self.RootUi.ImgSellOutEnable:Play()
    else
        if self._LastActiveSellOut then
            self.RootUi.ImgSellOutEnable:Stop()
            self.RootUi.ImgSellOutDisable.time = 0
            self.RootUi.ImgSellOutDisable:Play()
        end
    end
    self._LastActiveSellOut = isActiveSellOut
    local grid = self.DynamicTable:GetGridByIndex(index - 1)
    if grid then
        grid:PlayEnableAnim()
    end
end

function XUiPurchaseRecommend:RefreshTimeData()
    if self.Recommends == nil then return end
    for i, _ in ipairs(self.Recommends) do
        local button = self.PanelTabGroup:GetButtonByIndex(i)
        local timeTip = self.Recommends[i]:GetLeaveTimeTip()
        button:SetNameByGroup(1, timeTip)
        button:SetNameByGroup(2, timeTip)
        if not self.Recommends[i]:GetIsInTime() then
            self:OnRefresh()
            break
        end
    end
end

return XUiPurchaseRecommend