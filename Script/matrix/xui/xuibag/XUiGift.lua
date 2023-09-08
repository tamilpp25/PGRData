-- Author: copy from Matrix\XUi\XUiBag\XUiPanelSelectGift.lua
local XUiGift = XLuaUiManager.Register(XLuaUi, "UiGift")

function XUiGift:OnAwake()
    self:InitButton()
    self.RewardItems = {}
end

function XUiGift:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClearSelection, self.OnBtnClearSelectionClick)
end

function XUiGift:OnStart(itemId)
    self.ItemId = itemId
end

function XUiGift:OnEnable()
    self:Refresh()
end

function XUiGift:Refresh()
    local id = self.ItemId
    self.RewardId = XDataCenter.ItemManager.GetSelectGiftRewardId(id)


    self.GridDatas = {}
    local rewardItems = XRewardManager.GetRewardList(self.RewardId)
    for index, data in pairs(rewardItems) do
        table.insert(self.GridDatas, { Data = data, GridIndex = index })
    end

    local onCreate = function(item, data)
        item:Refresh(data, false, true, true)

        item:SetOwnedStatus(XRewardManager.CheckRewardOwn(data.Data.RewardType, data.Data.TemplateId))
    end
    self.GridRewardItem.gameObject:SetActiveEx(false)
    XUiHelper.CreateTemplates(self, self.RewardItems, self.GridDatas, XUiGridSelectGift.New, self.GridRewardItem.gameObject, self.PanelReward, onCreate)

    local count = #self.GridDatas
    local grid
    for i = 1, count do
        grid = self.RewardItems[i]
        if grid then
            grid:SetClickCallback(function(gridData, tmpGrid)
                self:SelectRewardGrid(gridData, tmpGrid)
            end)

            local gridData = self.GridDatas[i].Data
            grid:SetClickCallback2(function()
                self:OpenDetailUi(gridData)
            end)
        end

    end

    self.SelectGridIndexs = {}
    self.SelectCount = 0
    self.LastSelectGrid = nil
    local template = XDataCenter.ItemManager.GetItem(id).Template
    self.SupposedCount = template.SelectCount

    self.TxtGiftName.text = template.Name
    self.TxtCanSelectNum.text = CS.XTextManager.GetText("SelectGiftCount", template.SelectCount)
    self.TxtGfitCount.text = CS.XTextManager.GetText("ItemHaveSelectedCount", self.SelectCount, self.SupposedCount)

    self.GameObject:SetActiveEx(true)
    self.PanelCantConfirm.gameObject:SetActiveEx(self.SelectCount ~= self.SupposedCount)
    self.BtnConfirm.gameObject:SetActiveEx(self.SelectCount == self.SupposedCount)
    -- self.RootUi:PlayAnimation("AnimSelectGiftEnable")

    if not self.IsInitPc then
        XDataCenter.UiPcManager.OnUiEnable(self)
        self.IsInitPc = true
    end
end

function XUiGift:SelectRewardGrid(gridData, grid)
    local id = gridData.Data.TemplateId
    if not self.SelectGridIndexs[id] then
        if self.SupposedCount == 1 then
            if self.LastSelectGrid then
                self.SelectGridIndexs = {}
                self.LastSelectGrid:SetSelectState(false)
                self.SelectCount = 0
            end
            self.LastSelectGrid = grid
        else
            if self.SelectCount >= self.SupposedCount then
                XUiManager.TipText("SelectGiftMaxCount")
                return
            end
        end
        self.SelectCount = self.SelectCount + 1
        self.SelectGridIndexs[id] = gridData.GridIndex
        grid:SetSelectState(true)
    else
        self.SelectCount = self.SelectCount - 1
        self.SelectGridIndexs[id] = nil
        grid:SetSelectState(false)
    end

    self.TxtGfitCount.text = CS.XTextManager.GetText("ItemHaveSelectedCount", self.SelectCount, self.SupposedCount)
    self.BtnConfirm.gameObject:SetActiveEx(self.SelectCount == self.SupposedCount)
    self.PanelCantConfirm.gameObject:SetActiveEx(self.SelectCount ~= self.SupposedCount)
