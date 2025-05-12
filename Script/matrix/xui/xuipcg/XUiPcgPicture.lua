local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPcgPicture : XLuaUi
---@field private _Control XPcgControl
local XUiPcgPicture = XLuaUiManager.Register(XLuaUi, "UiPcgPicture")

function XUiPcgPicture:OnAwake()
    self:RegisterUiEvents()
    self:InitTabGroup()
    self:InitDynamicTable()
    self.ContentLocalPosition = self.Content.localPosition
end

function XUiPcgPicture:OnStart()

end

function XUiPcgPicture:OnEnable()
    self:Refresh()
end

function XUiPcgPicture:OnDisable()
    
end

function XUiPcgPicture:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiPcgPicture:OnBtnBackClick()
    self:Close()
end

function XUiPcgPicture:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPcgPicture:InitTabGroup()
    self.TabBtns = {
        self.BtnTabAll,
        self.BtnTabRed,
        self.BtnTabBlue,
        self.BtnTabYellow,
    }
    self.TAB_TYPE = {
        ALL = 1,
        RED = 2,
        BLUE = 3,
        YELLOW = 4,
    }
    self.BtnGroup:Init(self.TabBtns, function(index) self:OnBtnTabClick(index) end)
end

function XUiPcgPicture:OnBtnTabClick(index)
    if self.SelTabIndex == index then
        return
    end
    self.SelTabIndex = index
    self.SelCharIndex = 1
    self.CharacterIds = self:GetCharacterIds(index)
    self:RefreshCharacterList()

    -- 角色未解锁，直接显示详情
    -- 角色已经锁，走点击选中流程
    local charId = self.CharacterIds[self.SelCharIndex]
    local isUnlock = self._Control:IsCharacterUnlock(charId)
    if isUnlock then
        self:OnCharacterClick(self.SelCharIndex)
    else
        self:RefreshCharacterDetail()
    end
    
    self:PlayAnimation("QieHuan")
end

-- 刷新界面
function XUiPcgPicture:Refresh()
    -- 选中第一个页签
    self.BtnGroup:SelectIndex(self.SelTabIndex or 1)

    -- 刷新页签蓝点
    self:RefreshTabsRed()
end

function XUiPcgPicture:InitDynamicTable()
    local XUiGridPcgCharacter = require("XUi/XUiPcg/XUiGrid/XUiGridPcgCharacter")
    self.DynamicTable = XDynamicTableNormal.New(self.CharacterList)
    self.DynamicTable:SetProxy(XUiGridPcgCharacter, self)
    self.DynamicTable:SetDelegate(self)
    self.GridCharacter.gameObject:SetActiveEx(false)
end

-- 刷新角色列表
function XUiPcgPicture:RefreshCharacterList()
    self.DynamicTable:SetDataSource(self.CharacterIds)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiGridPcgCharacter
function XUiPcgPicture:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local characterId = self.CharacterIds[index]
        local isLock = not self._Control:IsCharacterUnlock(characterId)
        local lockTips = self._Control:GetCharacterLockTips(characterId)
        local isRed = self._Control:IsCharacterShowRed(characterId)
        grid:SetCharacterData(characterId)
        grid:ShowSelected(index == self.SelCharIndex and not isLock)
        grid:SetLock(isLock, lockTips)
        grid:SetRed(isRed)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnCharacterClick(index)
    end
end

function XUiPcgPicture:OnCharacterClick(index)
    local charId = self.CharacterIds[index]
    local isUnlock = self._Control:IsCharacterUnlock(charId)
    if not isUnlock then
        local tips = self._Control:GetClientConfig("CharacterNoUnlockTips")
        XUiManager.TipError(tips)
        return
    end
    self.Content.localPosition = self.ContentLocalPosition
    
    -- 修改选中状态
    self.SelCharIndex = index
    local grids = self.DynamicTable:GetGrids()
    for i, tempGrid in pairs(grids) do
        local isSel = i == self.SelCharIndex
        tempGrid:ShowSelected(isSel)
    end

    -- 消除蓝点
    local selGrid = grids[index]
    if selGrid then
        selGrid:SetRed(false)
    end
    self._Control:SetCharacterReviewedBrochure(charId)
    
    -- 刷新页签蓝点
    self:RefreshTabsRed()
    
    -- 刷新详情
    self:RefreshCharacterDetail()
end

-- 刷新角色详情
function XUiPcgPicture:RefreshCharacterDetail()
    local characterId = self.CharacterIds[self.SelCharIndex]
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
    self.GridPcgCard:SetCardData(cardId)
    self.GridPcgCard:SetInputCallBack(function()
        XLuaUiManager.Open("UiPcgPopupCardDetail", cardId)
    end)
end

-- 获取页签角色列表
function XUiPcgPicture:GetCharacterIds(tabIndex)
    local charCfgs = self._Control:GetConfigCharacter()
    local charIds = {}
    for _, charCfg in ipairs(charCfgs) do
        if tabIndex == self.TAB_TYPE.ALL 
        or (tabIndex == self.TAB_TYPE.RED and charCfg.ColorType == XEnumConst.PCG.COLOR_TYPE.RED)
        or (tabIndex == self.TAB_TYPE.BLUE and charCfg.ColorType == XEnumConst.PCG.COLOR_TYPE.BLUE)
        or (tabIndex == self.TAB_TYPE.YELLOW and charCfg.ColorType == XEnumConst.PCG.COLOR_TYPE.YELLOW)then
            table.insert(charIds, charCfg.Id)
        end
    end
    table.sort(charIds, function(idA, idB) 
        local isUnlockA = self._Control:IsCharacterUnlock(idA)
        local isUnlockB = self._Control:IsCharacterUnlock(idB)
        if isUnlockA ~= isUnlockB then
            return isUnlockA
        end
        return idA < idB
    end)
    return charIds
end

-- 刷新页签蓝点
function XUiPcgPicture:RefreshTabsRed()
    for i, btn in ipairs(self.TabBtns) do
        local isRed = false
        local characterIds = self:GetCharacterIds(i)
        for _, characterId in ipairs(characterIds) do
            if self._Control:IsCharacterShowRed(characterId) then
                isRed = true
            end
        end
        btn:ShowReddot(isRed)
    end
end

return XUiPcgPicture
