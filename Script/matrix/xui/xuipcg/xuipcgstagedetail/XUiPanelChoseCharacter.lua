local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelChoseCharacter : XUiNode
---@field private _Control XPcgControl
---@field Parent XUiPcgGame
local XUiPanelChoseCharacter = XClass(XUiNode, "XUiPanelChoseCharacter")

function XUiPanelChoseCharacter:OnStart()
    self.GridCharacter.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self:InitDynamicTable()
    self.ContentLocalPosition = self.Content.localPosition
end

function XUiPanelChoseCharacter:OnEnable()
    self:PlayAnimation("PaneChoseCharacterEnable")
end

function XUiPanelChoseCharacter:OnDisable()
    
end

function XUiPanelChoseCharacter:OnDestroy()
    
end

function XUiPanelChoseCharacter:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBgClose, self.OnBtnCloseClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnSelectClick, nil, true)
end

function XUiPanelChoseCharacter:OnBtnCloseClick()
    if self.IsClosing then return end

    self.IsClosing = true
    self:PlayAnimation("PaneChoseCharacterDisable", function()
        self.IsClosing = false
        self.Parent:SetCharacterLayer()
        self:Close()
    end)
end

function XUiPanelChoseCharacter:OnBtnSelectClick()
    local characterId = self.CharacterIds[self.SelectedIndex]
    if characterId == self.TeamCharacterId then
        local tips = self._Control:GetClientConfig("CharacterSelectedTips")
        XUiManager.TipError(tips)
        return 
    end
    
    if self.StageType == XEnumConst.PCG.STAGE_TYPE.TEACHING then
        local tips = self._Control:GetClientConfig("NoChangeCharacterTips")
        XUiManager.TipError(tips)
        return
    end
    
    self.Parent:OnChangeCharacter(self.CharacterIndex, characterId)
    self:Close()
end

function XUiPanelChoseCharacter:OnCharacterClick(index)
    self.SelectedIndex = index
    local grids = self.DynamicTable:GetGrids()
    for i, tempGrid in pairs(grids) do
        tempGrid:ShowSelected(i == self.SelectedIndex)
    end
    self.Content.localPosition = self.ContentLocalPosition
    self:RefreshCharacterDetail()
end

function XUiPanelChoseCharacter:Refresh(stageId, index, characterId)
    self.StageId = stageId
    self.CharacterIndex = index
    self.TeamCharacterId = characterId
    self.CharacterIds = self._Control:GetUnlockCharacterIds(self.StageId, index)
    self.SelectedIndex = 1
    local isContain, idx = table.contains(self.CharacterIds, characterId)
    if isContain then
        self.SelectedIndex = idx
    end
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    self.StageType = stageCfg.Type
    self:RefreshCharacterList()
    self:RefreshCharacterDetail()
end

-- 刷新角色详情
function XUiPanelChoseCharacter:RefreshCharacterDetail()
    local characterId = self.CharacterIds[self.SelectedIndex]
    local cfg = self._Control:GetConfigCharacter(characterId)
    
    -- 成员信息
    self.TxtCharacterName.text = cfg.Name
    self.TxtCharacterDetail.requestImage = XMVCA.XPcg.RichTextImageCallBack
    self.TxtCharacterDetail.text = XUiHelper.ReplaceTextNewLine(cfg.Desc)
    self.TxtCharacterDetail:ForcePopulateIcons()
    self.TxtQteDetail.requestImage = XMVCA.XPcg.RichTextImageCallBack
    self.TxtQteDetail.text = XUiHelper.ReplaceTextNewLine(cfg.QteDesc)
    self.TxtQteDetail:ForcePopulateIcons()
    -- 成员类型
    local typeCfg = self._Control:GetConfigCharacterType(cfg.Type)
    self.TxtType.text = typeCfg.Name
    self.RImgTypeIcon:SetRawImage(typeCfg.Icon)
    -- 三消球描述
    local colorNames = self._Control:GetClientConfigParams("CardColorNames")
    local colorBallDesc = { cfg.RedBallDesc, cfg.BlueBallDesc, cfg.YellowBallDesc } 
    local colorIcons = self._Control:GetClientConfigParams("CardColorIcons")
    for i, ballDesc in ipairs(colorBallDesc) do
        local uiObj = self["GridSkill" .. tostring(i)]
        uiObj:GetObject("TxtName").text = colorNames[i]
        uiObj:GetObject("RImgBall"):SetRawImage(colorIcons[i])
        local txtDetail = uiObj:GetObject("TxtDetail")
        txtDetail.requestImage = XMVCA.XPcg.RichTextImageCallBack
        txtDetail.text = ballDesc
        txtDetail:ForcePopulateIcons()
    end

    -- 必杀牌
    local cardId = cfg.SignatureCardId
    if not self.GridPcgCard then
        local XUiGridPcgCard = require("XUi/XUiPcg/XUiGrid/XUiGridPcgCard")
        ---@type XUiGridPcgCard
        self.GridPcgCard = XUiGridPcgCard.New(self.UiPcgGridCard, self)
    end
    self.GridPcgCard:SetCardData(cardId, nil, nil, true)
    self.GridPcgCard:SetInputCallBack(function()
        XLuaUiManager.Open("UiPcgPopupCardDetail", cardId)
    end)
    
    -- 上阵按钮
    self.BtnSelect:SetDisable(characterId == self.TeamCharacterId)
end

function XUiPanelChoseCharacter:InitDynamicTable()
    local XUiGridPcgCharacter = require("XUi/XUiPcg/XUiGrid/XUiGridPcgCharacter")
    self.DynamicTable = XDynamicTableNormal.New(self.CharacterList)
    self.DynamicTable:SetProxy(XUiGridPcgCharacter, self)
    self.DynamicTable:SetDelegate(self)
end

-- 刷新角色列表
function XUiPanelChoseCharacter:RefreshCharacterList()
    self.DynamicTable:SetDataSource(self.CharacterIds)
    self.DynamicTable:ReloadDataSync(self.SelectedIndex)
end

---@param grid XUiGridPcgCharacter
function XUiPanelChoseCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local characterId = self.CharacterIds[index]
        grid:SetCharacterData(characterId)
        grid:ShowSelected(index == self.SelectedIndex)
        grid:ShowTagNow(characterId == self.TeamCharacterId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnCharacterClick(index)
    end
end

return XUiPanelChoseCharacter
