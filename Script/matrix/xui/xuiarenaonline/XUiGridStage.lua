local XUiGridStage = XClass(nil, "XUiGridStage")
local XUiPanelStars = require("XUi/XUiFubenMainLineChapter/XUiPanelStars")

function XUiGridStage:Ctor(ui, uiRoot, parent, challengeId, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.Parent = parent
    self.ChallengeId = challengeId
    self.ClickCb = clickCb

    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:Refresh()
end

function XUiGridStage:AutoAddListener()
    self.BtnStage.CallBack = function() self:OnBtnStageClick() end
end

function XUiGridStage:SetStageSelect()
    self.PanelSlect.gameObject:SetActiveEx(true)
end

function XUiGridStage:SetStageActive()
    self.PanelSlect.gameObject:SetActiveEx(false)
end

function XUiGridStage:OnBtnStageClick()
    self.UiRoot:OpenStageDetial(self.ChallengeId)
    if self.ClickCb then self.ClickCb(self) end
end

function XUiGridStage:Refresh()
    local arenaOnlieStageCfg = XArenaOnlineConfigs.GetStageById(self.ChallengeId)
    local stagePass = XDataCenter.ArenaOnlineManager.CheckStagePass(self.ChallengeId)
    self:SetStageActive()
    if not arenaOnlieStageCfg then return end

    self.TxtStage.text = arenaOnlieStageCfg.Name
    self.RImgBg:SetRawImage(arenaOnlieStageCfg.BgIcon)
    self.RImgName:SetRawImage(arenaOnlieStageCfg.NameIcon)
    self.PanelStars = XUiPanelStars.New(self.PanelStar)
    local starsMap = XDataCenter.ArenaOnlineManager.GetStageStarsMapByChallengeId(self.ChallengeId)
    self.PanelStars:OnEnable(starsMap)
    self.PanelClear.gameObject:SetActiveEx(stagePass)
end

return XUiGridStage