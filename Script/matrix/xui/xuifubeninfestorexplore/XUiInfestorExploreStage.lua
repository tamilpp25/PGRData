local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridFubenInfestorExploreMember = require("XUi/XUiFubenInfestorExplore/XUiGridFubenInfestorExploreMember")
local XUiPanelFubenInfestorExploreStages = require("XUi/XUiFubenInfestorExplore/XUiPanelFubenInfestorExploreStages")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local MAX_MEMBER_NUM = 3

local XUiInfestorExploreStage = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreStage")

function XUiInfestorExploreStage:OnAwake()
    self:AutoAddListener()
    self.GridCharacter.gameObject:SetActiveEx(false)
    self.PanelFullFinish.gameObject:SetActiveEx(false)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiInfestorExploreStage:OnStart(chapterId)
    self.ChapterId = chapterId
    self.MemberGrids = {}
    self:InitView()
    self:InitStagesMap()
end

function XUiInfestorExploreStage:OnEnable()
    self:RefreshView()

    self:InitCacheMoneyCount()

    local newChapterAnimFunc = function()
        if XDataCenter.FubenInfestorExploreManager.CheckNewChapterNeedShowAnim() then
            self:PlayChapterFinishedAnimation()
            XDataCenter.FubenInfestorExploreManager.ClearNewChapterNeedShowAnim()
        end
    end

    if XDataCenter.FubenInfestorExploreManager.IsFightRewadsExist() then
        XLuaUiManager.Open("UiInfestorExploreChoose", newChapterAnimFunc)
    else
        newChapterAnimFunc()
    end
end

function XUiInfestorExploreStage:OnDestroy()
    XDataCenter.FubenInfestorExploreManager.SetOpenInfestorExploreCoreDelay(0)
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.FubenInfestorExplore)
end

function XUiInfestorExploreStage:OnGetEvents()
    return { XEventId.EVENT_INFESTOREXPLORE_MOVE_TO_NEXT_NODE
    , XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.InfestorActionPoint
    , XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.InfestorMoney
    , XEventId.EVENT_INFESTOREXPLORE_CHARACTER_HP_CHANGE
    , XEventId.EVENT_INFESTOREXPLORE_RESET
    }
end

function XUiInfestorExploreStage:OnNotify(evt, ...)
    if evt == XEventId.EVENT_INFESTOREXPLORE_MOVE_TO_NEXT_NODE then
        self:UpdateStagesMap()
    elseif evt == XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.InfestorActionPoint then
        self:UpdateActionPoint()
    elseif evt == XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.InfestorMoney then
        self:UpdateMoney()
    elseif evt == XEventId.EVENT_INFESTOREXPLORE_CHARACTER_HP_CHANGE then
        self:UpdateCharacters()
    elseif evt == XEventId.EVENT_INFESTOREXPLORE_RESET then
        XDataCenter.FubenInfestorExploreManager.Reset()
    end
end

function XUiInfestorExploreStage:InitView()
    local chapterId = self.ChapterId

    self.TxtTitle.text = XFubenInfestorExploreConfigs.GetChapterName(chapterId)

    local icon = XDataCenter.FubenInfestorExploreManager.GetMoneyIcon()
    self.RImgCost:SetRawImage(icon)

    local isHard = XDataCenter.FubenInfestorExploreManager.IsChapterRequireIsomer(chapterId)
    self.ImgHard.gameObject:SetActiveEx(isHard)
    self.ImgEasy.gameObject:SetActiveEx(not isHard)

    local actionPoint = XDataCenter.FubenInfestorExploreManager.GetActionPoint()
    self.TxtActionPoint.text = CSXTextManagerGetText("InfestorExploreActionPointDes", actionPoint)

    local isPassed = XDataCenter.FubenInfestorExploreManager.IsChapterPassed(chapterId)
    self.PanelCharacterGroup.gameObject:SetActiveEx(not isPassed)

    XCountDown.BindTimer(self, XCountDown.GTimerName.FubenInfestorExplore, function(time)
        time = time > 0 and time or 0
        local timeText = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHALLENGE)
        self.TxtTime.text = CSXTextManagerGetText("InfestorExploreLeftTime", timeText)
    end)

    self.TxtEffectPosition.text = XDataCenter.FubenInfestorExploreManager.GetBuffDes()
