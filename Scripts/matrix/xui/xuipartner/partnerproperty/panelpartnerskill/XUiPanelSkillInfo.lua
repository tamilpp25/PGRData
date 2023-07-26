local XUiPanelSkillInfo = XClass(nil, "XUiPanelSkillInfo")
local XUiGridCostItem = require("XUi/XUiEquipBreakThrough/XUiGridCostItem")
local DefaultCount = 1
local DefaultIndex = 1
local MainSkillIndex = 1
local LONG_CLICK_OFFSET = 0.2
local LONG_PRESS_PARAMS = 500
local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.red,
}

function XUiPanelSkillInfo:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    XTool.InitUiObject(self)
    self.Partner = nil                  -- 辅助机数据
    self.SkillGroupList = nil           -- 辅助机主动技能+被动技能列表
    self.SkillGroup = nil               -- 当前选中的技能
    self.ShowMainSkillGroup = nil       -- 当前战士的主动技能
    self.SelectIndex = 1                -- 当前选中的技能下标
    self.GridCostItems = {}             -- 升级消耗的道具item
    self:SetButtonCallBack()
    self:ResetLongPressData()
end

function XUiPanelSkillInfo:SetButtonCallBack()
    self.BtnNext.CallBack = function()
        self:OnBtnNextClick()
    end
    self.BtnPrior.CallBack = function()
        self:OnBtnPriorClick()
    end
    self.BtnSwitchMainSkill.CallBack = function()
        self:OnBtnSwitchMainSkillClick()
    end
    --self.BtnSkillUp.CallBack = function()
    --    self:OnBtnSkillUpClick()
    --end
    self.BtnSkillPreview.CallBack = function()
        self:OnSkillPreviewClick()
    end
    self:RegisterLongPressLevelUp()
end
function XUiPanelSkillInfo:RegisterLongPressLevelUp()
    -- 添加长按事件
    local btnClickPointer = self.BtnSkillUp.gameObject:GetComponent("XUiPointer")
    if not btnClickPointer then
        btnClickPointer =  self.BtnSkillUp.gameObject:AddComponent(typeof(CS.XUiPointer))
    end
    self.Clicker = XUiButtonLongClick.New(btnClickPointer, math.floor(1000/ CS.XGame.ClientConfig:GetInt("LongPressPerLevelUp")), self, self.OnBtnSkillUpClick, self.OnLongPress, function()
        self:OnLongPressUp()
    end, false, nil,true,true)
    self.Clicker:SetTriggerOffset(LONG_CLICK_OFFSET)
end

function XUiPanelSkillInfo:OnLongPressUp()
    self.NotMaskShow = true
    --self.PanelMask.gameObject:SetActiveEx(false)
    if self.ClientLongPressIncreaseLevel <= 0 or self.ClientShowLevelParam == 0 then
        self:ResetLongPressData()
        self:UpdateSkill()
        return
    end
    local originalLevel = self.SkillGroup:GetLevel()
    local maxLevel = self.SkillGroup:GetLevelLimit()
    local money = self.Partner:GetSkillUpgradeMoney()
    self.LongPressCostCoin = (self.ClientShowLevelParam - originalLevel) * money.Count
    local updateItems = self.Partner:GetSkillUpgradeCostItem()
    for _, item in pairs(updateItems) do
        if item.Id ~= XDataCenter.ItemManager.ItemId.Coin then
            self.LongPressCostItem = self.LongPressCostItem + item.Count
        end
    end
    self.LongPressCostItem = self.LongPressCostItem * (self.ClientShowLevelParam - originalLevel)
    if  self.LongPressCostCoin <= 0 and self.LongPressCostItem <= 0  then --无消耗就无升级
        self:ResetLongPressData()
        self:UpdateSkill()
        return
    end
    local textParam = "PartnerLongPressLevelUpSkill"
    if maxLevel == self.ClientShowLevelParam then
        textParam = "PartnerLongPressLevelUpSkillMax"
    end
    local content = CSXTextManagerGetText(textParam, self.LongPressCostCoin, self.LongPressCostItem, self.ClientShowLevelParam)
    local tempClientShowLevelParam = self.ClientShowLevelParam
    local sureCallBack = function()
        self:OnBtnSkillUpClick(tempClientShowLevelParam - originalLevel)
    end

    local closeCallback = function()
        self:UpdateSkill()
    end
    self:ResetLongPressData()
    local title = CS.XTextManager.GetText("TipTitle")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, closeCallback, sureCallBack)
end

