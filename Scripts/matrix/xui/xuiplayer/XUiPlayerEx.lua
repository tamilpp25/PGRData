--============
--新玩家信息界面
--============
local XUiPlayerEx = XLuaUiManager.Register(XLuaUi, "UiPlayer")

function XUiPlayerEx:OnStart()
    self:PlayAnimation("PanelAnimEnable")
    --self:PlayAnimation("PanelPlayerGloryExpEnable")
    self:InitTopButtons()
    self:InitPanelPlayerInfo()
end

function XUiPlayerEx:InitTopButtons()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        self:OnClickBtnMainUi()
    end
    self.BtnAchievement.CallBack = function()
        self:OnClickBtnAchievement()
    end
    self.BtnArchive.CallBack = function()
        self:OnClickBtnArchive()
    end
    self.BtnExhibition.CallBack = function()
        self:OnClickBtnExhibition()
    end
end

function XUiPlayerEx:Close()
    if self.IsOpenSetting then
        if self.NeedSave then
            self:CheckSave(function()
                self:Close()
            end)
            return
        end
        self:CloseChildUi("UiPanelSetting")
        self.IsOpenSetting = false
        self.PanelPlayerInfoEx:OnEnable()
        self.PanelPlayerInfoEx.GameObject:SetActiveEx(true)
    else
        self.Super.Close(self)
    end
end

function XUiPlayerEx:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiPlayerEx:InitPanelPlayerInfo()
    local XUiPanelPlayerInfoEx = require("XUi/XUiPlayer/XUiPanelPlayerInfoEx")
    self.PanelPlayerInfoEx = XUiPanelPlayerInfoEx.New(self.UiPanelPlayerInfo, self)
    
    ---@type XUiBtnDownload
    self.GirdBtnDownload = require("XUi/XUiDlcDownload/XUiBtnDownload").New(self.BtnDownload)
    self.GirdBtnDownload:Init(XDlcConfig.EntryType.Archive, 0)
end

function XUiPlayerEx:OnEnable()
    self.PanelPlayerInfoEx:OnEnable()
    self.GirdBtnDownload:RefreshView()
    self.BtnAchievement:ShowReddot(XDataCenter.MedalManager.CheckHaveNewMedal() or XDataCenter.AchievementManager.CheckHasReward())
    self.BtnExhibition:ShowReddot(XDataCenter.ExhibitionManager.CheckNewCharacterReward())
end

function XUiPlayerEx:OnDisable()
    self.PanelPlayerInfoEx:OnDisable()
end

function XUiPlayerEx:OnDestroy()
    self.PanelPlayerInfoEx:OnDestroy()
end

function XUiPlayerEx:OnClickBtnAchievement()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PlayerAchievement) then
        self.PanelPlayerInfoEx:RecordAnimation()
        XLuaUiManager.Open("UiAchievementSystem")
    end
end

function XUiPlayerEx:OnClickBtnArchive()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Archive) then
        self.PanelPlayerInfoEx:RecordAnimation()
        XLuaUiManager.Open("UiArchiveMain")
    end
end

function XUiPlayerEx:OnClickBtnExhibition()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterExhibition) then
        if self.GirdBtnDownload:CheckNeedDownload() then
            self.GirdBtnDownload:OnBtnClick()
            return
        end
        self.PanelPlayerInfoEx:RecordAnimation()
        XLuaUiManager.Open("UiExhibition", true)
    end
end

function XUiPlayerEx:ShowSetting()
    self.PanelPlayerInfoEx:OnDisable()
    self.PanelPlayerInfoEx.GameObject:SetActiveEx(false)
    self:OpenOneChildUi("UiPanelSetting", self)
    self.UiPanelSetting:InitCollectionWallShow()
    self.UiPanelSetting:UpdateCharacterHead()
    self.IsOpenSetting = true
end

function XUiPlayerEx:CheckSave(cb)
    self.NeedSave = false
    XUiManager.DialogTip(
            CS.XTextManager.GetText("TipTitle"),
            CS.XTextManager.GetText("SaveShowSetting"),
            XUiManager.DialogType.Normal,
            function()
                self.UiPanelSetting.CharacterList = XPlayer.ShowCharacters
                self.UiPanelSetting:InitAppearanceSetting()
                if cb then
                    cb()
                end
            end,
            function()
                self.UiPanelSetting:OnBtnSave()
                if cb then
                    cb()
                end
            end)
end