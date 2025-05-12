local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XGridTheatre3RewardChoose = require("XUi/XUiTheatre3/Adventure/Reward/XGridTheatre3RewardChoose")

---@class XUiTheatre3RewardChoose : XLuaUi
---@field BGM UnityEngine.Transform
---@field _Control XTheatre3Control
local XUiTheatre3RewardChoose = XLuaUiManager.Register(XLuaUi, "UiTheatre3RewardChoose")

function XUiTheatre3RewardChoose:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3RewardChoose:OnStart(isProp)
    self._IsProp = isProp
    self:InitUi()
end

function XUiTheatre3RewardChoose:OnEnable()
    self:RefreshUi()
    if self._IsProp and self.BGM then
        for i = 0, self.BGM.childCount - 1 do
            self.BGM:GetChild(i).gameObject:SetActiveEx(true)
        end
    end
    self:AddEventListener()
end

function XUiTheatre3RewardChoose:OnDisable()
    self:RemoveEventListener()
end

function XUiTheatre3RewardChoose:OnDestroy()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self._PanelAsset)
end

function XUiTheatre3RewardChoose:InitUi()
    self:InitPanelAsset()
    self:InitPanelProp()
    self:InitPanelFightReward()
    self:InitButton()
    self:InitEffect()
end

function XUiTheatre3RewardChoose:RefreshUi()
    local step = self._Control:GetAdventureCurChapterDb():GetLastStep()
    self:RefreshPanelProp(step)
    self:RefreshPanelFightReward(step)
    self:RefreshBtn()
end

--region Ui - PanelAsset
function XUiTheatre3RewardChoose:InitPanelAsset()
    self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(
        {XEnumConst.THEATRE3.Theatre3InnerCoin,},
        self.PanelSpecialTool, self,
        nil,
        function()
            self._Control:OpenAdventureTips(XEnumConst.THEATRE3.Theatre3InnerCoin)
        end)
end
--endregion

--region Ui - PanelProp
function XUiTheatre3RewardChoose:InitPanelProp()
    self.PanelPropChoose.gameObject:SetActiveEx(self._IsProp)
    if not self._IsProp then
        return
    end
    ---@type XGridTheatre3RewardChoose[]
    self._GridPropRewardList = {
        XGridTheatre3RewardChoose.New(self.PanelPropReward1, self),
        XGridTheatre3RewardChoose.New(self.PanelPropReward2 or XUiHelper.Instantiate(self.PanelPropReward1.gameObject, self.PanelPropReward1.transform.parent), self),
        XGridTheatre3RewardChoose.New(self.PanelPropReward3 or XUiHelper.Instantiate(self.PanelPropReward1.gameObject, self.PanelPropReward1.transform.parent), self),
    }
end

function XUiTheatre3RewardChoose:RefreshPanelProp()
    if not self._IsProp then
        return
    end
    local clickFunc = function(gridProp)
        self:RefreshPropSelect(gridProp)
    end
    local ItemList = self._Control:GetAdventureStepSelectItemList()
    for i, grid in ipairs(self._GridPropRewardList) do
        if XTool.IsNumberValid(ItemList[i]) then
            grid:Refresh(self._IsProp, ItemList[i], clickFunc)
        else
            grid:Close()
        end
    end
end

---@param grid XGridTheatre3RewardChoose
function XUiTheatre3RewardChoose:RefreshPropSelect(grid)
    for _, gridProp in ipairs(self._GridPropRewardList) do
        gridProp:SetSelect(grid == gridProp)
    end
end
--endregion

--region Ui - PanelFightReward
function XUiTheatre3RewardChoose:InitPanelFightReward()
    self.SViewRewardList.gameObject:SetActiveEx(not self._IsProp)
    if self._IsProp then
        return
    end
    if not self.PanelNoReward then
        self.PanelNoReward = XUiHelper.TryGetComponent(self.SViewRewardList, "PanelNoReward")
    end
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRewardList)
    self.DynamicTable:SetProxy(XGridTheatre3RewardChoose, self)
    self.DynamicTable:SetDelegate(self)
    self.GridReward.gameObject:SetActiveEx(false)
end

function XUiTheatre3RewardChoose:RefreshPanelFightReward()
    if self._IsProp then
        return
    end
    local rewards = {}
    for _, v in pairs(self._Control:GetAdventureStepSelectRewardList()) do
        if not v.Received then
            table.insert(rewards, v)
        end
    end
    self.DynamicTable:SetDataSource(rewards)
    self.DynamicTable:ReloadDataASync(1)

    if self.PanelNoReward then
        self.PanelNoReward.gameObject:SetActiveEx(not self._Control:IsAdventureHaveFightReward())
    end
    self:RefreshEffect()
