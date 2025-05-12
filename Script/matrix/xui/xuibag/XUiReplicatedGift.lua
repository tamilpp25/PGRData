local XUiGridSelectReplicatedGift = require("XUi/XUiBag/XUiGridSelectReplicatedGift")
-- Author: copy from Matrix\XUi\XUiBag\XUiReplicatedGift.lua
local XUiReplicatedGift = XLuaUiManager.Register(XLuaUi, "UiReplicatedGift")

function XUiReplicatedGift:OnAwake()
    self:InitButton()

    self.RewardItemList = {}
    self.CategoryCount = 0
    self.CurSelectCount = 0
    self.MaxSelectCount = 0
end

function XUiReplicatedGift:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnBtnConfirmClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClearSelection, self.OnBtnClearSelectionClick)
end

function XUiReplicatedGift:OnStart(itemId, maxSelectCount)
    self.ItemId = itemId
    self.MaxSelectCount = maxSelectCount
end

function XUiReplicatedGift:OnEnable()
    self:Refresh()
end

function XUiReplicatedGift:Refresh()
    local itemId = self.ItemId
    local maxSelectCount = self.MaxSelectCount

    self.CurSelectCount = 0
    self.MaxSelectCount = maxSelectCount

    self.RewardId = XDataCenter.ItemManager.GetSelectGiftRewardId(itemId)
    self.GridDataList = {}
    local rewardDataList = XRewardManager.GetRewardList(self.RewardId)
    for index, data in pairs(rewardDataList) do
        table.insert(self.GridDataList, {Data = data, GridIndex = index})
    end

    local onCreate = function(item, data)
        item:Refresh(data, false, true, true)
        item:SetOwnedStatus(XRewardManager.CheckRewardOwn(data.Data.RewardType, data.Data.TemplateId))
    end

    self.GridRewardItem.gameObject:SetActiveEx(false)
    XUiHelper.CreateTemplates(self, self.RewardItemList, self.GridDataList, XUiGridSelectReplicatedGift.New, self.GridRewardItem.gameObject, self.PanelReward, onCreate)


    local count = #self.GridDataList
    self.CategoryCount = count
    local grid
    for i = 1, count do
        grid = self.RewardItemList[i]
        if grid then
            local gridData = self.GridDataList[i].Data
            grid:SetClickCallback2(function()
                self:OpenDetailUi(gridData, grid)
            end)

            grid:SetChangeSelectCountCondition(function(newCount)
                local isInCount = self:JudgeSelectCondition(i, newCount)
                if not isInCount then
                    XUiManager.TipError(CS.XTextManager.GetText("ItemSelectedCountOverLimit"))
                end
                return isInCount
            end)
            grid:SetSelectLongClickCallBack(function(time)
                if self.CurSelectCount >= self.MaxSelectCount then
                    return 0
                end
                
                local delta = math.max(0, math.floor(time / 150))
                local newCount = self.RewardItemList[i]:GetSelectCount() + delta
                if not self:JudgeSelectCondition(i, newCount) then
                    newCount = self.MaxSelectCount - self.CurSelectCount + self.RewardItemList[i]:GetSelectCount()
                end
                return newCount
            end)
            grid:SetSelectCountChangedCallback(function(deltaCount)
                self:UpdateSelection(deltaCount)
            end)
        end
    end

    local template = XDataCenter.ItemManager.GetItem(itemId).Template
    self.TxtGiftName.text = template.Name
    self.TxtCanSelectNum.text = CS.XTextManager.GetText("SelectReplicatedGiftCount", maxSelectCount)

    self.TxtGfitCount.text = CS.XTextManager.GetText("ItemHaveSelectedCount", self.CurSelectCount, self.MaxSelectCount)
    self:UpdateConfirmStatus()
    -- self:PlayAnimation("AnimSelectReplicatedGift")
    XDataCenter.UiPcManager.OnUiEnable(self)
end

function XUiReplicatedGift:OpenDetailUi(data)
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

function XUiReplicatedGift:JudgeSelectCondition(index, count)
    local deltaCount = count - self.RewardItemList[index]:GetSelectCount()
    return self.CurSelectCount + deltaCount <= self.MaxSelectCount
end

function XUiReplicatedGift:UpdateSelection(deltaCount)
    self.CurSelectCount = self.CurSelectCount + deltaCount
    self.TxtGfitCount.text =  CS.XTextManager.GetText("ItemHaveSelectedCount", self.CurSelectCount, self.MaxSelectCount)
    self:UpdateConfirmStatus()
end

function XUiReplicatedGift:UpdateConfirmStatus()
    self.PanelCantConfirm.gameObject:SetActiveEx(self.CurSelectCount == 0)
    self.BtnConfirm.gameObject:SetActiveEx(self.CurSelectCount ~= 0)
end

function XUiReplicatedGift:HandleConfirmClick(useList, rewardHasOwnTypeList)
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

        XDataCenter.ItemManager.MultiplyUse(useList, callback)
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

function XUiReplicatedGift:OnBtnConfirmClick()
    if self.CurSelectCount == 0 then return end

    local useList = {}

    local grid
    local rewardHasOwnTypeDic
    local count
    local gridData
    local useData
    for index = 1, self.CategoryCount do
        grid = self.RewardItemList[index]
        count = grid:GetSelectCount()

        local rewardId = XRewardManager.GetRewardSubId(self.RewardId, index)
        for _ = 1, count do
            useData = {}
            useData.Id = self.ItemId
            useData.Count = 1
            useData.SelectRewardIds = {}
            table.insert(useData.SelectRewardIds, rewardId)
            table.insert(useList, useData)
        end

        gridData = self.GridDataList[index].Data
        if count > 0 and XRewardManager.CheckRewardOwn(gridData.RewardType, gridData.TemplateId) then
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
    self:HandleConfirmClick(useList, rewardHasOwnTypeList)
end

function XUiReplicatedGift:OnBtnClearSelectionClick()
    for i = 1, self.CategoryCount do
        self.RewardItemList[i]:ClearSelectState()
    end
    self.TxtGfitCount.text = CS.XTextManager.GetText("ItemHaveSelectedCount", self.CurSelectCount, self.MaxSelectCount)
    self:UpdateConfirmStatus()
end

function XUiReplicatedGift:OnBtnBackClick()
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
    self:Close()
end

return XUiReplicatedGift