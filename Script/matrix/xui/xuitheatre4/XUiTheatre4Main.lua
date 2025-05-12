local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiTheatre4Main : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4Main = XLuaUiManager.Register(XLuaUi, "UiTheatre4Main")

function XUiTheatre4Main:OnAwake()
    ---@type XUiGridCommon
    self._BattlePassReward = nil
    self:RegisterUiEvents()
end

function XUiTheatre4Main:OnStart()
    
end

function XUiTheatre4Main:OnEnable()
    self._Control:CheckAndFixAdventureData()
    self._Control.SetControl:ResetStep()
    self:RefreshRedPoint()
    self:RefreshBattlePass()
    self:RefreshRetreatBtn()
    self._Control.SystemControl:CheckShowBattlePassLvUp(self)
    self:RefreshBgByEnding()
end

function XUiTheatre4Main:OnGetEvents()

end

function XUiTheatre4Main:OnGetLuaEvents()

end

function XUiTheatre4Main:OnNotify(event, ...)

end

function XUiTheatre4Main:OnDisable()
    if self.PopupLvTimer then
        XScheduleManager.UnSchedule(self.PopupLvTimer)
        self.PopupLvTimer = nil
    end
end

function XUiTheatre4Main:OnDestroy()
end

function XUiTheatre4Main:RefreshRedPoint()
    self.BtnHandBook:ShowReddot(self._Control.SystemControl:CheckAllHandBookRedDot())
    self.BtnScience:ShowReddot(self._Control.SystemControl:CheckAllTechRedDot())
    self.BtnBP:ShowReddot(self._Control.SystemControl:CheckAllBattlePassRedDot())
end

function XUiTheatre4Main:RefreshBattlePass()
    local entity, levelCurrentExp = self._Control.SystemControl:GetCurrentBattlePassEntity()
    local config = entity:GetConfig()
    local totalExp = entity:GetCurrentTotalExp()
    local levelExp = entity:GetCurrentExp()
    local icon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.Theatre4BpExperience)
    local maxExp = self._Control.SystemControl:GetBattlePassMaxExp()

    if totalExp >= maxExp then
        self.TxtPointsNum.text = self._Control:GetClientConfig("BpFullLevelTip")
        self.ImgBpProgress.fillAmount = 1
    else
        self.TxtPointsNum.text = (totalExp - levelExp) .. "/" .. levelCurrentExp
        self.ImgBpProgress.fillAmount = (totalExp - levelExp) / levelCurrentExp
    end

    self.IconPoints:SetRawImage(icon)
    self.TxtBpLvNum.text = config:GetLevel()
    self:RefreshBattlePassReward(entity)
end

---@param currentEntity XTheatre4BattlePassEntity
function XUiTheatre4Main:RefreshBattlePassReward(currentEntity)
    local nextEntity = self._Control.SystemControl:GetNextDisplayBattlePassEntity(currentEntity:GetIndex())
    local itemId = nextEntity:GetItemId()

    if not self._BattlePassReward then
        self._BattlePassReward = XUiGridCommon.New(self, self.GridReward)
        self._BattlePassReward:SetCustomItemTip(Handler(self, self.OpenItemDetail))
    end

    self._BattlePassReward:Refresh(itemId)
    self._BattlePassReward:SetUiActive(self._BattlePassReward.TxtName, false)
end

-- 刷新终止按钮
function XUiTheatre4Main:RefreshRetreatBtn()
    -- 检查冒险数据是否为空
    if self._Control:CheckAdventureDataEmpty() then
        self.BtnRetreat.gameObject:SetActiveEx(false)
    else
        self.BtnRetreat.gameObject:SetActiveEx(true)
    end
end

function XUiTheatre4Main:OpenItemDetail(itemId)
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", itemId)
end

function XUiTheatre4Main:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    self._Control:RegisterClickEvent(self, self.BtnBattle, self.OnBtnBattleClick)
    self._Control:RegisterClickEvent(self, self.BtnRetreat, self.OnBtnRetreatClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBP, self.OnBtnBpClick)
    XUiHelper.RegisterClickEvent(self, self.BtnScience, self.OnBtnScienceClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHandBook, self.OnBtnHandBookClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiTheatre4Main:OnBtnBackClick()
    self:Close()
end

function XUiTheatre4Main:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTheatre4Main:OnBtnBattleClick()
    -- 检查冒险数据是否为空
    if self._Control:CheckAdventureDataEmpty() then
        self._Control.SetControl:NextStep()
    else
        self._Control:EnterRequest(function()
            self._Control.SetControl:NextStep()
        end)
    end
end

-- 终止
function XUiTheatre4Main:OnBtnRetreatClick()
    local title = XUiHelper.GetText("Theatre4PopupCommonTitle")
    local content = XUiHelper.GetText("Theatre4RetreatConfirm")
    local sureCallback = handler(self, self.OnBtnRetreatSureClick)
    self._Control:ShowCommonPopup(title, content, sureCallback)
end

function XUiTheatre4Main:OnBtnRetreatSureClick()
    -- 请求终止冒险
    self._Control:SettleAdventureRequest(function()
        XMVCA.XTheatre4:CheckAndOpenAdventureSettle()
    end)
end

function XUiTheatre4Main:OnBtnBpClick()
    XLuaUiManager.Open("UiTheatre4LvReward")
end

function XUiTheatre4Main:OnBtnScienceClick()
    XLuaUiManager.Open("UiTheatre4Skill")
end

function XUiTheatre4Main:OnBtnHandBookClick()
    XLuaUiManager.Open("UiTheatre4Handbook")
end

function XUiTheatre4Main:RefreshBgByEnding()
    local mainBg = self._Control.SystemControl:GetMainBgByEnding()
    if mainBg then
        self.Bg:SetRawImage(mainBg)
    end
end

return XUiTheatre4Main