end

function XUiGift:OpenDetailUi(data)
    if data.RewardType == XRewardManager.XRewardType.Character then
        XLuaUiManager.Open("UiCharacterDetail", data.TemplateId)
    elseif data.RewardType == XRewardManager.XRewardType.Equip then
        XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipPreview(data.TemplateId)
    elseif data.RewardType == XRewardManager.XRewardType.Fashion then
        XLuaUiManager.Open("UiFashionDetail", data.TemplateId, false, nil)
    elseif data.RewardType == XRewardManager.XRewardType.Partner then
        local partnerData = {Id = 0,TemplateId = data.TemplateId}
        local partner = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData, true)
        XLuaUiManager.Open("UiPartnerPreview", partner)
    else
        if XDataCenter.ItemManager.IsWeaponFashion(data.TemplateId) then
            local weaponFashionId = XDataCenter.ItemManager.GetWeaponFashionId(data.TemplateId)
            XLuaUiManager.Open("UiFashionDetail", weaponFashionId, true, nil)
        else
            XLuaUiManager.Open("UiTip", data, true)
        end
    end
end

function XUiGift:HandleConfirmClick(itemId ,rewardIds, rewardHasOwnTypeList)
    local handle = function()

        local weaponFashionTemplateIdList = {}
        --如果武器涂装增加了时间，则循环提示
        local loopTips
        loopTips = function()
            if #weaponFashionTemplateIdList > 0 then
                local currentRewardTemplateId = table.remove(weaponFashionTemplateIdList)
                --判断是不是武器涂装类型
                local weaponFashionId = XDataCenter.ItemManager.GetWeaponFashionId(currentRewardTemplateId)
                local weaponFashion = XDataCenter.WeaponFashionManager.GetWeaponFashion(weaponFashionId)
                local time = XDataCenter.ItemManager.GetWeaponFashionAddTime(currentRewardTemplateId)
                if weaponFashion and weaponFashion:IsTimeLimit() and time then
                    --此时提示叠加时长信息
                    local addTime = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.DEFAULT)
                    local weaponFashionId = XDataCenter.ItemManager.GetWeaponFashionId(currentRewardTemplateId)
                    local weaponFashionName = XDataCenter.WeaponFashionManager.GetWeaponFashionName(weaponFashionId)
                    local descStr = CsGetText("WeaponFashionLimitGetAlreadyHaveLimit", weaponFashionName, addTime)
                    XUiManager.TipMsg(descStr, nil, loopTips)
                end
            else
                return 
            end
        end

        local callback = function(rewardGoodsList)
            local resultGoodsList = {}
            --如果武器涂装增加了时间，则逐条显示遍历
            local isNotifyWeaponFashionTransform = XDataCenter.WeaponFashionManager.GetIsNotifyWeaponFashionTransform()
            weaponFashionTemplateIdList = {}
            for _, rewardGoodsId in pairs(rewardGoodsList) do
                if XDataCenter.ItemManager.IsWeaponFashion(rewardGoodsId.TemplateId) and isNotifyWeaponFashionTransform then
                    table.insert(weaponFashionTemplateIdList, rewardGoodsId.TemplateId)
                else
                    table.insert(resultGoodsList, rewardGoodsId)
                end
            end

            XDataCenter.WeaponFashionManager.ResetIsNotifyWeaponFashionTransform()

            if #resultGoodsList > 0 then
                XUiManager.OpenUiObtain(resultGoodsList)
            end
            loopTips(weaponFashionTemplateIdList)
        end

        XDataCenter.ItemManager.Use(itemId, nil, 1, callback, rewardIds)
        self:Close()
    end

    local confirmCallback
    local confirmLoop
    confirmCallback = function()
        if #rewardHasOwnTypeList > 0 then
            if confirmLoop then
                confirmLoop()
            end
        else
            handle()
        end
    end
    confirmLoop = function()        
        local tab = table.remove(rewardHasOwnTypeList)
        if XDataCenter.ItemManager.IsWeaponFashion(tab.templateId) then
            local weaponFashionId = XDataCenter.ItemManager.GetWeaponFashionId(tab.templateId)
            local time = XDataCenter.ItemManager.GetWeaponFashionAddTime(tab.templateId)
            local weaponFashion = XDataCenter.WeaponFashionManager.GetWeaponFashion(weaponFashionId)
            local title = CsGetText("WeaponFashionGetTitleInfo")
            local msg
            --判断武器时装是不是永久的
            if weaponFashion and weaponFashion:IsTimeLimit() then
                if not time then
                    msg = CsGetText("WeaponFashionForeverGetAlreadyHaveLimit")
                else
                    confirmCallback()
                    return
                end
            else
                if not time then
                    msg = CsGetText("WeaponFashionForeverGetAlreadyHaveForever")
                else
                    msg = CsGetText("WeaponFashionLimitGetAlreadyHaveForever")
                end
            end
            
            XUiManager.DialogTip(
                title,
                msg,
                XUiManager.DialogType.Normal,
                nil,
                confirmCallback
            )
        else
            local template = XRewardConfigs.GetRewardConfirmTemplate(tab.type)
            local title = template.Title
            local msg = template.Content
            XUiManager.DialogTip(
                title,
                msg,
                XUiManager.DialogType.Normal,
                nil,
                confirmCallback
            )
        end
    end

    if rewardHasOwnTypeList then
        table.sort(rewardHasOwnTypeList, function(a, b)
            local aTemplate = XRewardConfigs.GetRewardConfirmTemplate(a.type)
            local bTemplate = XRewardConfigs.GetRewardConfirmTemplate(b.type)
            local aPriority = aTemplate and aTemplate.Priority or 1
            local bPriority = bTemplate and bTemplate.Priority or 1
            return aPriority > bPriority
        end)
        confirmLoop()
    else
        handle()
    end
