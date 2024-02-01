local XUiRiftAttributeSlider = require("XUi/XUiRift/Grid/XUiRiftAttributeSlider")
local XUiRiftAttributeEffectGrid = require("XUi/XUiRift/Grid/XUiRiftAttributeEffectGrid")
local XRiftAttributeTemplate = require("XEntity/XRift/XRiftAttributeTemplate")

local Color = {
    red = XUiHelper.Hexcolor2Color("d11227"),
    blue = XUiHelper.Hexcolor2Color("00FFD6"),
}

---@class XUiRiftAttribute : XLuaUi
local XUiRiftAttribute = XLuaUiManager.Register(XLuaUi, "UiRiftAttribute")

function XUiRiftAttribute:OnAwake()
    self:RegisterClickEvent(self.BtnMainUi, self.OnClickMain)
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnTemplate, self.OnClickBtnTemplate)
    self:RegisterClickEvent(self.BtnSave, self.OnClickSave)
    self:RegisterClickEvent(self.BtnCloseBubble, self.CloseBubble)
    self:BindHelpBtn(self.BtnHelp, "RiftAttributeHelp")
end

function XUiRiftAttribute:OnStart()
    ---@type XUiRiftAttributeEffectGrid[]
    self.BasePropGrids = {}
    ---@type XUiRiftAttributeEffectGrid[]
    self.RewardPropGrids = {}
    self:InitSliders()
    self:InitCompnent()
    self:CloseBubble()
end

function XUiRiftAttribute:OnEnable()
    local attrTemplateId = self.AttrTemplate and self.AttrTemplate.Id or XRiftConfig.DefaultAttrTemplateId
    self:Refresh(attrTemplateId)
end

function XUiRiftAttribute:OnDisable()
    XDataCenter.RiftManager.CloseBuyAttrRed()
end

function XUiRiftAttribute:InitCompnent()
    local itemId = XDataCenter.ItemManager.ItemId.RiftGold
    if not self.AssetPanel then
        self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self)
    else
        self.AssetPanel:Refresh({ itemId })
    end

    local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.RiftGold)
    self.RImgExpend:SetRawImage(icon)
end

function XUiRiftAttribute:InitSliders()
    ---@type XUiRiftAttributeSlider[]
    self.AttrSliderList = {}
    for i = 1, XRiftConfig.AttrCnt do
        local tran = self["Attr" .. i]
        local slider = XUiRiftAttributeSlider.New(tran, self, i)
        table.insert(self.AttrSliderList, slider)
    end
end

function XUiRiftAttribute:IsAttrChange()
    local attrTemplate = XDataCenter.RiftManager.GetAttrTemplate(XRiftConfig.DefaultAttrTemplateId)
    for i = 1, XRiftConfig.AttrCnt do
        if self.AttrSliderList[i]:GetLevel() ~= attrTemplate:GetAttrLevel(i) then
            return true
        end
    end
    return false
end

function XUiRiftAttribute:RefreshSlider()
    local attrLevelMax = XDataCenter.RiftManager.GetAttrLevelMax()
    for i, attrSlider in ipairs(self.AttrSliderList) do
        local level = self.AttrTemplate:GetAttrLevel(i)
        attrSlider:Refresh(level, attrLevelMax)
    end
end

function XUiRiftAttribute:Refresh(attrTemplateId)
    -- 设置属性加点模板
    local attrTemplate = XDataCenter.RiftManager.GetAttrTemplate(attrTemplateId)
    ---@type XRiftAttributeTemplate
    self.AttrTemplate = XRiftAttributeTemplate.New(XRiftConfig.DefaultAttrTemplateId, attrTemplate.AttrList)

    self:RefreshSlider()
    self:RefreshAttrLevelAndConst()
    self:RefreshAttrBtnState()
    self:RefreshProperty()
    self:RefreshBubble()
end

function XUiRiftAttribute:RefreshAttrBtnState()
    for i = 1, XRiftConfig.AttrCnt do
        self.AttrSliderList[i]:RefreshButton()
    end

    local isChange = self:IsAttrChange()
    self.BtnSave:SetDisable(not isChange, false)
    self.BtnTemplate:SetDisable(isChange, false)
end

