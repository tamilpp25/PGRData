local XUiPicChatRank = XLuaUiManager.Register(XLuaUi, "UiPicChatRank")
local RankRewardMax = 3
local DialogueMax = 4
local CSTextManagerGetText = CS.XTextManager.GetText
local CSXGameConfig = CS.XGame.Config
function XUiPicChatRank:OnDestroy()

end

function XUiPicChatRank:OnStart()
    self:InitData()
end

function XUiPicChatRank:OnEnable()

end



function XUiPicChatRank:InitData()
    local picCompositionCfg = XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()

    self.CurActivityId = XDataCenter.MarketingActivityManager.GetNowActivityId()
    local picComposition = picCompositionCfg[self.CurActivityId]

    self.LikeItem = self.CurActivityId and picComposition and
    picComposition.PraiseItemId or nil

    self.RankNum = self.CurActivityId and picComposition and
    picComposition.RankNum or nil

    self.RankDataAllList = {}
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, true)

    self.RankDataAllList = XDataCenter.MarketingActivityManager.GetRankCompositionDataList()
    self.PanelNoRank.gameObject:SetActiveEx(#self.RankDataAllList == 0)

    self.TopTxet.text = CSTextManagerGetText("PicCompositionRankTop",self.RankNum)

    self:InitRankReward()
    self:InitPhone()
    self:UpdatePhone()
    self:SetButtonCallBack()
    self:InitDynamicTable()
    self:SetupDynamicTable()

end

function XUiPicChatRank:InitRankReward()
    local RankRewardInfos = XDataCenter.MarketingActivityManager.GetPicCompositionRankRewardInfoList()
    self.RankObj = {
        self.Rank1,
        self.Rank2,
        self.Rank3
        }

    self.IsHaveReward = #RankRewardInfos > 0
    self.PanelRankReward.gameObject:SetActiveEx(self.IsHaveReward)
    self.Phone.gameObject:SetActiveEx(not self.IsHaveReward)

    if self.IsHaveReward then
        self:PlayAnimation("AnimEnable1")
    else
        self:PlayAnimation("AnimEnable2")
    end

    self.RankReward ={}
    for i = 1, RankRewardMax do
        if not RankRewardInfos[i] then
            self.RankObj[i].gameObject:SetActiveEx(false)
            break
        end

        self.RankReward[i] = {}
        self.RankReward[i].RewardPanelList = {}
        self.RankReward[i].Transform = self.RankObj[i].transform
        self.RankReward[i].GameObject = self.RankObj[i].gameObject
        XTool.InitUiObject(self.RankReward[i])

        local minRank = RankRewardInfos[i].MinRank or 0
        local maxRank = RankRewardInfos[i].MaxRank or 0
        self.RankReward[i].Text.text = CSTextManagerGetText("PicCompositionRankReward",minRank,maxRank)

        local rewards = XRewardManager.GetRewardList(RankRewardInfos[i].RewardId)
        for _,reward in pairs(rewards or {}) do
            local panel
            if #self.RankReward[i].RewardPanelList == 0 then
                panel = XUiGridCommon.New(self, self.RankReward[i].GridDrawActivity)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.RankReward[i].GridDrawActivity)
                ui.transform:SetParent(self.RankReward[i].Reward, false)
                panel = XUiGridCommon.New(self, ui)
            end
            table.insert(self.RankReward[i].RewardPanelList, panel)
            panel:Refresh(reward)
        end
    end

    local serverId = CS.XHeroBdcAgent.ServerId
    if serverId == XMarketingActivityConfigs.SeverId.SparkServer then
        self.TxtIos.text = CSTextManagerGetText("PicCompositionServerRankName",CSXGameConfig:GetString("SparkServer"))
    elseif serverId == XMarketingActivityConfigs.SeverId.BeaconServer then
        self.TxtIos.text = CSTextManagerGetText("PicCompositionServerRankName",CSXGameConfig:GetString("BeaconServer"))
    else
        self.TxtIos.text = CSTextManagerGetText("PicCompositionServerRankName",CSXGameConfig:GetString("TestServer"))
    end
end

function XUiPicChatRank:InitPhone()
    self.NormalPhone = {}
    self.NormalDialogueList = {}
    self.NormalPhone.Transform = self.PanelNormalPhone.transform
    self.NormalPhone.GameObject = self.PanelNormalPhone.gameObject
    XTool.InitUiObject(self.NormalPhone)
    self.NormalPhone.BtnPhoneClose.CallBack = function()
        self:OnBtnPhoneCloseClick()
    end
    self.NormalPhone.BtnPhoneClose.gameObject:SetActiveEx(self.IsHaveReward)
    self.NormalPhone.GameObject:SetActiveEx(true)
    self.NormalPhone.DialogueObj = {
        self.NormalPhone.Dialogue1,
        self.NormalPhone.Dialogue2,
        self.NormalPhone.Dialogue3,
        self.NormalPhone.Dialogue4
    }

    for index = 1,DialogueMax do
        self.NormalDialogueList[index] = XUiGridNormalDialogue.New(self.NormalPhone.DialogueObj[index],self)
    end

