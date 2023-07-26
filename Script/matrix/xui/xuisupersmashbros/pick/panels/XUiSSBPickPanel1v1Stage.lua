local XUiSSBPickPanel1v1Stage = XClass(nil, "XUiSSBPickPanel1v1Stage")

function XUiSSBPickPanel1v1Stage:Ctor(uiPrefab, mode, panelRefresh)
    self.Mode = mode
    self.IsLineMode = self.Mode:GetIsLinearStage()
    XTool.InitUiObjectByUi(self, uiPrefab)
    self:InitPanel()
end

function XUiSSBPickPanel1v1Stage:InitPanel()
    self:InitBtns()
    self:InitInfos()
end

function XUiSSBPickPanel1v1Stage:InitBtns()
    --左按钮在非排行榜模式中为成员界面按钮，在排行模式时为通关记录按钮
    --右按钮仅在排行模式时显示，固定为成员界面按钮
    self.BtnLeft.CallBack = function() self:OnClickBtnLeft() end
    self.BtnRight.gameObject:SetActiveEx(self.Mode:GetIsRanking())
    if self.Mode:GetIsRanking() then
        self.BtnLeft:SetName(XUiHelper.GetText("SSBClearTimeBtnName"))
        self.BtnRight.CallBack = function() self:OnClickBtnRight() end
    else
        self.BtnLeft:SetName(XUiHelper.GetText("SSBCharacterBtnName"))
    end
    self.BtnBalance.CallBack = function() self:OnClickBtnBalance() end
    XUiHelper.RegisterClickEvent(self, self.RImgIconRanking, function() self:OnClickIconRanking() end)
end

function XUiSSBPickPanel1v1Stage:InitInfos()
    self.PanelMessageRank.gameObject:SetActiveEx(self.IsLineMode)
    if self.IsLineMode then
        self.TxtWinCount.text = XUiHelper.GetText("SSBReadyWinCount", self.Mode:GetWinCount())

        -- 总是不显示排行，因为排行分职业了，界面无法显示
        self.TxtRankNow.gameObject:SetActive(false)
        if not self.Mode:GetIsRanking() then
            -- cxldV2 不显示排行榜
            self.RImgIconRanking.gameObject:SetActive(false)
            --self.TxtRankNow.gameObject:SetActive(false)
            return
        end

        --XDataCenter.SuperSmashBrosManager.GetMyRankByNet(function(myRank)
        --            self.TxtRankNow.text = XUiHelper.GetText("SSBReadyRankNow", myRank)
        --        end)
    end
end

function XUiSSBPickPanel1v1Stage:OnClickBtnLeft()
    if self.Mode:GetIsRanking() then
        XLuaUiManager.Open("UiSuperSmashBrosClearTime")
    else
        XLuaUiManager.Open("UiSuperSmashBrosCharacter", XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(self.Mode:GetId()).RoleIds, true)
    end
end

function XUiSSBPickPanel1v1Stage:OnClickBtnRight()
    XLuaUiManager.Open("UiSuperSmashBrosCharacter", XDataCenter.SuperSmashBrosManager.GetDefaultTeamInfoByModeId(self.Mode:GetId()).RoleIds, true)
end

function XUiSSBPickPanel1v1Stage:OnClickBtnBalance()
    XLuaUiManager.Open("UiSuperSmashBrosBalanceTips")
end

function XUiSSBPickPanel1v1Stage:OnClickIconRanking()
    XLuaUiManager.Open("UiSuperSmashBrosRanking")
end

return XUiSSBPickPanel1v1Stage