-- XUiRiftAttributeSlider调用
function XUiRiftAttribute:OnAttrLevelChange()
    self:RefreshAttrLevelAndConst()
    self:RefreshAttrBtnState()
    self:RefreshProperty()
end

function XUiRiftAttribute:GetCurAttrTemplate()
    if self.CurAttrTemplate == nil then
        ---@type XRiftAttributeTemplate
        self.CurAttrTemplate = XRiftAttributeTemplate.New(XRiftConfig.DefaultAttrTemplateId)
    end

    self.CurAttrTemplate:SetAttrLevel(1, self.AttrSliderList[1]:GetLevel())
    self.CurAttrTemplate:SetAttrLevel(2, self.AttrSliderList[2]:GetLevel())
    self.CurAttrTemplate:SetAttrLevel(3, self.AttrSliderList[3]:GetLevel())
    self.CurAttrTemplate:SetAttrLevel(4, self.AttrSliderList[4]:GetLevel())
    return self.CurAttrTemplate
end

function XUiRiftAttribute:RefreshAttrLevelAndConst()
    local totalLevel = 0
    for _, attrSlider in ipairs(self.AttrSliderList) do
        totalLevel = totalLevel + attrSlider:GetLevel()
    end
    self.TxtTotalLv.text = totalLevel

    -- 右上角的+/-标志
    local originLevel = self.AttrTemplate:GetAllLevel()
    local isAdd = totalLevel > originLevel
    self.TxtTotalLvAdd.gameObject:SetActiveEx(isAdd)
    if isAdd then
        self.TxtTotalLvAdd.text = "+" .. (totalLevel - originLevel)
    end
    local isSub = originLevel > totalLevel
    self.TxtTotalLvSubtract.gameObject:SetActiveEx(isSub)
    if isSub then
        self.TxtTotalLvSubtract.text = "-" .. (originLevel - totalLevel)
    end

    -- 购买点数消耗
    self.PanelExpend.gameObject:SetActiveEx(false)
    self.GoldNoEnough = false
    local const = XDataCenter.RiftManager.GetAttributeCost(totalLevel)
    local ownCnt = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.RiftGold)
    local showConst = const > 0
    if showConst then
        self.TxtExpendTitle.text = XUiHelper.GetText("RiftBuyAttrConst")
        self.TxtExpend.text = const
        self.GoldNoEnough = ownCnt < const
        self.TxtExpend.color = self.GoldNoEnough and Color.red or Color.blue
        self.PanelExpend.gameObject:SetActiveEx(true)
    end

    -- 无点数变化 且 当前加点=已购买点数，显示购买下一点数需要的金币
    local isChange = self:IsAttrChange()
    local buyAttrLevel = XDataCenter.RiftManager.GetTotalAttrLevel()
    if not isChange and totalLevel == buyAttrLevel then
        local nextLvCost = XDataCenter.RiftManager.GetAttributeCost(buyAttrLevel + 1)
        if nextLvCost > 0 then
            self.TxtExpendTitle.text = XUiHelper.GetText("RiftNextAttrConst")
            self.TxtExpend.text = nextLvCost
            local canBuyNext = ownCnt >= nextLvCost
            self.TxtExpend.color = canBuyNext and Color.blue or Color.red
            self.PanelExpend.gameObject:SetActiveEx(true)
        end
    end
end

function XUiRiftAttribute:RefreshProperty()
    local baseProps, rewardProps = self:GetEffectDataList()
    self:SetPropList(baseProps, self.BasePropGrids, self.GridBaseBuff, self.PanelBaseNoProperty)
    self:SetPropList(rewardProps, self.RewardPropGrids, self.GridRewardBuff, self.PanelRewardNoProperty)
end

