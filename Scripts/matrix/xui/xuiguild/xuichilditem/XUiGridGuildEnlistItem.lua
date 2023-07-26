local XUiGridGuildEnlistItem = XClass(nil, "XUiGridGuildEnlistItem")

function XUiGridGuildEnlistItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    if self.BtnRecruit then
        self.BtnRecruit.CallBack = function() self:OnBtnRecruitClick() end
    end

    if self.BtnAccept then
        self.BtnAccept.CallBack = function() self:OnBtnAcceptClick() end
    end

    if self.BtnRefuse then
        self.BtnRefuse.CallBack = function() self:OnBtnRefuseClick() end
    end

    if self.BtnHead then
        self.BtnHead.CallBack = function() self:OnBtnHeadClick() end
    end
end

function XUiGridGuildEnlistItem:Init(uiParent, uiRoot)
    self.UiParent = uiParent
    self.UiRoot = uiRoot
end

-- PlayerId,
-- PlayerName
-- Level
-- HeadPortraitId
-- GuildCoin
-- LastLoginTime
function XUiGridGuildEnlistItem:SetItemData(itemData)
    self.ItemData = itemData
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(itemData.PlayerId, itemData.PlayerName)
    if itemData.OnlineFlag == 1 then
        self.TxtOnline.text = CS.XTextManager.GetText("GuildMemberOnline")
    else
        self.TxtOnline.text = XUiHelper.CalcLatelyLoginTime(itemData.LastLoginTime)
    end

    XUiPlayerLevel.UpdateLevel(itemData.Level, self.TxtLv, CS.XTextManager.GetText("GuildMemberLevel", itemData.Level))

    self.TxtNum.text = itemData.GuildCoin
    self.RImgContribute:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XGuildConfig.GuildCoin))
    XUiPLayerHead.InitPortrait(itemData.HeadPortraitId, itemData.HeadFrameId, self.Head)
end

function XUiGridGuildEnlistItem:OnBtnRecruitClick()
    if self.ItemData then
        if not XDataCenter.GuildManager.IsGuildAdminister() then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
            self.UiRoot:Close()
            return
        end
        XDataCenter.GuildManager.GuildRecruit(self.ItemData.PlayerId, function()
            self.UiParent:RefreshEnlists()
        end)
    end
end

function XUiGridGuildEnlistItem:OnBtnAcceptClick()
    if self.ItemData and self.UiRoot and self.UiParent then
        if not XDataCenter.GuildManager.IsGuildAdminister() then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
            self.UiRoot:Close()
            return
        end
        XDataCenter.GuildManager.AcceptGuildRequest(self.ItemData.PlayerId, self.ItemData.PlayerName, function()
            self.UiParent:RefreshEnlists()
        end)
    end
end

function XUiGridGuildEnlistItem:OnBtnRefuseClick()
    if self.ItemData and self.UiRoot and self.UiParent then
        if not XDataCenter.GuildManager.IsGuildAdminister() then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
            self.UiRoot:Close()
            return
        end
        XDataCenter.GuildManager.RefuseGuildRequest(self.ItemData.PlayerId, function()
            self.UiParent:RefreshEnlists()
        end)
    end
end

function XUiGridGuildEnlistItem:OnBtnHeadClick()
    if not self.ItemData then return end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.ItemData.PlayerId)
end
return XUiGridGuildEnlistItem