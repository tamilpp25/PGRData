local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiSummerOnlineSection = XLuaUiManager.Register(XLuaUi, "UiSummerOnlineSection")

function XUiSummerOnlineSection:OnAwake()
    self.TxtDesc = {}
    self.GridList = {}
    self.GridCommon.gameObject:SetActiveEx(false)
    for i = 1, 3, 1 do
        self.TxtDesc[i] = self["Txt" .. i]
    end

    self.BtnMatch.CallBack = function() self:OnBtnMatchClick() end
    self.BtnCreateRoom.CallBack = function() self:OnBtnCreateRoomClick() end
end

function XUiSummerOnlineSection:OnStart(rootUi, stage)
    self.RootUi = rootUi
    self.Stage = stage
    self.StageId = stage.StageId

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint)
end

function XUiSummerOnlineSection:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.EnterRoom, self)

    self.Stage = self.RootUi.Stage
    self.StageId = self.Stage.StageId
    self.Chapter = self.RootUi.CurChapter

    self:Refresh()
end

function XUiSummerOnlineSection:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.EnterRoom, self)
end

function XUiSummerOnlineSection:EnterRoom()
    self:ResetState()
end

--刷新联机详情面板
function XUiSummerOnlineSection:Refresh()
    if not self.StageId then return end

    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local leastPlayer = self.StageCfg.OnlinePlayerLeast <= 0 and 1 or self.StageCfg.OnlinePlayerLeast
    local orderId = self.StageCfg.OrderId
    for i, v in ipairs(self.Chapter.StageIds) do
        if v == self.StageId then
            orderId = i
            break
        end
    end
    self.TxtTitle.text = self.Chapter.PrefixName .. "-" .. tostring(orderId) .. self.Stage.Name
    self.TxtPeople.text = leastPlayer
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    --  local atNums = stageInfo.Passed and 0 or
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(self.StageId)
    self.PanelMatching.gameObject:SetActiveEx(false)

    for i = 1, #self.TxtDesc do
        local txtDesc = self.TxtDesc[i]
        local desc = self.StageCfg.StarDesc[i]
        if desc then
            txtDesc.text = desc
            txtDesc.gameObject:SetActiveEx(true)
        else
            txtDesc.gameObject:SetActiveEx(false)
        end
    end

    local isMatching = XDataCenter.RoomManager.Matching
    self.BtnMatch.gameObject:SetActive(not isMatching)
    self.PanelMatching.gameObject:SetActive(isMatching)
    self.BtnCreateRoom.interactable = not isMatching

    self:SetDropList()
end

--创建房间
function XUiSummerOnlineSection:OnBtnCreateRoomClick()
    if XDataCenter.RoomManager.Matching then
        XUiManager.TipMsg(CS.XTextManager.GetText("OnlineInstanceMatching"))
        return
    end


    if XDataCenter.FubenSpecialTrainManager.CheckActivityTimeout(XDataCenter.FubenSpecialTrainManager.CurActiveId, true) then
        return
    end

    XDataCenter.FubenManager.RequestCreateRoom(self.StageCfg)
end


--匹配
function XUiSummerOnlineSection:OnBtnMatchClick()
    if XDataCenter.FubenSpecialTrainManager.CheckActivityTimeout(XDataCenter.FubenSpecialTrainManager.CurActiveId, true) then
        return
    end

    if XDataCenter.RoomManager.Matching then
        return
    end

    XDataCenter.FubenManager.RequestMatchRoom(self.StageCfg, function()
        --匹配房间
        if XDataCenter.RoomManager.Matching then
            XLuaUiManager.Open("UiOnLineMatching", self.StageCfg)
        end

        self.BtnCreateRoom.interactable = false
        self.BtnMatch.gameObject:SetActiveEx(false)
        self.PanelMatching.gameObject:SetActiveEx(true)
    end)
end

--取消匹配
function XUiSummerOnlineSection:OnCancelMatch()
    self.BtnCreateRoom.interactable = true
    self.BtnMatch.gameObject:SetActiveEx(true)
    self.PanelMatching.gameObject:SetActiveEx(false)
end

--重置
function XUiSummerOnlineSection:ResetState()
    self.BtnMatch.gameObject:SetActive(true)
    self.PanelMatching.gameObject:SetActive(false)
    self.BtnCreateRoom.interactable = true
end

-- 获取显示奖励
function XUiSummerOnlineSection:SetDropList()
    local IsFirst = false
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    -- 获取显示奖励Id
    local rewardId = 0
    local cfg = XDataCenter.FubenManager.GetStageLevelControl(self.StageId)
    if not stageInfo.Passed then
        rewardId = cfg and cfg.FirstRewardShow or self.StageCfg.FirstRewardShow
        if cfg and cfg.FirstRewardShow > 0 or self.StageCfg.FirstRewardShow > 0 then
            IsFirst = true
        end
    end


    self.TxtDrop.gameObject:SetActiveEx(not IsFirst)
    self.TxtFirstDrop.gameObject:SetActiveEx(IsFirst)

    if rewardId == 0 then
        rewardId = cfg and cfg.FinishRewardShow or self.StageCfg.FinishRewardShow
    end

    if rewardId == 0 then
        for j = 1, #self.GridList do
            self.GridList[j].GameObject:SetActiveEx(false)
        end
        return
    end

    local rewards = IsFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.PanelDropContent, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActiveEx(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.GridList do
        if j > rewardsCount then
            self.GridList[j].GameObject:SetActiveEx(false)
        end
    end
end