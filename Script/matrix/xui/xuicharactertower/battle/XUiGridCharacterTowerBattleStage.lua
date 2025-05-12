local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
local XUiPanelStars = require("XUi/XUiFubenMainLineChapter/XUiPanelStars")

---@class XUiGridCharacterTowerBattleStage
local XUiGridCharacterTowerBattleStage = XClass(nil, "XUiGridCharacterTowerBattleStage")

function XUiGridCharacterTowerBattleStage:Ctor(ui, rootUi, cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = cb
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnStage, self.OnBtnStageClick)
    self.PanelStars = XUiPanelStars.New(self.PanelStar)
end

function XUiGridCharacterTowerBattleStage:Refresh(stageId)
    self.StageId = stageId
    self:SetNormalStage()
    -- 播放动画
    self.IconEnable:PlayTimelineAnimation()
end

function XUiGridCharacterTowerBattleStage:SetNormalStage()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)

    self.PanelStageNormal.gameObject:SetActiveEx(true)
    self.ImageSelected.gameObject:SetActiveEx(false)

    self.RImgFightActiveNor:SetSprite(stageCfg.Icon)
    if self.TxtStageTitle then
        self.TxtStageTitle.text = stageCfg.Name
    end
    if self.TxtStagePrefix then
        self.TxtStagePrefix.text = stageCfg.Description
    end
    
    if stageInfo.Unlock then
        self.PanelStageLock.gameObject:SetActiveEx(false)
        self.PanelStars:OnEnable(stageInfo.StarsMap)
    elseif stageInfo.IsOpen then
        self.PanelStageLock.gameObject:SetActiveEx(true)
        self.PanelStars.GameObject:SetActiveEx(false)
    end
    
    self.PanelStagePass.gameObject:SetActiveEx(stageInfo.Passed)
end

--- 是否显示选中框
function XUiGridCharacterTowerBattleStage:SetStageSelect(isSelect)
    if self.ImageSelected then
        self.ImageSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridCharacterTowerBattleStage:OnBtnStageClick()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    if not stageInfo.Unlock then
        XUiManager.TipMsg(XDataCenter.FubenManager.GetFubenOpenTips(self.StageId))
        return
    end
    if self.ClickCb then
        self.ClickCb(self)
    end
end

return XUiGridCharacterTowerBattleStage