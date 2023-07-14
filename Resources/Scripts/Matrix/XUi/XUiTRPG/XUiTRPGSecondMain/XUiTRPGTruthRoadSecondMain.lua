local Object

local XUiTRPGTruthRoadSecondMainStages = require("XUi/XUiTRPG/XUiTRPGSecondMain/XUiTRPGTruthRoadSecondMainStages")

--常规主线的关卡界面
local XUiTRPGTruthRoadSecondMain = XLuaUiManager.Register(XLuaUi, "UiTRPGTruthRoadSecondMain")

function XUiTRPGTruthRoadSecondMain:OnAwake()
    XDataCenter.TRPGManager.SaveIsAlreadyOpenTruthRoad()

    self.TopTabBtns = {}
    Object = CS.UnityEngine.Object
    self.CurStages = nil
    self.StageId = 0
    self.CurrSelectSecondMainStageId = nil    --当前选择的关卡id

    self:InitAutoScript()
    
    self.PanelSpecialTool.gameObject:SetActiveEx(false)

    XEventManager.AddEventListener(XEventId.EVENT_TRPG_GET_REWARD, self.OnCheckRedPoint, self)
end

function XUiTRPGTruthRoadSecondMain:OnStart(secondMainId)
    self.SecondMainId = secondMainId

    local secondMainBg = XTRPGConfigs.GetSecondMainBG(secondMainId)
    self.RImgBg:SetRawImage(secondMainBg) 

    self:OnCheckRedPoint()
    self:InitStagesMap()
end

function XUiTRPGTruthRoadSecondMain:OnEnable()
    self:Refresh()
end

function XUiTRPGTruthRoadSecondMain:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRPG_GET_REWARD, self.OnCheckRedPoint, self)
end

function XUiTRPGTruthRoadSecondMain:InitStagesMap()
    local secondMainId = self.SecondMainId
    local prefabName = XTRPGConfigs.GetSecondMainPrefab(secondMainId)
    local prefab = self.PanelPrequelStages:LoadPrefab(prefabName)
    if prefab == nil or not prefab:Exist() then
        return
    end
    self.CurStages = XUiTRPGTruthRoadSecondMainStages.New(prefab, secondMainId, function(secondMainStageId) self:OpenEnterDialog(secondMainStageId) end, self.CurrSelectSecondMainStageId)
    self.CurStages:SetParent(self.PanelPrequelStages)
end

function XUiTRPGTruthRoadSecondMain:InitAutoScript()
    self:AutoAddListener()
end

function XUiTRPGTruthRoadSecondMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self:RegisterClickEvent(self.BtnMask, self.OnBtnMaskClick)
    self:RegisterClickEvent(self.BtnEnterStory, self.OnBtnEnterStoryClick)
    self:RegisterClickEvent(self.BtnEnterFight, self.OnBtnEnterFightClick)
end

function XUiTRPGTruthRoadSecondMain:OnBtnEnterStoryClick()
    self:CloseEnterDialog()
    local stageId = self.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if stageInfo.Passed then
        XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId)
    else
        XDataCenter.FubenManager.FinishStoryRequest(stageId, function()
            XDataCenter.TRPGManager.SetStagePass(stageId)
            XDataCenter.MovieManager.PlayMovie(stageCfg.BeginStoryId, function()
                self:Refresh()
            end)
        end)
    end
end

function XUiTRPGTruthRoadSecondMain:OnBtnEnterFightClick()
    self:CloseEnterDialog()
    XLuaUiManager.Open("UiNewRoomSingle", self.StageId)
end

function XUiTRPGTruthRoadSecondMain:OnBtnMaskClick()
    self:CloseEnterDialog()
end

function XUiTRPGTruthRoadSecondMain:OnBtnBackClick()
    self:Close()
end

function XUiTRPGTruthRoadSecondMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTRPGTruthRoadSecondMain:Refresh()
    self:UpdateStagesMap()
    self:UpdateProgress()
end

function XUiTRPGTruthRoadSecondMain:UpdateStagesMap()
    self.CurStages:UpdateStagesMap()
end

function XUiTRPGTruthRoadSecondMain:UpdateProgress()
    local secondMainId = self.SecondMainId
    local rewardIdList = XTRPGConfigs.GetSecondMainStageRewardIdList(secondMainId)
    if #rewardIdList > 0 then
        local percent = XDataCenter.TRPGManager.GetSecondMainStagePercent(secondMainId)
        self.TxtBfrtTaskTotalNum.text = math.floor(percent * 100) .. "%"
        self.ImgJindu.fillAmount = percent
        self:OnCheckRedPoint()
        self.PanelBottom.gameObject:SetActiveEx(true)
    else
        self.PanelBottom.gameObject:SetActiveEx(false)
    end
end

--进度领奖
function XUiTRPGTruthRoadSecondMain:OnBtnTreasureClick()
    local secondMainId = self.SecondMainId
    local rewardIdList = XTRPGConfigs.GetSecondMainStageRewardIdList(secondMainId)
    XLuaUiManager.Open("UiTRPGRewardTip", rewardIdList, nil, secondMainId)
end

function XUiTRPGTruthRoadSecondMain:OpenEnterDialog(secondMainStageId)
    self:SetCurrSelectSecondMainStageId(secondMainStageId)

    local name = XTRPGConfigs.GetSecondMainStageName(secondMainStageId)
    local desc = XTRPGConfigs.GetSecondMainStageDesc(secondMainStageId)
    local dialogIcon = XTRPGConfigs.GetSecondMainStageDialogIcon(secondMainStageId)
    local stageId = XTRPGConfigs.GetSecondMainStageStageId(secondMainStageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

    if stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHT or stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG or stageCfg.StageType == XFubenConfigs.STAGETYPE_COMMON then
        self.TxtFightName.text = name
        self.TxtFightDec.text = desc
        self.RImgFight:SetRawImage(dialogIcon)
        self.PanelStory.gameObject:SetActiveEx(false)
        self.PanelFight.gameObject:SetActiveEx(true)
    else
        self.TxtStoryName.text = name
        self.TxtStoryDec.text = desc
        self.RImgStory:SetRawImage(dialogIcon)
        self.PanelStory.gameObject:SetActiveEx(true)
        self.PanelFight.gameObject:SetActiveEx(false)
    end

    self.StageId = stageId
    self.PanelEnterDialog.gameObject:SetActiveEx(true)
end

function XUiTRPGTruthRoadSecondMain:CloseEnterDialog()
    self.PanelEnterDialog.gameObject:SetActiveEx(false)
    self.CurStages:CancalSelectLastGrid()
end

function XUiTRPGTruthRoadSecondMain:OnCheckRedPoint()
    local secondMainId = self.SecondMainId
    local isShowRedPoint = XDataCenter.TRPGManager.IsSecondMainCanReward(secondMainId)
    self.ImgRedProgress.gameObject:SetActiveEx(isShowRedPoint)
end

function XUiTRPGTruthRoadSecondMain:OnResume(data)
    self:SetCurrSelectSecondMainStageId(data)
end

function XUiTRPGTruthRoadSecondMain:OnReleaseInst()
    return self.CurrSelectSecondMainStageId
end

function XUiTRPGTruthRoadSecondMain:SetCurrSelectSecondMainStageId(currSelectSecondMainStageId)
    self.CurrSelectSecondMainStageId = currSelectSecondMainStageId
end