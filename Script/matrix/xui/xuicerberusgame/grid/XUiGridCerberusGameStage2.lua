---@class XUiGridCerberusGameStage2
local XUiGridCerberusGameStage2 = XClass(nil, "XUiGridCerberusGameStage2")
local MaxStarCount = 3

function XUiGridCerberusGameStage2:Ctor(ui, index, rootui)
    self.RootUi = rootui
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GridIndex = index
    XTool.InitUiObject(self)
end

function XUiGridCerberusGameStage2:Refresh(stageId, bossCfg)
    local xStage = XMVCA.XCerberusGame:GetXStageById(stageId)
    self.XStage = xStage
    if self.PanelStageLock then
        self.PanelStageLock.gameObject:SetActiveEx(not xStage:GetIsOpen())
    end
    if self.TxtName then
        self.TxtName.text = bossCfg.BossName
    end
    if self.TxtName2 then
        self.TxtName2.text = bossCfg.BossName
    end
    if self.IconBoss then
        self.IconBoss:SetRawImage(bossCfg.BossImg)
    end
    if self.IconBoss2 then
        self.IconBoss2:SetRawImage(bossCfg.BossImg)
    end

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(xStage.StageId)
    local starDescCount = #stageCfg.StarDesc
    local starCount = xStage:GetStarsCount()
    starCount = XTool.IsNumberValid(starCount) and starCount or 0
    if starCount >= starDescCount then
        starCount = MaxStarCount
    end 

    local iconPath = CS.XGame.ClientConfig:GetString(XEnumConst.CerberusGame.ChallengeStageStar[starCount])
    if self.Progress then
        self.Progress:SetRawImage(iconPath)
    end
    if self.Progress2 then
        self.Progress2:SetRawImage(iconPath)
    end
    if self.Clear then
        self.Clear.gameObject:SetActiveEx(xStage:GetIsPassed() and starCount == MaxStarCount)
    end
end

return XUiGridCerberusGameStage2