local XUiPanelStageSelect = XClass(nil, "XUiPanelStageSelect")
local CSTextManagerGetText = CS.XTextManager.GetText
local XUiSTFunctionButton = require("XUi/XUiSuperTower/Common/XUiSTFunctionButton")
function XUiPanelStageSelect:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiPanelStageSelect:SetButtonCallBack()
    self.BtnMap.CallBack = function()
        self:OnBtnMapClick()
    end
    self.BtnAdventure.CallBack = function()
        self:OnBtnAdventureClick()
    end
    
    self.FunctionBtnSpecial = XUiSTFunctionButton.New(self.BtnSpecial, function() self:OnBtnSpecialClick() end, "CheckSpecialCharacterIsOpen")
    
    self.BtnGacha.CallBack = function()
        self:OnBtnGachaClick()
    end
    
    self.PanelTask:GetObject("BtnClick").CallBack = function()
        self:OnTagetInfoClick()
    end
end

function XUiPanelStageSelect:OnBtnMapClick()
    local index = XDataCenter.SuperTowerManager.ThemeIndex.ThemeAll
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ST_MAP_THEME_SELECT, index)
end

function XUiPanelStageSelect:OnBtnAdventureClick()
    local playingId = XDataCenter.SuperTowerManager.GetStageManager():GetPlayingTierId()
    if playingId == 0 or playingId == self.STTheme:GetId() then
        XLuaUiManager.Open("UiSuperTowerStageDetail04", self.STTheme)
    else
        local tierTheme = XDataCenter.SuperTowerManager.GetStageManager():GetThemeById(playingId)
        XUiManager.TipMsg(CSTextManagerGetText("STTierCanNotPlayHint", tierTheme:GetName()))
    end
end

function XUiPanelStageSelect:UpdatePanel(data)
    self.STTheme = data
    self:UpdateInfo()
    self:UpdateAdventure()
    self:UpdatePanelTask()
    self:UpdateGachaRed()
    XRedPointManager.CheckOnceByButton(self.BtnSpecial, { XRedPointConditions.Types.CONDITION_SUPERTOWER_ROLE_INDULT })
end

function XUiPanelStageSelect:UpdateInfo()
    self.TxtName.text = self.STTheme:GetName()
    self.BtnMap:SetName(CSTextManagerGetText("STMainBtnMapName"))
    self.BtnSpecial:SetName(CSTextManagerGetText("STMainBtnSpecialName"))
    self.BtnGacha:SetName(CSTextManagerGetText("STMainBtnGachaName"))
end

function XUiPanelStageSelect:UpdateGachaRed()
    local gachaNeedItemCount = XSuperTowerConfigs.GetClientBaseConfigByKey("GachaNeedItemCount", true)
    local gachaItem = XSuperTowerConfigs.GetClientBaseConfigByKey("GachaItemId", true)
    local gachaItemCount = XDataCenter.ItemManager.GetCount(gachaItem)
    self:ShowGachaRed(gachaItemCount >= gachaNeedItemCount)
end

function XUiPanelStageSelect:UpdateTime(time)
    self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiPanelStageSelect:UpdateAdventure()
    self.TxtLayer.text = CSTextManagerGetText("STThemeLayer", self.STTheme:GetTierStr())
    self.TxtLayerTop.text = CSTextManagerGetText("STThemeLayer", self.STTheme:GetHistoryTierStr())
    self.TxtHonorName.text = CSTextManagerGetText("STHonorNameText")
    self.TxtHonor.text = self.STTheme:GetTierScore()

    self.BtnAdventure:SetName(self.STTheme:GetTierName())
    self.BtnAdventure:ShowTag(self.STTheme:CheckTierIsPlaying())
end

function XUiPanelStageSelect:UpdatePanelTask()
    local functionManager = XDataCenter.SuperTowerManager.GetFunctionManager()
    local newFunction = functionManager:GetTheNewFunction()
    self.PanelTask:GetObject("TxtTarget").text = newFunction and newFunction:GetUnLockDescription() or ""
    self.PanelTask:GetObject("TxtName").text = CSTextManagerGetText("STTagetFunctionTitleText")
    self.PanelTask.gameObject:SetActiveEx(newFunction)
end

function XUiPanelStageSelect:ShowPanel(IsShow)
    self.GameObject:SetActiveEx(IsShow)
end

function XUiPanelStageSelect:OnBtnSpecialClick()
    XLuaUiManager.Open("UiSuperTowerTedianUP")
    XRedPointManager.CheckOnceByButton(self.BtnSpecial, { XRedPointConditions.Types.CONDITION_SUPERTOWER_ROLE_INDULT })
end

function XUiPanelStageSelect:OnBtnGachaClick()
    local gachaSkipId = XSuperTowerConfigs.GetClientBaseConfigByKey("GachaSkipId")
    if gachaSkipId then
        XFunctionManager.SkipInterface(gachaSkipId)
    end
end

function XUiPanelStageSelect:OnTagetInfoClick()
    local functionManager = XDataCenter.SuperTowerManager.GetFunctionManager()
    local newFunction = functionManager:GetTheNewFunction()
    local itemId = newFunction:GetItemId()
    if itemId then
        local ownCount = XDataCenter.ItemManager.GetCount(itemId)
        local data = {Id = itemId, Count = ownCount}
        XLuaUiManager.Open("UiTip", data)
    end
end

function XUiPanelStageSelect:ShowGachaRed(IsShow)
    self.BtnGacha:ShowReddot(IsShow)
end

return XUiPanelStageSelect