function XUiPanelSkillInfo:OnLongPress(pressingTime)
    if self.NotMaskShow then --增加mask，阻止长按时候玩家的其他操作
        self.NotMaskShow = false
        --self.PanelMask.gameObject:SetActiveEx(true)
    end
    local clientShowLevelParam = 0
    if pressingTime > LONG_CLICK_OFFSET * LONG_PRESS_PARAMS then
        --控制延时刷新，避免点击一次就刷新技能升级预览
        self.SkillGroup = self.SkillGroupList[self.SelectIndex]
        local originalLevel = self.SkillGroup:GetLevel()
        local maxLevel = self.SkillGroup:GetLevelLimit()
        self.ClientLongPressIncreaseLevel = self.ClientLongPressIncreaseLevel + 1
        clientShowLevelParam = self.ClientLongPressIncreaseLevel + originalLevel
        local canUpdate = clientShowLevelParam <= maxLevel and XDataCenter.PartnerManager.CheckCanUpdateSkillMultiple(self.Partner:GetId(), self.SkillGroup, self.ClientLongPressIncreaseLevel)
        if canUpdate then
            if (clientShowLevelParam > maxLevel) then
                clientShowLevelParam = maxLevel
            end
            self.ClientShowLevelParam = clientShowLevelParam
            self:UpdateSkill(self.ClientShowLevelParam)
        else
            return true, true --回调参数即使时间短也要加弹窗提示
        end
    end
end


function XUiPanelSkillInfo:ResetLongPressData()
    self.ClientShowLevelParam = 0 --要升级到的等级
    self.ClientLongPressIncreaseLevel = 0 --等级变量依据长按时间增加
    self.LongPressCostCoin = 0
    self.LongPressCostItem = 0
    self.NotMaskShow = true
    --self.PanelMask.gameObject:SetActiveEx(false)
end

function XUiPanelSkillInfo:UpdatePanel(partner, selectIndex)
    self.Partner = partner
    self.SelectIndex = selectIndex
    self:GenSkillGroupList()
    self:UpdateSkill()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelSkillInfo:HidePanel()
    self.GameObject:SetActiveEx(false)
    self.ShowMainSkillGroup = nil
end

function XUiPanelSkillInfo:GenSkillGroupList()
    self.SkillGroupList = {}
    local mainSkillGroupList = self.Partner:GetCarryMainSkillGroupList()
    for _, entity in pairs(mainSkillGroupList or {}) do
        table.insert(self.SkillGroupList, entity)
    end

    local passiveSkillEntityDic = self.Partner:GetPassiveSkillGroupEntityDic()
    for _, entity in pairs(passiveSkillEntityDic or {}) do
        table.insert(self.SkillGroupList, entity)
    end
end

function XUiPanelSkillInfo:UpdateSkill(level)
    self.SkillGroup = self.SkillGroupList[self.SelectIndex]
    level = level or self.SkillGroup:GetLevel()
    local limitLevel = self.SkillGroup:GetLevelLimit()
    local isMaxLevel = level >= limitLevel
    
    local activeId = self.SkillGroup:GetActiveSkillId()
    if self.SelectIndex == MainSkillIndex and self.ShowMainSkillGroup then
        local mainActiveId = self.ShowMainSkillGroup:GetActiveSkillId()
        self.ImgSkillPointIcon:SetRawImage(self.ShowMainSkillGroup:GetSkillIcon(mainActiveId,level))
        self.TxtSkillName.text = self.ShowMainSkillGroup:GetSkillName(mainActiveId,level)
        self.TxtSkillLevel.text = isMaxLevel and "MAX" or level
        self.TxtSkillDesc.text = self.ShowMainSkillGroup:GetSkillDesc(mainActiveId,level)
    else
        self.ImgSkillPointIcon:SetRawImage(self.SkillGroup:GetSkillIcon(activeId,level))
        self.TxtSkillName.text = self.SkillGroup:GetSkillName(activeId,level)
        self.TxtSkillLevel.text = isMaxLevel and "MAX" or level
        self.TxtSkillDesc.text = self.SkillGroup:GetSkillDesc(activeId,level)
    end

    local isMainSkill = self:IsMainSkill()
    self.ImgSkillType.gameObject:SetActiveEx(isMainSkill)
    self.BtnSwitchMainSkill.gameObject:SetActiveEx(isMainSkill)

    self.PanelMaxLevel.gameObject:SetActiveEx(isMaxLevel)
    self.PanelUnlockMaterial.gameObject:SetActiveEx(not isMaxLevel)
    self.PanelConsume.gameObject:SetActiveEx(not isMaxLevel)
    self.BtnSkillUp.gameObject:SetActiveEx(not isMaxLevel)
    if not isMaxLevel then
        self:UpdateCost()
    end
end

