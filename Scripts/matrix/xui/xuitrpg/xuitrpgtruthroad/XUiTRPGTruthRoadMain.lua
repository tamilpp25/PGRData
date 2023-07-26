local Object

local XUiTRPGTruthRoadStages = require("XUi/XUiTRPG/XUiTRPGTruthRoad/XUiTRPGTruthRoadStages")

--求真之路主界面
local XUiTRPGTruthRoadMain = XLuaUiManager.Register(XLuaUi, "UiTRPGTruthRoadMain")

function XUiTRPGTruthRoadMain:OnAwake()
    XDataCenter.TRPGManager.SaveIsAlreadyOpenTruthRoad()

    self.TopTabBtns = {}
    Object = CS.UnityEngine.Object
    self.CurStages = nil
    self.DialogId = 0
    self.CurrSelectTruthRoadId = nil    --当前选择的求真之路id

    self:InitAutoScript()
    
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.TRPGMoney, function()
        self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.TRPGMoney})
    end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.TRPGMoney})

    XEventManager.AddEventListener(XEventId.EVENT_TRPG_GET_REWARD, self.OnCheckRedPoint, self)
end

function XUiTRPGTruthRoadMain:OnStart(param)
    local defaltBottomIndex = param[1]
    self.BottomTabGroup:SelectIndex(defaltBottomIndex)
    self:OnCheckRedPoint()
end

function XUiTRPGTruthRoadMain:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRPG_GET_REWARD, self.OnCheckRedPoint, self)

end

function XUiTRPGTruthRoadMain:InitAutoScript()
    self:InitTopTabGroup()
    self:InitBottomTabGroup()
    self:AutoAddListener()
end

function XUiTRPGTruthRoadMain:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self:BindHelpBtn(self.BtnActDesc, "TRPGMainLine")
    self:RegisterClickEvent(self.BtnMask, self.OnBtnMaskClick)
    self:RegisterClickEvent(self.BtnEnterStory, self.OnBtnEnterStoryClick)
    self:RegisterClickEvent(self.BtnEnterFight, self.OnBtnEnterFightClick)

end

function XUiTRPGTruthRoadMain:OnBtnEnterStoryClick()
    self:CloseEnterDialog()
    XDataCenter.MovieManager.PlayMovie(self.DialogId)
end

function XUiTRPGTruthRoadMain:OnBtnEnterFightClick()
    self:CloseEnterDialog()
    XLuaUiManager.Open("UiNewRoomSingle", self.DialogId)
end

function XUiTRPGTruthRoadMain:OnBtnMaskClick()
    self:CloseEnterDialog()
end

function XUiTRPGTruthRoadMain:OnBtnBackClick()
    self:Close()
end

function XUiTRPGTruthRoadMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

--初始化区域按钮组
function XUiTRPGTruthRoadMain:InitBottomTabGroup()
    self.BottomTabBtns = {}
    local mainAreaMaxNum = XTRPGConfigs.GetMainAreaMaxNum()
    local btnName, imagePath
    local isOpen
    for i = 1, mainAreaMaxNum do
        if not self.BottomTabBtns[i] then
            if i == 1 then
                self.BottomTabBtns[i] = self.BtnPrequelPlotTab
            else
                local btn = Object.Instantiate(self.BtnPrequelPlotTab)
                btn.transform:SetParent(self.BottomTabGroup.transform, false)
                self.BottomTabBtns[i] = btn
            end
        end
        btnName = XTRPGConfigs.GetMainAreaName(i)
        imagePath = XTRPGConfigs.GetTruthRoadTabBg(i)
        isOpen = XDataCenter.TRPGManager.IsTruthRoadOpenArea(i)
        self.BottomTabBtns[i]:SetName(btnName)
        self.BottomTabBtns[i]:ShowTag(false)
        self.BottomTabBtns[i]:SetRawImage(imagePath)
        self.BottomTabBtns[i]:SetDisable(not isOpen)
        self.BottomTabBtns[i].gameObject:SetActiveEx(true)
    end

    self.BottomTabGroup:Init(self.BottomTabBtns, function(groupIndex) self:BottomTabGroupSkip(groupIndex) end)
end

