local XUiGridFavorabilityCharacterSelect = XClass(nil, "XUiGridFavorabilityCharacterSelect")

function XUiGridFavorabilityCharacterSelect:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- 更新数据
function XUiGridFavorabilityCharacterSelect:OnRefresh(charData, rootUi)
    if not charData then
        return
    end

    self.RootUi = rootUi
    local trustExp = XFavorabilityConfigs.GetTrustExpById(charData.Id)
    self.Data = charData
    self.TxtLevel.text = charData.TrustLv
    self.TxtDisplayLevel.text = XFavorabilityConfigs.GetWordsWithColor(charData.TrustLv, trustExp[charData.TrustLv].Name)
    self.RImgAIxin:SetSprite(XFavorabilityConfigs.GetTrustLevelIconByLevel(charData.TrustLv))
    self.ImgIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(charData.Id))
    
    -- 选中状态
    self.ImgSelect.gameObject:SetActiveEx(false)
    self:RefreshSelectedState()
end

function XUiGridFavorabilityCharacterSelect:RefreshSelectedState()
    self.ImgSelect.gameObject:SetActiveEx(self.Data.IsSelected)
    self.RootUi:SetSelectedCurrChar(self.Data.Id, self.Data.IsSelected)
end

function XUiGridFavorabilityCharacterSelect:OnBtnClick()
    self.RootUi:SetAllGridCancelSelect(self.Data.Id) -- 做成单选效果
    self.Data.IsSelected = not self.Data.IsSelected

    self:RefreshSelectedState()
end

function XUiGridFavorabilityCharacterSelect:CancelSelect()
    self.Data.IsSelected = false
    self:RefreshSelectedState()
end

return XUiGridFavorabilityCharacterSelect