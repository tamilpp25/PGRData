local XUiFavorabilityLineRoomCharacterMainSelect=XLuaUiManager.Register(XLuaUi,"UiFavorabilityLineRoomCharacterMainSelect")
local XUiGridFavorabilityCharacterMainSelect=require('XUi/XUiFavorability/MainAssistantSelectPanel/XUiGridFavorabilityCharacterMainSelect')

--region 生命周期
function XUiFavorabilityLineRoomCharacterMainSelect:OnAwake()
    self.OrgSelected = nil
    self:InitButtonEvent()
    self:InitDynamicTable()
end

function XUiFavorabilityLineRoomCharacterMainSelect:OnStart(currCharacter)
    self.OrgSelected = currCharacter
end

function XUiFavorabilityLineRoomCharacterMainSelect:OnEnable()
    self:RefreshDynamicTable()
end
--endregion

--region 初始化
function XUiFavorabilityLineRoomCharacterMainSelect:InitButtonEvent()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnCancel, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiFavorabilityLineRoomCharacterMainSelect:InitDynamicTable()
    self.DynamicTableCharacter = XDynamicTableNormal.New(self.PanelSelectList.gameObject)
    self.DynamicTableCharacter:SetProxy(XUiGridFavorabilityCharacterMainSelect,self)
    self.DynamicTableCharacter:SetDelegate(self)
    self.GridChar.gameObject:SetActiveEx(false)
end
--endregion

--region 数据更新
function XUiFavorabilityLineRoomCharacterMainSelect:RefreshDynamicTable()
    self.CharaList = self:GetCharaterList()
    if not self.CharaList or not next(self.CharaList) then
        self.ImgNonePerson.gameObject:SetActiveEx(true) -- 无助理背景标签
        return
    else
        self.ImgNonePerson.gameObject:SetActiveEx(false)
    end
    self.DynamicTableCharacter:SetDataSource(self.CharaList)
    self.DynamicTableCharacter:ReloadDataASync()
end
--endregion

--region 数据处理
function XUiFavorabilityLineRoomCharacterMainSelect:GetCharaterList()
    self.Count=0
    local result = {}
    local charaList = XMVCA.XCharacter:GetCharacterList()
    --筛选
    for k, character in pairs(charaList) do
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(character.Id)
        if isOwn then
            local isin,index=table.contains(XPlayer.DisplayCharIdList, character.Id)
            local value =
            {
                -- 设置默认信任度等级
                Id = character.Id,
                TrustLv = character.TrustLv or 1,
                IsAssistant=isin,
                MainAssistant=isin and index==1
            }
            if self.OrgSelected and self.OrgSelected.Id == character.Id then
                value.IsOrg = true
                value.IsSelected = true
            end
            table.insert(result, value)
        end
    end

    --排序
    table.sort(result, function (characterA, characterB)
        if characterA.IsOrg ~= characterB.IsOrg then
            return characterA.IsOrg
        end

        if characterA.IsAssistant ~= characterB.IsAssistant then
            return characterA.IsAssistant==true
        end

        if characterA.TrustLv == characterB.TrustLv then
            return characterA.Id < characterB.Id
        end
        return characterA.TrustLv > characterB.TrustLv
    end)

    return result
end

function XUiFavorabilityLineRoomCharacterMainSelect:SetAllGridCancelSelect(exceptId)
    for k, data in pairs(self.CharaList) do
        if data.Id ~= exceptId then -- 排除的格子
            data.IsSelected = false
        end
    end

    -- 并刷新格子状态
    for i = 1, self.DynamicTableCharacter.Imp.TotalCount - 1 do
        local grid = self.DynamicTableCharacter:GetGridByIndex(i)
        if grid then
            grid:RefreshSelectedState()
        end
    end
end

function XUiFavorabilityLineRoomCharacterMainSelect:SetSelectedCurrChar(characterId, isSelcted)
    if not isSelcted and characterId == self.SelectedCharaterId then -- 只有点击被选择的格子，才能取消（该格子类型都是单选格子）
        self.SelectedCharaterId = nil
    end

    if isSelcted then
        self.SelectedCharaterId = characterId
    end
end
--endregion

--region 事件
function XUiFavorabilityLineRoomCharacterMainSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:OnRefresh(self.CharaList[index], self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnBtnClick()
    end
end

function XUiFavorabilityLineRoomCharacterMainSelect:OnBtnConfirmClick()
    -- 重复
    if self.SelectedCharaterId==self.OrgSelected.Id then
        self:Close()
        return
    end
    
    if self.IsSelectAssistant then    -- 助理之间更换
        XDataCenter.DisplayManager.SetDisplayCharIdFirstRequest(self.SelectedCharaterId, function (res)
            self.SelectIndex = 0 -- 设置首席后重新选定默认下标为0
            local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.SelectedCharaterId)
            local name = charConfig.Name.. "·"..charConfig.TradeName
            XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilitySetChiefAssistSucc", name))
        end)
    else     --更换并直接提拔首席助理
        XDataCenter.DisplayManager.UpdatePlayerDisplayCharIdRequest(self.OrgSelected.Id, self.SelectedCharaterId, function(res)
            if res.DisplayCharIdList and table.contains(res.DisplayCharIdList,self.SelectedCharaterId) then
                local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.SelectedCharaterId)
                local name = charConfig.Name.. "·"..charConfig.TradeName
                XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilitySetChiefAssistSucc", name))
            end
        end)
    end
    self:Close()
end

function XUiFavorabilityLineRoomCharacterMainSelect:OnBtnTanchuangCloseClick()
    if self.SelectedCharaterId~=self.OrgSelected.Id then
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"),XUiHelper.GetText('FavorabilityCharacterSelectChangeTips'),XUiManager.DialogType.Normal,nil,function()
            self:OnBtnConfirmClick()
        end)
    else
        self:Close()
    end
end
--endregion


return XUiFavorabilityLineRoomCharacterMainSelect