local XUiGridNewsItem = XClass(nil, "XUiGridNewsItem")
function XUiGridNewsItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridNewsItem:Init(uiRoot)
    self.UiRoot = uiRoot
    self:InitFun()
end

--同意
function XUiGridNewsItem:OnBtnAcceptClick()
    if not self.ItemData then return end
    XDataCenter.GuildManager.GuildAckRecruitRequest(self.ItemData.GuildId, true, self.ItemData.PlayerId, function()
        self.UiRoot:OnRefresh()
    end)
end

--拒绝
function XUiGridNewsItem:OnBtnRefuseClick()
    if not self.ItemData then return end
    XDataCenter.GuildManager.GuildAckRecruitRequest(self.ItemData.GuildId, false, self.ItemData.PlayerId, function()
        self.UiRoot:OnRefresh()
    end)
end

--详情
function XUiGridNewsItem:OnBtnSetClick()
    if not self.ItemData then return end
    local guildId = self.ItemData.GuildId
    local guildInfo = XDataCenter.GuildManager.GetVistorGuildDetailsById(guildId)
    if not guildInfo then
        XDataCenter.GuildManager.GetVistorGuildDetailsReq(guildId, function()
            XLuaUiManager.Open("UiGuildRankingList", guildId)
        end)
    else
        XLuaUiManager.Open("UiGuildRankingList", guildId)
    end
end

function XUiGridNewsItem:InitFun()
    self.BtnAccept.CallBack = function() self:OnBtnAcceptClick() end
    self.BtnRefuse.CallBack = function() self:OnBtnRefuseClick() end
    self.BtnSet.CallBack = function() self:OnBtnSetClick() end
end

-- 更新数据
function XUiGridNewsItem:OnRefresh(itemdata)
    if not itemdata then
        return
    end

    self.ItemData = itemdata
    self.TxtPlayerName.text = XDataCenter.SocialManager.GetPlayerRemark(itemdata.PlayerId, itemdata.PlayerName)
    self.TxtEnter.text = itemdata.GuildName
    XUiPLayerHead.InitPortrait(itemdata.HeadPortraitId, itemdata.HeadFrameId, self.Head)
end

return XUiGridNewsItem