function XUiPanelSkillInfo:OnBtnNextClick()
    if self.SelectIndex < #self.SkillGroupList then
        self.SelectIndex = self.SelectIndex + 1
    else
        self.SelectIndex = 1
    end
    self:UpdateSkill()
    self.Base:SetSkillInfoState(self.SelectIndex)
    self:PlaySwitchSkillAnime()
end

function XUiPanelSkillInfo:OnBtnPriorClick()
    if self.SelectIndex > 1 then
        self.SelectIndex = self.SelectIndex - 1
    else
        self.SelectIndex = #self.SkillGroupList
    end
    self:UpdateSkill()
    self.Base:SetSkillInfoState(self.SelectIndex)
    self:PlaySwitchSkillAnime()
end

function XUiPanelSkillInfo:OnBtnSwitchMainSkillClick()
    local mainSkillGroupList = self.Partner:GetMainSkillGroupList()
    local curIndex = 1
    self.ShowMainSkillGroup = self.ShowMainSkillGroup or self.SkillGroup
    for index, masinSkillGroup in ipairs(mainSkillGroupList) do
        if masinSkillGroup == self.ShowMainSkillGroup then
            curIndex = index
        end
    end

    local nextIndex = 1
    if curIndex < #mainSkillGroupList then
        nextIndex = curIndex + 1
    end
    self.ShowMainSkillGroup = mainSkillGroupList[nextIndex]
    self:UpdateSkill()
    self:PlaySwitchMainSkillAnime()
end

function XUiPanelSkillInfo:UpdateCost()
    local costMoney = self.Partner:GetSkillUpgradeMoney().Count
    local isCoinsEnough = XDataCenter.ItemManager.GetCoinsNum() >= costMoney
    self.TxtCoinCount.text = costMoney
    self.TxtCoinCount.color = CONDITION_COLOR[isCoinsEnough]
    local canLevelUp = isCoinsEnough

    local consumeItems = self.Partner:GetSkillUpgradeItem()
    for index, item in pairs(consumeItems) do
        local grid = self.GridCostItems[index]
        if not grid then
            local obj = CS.UnityEngine.Object.Instantiate(self.GridItem, self.PanelItem)
            grid = XUiGridCostItem.New(self.Root, obj)
            self.GridCostItems[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(item.Id, item.Count)

        local haveCount = XDataCenter.ItemManager.GetCount(item.Id)
        canLevelUp = canLevelUp and haveCount >= item.Count
    end

    self.GridItem.gameObject:SetActiveEx(false)
    for i = #consumeItems + 1, #self.GridCostItems do
        self.GridCostItems[i].GameObject:SetActiveEx(false)
    end

    self.BtnSkillUp:SetDisable(not canLevelUp)
end

function XUiPanelSkillInfo:OnBtnSkillUpClick(ClientLongPressIncreaseLevel)
    if not self.NotMaskShow then
        self.NotMaskShow = true
        --self.PanelMask.gameObject:SetActiveEx(false)
    end

    XDataCenter.PartnerManager.PartnerSkillUpRequest(self.Partner:GetId(), self.SkillGroup:GetActiveSkillId(), ClientLongPressIncreaseLevel or DefaultCount, 
        function(skillUpInfo)
           --XLuaUiManager.Open("UiPartnerPopupTip",CS.XTextManager.GetText("PartnerSkillUpConfirm"))
            self.Base:SetSkillUpInfo(skillUpInfo, self.Partner)
            self.Base:ShowPanel()
        end
    )
end

function XUiPanelSkillInfo:OnSkillPreviewClick()
    if self:IsMainSkill() then
        local mainSkillGroupList = self.Partner:GetMainSkillGroupList()
        XLuaUiManager.Open("UiPartnerSkillPreview", mainSkillGroupList, XPartnerConfigs.SkillType.MainSkill)
    else
        XLuaUiManager.Open("UiPartnerSkillPreview", {self.SkillGroup}, XPartnerConfigs.SkillType.PassiveSkill)
    end
end

function XUiPanelSkillInfo:IsMainSkill()
    return self.SkillGroup:GetSkillType() == XPartnerConfigs.SkillType.MainSkill
end

function XUiPanelSkillInfo:PlayEnableAnime()
    self.Base.Animation:GetObject("PanelSkillInfoEnable"):PlayTimelineAnimation()
end

function XUiPanelSkillInfo:PlaySwitchMainSkillAnime()
    self.Base.Animation:GetObject("QieHuan2"):PlayTimelineAnimation()
end

function XUiPanelSkillInfo:PlaySwitchSkillAnime()
    self.Base.Animation:GetObject("QieHuan1"):PlayTimelineAnimation()
end

return XUiPanelSkillInfo