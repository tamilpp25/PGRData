local XUiPanelSkillDetailsInfoV2P6 = XClass(XUiNode, "XUiPanelSkillDetailsInfoV2P6")

function XUiPanelSkillDetailsInfoV2P6:OnStart(ui, rootUi)
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self.Attribute.gameObject:SetActiveEx(false)
    self.TxtSkillTitle.gameObject:SetActiveEx(false)
    self.MaterialItemDic = {}

    self:InitButton()
end

function XUiPanelSkillDetailsInfoV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnUpgrade, self.OnBtnUpgradeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUnlock, self.OnBtnUnlockClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCoin, self.OnBtnCoinClick)
end

function XUiPanelSkillDetailsInfoV2P6:Refresh(skillGroupIndex)
    self.SkillGroupIndex = skillGroupIndex
    self.CharacterId = self.Parent.CharacterId
    self.Character = self.CharacterAgency:GetCharacter(self.CharacterId)
    self.SkillType = XCharacterConfigs.IsIsomer(self.CharacterId) and XCharacterConfigs.SkillUnLockType.Sp or XCharacterConfigs.SkillUnLockType.Enhance
    
    local skillGroupIdList = self.Character:GetEnhanceSkillGroupIdList() or {}
    local skillGroup = self.Character:GetEnhanceSkillGroupData(skillGroupIdList[skillGroupIndex])
    self.SkillGroup = skillGroup
    local configDes = skillGroup:GetSkillDescConfig(skillGroup.ActiveSkillId, skillGroup.Level)

    -- 技能名称
    self.TxtSkillName.text = skillGroup:GetName()
    self.TxtSkillLevel.text = skillGroup:GetLevel()
    -- 技能类型
    self.TxtSkillType.text = configDes.TypeDes and CSXTextManagerGetText("CharacterSkillTypeText", configDes.TypeDes) or ""
    -- 技能图标
    self.ImgSkillPointIcon:SetRawImage(skillGroup:GetIcon())
    -- 技能描述
    self.TxtSkillSpecific.text = XUiHelper.ReplaceTextNewLine(configDes.Intro)

    -- 条件
    local passCondition, conditionDes = self.CharacterAgency:GetEnhanceSkillIsPassCondition(skillGroup, self.CharacterId)
    self.PanelConsume.gameObject:SetActiveEx(passCondition)
    self.PanelCondition.gameObject:SetActiveEx(not passCondition)
    self.TxtConditionOk.gameObject:SetActiveEx(passCondition)
    self.TxtConditionBad.gameObject:SetActiveEx(not passCondition)

    -- 技能升级消费
    local baseItem = skillGroup:GetBaseCostItemV2P6()
    if passCondition then
        self.TxtConditionOk.text = conditionDes
        
        --消耗技能点(这里不会再有了  技能点改到左边了)
        -- local itemData = baseItem[1]
        -- local isEnoughtCount1
        -- if itemData then
        --     local itemId = itemData.Id
        --     isEnoughtCount1 = self.CharacterAgency:IsUseItemEnough({ itemId }, { itemData.Count })
        --     local icon = XDataCenter.ItemManager.GetItemIcon(itemId)
        --     self.PanelSkillPointOk:Find("Icon"):GetComponent("RawImage"):SetRawImage(icon)
        --     self.PanelSkillPointOk:Find("TxtCosumeNumber"):GetComponent("Text").text = itemData.Count

        --     self.PanelSkillPointBad:Find("Icon"):GetComponent("RawImage"):SetRawImage(icon)
        --     self.PanelSkillPointBad:Find("TxtCosumeNumber"):GetComponent("Text").text = itemData.Count
        -- end
        -- self.PanelSkillPointOk.gameObject:SetActiveEx(isEnoughtCount1)
        -- self.PanelSkillPointBad.gameObject:SetActiveEx(not isEnoughtCount1)
        -- self.PanelSkillPoint.gameObject:SetActiveEx(itemData)
        self.PanelSkillPoint.gameObject:SetActiveEx(false)

        --消耗螺母
        local itemData = baseItem[1]
        local isEnoughtCount2
        if itemData then
            local itemId = itemData.Id
            local icon = XDataCenter.ItemManager.GetItemIcon(itemId)
            isEnoughtCount2 = self.CharacterAgency:IsUseItemEnough({ itemId }, { itemData.Count })
            self.PanelCoinOk:Find("Icon"):GetComponent("RawImage"):SetRawImage(icon)
            self.PanelCoinOk:Find("TxtCosumeNumber"):GetComponent("Text").text = itemData.Count

            self.PanelCoinBad:Find("Icon"):GetComponent("RawImage"):SetRawImage(icon)
            self.PanelCoinBad:Find("TxtCosumeNumber"):GetComponent("Text").text = itemData.Count

            self.CurCoinCostId = itemId
        end
        self.PanelCoinOk.gameObject:SetActiveEx(isEnoughtCount2)
        self.PanelCoinBad.gameObject:SetActiveEx(not isEnoughtCount2)
        self.PanelCoin.gameObject:SetActiveEx(itemData)

        if XTool.IsTableEmpty(baseItem) then
            self.PanelConsume.gameObject:SetActiveEx(false)
        end
    else
        self.TxtConditionBad.text = conditionDes
    end

    -- 刷新格子前先隐藏
    for k, grid in pairs(self.MaterialItemDic) do
        grid.GameObject:SetActiveEx(false)
    end
    local materialItemList = skillGroup:GetMaterialCostItemListV2P6()
    for k, v in pairs(materialItemList) do
        local grid = self.MaterialItemDic[k]
        if not grid then
            local gridUi = self["GridItemHaveCount"..k]
            grid = XUiGridCommon.New(self.Parent, gridUi)
            self.MaterialItemDic[k] = grid
        end
        local curCount = XDataCenter.ItemManager.GetCount(v.Id)
        grid:Refresh({CostCount = v.Count, Count = curCount, Id = v.Id})
        grid.GameObject:SetActiveEx(true)
    end

    local IsCanUnlockOrLevelUp = self.CharacterAgency:CheckEnhanceSkillIsCanUnlockOrLevelUp(skillGroup)
    local isDisable = not IsCanUnlockOrLevelUp or not passCondition
    self.IsCanUpGrageOrUnlock = not isDisable
    self.BtnUpgrade:SetDisable(isDisable, not isDisable)
    self.BtnUnlock:SetDisable(isDisable, not isDisable)

    local isCanUpgrade = skillGroup:GetIsUnLock() and not skillGroup:GetIsMaxLevel()
    self.PanelConsume2.gameObject:SetActiveEx(not skillGroup:GetIsMaxLevel())
    self.BtnUpgrade.gameObject:SetActiveEx(isCanUpgrade)
    self.BtnUnlock.gameObject:SetActiveEx(not skillGroup:GetIsUnLock() and not skillGroup:GetIsMaxLevel())
    self.PanelMaxLevel.gameObject:SetActiveEx(skillGroup:GetIsMaxLevel())

    local consumeText = nil
    if self.BtnUpgrade.gameObject.activeInHierarchy then
        consumeText = CS.XTextManager.GetText("EnhanceSkillLevelUpHint")
    elseif self.BtnUnlock.gameObject.activeInHierarchy then
        consumeText = CS.XTextManager.GetText("EnhanceSkillUnLockHint")
    end
    self.TxtConsume.text = consumeText
