local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XUiFubenMaverickCharacter = XLuaUiManager.Register(XLuaUi, "UiFubenMaverickCharacter")
local XUiFubenMaverickCharacterPanel = require("XUi/XUiFubenMaverick/XUiScrollView/XUiFubenMaverickCharacterPanel")
local XUiFubenMaverickCharacterInfo = require("XUi/XUiFubenMaverick/XUiOther/XUiFubenMaverickCharacterInfo")
local XUiFubenMaverickCharacterTalent = require("XUi/XUiFubenMaverick/XUiOther/XUiFubenMaverickCharacterTalent")

function XUiFubenMaverickCharacter:OnAwake()
    self:InitButtons()
    self:InitOtherUi()
    self:InitPanelAssets()
    self:InitDynamicTable()
end

function XUiFubenMaverickCharacter:OnStart()
    self:SetAutoCloseInfo(XDataCenter.MaverickManager.GetEndTime(), function(isClose)
        if isClose then
            XDataCenter.MaverickManager.EndActivity()
        end
    end, nil , 0)

    self:SetPanelLvActive(false)
    self.UiCharacterPanel:Refresh(true)
end

function XUiFubenMaverickCharacter:OnEnable()
    self.Super.OnEnable(self)
    
    self:UpdateAssets()
end

function XUiFubenMaverickCharacter:OnGetEvents()
    return { XEventId.EVENT_MAVERICK_MEMBER_UPDATE }
end

function XUiFubenMaverickCharacter:OnNotify(evt)
    if evt == XEventId.EVENT_MAVERICK_MEMBER_UPDATE then
        self.UiCharacterPanel:Refresh()
    end
end

function XUiFubenMaverickCharacter:CheckRedDots()
    XRedPointManager.CheckOnce(self.OnCheckRedDot, self, { XRedPointConditions.Types.CONDITION_MAVERICK_CHARACTER }, self.MemberId)
end

function XUiFubenMaverickCharacter:OpenTalentSummary(memberId)
    XLuaUiManager.Open("UiFubenMaverickBuffSummary", memberId)
end

function XUiFubenMaverickCharacter:InitOtherUi()
    self.UiCharacterInfo = XUiFubenMaverickCharacterInfo.New(self.PanelOwnedInfo)
    self.UiCharacterTalent = XUiFubenMaverickCharacterTalent.New(self, self.PanelLv)
end

function XUiFubenMaverickCharacter:InitButtons()
    self:BindHelpBtn(self.BtnHelp, "MaverickHelp")
    self.BtnBack.CallBack = function()
        if self.IsPanelLvShow then
            self:SetPanelLvActive(false)
        else
            self:Close()
        end
    end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnLevelUp.onClick:AddListener(function() self:SetPanelLvActive(true) end)
end

function XUiFubenMaverickCharacter:SetPanelLvActive(active)
    self.IsPanelLvShow = active
    self.PanelLv.gameObject:SetActiveEx(active)
    self.PanelOwnedInfo.gameObject:SetActiveEx(not active)
    self.UiCharacterPanel.GameObject:SetActiveEx(not active)
    --更新镜头
    if active then
        self.UiCharacterPanel:UpdateCamera(XDataCenter.MaverickManager.CameraTypes.ADAPT)
    else
        self.UiCharacterPanel:UpdateCamera(XDataCenter.MaverickManager.CameraTypes.MAIN)
    end
end

function XUiFubenMaverickCharacter:InitPanelAssets()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
            {
                XDataCenter.MaverickManager.LvUpConsumeItemId,
            },
            handler(self, self.UpdateAssets),
            self.AssetActivityPanel
    )
end

function XUiFubenMaverickCharacter:UpdateAssets()
    self.AssetActivityPanel:Refresh(
            {
                XDataCenter.MaverickManager.LvUpConsumeItemId,
            }
    )
end

function XUiFubenMaverickCharacter:InitDynamicTable()
    local index = 1
    local uiSkills = { }
    local uiSkill = self["PanelSkill" .. index]
    while uiSkill do
        uiSkills[index] = uiSkill
        index = index + 1
        uiSkill = self["PanelSkill" .. index]
    end
    self.UiCharacterPanel = XUiFubenMaverickCharacterPanel.New(self, uiSkills, 
            self.SViewCharacterList, function(memberId)
                self.MemberId = memberId
                self.UiCharacterInfo:Refresh(memberId)
                self.UiCharacterTalent:Refresh(memberId)
            end, true)
end