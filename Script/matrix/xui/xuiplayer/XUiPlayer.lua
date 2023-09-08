local XUiPlayer = {}--XLuaUiManager.Register(XLuaUi, "UiPlayer")
local None = -1
function XUiPlayer:OnStart(closeCb, selectIdx, achiveIdx,medalViewType)
    self.TagPage = {
        PlayerInfo = 1,
        Achievement = 2,
        Setting = 3,
        Collect = 4,
    }
    self.SelectIdx = selectIdx
    self.MedalViewType = medalViewType
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnAchievement:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.PlayerAchievement))
    self.TagBtns = { self.BtnPlayerInfo, self.BtnAchievement, self.BtnSetting, self.BtnCollect }
    self.TabBtnGroup:Init(self.TagBtns, function(index) self:OnTabBtnGroup(index) end)
    self.closeCb = closeCb
    self.AchiveIdx = achiveIdx

    self.TabBtnGroup:SelectIndex(self.SelectIdx or self.TagPage.PlayerInfo)
    self:AddRedPointEvent(self.ImgSetNameTag, self.OnCheckSetName, self, { XRedPointConditions.Types.CONDITION_PLAYER_SETNAME, XRedPointConditions.Types.CONDITION_HEADPORTRAIT_RED })
    self:AddRedPointEvent(self.BtnAchievement, self.OnCheckAcchiveRedPoint, self, { XRedPointConditions.Types.CONDITION_PLAYER_ACHIEVE })
    self:AddRedPointEvent(self.BtnCollect, self.OnCheckMedalRedPoint, self, { XRedPointConditions.Types.CONDITION_MEDAL_RED })
    -- 功能屏蔽
    self.BtnAchievement.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.PlayerAchievement))
end

function XUiPlayer:OnEnable()
    -- 跳转到设置界面
    XEventManager.AddEventListener(XEventId.EVENT_PLAYER_SETTING, self.SelectSetting, self)
end

function XUiPlayer:OnCheckSetName(count)
    self.ImgSetNameTag.gameObject:SetActive(count >= 0)
end

function XUiPlayer:OnCheckAcchiveRedPoint(count)
    self.BtnAchievement:ShowReddot(count >= 0)
end

function XUiPlayer:OnCheckMedalRedPoint(count)
    self.BtnCollect:ShowReddot(count >= 0)
end

function XUiPlayer:OnTabBtnGroup(index)
    if self.NeedSave then
        self:CheckSave(function() self:OnTabBtnGroup(index) end)
        return
    end

    -- 记录玩家信息界面的动画状态，避免切换界面后卡在动画中间
    if XLuaUiManager.IsUiShow("UiPanelPlayerInfo") then
        self:FindChildUiObj("UiPanelPlayerInfo"):RecordAnimation()
    end

    if index == self.TagPage.PlayerInfo then
        self:ShowPanelPlayer()
    elseif index == self.TagPage.Achievement then
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PlayerAchievement) then
            self:ShowPanelAchv()
        end
    elseif index == self.TagPage.Setting then
        self:ShowSetting()
    elseif index == self.TagPage.Collect then
        self:ShowCollect()
    end
    self:PlayAnimation("QieHuan")
end

function XUiPlayer:OnBtnMainUiClick()
    if self.NeedSave then
        self:CheckSave(function() self:OnBtnMainUiClick() end)
        return
    end
    XLuaUiManager.RunMain()
end

function XUiPlayer:Close()
    if self.NeedSave then
        self:CheckSave(function() self:Close() end)
        return
    end

    self.Super.Close(self)

    if self.closeCb then
        self.closeCb()
    end
end

function XUiPlayer:ShowPanelPlayer()
    self:OpenOneChildUi("UiPanelPlayerInfo")
end

function XUiPlayer:ShowPanelAchv()
    self:OpenOneChildUi("UiPanelAchieve", self, self.AchiveIdx)
    self.AchiveIdx = nil
end

function XUiPlayer:ShowSetting()
    self:OpenOneChildUi("UiPanelSetting", self)
    self.UiPanelSetting:InitCollectionWallShow()
    self.UiPanelSetting:UpdateCharacterHead()
end

function XUiPlayer:ShowCollect()
    local viewType = None
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Collection) then
        viewType = XMedalConfigs.ViewType.Collection
    end
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Medal) then
        viewType = XMedalConfigs.ViewType.Medal
    end
    self:OpenOneChildUi("UiPanelMedal",self.MedalViewType or viewType)
end

function XUiPlayer:CheckSave(cb)
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

function XUiPlayer:SelectSetting()
    self.TabBtnGroup:SelectIndex(self.TagPage.Setting)
end

function XUiPlayer:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLAYER_SETTING, self.SelectSetting, self)
end