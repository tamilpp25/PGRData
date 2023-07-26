local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local DECOMPOSE_PARTNER_QUALITY = 2 --超过（包含）这个品质的伙伴分解时需要二次确认
local DECOMPOSE_SECOND_CHECK_EQUIP_STAR = 4 --超过（包含）这个星星的装备分解时需要二次确认
local RECYCLE_SECOND_CHECK_EQUIP_STAR = 5 --超过（包含）这个星星的装备回收时需要二次确认
local SECOND_CHECK_ITEM_QUALITY = 5 --超过（包含）这个品质的物品出售时需要二次确认
local TOG_INDEX_TO_STAR_CHECK_DIC = {
    [1] = {
        [1] = true,
        [2] = true,
        [3] = true,
    },
    [2] = {
        [4] = true,
    },
    [3] = {
        [5] = true,
    },
}

local XUiPanelSidePopUp = XClass(nil, "XUiPanelSidePopUp")

function XUiPanelSidePopUp:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self.SelectCount = 0

    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:InitDynamicTable()

    self.GridCommonPopUp.gameObject:SetActiveEx(false)
end

function XUiPanelSidePopUp:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTablePopUp)
    self.DynamicTable:SetProxy(XUiGridCommon)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelSidePopUp:UpdateDynamicTable(bReload)
    self.DynamicTable:SetDataSource(self.Rewards)
    self.DynamicTable:ReloadDataASync(bReload and 1 or -1)
end

