local XUiCerberusGameChallengeV2P9 = XLuaUiManager.Register(nil, "UiCerberusGameChallengeV2P9")

function XUiCerberusGameChallengeV2P9:OnAwake()
    self.ChapterId = XMVCA.XCerberusGame:GetChapterIdList()[XEnumConst.CerberusGame.ChapterIdIndex.FashionChallenge]
    self.GridNormalStageDic = {}
    self:InitButton()
    self:InitTimes()
end

function XUiCerberusGameChallengeV2P9:InitButton()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function () XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "CerberusHelp")
end

function XUiCerberusGameChallengeV2P9:InitTimes()
    local secondTimeId = XMVCA.XCerberusGame:GetClientConfigValueByKey("CerberusGameRound2Time")
    local timeId = secondTimeId
    if not timeId then
        return
    end
    
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiCerberusGameChallengeV2P9:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshStageList()
end

function XUiCerberusGameChallengeV2P9:RefreshStageList()
    local stageIdList = XMVCA.XCerberusGame:GetChallengeStageIdListByChapterId(self.ChapterId)
    for i = 1, #stageIdList do
        local stageId = stageIdList[i]
        local gridStage = self.GridNormalStageDic[i]
        if not gridStage then
            local ui = self.PanelChapterList:GetChild(i-1)
            local XUiGridCerberusGameChallengeStageV2P9 = require("XUi/XUiCerberusGame/V2P9/Grid/XUiGridCerberusGameChallengeStageV2P9")
            gridStage = XUiGridCerberusGameChallengeStageV2P9.New(ui, self)
            self.GridNormalStageDic[i] = gridStage
            XUiHelper.RegisterClickEvent(gridStage, gridStage.BtnChapter, function ()
                self:OnGridClick(stageId)
            end)
        end
        gridStage:Refresh(stageId)
    end
end

function XUiCerberusGameChallengeV2P9:OnGridClick(stageId)
    local xStage = XMVCA.XCerberusGame:GetXStageById(stageId)    
    if not xStage:GetIsOpen() then
        local preStageId = XMVCA.XCerberusGame:GetModelCerberusGameChallenge()[stageId].PreStageId
        local preStageCfg = XDataCenter.FubenManager.GetStageCfg(preStageId)
        XUiManager.TipError(CS.XTextManager.GetText("FubenPreStage", preStageCfg.Name))
        return
    end
    XLuaUiManager.Open("UiCerberusGameTipsV2P9", stageId, self.ChapterId)
end

return XUiCerberusGameChallengeV2P9