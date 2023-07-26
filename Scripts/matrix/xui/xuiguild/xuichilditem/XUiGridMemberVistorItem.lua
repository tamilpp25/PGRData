local XUiGridMemberVistorItem = XClass(nil, "XUiGridMemberVistorItem")
function XUiGridMemberVistorItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridMemberVistorItem:Init(uiRoot)
    self.UiRoot = uiRoot
    self.HeadBtn.CallBack = function() self:OnHeadBtn()end
end

function XUiGridMemberVistorItem:OnHeadBtn()
    -- if not self.PlayId then
    --     return
    -- end

    -- 查看个人信息
    -- XDataCenter.PlayerInfoManager.RequestPlayerInfoData(self.PlayId, function(data)
    --         XLuaUiManager.Open("UiPlayerInfo", data, chatContent)
    --         if loadCompleteCB then
    --             loadCompleteCB()
    --         end
    -- end)
end

-- 更新数据
function XUiGridMemberVistorItem:OnRefresh(itemdata)
    if not itemdata then
        return
    end

    self.ItemData = itemdata
    self.PlayId = itemdata.PlayId
    XUiPLayerHead.InitPortrait(itemdata.HeadPortraitId, itemdata.HeadFrameId, self.Head)
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(itemdata.PlayId, itemdata.Name) 
    self.TextLv.text = itemdata.Level
    self.TxtJob.text = XDataCenter.GuildManager.GetRankNameByLevel(itemdata.RankLevel)
    self.TxtContribution.text = itemdata.ContributeAct
    self.TxtHistoryContribution.text = itemdata.ContributeHistory
    self.TxtLastLogin.text = XUiHelper.CalcLatelyLoginTime(itemdata.LastLoginTime)
    self.TxtPopulation.text = itemdata.Popularity
end

return XUiGridMemberVistorItem