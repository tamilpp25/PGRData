local XUiGridLikeRoleItem=require("XUi/XUiFavorability/XUiGridLikeRoleItem")
---@class XUiPanelFavorabilityExchangeRole
local XUiPanelFavorabilityExchangeRole = XClass(XUiNode, "XUiPanelFavorabilityExchangeRole")

function XUiPanelFavorabilityExchangeRole:OnStart()
    self.BtnCancel.CallBack = function() self:OnBtnCancelClick() end

end

function XUiPanelFavorabilityExchangeRole:OnDisable()
    if self.DynamicTabelCharacters then
        self.DynamicTabelCharacters:RecycleAllTableGrid()
    end
end


-- [刷新切换角色界面]
function XUiPanelFavorabilityExchangeRole:RefreshDatas()
    self:LoadDatas()
end

function XUiPanelFavorabilityExchangeRole:LoadDatas()
    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    local allCharDatas = XMVCA.XCharacter:GetCharacterList()
    local characterList = {}
    for _, v in pairs(allCharDatas or {}) do
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(v.Id)
        local isin,index=table.contains(XPlayer.DisplayCharIdList, v.Id)
        if isOwn then
            table.insert(characterList, {
                Id = v.Id,
                TrustLv = v.TrustLv or 1,
                Selected = (characterId == v.Id),
                IsAssistant=isin,
                MainAssistant=isin and index==1
            })
        end
    end
    table.sort(characterList, function(characterA, characterB)
        --首席优先
        if characterA.MainAssistant~=characterB.MainAssistant then
            return characterA.MainAssistant
        end
        
        --助理优先
        if characterA.IsAssistant~=characterB.IsAssistant then
            return characterA.IsAssistant
        end
        
        if characterA.TrustLv == characterB.TrustLv then
            return characterA.Id < characterB.Id
        end
        return characterA.TrustLv > characterB.TrustLv
    end)

    self:UpdateCharacterList(characterList)
end

-- [刷新角色ListView]
function XUiPanelFavorabilityExchangeRole:UpdateCharacterList(charList)
    if not charList then
        XLog.Warning("XUiPanelFavorabilityExchangeRole:UpdateCharacterList error: charList is nil")
        return
    end

    self.CharList = charList

    if not self.DynamicTabelCharacters then
        self.DynamicTabelCharacters = XDynamicTableNormal.New(self.SViewSelectRole.gameObject)
        self.DynamicTabelCharacters:SetProxy(XUiGridLikeRoleItem,self.Parent)
        self.DynamicTabelCharacters:SetDelegate(self)
    end

    self.DynamicTabelCharacters:SetDataSource(self.CharList)
    self.DynamicTabelCharacters:ReloadDataASync()

end

-- [监听动态列表事件]
function XUiPanelFavorabilityExchangeRole:OnDynamicTableEvent(event, index, grid)
    if not self.Parent then return end
    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.CharList[index]
        if not data then return end
        grid:OnRefresh(self.CharList[index], index)
        if characterId == data.Id then
            self.CurCharacter = self.CharList[index]
            self.CurCharacterGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.CurCharacter = self.CharList[index]
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(self.CurCharacter.Id)
        if not isOwn then
            XUiManager.TipMsg(CS.XTextManager.GetText("FavorabilityNotOwnChar"))
            return
        end

        if self.CurCharacterGrid then
            if self.CurCharacter then
                self.CurCharacter.Selected = false
            end
            self.CurCharacterGrid:OnSelect()
        end

        self.CurCharacter.Selected = true
        grid:OnSelect()
        self.CurCharacterGrid = grid
        self:OnChangeCharacter()
    end
end

-- [换人确定按钮]
function XUiPanelFavorabilityExchangeRole:OnChangeCharacter()
    if self.CurCharacter == nil then
        return
    end

    local isOwn = XMVCA.XCharacter:IsOwnCharacter(self.CurCharacter.Id)
    if not isOwn then
        XUiManager.TipError(CS.XTextManager.GetText("FavorabilityNotOwnChar"))
        return
    end

    self.Parent:StopCvContent()
    self.Parent:SetCurrFavorabilityCharacter(self.CurCharacter.Id)
    self.Parent:UpdateCamera(false)
    self.Parent:CloseChangeRoleView()
end

-- [取消按钮]
function XUiPanelFavorabilityExchangeRole:OnBtnCancelClick()
    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    self.Parent:ChangeCharacterModel(characterId)
    self.Parent:UpdateCamera(false)
    self.Parent:CloseChangeRoleView()
end

return XUiPanelFavorabilityExchangeRole