

---@class XUiBigWorldStoryStageDetail : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XBigWorldQuestControl
local XUiBigWorldStoryStageDetail = XLuaUiManager.Register(XLuaUi, "UiBigWorldStoryStageDetail")

local QuestState = XMVCA.XBigWorldQuest.QuestState
local DlcEventId = XMVCA.XBigWorldService.DlcEventId

function XUiBigWorldStoryStageDetail:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldStoryStageDetail:OnStart(archiveId, closeCb)
    self._ArchiveId = archiveId
    self._CloseCb = closeCb
    self:InitView()
end

function XUiBigWorldStoryStageDetail:OnDestroy()
    if self._CloseCb then
        self._CloseCb()
    end
end

function XUiBigWorldStoryStageDetail:InitUi()
end

function XUiBigWorldStoryStageDetail:InitCb()
    self.BtnClose.CallBack = function()
        self:Close()
    end

    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
    
    self:RegisterClickEvent(self.ImgAutoFighting, self.OnBtnImgAutoClick)
end

function XUiBigWorldStoryStageDetail:InitView()
    local questId = self._Control:GetQuestIdByArchiveId(self._ArchiveId)
    local groupId = self._Control:GetGroupIdByQuestId(questId)
    self.TxtTitle.text = self._Control:GetQuestName(questId)
    self.TxtName.text = self._Control:GetGroupName(groupId)

    local data = XMVCA.XBigWorldQuest:GetQuestData(questId)
    local state = data:GetState()
    local desc = ""
    if state == QuestState.Activated then
        self.BtnEnter.gameObject:SetActiveEx(false)

        local firstStepId = self._Control:GetQuestFirstStepId(questId)
        if firstStepId and firstStepId > 0 then
            self.ImgAutoFighting.gameObject:SetActiveEx(true)
            local location = self._Control:GetStepLocation(firstStepId)
            self.TxtAutoFight.text = XMVCA.XBigWorldService:GetText("QuestGoToText", location)
        else
            self.ImgAutoFighting.gameObject:SetActiveEx(false)
        end
    elseif state == QuestState.Undertaken then
        self.BtnEnter.gameObject:SetActiveEx(true)
        self.BtnEnter:SetDisable(false, true)
        self.ImgAutoFighting.gameObject:SetActiveEx(false)
        local stepList = data:GetActiveStepData()
        if stepList then
            local step = stepList[1]
            desc = self._Control:GetStepText(step:GetId())
        end
    else
        self.BtnEnter.gameObject:SetActiveEx(true)
        self.BtnEnter:SetDisable(true, false)
        self.ImgAutoFighting.gameObject:SetActiveEx(false)
        desc = self._Control:GetQuestDesc(questId)
    end

    self.TxtStoryDes.text = desc
end

function XUiBigWorldStoryStageDetail:OnBtnEnterClick()
    local questId = self._Control:GetQuestIdByArchiveId(self._ArchiveId)
    if not questId or questId <= 0 then
        XLog.Error("QuestId 无效！")
        return
    end
    if XLuaUiManager.IsUiLoad("UiBigWorldTaskMain") then
        XEventManager.DispatchEvent(DlcEventId.EVENT_REFRESH_QUEST_MAIN, 1, questId)
        self:Close()
        XLuaUiManager.Close("UiBigWorldLineChapter")
    else
        self:Close()
        XLuaUiManager.PopThenOpen("UiBigWorldTaskMain", 1, questId)
    end
end

function XUiBigWorldStoryStageDetail:OnBtnImgAutoClick()
    local questId = self._Control:GetQuestIdByArchiveId(self._ArchiveId)
    if not questId or questId <= 0 then
        XLog.Error("QuestId 无效！")
        return
    end
    XMVCA.XBigWorldMap:OpenBigWorldMapUiAnchorQuest(questId)
end