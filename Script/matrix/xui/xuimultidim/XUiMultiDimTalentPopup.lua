local XUiMultiDimTalentPopup = XLuaUiManager.Register(XLuaUi, "UiMultiDimTalentPopup")

function XUiMultiDimTalentPopup:OnAwake()
    self:RegisterUiEvents()
end

function XUiMultiDimTalentPopup:OnGetEvents()
    return {
        XEventId.EVENT_MULTI_DIM_TALENT_LEVEL_UPDATE,
    }
end

function XUiMultiDimTalentPopup:OnNotify(event, ...)
    if event == XEventId.EVENT_MULTI_DIM_TALENT_LEVEL_UPDATE then
        -- 刷新UI
        self:RefreshView()
    end
end

function XUiMultiDimTalentPopup:Refresh(careerId, talentType, cb)
    self.CareerId = careerId
    self.TalentType = talentType
    self.CallBack = cb
    
    self:RefreshView()
end

function XUiMultiDimTalentPopup:RefreshView()
    -- 图标
    local icon = XDataCenter.MultiDimManager.GetTalentIcon(self.CareerId, self.TalentType)
    self.RImgIcon:SetRawImage(icon)
    -- 名称
    local name = XDataCenter.MultiDimManager.GetTalentName(self.CareerId, self.TalentType)
    self.TxtName.text = name
    -- 等级
    local level = XDataCenter.MultiDimManager.GetTalentLevel(self.CareerId, self.TalentType)
    self.TxtLevel.text = level
    local isLowestLevel = level == 0
    self.TxtCurrentDes.gameObject:SetActiveEx(not isLowestLevel)
    self.TxtCurrentTitle.gameObject:SetActiveEx(not isLowestLevel)
    if not isLowestLevel then
        -- 当前描述
        self.TxtCurrentDes.text = XDataCenter.MultiDimManager.GetTalentDescription(self.CareerId, self.TalentType)
    end
    -- 是否满级
    local isHighLevel = XDataCenter.MultiDimManager.GetTalentIsHighLevel(self.CareerId, self.TalentType)
    local isHigh = isHighLevel == 1
    self.BtnUnlock:SetButtonState(isHigh and XUiButtonState.Disable or XUiButtonState.Normal)
    self.TxtCostUnlock.gameObject:SetActiveEx(not isHigh)
    self.TxtNextTitle.gameObject:SetActiveEx(not isHigh)
    self.TxtNextDes.gameObject:SetActiveEx(not isHigh)
    -- 是否是核心天赋
    local isCoreTalent = self.TalentType == XMultiDimConfig.TalentType.CoreTalent
    -- 主天赋显示
    self.PanelMasterTalent.gameObject:SetActiveEx(isCoreTalent)
    self.BtnUnlock.gameObject:SetActiveEx(not isCoreTalent)
    self.TxtRemind.gameObject:SetActiveEx(isCoreTalent)
    if not isHigh then
        -- 下级描述
        local nextLevel = XDataCenter.MultiDimManager.GetTalentNextLevel(self.CareerId, self.TalentType)
        self.TxtNextDes.text = XDataCenter.MultiDimManager.GetTalentDescription(self.CareerId, self.TalentType, nextLevel)
        
        if not isCoreTalent then
            local costItemId = XDataCenter.MultiDimManager.GetTalentCostItemId(self.CareerId, self.TalentType)
            -- 代币图标
            local coinIcon = XEntityHelper.GetItemIcon(costItemId)
            self.RImgCostUnlock:SetRawImage(coinIcon)
            -- 消耗代币的数量
            local costItemCount = XDataCenter.MultiDimManager.GetTalentCostItemCount(self.CareerId, self.TalentType)
            self.TxtCostUnlock.text = costItemCount
        end
    end
end

function XUiMultiDimTalentPopup:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUnlock, self.OnBtnUnlockClick)
end

function XUiMultiDimTalentPopup:OnBtnCloseClick()
    if self.CallBack then
        self.CallBack()
    end
    self:Close()
end

function XUiMultiDimTalentPopup:OnBtnUnlockClick()
    -- 是否满级
    local isHighLevel = XDataCenter.MultiDimManager.GetTalentIsHighLevel(self.CareerId, self.TalentType)
    if isHighLevel == 1 then -- 已满级
        return
    end
    
    -- 代币Id
    local costItemId = XDataCenter.MultiDimManager.GetTalentCostItemId(self.CareerId, self.TalentType)
    -- 升级需要消耗代币的数量
    local costItemCount = XDataCenter.MultiDimManager.GetTalentCostItemCount(self.CareerId, self.TalentType)
    -- 判断代币的数量是否足够
    if XDataCenter.ItemManager.GetCount(costItemId) < costItemCount then
        XUiManager.TipMsg(CSXTextManagerGetText("MultiDimTalentNotItemCountTips", XEntityHelper.GetItemName(costItemId)))
        return
    end
    local talentId = XDataCenter.MultiDimManager.GetTalentId(self.CareerId, self.TalentType)
    -- 提升天赋
    XDataCenter.MultiDimManager.MultiDimUpgradeTalentRequest(talentId, function()
        XUiManager.TipText("MultiDimTalentUpgradeSucceed")
    end)
end

return XUiMultiDimTalentPopup