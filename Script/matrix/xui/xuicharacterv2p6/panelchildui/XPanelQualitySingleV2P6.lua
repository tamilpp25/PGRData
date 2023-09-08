local XPanelQualitySingleV2P6 = XClass(XUiNode, "XPanelQualitySingleV2P6")

function XPanelQualitySingleV2P6:OnStart(onCharEvolutionCb)
    self.OnCharEvolutionCb = onCharEvolutionCb
    self.PanelModel = self.Parent.ParentUi.PanelModel -- 镜头

    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    
    self:InitButton()
end

function XPanelQualitySingleV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnOverview, self.OnBtnOverviewClick)
    XUiHelper.RegisterClickEvent(self, self.BtnActive, self.OnBtnActiveClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEvolution, self.OnBtnEvolutionClick)

    self.PanelModel:InitQualitySingleRelatedBtn()
    self.PanelModel:SetBtnDropCb(function (quality)
        self:Refresh(quality)
    end)
end

function XPanelQualitySingleV2P6:RefreshSingleBigBall(isActiveNode)
    self.PanelModel:RefreshSingleBigBall(isActiveNode)
end

function XPanelQualitySingleV2P6:RefreshRightDownBtn()
    local character = self.Character
    local isCurSeleQuality = character.Quality == self.SeleQuality
    if not isCurSeleQuality then
        self.BtnActive.gameObject:SetActiveEx(false)
        self.BtnEvolution.gameObject:SetActiveEx(false)
        self.PanelConsume.gameObject:SetActiveEx(false)
        return
    end

    -- 最大品质或当前品质最大星
    local isMaxQuality = self.CharacterAgency:GetCharMaxQuality(character.Id) == character.Quality
    local isMaxStars = character.Star == XEnumConst.CHARACTER.MAX_QUALITY_STAR
    self.BtnActive.gameObject:SetActiveEx(not isMaxStars and not isMaxQuality)
    self.BtnEvolution.gameObject:SetActiveEx(isMaxStars and not isMaxQuality)
    self.PanelConsume.gameObject:SetActiveEx(true)

    -- 红点
    local isRed = XRedPointManager.CheckConditions({XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY }, character.Id)
    self.BtnActive:ShowReddot(isRed)
    self.BtnEvolution:ShowReddot(isRed)
end

function XPanelQualitySingleV2P6:RefreshUseItem()
    local character = self.Character
    local isMaxQuality = self.CharacterAgency:GetCharMaxQuality(character.Id) == character.Quality
    local isMaxStars = character.Star == XEnumConst.CHARACTER.MAX_QUALITY_STAR
    local characterType = XMVCA.XCharacter:GetCharacterType(self.CharacterId)

    if isMaxQuality then
        self.PanelConsume.gameObject:SetActiveEx(false)
        return
    end

    local grid = self.UseItemGrid
    if not grid then
        grid = XUiGridCommon.New(self.Parent, self.GridItemHaveCount)
        self.UseItemGrid = grid
    end

    local itemId = nil
    if isMaxStars then
        itemId = XCharacterConfigs.GetPromoteItemId(characterType, character.Quality)
        local useCoin = XCharacterConfigs.GetPromoteUseCoin(characterType, character.Quality)
        local curCount = XDataCenter.ItemManager.GetCount(itemId)
        local data = {CostCount = useCoin, Count = curCount, Id = itemId}
        grid:Refresh(data)
    else
        itemId = XMVCA.XCharacter:GetCharacterItemId(self.CharacterId)
        local curItem = XDataCenter.ItemManager.GetItem(itemId)
        local itemCount = 0
        if curItem ~= nil then
            itemCount = curItem.Count
        end
        local useCount = XCharacterConfigs.GetStarUseCount(characterType, character.Quality, character.Star + 1)
        local curCount = XDataCenter.ItemManager.GetCount(itemId)
        local data = {CostCount = useCount, Count = curCount, Id = itemId}
        grid:Refresh(data)
    end
    self:AddEventListener(itemId)
end

function XPanelQualitySingleV2P6:OnEnable()
    -- single展示界面要关闭外部的动态列表特效球,打开专属的相机
    self.PanelModel:SetDynamicTableActive(false)
    self.PanelModel:SetQualitySingleRelated(true)
    
    self:RefreshUiShow()
end

-- 基于持有的数据刷新界面
function XPanelQualitySingleV2P6:RefreshUiShow(isActiveNode)
    if not self.SeleQuality then
        return
    end
    self:RefreshSingleBigBall(isActiveNode)
    self:RefreshRightDownBtn()
    self:RefreshUseItem()
end

-- 刷新包括数据更新 (该函数类似Start外部传参)
function XPanelQualitySingleV2P6:Refresh(seleQuality)
    self.SeleQuality = seleQuality
    self.CharacterId = self.Parent.ParentUi.CurCharacter.Id
    self.Character = self.CharacterAgency:GetCharacter(self.CharacterId)

    self:RefreshUiShow()
end

function XPanelQualitySingleV2P6:OnBtnOverviewClick()
    local enbaleCb = function ()
        self.Parent.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.QualityOverview)
        self.PanelModel:SetQualitySingleRelated(false)

        -- 隐藏小物件
        self.PanelQualityEvoRelative.gameObject:SetActiveEx(false)
    end
    local closeCb = function ()
        self.Parent.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.QualitySingle)
        self.PanelModel:SetQualitySingleRelated(true)

        self.PanelQualityEvoRelative.gameObject:SetActiveEx(true)
    end
    XLuaUiManager.Open("UiCharacterQualityOverviewV2P6", self.CharacterId, enbaleCb, closeCb)
end

-- 品质内升阶级
function XPanelQualitySingleV2P6:OnBtnActiveClick()
    local character = self.Character
    local beforeArea = self.CharacterAgency:GetCharQualityPerformArea(character.Id, character.Quality)
    self.CharacterAgency:ActivateStar(character, function()
        self:RefreshUiShow(true)
        -- cv
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiCharacter_QualityFragments)

        -- 音效 .进化到了特定阶段才播放
        local areaAfter = self.CharacterAgency:GetCharQualityPerformArea(character.Id, character.Quality)
        if areaAfter <= beforeArea then
            return
        end

        local config = self.CharacterAgency:GetModelCharacterSkillQualityBigEffectBall()[character.Quality]
        local cueId = config.CueIds[areaAfter]
        if not XTool.IsNumberValid(cueId) then
            return
        end
        CS.XAudioManager.PlaySound(cueId)
    end)
end

function XPanelQualitySingleV2P6:OnBtnEvolutionClick()
    local characterId = self.CharacterId
    local character = XDataCenter.CharacterManager.GetCharacter(characterId)
    if character.Star ~= XEnumConst.CHARACTER.MAX_QUALITY_STAR then
        return
    end

    local nextQuality = character.Quality + 1
    self.CharacterAgency:PromoteQuality(character, function()
        self:RefreshUiShow()
        if self.OnCharEvolutionCb then
            self.OnCharEvolutionCb(nextQuality)
        end
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiCharacter_QualityUp)
    end)
end

function XPanelQualitySingleV2P6:OnDisable()
    self.PanelModel:SetQualitySingleRelated(false)
end

function XPanelQualitySingleV2P6:AddEventListener(itemId)
    self:RemoveEventListener()
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self:RefreshUiShow()
    end, self.GridItemHaveCount)
end

function XPanelQualitySingleV2P6:RemoveEventListener()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self.GridItemHaveCount)
end

function XPanelQualitySingleV2P6:OnDestroy()
    self:RemoveEventListener()
end

return XPanelQualitySingleV2P6