local XUiPanelSkillDetailsInfo = XClass(nil, "XUiPanelSkillDetailsInfo")

-- 触发拖拽前的延时
local LONG_CLICK_OFFSET = 0.2
local LONG_PRESS_PARAMS = 500
local SIGNAL_BAL_MEMBER = 3 --信号球技能（红黄蓝)
local DescribeType = {
    Title = 1,
    Specific = 2,
}

function XUiPanelSkillDetailsInfo:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self:RegisterUiEvents()
    self:ResetLongPressData()
    self.Attribute.gameObject:SetActiveEx(false)
    self.TxtSkillTitle.gameObject:SetActiveEx(false)
    self.TxtSkillSpecific.gameObject:SetActiveEx(false)
    
    self.SkillTag = {}
    self.TxtSkillTitleGo = {}
    self.TxtSkillSpecificGo = {}
end

function XUiPanelSkillDetailsInfo:Refresh(characterId, subSkill, isDetails)
    self.CharacterId = characterId
    self.SubSkill = subSkill
    self.IsDetails = isDetails
    self:RefreshSubSkillInfoPanel(subSkill)
end

function XUiPanelSkillDetailsInfo:RefreshSubSkillInfoPanel(subSkill)
    -- 切换按钮
    local showSwithBtn = subSkill.Level > 0 and XCharacterConfigs.CanSkillSwith(subSkill.SubSkillId)
    self.BtnSwitch.gameObject:SetActiveEx(showSwithBtn)

    self:RefreshSkillLevel(subSkill)
    self:RefreshSkillView()
    self:RefreshEntryBtn()

    local min_max = XCharacterConfigs.GetSubSkillMinMaxLevel(self.SubSkillId)
    if (subSkill.Level >= min_max.Max) then
        self.PanelCondition.gameObject:SetActiveEx(false)
        self.PanelConsume.gameObject:SetActiveEx(false)
        self.BtnUpgrade.gameObject:SetActiveEx(false)
        self.BtnUnlock.gameObject:SetActiveEx(false)
        self.PanelMax.gameObject:SetActiveEx(true)
        return
    else
        self.PanelMax.gameObject:SetActiveEx(false)
    end
    
    local passCondition = true
    local conditionDes = ""
    local conditions = subSkill.config.ConditionId
    if conditions then
        for _, conditionId in pairs(conditions) do
            if conditionId ~= 0 then
                passCondition, conditionDes = XConditionManager.CheckCondition(conditionId, self.CharacterId)
                if not passCondition then
                    break
                end
            end
        end
    end

    self.PanelConsume.gameObject:SetActiveEx(passCondition)
    self.PanelCondition.gameObject:SetActiveEx(not passCondition)
    self.TxtConditionOk.gameObject:SetActiveEx(passCondition)
    self.TxtConditionBad.gameObject:SetActiveEx(not passCondition)

    if passCondition then
        self.TxtConditionOk.text = conditionDes
        --消耗技能点
        local showSkillPoint = subSkill.config.UseSkillPoint > 0
        self.PanelSkillPoint.gameObject:SetActiveEx(showSkillPoint)
        if showSkillPoint then
            local isSkillPointMeet = self.CharacterAgency:IsUseItemEnough({ XDataCenter.ItemManager.ItemId.SkillPoint }, { subSkill.config.UseSkillPoint })
            if isSkillPointMeet then
                self.TxtSkillPointOk.text = subSkill.config.UseSkillPoint
            else
                self.TxtSkillPointBad.text = subSkill.config.UseSkillPoint
            end
            local icon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.SkillPoint)
            self.PanelSkillPointOk:Find("Icon"):GetComponent("RawImage"):SetRawImage(icon)
            self.PanelSkillPointBad:Find("Icon"):GetComponent("RawImage"):SetRawImage(icon)

            self.PanelSkillPointBad.gameObject:SetActiveEx(not isSkillPointMeet)
            self.PanelSkillPointOk.gameObject:SetActiveEx(isSkillPointMeet)
        end

        --消耗螺母
        local showCoin = subSkill.config.UseCoin > 0
        self.PanelCoin.gameObject:SetActiveEx(showCoin)
        if showCoin then
            local isUseCoinMeet = self.CharacterAgency:IsUseItemEnough({ XDataCenter.ItemManager.ItemId.Coin }, { subSkill.config.UseCoin })
            if isUseCoinMeet then
                self.TxtCoinOk.text = subSkill.config.UseCoin
            else
                self.TxtCoinBad.text = subSkill.config.UseCoin
            end

            local icon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.Coin)
            self.PanelCoinOk:Find("Icon"):GetComponent("RawImage"):SetRawImage(icon)
            self.PanelCoinBad:Find("Icon"):GetComponent("RawImage"):SetRawImage(icon)

            self.PanelCoinBad.gameObject:SetActiveEx(not isUseCoinMeet)
            self.PanelCoinOk.gameObject:SetActiveEx(isUseCoinMeet)
        end

        if not showCoin and not showSkillPoint then
            self.PanelConsume.gameObject:SetActiveEx(false)
        end
    else
        self.TxtConditionBad.text = conditionDes
    end

    if (subSkill.Level <= 0) then
        self.BtnUnlock:SetDisable(not passCondition)
        self.BtnUnlock.gameObject:SetActiveEx(true)
        self.BtnUpgrade.gameObject:SetActiveEx(false)
    elseif (subSkill.Level < min_max.Max and subSkill.Level > 0) then
        local canUpdate = self.CharacterAgency:CheckCanUpdateSkill(self.CharacterId, subSkill.SubSkillId, subSkill.Level)
        self.BtnUpgrade:SetDisable(not canUpdate)
        self.BtnUpgrade.gameObject:SetActiveEx(true)
        self.BtnUnlock.gameObject:SetActiveEx(false)
    end
