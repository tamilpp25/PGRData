local XUiFavorabilityLineRoomCharacterSelect = XLuaUiManager.Register(XLuaUi, "UiFavorabilityLineRoomCharacterSelect")
local XUiGridFavorabilityCharacterSelect = require("XUi/XUiFavorability/XUiGridFavorabilityCharacterSelect")

-- 更换选择助理弹窗界面
function XUiFavorabilityLineRoomCharacterSelect:OnAwake()
    self.OrgSelected = nil
    self:InitButtonEvent()
    self:InitDynamicTable()
end

function XUiFavorabilityLineRoomCharacterSelect:InitButtonEvent()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnCancel, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiFavorabilityLineRoomCharacterSelect:InitDynamicTable()
    self.DynamicTableCharacter = XDynamicTableNormal.New(self.PanelSelectList.gameObject)
    self.DynamicTableCharacter:SetProxy(XUiGridFavorabilityCharacterSelect)
    self.DynamicTableCharacter:SetDelegate(self)
    self.GridChar.gameObject:SetActiveEx(false)
end

function XUiFavorabilityLineRoomCharacterSelect:OnStart(currCharacter)
    self.OrgSelected = currCharacter
end

function XUiFavorabilityLineRoomCharacterSelect:OnEnable()
    self:RefreshDynamicTable()
end

function XUiFavorabilityLineRoomCharacterSelect:GetCharaterList()
    local result = {}
    local charaList = XDataCenter.CharacterManager.GetCharacterList()
    for k, character in pairs(charaList) do
        local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(character.Id) 
        if isOwn and ((not table.contains(XPlayer.DisplayCharIdList, character.Id)) or (self.OrgSelected and self.OrgSelected.Id == character.Id)) then -- 选人界面只显示不在助理队列里的构造体（除了自己）
            local value = 
            {
                -- 设置默认信任度等级
                Id = character.Id,
                TrustLv = character.TrustLv or 1,
            }
            if self.OrgSelected and self.OrgSelected.Id == character.Id then
                value.IsOrg = true
                value.IsSelected = true
            end
            table.insert(result, value)
        end
    end
   
    table.sort(result, function (characterA, characterB)
        if characterA.IsOrg ~= characterB.IsOrg then
            return characterA.IsOrg
        end
    
        if characterA.TrustLv == characterB.TrustLv then
            return characterA.Id < characterB.Id
        end
        return characterA.TrustLv > characterB.TrustLv
    end)

    return result
end

function XUiFavorabilityLineRoomCharacterSelect:RefreshDynamicTable()
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

-- 将所有的格子设为非选中
function XUiFavorabilityLineRoomCharacterSelect:SetAllGridCancelSelect(exceptId)
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

function XUiFavorabilityLineRoomCharacterSelect:SetSelectedCurrChar(characterId, isSelcted)
    if not isSelcted and characterId == self.SelectedCharaterId then -- 只有点击被选择的格子，才能取消（该格子类型都是单选格子）
        self.SelectedCharaterId = nil
    end
    
    if isSelcted then
        self.SelectedCharaterId = characterId
    end
end

-- [监听动态列表事件]
function XUiFavorabilityLineRoomCharacterSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:OnRefresh(self.CharaList[index], self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnBtnClick()
    end
end

function XUiFavorabilityLineRoomCharacterSelect:OnBtnConfirmClick()
    -- 这个函数需要判断3种情况
    -- 1.【替换】角色到助理队列
    -- 2.【移除】在队列中的角色
    -- 3.【添加】新的角色到助理队列
    if self.OrgSelected and self.SelectedCharaterId then -- 1.替换
        if self.OrgSelected.Id == self.SelectedCharaterId then
            self:Close()
            return
        end
        local newCharId = self.SelectedCharaterId
        local oldCharId = self.OrgSelected.Id

        XDataCenter.DisplayManager.UpdatePlayerDisplayCharIdRequest(oldCharId, newCharId, function(res)
            if res.DisplayCharIdList and newCharId == res.DisplayCharIdList[1] then
                local charConfig = XCharacterConfigs.GetCharacterTemplate(newCharId)
                local name = charConfig.Name.. "·"..charConfig.TradeName
                XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilitySetChiefAssistSucc", name))
            end
        end)
    elseif self.OrgSelected and not self.SelectedCharaterId then -- 2.移除
        if XPlayer.DisplayCharIdList and #XPlayer.DisplayCharIdList <= 1 then
            XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityNotRemoveOnlyAssist"))
            return 
        end

        XNetwork.Call("RemovePlayerDisplayCharIdRequest", {CharId = self.OrgSelected.Id}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local charConfig = XCharacterConfigs.GetCharacterTemplate(self.OrgSelected.Id)
            local name = charConfig.Name.. "·"..charConfig.TradeName
            XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityRemoveAssistSucc", name))
            XPlayer.SetDisplayCharIdList(res.DisplayCharIdList)
        end)
    elseif not self.OrgSelected and self.SelectedCharaterId then  -- 3.添加
        XDataCenter.DisplayManager.AddPlayerDisplayCharIdRequest(self.SelectedCharaterId)
    end
    
    self:Close()
end