end

function XUiPicChatRank:UpdatePhone()
    if not self.PlayerRankData then
        local UpLoadTimeType = XDataCenter.MarketingActivityManager.CheckIsCanUpLoad()
        self:SetOtherDialogueStateShow(false)
        if UpLoadTimeType == XMarketingActivityConfigs.TimeType.Before then
            local bTime,eTime = XDataCenter.MarketingActivityManager.GetUpLoadTime(false)
            self.NormalPhone.TipsText.text = CSTextManagerGetText("PicCompositionUpLoadTimeText")
            self.NormalPhone.TimeText.text = string.format("%s--%s",bTime,eTime)
            self.NormalPhone.TimeText.gameObject:SetActiveEx(true)
        else
            self.NormalPhone.TipsText.text = CSTextManagerGetText("NotHaveOtherComposition")
            self.NormalPhone.TimeText.gameObject:SetActiveEx(false)
        end
    else
        local hot = self.PlayerRankData.Hot or 0
        local name = self.PlayerRankData.UserName
        local id = self.PlayerRankData.Id
        local IsLike = XDataCenter.MarketingActivityManager.IsDoPicCompositionLike(id)
        local dialogueDataList = self.PlayerRankData.Dialogue
        local btnStatus = IsLike and CS.UiButtonState.Select or CS.UiButtonState.Normal
        self.NormalPhone.OtherHotNum.text = XMarketingActivityConfigs.GetCountUnitChange(hot)
        self.NormalPhone.PlayerName.text = CSTextManagerGetText("PicCompositionPlayerName",name)
        self.NormalPhone.Tips.gameObject:SetActiveEx(false)
        for index = 1,DialogueMax do
            self.NormalDialogueList[index]:Update(dialogueDataList[index])
        end

        self:SetOtherDialogueStateShow(true)
        self.NormalPhone.BtnLike:SetButtonState(btnStatus)
    end

    local item = XDataCenter.ItemManager.GetItem(self.LikeItem)
    if item then
        self.AssetActivityPanel:Refresh({self.LikeItem})
    else
        self.AssetActivityPanel:Refresh(nil)
    end
end

function XUiPicChatRank:SetOtherDialogueStateShow(IsShow)
    self.NormalPhone.Tips.gameObject:SetActiveEx(not IsShow)
    self.NormalPhone.PanelChatView.gameObject:SetActiveEx(IsShow)
    self.NormalPhone.PanelOther.gameObject:SetActiveEx(IsShow)
end

function XUiPicChatRank:SetButtonCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end

    self.NormalPhone.BtnLike.CallBack = function()
        self:OnBtnLikeClick()
    end
end

function XUiPicChatRank:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ChatRankList)
    self.DynamicTable:SetProxy(XUiGridRank)
    self.DynamicTable:SetDelegate(self)
end

function XUiPicChatRank:SetupDynamicTable()
    self.PageDatas = self.RankDataAllList
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiPicChatRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:UpdateGrid(self.PageDatas[index],index,self,true)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index],index,self,false)
    -- elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end

function XUiPicChatRank:OnBtnBackClick()
    self:Close()
end

function XUiPicChatRank:OnBtnPhoneCloseClick()
    self.PanelRankReward.gameObject:SetActiveEx(true)
    self.Phone.gameObject:SetActiveEx(false)
    self:PlayAnimation("RankRewardQieHuan")
end

function XUiPicChatRank:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPicChatRank:OnBtnLikeClick()
    local id = self.PlayerRankData.Id
    if XDataCenter.MarketingActivityManager.IsDoPicCompositionLike(id) then
        XUiManager.TipText("PicCompositionLikeHint")
        return
    end

    if self.PlayerRankData.UserId == XPlayer.Id then
        XUiManager.TipText("PicCompositionLikeSelf")
        return
    end

    local itemCount = XDataCenter.ItemManager.GetCount(self.LikeItem)
    if not XDataCenter.MarketingActivityManager.CheckItemEnough(itemCount) then
        XUiManager.TipText("PicCompositionNotEnough")
        return
    end

    XDataCenter.MarketingActivityManager.GivePraise(id, function ()
            self.PlayerRankData.Hot =
            self.PlayerRankData.Hot + 1
            self:UpdatePhone()
        end)
end

function XUiPicChatRank:ErrorExit()
    XUiManager.TipText("PicCompositionNetError")
    XLuaUiManager.RunMain()
end