end

function XUiPanelSkillDetailsInfoV2P6:OnBtnUpgradeClick()
    if not self.IsCanUpGrageOrUnlock then
        return
    end
    self.CharacterAgency:UpgradeEnhanceSkillRequest(self.SkillGroup:GetSkillGroupId(), 1, self.CharacterId, function ()
        self.Parent:RefreshUiShow()

        local text = ""
        if self.SkillType == XCharacterConfigs.SkillUnLockType.Enhance then
            text = CS.XTextManager.GetText("EnhanceSkillLevelUpFinishHint")
        elseif self.SkillType == XCharacterConfigs.SkillUnLockType.Sp then
            text = CS.XTextManager.GetText("SpSkillLevelUpFinishHint")
        end
        XUiManager.PopupLeftTip(text)
    end)
end

function XUiPanelSkillDetailsInfoV2P6:OnBtnUnlockClick()
    if not self.IsCanUpGrageOrUnlock then
        return
    end
    self.CharacterAgency:UnlockEnhanceSkillRequest(self.SkillGroup:GetSkillGroupId(), self.CharacterId, function ()
        self.Parent:RefreshUiShow()
        XLuaUiManager.Open("UiEnhanceSkillActivation", self.SkillType, self.SkillGroup, self.CharacterId)
    end)
end

-- 这里的螺母要和快捷购买的逻辑一样（策划说的），这里是复制粘贴PanelAsset的点击
function XUiPanelSkillDetailsInfoV2P6:OnBtnCoinClick()
    local itemId = self.CurCoinCostId
    if not itemId then
        return
    end
    
    if itemId == XDataCenter.ItemManager.ItemId.FreeGem then
        XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
    elseif itemId == XDataCenter.ItemManager.ItemId.HongKa then
        if XLuaUiManager.IsUiShow("UiMain") then
            XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnAddFreeGem)
        end
        XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
    elseif itemId == XDataCenter.ItemManager.ItemId.DoubleTower then
        --展示物品详情
        local item = XDataCenter.ItemManager.GetItem(itemId)
        local data = {
            Id = itemId,
            Count = item ~= nil and tostring(item.Count) or "0"
        }
        if self.QueryFunc then
            data = XTool.Clone(XGoodsCommonManager.GetGoodsShowParamsByTemplateId(itemId))
            data.IsTempItemData = true
            data.Count = self.QueryFunc(item) or data.Count
            data.Description = XGoodsCommonManager.GetGoodsDescription(itemId)
            data.WorldDesc = XGoodsCommonManager.GetGoodsWorldDesc(itemId)
        end
        XLuaUiManager.Open("UiTip", data, self.HideSkipBtn)
    elseif itemId == XDataCenter.PivotCombatManager.GetActivityCoinId() 
            or itemId == XDataCenter.ItemManager.ItemId.SkillPoint
            or itemId == XMazeConfig.GetTicketItemId()
    then
        local id = itemId
        XLuaUiManager.Open("UiTip", id)
    elseif not XDataCenter.ItemManager.GetBuyAssetTemplate(itemId, 1, true) then -- 没有购买数据的话就打开详情
        local id = itemId
        XLuaUiManager.Open("UiTip", id)
    else
        XUiManager.OpenBuyAssetPanel(itemId)
    end
end

return XUiPanelSkillDetailsInfoV2P6