end

function XUiInfestorExploreStage:InitStagesMap()
    local chapterId = self.ChapterId
    local parentPrefabPath = XFubenInfestorExploreConfigs.GetChapterPrefabPath(chapterId)
    local parentPrefab = self.PanelStages:LoadPrefab(parentPrefabPath)
    local clickStageCb = function(chapterId, paramNodeId, paramGrid)
        if XDataCenter.FubenInfestorExploreManager.IsNodeCurrentShop(chapterId, paramNodeId) then
            --商店节点类型特殊判断
            if XDataCenter.FubenInfestorExploreManager.IsNodeCurrentFinished(chapterId, paramNodeId) then
                XUiManager.TipText("InfestorExploreShopNodeCurrentFinshed")
            else
                if XDataCenter.FubenInfestorExploreManager.CheckShopExist() then
                    XLuaUiManager.Open("UiInfestorExploreShop")
                else
                    local callBack = function()
                        XLuaUiManager.Open("UiInfestorExploreShop")
                    end
                    XDataCenter.FubenInfestorExploreManager.RequestShopInfo(paramNodeId, callBack)
                end
            end
        else
            local nodeUiName = XDataCenter.FubenInfestorExploreManager.GetNodeTypeDetailUiName(chapterId, paramNodeId)
            if nodeUiName then
                self:OnOpenStageDetail()
                local grid = paramGrid  --magical upvalue!
                local closeCb = function()
                    self:OnCloseStageDetail()
                    grid:SetSelect(false)
                    self.PanelStagesParent.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic

                    if XDataCenter.FubenInfestorExploreManager.CheckNewChapterNeedShowAnim() then
                        self:PlayChapterFinishedAnimation()
                        XDataCenter.FubenInfestorExploreManager.ClearNewChapterNeedShowAnim()
                    end
                end
                self:OpenChildUi(nodeUiName, closeCb)
                self:FindChildUiObj(nodeUiName):Refresh(chapterId, paramNodeId)
            end
        end
    end
    self.PanelStagesParent = XUiPanelFubenInfestorExploreStages.New(parentPrefab, self, chapterId, clickStageCb)
end

function XUiInfestorExploreStage:RefreshView()
    self:UpdateActionPoint()
    self:UpdateMoney()
    self:UpdateCharacters()
    self:UpdateStagesMap()
end

function XUiInfestorExploreStage:UpdateActionPoint()
    local actionPoint = XDataCenter.FubenInfestorExploreManager.GetActionPoint()
    self.TxtActionPoint.text = CSXTextManagerGetText("InfestorExploreCurActionPoint", actionPoint)
end

function XUiInfestorExploreStage:UpdateMoney()
    local count = XDataCenter.FubenInfestorExploreManager.GetMoneyCount()
    self:RefreshCacheMoneyCount(count)
    self.TxtCost.text = "x" .. count
end

function XUiInfestorExploreStage:InitCacheMoneyCount()
    local count = XDataCenter.FubenInfestorExploreManager.GetMoneyCount()
    XDataCenter.FubenInfestorExploreManager.RefreshCacheMoneyCount(count, count)
end

function XUiInfestorExploreStage:RefreshCacheMoneyCount(newMoneyCount)
    XDataCenter.FubenInfestorExploreManager.RefreshCacheMoneyCount(newMoneyCount)
end