function XUiPanelSidePopUp:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.Parent)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.Rewards[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        XLuaUiManager.Open("UiTip", self.Rewards[index])
    end
end

function XUiPanelSidePopUp:Refresh()
    if self.Parent.Operation == self.Parent.OperationType.Common then
        self.Parent:PlayAnimation("AnimChuShouDisable", function()
            self.CurState = false
            self.GameObject:SetActiveEx(false)
        end)
    else
        if self.Parent.Operation == self.Parent.OperationType.Decomposion then
            self.PanelNumBtn.gameObject:SetActiveEx(false)
            self.PanelSellPopUp.gameObject:SetActiveEx(false)
            self.PanelConvertPopUp.gameObject:SetActiveEx(false)
            self.TxtTitle.text = CS.XTextManager.GetText("DecomposeTitle")
            self.PanelRecycle.gameObject:SetActiveEx(false)
            self.PanelDecomposionPopUp.gameObject:SetActiveEx(true)
            self.PanelFilterPopUp.gameObject:SetActiveEx(true)
            self.PanelSelectNum.gameObject:SetActiveEx(true)
            self.PanelSelectNum2.gameObject:SetActiveEx(false)

            --再次打开侧边栏时toggle清空选中状态
            for i = 1, #TOG_INDEX_TO_STAR_CHECK_DIC do
                self["TogStar" .. i .. "PopUp"].isOn = false
            end

            self:RefreshDecomposionPreView(self.Parent.SelectList)
        elseif self.Parent.Operation == self.Parent.OperationType.PartnerDecomposion then
            self.PanelNumBtn.gameObject:SetActiveEx(false)
            self.PanelSellPopUp.gameObject:SetActiveEx(false)
            self.PanelConvertPopUp.gameObject:SetActiveEx(false)
            self.TxtTitle.text = CS.XTextManager.GetText("DecomposeTitle")
            self.PanelRecycle.gameObject:SetActiveEx(false)
            self.PanelDecomposionPopUp.gameObject:SetActiveEx(true)
            self.PanelFilterPopUp.gameObject:SetActiveEx(false)
            self.PanelSelectNum.gameObject:SetActiveEx(true)
            self.PanelSelectNum2.gameObject:SetActiveEx(false)

            self:RefreshPartnerDecomposionPreView(self.Parent.SelectList)
        elseif self.Parent.Operation == self.Parent.OperationType.Recycle then
            self:CheckFirstOpenHelp()
            self.PanelNumBtn.gameObject:SetActiveEx(false)
            self.PanelSellPopUp.gameObject:SetActiveEx(false)
            self.PanelConvertPopUp.gameObject:SetActiveEx(false)
            self.TxtTitle.text = CS.XTextManager.GetText("RecycleTitle")
            self.PanelDecomposionPopUp.gameObject:SetActiveEx(false)
            self.PanelRecycle.gameObject:SetActiveEx(true)
            self.PanelFilterPopUp.gameObject:SetActiveEx(true)
            self.PanelSelectNum.gameObject:SetActiveEx(false)
            self.PanelSelectNum2.gameObject:SetActiveEx(true)

            --再次打开侧边栏时toggle清空选中状态
            for i = 1, #TOG_INDEX_TO_STAR_CHECK_DIC do
                self["TogStar" .. i .. "PopUp"].isOn = false
            end

            self:RefreshRecyclePreView(self.Parent.SelectList)
        else
            if self.Parent.Operation == self.Parent.OperationType.Sell then
                self.PanelConvertPopUp.gameObject:SetActiveEx(false)
                self.TxtTitle.text = CS.XTextManager.GetText("SellTitle")
                self.PanelSellPopUp.gameObject:SetActiveEx(true)
                self.PanelNumBtn.gameObject:SetActiveEx(true)
                self.PanelSelectNum.gameObject:SetActiveEx(false)
                self:RefreshSellPreView()
            elseif self.Parent.Operation == self.Parent.OperationType.Convert then
                self.PanelSellPopUp.gameObject:SetActiveEx(false)
                self.TxtTitle.text = CS.XTextManager.GetText("ConverseTitle")
                self.PanelConvertPopUp.gameObject:SetActiveEx(true)
                self.PanelNumBtn.gameObject:SetActiveEx(false)
                self.PanelSelectNum.gameObject:SetActiveEx(true)
                self:RefreshConvertPreView(self.Parent.SelectList, 0)
            end
            self.PanelDecomposionPopUp.gameObject:SetActiveEx(false)
            self.PanelRecycle.gameObject:SetActiveEx(false)
            self.PanelFilterPopUp.gameObject:SetActiveEx(false)
            self.PanelSelectNum2.gameObject:SetActiveEx(false)
        end
        self.GameObject:SetActiveEx(true)
        self.CurState = true
        self.Parent:PlayAnimation("AnimChuShouEnable")
    end
end

function XUiPanelSidePopUp:RefreshDecomposionPreView(selectEquipIds, cancelStar)
    self.SelectEquipIds = {}
    if selectEquipIds then
        for _, equipId in pairs(selectEquipIds) do
            table.insert(self.SelectEquipIds, equipId)
        end
    end

    self.TxtSelectNum.text = #self.SelectEquipIds

    local listEmpty = not next(self.SelectEquipIds)
    self.ImgCantDecomposionPopUp.gameObject:SetActiveEx(listEmpty)
    self.BtnDecomposionPopUp.gameObject:SetActiveEx(not listEmpty)

    self.Rewards = XDataCenter.EquipManager.GetDecomposeRewards(self.SelectEquipIds)
    if #self.Rewards == 1 then
        if not self.SingleItemGrid then
            local ui = CSUnityEngineObjectInstantiate(self.GridCommonPopUp, self.Transform)
            self.SingleItemGrid = XUiGridCommon.New(self.Parent, ui)
        end

        self.SingleItemGrid:Refresh(self.Rewards[1])
        self.SingleItemGrid.GameObject:SetActiveEx(true)
        self.PanelDynamicTablePopUp.gameObject:SetActiveEx(false)

        CsXUiHelper.RegisterClickEvent(self.SingleItemGrid.RImgIcon, function()
            XLuaUiManager.Open("UiTip", self.Rewards[1])
        end, true)
    else
        self:UpdateDynamicTable()

        if self.SingleItemGrid then
            self.SingleItemGrid.GameObject:SetActiveEx(false)
        end
        self.PanelDynamicTablePopUp.gameObject:SetActiveEx(true)
    end

    --取消选中时星星筛选tog状态置false
    if cancelStar then
        for togIndex, starCheckTable in pairs(TOG_INDEX_TO_STAR_CHECK_DIC) do
            if starCheckTable[cancelStar] then
                local tog = self["TogStar" .. togIndex .. "PopUp"]
                if tog then
                    tog.isOn = false
                end
            end
        end
    end

end

function XUiPanelSidePopUp:RefreshPartnerDecomposionPreView(selectPartner)
    self.SelectPartnerList = {}
    if selectPartner then
        for _, partner in pairs(selectPartner) do
            table.insert(self.SelectPartnerList, partner)
        end
    end

    self.TxtSelectNum.text = #self.SelectPartnerList

    local listEmpty = not next(self.SelectPartnerList)
    self.ImgCantDecomposionPopUp.gameObject:SetActiveEx(listEmpty)
    self.BtnDecomposionPopUp.gameObject:SetActiveEx(not listEmpty)

    self.Rewards = XDataCenter.PartnerManager.GetPartnerDecomposeRewards(self.SelectPartnerList)
    if #self.Rewards == 1 then
        if not self.SingleItemGrid then
            local ui = CSUnityEngineObjectInstantiate(self.GridCommonPopUp, self.Transform)
            self.SingleItemGrid = XUiGridCommon.New(self.Parent, ui)
        end

        self.SingleItemGrid:Refresh(self.Rewards[1])
        self.SingleItemGrid.GameObject:SetActiveEx(true)
        self.PanelDynamicTablePopUp.gameObject:SetActiveEx(false)

        CsXUiHelper.RegisterClickEvent(self.SingleItemGrid.RImgIcon, function()
            XLuaUiManager.Open("UiTip", self.Rewards[1])
        end, true)
    else
        self:UpdateDynamicTable()

        if self.SingleItemGrid then
            self.SingleItemGrid.GameObject:SetActiveEx(false)
        end
        self.PanelDynamicTablePopUp.gameObject:SetActiveEx(true)
    end
end

function XUiPanelSidePopUp:RefreshRecyclePreView(selectEquipIds, cancelStar)
    self.SelectEquipIds = {}
    if selectEquipIds then
        for _, equipId in pairs(selectEquipIds) do
            table.insert(self.SelectEquipIds, equipId)
        end
    end

    self.TxtSelectNum2.text = #self.SelectEquipIds

    local listEmpty = not next(self.SelectEquipIds)
    self.ImgCantRecycle.gameObject:SetActiveEx(listEmpty)
    self.BtnRecycle.gameObject:SetActiveEx(not listEmpty)

    self.Rewards = XDataCenter.EquipManager.GetRecycleRewards(self.SelectEquipIds)
    if #self.Rewards == 1 then
        if not self.SingleItemGrid then
            local ui = CSUnityEngineObjectInstantiate(self.GridCommonPopUp, self.Transform)
            self.SingleItemGrid = XUiGridCommon.New(self.Parent, ui)
        end

        self.SingleItemGrid:Refresh(self.Rewards[1])
        self.SingleItemGrid.GameObject:SetActiveEx(true)
        self.PanelDynamicTablePopUp.gameObject:SetActiveEx(false)

        CsXUiHelper.RegisterClickEvent(self.SingleItemGrid.RImgIcon, function()
            XLuaUiManager.Open("UiTip", self.Rewards[1])
        end, true)

    else
        self:UpdateDynamicTable()

        if self.SingleItemGrid then
            self.SingleItemGrid.GameObject:SetActiveEx(false)
        end
        self.PanelDynamicTablePopUp.gameObject:SetActiveEx(true)
    end

    --取消选中时星星筛选tog状态置false
    if cancelStar then
        for togIndex, starCheckTable in pairs(TOG_INDEX_TO_STAR_CHECK_DIC) do
            if starCheckTable[cancelStar] then
                local tog = self["TogStar" .. togIndex .. "PopUp"]
                if tog then
                    tog.isOn = false
                end
            end
        end
    end

end

function XUiPanelSidePopUp:RefreshConvertPreView(selectFragmentIds, count)
    self.SelectFragmentIdAndCount = {}
    count = count or 0
    self.FragmentCount = self.FragmentCount and self.FragmentCount + count or count
    if selectFragmentIds then
        for fragmentId, count in pairs(selectFragmentIds) do
            self.SelectFragmentIdAndCount[fragmentId] = count
        end
    end

    self.TxtSelectNum.text = self.FragmentCount

    local isEmpty = not next(self.SelectFragmentIdAndCount)
    self.ImgCantConvertPopUp.gameObject:SetActiveEx(isEmpty)
    self.BtnConvertPopUp.gameObject:SetActiveEx(not isEmpty)
    
    self.Rewards = XDataCenter.ItemManager.GetSellRewards(self.SelectFragmentIdAndCount)
    if #self.Rewards == 1 then
        if not self.SingleItemGrid then
            local ui = CSUnityEngineObjectInstantiate(self.GridCommonPopUp, self.Transform)
            self.SingleItemGrid = XUiGridCommon.New(self.Parent, ui)
        end

        self.SingleItemGrid:Refresh(self.Rewards[1])
        self.SingleItemGrid.GameObject:SetActiveEx(true)
        self.PanelDynamicTablePopUp.gameObject:SetActiveEx(false)

        CsXUiHelper.RegisterClickEvent(self.SingleItemGrid.RImgIcon, function()
            XLuaUiManager.Open("UiTip", self.Rewards[1])
        end, true)

    else
        self:UpdateDynamicTable()

        if self.SingleItemGrid then
            self.SingleItemGrid.GameObject:SetActiveEx(false)
        end
        self.PanelDynamicTablePopUp.gameObject:SetActiveEx(true)
    end

end

function XUiPanelSidePopUp:ClearData()
    self.SelectItemId = nil
    self.SelectCount = nil
    self.SelectGrid = nil
    self.FragmentCount = nil
end

function XUiPanelSidePopUp:RefreshSellPreView(selectItemId, count, selectGrid)
    self.SelectItemId = selectItemId or self.SelectItemId
    self.SelectCount = count or self.SelectCount
    self.SelectGrid = selectGrid or self.SelectGrid
    self.GridMaxCount = self.SelectGrid and self.SelectGrid:GetGridCount() or self.GridMaxCount

    local cantSell = not self.SelectItemId or not self.SelectCount or self.SelectCount == 0
    if self.Parent.Operation == self.Parent.OperationType.Sell then
        self.BtnSellPopUp.gameObject:SetActiveEx(not cantSell)
        self.ImgCantSellPopUp.gameObject:SetActiveEx(cantSell)
    elseif self.Parent.Operation == self.Parent.OperationType.Convert then
        self.BtnConvertPopUp.gameObject:SetActiveEx(not cantSell)
        self.ImgCantConvertPopUp.gameObject:SetActiveEx(cantSell)
    end
    self.TxtNum.text = self.SelectCount

    local showSub = self.SelectCount ~= 0
    self.BtnSub.gameObject:SetActiveEx(showSub)
    self.ImgCantSub.gameObject:SetActiveEx(not showSub)

    local showAdd = self.SelectItemId and (not self.GridMaxCount or self.SelectCount ~= self.GridMaxCount)
    self.BtnAdd.gameObject:SetActiveEx(showAdd)
    self.ImgCantAdd.gameObject:SetActiveEx(not showAdd)

    local reward = XDataCenter.ItemManager.GetSellReward(self.SelectItemId, self.SelectCount)
    if not next(reward) then
        if self.SingleItemGrid then
            self.SingleItemGrid.GameObject:SetActiveEx(false)
        end
    else
        if not self.SingleItemGrid then
            local ui = CSUnityEngineObjectInstantiate(self.GridCommonPopUp, self.Transform)
            self.SingleItemGrid = XUiGridCommon.New(self.Parent, ui)
        end
        self.SingleItemGrid:Refresh(reward)
        self.SingleItemGrid.GameObject:SetActiveEx(true)
    end
    self.PanelDynamicTablePopUp.gameObject:SetActiveEx(false)
end

function XUiPanelSidePopUp:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelSidePopUp:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelSidePopUp:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelSidePopUp:AutoAddListener()
    self:RegisterClickEvent(self.TogStar1PopUp, self.OnTogStar1PopUpClick)
    self:RegisterClickEvent(self.TogStar2PopUp, self.OnTogStar2PopUpClick)
    self:RegisterClickEvent(self.TogStar3PopUp, self.OnTogStar3PopUpClick)
    self:RegisterClickEvent(self.BtnSub, self.OnBtnSubClick)
    self:RegisterClickEvent(self.BtnAdd, self.OnBtnAddClick)
    self:RegisterClickEvent(self.BtnMax, self.OnBtnMaxClick)
    self:RegisterClickEvent(self.BtnSellPopUp, self.OnBtnSellPopUpClick)
    self:RegisterClickEvent(self.BtnDecomposionPopUp, self.OnBtnDecomposionPopUpClick)
    self:RegisterClickEvent(self.BtnRecycle, self.OnBtnRecycleClick)
    self:RegisterClickEvent(self.BtnRecycleSet, self.OnBtnRecycleSetClick)
    self:RegisterClickEvent(self.BtnConvertPopUp, self.OnBtnConvertPopUpClick)
    self:RegisterClickEvent(self.BtnCha, self.OnBtnChaClick)
end

function XUiPanelSidePopUp:OnBtnSubClick()
    if not self.SelectCount then return end
    self:RefreshSellPreView(self.SelectItemId, self.SelectCount - 1)
end

function XUiPanelSidePopUp:OnBtnAddClick()
    if not self.SelectCount then return end
    self:RefreshSellPreView(self.SelectItemId, self.SelectCount + 1)
end

function XUiPanelSidePopUp:OnBtnMaxClick()
    if not self.SelectItemId then return end
    self:RefreshSellPreView(self.SelectItemId, self.SelectGrid:GetGridCount())
end

function XUiPanelSidePopUp:OnTogStar1PopUpClick()
    self.Parent:SelectByStar(TOG_INDEX_TO_STAR_CHECK_DIC[1], self.TogStar1PopUp.isOn, true)
end

function XUiPanelSidePopUp:OnTogStar2PopUpClick()
    self.Parent:SelectByStar(TOG_INDEX_TO_STAR_CHECK_DIC[2], self.TogStar2PopUp.isOn, true)
end

function XUiPanelSidePopUp:OnTogStar3PopUpClick()
    self.Parent:SelectByStar(TOG_INDEX_TO_STAR_CHECK_DIC[3], self.TogStar3PopUp.isOn, true)
end

function XUiPanelSidePopUp:OnBtnSellPopUpClick()
    if not self.SelectItemId or not self.SelectCount or self.SelectCount == 0 then return end

    local sellFunc = function()
        local datas = {[self.SelectItemId] = self.SelectCount }
        XDataCenter.ItemManager.Sell(datas, function(rewardGoodDic)
            self.Parent:OperationTurn(self.Parent.OperationType.Sell)

            local rewards = {}
            for key, value in pairs(rewardGoodDic) do
                table.insert(rewards, { TemplateId = key, Count = value })
            end
            XUiManager.OpenUiObtain(rewards)
        end)
    end

    local quality = XDataCenter.ItemManager.GetItemQuality(self.SelectItemId)
    if quality >= SECOND_CHECK_ITEM_QUALITY then
        local title = CS.XTextManager.GetText("SellConfirmTitle")
        local content = CS.XTextManager.GetText("SellConfirmTip")

        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
            sellFunc()
        end)

        return
    end

    sellFunc()
