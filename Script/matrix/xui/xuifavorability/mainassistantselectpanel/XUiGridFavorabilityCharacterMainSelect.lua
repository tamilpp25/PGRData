local XUiGridFavorabilityCharacterMainSelect=XClass(XUiNode,'XUiGridFavorabilityCharacterMainSelect')

-- 更新数据
function XUiGridFavorabilityCharacterMainSelect:OnRefresh(charData, rootUi)
    if not charData then
        return
    end

    self.RootUi = rootUi
    local trustExp = self._Control:GetTrustExpById(charData.Id)
    self.Data = charData
    self.TxtLevel.text = charData.TrustLv
    self.TxtDisplayLevel.text = self._Control:GetWordsWithColor(charData.TrustLv, trustExp[charData.TrustLv].Name)
    self.RImgAIxin:SetSprite(self._Control:GetTrustLevelIconByLevel(charData.TrustLv))
    self.ImgIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(charData.Id))

    if self.ImgAssist then
        self.ImgAssist.gameObject:SetActiveEx(self.Data.IsAssistant and not self.Data.MainAssistant)
    end
    if self.ImgAssistMain then
        self.ImgAssistMain.gameObject:SetActiveEx(self.Data.MainAssistant)
    end

    -- 选中状态
    self.ImgSelect.gameObject:SetActiveEx(false)
    self:RefreshSelectedState()
end

function XUiGridFavorabilityCharacterMainSelect:RefreshSelectedState()
    self.ImgSelect.gameObject:SetActiveEx(self.Data.IsSelected)
    self.RootUi:SetSelectedCurrChar(self.Data.Id, self.Data.IsSelected)
end

function XUiGridFavorabilityCharacterMainSelect:OnBtnClick()
    if not self.Data.IsSelected then
        self.RootUi:SetAllGridCancelSelect(self.Data.Id) -- 做成单选效果
        self.Data.IsSelected = not self.Data.IsSelected
        self.RootUi.IsSelectAssistant=self.Data.IsAssistant
        self:RefreshSelectedState()
    end
end

function XUiGridFavorabilityCharacterMainSelect:CancelSelect()
    self.Data.IsSelected = false
    self:RefreshSelectedState()
end

return XUiGridFavorabilityCharacterMainSelect