function XUiInfestorExploreStage:UpdateCharacters()
    local chapterId = self.ChapterId
    local characterIds = XDataCenter.FubenInfestorExploreManager.GetChapterTeamCharacterIds(chapterId)
    local captainPos = XDataCenter.FubenInfestorExploreManager.GetChapterTeamCaptainPos(chapterId)
    for pos = 1, MAX_MEMBER_NUM do
        local characterId = characterIds[pos]
        local isCaptain = pos == captainPos
        local grid = self.MemberGrids[pos]
        if characterId > 0 then
            if not grid then
                local go = CSUnityEngineObjectInstantiate(self.GridCharacter, self.PanelCharacterContent)
                local clickCb = function()
                    XUiManager.TipText("InfestorExploreCharacterReplaceTip")
                end
                grid = XUiGridFubenInfestorExploreMember.New(go, clickCb)
                self.MemberGrids[pos] = grid
            end
            grid:Refresh(characterId, isCaptain)
            grid.GameObject:SetActiveEx(true)
        else
            if grid then
                grid.GameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiInfestorExploreStage:UpdateStagesMap()
    self.PanelStagesParent:UpdateStagesMap()
end

function XUiInfestorExploreStage:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self:BindHelpBtn(self.BtnHelp, "InfestorExplore")
    self.BtnNegativeEffects.CallBack = function() self:OnClickBtnNegativeEffects() end
    self.BtnTacticalCore.CallBack = function() self:OnClickBtnTacticalCore() end
    self.BtnContract.CallBack = function() self:OnClickBtnContract() end
    self.BtnMessage.CallBack = function() self:OnClickBtnGuestbook() end
    self.BtnRImgCost.CallBack = function() self:OnClickRImgCostBack() end
end

function XUiInfestorExploreStage:OnBtnBackClick()
    self:Close()
end

function XUiInfestorExploreStage:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiInfestorExploreStage:OnClickBtnNegativeEffects()
    XLuaUiManager.Open("UiInfestorExploreDebuff")
end

function XUiInfestorExploreStage:OnClickBtnTacticalCore()
    XLuaUiManager.Open("UiInfestorExploreCore")
end

function XUiInfestorExploreStage:OnClickBtnContract()
    XLuaUiManager.Open("UiInfestorExploreContract")
end

function XUiInfestorExploreStage:OnOpenStageDetail()
    self.LeftGroup.gameObject:SetActiveEx(false)
    self.BtnNegativeEffects.gameObject:SetActiveEx(false)
    self.BtnTacticalCore.gameObject:SetActiveEx(false)
    self.BtnMessage.gameObject:SetActiveEx(false)
end

function XUiInfestorExploreStage:OnCloseStageDetail()
    self.LeftGroup.gameObject:SetActiveEx(true)
    self.BtnNegativeEffects.gameObject:SetActiveEx(true)
    self.BtnTacticalCore.gameObject:SetActiveEx(true)
    self.BtnMessage.gameObject:SetActiveEx(true)
    self:PlayAnimation("QieHuan")
end

function XUiInfestorExploreStage:PlayChapterFinishedAnimation()
    if self.IsPlayingAnim then return end
    self.IsPlayingAnim = true

    self.PanelFullFinish.gameObject:SetActiveEx(true)

    XDataCenter.FubenInfestorExploreManager.SetOpenInfestorExploreCoreDelay(2000)
    XDataCenter.FubenInfestorExploreManager.OpenGetNewCoreUi()
    self:PlayAnimation("PanelFullFinishEnable", function()
        self.IsPlayingAnim = nil
        self:Close()
    end)
end

function XUiInfestorExploreStage:OnClickBtnGuestbook()
    XDataCenter.FubenInfestorExploreManager.OpenGuestBook(self.ChapterId)
end

function XUiInfestorExploreStage:OnClickRImgCostBack()
    local data = {
        Id = XDataCenter.ItemManager.ItemId.InfestorMoney,
        Count = XDataCenter.FubenInfestorExploreManager.GetMoneyCount()
    }
    XLuaUiManager.Open("UiTip", data)
end