end

function XUiPanelSkillDetailsInfo:RefreshSkillLevel(subSkill)
    self.SubSkillId  = subSkill.SubSkillId
    local levelStr = subSkill.Level
    
    local addLevel = 0
    local addLevelStr = ""
    local resonanceLevel = self.CharacterAgency:GetResonanceSkillLevel(self.CharacterId, self.SubSkillId)
    local assignLevel = XDataCenter.FubenAssignManager.GetSkillLevel(self.CharacterId, self.SubSkillId)

    if (resonanceLevel and resonanceLevel > 0) then
        addLevel = addLevel + resonanceLevel
    end

    if (assignLevel and assignLevel > 0) then
        addLevel = addLevel + assignLevel
    end

    if addLevel ~= 0 then
        addLevelStr = addLevelStr .. CS.XTextManager.GetText("CharacterSkillLevelDetail", addLevel)
        levelStr = levelStr .. addLevelStr
        self.BtnDetails.gameObject:SetActiveEx(true)
    else
        self.BtnDetails.gameObject:SetActiveEx(false)
    end

    self.SubSkillLevel = subSkill.Level + addLevel
    self.GradeConfig = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(self.SubSkillId, self.SubSkillLevel)
    self.TxtSkillLevel.text = levelStr
end

function XUiPanelSkillDetailsInfo:RefreshSkillView()
    local configDes = self.GradeConfig
    -- 技能名称
    self.TxtSkillName.text = configDes.Name
    -- 技能类型
    self.TxtSkillType.text = configDes.TypeDes and CSXTextManagerGetText("CharacterSkillTypeText", configDes.TypeDes) or ""
    -- 技能图标
    local skillType = XCharacterConfigs.GetSkillType(self.SubSkillId)
    local isSignalBal = skillType <= SIGNAL_BAL_MEMBER
    self.ImgSkillPointIcon:SetRawImage(configDes.Icon)
    self.ImgBlueBall:SetRawImage(configDes.Icon)
    self.ImgSkillPointIcon.gameObject:SetActiveEx(not isSignalBal)
    self.ImgBlueBall.gameObject:SetActiveEx(isSignalBal)
    -- 技能标签
    for index, tag in pairs(configDes.Tag or {}) do
        local grid = self.SkillTag[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.Attribute, self.PanelAttribute)
            self.SkillTag[index] = grid
        end
        local tagUi = {}
        XTool.InitUiObjectByUi(tagUi, grid)
        tagUi.Name.text = tag
        grid.gameObject:SetActiveEx(true)
    end
    for i = #configDes.Tag + 1, #self.SkillTag do
        self.SkillTag[i].gameObject:SetActiveEx(false)
    end
    -- 技能描述
    self:RefreshSkillDescribe(self.IsDetails)
