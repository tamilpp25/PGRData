local XUiGridUnionEventStageItem = XClass(nil, "XUiGridUnionEventStageItem")
local XUiGridUnionEventHead = require("XUi/XUiFubenUnionKill/XUiGridUnionEventHead")


function XUiGridUnionEventStageItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.Challengers = {}
    -- BgBuff
    self.BtnUnlock.CallBack = function() self:OnBtnUnlockClick() end
    self.BtnStageLock.CallBack = function() self:OnBtnStageLockClick() end
end

function XUiGridUnionEventStageItem:Refresh(eventStageId, sectionTemplate)
    self.GameObject:SetActiveEx(true)
    self.EventStageId = eventStageId
    self.CurSectionTemplate = sectionTemplate
    self.EventStageLimit = self.CurSectionTemplate.EventStageLimit

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(eventStageId)
    self.TxtEventStageName.text = stageCfg.Name
    self.TxtEventStageLock.text = stageCfg.Name

    self.RoomFightData = XDataCenter.FubenUnionKillManager.GetCurRoomData()
    if not self.RoomFightData then return end
    local finishNum = self:GetFinishStageNum(self.RoomFightData.UnionKillStageInfos)
    local isUnlock = self.EventStageLimit > finishNum

    self:RefreshBuffView(isUnlock)
    self:RefreshChallengeView()
end

function XUiGridUnionEventStageItem:RefreshBuffView(isUnlock)
    local stageInfos = self.RoomFightData.UnionKillStageInfos
    local eventStageTemplate = XFubenUnionKillConfigs.GetUnionEventStageById(self.EventStageId)
    local curStageInfo = stageInfos[self.EventStageId]
    -- 解锁条件：打过的关卡没有超过限制数量
    -- 已经打过（不可重复挑战）、还没打过（可以挑战）
    -- 锁住：打过的关卡超过了限制数量
    -- 已经打过（不可挑战）、还没打过（置灰）
    local hasMeFinish = XDataCenter.FubenUnionKillManager.IsMeFinish(curStageInfo)
    local hasOthersFinish = XDataCenter.FubenUnionKillManager.IsOthersFinish(curStageInfo)

    if isUnlock then--没有超过
        self.PanelEventStageNor.gameObject:SetActiveEx(true)
        self.PanelEventStageLock.gameObject:SetActiveEx(false)
    else--超过限制的关卡数量
        self.PanelEventStageNor.gameObject:SetActiveEx(hasMeFinish)
        self.PanelEventStageLock.gameObject:SetActiveEx(not hasMeFinish)
    end
    self.ImgBuffFirstLevel.gameObject:SetActiveEx(hasMeFinish)
    self.ImgBuffSecondLevel.gameObject:SetActiveEx(hasMeFinish and hasOthersFinish)
    -- 图标
    local buffId = eventStageTemplate.EventId[1]
    local buffConfig = XFubenUnionKillConfigs.GetUnionEventConfigById(buffId)
    self.RImgBuff:SetRawImage(buffConfig.Icon)
    self.RImgBuffLcok:SetRawImage(buffConfig.Icon)

    self:UpdateEffect()
end

function XUiGridUnionEventStageItem:UpdateEffect()
    if self.RoomFightData and self.EventStageId and self.EventStageId > 0 then
        local challengeStages = self.RoomFightData.ChallengeStage
        local stageInfos = self.RoomFightData.UnionKillStageInfos
        local curStageInfo = stageInfos[self.EventStageId]
        local hasMeFinish = XDataCenter.FubenUnionKillManager.IsMeFinish(curStageInfo)
        if not hasMeFinish and challengeStages and challengeStages[self.EventStageId] then
            if not XTool.UObjIsNil(self.Effect) then
                self.Effect.gameObject:SetActiveEx(true)
            end
        else
            if not XTool.UObjIsNil(self.Effect) then
                self.Effect.gameObject:SetActiveEx(false)
            end
        end
    end
end

-- 玩家通了多少关卡
function XUiGridUnionEventStageItem:GetFinishStageNum(stageInfos)
    local count = 0
    for _, stageInfo in pairs(stageInfos or {}) do
        for _, playerId in pairs(stageInfo.PlayerIds or {}) do
            if playerId == XPlayer.Id then
                count = count + 1
            end
        end
    end
    return count
end

-- 设置挑战过的玩家
function XUiGridUnionEventStageItem:RefreshChallengeView()
    self.UnionKillStageClear.gameObject:SetActiveEx(false)
    local playerInfos = self.RoomFightData.UnionKillPlayerInfos
    local headInfos = {}
    if playerInfos then
        for id, playerInfo in pairs(playerInfos) do
            for _, eventId in pairs(playerInfo.FinishEventStage or {}) do
                if id == XPlayer.Id and self.EventStageId == eventId then
                    self.UnionKillStageClear.gameObject:SetActiveEx(true)
                end
                if eventId == self.EventStageId then
                    table.insert(headInfos, {
                        PlayerId = id,
                        PlayerLevel = playerInfo.PlayerLevel,
                        PlayerHeadPortraitId = playerInfo.HeadPortraitId,
                        PlayerHeadFrameId = playerInfo.HeadFrameId,
                        Position = playerInfo.Position
                    })
                    break
                end
            end
        end

    end
    table.sort(headInfos, function(head1, head2)
        return head1.Position < head2.Position
    end)
    -- 通关的玩家
    for i = 1, #headInfos do
        if not self.Challengers[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.Head)
            ui.transform:SetParent(self.HeadGroup, false)
            self.Challengers[i] = XUiGridUnionEventHead.New(ui)
        end
        self.Challengers[i]:Refresh(headInfos[i])
    end
    for i = #headInfos + 1, #self.Challengers do
        self.Challengers[i].GameObject:SetActiveEx(false)
    end
end

function XUiGridUnionEventStageItem:OnBtnUnlockClick()
    if not self.EventStageId then return end
    XLuaUiManager.Open("UiUnionKillEnterFight", self.EventStageId, self.CurSectionTemplate, XFubenUnionKillConfigs.UnionKillStageType.EventStage)
end

function XUiGridUnionEventStageItem:OnBtnStageLockClick()
    if not self.RoomFightData then return end
    local finishNum = self:GetFinishStageNum(self.RoomFightData.UnionKillStageInfos)
    local stageInfos = self.RoomFightData.UnionKillStageInfos
    local curStageInfo = stageInfos[self.EventStageId]
    local hasMeFinish = XDataCenter.FubenUnionKillManager.IsMeFinish(curStageInfo)
    if hasMeFinish then
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionHadFightEventStage"))
        return
    end
    -- 我打过，不可以再打
    -- 数量限制，不可打
    if finishNum >= self.EventStageLimit then
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionEventStageOverLimited", self.EventStageLimit))
        return
    end
end

return XUiGridUnionEventStageItem