---@class XUiGridStrongholdStage : XUiNode 主界面关卡节点
---@field Parent XUiStrongholdMain
local XUiGridStrongholdStage = XClass(XUiNode, "XUiGridStrongholdStage")

function XUiGridStrongholdStage:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnCard, self.OnClickCard)
    XUiHelper.RegisterClickEvent(self, self.BtnNode, self.OnClickNode)
end

function XUiGridStrongholdStage:Init(chapterId)
    self._ChapterId = chapterId
    self.RImgArea:SetRawImage(XStrongholdConfigs.GetChapterBg(chapterId))
    self.TxtName.text = XStrongholdConfigs.GetChapterName(chapterId)
    self.TxtName2.text = XStrongholdConfigs.GetChapterName(chapterId)
end

function XUiGridStrongholdStage:Update()
    local isUnlock, desc = XDataCenter.StrongholdManager.CheckChapterUnlock(self._ChapterId)
    self._CondDesc = desc
    if not isUnlock then
        -- 未解锁
        self.BtnCard.gameObject:SetActiveEx(false)
        self.BtnNode.gameObject:SetActiveEx(true)
        self.ImgLock.gameObject:SetActiveEx(true)
        self.TxtTips.text = desc
    else
        local showRewards = {}
        local itemIdMap = {}
        local itemGainMap = {}
        self._IsRewardFinish = true
        local rewards = XStrongholdConfigs.GetChapterRewards(XDataCenter.StrongholdManager.GetLevelId(), self._ChapterId)
        for _, reward in pairs(rewards) do
            local isFinish = XDataCenter.StrongholdManager.IsRewardFinished(reward.Id) or false
            self._IsRewardFinish = false
            local rewardList = XRewardManager.GetRewardList(reward.RewardId)
            if XTool.IsNumberValid(reward.IconNumber) then
                for i = 1, reward.IconNumber do
                    local data = rewardList[i]
                    if data then
                        if itemIdMap[data.TemplateId] then
                            if itemGainMap[data.TemplateId] ~= false then
                                itemGainMap[data.TemplateId] = isFinish
                            end
                        else
                            table.insert(showRewards, data)
                            itemIdMap[data.TemplateId] = true
                            itemGainMap[data.TemplateId] = isFinish
                        end
                    end
                end
            end
        end
        -- 有奖励能领取
        self.BtnCard.gameObject:SetActiveEx(true)
        self.BtnNode.gameObject:SetActiveEx(false)
        self.ImgLock.gameObject:SetActiveEx(false)
        local finishCount, totalCount = XDataCenter.StrongholdManager.GetChapterGroupProgress(self._ChapterId)
        self.TxtCurrent.text = XUiHelper.GetText("StrongholdActivityProgress", finishCount, totalCount)
        self.PanelClear.gameObject:SetActiveEx(finishCount >= totalCount)
        XUiHelper.RefreshCustomizedList(self.Grid256New.parent, self.Grid256New, #showRewards, function(i, grid)
            local grid = XUiGridCommon.New(self.Parent, grid)
            grid:Refresh(showRewards[i])
            grid:SetName("")
            grid.PanelTxt.gameObject:SetActiveEx(itemGainMap[showRewards[i].TemplateId])
        end)
    end
end

function XUiGridStrongholdStage:OnClickCard()
    XLuaUiManager.Open("UiStrongholdFightMain", self._ChapterId)
end

function XUiGridStrongholdStage:OnClickNode()
    if self._IsRewardFinish then
        self:OnClickCard()
        return
    end
    XUiManager.TipError(self._CondDesc)
end

return XUiGridStrongholdStage