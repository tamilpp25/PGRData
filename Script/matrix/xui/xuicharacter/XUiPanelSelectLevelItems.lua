local XUiBagItem = require("XUi/XUiBag/XUiBagItem")
require("XManager/XModelManager")

local XUiPanelSelectLevelItems = XClass(XUiNode, "XUiPanelSelectLevelItems")

function XUiPanelSelectLevelItems:Ctor(ui, parent, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    self:InitAutoScript()
    self.ExpItems = {}
    self.TotalExp = {}

	local XUiPanelLevelUpgrade = require("XUi/XUiCharacter/XUiPanelLevelUpgrade") --XUiPanelLevelUpgrade,
    self.CharUpgradeInfoPanel = XUiPanelLevelUpgrade.New(self.PanelLevelUpgrade, self, self.Parent)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelSelectLevelItems:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelSelectLevelItems:AutoInitUi()
    self.PanelItems = self.Transform:Find("PanelItems")
    self.PanelLvInfo = self.Transform:Find("PanelItems/PanelLvInfo")
    self.PanelRole = self.Transform:Find("PanelItems/PanelLvInfo/PanelRole")
    self.PanelContent = self.Transform:Find("PanelItems/PanelLvInfo/SffViewItem/AVSDiewport/PanelContent")
    self.PanelExpItem = self.Transform:Find("PanelItems/PanelLvInfo/SffViewItem/AVSDiewport/PanelContent/PanelExpItem")
    self.ScrollbarVertical = self.Transform:Find("PanelItems/PanelLvInfo/SffViewItem/ScrollbarVertical"):GetComponent("Scrollbar")
    self.BtnUpgrade = self.Transform:Find("PanelItems/PanelLvInfo/BtnUpgrade"):GetComponent("Button")
    self.ImgMaxLevel = self.Transform:Find("PanelItems/PanelLvInfo/ImgMaxLevel"):GetComponent("Image")
    self.PanelLevel = self.Transform:Find("PanelItems/PanelLevel")
    self.TxtExpCompare = self.Transform:Find("PanelItems/PanelLevel/LevelBarInfo/TxtExpCompare"):GetComponent("Text")
    self.TxtAddExp = self.Transform:Find("PanelItems/PanelLevel/LevelBarInfo/TxtAddExp"):GetComponent("Text")
    self.TxtShowLevel = self.Transform:Find("PanelItems/PanelLevel/LevelBarInfo/TxtShowLevel"):GetComponent("Text")
    self.TxtCharCurLevel = self.Transform:Find("PanelItems/PanelLevel/LevelBarInfo/TxtCharCurLevel"):GetComponent("Text")
    self.ImgExpBar = self.Transform:Find("PanelItems/PanelLevel/LevelBarInfo/ImgExpBar"):GetComponent("Image")
    self.ImgExpAddBar = self.Transform:Find("PanelItems/PanelLevel/LevelBarInfo/ImgExpAddBar"):GetComponent("Image")
    self.PanelLevelUpgrade = self.Transform.parent:FindTransform("PanelLevelUpgrade")
    self.PanelEmpty = self.Transform:Find("PanelItems/PanelLvInfo/PanelEmpty")
end

function XUiPanelSelectLevelItems:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelSelectLevelItems:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelSelectLevelItems:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelSelectLevelItems:AutoAddListener()
    self:RegisterClickEvent(self.BtnUpgrade, self.OnBtnUpgradeClick)
end
-- auto

function XUiPanelSelectLevelItems:OnBtnUpgradeClick()
    self:SendLevelExpItems()
end

function XUiPanelSelectLevelItems:ResetData()
    local characterId = self.CharacterId
    local character = XMVCA.XCharacter:GetCharacter(characterId)

    self.MaxLevelNeedExp = 0
    self.ShowNextLevel = character.Level

    for start = character.Level, self.MaxLevel - 1 do
        self.MaxLevelNeedExp = self.MaxLevelNeedExp + XMVCA.XCharacter:GetNextLevelExp(characterId, start)
    end

    self.ShowCurExp = character.Exp
    self.CurCharacterExp = character.Exp
    self.CharacterTempExp = character.Exp
    if character.Exp > XMVCA.XCharacter:GetNextLevelExp(characterId, character.Level) then
        self.CharacterTempExp = 0
    end
    self.MaxLevelNeedExp = self.MaxLevelNeedExp - self.CharacterTempExp
    self.RedundantExp = character.Exp - self.CharacterTempExp

    self.AddExp = 0
end

function XUiPanelSelectLevelItems:ShowPanel(characterId)
    self.ItemId = nil
    self.CharacterId = characterId
    self.MaxLevel = XMVCA.XCharacter:GetMaxAvailableLevel(characterId)
    self.IsShow = true
    self.ScrollbarVertical.value = 1
    self.CharUpgradeInfoPanel.GameObject:SetActive(false)
    self:ResetData()
    self:UpdateItems()
    self:UpdateUi()
    self:CheckMaxLevel()
    local character = XMVCA.XCharacter:GetCharacter(characterId)
    self.TxtShowLevel.text = CS.XTextManager.GetText("CharacterShowLevel", character.Level, self.MaxLevel)
    self.PanelItems.gameObject:SetActive(true)
    self.GameObject:SetActive(true)
end

function XUiPanelSelectLevelItems:HidePanel()
    self.IsShow = false
    self.GameObject:SetActive(false)
    self.PanelRole.gameObject:SetActive(false)
end

function XUiPanelSelectLevelItems:CheckMaxLevel()
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)
    local isMaxLevel = character.Level >= self.MaxLevel or self.AddExp <= 0
    self.BtnUpgrade.gameObject:SetActive(not isMaxLevel)
    self.ImgMaxLevel.gameObject:SetActive(isMaxLevel)
