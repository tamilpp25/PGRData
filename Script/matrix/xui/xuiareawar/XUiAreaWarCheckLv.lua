local XUiGridAreaWarBuff = XClass(XUiNode, "XUiGridAreaWarBuff")

local ColorEnum = {
    Normal = XUiHelper.Hexcolor2Color("00FFFCFF"),
    Lock = XUiHelper.Hexcolor2Color("00FFFC27"),
}

function XUiGridAreaWarBuff:OnStart()
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
    self.IsSelect = false
end

function XUiGridAreaWarBuff:OnBtnClick()
    local buffId = self.BuffId
    if not buffId or buffId <= 0 then
        return
    end
    if not self.Parent.UnlockDict[buffId] then
        self.BtnClick:SetDisable(true)
        --XUiManager.TipMsg(XAreaWarConfigs.GetGrowBuffLockTip(buffId))
        --return
    end
    self:SetSelect(not self.IsSelect)
    self.BtnClick:ShowReddot(false)
    self:MarkBuffRedPoint(buffId)
    self.Parent:OnClickBuff(self.Index, self.BuffId, self.IsSelect)
end

function XUiGridAreaWarBuff:Refresh(index, buffId, unlock)
    self.Index = index
    self.BuffId = buffId
    self:Open()
    self.BtnClick:SetRawImage(XAreaWarConfigs.GetBuffIcon(buffId))
    self.BtnClick:SetDisable(not unlock)
    self.BtnClick:ShowReddot(self:CheckBuffRedPoint(buffId))
    local isGlow = XAreaWarConfigs.IsEmptyFightEvent(buffId)
    self.ImgGlow.gameObject:SetActiveEx(isGlow)
    if isGlow then
        self.ImgGlow.color = unlock and ColorEnum.Normal or ColorEnum.Lock
    end
end

function XUiGridAreaWarBuff:CheckBuffRedPoint(buffId)
    if not buffId or buffId <= 0 then
        return false
    end
    if not self.Parent.UnlockDict[buffId] then
        return false
    end
    local key = XDataCenter.AreaWarManager.GetCookieKey("GrowBuffFirstUnlock_" .. buffId)
    local data = XSaveTool.GetData(key)
    if data then
        return false
    end

    return true
end

function XUiGridAreaWarBuff:MarkBuffRedPoint(buffId)
    if not buffId or buffId <= 0 then
        return
    end
    if not self.Parent.UnlockDict[buffId] then
        return
    end
    local key = XDataCenter.AreaWarManager.GetCookieKey("GrowBuffFirstUnlock_" .. buffId)
    local data = XSaveTool.GetData(key)
    if data then
        return
    end
    XSaveTool.SaveData(key, true)
end

function XUiGridAreaWarBuff:SetSelect(isSelect)
    self.IsSelect = isSelect
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

---@class XUiAreaWarCheckLv : XLuaUi
local XUiAreaWarCheckLv = XLuaUiManager.Register(XLuaUi, "UiAreaWarCheckLv")

local ExpItemId = XDataCenter.ItemManager.ItemId.AreaWarPersonalExp


function XUiAreaWarCheckLv:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiAreaWarCheckLv:OnStart()
    self:InitView()
end

function XUiAreaWarCheckLv:InitUi()
    self.BuffGrids = {}
    self.PanelHead = {}
    XTool.InitUiObjectByUi(self.PanelHead, self.HeadObject)

    self.RImgExp:SetRawImage(XDataCenter.ItemManager.GetItemIcon(ExpItemId))
end

function XUiAreaWarCheckLv:InitCb()
    self:BindExitBtns()
    self:BindHelpBtn()
    self.BtnCloseTip.CallBack = function() 
        self:RefreshTip(false)
    end
end

function XUiAreaWarCheckLv:InitView()
    self:UpdatePurificationLevel()
    --self:RefreshHead()
    self:RefreshLevel()
    
    self:RefreshTip(false)
end

function XUiAreaWarCheckLv:UpdatePurificationLevel()
    local level = XDataCenter.AreaWarManager.GetSelfPurificationLevel()
    --属性
    local addAttrs = XAreaWarConfigs.GetPfLevelAddAttrs(level)
    for index, attr in ipairs(addAttrs) do
        self["TxtAttr" .. index].text = attr
    end
    local progress = XDataCenter.AreaWarManager.GetSelfPurificationNextProgress()
    self.TxtLv.text = string.format("Lv.%d", level)
    self.ImgBar.fillAmount = progress
end

function XUiAreaWarCheckLv:RefreshHead()
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

function XUiAreaWarCheckLv:RefreshLevel()
    local personal = XDataCenter.AreaWarManager.GetPersonal()
    self.UnlockDict = personal:GetUnlockBuffDict()
    local level = personal:GetLevel()
    self.TxtName.text = personal:GetLevelName()
    self.PanelHead.ImgIcon:SetRawImage(XAreaWarConfigs.GetGrowIcon(level))
    --当前等级含有的Exp
    local exp = personal:GetExp()
    --当前等级需要的Exp
    local curExp = XAreaWarConfigs.GetLevelExp(level + 1)
    local fillAmount = personal:GetExpProgress()
    self.ImgHBar.fillAmount = fillAmount
    self.TxtNum.text = string.format("%d/%d", exp, curExp)
    
    self.TxtLikeNum.text = personal:GetLikeCount()

    local buffList = XAreaWarConfigs.GetAllBuffIds()
    self:RefreshBuff(buffList)
end

function XUiAreaWarCheckLv:RefreshTip(isShow)
    self.BtnCloseTip.gameObject:SetActiveEx(isShow)
    self.PanelContent.gameObject:SetActiveEx(isShow)
    if not isShow then
        if self.LastIndex then
            self.BuffGrids[self.LastIndex]:SetSelect(false)
            self.LastIndex = nil
        end
        return
    end
    self.TxtDesc.text = XAreaWarConfigs.GetBuffDesc(self.SelectBuffId)
    self.TxtBuffName.text = XAreaWarConfigs.GetBuffName(self.SelectBuffId)
    self.RImgBuffIcon:SetRawImage(XAreaWarConfigs.GetBuffIcon(self.SelectBuffId))
end

function XUiAreaWarCheckLv:RefreshBuff(buffList)
    for _, grid in pairs(self.BuffGrids) do
        grid:Close()
    end

    for index, buffId in pairs(buffList) do
        local grid = self.BuffGrids[index]
        if not grid then
            local parent = self.PanelBuff:Find("Buff"..index)
            if not parent then
                XLog.Error("Ui上最大支持" .. (index - 1) .."个Buff的显示, 配置了" .. #buffList .. "个Buff")
                break
            end
            local ui = XUiHelper.Instantiate(self.GridBuff, parent)
            ui.transform.anchoredPosition = Vector2.zero
            ui.gameObject.name = buffId
            grid = XUiGridAreaWarBuff.New(ui, self)
            self.BuffGrids[index] = grid
        end
        grid:Refresh(index, buffId, self.UnlockDict[buffId] and true or false)
    end
end

function XUiAreaWarCheckLv:OnClickBuff(index, buffId, isSelect)
    if isSelect then
        self.SelectBuffId = buffId
        if self.LastIndex then
            self.BuffGrids[self.LastIndex]:SetSelect(false)
            self.LastIndex = nil
        end
        self.LastIndex = index
    end
    self:RefreshTip(isSelect)
end