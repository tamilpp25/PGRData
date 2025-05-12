local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiEquipResonanceSelectEquipV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSelectEquipV2P6")

function XUiEquipResonanceSelectEquipV2P6:OnAwake()
    self.GridEquip.gameObject:SetActiveEx(false)

    self.TAB_TYPE = { TOKEN = 1, WEAPON = 2, AWARENESS = 3, ITEM = 4 }

    self:SetButtonCallBack()
    self:InitTabGroup()
    self:InitDynamicTable()
end

function XUiEquipResonanceSelectEquipV2P6:OnStart(equipId, confirmCb, isHideTokenTab, isHideItemTab)
    self.EquipId = equipId
    self.ConfirmCb = confirmCb
    self.IsHideTokenTab = isHideTokenTab or false
    self.IsHideItemTab = isHideItemTab or false
    self.TemplateId = self._Control:GetEquipTemplateId(equipId)

    self:RefreshTabGroup()
end

function XUiEquipResonanceSelectEquipV2P6:OnEnable()
end

function XUiEquipResonanceSelectEquipV2P6:OnRelease()
    self.ConfirmCb = nil
    self.TokenInfoList = nil
    self.WeaponIdList = nil
    self.AwarenessIdList = nil
    self.ItemInfoList = nil

    self.BtnList = nil
    self.DynamicTable = nil
end

function XUiEquipResonanceSelectEquipV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.Btncancel, self.OnBtnCloseClick)
end

function XUiEquipResonanceSelectEquipV2P6:OnBtnCloseClick()
    self:Close()
end

function XUiEquipResonanceSelectEquipV2P6:OnBtnConfirmClick()
    if not self:IsBtnConfirmActive() then
        return
    end

    if self.TabIndex == self.TAB_TYPE.TOKEN then
        local tokenId = self.TokenInfoList[self.SelIndex].TemplateId
        self.ConfirmCb(nil, tokenId)
    elseif self.TabIndex == self.TAB_TYPE.WEAPON then
        local weaponId = self.WeaponIdList[self.SelIndex]
        self.ConfirmCb(weaponId, nil)
    elseif self.TabIndex == self.TAB_TYPE.AWARENESS then
        local awarenessId = self.AwarenessIdList[self.SelIndex]
        self.ConfirmCb(awarenessId, nil)
    elseif self.TabIndex == self.TAB_TYPE.ITEM then
        local itemId = self.ItemInfoList[self.SelIndex].TemplateId
        self.ConfirmCb(nil, itemId)
    end
    XLuaUiManager.Remove(self.Name)
end

function XUiEquipResonanceSelectEquipV2P6:InitTabGroup()
    self.BtnList = {
        self.BtnTabToken,
        self.BtnTabWeapon,
        self.BtnTabAwareness,
        self.BtnTabItem,
    }

    self.PanelTabList:Init(self.BtnList, function(tabIndex)
        self:OnClickTab(tabIndex)
    end)
end

function XUiEquipResonanceSelectEquipV2P6:OnClickTab(index)
    if self.TabIndex == index then
        return
    end

    self.TabIndex = index
    self.SelIndex = nil
    if self.TabIndex == self.TAB_TYPE.TOKEN then
        self:RefreshTokenList()
    elseif self.TabIndex == self.TAB_TYPE.WEAPON then
        self:RefreshWeaponList()
    elseif self.TabIndex == self.TAB_TYPE.AWARENESS then
        self:RefreshAwarenessList()
    elseif self.TabIndex == self.TAB_TYPE.ITEM then
        self:RefreshItemList()
    end

    self:RefreshBtnConfirm()
    self:RefreshTitle()
    self:PlayAnimation("QieHuan")
end