end

---@param grid XGridTheatre3RewardChoose
function XUiTheatre3RewardChoose:OnDynamicTableEvent(event, index, grid)
    if not grid then
        return
    end
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        grid:Refresh(self._IsProp, data)
    end
end
--endregion

--region Ui - Btn
function XUiTheatre3RewardChoose:InitButton()
    self.BtnReceiveRed.gameObject:SetActiveEx(not self._IsProp)
end

function XUiTheatre3RewardChoose:RefreshBtn()
    --self.BtnSetBag:SetNameByGroup(0, XUiHelper.GetText("Theatre3AdventureSuitBtnName", self._Control:GetAdventureCurEquipSuitCount()))
    --self.BtnProp:SetNameByGroup(0, XUiHelper.GetText("Theatre3AdventurePropBtnName", #self._Control:GetAdventureCurItemList()))
    self.BtnSetBag:SetNameByGroup(1, self._Control:GetAdventureCurEquipSuitCount())
    self.BtnProp:SetNameByGroup(1, self._Control:GetAdventureCurItemCount())
    self.BtnFightResult.gameObject:SetActiveEx(self._Control:GetShowDamageStatisticsIsOpen())
end
--endregion

--region Ui - Effect
function XUiTheatre3RewardChoose:InitEffect()
    if not self.Effect then
        ---@type UnityEngine.Transform
        self.Effect = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/Effect")
    end
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3RewardChoose:RefreshEffect()
    if not self.Effect then
        return
    end
    local quantumLevelCfg = self._Control:GetCfgQuantumLevelByValue(self._Control:GetAdventureQuantumValue(true) + self._Control:GetAdventureQuantumValue(false))
    --全屏特效
    if quantumLevelCfg and not string.IsNilOrEmpty(quantumLevelCfg.ScreenEffectUrl) then
        local screenEffectUrl = self._Control:GetClientConfig(quantumLevelCfg.ScreenEffectUrl, self._Control:IsAdventureALine() and 1 or 2)
        self.Effect:LoadUiEffect(screenEffectUrl)
        self.Effect.gameObject:SetActiveEx(true)
    end
end
--endregion

--region Ui - BtnListener
function XUiTheatre3RewardChoose:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnReceiveRed, self.OnBtnReceiveRedClick)
    self._Control:RegisterClickEvent(self, self.BtnProp, self.OnBtnPropClick)
    self._Control:RegisterClickEvent(self, self.BtnSetBag, self.OnBtnSetBagClick)
    self._Control:RegisterClickEvent(self, self.BtnFightResult, self.OnBtnFightResultClick)
end

function XUiTheatre3RewardChoose:OnBtnBackClick()
    self._Control:OpenTextTip(handler(self, self.Close), XUiHelper.ReadTextWithNewLineWithNotNumber("TipTitle"), XUiHelper.ReadTextWithNewLineWithNotNumber("Theatre3SettleRewardTip"))
end

function XUiTheatre3RewardChoose:OnBtnReceiveRedClick()
    if not self._IsProp then    -- 战斗奖励退出
        local finishRewardFunc = function()
            self._Control:RequestAdventureEndRecvFightReward(function()
                self._Control:CheckAndOpenAdventureNextStep(true, nil, true)
            end)
        end
        if self._Control:IsAdventureHaveFightReward() then
            self._Control:OpenTextTip(finishRewardFunc,
                    XUiHelper.ReadTextWithNewLineWithNotNumber("Theatre3EndFightRewardTitle"),
                    XUiHelper.ReadTextWithNewLineWithNotNumber("Theatre3EndFightRewardContent"))
        else
            finishRewardFunc()
        end
    end
end

function XUiTheatre3RewardChoose:OnBtnPropClick()
    self._Control:OpenAdventureProp()
end

function XUiTheatre3RewardChoose:OnBtnSetBagClick()
    self._Control:OpenShowEquipPanel()
end

function XUiTheatre3RewardChoose:OnBtnFightResultClick()
    self._Control:OpenAdventureFightResult()
end
--endregion

--region Event
function XUiTheatre3RewardChoose:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_ADVENTURE_RECV_FIGHT_REWARD, self.RefreshUi, self)
end

function XUiTheatre3RewardChoose:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_ADVENTURE_RECV_FIGHT_REWARD, self.RefreshUi, self)
end
--endregion

return XUiTheatre3RewardChoose