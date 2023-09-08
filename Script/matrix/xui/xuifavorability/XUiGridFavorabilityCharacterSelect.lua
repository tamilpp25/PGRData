local XUiGridFavorabilityCharacterSelect = XClass(XUiNode, "XUiGridFavorabilityCharacterSelect")

-- 更新数据
function XUiGridFavorabilityCharacterSelect:OnRefresh(charData, rootUi)
    if not charData then
        return
    end

    self.RootUi = rootUi
    local trustExp = self._Control:GetTrustExpById(charData.Id)
    self.Data = charData
    self.TxtLevel.text = charData.TrustLv
    self.TxtDisplayLevel.text = self._Control:GetWordsWithColor(charData.TrustLv, trustExp[charData.TrustLv].Name)
    self.RImgAIxin:SetSprite(self._Control:GetTrustLevelIconByLevel(charData.TrustLv))
    self.ImgIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(charData.Id))
    
    --2.7判断是否是助理：助理默认选中
    if self.ImgAssist then
        self.ImgAssist.gameObject:SetActiveEx(self.Data.IsAssistant)
    end
    
    -- 选中状态
    self.ImgSelect.gameObject:SetActiveEx(false)
    self:RefreshSelectedState()
end

function XUiGridFavorabilityCharacterSelect:RefreshSelectedState()
    self.ImgSelect.gameObject:SetActiveEx(self.Data.IsSelected)
    self.RootUi:SetSelectedCurrChar(self.Data.Id, self.Data.IsSelected)
end

function XUiGridFavorabilityCharacterSelect:OnBtnClick()
    --self.RootUi:SetAllGridCancelSelect(self.Data.Id) -- 做成单选效果
    if self.RootUi:OnGridClickRequest(not self.Data.IsSelected) then
        self.Data.IsSelected = not self.Data.IsSelected
        --每次点击都是一次更新，其中偶数次将还原状态，奇数次将改变状态
        self.RootUi.ChangeCache[self.Data.Id]= self.RootUi.ChangeCache[self.Data.Id]==nil and self.Data or nil
        self:RefreshSelectedState()
    end
end

function XUiGridFavorabilityCharacterSelect:CancelSelect()
    self.Data.IsSelected = false
    self:RefreshSelectedState()
end

return XUiGridFavorabilityCharacterSelect