---@param pool XUiRiftAttributeEffectGrid[]
function XUiRiftAttribute:SetPropList(props, pool, cell, noPropertyPanel)
    for i, prop in ipairs(props) do
        local grid = pool[i]
        if not grid then
            local go = XUiHelper.Instantiate(cell, cell.parent)
            grid = XUiRiftAttributeEffectGrid.New(go, self)
            table.insert(pool, grid)
        end
        grid:Open()
        grid:Refresh(i, prop)
    end
    for i = #props + 1, #pool do
        pool[i]:Close()
    end
    noPropertyPanel.gameObject:SetActiveEx(#props == 0)
    cell.gameObject:SetActiveEx(false)
end

function XUiRiftAttribute:GetEffectDataList()
    local originEffectList = self.AttrTemplate:GetEffectList()
    local curAttrTemplate = self:GetCurAttrTemplate()
    local curEffectList = curAttrTemplate:GetEffectList()

    local showEffectDic = {}
    showEffectDic[XEnumConst.Rift.PropType.Battle] = {}
    showEffectDic[XEnumConst.Rift.PropType.System] = {}
    for _, effect in ipairs(originEffectList) do
        local showEffect = showEffectDic[effect.PropType][effect.EffectType]
        if showEffect == nil then
            showEffectDic[effect.PropType][effect.EffectType] = {}
            showEffect = showEffectDic[effect.PropType][effect.EffectType]
            showEffect.EffectType = effect.EffectType
            showEffect.OriginValue = 0
            showEffect.CurValue = 0
            showEffect.PropType = effect.PropType
        end
        showEffect.OriginValue = showEffect.OriginValue + effect.EffectValue
    end

    for _, effect in ipairs(curEffectList) do
        local showEffect = showEffectDic[effect.PropType][effect.EffectType]
        if showEffect == nil then
            showEffectDic[effect.PropType][effect.EffectType] = {}
            showEffect = showEffectDic[effect.PropType][effect.EffectType]
            showEffect.EffectType = effect.EffectType
            showEffect.OriginValue = 0
            showEffect.CurValue = 0
            showEffect.PropType = effect.PropType
        end
        showEffect.CurValue = showEffect.CurValue + effect.EffectValue
    end

    local showBattleEffectList = {}
    for _, effect in pairs(showEffectDic[XEnumConst.Rift.PropType.Battle]) do
        table.insert(showBattleEffectList, effect)
    end
    local battleEffectTypeConfigs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTeamAttributeEffectType)
    table.sort(showBattleEffectList, function(a, b)
        return battleEffectTypeConfigs[a.EffectType].Order < battleEffectTypeConfigs[b.EffectType].Order
    end)

    local showSystemEffectList = {}
    for _, effect in pairs(showEffectDic[XEnumConst.Rift.PropType.System]) do
        table.insert(showSystemEffectList, effect)
    end
    local systemEffectTypeConfigs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftSystemAttributeEffectType)
    table.sort(showSystemEffectList, function(a, b)
        return systemEffectTypeConfigs[a.EffectType].Order < systemEffectTypeConfigs[b.EffectType].Order
    end)

    return showBattleEffectList, showSystemEffectList
end

function XUiRiftAttribute:OnDestroy()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self.AssetPanel)
end

function XUiRiftAttribute:OnClickMain()
    XLuaUiManager.RunMain()
end

function XUiRiftAttribute:OnClickBtnTemplate()
    if self.BtnTemplate.ButtonState == CS.UiButtonState.Disable then
        return
    end
    XLuaUiManager.Open("UiRiftTemplate", self.AttrTemplate.Id, function(id)
        self:Refresh(id)
        self:OnClickSave()
    end)
end

function XUiRiftAttribute:OnClickSave()
    if self.BtnSave.ButtonState == CS.UiButtonState.Disable then
        return
    end

    if self.GoldNoEnough then
        XUiManager.TipText("RogueLikeBuyNotEnough")
    else
        local curAttrTemplate = self:GetCurAttrTemplate()
        XDataCenter.RiftManager.RequestSetAttrSet(curAttrTemplate, function()
            self:Refresh(XRiftConfig.DefaultAttrTemplateId)
        end)
    end
end

--region 系统属性气泡

function XUiRiftAttribute:RefreshBubble()
    local curAttrTemplate = self:GetCurAttrTemplate()
    for _, v in pairs(self.AttrSliderList) do
        v.Bubble:SetData(curAttrTemplate)
    end
end

function XUiRiftAttribute:CloseBubble()
    for _, v in pairs(self.AttrSliderList) do
        v.Bubble:Close()
    end
    self.BtnCloseBubble.gameObject:SetActiveEx(false)
end

function XUiRiftAttribute:OpenBubbleCloseBtn()
    self.BtnCloseBubble.gameObject:SetActiveEx(true)
end

--endregion

return XUiRiftAttribute