end

function XUiPanelSelectLevelItems:UpdateUi()
    local characterId = self.CharacterId
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)

    self.ImgExpAddBar.gameObject:SetActive(false)
    local isMaxLevel = self.ShowNextLevel >= self.MaxLevel
    self.ImgExpBar.fillAmount = isMaxLevel and 0 or self.CharacterTempExp / XMVCA.XCharacter:GetNextLevelExp(characterId, self.ShowNextLevel)
    self.TxtExpCompare.text = math.floor(self.ShowCurExp) .. "/" .. XMVCA.XCharacter:GetNextLevelExp(characterId, self.ShowNextLevel)
    self.TxtCharCurLevel.text = character.Level
    self.TxtAddExp.text = self.AddExp > 0 and "+" .. math.floor(self.AddExp) or ""

    for i = 1, #self.ExpItems do
        self.ExpItems[i].Btn2.gameObject:SetActive(not isMaxLevel and self.ExpItems[i].SelectCount > 0)
    end
end

function XUiPanelSelectLevelItems:UpdateUiAdd(index)
    local characterId = self.CharacterId
    local character = XMVCA.XCharacter:GetCharacter(characterId)

    local isMaxLevel = self.ShowNextLevel >= self.MaxLevel
    local nextLevelExp = XMVCA.XCharacter:GetNextLevelExp(characterId, self.ShowNextLevel)

    self.ImgExpAddBar.gameObject:SetActive(true)

    if self.AddExp == 0 then
        self.ImgExpAddBar.fillAmount = character.Exp / nextLevelExp
    else
        self.ImgExpAddBar.fillAmount = isMaxLevel and 0 or (self.AddExp + self.CurCharacterExp) / nextLevelExp
    end

    if character.Level < self.ShowNextLevel then
        self.ImgExpAddBar.fillAmount = 1
    end

    self.TxtCharCurLevel.text = character.Level
    self.TxtAddExp.text = self.AddExp > 0 and "+" .. math.floor(self.AddExp) or ""
    self.ExpItems[index].Btn2.gameObject:SetActive(self.ExpItems[index].SelectCount > 0)
end

function XUiPanelSelectLevelItems:CalcMaxCount(expItem)
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)

    local count = expItem.SelectCount
    local itemId = expItem.Data.Id
    local itemexp = XDataCenter.ItemManager.GetCharExp(itemId, character.Type)
    local sumExp = 0

    for _, item in pairs(self.ExpItems) do
        local compareItemId = item.Data.Id
        if compareItemId ~= itemId then
            sumExp = sumExp + XDataCenter.ItemManager.GetCharExp(compareItemId, character.Type) * item.SelectCount
        end
    end

    if (self.MaxLevelNeedExp - sumExp) > 0 then
        count = (self.MaxLevelNeedExp - sumExp) / itemexp
        count = math.ceil(count)
    end

    return count
end

function XUiPanelSelectLevelItems:UpdateItems()
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)

    local expItemsInfo = XDataCenter.ItemManager.GetCardExpItems()
    local index = 1

    for i = 1, #expItemsInfo do
        if expItemsInfo[i].Template.UpType == character.Type then
            local a = expItemsInfo[i]
            table.insert(expItemsInfo, index, a)
            table.remove(expItemsInfo, i + 1)
            index = index + 1
        end
    end

    XUiHelper.CreateTemplates(self.RootUi, self.ExpItems, expItemsInfo, XUiBagItem.New, self.PanelExpItem.gameObject, self.PanelContent)
    self.PanelExpItem.gameObject:SetActive(false)

    local itemCount = #expItemsInfo
    for i = 1, itemCount do
        local info = expItemsInfo[i]
        local expItem = self.ExpItems[i]

        expItem.GameObject.name = info.Id
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_STEP_OPEN_EVENT,expItem.GameObject.name)

        expItem:Refresh(info, true, true)
        expItem:SetSelectCount(0)
        expItem.Btn2.gameObject:SetActive(false)
        expItem:SetClickCallback2(function()
            expItem:UpdateSelectCount(self:CalcMaxCount(expItem))

            local selectCount = expItem.SelectCount
            if selectCount > 0 then
                expItem.TxtSelectHide.text = string.format("%s%s", "x", selectCount)
                expItem.TxtSelectHide.gameObject:SetActive(true)
                expItem.ImgSelectBg.gameObject:SetActive(true)
            else
                expItem.TxtSelectHide.gameObject:SetActive(false)
                expItem.ImgSelectBg.gameObject:SetActive(false)
            end
        end)
        expItem:SetChangeSelectCountCondition(function(newCount)
            return self:DealSelectItem(i, newCount)
        end)
    end

    --多出来被消耗的格子要清掉数据
    for i = itemCount + 1, #self.ExpItems do
        self.ExpItems[i] = nil
    end

    self.PanelEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(expItemsInfo))
