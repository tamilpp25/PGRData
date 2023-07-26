local XUiGuidMultiDimSelectDifficult = XClass(nil, "XUiGuidMultiDimSelectDifficult")

function XUiGuidMultiDimSelectDifficult:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self:RegisterUiEvents()
end

function XUiGuidMultiDimSelectDifficult:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnSelectClick)
end

function XUiGuidMultiDimSelectDifficult:OnBtnSelectClick()
    XUiManager.TipText("MultiDimDifficultySelectSucceed")
    self.RootUi:OnClick(self.DifficultyInfo.DifficultyId,self.DifficultyInfo.StageId)
end

function XUiGuidMultiDimSelectDifficult:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGuidMultiDimSelectDifficult:Refresh(difficultyInfo, currentDifficulty)
    self.DifficultyInfo = difficultyInfo
    self.DifficultyInfoDetail = XDataCenter.MultiDimManager.GetDifficultyDetailInfo(difficultyInfo.ThemeId, difficultyInfo.DifficultyId)
    -- 难度
    self.TxtDiffcult.text = self.DifficultyInfoDetail.Name
    self.TxtDiffcult.color = XUiHelper.Hexcolor2Color(self.DifficultyInfoDetail.Color)
    -- 推荐战力
    local abilityText = "MultiDimDifficultyAbilityText"
    if difficultyInfo.IsOnRank == 1 then
        abilityText = "MultiDimHighDifficultyAbilityText"
    end
    self.TxtAbility.text = CSXTextManagerGetText(abilityText, difficultyInfo.FightAbility)
    -- 描述
    self.TxtPoint.text = self.DifficultyInfoDetail.Description
    -- 选择状态
    local isSelect = difficultyInfo.DifficultyId == currentDifficulty
    self.PanelCurSelect.gameObject:SetActiveEx(isSelect)
    self.BtnSelect.gameObject:SetActiveEx(not isSelect)

    self.PanelDifficultyText.gameObject:SetActiveEx(false)
    if not isSelect then
        local isUnlock, limitName = self:CheckIsUnlock(difficultyInfo.ThemeId, difficultyInfo.DifficultyId)
        -- 锁定描述
        self.PanelDifficultyText.text = XUiHelper.ConvertLineBreakSymbol(CSXTextManagerGetText("MultiDimDifficultyLimitDescription", limitName))
        -- 锁定状态
        self.PanelDifficultyText.gameObject:SetActiveEx(not isUnlock)
        self.BtnSelect.gameObject:SetActiveEx(isUnlock)
    end
end

function XUiGuidMultiDimSelectDifficult:CheckIsUnlock(themeId, difficultyId)
    local currentDifficulty = difficultyId
    local isUnlock = true
    local limitName = ""
    while true do
        local infoDetail = XDataCenter.MultiDimManager.GetDifficultyDetailInfo(themeId, currentDifficulty)
        local isLimitShow = infoDetail.IsLimitShow
        if not XTool.IsNumberValid(isLimitShow) then
            break
        end
        local limitShowInfo = XDataCenter.MultiDimManager.GetDifficultyDetailInfo(themeId, isLimitShow)
        local isPass = XDataCenter.MultiDimManager.CheckTodayIsPass(limitShowInfo.Id)
        -- 锁定状态
        if not isPass then
            limitName = limitShowInfo.Name or ""
            isUnlock = false
            break
        end
        currentDifficulty = isLimitShow
    end
    return isUnlock, limitName
end

return XUiGuidMultiDimSelectDifficult