-- 刷新页签显示和选中
function XUiEquipResonanceSelectEquipV2P6:RefreshTabGroup()
    local isWeapon = self._Control:IsEquipWeapon(self.TemplateId)
    self.BtnTabWeapon.gameObject:SetActiveEx(isWeapon)
    self.BtnTabAwareness.gameObject:SetActiveEx(not isWeapon)

    local isShowToken = not isWeapon and not self.IsHideTokenTab and self._Control:IsResonanceShowToken(self.TemplateId)
    self.BtnTabToken.gameObject:SetActiveEx(isShowToken)
    local isShowItem = not self.IsHideItemTab
    self.BtnTabItem.gameObject:SetActiveEx(isShowItem)

    self.TabIndex = nil
    if isWeapon then
        self.PanelTabList:SelectIndex(self.TAB_TYPE.WEAPON)
    else
        local tabIndex = isShowToken and self.TAB_TYPE.TOKEN or self.TAB_TYPE.AWARENESS
        self.PanelTabList:SelectIndex(tabIndex)
    end
end

function XUiEquipResonanceSelectEquipV2P6:InitDynamicTable()
    local XUiGridEquipResonanceSelectEquipV2P6 = require("XUi/XUiEquip/XUiGridEquipResonanceSelectEquipV2P6")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridEquipResonanceSelectEquipV2P6, self)
end

-- 刷新代币列表
function XUiEquipResonanceSelectEquipV2P6:RefreshTokenList()
    self.TokenInfoList = self.TokenInfoList or self._Control:GetResonanceTokenInfoList(self.TemplateId)
    self:RefreshAutoSelection()
    self.DynamicTable:SetDataSource(self.TokenInfoList)
    self.DynamicTable:ReloadDataASync(self.SelIndex)
    self.PanelNoEquip.gameObject:SetActive(false)
end

-- 刷新武器列表
function XUiEquipResonanceSelectEquipV2P6:RefreshWeaponList()
    if not self.WeaponIdList then
        self.WeaponIdList = self._Control:GetWeaponResonanceCanEatEquipIds(self.EquipId)
        XTool.ReverseList(self.WeaponIdList) --这个UI要初始升序
    end

    self.DynamicTable:SetDataSource(self.WeaponIdList)
    self.DynamicTable:ReloadDataASync()

    local isEmpty = #self.WeaponIdList == 0
    self.PanelNoEquip.gameObject:SetActive(isEmpty)
    if isEmpty then
        self.TxtNoEquip.text = CS.XTextManager.GetText("EquipResonanceNoWeaponTip")
    end
end

-- 刷新意识列表
function XUiEquipResonanceSelectEquipV2P6:RefreshAwarenessList()
    if not self.AwarenessIdList then
        self.AwarenessIdList = self._Control:GetAwarenessResonanceCanEatEquipIds(self.EquipId)
        XTool.ReverseList(self.AwarenessIdList) --这个UI要初始升序
    end

    self.DynamicTable:SetDataSource(self.AwarenessIdList)
    self.DynamicTable:ReloadDataASync()

    local isEmpty = #self.AwarenessIdList == 0
    self.PanelNoEquip.gameObject:SetActive(isEmpty)
    if isEmpty then
        self.TxtNoEquip.text = CS.XTextManager.GetText("EquipResonanceNoAwarenessTip")
    end
end

-- 刷新道具列表
function XUiEquipResonanceSelectEquipV2P6:RefreshItemList()
    if not self.ItemInfoList then
        self.ItemInfoList = {}

        local config = self._Control:GetEquipResonanceUseItem(self.TemplateId)
        for i, itemId in ipairs(config.ItemId) do
            local inTokenTab = self._Control:IsResonanceItemShowInTokenTab(itemId)
            if not inTokenTab then
                local count = XDataCenter.ItemManager.GetCount(itemId)
                if count > 0 then
                    table.insert(self.ItemInfoList, { TemplateId = itemId, CostCnt = config.ItemCount[i] })
                end
            end
        end
        for i, itemId in ipairs(config.SelectSkillItemId) do
            local inTokenTab = self._Control:IsResonanceItemShowInTokenTab(itemId)
            if not inTokenTab then
                local count = XDataCenter.ItemManager.GetCount(itemId)
                if count > 0 then
                    table.insert(self.ItemInfoList, { TemplateId = itemId, CostCnt = config.SelectSkillItemCount[i] })
                end
            end
        end
    end

    self.DynamicTable:SetDataSource(self.ItemInfoList)
    self.DynamicTable:ReloadDataASync()

    local isEmpty = #self.ItemInfoList == 0
    self.PanelNoEquip.gameObject:SetActive(isEmpty)
    if isEmpty then
        self.TxtNoEquip.text = CS.XTextManager.GetText("EquipResonanceNoItemTip")
    end