end

function XUiPanelSkillDetailsInfo:RefreshSkillDescribe(isDetails)
    -- 隐藏
    for _, go in pairs(self.TxtSkillTitleGo) do
        go:SetActiveEx(false)
    end
    for _, go in pairs(self.TxtSkillSpecificGo) do
        go:SetActiveEx(false)
    end
    -- 显示
    local messageDes = {}
    if isDetails then
        messageDes = self.GradeConfig.SpecificDes
    else
        messageDes = self.GradeConfig.BriefDes
    end
    for index, message in pairs(messageDes or {}) do
        local title = self.GradeConfig.Title[index]
        if title then
            self:SetTextInfo(DescribeType.Title, index, title)
        end
        self:SetTextInfo(DescribeType.Specific, index, message)
    end
    -- 每次刷新技能描述时，都从最开头进行显示
    if self.GridSkillInfo then
        self.GridSkillInfo.verticalNormalizedPosition = 1
    end
end

function XUiPanelSkillDetailsInfo:SetTextInfo(txtType, index, info)
    local txtSkillGo = {}
    local target
    if txtType == DescribeType.Title then
        txtSkillGo = self.TxtSkillTitleGo
        target = self.TxtSkillTitle.gameObject
    else
        txtSkillGo = self.TxtSkillSpecificGo
        target = self.TxtSkillSpecific.gameObject
    end
    local txtGo = txtSkillGo[index]
    if not txtGo then
        txtGo = XUiHelper.Instantiate(target, self.PanelReward)
        txtSkillGo[index] = txtGo
    end
    txtGo:SetActiveEx(true)
    local goTxt = txtGo:GetComponent("Text")
    goTxt.text = XUiHelper.ConvertLineBreakSymbol(info)
    txtGo.transform:SetAsLastSibling()
end

function XUiPanelSkillDetailsInfo:RefreshEntryBtn()
    if not XTool.IsNumberValid(self.SubSkillId) then
        self.BtnNounParsing.gameObject:SetActiveEx(false)
        return
    end

    self.EntryList = XCharacterConfigs.GetSkillGradeDesConfigEntryList(self.SubSkillId, self.SubSkillLevel)
    if XTool.IsTableEmpty(self.EntryList) then
        self.BtnNounParsing.gameObject:SetActiveEx(false)
        return
    end

    self.BtnNounParsing.gameObject:SetActiveEx(true)
end

function XUiPanelSkillDetailsInfo:CheckUpgradeSubSkill()
    local subSkill = self.SubSkill
    local conditions = subSkill.config.ConditionId
    if not conditions then
        return true
    end

    for _, conditionId in pairs(conditions) do
        local passCondition
        local conditionDes
        if conditionId ~= 0 then
            passCondition, conditionDes = XConditionManager.CheckCondition(conditionId, self.CharacterId)
            if not passCondition then
                XUiManager.TipMsg(conditionDes)
                return false
            end
        end
    end

    if (not self.CharacterAgency:IsUseItemEnough(XDataCenter.ItemManager.ItemId.SkillPoint, subSkill.config.UseSkillPoint)) then
        XUiManager.TipText("CharacterUngradeSkillSkillPointNotEnough")
        return false
    end

    return true
end

--region 按钮相关

function XUiPanelSkillDetailsInfo:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnDetails, self.OnBtnDetails)
    XUiHelper.RegisterClickEvent(self, self.BtnNounParsing, self.OnBtnNounParsing)
    XUiHelper.RegisterClickEvent(self, self.BtnSwitch, self.OnBtnSwitchClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUnlock, self.OnBtnUnlockClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSkillPoint, self.OnBtnSkillPointClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCoin, self.OnBtnCoinClick)

    self:RegisterLongPressLevelUp()
