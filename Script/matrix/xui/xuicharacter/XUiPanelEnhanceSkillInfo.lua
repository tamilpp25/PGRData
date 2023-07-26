local XUiPanelEnhanceSkillInfo = XClass(nil, "XUiPanelEnhanceSkillInfo")
local CSTextManagerGetText = CS.XTextManager.GetText
local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.red,
}
local MAX_ENHANCESKILL_COUNT = 3
local MAX_ENHANCESKILLSP_COUNT = 5

function XUiPanelEnhanceSkillInfo:Ctor(ui, root, anime, IsSelf, priorCallBack, nextCallBack,skillType)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Root = root
    self.Anime = anime
    self.IsSelf = IsSelf
    self.PriorCallBack = priorCallBack
    self.NextCallBack = nextCallBack
    self.SkillType = skillType or XCharacterConfigs.SkillUnLockType.Enhance
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self.GridItem.gameObject:SetActiveEx(false)
end

function XUiPanelEnhanceSkillInfo:SetButtonCallBack()
    self.BtnEntry.CallBack = function()
        self:OnBtnEntryClick()
    end
    self.BtnNext.CallBack = function()
        if self.NextCallBack then
            self.NextCallBack()
        end
    end
    self.BtnPrior.CallBack = function()
        if self.PriorCallBack then
            self.PriorCallBack()
        end
    end
    self.BtnUpgrade.CallBack = function()
        self:OnBtnUpgradeClick()
    end
    self.BtnUnlock.CallBack = function()
        self:OnBtnUnlockClick()
    end
end

function XUiPanelEnhanceSkillInfo:ShowPanel(skillGroupPos, character)
    self.SkillGroupPos = skillGroupPos
    self.SkillGroup = character:GetEnhanceSkillGroupByPos(skillGroupPos)
    self.CharEntity = character

    self:UpdataPanel()

    self.GameObject:SetActiveEx(true)
    self.Anime.SkillInfoQiehuan:PlayTimelineAnimation()
end

function XUiPanelEnhanceSkillInfo:UpdataPanel()
    if self.SkillGroup then
        self.EntryList = self.SkillGroup:GetSkillEntryConfigList()
        self.ImgSkillPointIcon:SetRawImage(self.SkillGroup:GetIcon())
        self.TxtSkillType.text = self.SkillGroup:GetSkillTypeName()
        self.TxtSkillName.text = self.SkillGroup:GetName()
        self.TxtSkillLevel.text = self.SkillGroup:GetLevel()
        self.TxtSkillDesc.text = string.gsub(self.SkillGroup:GetDesc(), "\\n", "\n")
        self:ShowInfo(self.SkillGroup)

        if self.IsSelf then
            local hintStr = self.SkillGroup:GetIsUnLock() and "EnhanceSkillLevelUpHint" or "EnhanceSkillUnLockHint"
            self.TxtNeed.text = CSTextManagerGetText(hintStr)
            self:ShowCostItem(self.SkillGroup)
            self:ShowCondtion(self.SkillGroup)
        end
        self.PanelButton.gameObject:SetActiveEx(self.IsSelf)
        self.PanelUnlockMaterial.gameObject:SetActiveEx(self.IsSelf and not self.SkillGroup:GetIsMaxLevel())
        self.PanelSkillLevel.gameObject:SetActiveEx(self.SkillGroup:GetIsUnLock())
    end
end