end

function XUiGift:OnBtnConfirmClick()
    if self.SelectCount ~= self.SupposedCount then return end

    local rewardHasOwnTypeDic
    local gridData
    local rewardIds = {}
    for _, index in pairs(self.SelectGridIndexs) do
        table.insert(rewardIds, XRewardManager.GetRewardSubId(self.RewardId, index))
        gridData = self.GridDatas[index].Data
        if XRewardManager.CheckRewardOwn(gridData.RewardType, gridData.TemplateId) then
            rewardHasOwnTypeDic = rewardHasOwnTypeDic or {}
            rewardHasOwnTypeDic[gridData.RewardType] = gridData.TemplateId
        end
    end

    local rewardHasOwnTypeList
    if rewardHasOwnTypeDic then
        rewardHasOwnTypeList = {}
        for type, templateId in pairs(rewardHasOwnTypeDic) do
            local tab = {}
            tab.type = type
            tab.templateId = templateId
            table.insert(rewardHasOwnTypeList, tab)
        end
    end
    self:HandleConfirmClick(self.ItemId, rewardIds, rewardHasOwnTypeList)
end

function XUiGift:OnBtnClearSelectionClick()
    for _, index in pairs(self.SelectGridIndexs)do
        self:SelectRewardGrid(self.GridDatas[index], self.RewardItems[index])
    end
    self.PanelCantConfirm.gameObject:SetActiveEx(self.SelectCount ~= self.SupposedCount)
    self.BtnConfirm.gameObject:SetActiveEx(self.SelectCount == self.SupposedCount)
end

function XUiGift:OnBtnBackClick()
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
    self.IsInitPc = false
    self:Close()
end

return XUiGift