function XUiTRPGTruthRoadMain:BottomTabGroupSkip(groupIndex)
    if self.CurAreaId == groupIndex then
        return
    end

    local isOpen, topTapGroupIndex = XDataCenter.TRPGManager.IsTruthRoadOpenArea(groupIndex)
    if not isOpen then
        self.BottomTabGroup:SelectIndex(self.CurAreaId)
        XUiManager.TipText("TRPGTruthRoadAreaNotOpen")
        return
    end

    self.CurAreaId = groupIndex
    self.TxtName.text = XTRPGConfigs.GetMainAreaName(groupIndex)
    self.EnName.text = XTRPGConfigs.GetMainAreaEnName(groupIndex)
    local bgPath = XTRPGConfigs.GetTruthRoadBg(groupIndex)
    self.RImgBg:SetRawImage(bgPath)

    self:RefreshTopTabGroup(topTapGroupIndex)
    self:OnCheckTopTabRedPoint()
    self:PlayAnimation("QieHuan2")
end

--初始化任务按钮组
function XUiTRPGTruthRoadMain:InitTopTabGroup()
    local truthGroupMaxNum = XTRPGConfigs.GetTruthRoadGroupMaxNum()
    for i = 1, truthGroupMaxNum do
        if i == 1 then
            self.TopTabBtns[i] = self.BtnTab01
        else
            local btn = Object.Instantiate(self.BtnTab01)
            btn.transform:SetParent(self.PanelTab.transform, false)
            self.TopTabBtns[i] = btn
        end
    end

    self.TopTabButtonGroup = self.PanelTab:GetComponent("XUiButtonGroup")
    self.TopTabButtonGroup:Init(self.TopTabBtns, function(groupIndex) self:TopTabGroupSkip(groupIndex) end)
end

function XUiTRPGTruthRoadMain:RefreshTopTabGroup(topTapGroupIndex)
    for _, v in ipairs(self.TopTabBtns) do
        v.gameObject:SetActiveEx(false)
    end

    local truthGroupIdList = XTRPGConfigs.GetTruthRoadGroupIdList(self.CurAreaId)
    local tabName, tabSmallName
    local isOpen
    for i, truthGroupId in ipairs(truthGroupIdList) do
        tabName = XTRPGConfigs.GetTruthRoadGroupName(truthGroupId)
        tabSmallName = XTRPGConfigs.GetTruthRoadGroupSmallName(truthGroupId)
        isOpen = XDataCenter.TRPGManager.IsTruthRoadGroupConditionFinish(self.CurAreaId, i)
        self.TopTabBtns[i].gameObject:SetActiveEx(true)
        self.TopTabBtns[i]:SetNameByGroup(0, tabName)
        self.TopTabBtns[i]:SetNameByGroup(1, tabSmallName)
        self.TopTabBtns[i]:SetDisable(not isOpen)
    end

    if self.TopTabGroupIndex == topTapGroupIndex then
        self:Refresh()
    end
    self.TopTabButtonGroup:SelectIndex(topTapGroupIndex)
end

function XUiTRPGTruthRoadMain:TopTabGroupSkip(groupIndex)
    if self.TopTabGroupIndex == groupIndex then
        return
    end

    local ret, desc = XDataCenter.TRPGManager.IsTruthRoadGroupConditionFinish(self.CurAreaId, groupIndex)
    if not ret then
        self.TopTabButtonGroup:SelectIndex(self.TopTabGroupIndex)
        XUiManager.TipMsg(desc)
        return
    end

    self.TopTabGroupIndex = groupIndex
    self:Refresh()
    self:PlayAnimation("QieHuan1")
end

function XUiTRPGTruthRoadMain:Refresh()
    self:UpdateStagesMap()
    self:UpdateProgress()
end

function XUiTRPGTruthRoadMain:UpdateStagesMap()
    local truthRoadGroupId = XTRPGConfigs.GetTruthRoadGroupId(self.CurAreaId, self.TopTabGroupIndex)
    if truthRoadGroupId ~= self.TruthRoadGroupId then
        local prefabName = XTRPGConfigs.GetTruthRoadGroupPrefab(truthRoadGroupId)
        local prefab = self.PanelPrequelStages:LoadPrefab(prefabName)
        if prefab == nil or not prefab:Exist() then
            return
        end
        self.TruthRoadGroupId = truthRoadGroupId
        self.CurStages = XUiTRPGTruthRoadStages.New(prefab, truthRoadGroupId, function(truthRoadId) self:OpenEnterDialog(truthRoadId) end, self.CurrSelectTruthRoadId)
        self.CurStages:SetParent(self.PanelPrequelStages)
    end
    self.CurStages:UpdateStagesMap()
end