end

function XUiPanelSidePopUp:OnBtnDecomposionPopUpClick()
    if self.Parent.Operation == self.Parent.OperationType.PartnerDecomposion then
        self:PartnerDecomposionPopUpClick()
    else
        self:EqualDecomposionPopUpClick()
    end
end

function XUiPanelSidePopUp:EqualDecomposionPopUpClick()
    local callFunc = function()
        XMVCA:GetAgency(ModuleId.XEquip):EquipDecompose(self.SelectEquipIds, function(rewardGoodsList)
            self.Parent:OperationTurn(self.Parent.OperationType.Decomposion)
            if (#rewardGoodsList > 0) then
                XUiManager.OpenUiObtain(rewardGoodsList)
            end
        end)
    end

    for _, equipId in pairs(self.SelectEquipIds) do
        local equip = XDataCenter.EquipManager.GetEquip(equipId)
        local star = XDataCenter.EquipManager.GetEquipStar(equip.TemplateId)

        if star >= DECOMPOSE_SECOND_CHECK_EQUIP_STAR then
            local title = CS.XTextManager.GetText("DecomposeConfirmTitle")
            local content = CS.XTextManager.GetText("DecomposeConfirmTip")

            XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
                callFunc()
            end)

            return
        end
    end

    callFunc()
