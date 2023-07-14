local XUiCerberusGameChallenge = XLuaUiManager.Register(XLuaUi, "UiCerberusGameChallenge")
local XUiGridCerberusGameStage2 = require("XUi/XUiCerberusGame/Grid/XUiGridCerberusGameStage2")

local DicName = 
{
    [XCerberusGameConfig.StageDifficulty.Normal] = "GridNormalStageDic",
    [XCerberusGameConfig.StageDifficulty.Hard] = "GridHardStageDic",
}

function XUiCerberusGameChallenge:OnAwake()
    self.ChapterId = XDataCenter.CerberusGameManager.GetChapterIdList()[2]  -- 挑战是第二个chapter 写死
    self.GridNormalStageDic = {}
    self.GridHardStageDic = {}
    self.CurrDifficulty = nil
    self:InitButton()
    self:InitTimes()
end

function XUiCerberusGameChallenge:InitButton()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function () XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "CerberusHelp")

    local tabBtns = { self.BtnNormal, self.BtnHard }
    self.TabBtns = tabBtns
    self.BtnTab:Init(tabBtns, function(index) self:OnSelected(index) end)
end

function XUiCerberusGameChallenge:InitTimes()
    local timeId = XDataCenter.CerberusGameManager.GetActivityConfig().TimeId
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

function XUiCerberusGameChallenge:OnEnable()
    self.Super.OnEnable(self)
    self.BtnTab:SelectIndex(self.LastDifficulty or 1)
end

function XUiCerberusGameChallenge:OnSelected(targetIndex)
    if targetIndex == self.CurrDifficulty then
        return
    end

    if targetIndex == XCerberusGameConfig.StageDifficulty.Hard and self:GetDifficultyIsLock(targetIndex) then
        XUiManager.TipError(CS.XTextManager.GetText("CerbrusGameChallengeLimit"))
        return
    end

    for k, v in pairs(DicName) do
        self["PanelContent"..k].gameObject:SetActiveEx(k == targetIndex)
    end

    self:RefreshStageList(targetIndex)
    self:RefreshButtonState(targetIndex)
    local btn = self.TabBtns[targetIndex]
    if btn.ButtonType ~= CS.UiButtonState.Select then
        btn:SetButtonState(CS.UiButtonState.Select)
    end

    self["RImgBg"..(self.CurrDifficulty or self.LastDifficulty or 1)].gameObject:SetActiveEx(false)
    self["RImgBg"..targetIndex].gameObject:SetActiveEx(true)

    self.CurrDifficulty = targetIndex
    self:PlayAnimation("QieHuan")
end

function XUiCerberusGameChallenge:RefreshStageList(difficulty)
    local bossList = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameBoss)
    for k, v in pairs(bossList) do
        local stageId = v.StageId[difficulty]
        if stageId then
            ---@type XUiGridCerberusGameStage2
            local gridStage = self[DicName[difficulty]][stageId]
            if not gridStage then
                local ui = CS.UnityEngine.Object.Instantiate(self["GridStage"..difficulty], self["GridStage"..difficulty].parent)
                ui.gameObject:SetActiveEx(true)
                gridStage = XUiGridCerberusGameStage2.New(ui)
                self[DicName[difficulty]][stageId] = gridStage
            end
            gridStage:Refresh(stageId, v)
            XUiHelper.RegisterClickEvent(gridStage, gridStage.BtnClick, function ()
                self:OnGridStoryPointClick(stageId, k)
            end)
        end
    end
end

function XUiCerberusGameChallenge:RefreshButtonState()
    for difficulty, name in pairs(DicName) do
        local isDisable = true
        local gridsList = self[name]
        for k, grid in pairs(gridsList) do
            local xStage = grid.XStage
            if xStage and xStage:GetIsOpen() then
                isDisable = false
                break
            end
        end
        local btn = self.TabBtns[difficulty]
        btn:SetDisable(isDisable)
    end
end

function XUiCerberusGameChallenge:GetDifficultyIsLock(difficulty)
    local bossList = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameBoss)
    local stageList = {}
    for k, v in pairs(bossList) do
        table.insert(stageList, v.StageId[difficulty])
    end

    for k, stageId in pairs(stageList) do
        local xStage = XDataCenter.CerberusGameManager.GetXStageById(stageId)
        if xStage:GetIsOpen() then
            return false
        end
    end

    return true
end

function XUiCerberusGameChallenge:OnGridStoryPointClick(stageId, bossIndex)
    local xStage = XDataCenter.CerberusGameManager.GetXStageById(stageId)    
    if not xStage:GetIsOpen() then
        local preStageId = XCerberusGameConfig.GetAllConfigs(XCerberusGameConfig.TableKey.CerberusGameChallenge)[stageId].PreStageId
        local preStageCfg = XDataCenter.FubenManager.GetStageCfg(preStageId)
        XUiManager.TipError(CS.XTextManager.GetText("FubenPreStage", preStageCfg.Name))
        return
    end
    XLuaUiManager.Open("UiCerberusGameTips", stageId, self.ChapterId, self.CurrDifficulty, bossIndex)
end

-- 记录作战前底部页签选择的Id
function XUiCerberusGameChallenge:OnReleaseInst()
    return { 
        SelectDifficulty = self.CurrDifficulty,
    }
end

function XUiCerberusGameChallenge:OnResume(data)
    if XLuaUiManager.IsUiLoad("UiMain")  then  -- 如果是从uimain打开  
        return
    end

    data = data or {}
    self.LastDifficulty = data.SelectDifficulty
end

return XUiCerberusGameChallenge