function XUiTRPGTruthRoadMain:UpdateProgress()
    local rewardIdList = XTRPGConfigs.GetTruthRoadRewardIdList(self.TruthRoadGroupId)
    if #rewardIdList > 0 then
        local percent = XDataCenter.TRPGManager.GetTruthRoadPercent(self.TruthRoadGroupId)
        self.TxtBfrtTaskTotalNum.text = math.floor(percent * 100) .. "%"
        self.ImgJindu.fillAmount = percent
        self:OnCheckPanelBottomRedPoint()
        self.PanelBottom.gameObject:SetActiveEx(true)
    else
        self.PanelBottom.gameObject:SetActiveEx(false)
    end
end

--进度领奖
function XUiTRPGTruthRoadMain:OnBtnTreasureClick()
    local rewardIdList = XTRPGConfigs.GetTruthRoadRewardIdList(self.TruthRoadGroupId)
    XLuaUiManager.Open("UiTRPGRewardTip", rewardIdList, self.TruthRoadGroupId)
end

function XUiTRPGTruthRoadMain:OpenEnterDialog(truthRoadId)
    self:SetCurrSelectTruthRoadId(truthRoadId)

    local name = XTRPGConfigs.GetTruthRoadName(truthRoadId)
    local icon = XTRPGConfigs.GetTruthRoadIcon(truthRoadId)
    local desc = XTRPGConfigs.GetTruthRoadDesc(truthRoadId)
    local dialogIcon = XTRPGConfigs.GetTruthRoadDialogIcon(truthRoadId)
    local stageId = XTRPGConfigs.GetTruthRoadStageId(truthRoadId)
    if stageId and stageId > 0 then
        self.DialogId = stageId
        self.TxtFightName.text = name
        self.TxtFightDec.text = desc
        self.RImgFight:SetRawImage(dialogIcon)
        self.PanelStory.gameObject:SetActiveEx(false)
        self.PanelFight.gameObject:SetActiveEx(true)
    else
        self.DialogId = XTRPGConfigs.GetTruthRoadStoryId(truthRoadId)
        self.TxtStoryName.text = name
        self.TxtStoryDec.text = desc
        self.RImgStory:SetRawImage(dialogIcon)
        self.PanelStory.gameObject:SetActiveEx(true)
        self.PanelFight.gameObject:SetActiveEx(false)
    end

    self.PanelEnterDialog.gameObject:SetActiveEx(true)
end

function XUiTRPGTruthRoadMain:CloseEnterDialog()
    self.PanelEnterDialog.gameObject:SetActiveEx(false)
    self.CurStages:CancalSelectLastGrid()
end

--下面区域按钮红点
function XUiTRPGTruthRoadMain:OnCheckBottomTabRedPoint()
    local isShowRedPoint
    for areaId, bottomTabBtn in ipairs(self.BottomTabBtns) do
        isShowRedPoint = XDataCenter.TRPGManager.CheckTruthRoadAreaReward(areaId)
        bottomTabBtn:ShowReddot(isShowRedPoint)
    end
end

--上面任务按钮红点
function XUiTRPGTruthRoadMain:OnCheckTopTabRedPoint()
    local truthGroupIdList = XTRPGConfigs.GetTruthRoadGroupIdList(self.CurAreaId)
    local isShowRedPoint
    for i, truthGroupId in ipairs(truthGroupIdList) do
        if self.TopTabBtns[i] then
            isShowRedPoint = XDataCenter.TRPGManager.CheckTruthRoadReward(truthGroupId)
            self.TopTabBtns[i]:ShowReddot(isShowRedPoint)
        end
    end
end

--区域进度红点
function XUiTRPGTruthRoadMain:OnCheckPanelBottomRedPoint()
    local truthGroupId = XTRPGConfigs.GetTruthRoadGroupId(self.CurAreaId, self.TopTabGroupIndex)
    local isShowRedPoint = XDataCenter.TRPGManager.CheckTruthRoadReward(truthGroupId)
    self.ImgRedProgress.gameObject:SetActiveEx(isShowRedPoint)
end

function XUiTRPGTruthRoadMain:OnCheckRedPoint()
    self:OnCheckPanelBottomRedPoint()
    self:OnCheckBottomTabRedPoint()
    self:OnCheckTopTabRedPoint()
end

function XUiTRPGTruthRoadMain:OnResume(data)
    self:SetCurrSelectTruthRoadId(data)
end

function XUiTRPGTruthRoadMain:OnReleaseInst()
    return self.CurrSelectTruthRoadId
end

function XUiTRPGTruthRoadMain:SetCurrSelectTruthRoadId(currSelectTruthRoadId)
    self.CurrSelectTruthRoadId = currSelectTruthRoadId
end