end

function XUiPanelSkillDetailsInfo:OnBtnNounParsing()
    if XTool.IsTableEmpty(self.EntryList) then return end

    if not XLuaUiManager.IsUiShow("UiCharSkillOtherParsing") then
        XLuaUiManager.Open("UiCharSkillOtherParsing", self.EntryList)
    end
end

function XUiPanelSkillDetailsInfo:OnBtnDetails()
    self.RootUi:ShowLevelDetail(self.SubSkillId)
end

function XUiPanelSkillDetailsInfo:OnBtnSwitchClick()
    local addLevel = self.CharacterAgency:GetSkillPlusLevel(self.CharacterId, self.SubSkillId)
    local totalLevel = self.SubSkill.Level + addLevel
    XLuaUiManager.Open("UiCharacterSkillSwich", self.SubSkillId, totalLevel, function()
        self.RootUi:RefreshData()
    end)
end

function XUiPanelSkillDetailsInfo:OnBtnUnlockClick()
    if (not self:CheckUpgradeSubSkill()) then
        return
    end

    if XTool.IsTableEmpty(self.SubSkill) or not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.Coin,
            self.SubSkill.config.UseCoin,
            1,
            function()
                self:OnBtnUnlockClick()
            end,
            "CharacterUngradeSkillCoinNotEnough") then
        return
    end

    self.CharacterAgency:UnlockSubSkill(self.SubSkillId, self.CharacterId, function()
        -- XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_INCREASE_TIP, CS.XTextManager.GetText("CharacterUnlockSkillComplete"))
        XUiManager.PopupLeftTip(CS.XTextManager.GetText("CharacterUnlockSkillComplete"))
        self.RootUi:RefreshData()
    end)
end

--endregion

--region 技能长按功能

function XUiPanelSkillDetailsInfo:ResetLongPressData()
    self.ClientShowLevelParam = 0 --要升级到的等级
    self.ClientLongPressIncreaseLevel = 0 --等级变量依据长按时间增加
    self.LongPressCostCoin = 0
    self.LongPressCostSkillPoint = 0
    self.NotMaskShow = true
    self.PanelMask.gameObject:SetActiveEx(false)
end

--技能长按
function XUiPanelSkillDetailsInfo:RegisterLongPressLevelUp()
    -- 添加长按事件
    local btnClickPointer = self.BtnUpgrade.gameObject:GetComponent("XUiPointer")
    if not btnClickPointer then
        btnClickPointer =  self.BtnUpgrade.gameObject:AddComponent(typeof(CS.XUiPointer))
    end
    self.Clicker = XUiButtonLongClick.New(btnClickPointer, math.floor(1000/ CS.XGame.ClientConfig:GetInt("LongPressPerLevelUp")), self, self.OnBtnUpgradeClick, self.OnLongPress, function()
        self:OnLongPressUp()
    end, false, nil,true,true)
    self.Clicker:SetTriggerOffset(LONG_CLICK_OFFSET)
end

function XUiPanelSkillDetailsInfo:OnBtnUpgradeClick(ClientLongPressIncreaseLevel)
    if not self.NotMaskShow then
        self.NotMaskShow = true
        self.PanelMask.gameObject:SetActiveEx(false)
    end
    if  not ClientLongPressIncreaseLevel then  --过滤掉不正确的弹窗
        if (not self:CheckUpgradeSubSkill())then
            return
        end
    end

    if XTool.IsTableEmpty(self.SubSkill) then
        return
    end

    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(XDataCenter.ItemManager.ItemId.Coin,
            self.SubSkill.config.UseCoin,
            1,
            function()
                self:OnBtnUpgradeClick()
            end,
            "CharacterUngradeSkillCoinNotEnough") then
        return
    end
    self.CharacterAgency:UpgradeSubSkillLevel(self.CharacterId, self.SubSkillId, function()
        -- XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_INCREASE_TIP, CS.XTextManager.GetText("CharacterUngradeSkillComplete"))
        if not self.RootUi.GameObject or XTool.UObjIsNil(self.RootUi.GameObject) then
            return
        end
        XUiManager.PopupLeftTip(CS.XTextManager.GetText("CharacterUngradeSkillComplete"))
        self.RootUi:RefreshData()
    end, ClientLongPressIncreaseLevel)
