local XUiNierCharacter = XLuaUiManager.Register(XLuaUi, "UiNierCharacter")
local UiPanelFoster = require("XUi/XUiNieR/XUiCharacter/XUiPanelNierCharacterFoster")
local UiPanelStory = require("XUi/XUiNieR/XUiCharacter/XUiPanelNierCharacterStory")
local UiPanelTeaching = require("XUi/XUiNieR/XUiCharacter/XUiPanelNierCharacterTeaching")

local PANEL_INDEX = {
    Foster = 1,
    Story = 2,
    Teaching = 3,
}
function XUiNierCharacter:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "NierCharacterHelp")
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.TabList = {
        self.BtnTabPeiyang,
        self.BtnTabDangan,
        self.BtnTabJiaoxue
    }
    self.PanelCharacterTypeBtns:Init(self.TabList, function(index) self:OnBtnTabPanelSelect(index) end)

    self.UiPanelFoster = UiPanelFoster.New(self.PanelFoster , self)
    self.UiPanelStory = UiPanelStory.New(self.PanelStory , self)
    self.UiPanelTeaching = UiPanelTeaching.New(self.PanelMainlineTeaching , self)
end

function XUiNierCharacter:OnReleaseInst()
    return self.CurToggleType
end

function XUiNierCharacter:OnResume(CurToggleType)
    self.CurToggleType = CurToggleType
end

function XUiNierCharacter:OnStart()
    self.CurToggleType = self.CurToggleType and self.CurToggleType or PANEL_INDEX.Foster
    self.Character = XDataCenter.NieRManager.GetSelNieRCharacter()
    self.NieRCharacterId = self.Character:GetNieRCharacterId()
    self.RoleName.text = self.Character:GetNieRCharName()

    self.ImgRole:SetRawImage(self.Character:GetNieRCharacterIcon())

    self:AddRedPointEvent()
end

function XUiNierCharacter:OnEnable()
    
    
    if XDataCenter.NieRManager.GetIsActivityEnd() then
        XScheduleManager.ScheduleOnce(function()
            XDataCenter.NieRManager.OnActivityEnd()
        end, 1)
    else
        self.PanelCharacterTypeBtns:SelectIndex(self.CurToggleType)
    end
end

function XUiNierCharacter:OnDisable()
end

function XUiNierCharacter:OnDestroy()
end

--添加点事件
function XUiNierCharacter:AddRedPointEvent()
    XRedPointManager.AddRedPointEvent(self.BtnTabDangan, self.RefreshDanganRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_CHARACTER_RED }, {CharacterId = self.NieRCharacterId, IsInfor = true, IsTeach = false}  )
    XRedPointManager.AddRedPointEvent(self.RedJiaoxue, self.RefreshTeachRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_CHARACTER_RED }, {CharacterId = self.NieRCharacterId, IsInfor = false, IsTeach = true} )
    self.RedPeiyang.gameObject:SetActive(false)
    --self.RedJiaoxue.gameObject:SetActive(false)
end

--任务按钮红点
function XUiNierCharacter:RefreshDanganRedDot(count)
    self.RedDangan.gameObject:SetActive(count >= 0)
end

--任务按钮红点
function XUiNierCharacter:RefreshTeachRedDot(count)
    self.RedJiaoxue.gameObject:SetActive(count >= 0)
end

function XUiNierCharacter:OnBtnBackClick()
    self:Close()
end

function XUiNierCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiNierCharacter:OnGetEvents()
    return { XEventId.EVENT_FUBEN_ENTERFIGHT }
end

--事件监听
function XUiNierCharacter:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_FUBEN_ENTERFIGHT then
        self:EnterFight(args[1])
    end
end

function XUiNierCharacter:EnterFight(stage)
    if XDataCenter.FubenManager.OpenRoomSingle(stage) then
        XLuaUiManager.Remove("UiFubenStageDetail")
    end
end

function XUiNierCharacter:OnBtnTabPanelSelect(index)
    if index == PANEL_INDEX.Foster then
        self.UiPanelStory:HidePanel()
        self.UiPanelTeaching:HidePanel()
        self.UiPanelFoster:ShowPanel()

        self.UiPanelFoster:InitAllData()
        self.CurToggleType = PANEL_INDEX.Foster
    elseif index == PANEL_INDEX.Story then
        self.UiPanelFoster:HidePanel()
        self.UiPanelTeaching:HidePanel()
        self.UiPanelStory:ShowPanel()
        
        self.UiPanelStory:InitAllInfo()
        self.CurToggleType = PANEL_INDEX.Story
    elseif index == PANEL_INDEX.Teaching then
        self.UiPanelFoster:HidePanel()
        self.UiPanelStory:HidePanel()
        self.UiPanelTeaching:ShowPanel()

        self.UiPanelTeaching:InitAllInfo()
        self.CurToggleType = PANEL_INDEX.Teaching
    end
end