end

function XUiEquipResonanceSelectEquipV2P6:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local isEquip = self.TabIndex == self.TAB_TYPE.WEAPON or self.TabIndex == self.TAB_TYPE.AWARENESS
        grid:Refresh(self:GetGridData(index), isEquip)

        local isSelected = self.SelIndex == index
        if isSelected then
            self.LastSelectGrid = grid
        end
        grid:SetSelected(isSelected)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.LastSelectGrid then
            self.LastSelectGrid:SetSelected(false)
        end

        grid:SetSelected(true)
        self.LastSelectGrid = grid
        self.SelIndex = index
        self:RefreshBtnConfirm()
    end
end

function XUiEquipResonanceSelectEquipV2P6:GetGridData(index)
    if self.TabIndex == self.TAB_TYPE.TOKEN then
        return self.TokenInfoList[index]
    elseif self.TabIndex == self.TAB_TYPE.WEAPON then
        return self.WeaponIdList[index]
    elseif self.TabIndex == self.TAB_TYPE.AWARENESS then
        return self.AwarenessIdList[index]
    elseif self.TabIndex == self.TAB_TYPE.ITEM then
        return self.ItemInfoList[index]
    end
end

function XUiEquipResonanceSelectEquipV2P6:IsBtnConfirmActive()
    if self.SelIndex == nil then
        return false
    end

    if self.TabIndex == self.TAB_TYPE.TOKEN then
        local data = self:GetGridData(self.SelIndex)
        local ownCnt = XDataCenter.ItemManager.GetCount(data.TemplateId)
        return ownCnt >= data.CostCnt
    else
        return true
    end
end

-- 刷新确定按钮
function XUiEquipResonanceSelectEquipV2P6:RefreshBtnConfirm()
    local isActive = self:IsBtnConfirmActive()
    self.BtnConfirm:SetDisable(not isActive)
end

function XUiEquipResonanceSelectEquipV2P6:RefreshTitle()
    local key = self.TabIndex == self.TAB_TYPE.TOKEN and "ResonanceSelectTitleToken" or "ResonanceSelectTitleItem"
    local title = XUiHelper.GetText(key)
    self.TextSelectTitle.text = title
    self.TextSelectTitleShadow.text = title
end

function XUiEquipResonanceSelectEquipV2P6:RefreshAutoSelection()
    -- 代币需要自选
    if self.TabIndex == self.TAB_TYPE.TOKEN then
        --- 没有选中时才执行
        if not self.SelIndex then
            --- 这个数据是列表结构
            if not XTool.IsTableEmpty(self.TokenInfoList) then
                --- 是否选择了复刷关代币，如果选择了复刷关代币，则不会选择其他代币
                for i, v in ipairs(self.TokenInfoList) do
                    -- 如果已经选择了，除非是复刷关代币，否则跳过
                    if not XTool.IsNumberValid(self.SelIndex) or v.TemplateId == XDataCenter.ItemManager.ItemId.RepeatChallengeCoin then
                        local haveCount = XDataCenter.ItemManager.GetCount(v.TemplateId)
                        if haveCount > v.CostCnt then
                            self.SelIndex = i
                        end
                    end
                end
            end
        end
    end
end

return XUiEquipResonanceSelectEquipV2P6