end

function XUiPanelSidePopUp:PartnerDecomposionPopUpClick()
    local IsNeedDialog = false
    local idList = {}

    for _, partner in pairs(self.SelectPartnerList or {}) do
        if partner:GetQuality() >= DECOMPOSE_PARTNER_QUALITY then
            IsNeedDialog = true
        end
        table.insert(idList, partner:GetId())
    end

    if IsNeedDialog then
        local title = CS.XTextManager.GetText("DecomposePartnerConfirmTitle")
        local content = CS.XTextManager.GetText("DecomposePartnerConfirmTip")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
            XDataCenter.PartnerManager.PartnerDecomposeRequest(idList, function()
                self.Parent:OperationTurn(self.Parent.OperationType.PartnerDecomposion)
            end)
        end)
    end
end

function XUiPanelSidePopUp:OnBtnRecycleClick()
    local callFunc = function()
        XDataCenter.EquipManager.EquipChipRecycleRequest(self.SelectEquipIds, function(rewardGoodsList)
            self.Parent:OperationTurn(self.Parent.OperationType.Recycle)
            if (#rewardGoodsList > 0) then
                XUiManager.OpenUiObtain(rewardGoodsList)
            end
        end)
    end

    for _, equipId in pairs(self.SelectEquipIds) do
        local equip = XDataCenter.EquipManager.GetEquip(equipId)
        local star = XDataCenter.EquipManager.GetEquipStar(equip.TemplateId)

        if star >= RECYCLE_SECOND_CHECK_EQUIP_STAR then
            local title = CS.XTextManager.GetText("EquipRecycleConfirmTitle")
            local content = CS.XTextManager.GetText("EquipRecycleConfirmTip")

            XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
                callFunc()
            end)

            return
        end
    end

    callFunc()