function XUiPanelEnhanceSkillInfo:ShowCostItem(skillGroup)
    local baseItem = skillGroup:GetBaseCostItem()
    local materialItemList = skillGroup:GetMaterialCostItemList()

    if baseItem then
        local curCount = XDataCenter.ItemManager.GetCount(baseItem.Id)
        self.TextCoinDes.text = XDataCenter.ItemManager.GetItemName(baseItem.Id)
        self.TxtCoinCount.text = baseItem.Count
        self.TxtCoinCount.color = CONDITION_COLOR[curCount >= baseItem.Count]
    end
    self.PanelConsume.gameObject:SetActiveEx(baseItem)
    
    self.GridCostItems = self.GridCostItems or {}
    for index, item in ipairs(materialItemList or {}) do
        local grid = self.GridCostItems[index]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridItem)
            grid = XUiGridCommon.New(self.Root, ui)
            grid.Transform:SetParent(self.PanelItem, false)
            self.GridCostItems[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        local curCount = XDataCenter.ItemManager.GetCount(item.Id)
        grid:Refresh({CostCount = item.Count, Count = curCount, Id = item.Id})
    end

    for i = #materialItemList + 1, #self.GridCostItems do
        self.GridCostItems[i].GameObject:SetActiveEx(false)
    end
end

function XUiPanelEnhanceSkillInfo:ShowCondtion(skillGroup)
    local IsPassCondition,conditionDes = XDataCenter.CharacterManager.GetEnhanceSkillIsPassCondition(skillGroup, self.CharEntity:GetId())
    self.TxtPass.text = conditionDes
    self.TxtNotPass.text = conditionDes
    if self.PanelPass then
        self.PanelPass.gameObject:SetActiveEx(IsPassCondition and not string.IsNilOrEmpty(conditionDes))
    end
    if self.PanelNotPass then
        self.PanelNotPass.gameObject:SetActiveEx(not IsPassCondition and not string.IsNilOrEmpty(conditionDes))
    end
    if self.GridCondition then
        self.GridCondition.gameObject:SetActiveEx(not string.IsNilOrEmpty(conditionDes))
    end
    self.TxtPass.gameObject:SetActiveEx(IsPassCondition and not string.IsNilOrEmpty(conditionDes))
    self.TxtNotPass.gameObject:SetActiveEx(not IsPassCondition and not string.IsNilOrEmpty(conditionDes))

    local IsCanUnlockOrLevelUp = XDataCenter.CharacterManager.CheckEnhanceSkillIsCanUnlockOrLevelUp(skillGroup)
    local isEnable = not IsCanUnlockOrLevelUp or not IsPassCondition
    self.BtnUpgrade:SetDisable(isEnable, not isEnable)
    self.BtnUnlock:SetDisable(isEnable, not isEnable)

    self.BtnUpgrade.gameObject:SetActiveEx(skillGroup:GetIsUnLock() and not skillGroup:GetIsMaxLevel())
    self.BtnUnlock.gameObject:SetActiveEx(not skillGroup:GetIsUnLock() and not skillGroup:GetIsMaxLevel())
    self.PanelMaxLevel.gameObject:SetActiveEx(skillGroup:GetIsMaxLevel())
end

function XUiPanelEnhanceSkillInfo:ShowInfo(skillGroup)
    self.BtnEntry.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.EntryList))
    if self.SkillType == XCharacterConfigs.SkillUnLockType.Enhance then
        self.BtnNext.gameObject:SetActiveEx(self.SkillGroupPos < MAX_ENHANCESKILL_COUNT)
    else
        self.BtnNext.gameObject:SetActiveEx(self.SkillGroupPos < MAX_ENHANCESKILLSP_COUNT)
    end
    self.BtnPrior.gameObject:SetActiveEx(self.SkillGroupPos > 1)

end

function XUiPanelEnhanceSkillInfo:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelEnhanceSkillInfo:OnBtnUpgradeClick()
    local baseItem = self.SkillGroup:GetBaseCostItem()
    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.Coin,
            baseItem.Count,
            1,
            function()
                self:OnBtnUpgradeClick()
            end,
            "CharacterUngradeSkillCoinNotEnough") then
        return
    end
    XDataCenter.CharacterManager.UpgradeEnhanceSkillRequest(self.SkillGroup:GetSkillGroupId(), 1, self.CharEntity:GetId(),function ()
            self:UpdataPanel()
            local text = ""
            if self.SkillType == XCharacterConfigs.SkillUnLockType.Enhance then
                text = CS.XTextManager.GetText("EnhanceSkillLevelUpFinishHint")
            elseif self.SkillType == XCharacterConfigs.SkillUnLockType.Sp then
                text = CS.XTextManager.GetText("SpSkillLevelUpFinishHint")
            end
            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_INCREASE_TIP, text)
        end)
end

function XUiPanelEnhanceSkillInfo:OnBtnUnlockClick()
    local baseItem = self.SkillGroup:GetBaseCostItem()
    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.Coin,
            baseItem.Count,
            1,
            function()
                self:OnBtnUnlockClick()
            end,
            "CharacterUngradeSkillCoinNotEnough") then
        return
    end
    XDataCenter.CharacterManager.UnlockEnhanceSkillRequest(self.SkillGroup:GetSkillGroupId(), self.CharEntity:GetId(),function ()
            self:UpdataPanel()
            XLuaUiManager.Open("UiEnhanceSkillActivation", self.SkillType, self.SkillGroup, self.CharEntity:GetId())
        end)
end

function XUiPanelEnhanceSkillInfo:OnBtnEntryClick()
    if XTool.IsTableEmpty(self.EntryList) then return end

    if not XLuaUiManager.IsUiShow("UiCharSkillOtherParsing") then
        XLuaUiManager.Open("UiCharSkillOtherParsing", self.EntryList)
    end
end

return XUiPanelEnhanceSkillInfo