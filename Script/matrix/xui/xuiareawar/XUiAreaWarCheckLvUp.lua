
---@class XUiAreaWarCheckLvUp : XLuaUi
local XUiAreaWarCheckLvUp = XLuaUiManager.Register(XLuaUi, "UiAreaWarCheckLvUp")

function XUiAreaWarCheckLvUp:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiAreaWarCheckLvUp:OnStart(closeCb)
    self.CloseCb = closeCb
    self:InitView()
end

function XUiAreaWarCheckLvUp:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiAreaWarCheckLvUp:InitUi()
    self.PanelHead = {}
    XTool.InitUiObjectByUi(self.PanelHead, self.HeadObject)
    
    self.BuffGrids = {}

    self.ItemBuff.gameObject:SetActiveEx(false)
end

function XUiAreaWarCheckLvUp:InitCb()
    
    self.BtnClose.CallBack = function() 
        self:Close()
    end
end

function XUiAreaWarCheckLvUp:InitView()
    self:RefreshLevel()
end

function XUiAreaWarCheckLvUp:RefreshHead()
    --头像
    local headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(XPlayer.CurrHeadPortraitId)
    self.PanelHead.ImgIcon:SetRawImage(headPortraitInfo.ImgSrc)

    local hasEffect = not string.IsNilOrEmpty(headPortraitInfo.Effect)
    self.PanelHead.EffectIcon.gameObject:SetActiveEx(hasEffect)
    if hasEffect then
        self.PanelHead.EffectIcon:LoadPrefab(headPortraitInfo.Effect)
    end

    local hasFrame = XTool.IsNumberValid(XPlayer.CurrHeadFrameId)
    self.PanelHead.ImgIconKuang.gameObject:SetActiveEx(hasEffect)

    if hasFrame then
        --头像框
        headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(XPlayer.CurrHeadFrameId)
        self.PanelHead.ImgIconKuang:SetRawImage(headPortraitInfo.ImgSrc)
        hasEffect = not string.IsNilOrEmpty(headPortraitInfo.Effect)
        self.PanelHead.EffectKuang.gameObject:SetActiveEx(hasEffect)
        if hasEffect then
            self.PanelHead.EffectKuang:LoadPrefab(headPortraitInfo.Effect)
        end
    end
end

function XUiAreaWarCheckLvUp:RefreshLevel()
    local personal = XDataCenter.AreaWarManager.GetPersonal()
    local addBuffList = personal:GetAddBuffList()
    local addSkillNum = personal:GetAddSkipNum()
    local cur = personal:GetSkipNum()
    self.TxtLv.text = personal:GetLevelName()
    local curLevel = personal:GetLevel()
    self.PanelHead.ImgIcon:SetRawImage(XAreaWarConfigs.GetGrowIcon(curLevel))
    self:RefreshRepeat(addSkillNum, cur)
    self:RefreshBuff(addBuffList)
end

function XUiAreaWarCheckLvUp:RefreshRepeat(addSkillNum, cur)
    local isShow = addSkillNum > 0
    self.GridRepeatChallengeNum.gameObject:SetActiveEx(isShow)
    if not isShow then
        return
    end
    self.TxtDetail.text = cur
end

function XUiAreaWarCheckLvUp:RefreshBuff(addBuffList)
    for _, grid in pairs(self.BuffGrids) do
        grid.GameObject:SetActiveEx(false)
    end

    for index, buffId in pairs(addBuffList) do
        local grid = self.BuffGrids[index]
        if not grid then
            local ui = index == 1 and self.ItemBuff or XUiHelper.Instantiate(self.ItemBuff, self.PanelBuff)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.BuffGrids[index] = grid
        end
        self:RefreshBuffGrid(buffId, grid)
    end
end

function XUiAreaWarCheckLvUp:RefreshBuffGrid(buffId, grid)
    if not grid then
        return
    end
    grid.GameObject:SetActiveEx(true)
    grid.RImgBuff:SetRawImage(XAreaWarConfigs.GetBuffIcon(buffId))
end