end

function XUiPanelSidePopUp:OnBtnRecycleSetClick()
    XLuaUiManager.Open("UiRecyclingSettings")
end

function XUiPanelSidePopUp:OnBtnConvertPopUpClick()
    local datas = {}
    if self.Parent.Operation == self.Parent.OperationType.Sell then
        if not self.SelectItemId or not self.SelectCount or self.SelectCount == 0 then return end
        datas = {[self.SelectItemId] = self.SelectCount }
    elseif self.Parent.Operation == self.Parent.OperationType.Convert then
        if not self.SelectFragmentIdAndCount then return end
        for itemId, count in pairs(self.SelectFragmentIdAndCount) do
            datas[itemId] = count
        end
    end
    XDataCenter.ItemManager.Sell(datas, function(rewardGoodDic)
        self.Parent:OperationTurn(self.Parent.OperationType.Convert)

        local rewards = {}
        local rewardType = XRewardManager.XRewardType.Item -- 碎片分解的奖励类型都是item
        for key, value in pairs(rewardGoodDic) do
            table.insert(rewards, { TemplateId = key, RewardType = rewardType, Count = value })
        end
        XUiManager.OpenUiObtain(rewards)
    end)
end

function XUiPanelSidePopUp:OnBtnChaClick()

    self.Parent:OperationTurn(self.Parent.OperationType.Common)
end

function XUiPanelSidePopUp:IsFirstOpen()
    return XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "IsAlreadyOpenPanelSidePopUp")) or false
end

function XUiPanelSidePopUp:CheckFirstOpenHelp()
    if not XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "IsAlreadyOpenPanelSidePopUp")) then
        XUiManager.ShowHelpTip("UiBagHelp")
        XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "IsAlreadyOpenPanelSidePopUp"), true)
    end
end

return XUiPanelSidePopUp