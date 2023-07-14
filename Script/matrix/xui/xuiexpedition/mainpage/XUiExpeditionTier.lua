--关卡层组件
local XUiExpeditionTier = XClass(nil, "XUiExpeditionTier")
local TierLayOffScript = require("XUi/XUiExpedition/MainPage/XUiTierLayOff")
local TierLayOutScript = require("XUi/XUiExpedition/MainPage/XUiTierLayOut")
local TierInfiScript = require("XUi/XUiExpedition/MainPage/XUiTierInfinity")
local UiName = {
    TierLayOff = "TierLayOff", --收起关卡的普通层
    TierLayOut = "TierLayOut", --展开关卡的普通层
    TierInfinity = "TierInfi", --无限层
}
local LayOffControl = require("XUi/XUiExpedition/MainPage/XUiTierLayOff")
local LayOutControl = require("XUi/XUiExpedition/MainPage/XUiTierLayOut")
function XUiExpeditionTier:Ctor(chapter)
    self.ChapterComponent = chapter
    self.RootUi = self.ChapterComponent.RootUi
    self.Content = self.RootUi.PanelChapterContent
end

function XUiExpeditionTier:Init()
    if self.InitialCompelete then return end
    self:GetTierLayOff()
    self:GetTierLayOut()
    self:GetTierInfi()
    self.InitialCompelete = true
end

function XUiExpeditionTier:RefreshData(tier)
    if not tier then return end
    self.Tier = tier
    self.IsInfinityTier = self.Tier:CheckIsInfiTier()
    self:Init()
    if self.IsInfinityTier then
        self:RefreshInfiTier()
        self.CurrentStatus = UiName.TierInfinity
    else
        self:RefreshNormalTier()
        self.CurrentStatus = UiName.TierLayOff
    end
end

function XUiExpeditionTier:RefreshInfiTier()
    if self.TierLayOff then self:GetTierLayOff():Hide() end
    if self.TierLayOut then self:GetTierLayOut():Hide() end
    self:GetTierInfi():RefreshData(self.Tier)
    self:GetTierInfi():Show()
end

function XUiExpeditionTier:RefreshNormalTier()
    if self.TierInfi then self:GetTierInfi():Hide() end
    self:GetTierLayOff():RefreshData(self.Tier)
    self:GetTierLayOut():RefreshData(self.Tier)
    self:LayOff()
end

function XUiExpeditionTier:GetTierLayOff()
    if not self.TierLayOff then
        local obj = self:GetTierGameObject(UiName.TierLayOff)
        self.TierLayOff = TierLayOffScript.New(obj, self)
    end
    return self.TierLayOff
end

function XUiExpeditionTier:GetTierLayOut()
    if not self.TierLayOut then
        local obj = self:GetTierGameObject(UiName.TierLayOut)
        self.TierLayOut = TierLayOutScript.New(obj, self)
    end
    return self.TierLayOut
end

function XUiExpeditionTier:GetTierInfi()
    if not self.TierInfi then
        local obj = self:GetTierGameObject(UiName.TierInfinity)
        self.TierInfi = TierInfiScript.New(obj, self)
    end
    return self.TierInfi
end

function XUiExpeditionTier:GetTierGameObject(uiName)
    local obj = CS.UnityEngine.Object.Instantiate(self.RootUi["Grid" .. uiName])
    obj.transform:SetParent(self.Content, false)
    obj.gameObject:SetActiveEx(false)
    obj.gameObject.name = uiName .. self.Tier:GetDifficultyName() .. self.Tier:GetOrderId()
    return obj
end
--============
--收起关卡
--============
function XUiExpeditionTier:LayOff(isClick)
    local show = function()
        self:GetTierLayOff():Show()
        self.CurrentStatus = UiName.TierLayOff
    end
    self:GetTierLayOut():Hide(isClick and show)
    if not isClick then
        show()
    end
end
--============
--列出关卡
--isEnable : 是否是界面显示时的列出关卡
--============
function XUiExpeditionTier:LayOut(isEnable)
    self:GetTierLayOff():Hide()
    self:GetTierLayOut():Show(isEnable)
    self.CurrentStatus = UiName.TierLayOut
end
--============
--点击收起关卡层时
--============
function XUiExpeditionTier:OnClickLayOff()
    self.ChapterComponent:SetTierSelect(self.Tier:GetOrderId(), true)
end
--============
--点击展开关卡层时
--============
function XUiExpeditionTier:OnClickLayOut()
    if not self.IsSelect then return end
    if self.IsSelect then self.IsSelect = false end
    self.ChapterComponent:SetTierSelect(self.Tier:GetOrderId(), false, true)
end
--============
--点击无尽层时
--============
function XUiExpeditionTier:OnClickInfi()
    if not self.IsInfinityTier then return end
    self.IsSelect = not self.IsSelect
    self.ChapterComponent:SetTierSelect(self.Tier:GetOrderId(), self.IsSelect, true)
    if self.IsSelect then
        XLuaUiManager.Open("UiExpeditionStageDetail", self.Tier:GetInfiStage(), self.RootUi, function() self:GetTierInfi():SetSelect(false) end)
    end
end
--============
--设置关卡层选中状态
--============
function XUiExpeditionTier:SetSelect(value, isClick, isEnable)
    self.IsSelect = value
    if self.IsInfinityTier then
        self:GetTierInfi():SetSelect(self.IsSelect)
    else
        if self.IsSelect then
            self:LayOut(isEnable)
        else
            self:LayOff(isClick)
        end
    end
end

function XUiExpeditionTier:Hide()
    self:GetTierLayOff():Hide()
    self:GetTierLayOut():Hide()
    self:GetTierInfi():Hide()
end

function XUiExpeditionTier:GetRectTransform()
    return self["Get" .. self.CurrentStatus](self).Transform
end

function XUiExpeditionTier:PlayAnimEnable(onStageShowCb)
    if self.CurrentStatus == UiName.TierLayOff then
        
    elseif self.CurrentStatus == UiName.TierLayOut then
        self:GetTierLayOut():PlayAnimEnable(onStageShowCb)
    elseif self.CurrentStatus == UiName.TierInfinity then
        self:GetTierInfi():PlayAnimEnable()
    end
end

return XUiExpeditionTier