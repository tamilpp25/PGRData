local XUiPanelNewCharTask=XClass(XUiNode,'XUiPanelNewCharTask')
local XUiGridNewCharTask=require('XUi/XUiNewChar/XUiGridNewCharTask')

function XUiPanelNewCharTask:OnStart(cfg)
    self.Cfg=cfg
    self.GridTreasureList={}
    self.BtnTanchuangClose.CallBack=function() self:Close() end
    self.BtnTreasureBg.CallBack=function() self:Close() end
end

function XUiPanelNewCharTask:OnEnable()
    self.GridTreasureGrade.gameObject:SetActiveEx(false)
    self:ResetList()

    self:RefreshList()
end

function XUiPanelNewCharTask:OnDisable()
    self.Parent:RefreshMainTask()
    self.Parent:CheckRedPoint()
end

function XUiPanelNewCharTask:RefreshList()
    local targetList = self.Cfg.TreasureId
    if not targetList then
        return
    end

    local gridCount = #targetList
    for i = 1, gridCount do
        local grid=self:GetGrid(i)
        local treasureCfg = XFubenNewCharConfig.GetTreasureCfg(targetList[i])
        local curStars = XDataCenter.FubenNewCharActivityManager.GetKoroStarProgressById(self.Cfg.Id)
        grid:UpdateGradeGrid(curStars, treasureCfg, self.Cfg.Id)

        grid:InitTreasureList()
        grid.GameObject:SetActiveEx(true)
    end
end

--region List Control
function XUiPanelNewCharTask:GetGrid(index)
    local grid = self.GridTreasureList[index]
    if not grid then
        local item = CS.UnityEngine.Object.Instantiate(self.GridTreasureGrade)  -- 复制一个item
        grid = XUiGridNewCharTask.New(self.Parent, item, XDataCenter.FubenManager.StageType.NewCharAct)
        grid.Transform:SetParent(self.PanelGradeContent, false)
        self.GridTreasureList[index] = grid
    end

    return grid
end

function XUiPanelNewCharTask:ResetList()
    for j = 1, #self.GridTreasureList do
        self.GridTreasureList[j].GameObject:SetActiveEx(false)
    end
end
--endregion

return XUiPanelNewCharTask