end

function XUiPanelSkillDetailsInfo:OnLongPress(pressingTime)
    if self.NotMaskShow then --增加mask，阻止长按时候玩家的其他操作
        self.NotMaskShow = false
        self.PanelMask.gameObject:SetActiveEx(true)
    end
    local clientShowLevelParam = 0
    local minMax
    if pressingTime > LONG_CLICK_OFFSET * LONG_PRESS_PARAMS then
        --控制延时刷新，避免点击一次就刷新技能升级预览
        local originalLevel = self.CharacterAgency:GetSkillLevel(self.SubSkillId)
        minMax = XCharacterConfigs.GetSubSkillMinMaxLevel(self.SubSkillId)
        self.ClientLongPressIncreaseLevel = self.ClientLongPressIncreaseLevel + 1
        clientShowLevelParam = self.ClientLongPressIncreaseLevel + originalLevel
        local canUpdate = self.CharacterAgency:CheckCanUpdateSkillMultiLevel(self.CharacterId, self.SubSkillId, originalLevel, clientShowLevelParam - 1)--当前等级的消耗是升级到下一级的，所以判断升级的时候-1
        if canUpdate then
            if (clientShowLevelParam > minMax.Max) then
                clientShowLevelParam = minMax.Max
            end
            self.ClientShowLevelParam = clientShowLevelParam
            self.RootUi:RefreshData(self.ClientShowLevelParam, self.SubSkill)
        else
            return true, true --回调参数即使时间短也要加弹窗提示
        end
    end
end

function XUiPanelSkillDetailsInfo:OnLongPressUp()
    self.NotMaskShow = true
    self.PanelMask.gameObject:SetActiveEx(false)
    if XTool.IsTableEmpty(self.SubSkill) then
        return
    end
    local originalLevel =  self.CharacterAgency:GetSkillLevel(self.SubSkillId)
    local minMax = XCharacterConfigs.GetSubSkillMinMaxLevel(self.SubSkillId)
    for i = originalLevel, self.ClientShowLevelParam - 1  do --当前等级的消耗是升级到下一级的需要减一操作
        local gradeConfig = XCharacterConfigs.GetSkillGradeConfig(self.SubSkillId, i)
        if not gradeConfig then break end
        self.LongPressCostCoin = self.LongPressCostCoin + gradeConfig.UseCoin
        self.LongPressCostSkillPoint = self.LongPressCostSkillPoint + gradeConfig.UseSkillPoint
    end
    if  self.LongPressCostCoin <= 0 and self.LongPressCostSkillPoint <= 0  then --无消耗就无升级
        return
    end
    local textParam = "LongPressLevelUpSkill"
    if minMax and minMax.Max == self.ClientShowLevelParam then
        textParam = "LongPressLevelUpSkillMax"
    end
    local content = CSXTextManagerGetText(textParam, self.LongPressCostCoin, self.LongPressCostSkillPoint, self.ClientShowLevelParam)
    local tempClientShowLevelParam = self.ClientShowLevelParam
    local sureCallBack = function()
        self:OnBtnUpgradeClick(tempClientShowLevelParam - originalLevel)
    end

    local closeCallback = function()
        self.RootUi:RefreshData()
    end
    self:ResetLongPressData()
    local title = CS.XTextManager.GetText("TipTitle")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, closeCallback, sureCallBack)
end

--endregion

function XUiPanelSkillDetailsInfo:OnDisable()
    self.Clicker:Reset()
    self:ResetLongPressData()
end

function XUiPanelSkillDetailsInfo:OnBtnSkillPointClick()
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.ItemId.SkillPoint)
end

function XUiPanelSkillDetailsInfo:OnBtnCoinClick()
    local itemId = XDataCenter.ItemManager.ItemId.Coin

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

return XUiPanelSkillDetailsInfo