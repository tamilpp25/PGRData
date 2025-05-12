local XUiNameplateTip = XLuaUiManager.Register(XLuaUi, "UiNameplateTip")
local XUiGridNameplate = require("XUi/XUiNameplate/XUiGridNameplate")


function XUiNameplateTip:OnAwake()

    self.BtnClose.CallBack = function()
        self:Close()
    end

    self.BtnDress.CallBack = function()
        self:OnBtnDressClick()
    end
    self.BtnUnDress.CallBack = function()
        self:OnBtnDressClick(true)
    end

    self.NameplateGrid = XUiGridNameplate.New(self.GridNameplate, self)
    self.TxtHintList = {}

    for index = 1, 4 do
        self.TxtHintList[index] = self["TxtHint"..index]
    end
    
    
end

function XUiNameplateTip:OnStart(Id, isOnlyShow, isInReward, isHideCondition)
    self.NameplateId = Id
    local data =  XDataCenter.MedalManager.CheckNameplateGroupUnluck(XMedalConfigs.GetNameplateGroup(Id))
    if data and data:GetNameplateId() == Id then
        self.Data = data
    end
    self.IsHideCondition = isHideCondition
    self.IsOnlyShow = isOnlyShow
    self.IsInReward = isInReward
    self:UpdateAllInfo(self.NameplateId, self.Data)
end

function XUiNameplateTip:OnEnable()

end

function XUiNameplateTip:UpdateAllInfo(nameplateId, nameplateData)
    self:UpdateRightPanel(nameplateId, nameplateData)
    self:UpdateNameplatePanel(nameplateId, nameplateData)
end

function XUiNameplateTip:UpdateRightPanel(nameplateId, nameplateData)
    self.TxtTitleName.text = XMedalConfigs.GetNameplateName(nameplateId)
    self.TxtInfo.text = XMedalConfigs.GetNameplateDescription(nameplateId)
    local HintList = XMedalConfigs.GetNameplateHint(nameplateId)
    for index, text in pairs(self.TxtHintList) do
        if HintList[index] then
            text.text = XMedalConfigs.GetNameplateMapText(HintList[index])
            text.gameObject:SetActiveEx(true)
        else
            text.gameObject:SetActiveEx(false)
        end
    end

    if self.IsOnlyShow or not nameplateData then
        self.BtnDress.gameObject:SetActiveEx(false)
        self.BtnUnDress.gameObject:SetActiveEx(false)
    else
        if not nameplateData:IsNamepalteExpire() then
            if nameplateData:IsNameplateDress() then
                self.BtnDress.gameObject:SetActiveEx(false)
                self.BtnUnDress.gameObject:SetActiveEx(true)
            else
                self.BtnDress.gameObject:SetActiveEx(true)
                self.BtnUnDress.gameObject:SetActiveEx(false)
                self.BtnDress:SetDisable(false)
            end
        else
            self.BtnDress.gameObject:SetActiveEx(true)
            self.BtnUnDress.gameObject:SetActiveEx(false)
            self.BtnDress:SetDisable(true, false)
        end
    end

    self.PanelNameplateCondition.gameObject:SetActiveEx(true)
    self.TxtCondition.text = XMedalConfigs.GetNameplateGetWay(nameplateId)
    if nameplateData and XDataCenter.MedalManager.CheckNameplateGroupUnluck(nameplateData:GetNameplateGroup()) then
        self.ImgConditionUnlock.gameObject:SetActiveEx(true)
    else
        self.ImgConditionUnlock.gameObject:SetActiveEx(false)
    end

    if nameplateData and nameplateData:GetNamepalteGetTime() then
        self.TxtTime.text = CS.XTextManager.GetText("NameplateGetTime", nameplateData:GetNamepalteGetTimeToString()) 
    else
        self.TxtTime.text = ""
    end

    -- 通用格子打开不显示这两个控件
    self.TxtTime.gameObject:SetActiveEx(not self.IsHideCondition)
    self.ImgConditionUnlock.gameObject:SetActiveEx(not self.IsHideCondition)
end

function XUiNameplateTip:UpdateNameplatePanel(nameplateId, nameplateData)
    self.NameplateGrid:UpdateDataById(nameplateId, false, false, self.IsInReward)
    self.NameplateGrid:HideNewLabel()
    if self.IsOnlyShow then
        self.NameplateGrid:HidePressLabel()
    end
    if not XMedalConfigs.GetNameplateQualityIcon(nameplateId) then
        self.IconLevel.gameObject:SetActiveEx(false)
    else
        self.IconLevel.gameObject:SetActiveEx(true)
        self.IconLevel:SetSprite(XMedalConfigs.GetNameplateQualityIcon(nameplateId))
    end

    if XMedalConfigs.GetNameplateUpgradeType(nameplateId) ~= XMedalConfigs.NameplateGetType.TypeThree or not nameplateData then
        self.PanelLevel.gameObject:SetActiveEx(false)
    else
        self.PanelLevel.gameObject:SetActiveEx(true)
        self.TextLevel.text = CS.XTextManager.GetText("NameplateLv", XMedalConfigs.GetNameplateQuality(nameplateId))
        self.TextNum.text = CS.XTextManager.GetText("NameplateExp", nameplateData:GetNamepalteExp(), nameplateData:GetNameplateUpgradeExp())
        self.ImageExp.fillAmount = nameplateData:GetNamepalteExp() / nameplateData:GetNameplateUpgradeExp()
    end
      
end

function XUiNameplateTip:ShowLock(IsLock)
    self.ImgConditionUnlock.gameObject:SetActiveEx(not IsLock)
end

function XUiNameplateTip:OnBtnDressClick(isUnDress)
    if not self.Data:IsNamepalteExpire() then
        local nameplateId = isUnDress and 0 or self.Data:GetNameplateId()
        XDataCenter.MedalManager.WearNameplate(nameplateId, function()
            self:UpdateAllInfo(self.NameplateId, self.Data)
        end)
    else
        self:UpdateAllInfo(self.NameplateId, self.Data)
        XUiManager.TipText("NameplateOutTime")
    end
end