end

function XUiPanelSelectLevelItems:UpdateAddExp(index, changeCount)
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)

    local exp = XDataCenter.ItemManager.GetCharExp(self.ExpItems[index].Data.Id, character.Type)
    self.AddExp = self.AddExp + exp * changeCount
    character.Exp = self.CharacterTempExp
    local preExp = self.AddExp ~= 0 and self.AddExp + self.RedundantExp or 0
    self.ShowNextLevel, self.ShowCurExp = XMVCA.XCharacter:CalLevelAndExp(character, preExp)

    if self.ShowNextLevel > self.MaxLevel then
        self.ShowNextLevel = self.MaxLevel
    end

    self.TxtShowLevel.text = CS.XTextManager.GetText("CharacterShowLevel", self.ShowNextLevel, self.MaxLevel)

    if self.AddExp < self.AddExp + exp * changeCount then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Promotion)  --杝均
    end


end

function XUiPanelSelectLevelItems:DealSelectItem(index, newCount)
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)

    if newCount < 0 then
        return
    end

    local expItem = self.ExpItems[index]
    local selectCount = self.ExpItems[index].SelectCount

    if self.ShowNextLevel >= self.MaxLevel and newCount > selectCount then
        XUiManager.TipText("CharacterNotMoreLevel")
        return
    end

    local diffCount = newCount - selectCount

    -- 由于长按可能导致道具超出理论极限使用个数，因此加个范围检测
    local exp = XDataCenter.ItemManager.GetCharExp(self.ExpItems[index].Data.Id, character.Type)
    local addExp = exp * diffCount
    local preExp = addExp ~= 0 and self.AddExp + addExp + self.RedundantExp or 0
    local showNextLevel, _ = XMVCA.XCharacter:CalLevelAndExp(character, preExp)
    if showNextLevel > self.MaxLevel and newCount > selectCount  then
        while showNextLevel >= self.MaxLevel do
            diffCount = diffCount - 1
            addExp = exp * diffCount
            preExp = self.AddExp + addExp ~= 0 and self.AddExp + addExp + self.RedundantExp or 0
            showNextLevel, _ = XMVCA.XCharacter:CalLevelAndExp(character, preExp)
        end
        diffCount = diffCount + 1
        self:UpdateAddExp(index, diffCount)
        expItem:SetSelectCount(selectCount + diffCount)
        self:UpdateUiAdd(index)
        character.Exp = self.CurCharacterExp
        self:CheckMaxLevel()
        return false
    end

    self:UpdateAddExp(index, diffCount)
    expItem:SetSelectCount(newCount)
    self:UpdateUiAdd(index)
    character.Exp = self.CurCharacterExp
    self:CheckMaxLevel()

    if self.AddExp > 0 and self.AddExp + self.RedundantExp >= self.MaxLevelNeedExp then
        return true
    end
    return false
end

function XUiPanelSelectLevelItems:SendLevelExpItems()
    local character = XMVCA.XCharacter:GetCharacter(self.CharacterId)

    --local curLevel = XPlayer.Level
    --if curLevel < self.ShowNextLevel then
    --    local text = CS.XTextManager.GetText('CharacterLevelFull')
    --    XUiManager.TipMsg(text, XUiManager.UiTipType.Tip)
    --    return
    --end

    local items = {}
    for i = 1, #self.ExpItems do
        local item = self.ExpItems[i]
        if item.GameObject.activeSelf and item.SelectCount ~= 0 then
            items[item.Data.Id] = item.SelectCount
        end
    end

    local oldCharLevel = character.Level
    self.CharUpgradeInfoPanel:OldCharUpgradeInfo(character)
    if next(items) then
        XMVCA.XCharacter:AddExp(character, items, function()
            self:ResetData()
            self:UpdateItems()
            self:UpdateUi()
            self:CheckMaxLevel()

            if character.Level >= self.MaxLevel then
                self.RootUi.ParentUi:OnBtnBackClick() -- 满级后自动点一次返回
            end

            if character.Level > oldCharLevel then
                self.Parent.LevelUpgradeEnable:PlayTimelineAnimation()
                self.CharUpgradeInfoPanel:ShowLevelInfo(character)
            end

            if self.RootUi.RefreshTabBtns then
                self.RootUi:RefreshTabBtns()
            end
        end)
    end
end

return XUiPanelSelectLevelItems