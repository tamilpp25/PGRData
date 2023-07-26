-- 兵法蓝图主页面关卡列表：关卡显示控件
local XUiRpgTowerStageGrid = XClass(nil, "XUiRpgTowerStageGrid")
function XUiRpgTowerStageGrid:Ctor()
    
end
--================
--关卡项初始化
--================
function XUiRpgTowerStageGrid:Init(ui, stageList)
    XTool.InitUiObjectByUi(self, ui)
    self.StageList = stageList
    self.GridStage.CallBack = function() self:OnClick() end
    --self.RImgBtnPress:SetSprite(CS.XGame.ClientConfig:GetString("RpgTowerStageBgNormal"))
    --self.RImgBtnNormal:SetSprite(CS.XGame.ClientConfig:GetString("RpgTowerStageBgNormal"))
    --self.RImgBtnSelect:SetSprite(CS.XGame.ClientConfig:GetString("RpgTowerStageBgSelect"))
end
--================
--刷新关卡数据
--================
function XUiRpgTowerStageGrid:RefreshData(rStageCfg, gridIndex)
    local rStage = XDataCenter.RpgTowerManager.GetRStageByStageId(rStageCfg.StageId)
    self.RStage = rStage
    self.GridIndex = gridIndex
    self.DifficultyData = XDataCenter.RpgTowerManager.StageDifficultyData[self.RStage:GetDifficulty()]
    self:SetName()
    self:SetBg()
    self.GridStage:SetDisable(not self.RStage:GetIsUnlock())
    self.GridStage:ShowTag(self.RStage:GetIsPass())
end
--================
--关卡点击事件
--================
function XUiRpgTowerStageGrid:OnClick()
    if self.RStage:GetIsUnlock() then
        self:SetSelect(true)
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("RpgTowerStageNotOpen"))
    end
    -- 本身UiButton的Bug，选中状态下再选中一次会给TempState赋值Select，这里把临时状态改为Normal避免让OnPointerExit事件中恢复TempState的状态变为Select
    self.GridStage.TempState = CS.UiButtonState.Normal
end
--================
--设置关卡名称
--================
function XUiRpgTowerStageGrid:SetName()
    self.GridStage:SetNameByGroup(0, self.RStage:GetOrderName())
    -- self.GridStage:SetNameByGroup(1, XUiHelper.GetText("RpgTowerStageDifficultTitle" .. self.RStage:GetDifficulty()))
end
--================
--设置图标
--================
function XUiRpgTowerStageGrid:SetBg()
    self.RawImageNormal:SetRawImage(XDataCenter.RpgTowerManager.StageDifficultyNewData[self.RStage:GetDifficulty()]["Normal"])
    local pressPath = XDataCenter.RpgTowerManager.StageDifficultyNewData[self.RStage:GetDifficulty()]["Disable"]
    self.RawImagePress:SetRawImage(pressPath)
    self.RawImageDisable:SetRawImage(pressPath)
    self.RawImageSelect:SetRawImage(XDataCenter.RpgTowerManager.StageDifficultyNewData[self.RStage:GetDifficulty()]["Select"])
end
--================
--选中事件
--================
function XUiRpgTowerStageGrid:SetSelect(isSelect)
    local uiBtnState
    if isSelect then
        uiBtnState = CS.UiButtonState.Select
    else
        if self.RStage:GetIsUnlock() then
            uiBtnState = CS.UiButtonState.Normal
            -- 本身UiButton的Bug，选中状态下再选中一次会给TempState赋值Select，这里把临时状态改为Normal避免让OnPointerExit事件中恢复TempState的状态变为Select
            self.GridStage.TempState = CS.UiButtonState.Normal
        else
            uiBtnState = CS.UiButtonState.Disable
            self.GridStage.TempState = CS.UiButtonState.Disable
        end
    end
    self.GridStage:SetButtonState(uiBtnState)
    if isSelect then self.StageList:SetSelect(self) end
end
return XUiRpgTowerStageGrid